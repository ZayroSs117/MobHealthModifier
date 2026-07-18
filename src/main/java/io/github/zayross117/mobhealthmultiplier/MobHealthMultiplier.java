package io.github.zayross117.mobhealthmultiplier;

import com.mojang.brigadier.arguments.DoubleArgumentType;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.ai.attributes.AttributeInstance;
import net.minecraft.world.entity.ai.attributes.AttributeModifier;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.entity.monster.Enemy;
import net.minecraft.world.entity.player.Player;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.event.RegisterCommandsEvent;
import net.minecraftforge.event.entity.EntityJoinLevelEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.loading.FMLPaths;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Properties;
import java.util.Set;
import java.util.UUID;
import java.util.WeakHashMap;

/**
 * Multiplies the maximum health of hostile mobs on a dedicated Forge server.
 */
@Mod(MobHealthMultiplier.MOD_ID)
public final class MobHealthMultiplier {
    public static final String MOD_ID = "mobhealthmultiplier";

    private static final String CONFIG_FILE_NAME = "mob-health-multiplier.properties";
    private static final UUID HEALTH_MODIFIER_UUID =
            UUID.fromString("1dd7e176-c692-4cee-8c5e-784f7326b50a");

    private static final Set<LivingEntity> TRACKED_HOSTILES =
            Collections.newSetFromMap(new WeakHashMap<>());

    private static volatile double healthMultiplier = 2.0D;
    private static volatile Path configFile;
    private static volatile boolean errorPrinted;

    public MobHealthMultiplier() {
        LoadResult result = loadConfiguration(true);
        MinecraftForge.EVENT_BUS.register(this);

        System.out.println("[MobHealthMultiplier] Enabled for hostile mobs only with multiplier x"
                + formatMultiplier(healthMultiplier) + ".");
        System.out.println("[MobHealthMultiplier] Config file: " + getConfigFile());

        if (!result.success()) {
            System.err.println("[MobHealthMultiplier] " + result.message());
        }
    }

    @SubscribeEvent
    public void onEntityJoin(EntityJoinLevelEvent event) {
        if (!(event.getLevel() instanceof ServerLevel)) {
            return;
        }
        if (!(event.getEntity() instanceof LivingEntity living)) {
            return;
        }
        if (living instanceof Player) {
            return;
        }

        try {
            if (living instanceof Enemy) {
                synchronized (TRACKED_HOSTILES) {
                    TRACKED_HOSTILES.add(living);
                }
                applyMultiplier(living, healthMultiplier);
            } else {
                // Removes the old modifier from passive entities affected by version 1.0.0.
                applyMultiplier(living, 1.0D);
            }
        } catch (RuntimeException | LinkageError error) {
            printEntityErrorOnce(error);
        }
    }

    @SubscribeEvent
    public void onRegisterCommands(RegisterCommandsEvent event) {
        event.getDispatcher().register(
                Commands.literal("mobhealth")
                        .requires(source -> source.hasPermission(2))
                        .executes(context -> commandGet(context.getSource()))
                        .then(Commands.literal("get")
                                .executes(context -> commandGet(context.getSource())))
                        .then(Commands.literal("set")
                                .then(Commands.argument(
                                                "multiplier",
                                                DoubleArgumentType.doubleArg(1.0D, 1000.0D))
                                        .executes(context -> commandSet(
                                                context.getSource(),
                                                DoubleArgumentType.getDouble(
                                                        context,
                                                        "multiplier")))))
                        .then(Commands.literal("reload")
                                .executes(context -> commandReload(context.getSource())))
                        .then(Commands.literal("apply")
                                .executes(context -> commandApply(context.getSource())))
                        .then(Commands.literal("config")
                                .executes(context -> commandConfig(context.getSource())))
        );
    }

    private static int commandGet(CommandSourceStack source) {
        sendFeedback(source,
                "Hostile mob health multiplier: x" + formatMultiplier(healthMultiplier)
                        + " | Config: " + getConfigFile(),
                false);
        return 1;
    }

    private static int commandSet(CommandSourceStack source, double multiplier) {
        if (!isValidMultiplier(multiplier)) {
            sendFeedback(source, "The multiplier must be between 1.0 and 1000.0.", false);
            return 0;
        }

        double previous = healthMultiplier;
        healthMultiplier = multiplier;

        try {
            saveConfiguration(multiplier);
        } catch (IOException error) {
            healthMultiplier = previous;
            sendFeedback(source,
                    "Could not save the config file: " + error.getMessage(),
                    false);
            return 0;
        }

        int changed = applyToTrackedHostiles();
        sendFeedback(source,
                "Multiplier changed to x" + formatMultiplier(multiplier)
                        + ". Updated " + changed + " loaded hostile mob(s).",
                true);
        return 1;
    }

    private static int commandReload(CommandSourceStack source) {
        double previous = healthMultiplier;
        LoadResult result = loadConfiguration(true);

        if (!result.success()) {
            healthMultiplier = previous;
            sendFeedback(source, result.message(), false);
            return 0;
        }

        int changed = applyToTrackedHostiles();
        sendFeedback(source,
                "Config reloaded. Multiplier is x" + formatMultiplier(healthMultiplier)
                        + ". Updated " + changed + " loaded hostile mob(s).",
                true);
        return 1;
    }

    private static int commandApply(CommandSourceStack source) {
        int changed = applyToTrackedHostiles();
        sendFeedback(source,
                "Reapplied x" + formatMultiplier(healthMultiplier)
                        + " to " + changed + " loaded hostile mob(s).",
                false);
        return 1;
    }

    private static int commandConfig(CommandSourceStack source) {
        try {
            ensureConfigurationExists();
            sendFeedback(source, "Config file: " + getConfigFile(), false);
            return 1;
        } catch (IOException error) {
            sendFeedback(source,
                    "Config path: " + getConfigFile()
                            + " (creation failed: " + error.getMessage() + ")",
                    false);
            return 0;
        }
    }

    private static void sendFeedback(
            CommandSourceStack source,
            String message,
            boolean broadcastToOps
    ) {
        source.sendSuccess(() -> Component.literal(message), broadcastToOps);
    }

    private static int applyToTrackedHostiles() {
        List<LivingEntity> snapshot;
        synchronized (TRACKED_HOSTILES) {
            snapshot = new ArrayList<>(TRACKED_HOSTILES);
        }

        int changed = 0;
        for (LivingEntity entity : snapshot) {
            if (entity == null || !(entity instanceof Enemy) || entity instanceof Player) {
                continue;
            }

            try {
                applyMultiplier(entity, healthMultiplier);
                changed++;
            } catch (RuntimeException | LinkageError error) {
                printEntityErrorOnce(error);
            }
        }
        return changed;
    }

    private static void applyMultiplier(LivingEntity entity, double multiplier) {
        AttributeInstance maxHealth = entity.getAttribute(Attributes.MAX_HEALTH);
        if (maxHealth == null) {
            return;
        }

        float oldHealth = entity.getHealth();
        float oldMaximum = entity.getMaxHealth();

        // Always remove the previous value first to prevent stacking.
        maxHealth.removeModifier(HEALTH_MODIFIER_UUID);

        if (multiplier > 1.0D) {
            maxHealth.addPermanentModifier(new AttributeModifier(
                    HEALTH_MODIFIER_UUID,
                    "Hostile Mob Health Multiplier",
                    multiplier - 1.0D,
                    AttributeModifier.Operation.MULTIPLY_TOTAL
            ));
        }

        float newMaximum = entity.getMaxHealth();
        if (oldMaximum > 0.0F && newMaximum > 0.0F) {
            float percentage = Math.max(0.0F, Math.min(1.0F, oldHealth / oldMaximum));
            entity.setHealth(newMaximum * percentage);
        }
    }

    private static Path getConfigFile() {
        Path result = configFile;
        if (result == null) {
            synchronized (MobHealthMultiplier.class) {
                result = configFile;
                if (result == null) {
                    result = FMLPaths.CONFIGDIR.get()
                            .resolve(CONFIG_FILE_NAME)
                            .toAbsolutePath()
                            .normalize();
                    configFile = result;
                }
            }
        }
        return result;
    }

    private static LoadResult loadConfiguration(boolean createIfMissing) {
        Path path = getConfigFile();

        try {
            if (createIfMissing) {
                ensureConfigurationExists();
            }

            Properties properties = new Properties();
            try (InputStream input = Files.newInputStream(path)) {
                properties.load(input);
            }

            double parsed = Double.parseDouble(
                    properties.getProperty("multiplier", "2.0").trim());
            if (!isValidMultiplier(parsed)) {
                throw new IllegalArgumentException(
                        "multiplier must be between 1.0 and 1000.0");
            }

            healthMultiplier = parsed;
            return new LoadResult(true,
                    "Loaded multiplier x" + formatMultiplier(parsed) + " from " + path + ".");
        } catch (IOException | IllegalArgumentException error) {
            return new LoadResult(false,
                    "Could not load " + path + ": " + error.getMessage());
        }
    }

    private static void ensureConfigurationExists() throws IOException {
        Path path = getConfigFile();
        Path parent = path.getParent();

        if (parent != null) {
            Files.createDirectories(parent);
        }
        if (!Files.exists(path)) {
            saveConfiguration(healthMultiplier);
        }
    }

    private static void saveConfiguration(double multiplier) throws IOException {
        Path path = getConfigFile();
        Path parent = path.getParent();

        if (parent != null) {
            Files.createDirectories(parent);
        }

        Properties properties = new Properties();
        properties.setProperty("multiplier", formatMultiplier(multiplier));

        try (OutputStream output = Files.newOutputStream(path)) {
            properties.store(output,
                    "Hostile Mob Health Multiplier\n"
                            + "Only hostile mobs are affected.\n"
                            + "1.0 = vanilla, 1.5 = +50%, 2.0 = double.\n"
                            + "Commands: /mobhealth get, set, reload, apply, config");
        }
    }

    private static boolean isValidMultiplier(double value) {
        return Double.isFinite(value) && value >= 1.0D && value <= 1000.0D;
    }

    private static String formatMultiplier(double value) {
        if (value == Math.rint(value)) {
            return Long.toString(Math.round(value)) + ".0";
        }
        return Double.toString(value);
    }

    private static void printEntityErrorOnce(Throwable error) {
        if (!errorPrinted) {
            errorPrinted = true;
            System.err.println("[MobHealthMultiplier] Could not modify hostile mob health: "
                    + error.getClass().getSimpleName() + ": " + error.getMessage());
            error.printStackTrace(System.err);
        }
    }

    private record LoadResult(boolean success, String message) {
    }
}
