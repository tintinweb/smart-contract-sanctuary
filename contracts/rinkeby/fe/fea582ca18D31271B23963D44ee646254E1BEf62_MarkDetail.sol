// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Mark SVG generator
library MarkDetail {
    /// @dev Mark N°1 => None
    function item_1() public pure returns (string memory) {
        return base("", "None");
    }

    /// @dev Mark N°2 => Dark circle
    function item_2() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path d="M163,210.9c4.8,0.2,9.5-1.4,13.9-3.3C173,210.4,167.7,211.7,163,210.9z" /><path d="M159,210.1c-2.4-0.4-4.7-1.7-6.7-3.1C154.5,207.9,156.8,209,159,210.1z" /></g><g display="inline" ><path d="M236.6,210.4c5.3,0.1,10.5-1.5,15.3-3.5C247.8,209.8,241.9,211.1,236.6,210.4z" /><path d="M232.1,209.6c-2.7-0.4-5.2-1.6-7.3-3C227.3,207.5,229.8,208.6,232.1,209.6z" /></g>',
                "Dark Circle"
            );
    }

    /// @dev Mark N°3 => Akuma Blood
    function item_3() public pure returns (string memory) {
        return base(akuma("b50d5e"), "Akuma Blood");
    }

    /// @dev Mark N°4 => Brother
    function item_4() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path  d="M220.1,206.2c0,0,15.2,24.7,32.7,39.1" /><path d="M220.1,206.2c1.3,1.8,2.4,3.5,3.8,5.2c1.3,1.8,2.5,3.4,3.8,5.1c2.6,3.4,5.1,6.7,7.8,10c2.6,3.3,5.5,6.4,8.3,9.6c1.5,1.6,2.9,3.1,4.5,4.6c1.5,1.6,3.1,2.9,4.6,4.5c-3.4-2.6-6.6-5.4-9.6-8.3c-3-3-5.8-6.2-8.5-9.5s-5.3-6.7-7.7-10.1C224.6,213.4,222.2,209.9,220.1,206.2z" /></g><g display="inline" ><path  d="M182.1,207c0,0-9.1,20.2-23.7,37.8" /><path d="M182.1,207c-1.4,3.4-3,6.9-4.7,10.1c-1.7,3.3-3.5,6.6-5.5,9.7c-2,3.1-4.1,6.3-6.3,9.3s-4.6,5.8-7.1,8.6c1-1.6,2.2-3,3.2-4.5l1.7-2.3l1.6-2.3c2.1-3.1,4.2-6.1,6-9.4c2-3.1,3.9-6.4,5.7-9.6c0.9-1.6,1.9-3.2,2.7-4.9C180.5,210.2,181.2,208.6,182.1,207z" /></g>',
                "Brother"
            );
    }

    /// @dev Mark N°5 => Chin Spiral
    function item_5() public pure returns (string memory) {
        return
            base(
                '<path display="inline" d="M203.4,279.3c0.2-0.6,0.4-1.4,1-1.9c0.3-0.2,0.7-0.4,1.1-0.3c0.4,0.1,0.7,0.4,0.9,0.7c0.4,0.6,0.5,1.5,0.5,2.2s-0.3,1.6-0.8,2.1c-0.5,0.6-1.4,0.9-2.2,0.8s-1.6-0.5-2.1-0.9c-0.6-0.4-1.1-1-1.6-1.7c-0.4-0.6-0.6-1.5-0.6-2.3c0.2-1.7,1.5-2.9,2.8-3.5c1.4-0.6,2.9-0.8,4.4-0.5c0.7,0.1,1.5,0.4,2.1,0.9s0.9,1.3,1,2c0.2,1.5-0.2,3-1.3,4.1c0.7-1.1,1-2.6,0.7-4c-0.2-0.6-0.5-1.3-1-1.6c-0.5-0.4-1.1-0.6-1.8-0.6c-1.4-0.1-2.7,0-3.9,0.6c-1.1,0.5-2.1,1.6-2.2,2.7c-0.1,1.1,0.7,2.3,1.7,3.1c0.5,0.4,1,0.8,1.6,0.8c0.5,0.1,1.1-0.1,1.6-0.5c0.4-0.4,0.7-0.9,0.7-1.7c0.1-0.6,0-1.4-0.3-1.9c-0.1-0.3-0.4-0.5-0.6-0.6c-0.3-0.1-0.6,0-0.8,0.1C204,278,203.5,278.7,203.4,279.3z"  />',
                "Chin Spiral"
            );
    }

    /// @dev Mark N°6 => Akuma Moon
    function item_6() public pure returns (string memory) {
        return base(akuma("000000"), "Akuma Moon");
    }

    /// @dev Mark N°7 => Full Moon
    function item_7() public pure returns (string memory) {
        return
            base(
                '<ellipse display="inline" fill="#B50D5E" cx="200.9" cy="146.5" rx="13.4" ry="13.4"  />',
                "Blood Full Moon"
            );
    }

    /// @dev Mark N°8 => Moon Blood
    function item_8() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#B50D5E" d="M218.2,146.2c0.2-6-2.7-11.5-7.2-14.7c2.3,2.5,3.8,5.7,3.6,9.4c-0.2,7.4-6.5,13.2-14.2,13s-13.7-6.4-13.5-13.8c0.1-3.5,1.7-6.9,4.1-9.2c-4.7,3.1-7.8,8.3-8,14.3c-0.2,9.7,7.5,17.8,17.2,18C209.7,163.6,217.9,156,218.2,146.2z"  />',
                "Blood Moon"
            );
    }

    /// @dev Mark N°9 => Tomoe Blood
    function item_9() public pure returns (string memory) {
        return base(tomoe("B50D5E"), "Tomoe Blood");
    }

    /// @dev Mark N°10 => Scar
    function item_10() public pure returns (string memory) {
        return
            base(
                '<path fill="#FF7478" d="M239.9,133.5c0,0-7.5,51,0.2,101.2C240.1,234.7,248.8,188.3,239.9,133.5z"  />',
                "Scar"
            );
    }

    /// @dev Mark N°11 => Tomoe Moon
    function item_11() public pure returns (string memory) {
        return base(tomoe("000000"), "Tomoe Moon");
    }

    /// @dev Mark N°12 => Cheeks Blood
    function item_12() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path fill="#E31466" d="M175.8,215.3c-8.6,0.4-17,0.3-25-0.3c-0.4,0-0.8-0.4-0.8-0.8v-3c0-0.4,0.4-0.8,0.8-0.8c7.7,0.7,16.2,0.8,25,0.3c0.4,0,0.8,0.4,0.8,0.8v3C176.5,214.9,176.2,215.3,175.8,215.3z" /><path fill="#E31466" d="M175.5,223.6c-8.6,0.4-17,0.3-25-0.3c-0.4,0-0.8-0.4-0.8-0.8v-3c0-0.4,0.4-0.8,0.8-0.8c7.7,0.7,16.2,0.8,25,0.3c0.4,0,0.8,0.4,0.8,0.8v3C176.3,223.3,176,223.6,175.5,223.6z" /></g><g display="inline" ><path fill="#E31466" d="M255.8,215.5c-8.6,0.6-17,0.7-25,0.2c-0.4,0-0.8-0.3-0.8-0.8v-3c0-0.4,0.3-0.8,0.8-0.8c7.7,0.5,16.2,0.4,25-0.2c0.4,0,0.8,0.3,0.8,0.8v3C256.7,215.1,256.4,215.5,255.8,215.5z" /><path fill="#E31466" d="M255.8,223.9c-8.6,0.6-17,0.7-25,0.2c-0.4,0-0.8-0.3-0.8-0.8v-3c0-0.4,0.3-0.8,0.8-0.8c7.7,0.5,16.2,0.4,25-0.2c0.4,0,0.8,0.3,0.8,0.8v3C256.5,223.5,256.2,223.9,255.8,223.9z" /></g>',
                "Cheeks Blood"
            );
    }

    /// @dev Mark N°13 => Kitsune
    function item_13() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><g><path  fill="#B50D5E" d="M264,242c0,0-11.8-5.9-30.5-6.8" /><path fill="#B50D5E" d="M264,242c-1.3-0.4-2.5-0.9-3.8-1.3c-1.3-0.4-2.5-0.8-3.8-1.1c-2.5-0.7-5-1.4-7.6-1.9c-2.5-0.5-5.1-1-7.7-1.5c-2.6-0.4-5.2-0.7-7.8-1c1.4,0,2.6,0,4,0c1.4,0.1,2.6,0.1,4,0.3c2.6,0.2,5.2,0.7,7.8,1.1c2.6,0.5,5.1,1.3,7.6,2.1C259.4,239.7,261.9,240.6,264,242z" /></g><g><path  fill="#B50D5E" d="M267.1,232.8c0,0-11.8-5.9-30.5-6.8" /><path fill="#B50D5E" d="M267.1,232.8c-1.3-0.4-2.5-0.9-3.8-1.3c-1.3-0.4-2.5-0.8-3.8-1.1c-2.5-0.7-5-1.4-7.6-1.9c-2.5-0.5-5.1-1-7.7-1.5s-5.2-0.7-7.8-1c1.4,0,2.6,0,4,0c1.4,0.1,2.6,0.1,4,0.3c2.6,0.2,5.2,0.7,7.8,1.1c2.6,0.5,5.1,1.3,7.6,2.1C262.4,230.5,264.9,231.5,267.1,232.8z" /></g><g><path  fill="#B50D5E" d="M268.1,223.4c0,0-11.8-5.9-30.5-6.8" /><path fill="#B50D5E" d="M268.1,223.4c-1.3-0.4-2.5-0.9-3.8-1.3c-1.3-0.4-2.5-0.8-3.8-1.1c-2.5-0.7-5-1.4-7.6-1.9c-2.5-0.5-5.1-1-7.7-1.5c-2.6-0.4-5.2-0.7-7.8-1c1.4,0,2.6,0,4,0c1.4,0.1,2.6,0.1,4,0.3c2.6,0.2,5.2,0.7,7.8,1.1c2.6,0.5,5.1,1.3,7.6,2.1C263.4,221.1,265.9,222.1,268.1,223.4z" /></g></g><g display="inline" ><g><path  fill="#B50D5E" d="M142.9,223c0,0,11-5.7,28.8-6.5" /><path fill="#B50D5E" d="M142.9,223c2.1-1.3,4.5-2.2,6.8-3s4.8-1.5,7.2-2.1c2.4-0.5,4.9-0.9,7.4-1.1c1.3-0.1,2.5-0.2,3.8-0.2s2.5,0,3.8,0c-2.5,0.3-4.9,0.6-7.3,1s-4.8,0.8-7.3,1.4c-2.4,0.5-4.8,1.1-7.2,1.8c-1.1,0.3-2.4,0.7-3.5,1C145.2,222.2,144.1,222.6,142.9,223z" /></g><g><path  fill="#B50D5E" d="M148.1,241.8c0,0,11-5.7,28.8-6.5" /><path fill="#B50D5E" d="M148.1,241.8c2.1-1.3,4.5-2.2,6.8-3s4.8-1.5,7.2-2.1c2.4-0.5,4.9-0.9,7.4-1.1c1.3-0.1,2.5-0.2,3.8-0.2s2.5,0,3.8,0c-2.5,0.3-4.9,0.6-7.3,1s-4.8,0.8-7.3,1.4c-2.4,0.5-4.8,1.1-7.2,1.8c-1.1,0.3-2.4,0.7-3.5,1C150.4,240.9,149.3,241.4,148.1,241.8z" /></g><g><path  fill="#B50D5E" d="M145.1,232.6c0,0,11-5.7,28.8-6.5" /><path fill="#B50D5E" d="M145.1,232.6c2.1-1.3,4.5-2.2,6.8-3s4.8-1.5,7.2-2.1c2.4-0.5,4.9-0.9,7.4-1.1c1.3-0.1,2.5-0.2,3.8-0.2s2.5,0,3.8,0c-2.5,0.3-4.9,0.6-7.3,1c-2.4,0.4-4.8,0.8-7.3,1.4c-2.4,0.5-4.8,1.1-7.2,1.8c-1.1,0.3-2.4,0.7-3.5,1C147.4,231.8,146.3,232.2,145.1,232.6z" /></g></g>',
                "Kitsune"
            );
    }

    /// @dev Mark N°14 => Cheeks Pure
    function item_14() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path fill="#FFEDED" d="M173.8,217.3c-8.6,0.4-17,0.3-25-0.3c-0.4,0-0.8-0.4-0.8-0.8v-3c0-0.4,0.4-0.8,0.8-0.8c7.7,0.7,16.2,0.8,25,0.3c0.4,0,0.8,0.4,0.8,0.8v3C174.5,216.9,174.2,217.3,173.8,217.3z" /><path fill="#FFEDED" d="M173.5,225.6c-8.6,0.4-17,0.3-25-0.3c-0.4,0-0.8-0.4-0.8-0.8v-3c0-0.4,0.4-0.8,0.8-0.8c7.7,0.7,16.2,0.8,25,0.3c0.4,0,0.8,0.4,0.8,0.8v3C174.3,225.3,174,225.6,173.5,225.6z" /></g><g display="inline" ><path fill="#FFEDED" d="M253.8,217.5c-8.6,0.6-17,0.7-25,0.2c-0.4,0-0.8-0.3-0.8-0.8v-3c0-0.4,0.3-0.8,0.8-0.8c7.7,0.5,16.2,0.4,25-0.2c0.4,0,0.8,0.3,0.8,0.8v3C254.7,217.1,254.4,217.5,253.8,217.5z" /><path fill="#FFEDED" d="M253.8,225.9c-8.6,0.6-17,0.7-25,0.2c-0.4,0-0.8-0.3-0.8-0.8v-3c0-0.4,0.3-0.8,0.8-0.8c7.7,0.5,16.2,0.4,25-0.2c0.4,0,0.8,0.3,0.8,0.8v3C254.5,225.5,254.2,225.9,253.8,225.9z" /></g>',
                "Cheeks Pure"
            );
    }

    /// @dev Mark N°15 => YinYang
    function item_15() public pure returns (string memory) {
        return
            base(
                '<path d="M218.1,361.41a15.58,15.58,0,0,0-15.5-15.5h-1.3a15.48,15.48,0,0,0,1.4,30.9A15.22,15.22,0,0,0,218.1,361.41Zm-13.7-7.1a2,2,0,1,1-2-2A1.94,1.94,0,0,1,204.4,354.31Zm4.7,14.5a7,7,0,0,1-7.2,6.9h0a14.4,14.4,0,0,1-13.8-14.3,14.18,14.18,0,0,1,9.7-13.5,7.83,7.83,0,0,0-3.5,6.5,7.6,7.6,0,0,0,7.6,7.6h0A7,7,0,0,1,209.1,368.81Zm-6.6,2.2a2,2,0,1,1,2-2A2.07,2.07,0,0,1,202.5,371Z" transform="translate(0 0.5)" fill="#0a0a02" opacity="0.93" style="isolation: isolate"/> <circle cx="143.6" cy="355.84" r="6.81" fill="#0a0a02"/> <circle cx="263.68" cy="359.93" r="6.81" fill="none" stroke="#000"/>',
                "YinYang"
            );
    }

    /// @dev Mark N°16 => Double Scar
    function item_16() public pure returns (string memory) {
        return
            base(
                '<path id="Scar" display="inline" fill="#FF7478" d="M239.9,133.5c0,0-7.5,51,0.2,101.2C240.1,234.7,248.8,188.3,239.9,133.5z"  /><path id="Scar" display="inline" fill="#FF7478" d="M163.7,135.1c0,0-6.9,51.1,1.6,101.2C165.2,236.2,173.1,189.8,163.7,135.1z"  />',
                "Double Scar"
            );
    }

    /// @dev Mark N°17 => Moon Pure
    function item_17() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#FFEDED" d="M218.2,146.2c0.2-6-2.7-11.5-7.2-14.7c2.3,2.5,3.8,5.7,3.6,9.4c-0.2,7.4-6.5,13.2-14.2,13s-13.7-6.4-13.5-13.8c0.1-3.5,1.7-6.9,4.1-9.2c-4.7,3.1-7.8,8.3-8,14.3c-0.2,9.7,7.5,17.8,17.2,18C209.7,163.6,217.9,156,218.2,146.2z"  />',
                "Pure Moon"
            );
    }

    /// @dev Mark N°18 => Akuma Pure
    function item_18() public pure returns (string memory) {
        return base(akuma("FFEDED"), "Akuma Pure");
    }

    /// @dev Mark N°19 => Tomoe Pure
    function item_19() public pure returns (string memory) {
        return base(tomoe("FFEDED"), "Tomoe Pure");
    }

    /// @dev Mark N°20 => Eye
    function item_20() public pure returns (string memory) {
        return
            base(
                '<path d="M203.3,344.4c0,0-16.4,12.2-7.2,35C196.3,379.3,212.5,366.2,203.3,344.4z"/> <g> <path d="M208.4,351.4c0.4,2.1,0.6,4.2,0.5,6.3c-0.1,2.1-0.3,4.2-0.7,6.3s-1.1,4.2-2.1,6.1c-0.8,1.9-2.2,3.7-3.5,5.3 c0.3-0.4,0.5-0.9,0.8-1.4l0.4-0.6l0.3-0.7l0.7-1.4l0.7-1.4c0.8-1.9,1.4-3.9,1.9-6c0.5-2,0.7-4.1,0.9-6.2c0.1-1,0.1-2.1,0.1-3.1 C208.4,353.5,208.4,352.4,208.4,351.4z"/> </g> <g> <path d="M191.5,362.4c-0.1,1.3-0.1,2.5-0.1,3.8c0,1.3,0,2.5,0.1,3.8c0,1.3,0.2,2.5,0.5,3.8c0.2,1.2,0.5,2.4,1,3.7 c-0.6-1-1.1-2.3-1.4-3.5c-0.3-1.2-0.4-2.5-0.6-3.8c0-1.3,0-2.5,0-3.8C191.1,364.8,191.2,363.6,191.5,362.4z"/> </g> <ellipse transform="matrix(3.212132e-02 -0.9995 0.9995 3.212132e-02 -158.675 548.08)"  fill="#FFFFFF" cx="203.7" cy="356" rx="2.9" ry="0.7"/>',
                "Eye"
            );
    }

    /// @dev Mark N°21 => TORI
    function item_21() public pure returns (string memory) {
        return
            base(
                '<line display="inline" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" x1="234.4" y1="209.2" x2="234.4" y2="216.3"  /><path display="inline" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M231.8,208.8c0,0,3.3,0.4,5.7,0.2"  /><path display="inline" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M240.9,209.2c0,0-3.6,3.2,0,6.6S245.9,209.2,240.9,209.2z"  /><path display="inline" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M246.9,215.7l-1.3-6.7c0,0,9.1-2.1,1,2.9l3.3,3.1"  /><line display="inline" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" x1="252.4" y1="208.6" x2="252.4" y2="215.4"  />',
                "TORI"
            );
    }

    /// @dev Mark N°22 => Kin Moon
    function item_22() public pure returns (string memory) {
        return
            base(
                '<linearGradient id="Kin Moon Gradient" gradientUnits="userSpaceOnUse" x1="182.9962" y1="-417.0576" x2="218.2097" y2="-417.0576" gradientTransform="matrix(1 0 0 -1 0 -270)" ><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7EC94" /><stop offset="1" style="stop-color:#FF9121" /></linearGradient><path fill="url(#Kin_Moon_Gradient)" d="M218.2,146.2c0.2-6-2.7-11.5-7.2-14.7c2.3,2.5,3.8,5.7,3.6,9.4c-0.2,7.4-6.5,13.2-14.2,13s-13.7-6.4-13.5-13.8c0.1-3.5,1.7-6.9,4.1-9.2c-4.7,3.1-7.8,8.3-8,14.3c-0.2,9.7,7.5,17.8,17.2,18C209.7,163.6,217.9,156,218.2,146.2z"  />',
                "Kin Moon"
            );
    }

    function tomoe(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path d="M289,339.8h0a5,5,0,1,0,0,7.3l.4-.4v.1c2.7,1.9,3.6,5.8,3.6,5.8C293.9,343.3,289,339.8,289,339.8Zm-2.2,5a1.7,1.7,0,1,1,.1-2.4A1.72,1.72,0,0,1,286.8,344.8Z" fill="#',
                    color,
                    '" /> <path d="M275.1,347.9h0a5,5,0,1,0-2.5,6.6c.1-.1.2-.1.4-.2,1.8,2.7,1.5,6.6,1.5,6.6C277.8,353.8,275.8,349.2,275.1,347.9Zm-3.9,3.5a1.62,1.62,0,0,1-2.2-.8,1.66,1.66,0,1,1,2.2.8Z" fill="#',
                    color,
                    '" /> <path d="M136.6,339.1a5.08,5.08,0,0,0-6.9,0h0s-4.9,3.5-4,12.8c0,0,.9-3.9,3.6-5.8V346c.1.1.2.3.4.4a5,5,0,1,0,6.9-7.3Zm-2.2,4.9a2,2,0,0,1-2.4.1,1.7,1.7,0,1,1,2.4-.1Z" fill="#',
                    color,
                    '" /> <path d="M150.5,344.6a5.14,5.14,0,0,0-6.7,2.5c0,.1-.1.1-.1.2-.7,1.4-2.5,6,.7,12.9,0,0-.3-3.9,1.5-6.6.1.1.2.1.4.2a5.06,5.06,0,0,0,4.2-9.2Zm-.7,5.3a1.66,1.66,0,1,1-.8-2.2A1.65,1.65,0,0,1,149.8,349.9Z" fill="#',
                    color,
                    '" />',
                    abi.encodePacked(
                        '<path d="M224.09,355.4a5.13,5.13,0,0,0-6.4-2.9,5.06,5.06,0,1,0,3.5,9.5c.1-.1.3-.1.4-.2,1.6,2.9,1,6.8,1,6.8C226.89,360.9,224.49,356,224.09,355.4Zm-4,3.5a2,2,0,0,1-2.2-1,1.71,1.71,0,1,1,2.2,1Z" fill="#',
                        color,
                        '" /> <path d="M189.79,352a4.94,4.94,0,0,0-6.5,2.5h0s-3.3,5,.8,13.4c0,0-.4-4,1.4-6.8h0a.76.76,0,0,0,.4.2,5,5,0,0,0,3.9-9.3Zm-.6,5.3c-.2,1-1.2,1.3-2.2.9a1.68,1.68,0,1,1,2.2-.9Z" fill="#',
                        color,
                        '" />'
                    )
                )
            );
    }

    function akuma(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g id="Eye_Mark" > <path d="M237.6,223c0-3.6,2.6-85.2,2.8-88.9s-1.8-24.7-1.6-28.3c5.6-6.5,12-33.11,15.92-33.27-4.46,2.4-8.32,29.47-11.52,33.27l-.2,31.1c.13,4.65-2.48,81.07-2.2,86.2a17.68,17.68,0,0,0-1.6,2.2A23.4,23.4,0,0,0,237.6,223Z" transform="translate(0 0.5)" fill="#',
                    color,
                    '"/> </g> <g id="Eye_Mark-2"> <path d="M163.2,221.8c-.1-3.6.1-88.4.2-92s1.8-21.8,2-25.4c5.5-6.6,13.87-34.73,18.37-34.63-5.3,2-11.77,33-14.87,37l-2.8,25.6c.2,3.6,0,85.7.3,89.3l-1.7,3.1Z" transform="translate(0 0.5)" fill="#',
                    color,
                    '"/> </g>'
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
            name = "Dark Circle";
        } else if (id == 3) {
            name = "Akuma Blood";
        } else if (id == 4) {
            name = "Brother";
        } else if (id == 5) {
            name = "Chin Spiral";
        } else if (id == 6) {
            name = "Akuma Moon";
        } else if (id == 7) {
            name = "Full Moon";
        } else if (id == 8) {
            name = "Moon Blood";
        } else if (id == 9) {
            name = "Tomoe Blood";
        } else if (id == 10) {
            name = "Scar";
        } else if (id == 11) {
            name = "Tomoe Moon";
        } else if (id == 12) {
            name = "Cheeks Blood";
        } else if (id == 13) {
            name = "Kitsune";
        } else if (id == 14) {
            name = "Cheeks Pure";
        } else if (id == 15) {
            name = "YinYang";
        } else if (id == 16) {
            name = "Double Scar";
        } else if (id == 17) {
            name = "Moon Pure";
        } else if (id == 18) {
            name = "Akuma Pure";
        } else if (id == 19) {
            name = "Tomoe Pure";
        } else if (id == 20) {
            name = "Eye";
        } else if (id == 21) {
            name = "TORI";
        } else if (id == 22) {
            name = "Kin Moon";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="mark"><g id="', name, '">', children, "</g></g>"));
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