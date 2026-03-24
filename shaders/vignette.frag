#version 320 es
precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec2 center = uv - 0.5;
    float dist = length(center) * 1.4;
    float vignette = smoothstep(0.5, 1.2, dist);
    float alpha = vignette * 0.45;
    fragColor = vec4(0.18, 0.12, 0.08, alpha);
}
