// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "./constants/Colors.sol";

/// @title Eyes SVG generator
library EyesDetail {
    /// @dev Eyes N°1 => Color White/Brown
    function item_1() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.BROWN);
    }

    /// @dev Eyes N°2 => Color White/Gray
    function item_2() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.GRAY);
    }

    /// @dev Eyes N°3 => Color White/Blue
    function item_3() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.BLUE);
    }

    /// @dev Eyes N°4 => Color White/Green
    function item_4() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.GREEN);
    }

    /// @dev Eyes N°5 => Color White/Black
    function item_5() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.BLACK_DEEP);
    }

    /// @dev Eyes N°6 => Color White/Yellow
    function item_6() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.YELLOW);
    }

    /// @dev Eyes N°7 => Color White/Red
    function item_7() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.RED);
    }

    /// @dev Eyes N°8 => Color White/Purple
    function item_8() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.PURPLE);
    }

    /// @dev Eyes N°9 => Color White/Pink
    function item_9() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.PINK);
    }

    /// @dev Eyes N°10 => Color White/White
    function item_10() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.WHITE);
    }

    /// @dev Eyes N°11 => Color Black/Blue
    function item_11() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.BLACK, Colors.BLUE);
    }

    /// @dev Eyes N°12 => Color Black/Yellow
    function item_12() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.BLACK, Colors.YELLOW);
    }

    /// @dev Eyes N°13 => Color Black/White
    function item_13() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.BLACK, Colors.WHITE);
    }

    /// @dev Eyes N°14 => Color Black/Red
    function item_14() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.BLACK, Colors.RED);
    }

    /// @dev Eyes N°15 => Blank White/White
    function item_15() public pure returns (string memory) {
        return eyesNoFillAndBlankPupils(Colors.WHITE, Colors.WHITE);
    }

    /// @dev Eyes N°16 => Blank Black/White
    function item_16() public pure returns (string memory) {
        return eyesNoFillAndBlankPupils(Colors.BLACK_DEEP, Colors.WHITE);
    }

    /// @dev Eyes N°17 => Shine (no-fill)
    function item_17() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        eyesNoFill(Colors.WHITE),
                        '<path fill="#FFEE00" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M161.4,195.1c1.4,7.4,1.4,7.3,8.8,8.8 c-7.4,1.4-7.3,1.4-8.8,8.8c-1.4-7.4-1.4-7.3-8.8-8.8C160,202.4,159.9,202.5,161.4,195.1z"/>',
                        '<path fill="#FFEE00" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M236.1,194.9c1.4,7.4,1.4,7.3,8.8,8.8 c-7.4,1.4-7.3,1.4-8.8,8.8c-1.4-7.4-1.4-7.3-8.8-8.8C234.8,202.3,234.7,202.3,236.1,194.9z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°18 => Stun (no-fill)
    function item_18() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        eyesNoFill(Colors.WHITE),
                        '<path d="M233.6,205.2c0.2-0.8,0.6-1.7,1.3-2.3c0.4-0.3,0.9-0.5,1.3-0.4c0.5,0.1,0.9,0.4,1.2,0.8c0.5,0.8,0.6,1.8,0.6,2.7c0,0.9-0.4,1.9-1.1,2.6c-0.7,0.7-1.7,1.1-2.7,1c-1-0.1-1.8-0.7-2.5-1.2c-0.7-0.5-1.4-1.2-1.9-2c-0.5-0.8-0.8-1.8-0.7-2.8c0.1-1,0.5-1.9,1.1-2.6c0.6-0.7,1.4-1.3,2.2-1.7c1.7-0.8,3.6-1,5.3-0.6c0.9,0.2,1.8,0.5,2.5,1.1c0.7,0.6,1.2,1.5,1.3,2.4c0.3,1.8-0.3,3.7-1.4,4.9c1-1.4,1.4-3.2,1-4.8c-0.2-0.8-0.6-1.5-1.3-2c-0.6-0.5-1.4-0.8-2.2-0.9c-1.6-0.2-3.4,0-4.8,0.7c-1.4,0.7-2.7,2-2.8,3.5c-0.2,1.5,0.9,3,2.2,4c0.7,0.5,1.3,1,2.1,1.1c0.7,0.1,1.5-0.2,2.1-0.7c0.6-0.5,0.9-1.3,1-2.1c0.1-0.8,0-1.7-0.4-2.3c-0.2-0.3-0.5-0.6-0.8-0.7c-0.4-0.1-0.8,0-1.1,0.2C234.4,203.6,233.9,204.4,233.6,205.2z"/>',
                        '<path d="M160.2,204.8c0.7-0.4,1.6-0.8,2.5-0.7c0.4,0,0.9,0.3,1.2,0.7c0.3,0.4,0.3,0.9,0.2,1.4c-0.2,0.9-0.8,1.7-1.5,2.3c-0.7,0.6-1.6,1.1-2.6,1c-1,0-2-0.4-2.6-1.2c-0.7-0.8-0.8-1.8-1-2.6c-0.1-0.9-0.1-1.8,0.1-2.8c0.2-0.9,0.7-1.8,1.5-2.4c0.8-0.6,1.7-1,2.7-1c0.9-0.1,1.9,0.1,2.7,0.4c1.7,0.6,3.2,1.8,4.2,3.3c0.5,0.7,0.9,1.6,1,2.6c0.1,0.9-0.2,1.9-0.8,2.6c-1.1,1.5-2.8,2.4-4.5,2.5c1.7-0.3,3.3-1.3,4.1-2.7c0.4-0.7,0.6-1.5,0.5-2.3c-0.1-0.8-0.5-1.5-1-2.2c-1-1.3-2.4-2.4-3.9-2.9c-1.5-0.5-3.3-0.5-4.5,0.5c-1.2,1-1.5,2.7-1.3,4.3c0.1,0.8,0.2,1.6,0.7,2.2c0.4,0.6,1.2,0.9,1.9,1c0.8,0,1.5-0.2,2.2-0.8c0.6-0.5,1.2-1.2,1.4-1.9c0.1-0.4,0.1-0.8-0.1-1.1c-0.2-0.3-0.5-0.6-0.9-0.6C161.9,204.2,161,204.4,160.2,204.8z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°19 => Squint (no-fill)
    function item_19() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        eyesNoFill(Colors.WHITE),
                        '<path d="M167.3,203.7c0.1,7.7-12,7.7-11.9,0C155.3,196,167.4,196,167.3,203.7z"/>',
                        '<path d="M244.8,205.6c-1.3,7.8-13.5,5.6-12-2.2C234.2,195.6,246.4,197.9,244.8,205.6z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°20 => Shock (no-fill)
    function item_20() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        eyesNoFill(Colors.WHITE),
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M163.9,204c0,2.7-4.2,2.7-4.1,0C159.7,201.3,163.9,201.3,163.9,204z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M236.7,204c0,2.7-4.2,2.7-4.1,0C232.5,201.3,236.7,201.3,236.7,204z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°21 => Cat (no-fill)
    function item_21() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        eyesNoFill(Colors.WHITE),
                        '<path d="M238.4,204.2c0.1,13.1-4.5,13.1-4.5,0C233.8,191.2,238.4,191.2,238.4,204.2z"/>',
                        '<path d="M164.8,204.2c0.1,13-4.5,13-4.5,0C160.2,191.2,164.8,191.2,164.8,204.2z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°22 => Ether (no-fill)
    function item_22() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        eyesNoFill(Colors.WHITE),
                        '<path d="M161.7,206.4l-4.6-2.2l4.6,8l4.6-8L161.7,206.4z"/>',
                        '<path d="M165.8,202.6l-4.1-7.1l-4.1,7.1l4.1-1.9L165.8,202.6z"/>',
                        '<path d="M157.9,203.5l3.7,1.8l3.8-1.8l-3.8-1.8L157.9,203.5z"/>',
                        '<path d="M236.1,206.6l-4.6-2.2l4.6,8l4.6-8L236.1,206.6z"/>',
                        '<path d="M240.2,202.8l-4.1-7.1l-4.1,7.1l4.1-1.9L240.2,202.8z"/>',
                        '<path d="M232.4,203.7l3.7,1.8l3.8-1.8l-3.8-1.8L232.4,203.7z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°23 => Feels
    function item_23() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M251.1,201.4c0.7,0.6,1,2.2,1,2.7c-0.1-0.4-1.4-1.1-2.2-1.7c-0.2,0.1-0.4,0.4-0.6,0.5c0.5,0.7,0.7,2,0.7,2.5c-0.1-0.4-1.3-1.1-2.1-1.6c-2.7,1.7-6.4,3.2-11.5,3.7c-8.1,0.7-16.3-1.7-20.9-6.4c5.9,3.1,13.4,4.5,20.9,3.8c6.6-0.6,12.7-2.9,17-6.3C253.4,198.9,252.6,200.1,251.1,201.4z"/>',
                        '<path d="M250,205.6L250,205.6C250.1,205.9,250.1,205.8,250,205.6z"/>',
                        '<path d="M252.1,204.2L252.1,204.2C252.2,204.5,252.2,204.4,252.1,204.2z"/>',
                        '<path d="M162.9,207.9c-4.1-0.4-8-1.4-11.2-2.9c-0.7,0.3-3.1,1.4-3.3,1.9c0.1-0.6,0.3-2.2,1.3-2.8c0.1-0.1,0.2-0.1,0.3-0.1c-0.2-0.1-0.5-0.3-0.7-0.4c-0.8,0.4-3,1.3-3.2,1.9c0.1-0.6,0.3-2.2,1.3-2.8c0.1-0.1,0.3-0.1,0.5-0.1c-0.9-0.7-1.7-1.6-2.4-2.4c1.5,1.1,6.9,4.2,17.4,5.3c11.9,1.2,18.3-4,19.8-4.7C177.7,205.3,171.4,208.8,162.9,207.9z"/>',
                        '<path d="M148.5,207L148.5,207C148.5,207.1,148.5,207.2,148.5,207z"/>',
                        '<path d="M146.2,205.6L146.2,205.6C146.2,205.7,146.2,205.7,146.2,205.6z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°24 => Happy
    function item_24() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M251.5,203.5c0.7-0.7,0.9-2.5,0.9-3.2c-0.1,0.5-1.3,1.4-2.2,1.9c-0.2-0.2-0.4-0.4-0.6-0.6c0.5-0.8,0.7-2.4,0.7-3 c-0.1,0.5-1.2,1.4-2.1,1.9c-2.6-1.9-6.2-3.8-11-4.3c-7.8-0.8-15.7,2-20.1,7.5c5.7-3.6,12.9-5.3,20.1-4.5 c6.4,0.8,12.4,2.9,16.5,6.9C253.3,205.1,252.3,204,251.5,203.5z"/>',
                        '<path d="M250.3,198.6L250.3,198.6C250.4,198.2,250.4,198.3,250.3,198.6z"/>',
                        '<path d="M252.4,200.3L252.4,200.3C252.5,199.9,252.5,200,252.4,200.3z"/>',
                        '<path d="M228.2,192.6c1.1-0.3,2.3-0.5,3.5-0.6c1.1-0.1,2.4-0.1,3.5,0s2.4,0.3,3.5,0.5s2.3,0.6,3.3,1.1l0,0 c-1.1-0.3-2.3-0.6-3.4-0.8c-1.1-0.3-2.3-0.4-3.4-0.5c-1.1-0.1-2.4-0.2-3.5-0.1C230.5,192.3,229.4,192.4,228.2,192.6L228.2,192.6z"/>',
                        '<path d="M224.5,193.8c-0.9,0.6-2,1.1-3,1.7c-0.9,0.6-2,1.2-3,1.7c0.4-0.4,0.8-0.8,1.2-1.1s0.9-0.7,1.4-0.9c0.5-0.3,1-0.6,1.5-0.8C223.3,194.2,223.9,193.9,224.5,193.8z"/>',
                        '<path d="M161.3,195.8c-3.7,0.4-7.2,1.6-10.1,3.5c-0.6-0.3-2.8-1.6-3-2.3c0.1,0.7,0.3,2.6,1.1,3.3c0.1,0.1,0.2,0.2,0.3,0.2 c-0.2,0.2-0.4,0.3-0.6,0.5c-0.7-0.4-2.7-1.5-2.9-2.2c0.1,0.7,0.3,2.6,1.1,3.3c0.1,0.1,0.3,0.2,0.4,0.2c-0.8,0.8-1.6,1.9-2.2,2.9 c1.3-1.4,6.3-5,15.8-6.3c10.9-1.4,16.7,4.7,18,5.5C174.8,198.9,169.1,194.8,161.3,195.8z"/>',
                        '<path d="M148.2,196.9L148.2,196.9C148.2,196.8,148.2,196.7,148.2,196.9z"/>',
                        '<path d="M146.1,198.6L146.1,198.6C146.1,198.5,146.1,198.4,146.1,198.6z"/>',
                        '<path d="M167.5,192.2c-1.1-0.2-2.3-0.3-3.5-0.3c-1.1,0-2.4,0-3.5,0.2c-1.1,0.1-2.3,0.3-3.4,0.5c-1.1,0.3-2.3,0.5-3.4,0.8 c2.1-0.9,4.3-1.5,6.7-1.7c1.1-0.1,2.4-0.1,3.5-0.1C165.3,191.7,166.4,191.9,167.5,192.2z"/>',
                        '<path d="M171.4,193.4c0.6,0.2,1.1,0.3,1.7,0.6c0.5,0.3,1,0.5,1.6,0.8c0.5,0.3,1,0.6,1.4,0.9c0.5,0.3,0.9,0.7,1.3,1 c-1-0.5-2.1-1.1-3-1.6C173.3,194.5,172.3,193.9,171.4,193.4z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°25 => Arrow
    function item_25() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-width="1.5" stroke-linejoin="round" stroke-miterlimit="10" d="M251.4,192.5l-30.8,8 c10.9,1.9,20.7,5,29.5,9.1"/>',
                        '<path fill="none" stroke="#000000" stroke-width="1.5" stroke-linejoin="round" stroke-miterlimit="10" d="M149.4,192.5l30.8,8 c-10.9,1.9-20.7,5-29.5,9.1"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°26 => Closed
    function item_26() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10" x1="216.3" y1="200.2" x2="259" y2="198.3"/>',
                        '<line fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10" x1="179.4" y1="200.2" x2="143.4" y2="198.3"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°27 => Suspicious
    function item_27() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path opacity="0.81" fill="#FFFFFF" d="M220.3,202.5c-0.6,4.6,0.1,5.8,1.6,8.3 c0.9,1.5,1,2.5,8.2-1.2c6.1,0.4,8.2-1.6,16,2.5c3,0,4-3.8,5.1-7.7c0.6-2.2-0.2-4.6-2-5.9c-3.4-2.5-9-6-13.4-5.3 c-3.9,0.7-7.7,1.9-11.3,3.6C222.3,197.9,221,197.3,220.3,202.5z"/>',
                        '<path d="M251.6,200c0.7-0.8,0.9-2.9,0.9-3.7c-0.1,0.6-1.3,1.5-2,2.2c-0.2-0.2-0.4-0.5-0.6-0.7c0.5-1,0.7-2.7,0.7-3.4 c-0.1,0.6-1.2,1.5-1.9,2.1c-2.4-2.2-5.8-4.4-10.4-4.9c-7.4-1-14.7,2.3-18.9,8.6c5.3-4.2,12.1-6,18.9-5.1c6,0.9,11.5,4,15.4,8.5 C253.6,203.4,252.9,201.9,251.6,200z"/>',
                        '<path d="M250.5,194.4L250.5,194.4C250.6,194,250.6,194.1,250.5,194.4z"/>',
                        '<path d="M252.4,196.3L252.4,196.3C252.5,195.9,252.5,196,252.4,196.3z"/>',
                        '<path d="M229.6,187.6c1.1-0.3,2.1-0.6,3.3-0.7c1.1-0.1,2.2-0.1,3.3,0s2.2,0.3,3.3,0.6s2.1,0.7,3.1,1.3l0,0 c-1.1-0.3-2.1-0.7-3.2-0.9c-1.1-0.3-2.1-0.5-3.2-0.6c-1.1-0.1-2.2-0.2-3.3-0.1C231.9,187.2,230.8,187.3,229.6,187.6L229.6,187.6 z"/>',
                        '<path d="M226.1,189c-0.9,0.7-1.8,1.3-2.8,1.9c-0.9,0.7-1.8,1.4-2.8,1.9c0.4-0.5,0.8-0.9,1.2-1.3c0.4-0.4,0.9-0.8,1.4-1.1 s1-0.7,1.5-0.9C225.1,189.4,225.7,189.1,226.1,189z"/>',
                        '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M222,212.8c0,0,9.8-7.3,26.9,0"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M229,195.2c0,0-4.6,8.5,0.7,14.4 c0,0,8.8-1.5,11.6,0.4c0,0,4.7-5.7,1.5-12.5S229,195.2,229,195.2z"/>',
                        '<path opacity="0.81" fill="#FFFFFF" d="M177.1,202.5c0.6,4.6-0.1,5.8-1.6,8.3 c-0.9,1.5-1,2.5-8.2-1.2c-6.1,0.4-8.2-1.6-16,2.5c-3,0-4-3.8-5.1-7.7c-0.6-2.2,0.2-4.6,2-5.9c3.4-2.5,9-6,13.4-5.3 c3.9,0.7,7.7,1.9,11.3,3.6C175.2,197.9,176.4,197.3,177.1,202.5z"/>',
                        '<path d="M145.9,200c-0.7-0.8-0.9-2.9-0.9-3.7c0.1,0.6,1.3,1.5,2,2.2c0.2-0.2,0.4-0.5,0.6-0.7c-0.5-1-0.7-2.7-0.7-3.4 c0.1,0.6,1.2,1.5,1.9,2.1c2.4-2.2,5.8-4.4,10.4-4.9c7.4-1,14.7,2.3,18.9,8.6c-5.3-4.2-12.1-6-18.9-5.1c-6,0.9-11.5,4-15.4,8.5 C143.8,203.4,144.5,201.9,145.9,200z"/>',
                        '<path d="M146.9,194.4L146.9,194.4C146.9,194,146.9,194.1,146.9,194.4z"/>',
                        abi.encodePacked(
                            '<path d="M145,196.3L145,196.3C144.9,195.9,144.9,196,145,196.3z"/>',
                            '<path d="M167.8,187.6c-1.1-0.3-2.1-0.6-3.3-0.7c-1.1-0.1-2.2-0.1-3.3,0s-2.2,0.3-3.3,0.6s-2.1,0.7-3.1,1.3l0,0 c1.1-0.3,2.1-0.7,3.2-0.9c1.1-0.3,2.1-0.5,3.2-0.6c1.1-0.1,2.2-0.2,3.3-0.1C165.6,187.2,166.6,187.3,167.8,187.6L167.8,187.6z"/>',
                            '<path d="M171.3,189c0.9,0.7,1.8,1.3,2.8,1.9c0.9,0.7,1.8,1.4,2.8,1.9c-0.4-0.5-0.8-0.9-1.2-1.3c-0.4-0.4-0.9-0.8-1.4-1.1 s-1-0.7-1.5-0.9C172.4,189.4,171.8,189.1,171.3,189z"/>',
                            '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M175.4,212.8c0,0-9.8-7.3-26.9,0"/>',
                            '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M168.5,195.2c0,0,4.6,8.5-0.7,14.4 c0,0-8.8-1.5-11.6,0.4c0,0-4.7-5.7-1.5-12.5S168.5,195.2,168.5,195.2z"/>'
                        )
                    )
                )
            );
    }

    /// @dev Eyes N°28 => Annoyed 1
    function item_28() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="218" y1="195.2" x2="256" y2="195.2"/>',
                        '<path stroke="#000000" stroke-miterlimit="10" d="M234,195.5c0,5.1,4.1,9.2,9.2,9.2s9.2-4.1,9.2-9.2"/>',
                        '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="143.2" y1="195.7" x2="181.1" y2="195.7"/>',
                        '<path stroke="#000000" stroke-miterlimit="10" d="M158.7,196c0,5.1,4.1,9.2,9.2,9.2c5.1,0,9.2-4.1,9.2-9.2"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°29 => Annoyed 2
    function item_29() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="218" y1="195.2" x2="256" y2="195.2"/>',
                        '<path stroke="#000000" stroke-miterlimit="10" d="M228,195.5c0,5.1,4.1,9.2,9.2,9.2s9.2-4.1,9.2-9.2"/>',
                        '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="143.2" y1="195.7" x2="181.1" y2="195.7"/>',
                        '<path stroke="#000000" stroke-miterlimit="10" d="M152.7,196c0,5.1,4.1,9.2,9.2,9.2c5.1,0,9.2-4.1,9.2-9.2"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°30 => RIP
    function item_30() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-width="3" stroke-linecap="square" stroke-miterlimit="10" x1="225.7" y1="190.8" x2="242.7" y2="207.8"/>',
                        '<line fill="none" stroke="#000000" stroke-width="3" stroke-linecap="square" stroke-miterlimit="10" x1="225.7" y1="207.8" x2="243.1" y2="190.8"/>',
                        '<line fill="none" stroke="#000000" stroke-width="3" stroke-linecap="square" stroke-miterlimit="10" x1="152.8" y1="190.8" x2="169.8" y2="207.8"/>',
                        '<line fill="none" stroke="#000000" stroke-width="3" stroke-linecap="square" stroke-miterlimit="10" x1="152.8" y1="207.8" x2="170.3" y2="190.8"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°31 => Heart
    function item_31() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#F44336" stroke="#C90005" stroke-miterlimit="10" d="M161.1,218.1c0.2,0.2,0.4,0.3,0.7,0.3s0.5-0.1,0.7-0.3l12.8-14.1 c5.3-5.9,1.5-16-6-16c-4.6,0-6.7,3.6-7.5,4.3c-0.8-0.7-2.9-4.3-7.5-4.3c-7.6,0-11.4,10.1-6,16L161.1,218.1z"/>',
                        '<path fill="#F44336" stroke="#C90005" stroke-miterlimit="10" d="M235.3,218.1c0.2,0.2,0.5,0.3,0.8,0.3s0.6-0.1,0.8-0.3l13.9-14.1 c5.8-5.9,1.7-16-6.6-16c-4.9,0-7.2,3.6-8.1,4.3c-0.9-0.7-3.1-4.3-8.1-4.3c-8.2,0-12.4,10.1-6.6,16L235.3,218.1z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°32 => Scribble
    function item_32() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<polyline fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" points="222.5,195.2 252.2,195.2 222.5,199.4 250.5,199.4 223.9,202.8 247.4,202.8"/>',
                        '<polyline fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" points="148.2,195.2 177.9,195.2 148.2,199.4 176.2,199.4 149.6,202.8 173.1,202.8"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°33 => Wide
    function item_33() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<ellipse fill-rule="evenodd" clip-rule="evenodd" fill="#FFFFFF" cx="236.7" cy="200.1" rx="12.6" ry="14.9"/>',
                        '<path d="M249.4,200.1c0,3.6-1,7.3-3.2,10.3c-1.1,1.5-2.5,2.8-4.1,3.7s-3.5,1.4-5.4,1.4s-3.7-0.6-5.3-1.5s-3-2.2-4.1-3.6c-2.2-2.9-3.4-6.5-3.5-10.2c-0.1-3.6,1-7.4,3.3-10.4c1.1-1.5,2.6-2.7,4.2-3.6c1.6-0.9,3.5-1.4,5.4-1.4s3.8,0.5,5.4,1.4c1.6,0.9,3,2.2,4.1,3.7C248.4,192.9,249.4,196.5,249.4,200.1z M249.3,200.1c0-1.8-0.3-3.6-0.9-5.3c-0.6-1.7-1.5-3.2-2.6-4.6c-2.2-2.7-5.5-4.5-9-4.5s-6.7,1.8-8.9,4.6c-2.2,2.7-3.3,6.2-3.4,9.8c-0.1,3.5,1,7.2,3.2,10s5.6,4.6,9.1,4.5c3.5,0,6.8-1.9,9-4.6C248,207.3,249.3,203.7,249.3,200.1z"/>',
                        '<ellipse fill-rule="evenodd" clip-rule="evenodd" fill="#FFFFFF" cx="163" cy="200.1" rx="12.6" ry="14.9"/>',
                        '<path d="M175.6,200.1c0,3.6-1,7.3-3.2,10.3c-1.1,1.5-2.5,2.8-4.1,3.7s-3.5,1.4-5.4,1.4s-3.7-0.6-5.3-1.5s-3-2.2-4.1-3.6c-2.2-2.9-3.4-6.5-3.5-10.2c-0.1-3.6,1-7.4,3.3-10.4c1.1-1.5,2.6-2.7,4.2-3.6c1.6-0.9,3.5-1.4,5.4-1.4s3.8,0.5,5.4,1.4c1.6,0.9,3,2.2,4.1,3.7C174.6,192.9,175.6,196.5,175.6,200.1z M175.5,200.1c0-1.8-0.3-3.6-0.9-5.3c-0.6-1.7-1.5-3.2-2.6-4.6c-2.2-2.7-5.5-4.5-9-4.5s-6.7,1.8-8.9,4.6c-2.2,2.7-3.3,6.2-3.4,9.8c-0.1,3.5,1,7.2,3.2,10s5.6,4.6,9.1,4.5c3.5,0,6.8-1.9,9-4.6C174.3,207.3,175.5,203.7,175.5,200.1z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°34 => Dubu
    function item_34() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M241.6,195.9c-8.7-7.2-25.1-4-4.7,6.6c-21.9-4.3-3.4,11.8,4.7,6.1"/>',
                        '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M167.6,195.9c-8.7-7.2-25.1-4-4.7,6.6c-21.9-4.3-3.4,11.8,4.7,6.1"/>'
                    )
                )
            );
    }

    /// @dev Right and left eyes (color pupils + eyes)
    function eyesNoFillAndColorPupils(string memory scleraColor, string memory pupilsColor)
        private
        pure
        returns (string memory)
    {
        return base(string(abi.encodePacked(eyesNoFill(scleraColor), colorPupils(pupilsColor))));
    }

    /// @dev Right and left eyes (blank pupils + eyes)
    function eyesNoFillAndBlankPupils(string memory scleraColor, string memory pupilsColor)
        private
        pure
        returns (string memory)
    {
        return base(string(abi.encodePacked(eyesNoFill(scleraColor), blankPupils(pupilsColor))));
    }

    /// @dev Right and left eyes
    function eyesNoFill(string memory scleraColor) private pure returns (string memory) {
        return string(abi.encodePacked(eyeLeftNoFill(scleraColor), eyeRightNoFill(scleraColor)));
    }

    /// @dev Eye right and no fill
    function eyeRightNoFill(string memory scleraColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    scleraColor,
                    "' d='M220.9,203.6c0.5,3.1,1.7,9.6,7.1,10.1 c7,1.1,21,4.3,23.2-9.3c1.3-7.1-9.8-11.4-15.4-11.2C230.7,194.7,220.5,194.7,220.9,203.6z'/>",
                    '<path d="M250.4,198.6c-0.2-0.2-0.4-0.5-0.6-0.7"/>',
                    '<path d="M248.6,196.6c-7.6-7.9-23.4-6.2-29.3,3.7c10-8.2,26.2-6.7,34.4,3.4c0-0.3-0.7-1.8-2-3.7"/>',
                    '<path d="M229.6,187.6c4.2-1.3,9.1-1,13,1.2C238.4,187.4,234,186.6,229.6,187.6L229.6,187.6z"/>',
                    '<path d="M226.1,189c-1.8,1.3-3.7,2.7-5.6,3.9C221.9,191.1,224,189.6,226.1,189z"/>',
                    '<path d="M224.5,212.4c5.2,2.5,19.7,3.5,24-0.9C244.2,216.8,229.6,215.8,224.5,212.4z"/>'
                )
            );
    }

    /// @dev Eye right and no fill
    function eyeLeftNoFill(string memory scleraColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    scleraColor,
                    "' d='M175.7,199.4c2.4,7.1-0.6,13.3-4.1,13.9 c-5,0.8-15.8,1-18.8,0c-5-1.7-6.1-12.4-6.1-12.4C156.6,191.4,165,189.5,175.7,199.4z'/>",
                    '<path d="M147.5,198.7c-0.8,1-1.5,2.1-2,3.3c7.5-8.5,24.7-10.3,31.7-0.9c-5.8-10.3-17.5-13-26.4-5.8"/>',
                    '<path d="M149.4,196.6c-0.2,0.2-0.4,0.4-0.6,0.6"/>',
                    '<path d="M166.2,187.1c-4.3-0.8-8.8,0.1-13,1.4C157,186.4,162,185.8,166.2,187.1z"/>',
                    '<path d="M169.8,188.5c2.2,0.8,4.1,2.2,5.6,3.8C173.5,191.1,171.6,189.7,169.8,188.5z"/>',
                    '<path d="M174.4,211.8c-0.2,0.5-0.8,0.8-1.2,1c-0.5,0.2-1,0.4-1.5,0.6c-1,0.3-2.1,0.5-3.1,0.7c-2.1,0.4-4.2,0.5-6.3,0.7 c-2.1,0.1-4.3,0.1-6.4-0.3c-1.1-0.2-2.1-0.5-3.1-0.9c-0.9-0.5-2-1.1-2.4-2.1c0.6,0.9,1.6,1.4,2.5,1.7c1,0.3,2,0.6,3,0.7 c2.1,0.3,4.2,0.3,6.2,0.2c2.1-0.1,4.2-0.2,6.3-0.5c1-0.1,2.1-0.3,3.1-0.5c0.5-0.1,1-0.2,1.5-0.4c0.2-0.1,0.5-0.2,0.7-0.3 C174.1,212.2,174.3,212.1,174.4,211.8z"/>'
                )
            );
    }

    /// @dev Generate color pupils
    function colorPupils(string memory pupilsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    pupilsColor,
                    "' d='M235,194.9c10.6-0.2,10.6,19,0,18.8C224.4,213.9,224.4,194.7,235,194.9z'/>",
                    '<path d="M235,199.5c3.9-0.1,3.9,9.6,0,9.5C231.1,209.1,231.1,199.4,235,199.5z"/>',
                    '<path fill="#FFFFFF" d="M239.1,200.9c3.4,0,3.4,2.5,0,2.5C235.7,203.4,235.7,200.8,239.1,200.9z"/>',
                    "<path fill='#",
                    pupilsColor,
                    "' d='M161.9,194.6c10.5-0.4,11,18.9,0.4,18.9C151.7,213.9,151.3,194.6,161.9,194.6z'/>",
                    '<path d="M162,199.2c3.9-0.2,4.1,9.5,0.2,9.5C158.2,208.9,158.1,199.2,162,199.2z"/>',
                    '<path fill="#FFFFFF" d="M157.9,200.7c3.4-0.1,3.4,2.5,0,2.5C154.6,203.3,154.5,200.7,157.9,200.7z"/>'
                )
            );
    }

    /// @dev Generate blank pupils
    function blankPupils(string memory pupilsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    abi.encodePacked(
                        "<path fill='#",
                        pupilsColor,
                        "' stroke='#000000' stroke-width='0.25' stroke-miterlimit='10' d='M169.2,204.2c0.1,11.3-14.1,11.3-13.9,0C155.1,192.9,169.3,192.9,169.2,204.2z'/>",
                        "<path fill='#",
                        pupilsColor,
                        "' stroke='#000000' stroke-width='0.25' stroke-miterlimit='10' d='M243.1,204.3c0.1,11.3-14.1,11.3-13.9,0C229,193,243.2,193,243.1,204.3z'/>"
                    )
                )
            );
    }

    /// @notice Return the eyes name of the given id
    /// @param id The eyes Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Color White/Brown";
        } else if (id == 2) {
            name = "Color White/Gray";
        } else if (id == 3) {
            name = "Color White/Blue";
        } else if (id == 4) {
            name = "Color White/Green";
        } else if (id == 5) {
            name = "Color White/Black";
        } else if (id == 6) {
            name = "Color White/Yellow";
        } else if (id == 7) {
            name = "Color White/Red";
        } else if (id == 8) {
            name = "Color White/Purple";
        } else if (id == 9) {
            name = "Color White/Pink";
        } else if (id == 10) {
            name = "Color White/White";
        } else if (id == 11) {
            name = "Color Black/Blue";
        } else if (id == 12) {
            name = "Color Black/Yellow";
        } else if (id == 13) {
            name = "Color Black/White";
        } else if (id == 14) {
            name = "Color Black/Red";
        } else if (id == 15) {
            name = "Blank White/White";
        } else if (id == 16) {
            name = "Blank Black/White";
        } else if (id == 17) {
            name = "Shine";
        } else if (id == 18) {
            name = "Stunt";
        } else if (id == 19) {
            name = "Squint";
        } else if (id == 20) {
            name = "Shock";
        } else if (id == 21) {
            name = "Cat";
        } else if (id == 22) {
            name = "Ether";
        } else if (id == 23) {
            name = "Feels";
        } else if (id == 24) {
            name = "Happy";
        } else if (id == 25) {
            name = "Arrow";
        } else if (id == 26) {
            name = "Closed";
        } else if (id == 27) {
            name = "Suspicious";
        } else if (id == 28) {
            name = "Annoyed 1";
        } else if (id == 29) {
            name = "Annoyed 2";
        } else if (id == 30) {
            name = "RIP";
        } else if (id == 31) {
            name = "Heart";
        } else if (id == 32) {
            name = "Scribble";
        } else if (id == 33) {
            name = "Wide";
        } else if (id == 34) {
            name = "Dubu";
        }
    }

    /// @dev The base SVG for the eyes
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Eyes">', children, "</g>"));
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

/// @title Color constants
library Colors {
    string internal constant BLACK = "33333D";
    string internal constant BLACK_DEEP = "000000";
    string internal constant BLUE = "7FBCFF";
    string internal constant BROWN = "735742";
    string internal constant GRAY = "7F8B8C";
    string internal constant GREEN = "2FC47A";
    string internal constant PINK = "FF78A9";
    string internal constant PURPLE = "A839A4";
    string internal constant RED = "D9005E";
    string internal constant SAIKI = "F02AB6";
    string internal constant WHITE = "F7F7F7";
    string internal constant YELLOW = "EFED8F";
}

