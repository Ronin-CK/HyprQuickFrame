/*
 * Copyright (c) 2025 JamDon2
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 selectionRect; // (x, y, width, height)
    float dimOpacity;
    vec2 screenSize;
    float borderRadius;
    float outlineThickness;
};

float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec2 halfSize = selectionRect.zw / 2.0;
    vec2 center = selectionRect.xy + halfSize;
    vec2 pixelPos = qt_TexCoord0 * screenSize;
    vec2 p = pixelPos - center;

    float dist = sdRoundedBox(p, halfSize, borderRadius);

    bool insideFilledArea = dist <= 0.0;

    bool insideOutline = dist > 0.0 && dist <= outlineThickness;

    if (insideFilledArea) {
        fragColor = vec4(0.0);
    } else if (insideOutline) {
        fragColor = vec4(1.0, 1.0, 1.0, 1.0 * qt_Opacity);
    } else {
        fragColor = vec4(0.0, 0.0, 0.0, dimOpacity * qt_Opacity);
    }
}
