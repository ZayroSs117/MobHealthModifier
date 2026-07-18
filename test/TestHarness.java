import com.mojang.brigadier.CommandDispatcher;
import io.github.zayross117.mobhealthmultiplier.MobHealthMultiplier;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.decoration.ArmorStand;
import net.minecraft.world.entity.monster.TestMonster;
import net.minecraft.world.entity.player.Player;
import net.minecraftforge.event.RegisterCommandsEvent;
import net.minecraftforge.event.entity.EntityJoinLevelEvent;

import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;

public class TestHarness {
    public static void main(String[] args) throws Exception {
        Path config = Path.of("config", "mob-health-multiplier.properties").toAbsolutePath();
        Files.deleteIfExists(config);

        MobHealthMultiplier mod = new MobHealthMultiplier();
        if (!Files.exists(config)) {
            throw new AssertionError("Config file was not created: " + config);
        }

        ServerLevel level = new ServerLevel();
        TestMonster hostile = new TestMonster();
        mod.onEntityJoin(new EntityJoinLevelEvent(hostile, level));
        assertNear(40.0f, hostile.m_21233_(), "hostile max health");
        assertNear(40.0f, hostile.m_21223_(), "hostile current health");

        // Rejoining must not stack the modifier.
        mod.onEntityJoin(new EntityJoinLevelEvent(hostile, level));
        assertNear(40.0f, hostile.m_21233_(), "hostile max health after rejoin");

        LivingEntity passive = new LivingEntity();
        mod.onEntityJoin(new EntityJoinLevelEvent(passive, level));
        assertNear(20.0f, passive.m_21233_(), "passive max health");

        Player player = new Player();
        mod.onEntityJoin(new EntityJoinLevelEvent(player, level));
        assertNear(20.0f, player.m_21233_(), "player max health");

        ArmorStand stand = new ArmorStand();
        mod.onEntityJoin(new EntityJoinLevelEvent(stand, level));
        assertNear(20.0f, stand.m_21233_(), "armor stand max health");

        CommandDispatcher<CommandSourceStack> dispatcher = new CommandDispatcher<>();
        mod.onRegisterCommands(new RegisterCommandsEvent(dispatcher));
        CommandSourceStack op = new CommandSourceStack(2);

        assertSuccess(dispatcher.execute("mobhealth get", op), "get command");
        assertSuccess(dispatcher.execute("mobhealth set 3", op), "set command");
        assertNear(60.0f, hostile.m_21233_(), "live set max health");
        assertNear(60.0f, hostile.m_21223_(), "live set current health");
        assertProperty(config, "3.0");

        Properties properties = new Properties();
        properties.setProperty("multiplier", "1.5");
        try (OutputStream output = Files.newOutputStream(config)) {
            properties.store(output, "test");
        }
        assertSuccess(dispatcher.execute("mobhealth reload", op), "reload command");
        assertNear(30.0f, hostile.m_21233_(), "live reload max health");
        assertNear(30.0f, hostile.m_21223_(), "live reload current health");

        CommandSourceStack nonOp = new CommandSourceStack(0);
        if (dispatcher.execute("mobhealth set 10", nonOp) != 0) {
            throw new AssertionError("Non-operator could execute the command");
        }
        assertNear(30.0f, hostile.m_21233_(), "non-op did not change health");

        assertSuccess(dispatcher.execute("mobhealth config", op), "config command");
        assertSuccess(dispatcher.execute("mobhealth apply", op), "apply command");

        System.out.println("Messages=" + op.messages);
        System.out.println("TEST OK");
    }

    private static void assertProperty(Path config, String expected) throws Exception {
        Properties properties = new Properties();
        try (InputStream input = Files.newInputStream(config)) {
            properties.load(input);
        }
        String actual = properties.getProperty("multiplier");
        if (!expected.equals(actual)) {
            throw new AssertionError("Expected config multiplier=" + expected + ", actual=" + actual);
        }
    }

    private static void assertSuccess(int result, String label) {
        if (result != 1) {
            throw new AssertionError(label + " failed with result=" + result);
        }
    }

    private static void assertNear(float expected, float actual, String label) {
        if (Math.abs(expected - actual) > 0.001f) {
            throw new AssertionError(label + ": expected=" + expected + ", actual=" + actual);
        }
    }
}
