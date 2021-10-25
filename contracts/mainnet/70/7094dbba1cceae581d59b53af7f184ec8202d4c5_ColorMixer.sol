/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice Interpolation between ColorAnchors to generate a colormap.
 * @dev A color anchor is encoded composed of four uint8 numbers in the order
 * `colorAnchor = | red | green | blue | position |`. Every `uint32` typed 
 * variable in the following code will correspond to such anchors, while 
 * `uint24`s correspond to rgb colors.
 * @author David Huber (@cxkoda)
 */
library ColorMixer {
    /**
     * @dev The internal fixed-point accuracy
     */
    uint8 private constant PRECISION = 32;
    uint256 private constant ONE = 2**32;

    /**
     * @notice Interpolate linearily between two colors.
     * @param fraction Fixed-point number in [0,1] giving the relative
     * contribution of `left` (0) and `right` (1).
     * The interpolation follows the equation 
     * `color = fraction * right + (1 - fraction) * left`.
     */
    function interpolate(
        uint24 left,
        uint24 right,
        uint256 fraction
    ) internal pure returns (uint24 color) {
        assembly {
            color := shr(
                PRECISION,
                add(
                    mul(fraction, and(shr(16, right), 0xff)),
                    mul(sub(ONE, fraction), and(shr(16, left), 0xff))
                )
            )
            color := add(
                shl(8, color),
                shr(
                    PRECISION,
                    add(
                        mul(fraction, and(shr(8, right), 0xff)),
                        mul(sub(ONE, fraction), and(shr(8, left), 0xff))
                    )
                )
            )
            color := add(
                shl(8, color),
                shr(
                    PRECISION,
                    add(
                        mul(fraction, and(right, 0xff)),
                        mul(sub(ONE, fraction), and(left, 0xff))
                    )
                )
            )
        }
    }

    /**
     * @notice Generate a colormap from a list of anchors.
     * @dev Anchors have to be sorted by position.
     */
    function getColormap(uint32[] calldata anchors)
        external
        pure
        returns (bytes memory colormap)
    {
        require(anchors.length > 0);
        colormap = new bytes(768);
        uint256 offset = 0;
        // Left extrapolation (below the leftmost anchor)
        {
            uint32 anchor = anchors[0];
            uint8 anchorPos = uint8(anchor & 0xff);
            for (uint32 position = 0; position < anchorPos; position++) {
                colormap[offset++] = bytes1(uint8((anchor >> 24) & 0xff));
                colormap[offset++] = bytes1(uint8((anchor >> 16) & 0xff));
                colormap[offset++] = bytes1(uint8((anchor >> 8) & 0xff));
            }
        }
        // Interpolation
        if (anchors.length > 1) {
            for (uint256 idx = 0; idx < anchors.length - 1; idx++) {
                uint32 left = anchors[idx];
                uint32 right = anchors[idx + 1];
                uint8 leftPosition = uint8(left & 0xff);
                uint8 rightPosition = uint8(right & 0xff);

                if (leftPosition == rightPosition) {
                    continue;
                }
                
                uint256 rangeInv = ONE / (rightPosition - leftPosition);
                for (
                    uint256 position = leftPosition;
                    position < rightPosition;
                    position++
                ) {
                    uint256 fraction = (position - leftPosition) * rangeInv;
                    uint32 interpolated = interpolate(
                        uint24(left >> 8),
                        uint24(right >> 8),
                        fraction
                    );
                    colormap[offset++] = bytes1(
                        uint8((interpolated >> 16) & 0xff)
                    );
                    colormap[offset++] = bytes1(
                        uint8((interpolated >> 8) & 0xff)
                    );
                    colormap[offset++] = bytes1(uint8(interpolated & 0xff));
                }
            }
        }
        // Right extrapolation (above the rightmost anchor)
        {
            uint32 anchor = anchors[anchors.length - 1];
            uint8 anchorPos = uint8(anchor & 0xff);
            for (uint256 position = anchorPos; position < 256; position++) {
                colormap[offset++] = bytes1(uint8((anchor >> 24) & 0xff));
                colormap[offset++] = bytes1(uint8((anchor >> 16) & 0xff));
                colormap[offset++] = bytes1(uint8((anchor >> 8) & 0xff));
            }
        }
    }
}