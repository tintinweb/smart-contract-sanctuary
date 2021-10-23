//SPDX-License-Identifier: Unlicense
/// @title: Quilt generator library
/// @author: Quilt stitcher
/*
++++++ -  - - - - - - - - - - - - - - +++ - - - - - - - - - - - - - - - - ++++++
.                                                                              .
.                                 quilts.art                                   .
.                             We like the Quilts!                              .
.                                                                              .
++++++ -  - - - - - - - - - - - - - - +++ - - - - - - - - - - - - - - - - ++++++
.                                                                              .
.                                                                              .
.           =##%%%%+    +%%%%%%+    +%%%%%%+    +%%%%%%+    +%%%%##=           .
.          :%%%%%%%%%%%+%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*%%%%%%%%%%%%:          .
.        :#%%%%%%%%%%%+-%%%%%%%%%%%%%%+-%%%%%%%%%%%%%%+-%%%%%%%%%%%%%#.        .
.     -%%%%%%%%%%%%%%=--%%%%%%%%%%%%%=--%%%%%%%%%%%%%=--%%%%%%%%%%%%%+#%%-     .
.     %%%%%%%%%%%%%#=---%%%%%%%%%%%#=---%%%%%%%%%%%#=---%%%%%%%%%%%#=-%%%%     .
.     %%%%%%%%%%%%#-----%%%%%%%%%%#-----%%%%%%%%%%#-----%%%%%%%%%%#---%%%%     .
.     *%%%%%%%%%%*------%%%%%%%%%*------%%%%%%%%%*------%%%%%%%%%*----#%%*     .
.       %%%%%%%%*-------%%%%%%%%*-------%%%%%%%%*-------%%%%%%%%*-------       .
.       %%%%%%%+--------%%%%%%%+--------%%%%%%%+--------%%%%%%%+--------       .
.     *%%%%%%%+---------%%%%%%+---------%%%%%%+---------%%%%%%+-------*%%*     .
.     %%%%%%%=----------%%%%%=----------%%%%%=----------%%%%%=--------%%%%     .
.     %%%%%#=-----------%%%#=-----------%%%#=-----------%%%#=---------%%%%     .
.     %%%%#-------------%%#-------------%%#-------------%%#-----------%%%%     .
.     *%%*--------------%*--------------%*--------------%*------------*%%*     .
.       *---------------*---------------*---------------*---------------       .
.                                                                              .
.     *%%*                                                            *%%*     .
.     %%%%                                                            %%%%     .
.     %%%%                                                            %%%%     .
.     %%%%                                                            %%%%     .
.     *%%*           -+**+-                          -+**+-           *%%*     .
.                   *%%%%%%*                        *%%%%%%*                   .
.                   *%%%%%%*                        *%%%%%%*                   .
.     *%%*           -+**+-                          -+**+-           *%%*     .
.     %%%%                                                            %%%%     .
.     %%%%                                                            %%%%     .
.     -%%*                                                            *%%-     .
.                                                                              .
.           *%%%%%%+    +%%%%%%+    +%%%%%%+    +%%%%%%+    +%%%%%%*           .
.           =##%%%%+    +%%%%%%+    +%%%%%%+    +%%%%%%+    +%%%%##=           .
.                                                                              .
.                                                                              .
++++++ -  - - - - - - - - - - - - - - +++ - - - - - - - - - - - - - - - - ++++++
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library QuiltGenerator {
    struct QuiltStruct {
        uint256[5][5] patches;
        uint256 quiltX;
        uint256 quiltY;
        uint256 quiltW;
        uint256 quiltH;
        uint256 xOff;
        uint256 yOff;
        uint256 maxX;
        uint256 maxY;
        uint256 patchXCount;
        uint256 patchYCount;
        uint256 roundness;
        uint256 themeIndex;
        uint256 backgroundIndex;
        uint256 backgroundThemeIndex;
        uint256 calmnessFactor;
        bool includesSpecialPatch;
        bool hovers;
        bool animatedBg;
    }

    struct RandValues {
        uint256 x;
        uint256 y;
        uint256 roundness;
        uint256 theme;
        uint256 bg;
        uint256 cf;
        uint256 spX;
        uint256 spY;
    }

    function getQuiltForSeed(string memory seed)
        external
        pure
        returns (QuiltStruct memory, string memory)
    {
        QuiltStruct memory quilt;
        RandValues memory rand;

        // Determine how big the quilt is
        rand.x = random(seed, "X") % 100;
        rand.y = random(seed, "Y") % 100;

        if (rand.x < 1) {
            quilt.patchXCount = 1;
        } else if (rand.x < 10) {
            quilt.patchXCount = 2;
        } else if (rand.x < 60) {
            quilt.patchXCount = 3;
        } else if (rand.x < 90) {
            quilt.patchXCount = 4;
        } else {
            quilt.patchXCount = 5;
        }

        if (quilt.patchXCount == 1) {
            quilt.patchYCount = 1;
        } else if (rand.y < 10) {
            quilt.patchYCount = 2;
        } else if (rand.y < 60) {
            quilt.patchYCount = 3;
        } else if (rand.y < 90) {
            quilt.patchYCount = 4;
        } else {
            quilt.patchYCount = 5;
        }

        if (quilt.patchXCount == 2 && quilt.patchYCount == 5) {
            quilt.patchXCount = 3;
        }
        if (quilt.patchYCount == 2 && quilt.patchXCount == 5) {
            quilt.patchYCount = 3;
        }

        // Patch selection
        quilt.includesSpecialPatch = random(seed, "ISP") % 4000 > 3996;
        rand.spX = random(seed, "SPX") % quilt.patchXCount;
        rand.spY = random(seed, "SPY") % quilt.patchYCount;
        for (uint256 col = 0; col < quilt.patchXCount; col++) {
            for (uint256 row = 0; row < quilt.patchYCount; row++) {
                quilt.patches[col][row] =
                    random(seed, string(abi.encodePacked("P", col, row))) %
                    15;

                if (quilt.includesSpecialPatch) {
                    quilt.patches[rand.spX][rand.spY] = 15;
                }
            }
        }

        // Coordinates and dimensions for the quilts
        quilt.maxX = 64 * quilt.patchXCount + (quilt.patchXCount - 1) * 4;
        quilt.maxY = 64 * quilt.patchYCount + (quilt.patchYCount - 1) * 4;
        quilt.xOff = (500 - quilt.maxX) / 2;
        quilt.yOff = (500 - quilt.maxY) / 2;
        quilt.quiltW = quilt.maxX + 32;
        quilt.quiltH = quilt.maxY + 32;
        quilt.quiltX = quilt.xOff + 0 - 16;
        quilt.quiltY = quilt.yOff + 0 - 16;

        // Patch roundness
        rand.roundness = random(seed, "R") % 100;
        if (rand.roundness < 70) {
            quilt.roundness = 8;
        } else if (rand.roundness < 90) {
            quilt.roundness = 16;
        } else {
            quilt.roundness = 0;
        }

        // Color theme
        rand.theme = random(seed, "T") % 1000;
        if (rand.theme < 115) {
            quilt.themeIndex = 0;
        } else if (rand.theme < 230) {
            quilt.themeIndex = 1;
        } else if (rand.theme < 345) {
            quilt.themeIndex = 2;
        } else if (rand.theme < 460) {
            quilt.themeIndex = 3;
        } else if (rand.theme < 575) {
            quilt.themeIndex = 4;
        } else if (rand.theme < 690) {
            quilt.themeIndex = 5;
        } else if (rand.theme < 805) {
            quilt.themeIndex = 6;
        } else if (rand.theme < 930) {
            quilt.themeIndex = 7;
        } else if (rand.theme < 990) {
            quilt.themeIndex = 8;
        } else {
            quilt.themeIndex = 9;
        }

        quilt.backgroundThemeIndex = random(seed, "SBGT") % 100 > 33
            ? random(seed, "SBGT") % 10
            : quilt.themeIndex;

        // Background variant
        rand.bg = random(seed, "BG") % 100;
        if (rand.bg < 70) {
            quilt.backgroundIndex = 0;
        } else if (rand.bg < 80) {
            quilt.backgroundIndex = 1;
        } else if (rand.bg < 90) {
            quilt.backgroundIndex = 2;
        } else {
            quilt.backgroundIndex = 3;
        }

        // How calm or wavey a quilt is
        rand.cf = random(seed, "CF") % 100;
        if (rand.cf < 50) {
            quilt.calmnessFactor = 1;
        } else if (rand.cf < 70) {
            quilt.calmnessFactor = 2;
        } else if (rand.cf < 95) {
            quilt.calmnessFactor = 3;
        } else {
            quilt.calmnessFactor = 4;
        }

        // Animations
        quilt.hovers = random(seed, "H") % 100 > 90;
        quilt.animatedBg = random(seed, "ABG") % 100 > 70;

        string[4][10] memory colors = [
            ["#5c457b", "#ff8fa4", "#f9bdbd", "#fbced6"],
            ["#006d77", "#ffafcc", "#ffe5ef", "#bde0fe"],
            ["#3d405b", "#f2cc8f", "#e07a5f", "#f4f1de"],
            ["#333d29", "#656d4a", "#dda15e", "#c2c5aa"],
            ["#6d2e46", "#d5b9b2", "#a26769", "#ece2d0"],
            ["#006d77", "#83c5be", "#ffddd2", "#edf6f9"],
            ["#351f39", "#726a95", "#719fb0", "#a0c1b8"],
            ["#472e2a", "#e78a46", "#fac459", "#fde3ae"],
            ["#0d1b2a", "#2f4865", "#7b88a7", "#b4c0d0"],
            ["#222222", "#eeeeee", "#bbbbbb", "#eeeeee"]
        ];

        string[16] memory patches = [
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M0 0h64v32H0z"/><path fill="url(#c2)" d="M0 32 16 0v32H0Zm16 0L32 0v32H16Zm16 0L48 0v32H32Zm16 0L64 0v32H48Z"/><circle cx="16" cy="48" r="4" fill="url(#c1)"/><circle cx="48" cy="48" r="4" fill="url(#c1)"/>',
            '<path fill="url(#c2)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M32 0h32v64H32z"/><path fill="url(#c3)" d="M0 64 64 0v64H0Z"/><circle cx="46" cy="46" r="10" fill="url(#c2)"/>',
            '<path fill="url(#c2)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="m52 16 8-16h16l-8 16v16l8 16v16H60V48l-8-16V16Zm-64 0 8-16h16L4 16v16l8 16v16H-4V48l-8-16V16Z"/><path fill="url(#c3)" d="m4 16 8-16h16l-8 16v16l8 16v16H12V48L4 32V16Zm32 0 8-16h16l-8 16v16l8 16v16H44V48l-8-16V16Z"/>',
            '<path fill="url(#c1)" d="M0 0h64v64H0z"/><path fill="url(#c3)" d="M0 60h64v8H0zm0-16h64v8H0zm0-16h64v8H0zm0-16h64v8H0zM0-4h64v8H0z"/>',
            '<path fill="url(#c1)" d="M0 0h64v64H0z"/><path fill="url(#c3)" d="M16 0H8L0 8v8L16 0Zm16 0h-8L0 24v8L32 0Zm16 0h-8L0 40v8L48 0Zm16 0h-8L0 56v8L64 0Zm0 16V8L8 64h8l48-48Zm0 16v-8L24 64h8l32-32Zm0 16v-8L40 64h8l16-16Zm0 16v-8l-8 8h8Z"/>',
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M0 64 32 0v64H0Zm32 0L64 0v64H32Z"/>',
            '<path fill="url(#c1)" d="M0 0h64v64H0z"/><path fill="url(#c3)" d="M0 64 64 0v64H0Z"/>',
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M0 16V0h64L48 16V0L32 16V0L16 16V0L0 16Z"/><path fill="url(#c2)" d="M0 48V32h64L48 48V32L32 48V32L16 48V32L0 48Z"/>',
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M0 0h48v48H0z"/><path fill="url(#c2)" d="M0 48 48 0v48H0Z"/><circle cx="23" cy="25" r="8" fill="url(#c3)"/>',
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M0 0h32v32H0zm32 32h32v32H32z"/>',
            '<path fill="url(#c1)" d="M0 0h64v64H0z"/><path fill="url(#c3)" d="M16 0 0 16v16l16-16 16 16 16-16 16 16V16L48 0 32 16 16 0Zm0 32L0 48v16l16-16 16 16 16-16 16 16V48L48 32 32 48 16 32Z"/>',
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M8 8h40v8H8z"/><path fill="url(#c2)" d="M24 32h8v8h-8zm8-8h8v8h-8z"/><path fill="url(#c1)" d="M24 24h8v8h-8zm8 8h8v8h-8zM16 48h40v8H16z"/><path fill="url(#c2)" d="M8 16h8v40H8zm40-8h8v40h-8z"/>',
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="m24 4 8 8-8 8V4Zm0 40 8 8-8 8V44Zm-4-20-8 8-8-8h16Zm40 0-8 8-8-8h16ZM40 4l-8 8 8 8V4Zm0 40-8 8 8 8V44Zm-20-4-8-8-8 8h16Zm40 0-8-8-8 8h16Z"/><path fill="url(#c2)" d="M24 24h16v16H24z"/>',
            '<path fill="url(#c1)" d="M0 0h64v64H0z"/><path fill="url(#c2)" d="m32 0 16 16-16 16V0Zm0 64L16 48l16-16v32ZM48 0l16 16-16 16V0ZM16 64 .0000014 48 16 32v32Z"/><path fill="url(#c3)" d="M0 16 16 2e-7 32 16H0Zm64 32L48 64 32 48h32ZM32 32 16 16 0 32h32Zm0 0 16 16 16-16H32Z"/>',
            '<path fill="url(#c2)" d="M0 0h64v64H0z"/><path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c2)" d="M32 32-.0000014.0000019 32 5e-7V32Zm0 0 32 32H32V32Z"/><path fill="url(#c1)" d="M32 32-.00000381 64l.0000028-32H32Zm0 0L64 0v32H32Z"/>',
            '<rect width="64" height="64" fill="url(#c2)"/><path fill="url(#c1)" d="M9 50v14h46V50h-2v-6h-2v-6h-2v-4h-2v-2h-4v2h-2v4H23v-4h-2v-2h-4v2h-2v4h-2v6h-2v6H9Z"/><path fill="url(#c3)" d="M11 50v14h42V50h-2v-6h-2v-6h-2v-4h-4v4h-2v2H23v-2h-2v-4h-4v4h-2v6h-2v6h-2Z"/><path fill="url(#c2)" d="M23 44v-4h4v4h-4Zm6 0v-4h6v4h-6Zm8 0v-4h4v4h-4ZM13 54h-2v8h2v-8Zm38 8v-8h2v8h-2Z"/><path fill="url(#c1)" d="M15 48v-2h2v2h2v2h-2v2h-2v-2h2v-2h-2Zm6 2v-4h4v4h-4Zm8 2v-2h2v-2h2v2h2v2h-6Zm10-2v-4h4v4h-4Zm8-4h2v2h-2v2h2v2h-2v-2h-2v-2h2v-2Z"/>'
        ];

        string[4] memory backgrounds = [
            string(
                abi.encodePacked(
                    '<pattern id="bp" width="64" height="64" patternUnits="userSpaceOnUse"><circle cx="32" cy="32" r="8" fill="transparent" stroke="url(#c1)" stroke-width="1" opacity=".6"/></pattern><filter id="bf"><feTurbulence type="fractalNoise" baseFrequency="0.2" numOctaves="1" seed="',
                    seed,
                    '"/><feDisplacementMap in="SourceGraphic" xChannelSelector="B" scale="200"/></filter><g filter="url(#bf)"><rect x="-50%" y="-50%" width="200%" height="200%" fill="url(#bp)">',
                    quilt.animatedBg
                        ? '<animateTransform attributeName="transform" type="translate" dur="4s" values="0,0; 0,64;"  repeatCount="indefinite"/>'
                        : "",
                    "</rect></g>"
                )
            ),
            string(
                abi.encodePacked(
                    '<pattern id="bp" width="128" height="128" patternUnits="userSpaceOnUse"><path d="m64 16 32 32H64V16ZM128 16l32 32h-32V16ZM0 16l32 32H0V16ZM128 76l-32 32h32V76ZM64 76l-32 32h32V76Z" fill="url(#c2)"/></pattern><filter id="bf"><feTurbulence type="fractalNoise" baseFrequency="0.002" numOctaves="1" seed="',
                    seed,
                    '"/><feDisplacementMap in="SourceGraphic" scale="100"/></filter><g filter="url(#bf)"><rect x="-50%" y="-50%" width="200%" height="200%" fill="url(#bp)" opacity=".2">',
                    quilt.animatedBg
                        ? '<animateTransform attributeName="transform" type="translate" dur="4s" values="0,0; 0,128;" repeatCount="indefinite"/>'
                        : "",
                    "</rect></g>"
                )
            ),
            string(
                abi.encodePacked(
                    '<pattern id="bp" width="64" height="64" patternUnits="userSpaceOnUse"><path d="M32 0L0 32V64L32 32L64 64V32L32 0Z" fill="url(#c1)" opacity=".1"/></pattern><filter id="bf"><feTurbulence type="fractalNoise" baseFrequency="0.004" numOctaves="1" seed="',
                    seed,
                    '"/><feDisplacementMap in="SourceGraphic" scale="200"/></filter><g filter="url(#bf)"><rect x="-50%" y="-50%" width="200%" height="200%" fill="url(#bp)">',
                    quilt.animatedBg
                        ? '<animateTransform attributeName="transform" type="translate" dur="4s" values="0,0; -128,0;" repeatCount="indefinite"/>'
                        : "",
                    "</rect></g>"
                )
            ),
            string(
                abi.encodePacked(
                    '<pattern id="bp" width="80" height="40" patternUnits="userSpaceOnUse"><path d="M0 20a20 20 0 1 1 0 1M40 0a20 20 0 1 0 40 0m0 40a20 20 0 1 0 -40 0" fill="url(#c2)" opacity=".2"/></pattern><filter id="bf"><feTurbulence type="fractalNoise" baseFrequency="0.02" numOctaves="1" seed="',
                    seed,
                    '"/><feDisplacementMap in="SourceGraphic" scale="200"/></filter><g filter="url(#bf)"><rect x="-50%" y="-50%" width="200%" height="200%" fill="url(#bp)">',
                    quilt.animatedBg
                        ? '<animateTransform attributeName="transform" type="translate" dur="4s" values="0,0; 0,-80;" repeatCount="indefinite"/>'
                        : "",
                    "</rect></g>"
                )
            )
        ];

        // Build the SVG from various parts
        string[7] memory svgParts;

        for (uint256 col = 0; col < quilt.patchXCount; col++) {
            for (uint256 row = 0; row < quilt.patchYCount; row++) {
                uint256 x = quilt.xOff + 68 * col;
                uint256 y = quilt.yOff + 68 * row;
                uint256 patchPartIndex = quilt.patches[col][row];

                // Patch masks
                svgParts[0] = string(
                    abi.encodePacked(
                        svgParts[0],
                        '<mask id="s',
                        Strings.toString(col + 1),
                        Strings.toString(row + 1),
                        '"><rect rx="',
                        Strings.toString(quilt.roundness),
                        '" x="',
                        Strings.toString(x),
                        '" y="',
                        Strings.toString(y),
                        '" width="64" height="64" fill="white"/></mask>'
                    )
                );

                // Patches
                svgParts[5] = string(
                    abi.encodePacked(
                        svgParts[5],
                        '<g mask="url(#s',
                        Strings.toString(col + 1),
                        Strings.toString(row + 1),
                        ')"><g transform="translate(',
                        Strings.toString(x),
                        " ",
                        Strings.toString(y),
                        ')">',
                        patches[patchPartIndex],
                        "</g></g>"
                    )
                );

                // Patch stitches
                svgParts[6] = string(
                    abi.encodePacked(
                        svgParts[6],
                        '<rect rx="',
                        Strings.toString(quilt.roundness),
                        '" stroke-width="2" stroke-linecap="round" stroke="url(#c1)" stroke-dasharray="4 4" x="',
                        Strings.toString(x),
                        '" y="',
                        Strings.toString(y),
                        '" width="64" height="64" fill="transparent"/>'
                    )
                );
            }
        }

        // Color theme
        svgParts[1] = string(
            abi.encodePacked(
                '<linearGradient id="c1"><stop stop-color="',
                colors[quilt.themeIndex][0],
                '"/></linearGradient><linearGradient id="c2"><stop stop-color="',
                colors[quilt.themeIndex][1],
                '"/></linearGradient><linearGradient id="c3"><stop stop-color="',
                colors[quilt.themeIndex][2],
                '"/></linearGradient><linearGradient id="c4"><stop stop-color="',
                colors[quilt.backgroundThemeIndex][3],
                '"/></linearGradient>'
            )
        );

        // Image background
        svgParts[2] = backgrounds[quilt.backgroundIndex];

        // Quilt shadow
        svgParts[3] = string(
            abi.encodePacked(
                '<rect transform="translate(',
                Strings.toString(quilt.quiltX + 8),
                " ",
                Strings.toString(quilt.quiltY + 8),
                ')" x="0" y="0" width="',
                Strings.toString(quilt.quiltW),
                '" height="',
                Strings.toString(quilt.quiltH),
                '" rx="',
                Strings.toString(
                    quilt.roundness == 0 ? 0 : quilt.roundness + 8
                ),
                '" fill="url(#c1)"/>'
            )
        );

        // Quilt background
        svgParts[4] = string(
            abi.encodePacked(
                '<rect x="',
                Strings.toString(quilt.quiltX),
                '" y="',
                Strings.toString(quilt.quiltY),
                '" width="',
                Strings.toString(quilt.quiltW),
                '" height="',
                Strings.toString(quilt.quiltH),
                '" rx="',
                Strings.toString(
                    quilt.roundness == 0 ? 0 : quilt.roundness + 8
                ),
                '" fill="url(#c2)" stroke="url(#c1)" stroke-width="2"/>'
            )
        );

        string memory svg = string(
            abi.encodePacked(
                '<svg width="500" height="500" viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg"><defs>',
                svgParts[0], // Patch masks
                svgParts[1], // Color theme
                '</defs><rect width="500" height="500" fill="url(#c4)"/>',
                svgParts[2], // Image background
                '<filter id="f" x="-50%" y="-50%" width="200%" height="200%"><feTurbulence baseFrequency="',
                quilt.calmnessFactor * 3 >= 10 ? "0.0" : "0.00",
                Strings.toString(quilt.calmnessFactor * 3),
                '" seed="',
                seed,
                '"/><feDisplacementMap in="SourceGraphic" scale="10"/></filter><g><g filter="url(#f)">',
                svgParts[3] // Quilt shadow
            )
        );

        svg = string(
            abi.encodePacked(
                svg,
                quilt.hovers
                    ? '<animateTransform attributeName="transform" type="scale" additive="sum" dur="4s" values="1 1; 1.005 1.02; 1 1;" calcMode="spline" keySplines="0.45, 0, 0.55, 1; 0.45, 0, 0.55, 1;" repeatCount="indefinite"/>'
                    : "",
                '</g><g filter="url(#f)">',
                svgParts[4], // Quilt background
                svgParts[5], // Patches
                svgParts[6], // Patch stitches
                quilt.hovers
                    ? '<animateTransform attributeName="transform" type="translate" dur="4s" values="0,0; -4,-16; 0,0;" calcMode="spline" keySplines="0.45, 0, 0.55, 1; 0.45, 0, 0.55, 1;" repeatCount="indefinite"/>'
                    : "",
                "</g></g></svg>"
            )
        );

        return (quilt, svg);
    }

    function random(string memory seed, string memory key)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(key, seed)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}