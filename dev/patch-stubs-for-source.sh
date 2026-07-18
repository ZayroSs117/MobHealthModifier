#!/usr/bin/env bash
set -euo pipefail
OUT="${1:?usage: patch-stubs-for-source.sh <output-directory>}"

mkdir -p "$OUT/net/minecraft/commands"
cat > "$OUT/net/minecraft/commands/Commands.java" <<'EOF'
package net.minecraft.commands;
import com.mojang.brigadier.arguments.ArgumentType;
import com.mojang.brigadier.builder.LiteralArgumentBuilder;
import com.mojang.brigadier.builder.RequiredArgumentBuilder;
public final class Commands {
    public static LiteralArgumentBuilder<CommandSourceStack> literal(String literal) {
        return LiteralArgumentBuilder.literal(literal);
    }
    public static <T> RequiredArgumentBuilder<CommandSourceStack,T> argument(String name, ArgumentType<T> type) {
        return RequiredArgumentBuilder.argument(name, type);
    }
}
EOF

cat > "$OUT/net/minecraft/commands/CommandSourceStack.java" <<'EOF'
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
    public boolean hasPermission(int level) { return m_6761_(level); }
    public void m_288197_(Supplier<Component> component, boolean broadcast) { messages.add(component.get().toString()); }
    public void sendSuccess(Supplier<Component> component, boolean broadcast) { m_288197_(component, broadcast); }
}
EOF

cat > "$OUT/net/minecraft/network/chat/Component.java" <<'EOF'
package net.minecraft.network.chat;
public class Component {
    private final String text;
    private Component(String text) { this.text = text; }
    public static Component m_237113_(String text) { return new Component(text); }
    public static Component literal(String text) { return m_237113_(text); }
    @Override public String toString() { return text; }
}
EOF

cat > "$OUT/net/minecraft/world/entity/LivingEntity.java" <<'EOF'
package net.minecraft.world.entity;
import net.minecraft.world.entity.ai.attributes.*;
public class LivingEntity extends Entity {
    private final AttributeInstance healthAttribute = new AttributeInstance(20.0);
    private float health = 20.0f;
    public AttributeInstance m_21051_(Attribute attribute) { return attribute == Attributes.f_22276_ ? healthAttribute : null; }
    public AttributeInstance getAttribute(Attribute attribute) { return m_21051_(attribute); }
    public float m_21223_() { return health; }
    public float getHealth() { return m_21223_(); }
    public float m_21233_() { return (float) healthAttribute.value(); }
    public float getMaxHealth() { return m_21233_(); }
    public void m_21153_(float health) { this.health = Math.min(health, m_21233_()); }
    public void setHealth(float health) { m_21153_(health); }
}
EOF

cat > "$OUT/net/minecraft/world/entity/ai/attributes/AttributeInstance.java" <<'EOF'
package net.minecraft.world.entity.ai.attributes;
import java.util.*;
public class AttributeInstance {
    private final double base;
    private final Map<UUID, AttributeModifier> modifiers = new HashMap<>();
    public AttributeInstance(double base) { this.base = base; }
    public void m_22120_(UUID uuid) { modifiers.remove(uuid); }
    public void removeModifier(UUID uuid) { m_22120_(uuid); }
    public void m_22125_(AttributeModifier modifier) { modifiers.put(modifier.uuid, modifier); }
    public void addPermanentModifier(AttributeModifier modifier) { m_22125_(modifier); }
    public double value() {
        double result = base;
        for (AttributeModifier modifier : modifiers.values()) {
            if (modifier.operation == AttributeModifier.Operation.MULTIPLY_TOTAL) result *= 1.0 + modifier.amount;
        }
        return result;
    }
}
EOF

cat > "$OUT/net/minecraft/world/entity/ai/attributes/Attributes.java" <<'EOF'
package net.minecraft.world.entity.ai.attributes;
public final class Attributes {
    public static final Attribute OTHER = new Attribute("attribute.name.generic.armor");
    public static final Attribute f_22276_ = new Attribute("attribute.name.generic.max_health");
    public static final Attribute MAX_HEALTH = f_22276_;
}
EOF
