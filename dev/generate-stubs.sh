#!/usr/bin/env bash
set -euo pipefail
OUT="${1:?usage: generate-stubs.sh <output-directory>}"
rm -rf "$OUT"
mkdir -p "$OUT"

mkdir -p "$OUT/com/mojang/brigadier"
cat > "$OUT/com/mojang/brigadier/Command.java" <<'__MOBHEALTH_STUB__'
package com.mojang.brigadier;
import com.mojang.brigadier.context.CommandContext;
@FunctionalInterface
public interface Command<S> { int run(CommandContext<S> context) throws Exception; }
__MOBHEALTH_STUB__

mkdir -p "$OUT/com/mojang/brigadier"
cat > "$OUT/com/mojang/brigadier/CommandDispatcher.java" <<'__MOBHEALTH_STUB__'
package com.mojang.brigadier;
import com.mojang.brigadier.arguments.DoubleArgumentType;
import com.mojang.brigadier.builder.*;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.tree.LiteralCommandNode;
import java.util.*;
public class CommandDispatcher<S> {
    private LiteralArgumentBuilder<S> root;
    public LiteralCommandNode<S> register(LiteralArgumentBuilder<S> command) { this.root = command; return new LiteralCommandNode<>(); }
    public int execute(String input, S source) throws Exception {
        String[] parts = input.trim().split("\\s+");
        if (parts.length == 0 || root == null || !root.literal().equals(parts[0]) || !root.requirement().test(source)) return 0;
        ArgumentBuilder<S,?> current = root;
        Map<String,Object> args = new HashMap<>();
        for (int i = 1; i < parts.length; i++) {
            ArgumentBuilder<S,?> next = null;
            for (ArgumentBuilder<S,?> child : current.children()) {
                if (child instanceof LiteralArgumentBuilder<?> rawLiteral) {
                    @SuppressWarnings("unchecked")
                    LiteralArgumentBuilder<S> literal = (LiteralArgumentBuilder<S>) rawLiteral;
                    if (literal.literal().equals(parts[i])) { next = child; break; }
                }
                if (child instanceof RequiredArgumentBuilder<?,?> rawRequired) {
                    @SuppressWarnings("unchecked")
                    RequiredArgumentBuilder<S,?> required = (RequiredArgumentBuilder<S,?>) rawRequired;
                    if (required.type() instanceof DoubleArgumentType type) {
                        double value = Double.parseDouble(parts[i]);
                        if (value < type.minimum() || value > type.maximum()) return 0;
                        args.put(required.name(), value);
                        next = child;
                        break;
                    }
                }
            }
            if (next == null) return 0;
            current = next;
        }
        return current.command() == null ? 0 : current.command().run(new CommandContext<>(source, args));
    }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/com/mojang/brigadier"
cat > "$OUT/com/mojang/brigadier/RedirectModifier.java" <<'__MOBHEALTH_STUB__'
package com.mojang.brigadier;
public interface RedirectModifier<S> {}
__MOBHEALTH_STUB__

mkdir -p "$OUT/com/mojang/brigadier/arguments"
cat > "$OUT/com/mojang/brigadier/arguments/ArgumentType.java" <<'__MOBHEALTH_STUB__'
package com.mojang.brigadier.arguments;
public interface ArgumentType<T> {}
__MOBHEALTH_STUB__

mkdir -p "$OUT/com/mojang/brigadier/arguments"
cat > "$OUT/com/mojang/brigadier/arguments/DoubleArgumentType.java" <<'__MOBHEALTH_STUB__'
package com.mojang.brigadier.arguments;
import com.mojang.brigadier.context.CommandContext;
public final class DoubleArgumentType implements ArgumentType<Double> {
    private final double minimum;
    private final double maximum;
    private DoubleArgumentType(double minimum, double maximum) { this.minimum = minimum; this.maximum = maximum; }
    public static DoubleArgumentType doubleArg(double minimum, double maximum) { return new DoubleArgumentType(minimum, maximum); }
    public static double getDouble(CommandContext<?> context, String name) { return ((Number) context.getArgumentRaw(name)).doubleValue(); }
    public double minimum() { return minimum; }
    public double maximum() { return maximum; }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/com/mojang/brigadier/builder"
cat > "$OUT/com/mojang/brigadier/builder/ArgumentBuilder.java" <<'__MOBHEALTH_STUB__'
package com.mojang.brigadier.builder;
import com.mojang.brigadier.Command;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Predicate;
@SuppressWarnings("unchecked")
public abstract class ArgumentBuilder<S,T extends ArgumentBuilder<S,T>> {
    protected final List<ArgumentBuilder<S,?>> children = new ArrayList<>();
    protected Command<S> command;
    protected Predicate<S> requirement = source -> true;
    public T then(ArgumentBuilder<S,?> child) { children.add(child); return (T) this; }
    public T executes(Command<S> command) { this.command = command; return (T) this; }
    public T requires(Predicate<S> requirement) { this.requirement = requirement; return (T) this; }
    public List<ArgumentBuilder<S,?>> children() { return children; }
    public Command<S> command() { return command; }
    public Predicate<S> requirement() { return requirement; }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/com/mojang/brigadier/builder"
cat > "$OUT/com/mojang/brigadier/builder/LiteralArgumentBuilder.java" <<'__MOBHEALTH_STUB__'
package com.mojang.brigadier.builder;
public final class LiteralArgumentBuilder<S> extends ArgumentBuilder<S, LiteralArgumentBuilder<S>> {
    private final String literal;
    private LiteralArgumentBuilder(String literal) { this.literal = literal; }
    public static <S> LiteralArgumentBuilder<S> literal(String literal) { return new LiteralArgumentBuilder<>(literal); }
    public String literal() { return literal; }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/com/mojang/brigadier/builder"
cat > "$OUT/com/mojang/brigadier/builder/RequiredArgumentBuilder.java" <<'__MOBHEALTH_STUB__'
package com.mojang.brigadier.builder;
import com.mojang.brigadier.arguments.ArgumentType;
public final class RequiredArgumentBuilder<S,T> extends ArgumentBuilder<S, RequiredArgumentBuilder<S,T>> {
    private final String name;
    private final ArgumentType<T> type;
    private RequiredArgumentBuilder(String name, ArgumentType<T> type) { this.name = name; this.type = type; }
    public static <S,T> RequiredArgumentBuilder<S,T> argument(String name, ArgumentType<T> type) { return new RequiredArgumentBuilder<>(name, type); }
    public String name() { return name; }
    public ArgumentType<T> type() { return type; }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/com/mojang/brigadier/context"
cat > "$OUT/com/mojang/brigadier/context/CommandContext.java" <<'__MOBHEALTH_STUB__'
package com.mojang.brigadier.context;
import java.util.Map;
public class CommandContext<S> {
    private final S source;
    private final Map<String,Object> arguments;
    public CommandContext(S source, Map<String,Object> arguments) { this.source = source; this.arguments = arguments; }
    public S getSource() { return source; }
    public Object getArgumentRaw(String name) { return arguments.get(name); }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/com/mojang/brigadier/tree"
cat > "$OUT/com/mojang/brigadier/tree/LiteralCommandNode.java" <<'__MOBHEALTH_STUB__'
package com.mojang.brigadier.tree;
public class LiteralCommandNode<S> {
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/commands"
cat > "$OUT/net/minecraft/commands/CommandSourceStack.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.commands;
import net.minecraft.network.chat.Component;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Supplier;
public class CommandSourceStack {
    private final int permission;
    public final List<String> messages = new ArrayList<>();
    public CommandSourceStack(int permission) { this.permission = permission; }
    public boolean m_6761_(int level) { return permission >= level; }
    public void m_288197_(Supplier<Component> component, boolean broadcast) { messages.add(component.get().toString()); }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/network/chat"
cat > "$OUT/net/minecraft/network/chat/Component.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.network.chat;
public class Component {
    private final String text;
    private Component(String text) { this.text = text; }
    public static Component m_237113_(String text) { return new Component(text); }
    @Override public String toString() { return text; }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/server/level"
cat > "$OUT/net/minecraft/server/level/ServerLevel.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.server.level;
public class ServerLevel extends net.minecraft.world.level.Level {}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/world/entity"
cat > "$OUT/net/minecraft/world/entity/Entity.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.world.entity;
public class Entity {}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/world/entity"
cat > "$OUT/net/minecraft/world/entity/LivingEntity.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.world.entity;
import net.minecraft.world.entity.ai.attributes.*;
public class LivingEntity extends Entity {
    private final AttributeInstance healthAttribute = new AttributeInstance(20.0);
    private float health = 20.0f;
    public AttributeInstance m_21051_(Attribute attribute) { return attribute == Attributes.f_22276_ ? healthAttribute : null; }
    public float m_21223_() { return health; }
    public float m_21233_() { return (float) healthAttribute.value(); }
    public void m_21153_(float health) { this.health = Math.min(health, m_21233_()); }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/world/entity/ai/attributes"
cat > "$OUT/net/minecraft/world/entity/ai/attributes/Attribute.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.world.entity.ai.attributes;
public class Attribute {
    private final String id;
    public Attribute(String id) { this.id = id; }
    public String m_22080_() { return id; }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/world/entity/ai/attributes"
cat > "$OUT/net/minecraft/world/entity/ai/attributes/AttributeInstance.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.world.entity.ai.attributes;
import java.util.*;
public class AttributeInstance {
    private final double base;
    private final Map<UUID, AttributeModifier> modifiers = new HashMap<>();
    public AttributeInstance(double base) { this.base = base; }
    public void m_22120_(UUID uuid) { modifiers.remove(uuid); }
    public void m_22125_(AttributeModifier modifier) { modifiers.put(modifier.uuid, modifier); }
    public double value() {
        double result = base;
        for (AttributeModifier modifier : modifiers.values()) {
            if (modifier.operation == AttributeModifier.Operation.MULTIPLY_TOTAL) result *= 1.0 + modifier.amount;
        }
        return result;
    }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/world/entity/ai/attributes"
cat > "$OUT/net/minecraft/world/entity/ai/attributes/AttributeModifier.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.world.entity.ai.attributes;
import java.util.UUID;
public class AttributeModifier {
    public enum Operation { ADDITION, MULTIPLY_BASE, MULTIPLY_TOTAL }
    public final UUID uuid;
    public final double amount;
    public final Operation operation;
    public AttributeModifier(UUID uuid, String name, double amount, Operation operation) {
        this.uuid = uuid; this.amount = amount; this.operation = operation;
    }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/world/entity/ai/attributes"
cat > "$OUT/net/minecraft/world/entity/ai/attributes/Attributes.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.world.entity.ai.attributes;
public final class Attributes {
    public static final Attribute OTHER = new Attribute("attribute.name.generic.armor");
    public static final Attribute f_22276_ = new Attribute("attribute.name.generic.max_health");
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/world/entity/decoration"
cat > "$OUT/net/minecraft/world/entity/decoration/ArmorStand.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.world.entity.decoration;
public class ArmorStand extends net.minecraft.world.entity.LivingEntity {}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/world/entity/monster"
cat > "$OUT/net/minecraft/world/entity/monster/Enemy.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.world.entity.monster;
public interface Enemy {}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/world/entity/monster"
cat > "$OUT/net/minecraft/world/entity/monster/TestMonster.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.world.entity.monster;
public class TestMonster extends net.minecraft.world.entity.LivingEntity implements Enemy {}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/world/entity/player"
cat > "$OUT/net/minecraft/world/entity/player/Player.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.world.entity.player;
public class Player extends net.minecraft.world.entity.LivingEntity {}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraft/world/level"
cat > "$OUT/net/minecraft/world/level/Level.java" <<'__MOBHEALTH_STUB__'
package net.minecraft.world.level;
public class Level {}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraftforge/common"
cat > "$OUT/net/minecraftforge/common/MinecraftForge.java" <<'__MOBHEALTH_STUB__'
package net.minecraftforge.common;
import net.minecraftforge.eventbus.api.IEventBus;
public final class MinecraftForge {
    public static final IEventBus EVENT_BUS = object -> {};
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraftforge/event"
cat > "$OUT/net/minecraftforge/event/RegisterCommandsEvent.java" <<'__MOBHEALTH_STUB__'
package net.minecraftforge.event;
import com.mojang.brigadier.CommandDispatcher;
import net.minecraft.commands.CommandSourceStack;
public class RegisterCommandsEvent {
    private final CommandDispatcher<CommandSourceStack> dispatcher;
    public RegisterCommandsEvent(CommandDispatcher<CommandSourceStack> dispatcher) { this.dispatcher = dispatcher; }
    public CommandDispatcher<CommandSourceStack> getDispatcher() { return dispatcher; }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraftforge/event/entity"
cat > "$OUT/net/minecraftforge/event/entity/EntityJoinLevelEvent.java" <<'__MOBHEALTH_STUB__'
package net.minecraftforge.event.entity;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.level.Level;
public class EntityJoinLevelEvent {
    private final Entity entity; private final Level level;
    public EntityJoinLevelEvent(Entity entity, Level level) { this.entity = entity; this.level = level; }
    public Entity getEntity() { return entity; }
    public Level getLevel() { return level; }
}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraftforge/eventbus/api"
cat > "$OUT/net/minecraftforge/eventbus/api/IEventBus.java" <<'__MOBHEALTH_STUB__'
package net.minecraftforge.eventbus.api;
public interface IEventBus { void register(Object object); }
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraftforge/eventbus/api"
cat > "$OUT/net/minecraftforge/eventbus/api/SubscribeEvent.java" <<'__MOBHEALTH_STUB__'
package net.minecraftforge.eventbus.api;
import java.lang.annotation.*;
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface SubscribeEvent {}
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraftforge/fml/common"
cat > "$OUT/net/minecraftforge/fml/common/Mod.java" <<'__MOBHEALTH_STUB__'
package net.minecraftforge.fml.common;
import java.lang.annotation.*;
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface Mod { String value(); }
__MOBHEALTH_STUB__

mkdir -p "$OUT/net/minecraftforge/fml/loading"
cat > "$OUT/net/minecraftforge/fml/loading/FMLPaths.java" <<'__MOBHEALTH_STUB__'
package net.minecraftforge.fml.loading;
import java.nio.file.Path;
public enum FMLPaths {
    CONFIGDIR;
    public Path get() { return Path.of("config"); }
}
__MOBHEALTH_STUB__
