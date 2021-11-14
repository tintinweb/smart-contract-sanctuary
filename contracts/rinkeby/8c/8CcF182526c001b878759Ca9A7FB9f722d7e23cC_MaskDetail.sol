// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Mask SVG generator
library MaskDetail {
    /// @dev Mask N°1 => None
    function item_1() public pure returns (string memory) {
        return base("", "None");
    }

    /// @dev Mask N°2 => Uni Horn Blood
    function item_2() public pure returns (string memory) {
        return base(horn("E31466"), "Uni Horn Blood");
    }

    /// @dev Mask N°3 => Power Sticks
    function item_3() public pure returns (string memory) {
        return base(powerStick("000000"), "Power sticks");
    }

    /// @dev Mask N°4 => Uni Horn Moon
    function item_4() public pure returns (string memory) {
        return base(horn("2A2C38"), "Uni Horn Moon");
    }

    /// @dev Mask N°5 => Power Neck
    function item_5() public pure returns (string memory) {
        return
            base(
                '<g display="inline"><path stroke="#000000" stroke-miterlimit="10" d="M254,291l22.2-0.1c0.3,0.4,2.5,4.3,0,9H254C252.1,296.7,251.9,293.7,254,291z" /><g><path d="M251.9,289.3c-1,2-1.8,4-1.9,6c0,1,0,2.1,0.3,3.1c0.1,0.5,0.3,1,0.4,1.6c0.2,0.5,0.4,1,0.6,1.6c-0.4-0.4-0.7-0.8-1-1.4c-0.3-0.5-0.6-0.9-0.7-1.6c-0.4-1-0.6-2.2-0.6-3.4c0-1.1,0.3-2.3,0.8-3.3C250.4,290.9,251.1,289.9,251.9,289.3z" /></g></g><g display="inline"><path stroke="#000000" stroke-miterlimit="10" d="M177.4,292.4l-20-0.1c-0.3,0.4-2.3,4.3,0,9h20C179.2,298.1,179.5,295.2,177.4,292.4z" /><g><path d="M179.5,290.7c0.8,0.7,1.6,1.7,2.1,2.7s0.8,2.2,0.8,3.3s-0.1,2.3-0.6,3.4c-0.2,0.5-0.5,1-0.7,1.6c-0.3,0.5-0.7,0.9-1,1.4c0.2-0.5,0.4-1,0.6-1.6c0.1-0.5,0.3-1,0.4-1.6c0.3-1,0.3-2.1,0.3-3.1C181.3,294.7,180.5,292.7,179.5,290.7z" /></g></g>',
                "Power Neck"
            );
    }

    /// @dev Mask N°6 => Bouc
    function item_6() public pure returns (string memory) {
        return
            base(
                '<path id="Bouc"  d="M189.4,279c0,0,8.8,9.2,9.8,10c0.7-0.7,6.4-14.7,6.4-14.7l5.8,14.7l10.4-10l-16.3,71L189.4,279z"/>',
                "Bouc"
            );
    }

    /// @dev Mask N°7 => BlindFold Tomoe Blood
    function item_7() public pure returns (string memory) {
        return base(blindfold("D4004D", "FFEDED"), "Blindfold Tomoe Blood");
    }

    /// @dev Mask N°8 => Strap Blood
    function item_8() public pure returns (string memory) {
        return base(strap("D9005E"), "Strap Blood");
    }

    /// @dev Mask N°9 => Sun Glasses
    function item_9() public pure returns (string memory) {
        return
            base(
                '<g display="inline" opacity="0.95"><ellipse stroke="#000000" stroke-miterlimit="10" cx="164.6" cy="189.5" rx="24.9" ry="24.8" /><ellipse stroke="#000000" stroke-miterlimit="10" cx="236.3" cy="188.5" rx="24.9" ry="24.8" /></g><path display="inline" fill="none" stroke="#000000" stroke-miterlimit="10" d="M261.1,188.6l32.2-3.6 M187,188.6c0,0,15.3-3.2,24.5,0 M140.6,189l-7.1-3" />',
                "Sun glasses"
            );
    }

    /// @dev Mask N°10 => Uni Horn Pure
    function item_10() public pure returns (string memory) {
        return base(horn("FFDAEA"), "Uni Horn Pure");
    }

    /// @dev Mask N°11 => Strap Moon
    function item_11() public pure returns (string memory) {
        return base(strap("575673"), "Strap Moon");
    }

    /// @dev Mask N°12 => BlindFold Tomoe Moon
    function item_12() public pure returns (string memory) {
        return base(blindfold("000000", "B50D5E"), "BlindFold Tomoe Moon");
    }

    /// @dev Mask N°13 => Stitch
    function item_13() public pure returns (string memory) {
        return
            base(
                '<g display="inline"><path d="M175.8,299.3c7.2,1.8,14.4,2.9,21.7,3.9c1.9,0.2,3.5,0.5,5.4,0.7s3.6,0.3,5.4,0.5c3.6,0.2,7.2,0.2,10.9,0.1c3.6-0.1,7.2-0.5,10.9-0.7l5.4-0.6c0.9-0.1,1.9-0.2,2.7-0.3l2.7-0.4c7.2-1,14.4-2.9,21.5-4.8v0.1l-5.5,1.9l-2.7,0.8c-0.9,0.3-1.8,0.5-2.7,0.7l-5.4,1.4c-1.9,0.4-3.5,0.6-5.4,1c-3.5,0.7-7.2,0.9-10.9,1.4c-3.6,0.2-7.2,0.4-10.9,0.3c-7.2-0.1-14.6-0.3-21.8-0.9C190.1,303.1,182.8,301.8,175.8,299.3L175.8,299.3z" /></g><path display="inline" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M206.9,304.5c0,0,5.3-2.1,11.8,0.2C218.8,304.7,212.8,307.6,206.9,304.5z" /><g display="inline"><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M222.1,301c0,0,0.7-3.4,1.9-1c0,0,0.3,5.3-0.5,9.9c0,0-0.7,2.2-1-0.6C222.1,306.5,222.7,306.2,222.1,301z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M227.4,301.2c0,0,0.7-3.1,1.7-0.9c0,0,0.3,4.7-0.4,8.9c0,0-0.6,1.9-0.9-0.5C227.4,306.1,228.2,305.8,227.4,301.2z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M231.8,301.1c0,0,0.6-2.7,1.5-0.8c0,0,0.3,4.1-0.3,7.7c0,0-0.5,1.7-0.7-0.4C231.8,305.3,232.3,305.1,231.8,301.1z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M235.5,300.8c0,0,0.5-2.4,1.4-0.7c0,0,0.3,3.6-0.3,6.9c0,0-0.5,1.5-0.7-0.4C235.6,304.6,236,304.4,235.5,300.8z" /></g><g display="inline"><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M203.8,300.5c0,0-0.7-3.4-1.9-1c0,0-0.3,5.3,0.5,9.9c0,0,0.7,2.2,1-0.6C203.8,306,203.1,305.8,203.8,300.5z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M198.5,300.8c0,0-0.7-3.1-1.7-0.9c0,0-0.3,4.7,0.4,8.9c0,0,0.6,1.9,0.9-0.5C198.5,305.8,197.7,305.3,198.5,300.8z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M194.1,300.6c0,0-0.6-2.7-1.5-0.8c0,0-0.3,4.1,0.3,7.7c0,0,0.5,1.7,0.7-0.4C193.9,305,193.6,304.7,194.1,300.6z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M190.4,300.3c0,0-0.5-2.4-1.4-0.7c0,0-0.3,3.6,0.3,6.9c0,0,0.5,1.5,0.7-0.4C190.4,304.2,189.9,304,190.4,300.3z" /></g>',
                "Stitch"
            );
    }

    /// @dev Mask N°14 => Strap Pure
    function item_14() public pure returns (string memory) {
        return base(strap("F2F2F2"), "Strap Pure");
    }

    /// @dev Mask N°15 => Eye Patch
    function item_15() public pure returns (string memory) {
        return
            base(
                '<g id="MASK EYE" display="inline"><g><path fill="#FCFEFF" d="M257.9,210.4h-36.1c-4.9,0-8.9-4-8.9-8.9v-21.7c0-4.9,4-8.9,8.9-8.9h36.1c4.9,0,8.9,4,8.9,8.9v21.8C266.6,206.4,262.8,210.4,257.9,210.4z"/><path d="M257.9,210.4l-10.7,0.1l-10.7,0.2c-3.6,0.1-7.1,0.1-10.7,0.1h-2.7h-1.3c-0.5,0-0.9,0-1.4-0.1c-1.9-0.3-3.6-1.2-4.9-2.5c-1.4-1.3-2.3-3-2.6-4.8c-0.2-0.9-0.2-1.9-0.2-2.7V198c0.1-3.6,0.1-7.1,0.1-10.7v-5.4c0-0.9,0-1.8,0-2.7c0.1-0.9,0.2-1.8,0.6-2.7c0.6-1.7,1.8-3.2,3.3-4.3c0.8-0.5,1.6-0.9,2.4-1.2c0.9-0.3,1.8-0.4,2.7-0.4l21.4-0.2l10.7-0.1h2.7h1.3c0.5,0,0.9,0,1.4,0.1c1.9,0.3,3.6,1.2,5,2.5s2.3,3,2.7,4.9c0.2,0.9,0.2,1.9,0.2,2.8v2.7l-0.1,10.7l-0.1,5.4c0,0.9,0,1.8-0.1,2.7s-0.3,1.8-0.7,2.6c-0.7,1.7-1.8,3.2-3.3,4.2c-0.7,0.5-1.6,0.9-2.4,1.2C259.7,210.3,258.8,210.4,257.9,210.4z M257.9,210.3c0.9,0,1.8-0.2,2.6-0.4c0.8-0.3,1.6-0.7,2.4-1.2c1.4-1,2.6-2.5,3.2-4.2c0.3-0.8,0.5-1.7,0.5-2.6c0.1-0.9,0-1.8,0-2.7l-0.1-5.4l-0.1-10.7v-2.7c0-0.9,0-1.7-0.2-2.6c-0.4-1.6-1.2-3.2-2.5-4.3c-1.2-1.2-2.8-1.9-4.5-2.2c-0.4-0.1-0.8-0.1-1.3-0.1h-1.3h-2.7l-10.7-0.1l-21.4-0.2c-3.5-0.1-6.9,2.2-8.1,5.5c-0.7,1.6-0.6,3.4-0.6,5.2v5.4c0,3.6,0,7.1,0.1,10.7v2.7c0,0.9,0,1.7,0.2,2.6c0.4,1.7,1.3,3.2,2.5,4.4s2.8,2,4.5,2.2c0.8,0.1,1.7,0.1,2.6,0.1h2.7c3.6,0,7.1,0,10.7,0.1l10.7,0.2L257.9,210.3z"/></g><g><path d="M254.2,206.4c-5.7,0-11.4,0.1-17,0.2c-2.8,0.1-5.7,0.1-8.5,0.1h-2.1c-0.7,0-1.4,0-2.2-0.1c-1.5-0.2-2.9-0.9-4-1.9s-1.8-2.4-2.2-3.8c-0.2-0.7-0.2-1.5-0.2-2.2v-2.1c0-2.8,0.1-5.7,0.1-8.5v-4.3c0-0.7,0-1.4,0-2.1c0.1-0.7,0.2-1.4,0.5-2.1c0.5-1.4,1.5-2.5,2.6-3.4c0.6-0.4,1.3-0.7,2-1c0.7-0.2,1.4-0.3,2.2-0.3l17-0.1h8.5h2.1c0.7,0,1.4,0,2.2,0.1c1.5,0.2,2.9,0.9,4,1.9s1.9,2.4,2.2,3.8c0.2,0.7,0.2,1.5,0.2,2.2v2.1l-0.1,8.5l-0.1,4.3c0,0.7,0,1.4-0.1,2.1c-0.1,0.7-0.2,1.4-0.5,2.1c-0.5,1.3-1.5,2.5-2.7,3.3C257.1,206,255.6,206.4,254.2,206.4z M254.2,206.4c1.4,0,2.8-0.4,4-1.2s2.1-1.9,2.6-3.3c0.2-0.7,0.4-1.4,0.4-2c0-0.7,0-1.4,0-2.1l-0.1-4.3L261,185v-2.1c0-0.7,0-1.4-0.2-2c-0.3-1.3-1-2.5-2-3.4s-2.3-1.5-3.6-1.7c-0.7-0.1-1.3-0.1-2.1-0.1H251h-8.5l-17-0.1c-2.8-0.1-5.5,1.7-6.5,4.3c-0.3,0.6-0.4,1.3-0.5,2s0,1.4,0,2.1v4.3c0,2.8,0,5.7,0.1,8.5v2.1c0,0.7,0,1.4,0.2,2.1c0.3,1.3,1,2.6,2.1,3.5c1,0.9,2.3,1.5,3.6,1.7c0.7,0.1,1.4,0.1,2.1,0.1h2.1c2.8,0,5.7,0,8.5,0.1C242.8,206.3,248.5,206.4,254.2,206.4z"/></g><g><path d="M214.4,174.8c-7-0.5-13.9-1.1-20.8-1.8c-3.5-0.4-6.9-0.8-10.4-1.1s-7-0.5-10.4-0.6c-7-0.3-13.9-0.5-20.9-0.9c-7-0.3-13.9-0.7-20.9-1.2c0,0,0,0,0-0.1l0,0c7-0.1,13.9,0,20.9,0.3s13.9,0.7,20.9,1.3c3.5,0.3,6.9,0.6,10.4,0.8l10.4,0.6C200.6,172.8,207.5,173.6,214.4,174.8C214.4,174.8,214.5,174.8,214.4,174.8C214.4,174.8,214.4,174.9,214.4,174.8z"/></g><g><path d="M265.2,175c2.8,0,5.5,0.3,8.2,0.7c1.4,0.3,2.7,0.6,4,0.8c1.4,0.2,2.7,0.4,4.1,0.5c2.7,0.2,5.5,0.6,8.2,1.1s5.4,1.2,8,2.1c0,0,0,0,0,0.1c0,0,0,0-0.1,0c-2.7-0.3-5.4-0.7-8.1-1.2s-5.4-1-8.1-1.6c-1.3-0.3-2.7-0.6-4.1-0.7c-1.4-0.2-2.7-0.2-4.1-0.3C270.6,176.2,267.9,175.8,265.2,175L265.2,175L265.2,175z"/></g><g><path d="M263.6,208.2c1.7,2.6,3.3,5.3,4.7,8.1c0.7,1.4,1.3,2.8,2.1,4.2c0.8,1.4,1.6,2.7,2.5,4c1.8,2.6,3.4,5.2,5.1,7.9c1.6,2.7,3.2,5.3,4.7,8.1v0.1c0,0,0,0-0.1,0c-2-2.4-3.8-5-5.6-7.6c-1.7-2.6-3.3-5.4-4.7-8.1c-0.7-1.4-1.5-2.8-2.3-4.1s-1.7-2.6-2.5-4C266,214,264.7,211.2,263.6,208.2C263.5,208.2,263.6,208.2,263.6,208.2C263.6,208.1,263.6,208.2,263.6,208.2z"/></g><g><path d="M213.9,206.7c-5.8,2.8-11.7,5.2-17.7,7.4l-4.5,1.5c-1.5,0.5-3,1-4.5,1.5c-3,1-6,2.1-9,3.2c-6,2.2-12.1,4.1-18.2,5.8c-6.1,1.7-12.3,3.2-18.6,4.4h-0.1v-0.1l36.7-10.7c3.1-0.9,6.1-1.9,9.1-3s5.9-2.3,8.9-3.5C201.9,211,207.9,208.8,213.9,206.7C213.9,206.6,213.9,206.7,213.9,206.7C214,206.7,213.9,206.7,213.9,206.7z"/></g></g>',
                "Eye Patch"
            );
    }

    /// @dev Mask N°16 => Eye
    function item_16() public pure returns (string memory) {
        return
            base(
                '<path d="M199.9,132.9s-15.2,17-.1,39.9C199.9,172.7,214.8,154.7,199.9,132.9Z" transform="translate(0 0.5)" /> <path d="M207,139.4c3.51,8.76,3.82,19.26-1,27.6C209.59,158.25,209.25,148.47,207,139.4Z" transform="translate(0 0.5)"/> <path d="M190.9,155.2c.81,5.6,1.84,11.19,4.9,16.1C192.1,167,191,160.73,190.9,155.2Z" transform="translate(0 0.5)"/> <path d="M202.27,142.35c1-.3,2.1,6.26,1.07,6.31C202.34,149,201.23,142.4,202.27,142.35Z" transform="translate(0 0.5)" fill="#fff"/>',
                "Eye"
            );
    }

    /// @dev Mask N°17 => Nihon
    function item_17() public pure returns (string memory) {
        return
            base(
                '<path id="Nihon" display="inline" fill="#FFFFFF" stroke="#000000" stroke-width="2" stroke-miterlimit="10" d="M175.3,307.1c0,0,21.5,15.8,85.9,0.3c0.3-0.1,0.4-0.3,0.4-0.5c0-2.7,0-17.9,4.6-46.5c0-0.1,0.1-0.2,0.1-0.3c1.1-1.6,13.5-17.6,15.9-20.6c0.2-0.3,0.1-0.6-0.2-0.8c-5.3-3.2-47.8-29-83-38c-1.1-0.3-3.1-0.7-4.2-0.2c-17.5,7.4-46.3,28.9-52.8,33.9c-0.8,0.6-0.9,1.7-0.7,2.7c1.5,5.3,8.2,19.9,10.2,21.8c1.8,1.7,23.1,18.5,23.1,18.5s0.7,0.2,0.7,0.3C175.8,278.6,177.7,287,175.3,307.1z" /><path display="inline" fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M175.8,277.7c0,0,21.3,17.6,29.6,17.9s15.7-4,16.6-4.5c0.9-0.4,19-9.1,33.1-20.7 M267,259.4c-3.2,3.5-7.3,7.3-11.9,11" /><path display="inline" fill="#696969" d="M199.5,231.6l-8.2-3.6c-0.4-0.2-0.5-0.7-0.2-1.1l3.3-3.4c0.4-0.4,1-0.5,1.6-0.3l13.2,4.8c0.6,0.2,0.6,1.1-0.1,1.4l-9.1,2.5C199.8,231.7,199.5,231.7,199.5,231.6z M175.5,278.2c0,0,26.5,36.4,43.2,32c16.8-4.4,43.7-21.8,43.7-21.8c1.3-9.1,2.2-19.7,3.3-28.7c-4.8,4.9-13.3,13.8-21.8,19.1c-5.2,3.2-22.1,15.1-36.4,16.7C200,296.3,175.5,278.2,175.5,278.2z"  /><ellipse display="inline" opacity="0.87" fill="#FF0057" enable-background="new    " cx="239.4" cy="248.4" rx="14" ry="15.1"  />',
                "Nihon"
            );
    }

    /// @dev Mask N°18 => BlindFold Tomoe Pure
    function item_18() public pure returns (string memory) {
        return base(blindfold("FFEDED", "B50D5E"), "BlindFold Tomoe Pure");
    }

    /// @dev Mask N°19 => Power Sticks Pure
    function item_19() public pure returns (string memory) {
        return base(powerStick("FFEDED"), "Power Sticks Pure");
    }

    /// @dev Mask N°20 => ???
    function item_20() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#F5F4F3" stroke="#000000" stroke-width="3" stroke-miterlimit="10" d="M290.1,166.9c0,71-20.4,132.3-81.2,133.3c-60.9,0.9-77.5-59.4-77.5-130.4s15-107.6,75.8-107.6C270.4,62.3,290.1,96,290.1,166.9z" /><path display="inline" opacity="8.000000e-02" enable-background="new    " d="M290,165.9c0,71-20.2,132.7-81.3,134.4c28.3-18.3,29.5-51.1,29.5-121.9S263,89,206.9,62.4C270.2,62.4,290,95,290,165.9z" /><ellipse display="inline" cx="245.9" cy="169.9" rx="17.6" ry="6.4" /><path display="inline" d="M233.7,266.5c0.3-7.5-12.6-6.4-28.3-6.4s-28.6-1.5-28.3,6.4c0.1,3.5,12.6,6.4,28.3,6.4S233.6,270,233.7,266.5z"  /><ellipse display="inline" cx="161.5" cy="169.7" rx="17" ry="6.3"  /><path display="inline" fill="#F2EDED" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M148.5,181c0,0,7,6,21.4,0.6"  /><path display="inline" fill="#F2EDED" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M235.2,180.9c0,0,6.9,5.9,21.3,0.6"  /><path display="inline" fill="#F2EDED" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M193.4,278.5c0,0,9.6,3.6,22.5,0"  /><path display="inline" fill="#996DAD" d="M149.8,190.5c1.6-3.8,17.9-3.5,19.6-0.4c1.9,3.3-5,47.5-6.9,47.8C159.2,238.6,146.9,201.5,149.8,190.5z"  /><path display="inline" fill="#996DAD" d="M236.3,189.8c1.6-3.8,18.8-2.8,20.5,0.3c3.9,6.7-6.8,47.3-9.7,47.2C243.6,237,233.4,200.8,236.3,189.8z"  /><path display="inline" fill="#996DAD" d="M233.6,149c1.4,2.4,15.3,2.2,16.8,0.2c1.7-2.1-4.3-28.8-7.5-29.3C239.4,119.5,231.1,142.3,233.6,149z"  /><path display="inline" fill="#996DAD" d="M151.9,151.7c1.4,2.4,15.3,2.2,16.8,0.2c1.7-2.1-4.3-28.8-7.5-29.3C157.8,122.1,149.5,144.9,151.9,151.7z"  />',
                "???"
            );
    }

    function powerStick(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    abi.encodePacked(
                        '<path style="fill:#',
                        color,
                        ";stroke:#",
                        color,
                        ';stroke-miterlimit:10;" d="M276.3,325.2l9.2-20.2c0.5-0.2,5-0.4,8.1,3.8l-9.3,20.1C280.7,329.3,277.8,328.2,276.3,325.2z"/><ellipse transform="matrix(0.4183 -0.9083 0.9083 0.4183 -110.5579 441.5047)" style="fill:#',
                        color,
                        ';" cx="289.4" cy="307.1" rx="1.7" ry="4.4"/><path d="M273.9,326.4c2.6,3.8,6.4,5.6,10.9,5.5C280.5,333.5,275,331.1,273.9,326.4z"/><path style="fill:#',
                        color,
                        ";stroke:#",
                        color,
                        ';stroke-miterlimit:10;" d="M304,341.3l9.9-19.9c0.5-0.1,5-0.3,7.9,4.1l-9.9,19.8C308.3,345.6,305.4,344.5,304,341.3z"/>'
                    ),
                    abi.encodePacked(
                        '<ellipse transform="matrix(0.4485 -0.8938 0.8938 0.4485 -113.8785 462.7307)" style="fill:#',
                        color,
                        ';" cx="318" cy="323.6" rx="1.7" ry="4.4"/><path d="M301.6,342.6c2.5,3.9,6.3,5.8,10.8,6C308.1,350,302.6,347.2,301.6,342.6z"/> <path style="fill:#',
                        color,
                        ";stroke:#",
                        color,
                        ';stroke-miterlimit:10;" d="M154.7,323.7l-7.1-21.1c-0.4-0.2-4.9-0.9-8.4,2.9l7.1,21.1C150,327.3,152.9,326.6,154.7,323.7z"/><ellipse transform="matrix(0.9467 -0.322 0.322 0.9467 -90.3736 62.4201)" style="fill:#',
                        color,
                        ';" cx="143.5" cy="304.4" rx="4.4" ry="1.7"/><path d="M157.1,325.2c-1.7,4.4-7.2,6.4-11.5,4.5C150,330.3,154.2,328.7,157.1,325.2z"/>'
                    ),
                    abi.encodePacked(
                        '<path style="fill:#',
                        color,
                        ";stroke:#",
                        color,
                        ';stroke-miterlimit:10;" d="M122.5,334.4l-7.7-20.8c-0.4-0.2-4.9-0.8-8.3,3.1l7.8,20.7C117.9,338.2,120.6,337.3,122.5,334.4z"/> <ellipse transform="matrix(0.9364 -0.3508 0.3508 0.9364 -103.5719 58.8717)" style="fill:#',
                        color,
                        ';" cx="110.7" cy="315.3" rx="4.4" ry="1.7"/><path d="M124.8,335.9c-1.4,4.4-6.9,6.8-11.2,4.8C117.9,341.1,122.2,339.3,124.8,335.9z"/>'
                    )
                )
            );
    }

    function blindfold(string memory colorBlindfold, string memory colorTomoe) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    abi.encodePacked(
                        '<path display="inline" opacity="0.22"  enable-background="new " d="M135.7,204.6 c0,0,45,25.9,146.6,0.3C287.1,206.1,189.1,221.5,135.7,204.6z"/> <g display="inline"> <path fill="#',
                        colorBlindfold,
                        '" stroke="#000000" stroke-miterlimit="10" d="M202.4,212.5c-26.8,0-49.2-2.8-66.6-8.4 c-5.3-14.6-5.5-31.4-5.5-36.5c19,5.4,44.2,6.6,74.8,6.6c46.3,0,91.3-7.8,99.7-9.1c-0.3,2.1-1.4,9-1.5,10.4 c-1.1,1.3-4.4,4.5-5.5,5.3c-3.1,2.1-2.1,2.4-5.4,7.1c0,0-2.7,5.1-3.2,6.4c-4.8,12.1-6.1,9.6-18.8,13.3 C246.2,210.8,223.3,212.5,202.4,212.5z"/> </g> <g display="inline"> <path fill="none" stroke="#000000" stroke-miterlimit="10" d="M283.6,203.5c0,0,17-24.4,14.9-37.3"/> <g opacity="0.91"> <path d="M133.9,168.6c4,4.6,8,9.1,12.2,13.4c1,1.1,2.1,2.2,3.1,3.2l1.6,1.7l1.7,1.6c2.2,2.1,4.6,4,6.9,5.8 c4.8,3.8,9.8,7.1,14.9,10.2c5.2,3,10.6,5.6,16.4,7.7l0,0l0,0c-5.8-1.7-11.5-4.1-16.7-7.1c-5.2-3.1-10.1-6.7-14.8-10.5 c-2.3-2-4.6-4-6.8-6c-1.1-1-2.3-2-3.3-3c-1.1-1-2.2-2.1-3.3-3.1c-2.2-2.1-4.2-4.4-6.1-6.7C137.5,173.5,135.6,171.1,133.9,168.6 L133.9,168.6L133.9,168.6z"/> </g> <g opacity="0.91"> <path d="M201.4,212.6c3.6-0.5,7.2-1.8,10.6-3.1c3.4-1.4,6.9-2.8,10.2-4.3c3.4-1.5,6.8-3,10.1-4.7s6.6-3.5,9.7-5.4 c6.4-3.8,12.6-7.7,18.8-11.9c3-2.1,6-4.3,9-6.6c2.9-2.3,5.7-4.7,8.1-7.5c0,0,0,0,0.1,0c0,0,0,0,0,0.1c-2.2,3-5,5.5-7.8,7.9 s-5.8,4.6-8.9,6.8c-6.1,4.3-12.5,8-19.1,11.6l-9.8,5.2c-3.3,1.7-6.6,3.4-9.9,5.1c-3.3,1.6-6.8,3-10.3,4.3 C208.7,211.2,205,212.4,201.4,212.6L201.4,212.6L201.4,212.6z"/> </g> <path opacity="0.14"  enable-background="new " d="M278.4,169.7 c0,0-25.9,38-71.8,42.3C206.6,211.9,252.6,193.4,278.4,169.7z"/> <path opacity="0.14"  enable-background="new " d="M297.3,166.3c0,0,5,10-14.5,37.2 C282.8,203.5,293.4,184.2,297.3,166.3z"/> <path opacity="0.14"  enable-background="new " d="M133.6,169 c0,0,12.5,34.7,54.9,42.9C188.6,212.1,155.2,197,133.6,169z"/> <polygon opacity="0.18"  enable-background="new " points="298.4,166.6 295.8,181.6 303.6,175.7 304.9,165.1 "/> <path opacity="0.2"  stroke="#000000" stroke-miterlimit="10" enable-background="new " d=" M131.2,168.4c0,0,55.6,17.3,172.7-3.2C308.7,166.4,183.7,189.6,131.2,168.4z"/> </g> <g display="inline"> <g> <path  fill="#',
                        colorTomoe,
                        '" d="M202.3,199.8c0,0-0.6,5.1-8.1,8.1c0,0,2.5-2.3,2.9-5.2"/> <path  fill="#',
                        colorTomoe,
                        '" d="M202.3,200.1c0.8-2.3-0.4-4.7-2.7-5.4 c-2.3-0.8-4.7,0.4-5.4,2.7c-0.8,2.3,0.4,4.7,2.7,5.4C199,203.5,201.4,202.4,202.3,200.1z M196.7,198.2c0.3-0.8,1-1.1,1.8-0.9 c0.8,0.3,1.1,1,0.9,1.8c-0.3,0.8-1,1.1-1.8,0.9C196.9,199.9,196.5,199,196.7,198.2z"/> </g>'
                    ),
                    abi.encodePacked(
                        '<g> <path  fill="#',
                        colorTomoe,
                        '" d="M205.4,183.2c0,0,4.8-1.9,11,3.2c0,0-3.2-1.1-5.9-0.1"/> <path  fill="#',
                        colorTomoe,
                        '" d="M205.5,183.1c-2.4,0.4-4,2.7-3.4,5c0.4,2.4,2.7,4,5,3.4 c2.4-0.4,4-2.7,3.4-5C210.2,184.2,207.9,182.7,205.5,183.1z M206.6,188.8c-0.8,0.1-1.5-0.4-1.7-1.1c-0.1-0.8,0.4-1.5,1.1-1.7 c0.8-0.1,1.5,0.4,1.7,1.1S207.3,188.6,206.6,188.8z"/> </g> <g> <path  fill="#',
                        colorTomoe,
                        '" d="M187.5,190.7c0,0-4.4-2.6-4.3-10.7c0,0,1,3.2,3.5,4.7"/> <path  fill="#',
                        colorTomoe,
                        '" d="M187.3,190.6c1.8,1.7,4.5,1.5,6-0.3c1.7-1.8,1.5-4.5-0.3-6 c-1.8-1.7-4.5-1.5-6,0.3C185.4,186.3,185.4,188.9,187.3,190.6z M191.2,186.2c0.6,0.6,0.6,1.4,0.1,2c-0.6,0.6-1.4,0.6-2,0.1 c-0.6-0.6-0.6-1.4-0.1-2C189.6,185.8,190.4,185.8,191.2,186.2z"/> </g> </g>'
                    )
                )
            );
    }

    function horn(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g><path d="M199.5,130.4c-6.8-.1-13.1-6.5-15-15.2,1.5-25.1,9.6-74.1,12.4-90.7,1.5,30.2,18.4,88.63,19.5,92.33-4.2,10.6-10,13.67-16.9,13.57Z" transform="translate(0 0.5)" fill="#',
                    color,
                    '"/> <path d="M196.6,28.9c2.7,30.6,17.1,83.43,18.6,88.13-4.2,10.4-9.2,13-15.8,12.87s-12.6-6.3-14.5-14.7c1.6-23.3,8.6-66.7,11.7-86.3m.7-10.2S186,85.75,184.19,116.45c1.9,8.9,8.11,14.15,15.31,14.35,6.1.1,12.1-1.57,16.9-14,0,.1-19.9-68.83-19.1-98.13Z" transform="translate(0 0.5)"/> <path d="M185.38,115.74s1.09,14.54,12.58,15c10.49.43,13.21-4.4,16.69-13.85" transform="translate(0 0.5)" fill="#',
                    color,
                    '" stroke="#',
                    color,
                    '" stroke-linecap="round" stroke-miterlimit="10" /></g>'
                )
            );
    }

    function strap(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g><path id="Classic" d="M174.76,306.81s22.1,16.3,86.9.5c0,0-.5-15.3,4.6-47.1l16.5-21.3s-46-28.7-83.5-38.3c-1.1-.3-3.1-.7-4.2-.2-19.9,8.4-54.1,34.8-54.1,34.8s9,20.8,10.8,23.4c1.4,2,23.1,18.5,23.1,18.5s.7.2.7.3C175.76,278.61,177.06,286.71,174.76,306.81Z" transform="translate(0 0.5)" fill="#',
                    color,
                    '" stroke="#000" stroke-miterlimit="10"/><path d="M199.5,231.6l-8.2-3.6a.71.71,0,0,1-.2-1.1l3.3-3.4a1.53,1.53,0,0,1,1.6-.3l13.2,4.8a.75.75,0,0,1-.1,1.4l-9.1,2.5C199.8,231.7,199.5,231.7,199.5,231.6Zm-24,46.6s26.5,36.4,43.2,32,43.7-21.8,43.7-21.8c1.3-9.1,2.2-19.7,3.3-28.7-4.8,4.9-13.3,13.8-21.8,19.1-5.2,3.2-22.1,15.1-36.4,16.7C200,296.3,175.5,278.2,175.5,278.2Z" transform="translate(0 0.5)" opacity="0.21" style="isolation: isolate"/> <path d="M142.2,237.5c35.7-22.7,64-30.2,98.5-21.1m30.6,36.9c-21.9-16.9-64.5-38-78.5-32.4-13.3,7.4-37,18-46.8,25.3m88-15.4c-33.8,2.6-57.2.1-84.7,23.6m115.5,7.2c-20.5-14.5-48.7-25.1-73.9-27m23,3.8c-19.3,2-43.6,11.7-59.1,22.8m106.1,4.2c-47.9-12.4-52.5-26.6-98,2.8m69.2-11.5c-20.7.3-43.9,9.9-63.3,16.4m72.4,7.2c-11.5-4.1-40.1-14.8-52.5-14.2m28.3,6c-10.7-2.9-24,7.9-32,13.1m39.3,4.8c-4-5.7-23-7.4-28.1-11.9M175.5,302c4.3,3.8,21.4,7.3,39.5,7.2,18.5-.1,38.1-4,46.6-8.6M176.4,294c11.6,3.8,18.2,7.3,38.1,5.9,15.1-1,34.3-4,47.8-10.7m-38.25.63c9.4,0,29.85-4.63,38.65-7.53m-21.8-2c3.4.4,20-5.4,23.6-6.8m-47-60.8a141,141,0,0,0-19.8-3.2c-5-.3-15.5-.2-20.6.6" transform="translate(0 0.5)" fill="none" stroke="#000" stroke-miterlimit="10"/> </g>'
                )
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "None";
        } else if (id == 2) {
            name = "Uni Horn Blood";
        } else if (id == 3) {
            name = "Power Sticks";
        } else if (id == 4) {
            name = "Uni Horn Moon";
        } else if (id == 5) {
            name = "Power Neck";
        } else if (id == 6) {
            name = "Bouc";
        } else if (id == 7) {
            name = "BlindFold Tomoe Blood";
        } else if (id == 8) {
            name = "Strap Blood";
        } else if (id == 9) {
            name = "Sun Glasses";
        } else if (id == 10) {
            name = "Uni Horn Pure";
        } else if (id == 11) {
            name = "Strap Moon";
        } else if (id == 12) {
            name = "BlindFold Tomoe Moon";
        } else if (id == 13) {
            name = "Stitch";
        } else if (id == 14) {
            name = "Strap Pure";
        } else if (id == 15) {
            name = "Eye Patch";
        } else if (id == 16) {
            name = "Eye";
        } else if (id == 17) {
            name = "Nihon";
        } else if (id == 18) {
            name = "BlindFold Tomoe Pure";
        } else if (id == 19) {
            name = "Power Sticks Pure";
        } else if (id == 20) {
            name = "???";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="mask"><g id="', name, '">', children, "</g></g>"));
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