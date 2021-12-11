//SPDX-License-Identifier: Unlicense
/// @title: PonziRugs library
/// @author: Rug Dev

pragma solidity ^0.8.0;

library PonziRugsGenerator {
    struct PonziRugsStruct 
    {
        uint pattern;
        uint background;
        uint colorOne;
        uint colorTwo;
        uint colorThree;
        bool set;
        string metadata;
        string combination;
    }

    struct RandValues {
        uint256 patternSelect;
        uint256 backgroundSelect;
    }

    function getRugForSeed(uint256[] memory combination) external pure returns (PonziRugsStruct memory, string memory)
    {
        PonziRugsStruct memory rug;
        RandValues memory rand;
        string[10] memory patterns = ["Ether", "Circles", "Hoots", "Kaiju", "Heart", "Persian", "Encore", "Kubrick", "Mozaic", "NGMI"];
        
        string[21] memory colors =  ["deeppink", "darkturquoise", "orange", "gold", "white", "silver", "green", 
                                    "darkviolet", "orangered", "lawngreen", "mediumvioletred", "red", "olivedrab",
                                    "bisque", "cornsilk", "darkorange", "slateblue", "floralwhite", "khaki", "crimson", "thistle"];

        string[21] memory ngmiPalette = ["black", "red", "green", "blue", "maroon", "violet", "tan", "turquoise", "cyan", 
                                        "darkred", "darkorange", "crimson", "darkviolet", "goldenrod", "forestgreen", "lime", "magenta", 
                                        "springgreen", "teal", "navy", "indigo"];

        // Determine the Pattern for the rug
        rand.patternSelect = combination[0];

        if(rand.patternSelect < 1) rug.pattern = 9;
        else if (rand.patternSelect < 60)  rug.pattern = 8;
        else if (rand.patternSelect < 100) rug.pattern = 7;
        else if (rand.patternSelect < 160) rug.pattern = 6;
        else if (rand.patternSelect < 240) rug.pattern = 5;
        else if (rand.patternSelect < 340) rug.pattern = 4;
        else if (rand.patternSelect < 460) rug.pattern = 3;
        else if (rand.patternSelect < 580) rug.pattern = 2;
        else if (rand.patternSelect < 780) rug.pattern = 1;
        else  rug.pattern = 0;

        // Rug Traits
        rug.background  = combination[1];
        rug.colorOne    = combination[2];
        rug.colorTwo    = combination[3];
        rug.colorThree  = combination[4];
        rug.set         = (rug.colorOne == rug.colorTwo) && (rug.colorTwo == rug.colorThree);
        rug.combination = string(abi.encodePacked(Utils.uint2str(rug.pattern), Utils.uint2str(rug.background), Utils.uint2str(rug.colorOne), Utils.uint2str(rug.colorTwo) , Utils.uint2str(rug.colorThree)));

        // Build the SVG from various parts
        string memory svg = string(abi.encodePacked('<svg customPattern = "', Utils.uint2str(rug.pattern), '" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 128 55" >'));

        //svg = string(abi.encodePacked(svg, id));
        string memory currentSvg = "";
        if(rug.pattern == 0)
        {
            //ETHERS
            currentSvg = string(abi.encodePacked('<pattern id="rug" viewBox="5.5,0,10,10" width="24%" height="20%"><polygon points="-10,-10 -10,30 30,30 30,-10" fill ="', colors[rug.background],'"/><polygon points="0,5 9,1 10,1 10,2 8,4 1,5 8,6 10,8 10,9 9,9 0,5"/><polygon points="10,5 13,1 14,1  21,5 14,9 13,9 10,5"/><polygon points="13.25,2.25 14.5,5 13.25,7.75 11,5" fill="', colors[rug.colorOne],'"/><polygon points="14.5,2.5 15.5,4.5 18.5,4.5" fill="', colors[rug.colorTwo],'"/><polygon points="18.5,5.5 15.5,5.5 14.5,7.5" fill="', colors[rug.colorThree],'"/><polygon points="18.5,5.5 15.5,5.5 14.5,7.5" transform="scale(-1,-1) translate(-35,-15)"/><polygon points="14.5,2.5 15.5,4.5 18.5,4.5" transform="scale(-1,-1) translate(-35,-5)"/><polygon points="13.25,2.25 14.5,5 13.25,7.75 11,5" transform="scale(-1,-1) translate(-35,-15)"/><polygon points="13.25,2.25 14.5,5 13.25,7.75 11,5" transform="scale(-1,-1) translate(-35,-5)"/><polygon points="2,5 10,5 13,9 10,9 8,6" transform="scale(-1,-1) translate(-9,-15)"/><polygon points="2,5 8,4 10,1 13,1 10,5" transform="scale(-1,-1) translate(-9,-5)"/><animate attributeName="x" from="0" to="2.4" dur="20s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#rug)" stroke-width="3" stroke="black"/>'));
        }
        else if(rug.pattern == 1)
        {
            //CIRCLES
            string[3] memory parts = [
                string(abi.encodePacked
                (
                    '<pattern id="star" viewBox="0,0,12,12" width="11%" height="25%"><circle cx="12" cy="0" r="4" fill="', colors[rug.colorOne],'" stroke="black" stroke-width="1"/><circle cx="12" cy="0" r="2" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="1"/><circle cx="0" cy="12" r="4" fill="', colors[rug.colorOne],'" stroke="black" stroke-width="1"/><circle cx="0" cy="12" r="2" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="1"/>'
                )), 
                string(abi.encodePacked
                (
                    '<circle cx="6" cy="6" r="6" fill="', colors[rug.colorTwo],'" stroke="black" stroke-width="1"/><circle cx="6" cy="6" r="4" fill="', colors[rug.colorOne],'" stroke="black" stroke-width="1"/><circle cx="6" cy="6" r="2" fill="', colors[rug.background],'" stroke="black" stroke-width="1"/><circle cx="0" cy="0" r="6" fill="', colors[rug.colorTwo],'" stroke="black" stroke-width="1"/><circle cx="0" cy="0" r="4" fill="', colors[rug.colorOne],'" stroke="black" stroke-width="1"/><circle cx="0" cy="0" r="2" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="1"/>'
                )),
                string(abi.encodePacked
                (
                    '<circle cx="12" cy="12" r="6" fill="', colors[rug.colorTwo],'" stroke="black" stroke-width="1"/><circle cx="12" cy="12" r="4" fill="', colors[rug.colorOne],'" stroke="black" stroke-width="1"/><circle cx="12" cy="12" r="2" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="1"/><animate attributeName="x" from="0" to="1.1" dur="9s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#star)" stroke="black" stroke-width="3"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2]));
        }
        else if(rug.pattern == 2)
        {
            //HOOTS
            string[4] memory parts = [
                string(abi.encodePacked
                (
                    '<pattern id="e" viewBox="13,-1,10,15" width="15%" height="95%"><polygon points="-99,-99 -99,99 99,99 99,-99" fill ="', colors[rug.background],'"/> <g stroke="black" stroke-width="0.75"><polygon points="5,5 18,10 23,5 18,0" fill ="', colors[rug.colorTwo],'"/><polygon points="21,0 26,5 21,10 33,5" fill ="', colors[rug.colorThree],'"/> </g><animate attributeName="x" from="0" to="0.3" dur="2.5s" repeatCount="indefinite"/> </pattern>'
                )), 
                string(abi.encodePacked
                (
                    '<pattern id="h" viewBox="10,0,20,25" width="15%" height="107%"><polygon points="-99,-99 -99,99 99,99 99,-99" fill ="', colors[rug.background],'"/><polygon points="9,4 14,9 14,18 9,23 26,23 31,18 31,9 26,4" fill ="', colors[rug.colorOne],'" stroke="black" stroke-width="1"/><g fill ="', colors[rug.background],'" stroke="black" stroke-width="0.5"><circle cx="20" cy="10" r="2.5"/><circle cx="20" cy="17" r="2.5"/><polygon points="24,11 24,16 29,13.5"/></g><circle cx="20" cy="10" r="1.75" fill="black"/><circle cx="20" cy="17" r="1.75" fill="black"/>'
                )),
                string(abi.encodePacked
                (
                    '<animate attributeName="x" from="0" to="0.6" dur="5s" repeatCount="indefinite"/></pattern><pattern id="c" viewBox="13,4,10,20" width="15%" height="135%"><polygon points="-99,-99 -99,99 99,99 99,-99" fill="', colors[rug.background],'"/><polygon points="7,3 7,18 32,18 32,3" fill="black"/><polygon points="11,7 11,15 28,15 28,7" fill="', colors[rug.background],'"/><g fill="black" stroke="', colors[rug.background],'" stroke-width="1">'
                )),
                string(abi.encodePacked
                (
                    '<polygon points="-3,9 -3,13 16,13 16,9"/><polygon points="23,9 23,13 41,13 41,9"/></g><animate attributeName="x" from="2.4" to="0" dur="40s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="', colors[rug.background],'"/><rect x="0" y="2" width="128" height="9" fill="url(#e)"/><rect x="0" y="10" width="128" height="9" fill="url(#c)"/><rect x="0" y="19" width="128" height="15" fill="url(#h)"/><rect x="0" y="36.5" width="128" height="9" fill="url(#c)"/><rect x="0" y="46.25" width="128" height="9" fill="url(#e)"/><rect width="128" height="55" fill="transparent" stroke="black" stroke-width="3"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2], parts[3]));
        }
        else if(rug.pattern == 3)
        {
            //SCALES
            string[3] memory parts = [
                string(abi.encodePacked
                (
                    '<linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="', colors[rug.background],'"/><stop offset="100%" stop-color="', colors[rug.colorOne],'"/></linearGradient>'
                )), 
                string(abi.encodePacked
                (
                    '<pattern id="R" viewBox="0 0 16 16" width="11.4%" height="25%"><g fill="url(#grad1)" stroke-width="1" stroke="black"><polygon points="8,-2 26,-2 26,18 8,18"/><circle cx="8" cy="8" r="8"/><circle cx="0" cy="0" r="8"/><circle cx="0" cy="16" r="8"/><circle cx="8" cy="8" r="3" fill="', colors[rug.colorThree],'"/><circle cx="0" cy="0" r="3" fill="', colors[rug.colorTwo],'"/><circle cx="0" cy="16" r="3" fill="', colors[rug.colorTwo],'"/><circle cx="17" cy="0" r="3" fill="', colors[rug.colorTwo],'"/>'
                )),
                string(abi.encodePacked(
                    '<circle cx="17" cy="16" r="3" fill="', colors[rug.colorTwo],'"/></g><animate attributeName="x" from="0" to="0.798" dur="6.6s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#R)" stroke-width="3" stroke="black"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2]));
        }
        else if(rug.pattern == 4)
        {
            //HEART
            currentSvg = string(abi.encodePacked('<pattern id="star" viewBox="5.5,-50,100,100" width="25%" height="25%"><g stroke="black" stroke-width="2"><polygon points="-99,-99 -99,99 999,99 999,-99" fill ="', colors[rug.background],'"/> <polygon points="0,-50 -60,-15.36 -60,-84.64" fill="', colors[rug.colorOne],'"/><polygon points="0,50 -60,84.64 -60,15.36" fill="', colors[rug.colorOne],'"/><circle cx="120" cy="0" r="30" fill ="', colors[rug.colorTwo],'" /><path fill="', colors[rug.colorThree],'" id="star" d="M0,0 C37.5,62.5 75,25 50,0 C75,-25 37.5,-62.5 0,0 z"/></g><g transform="translate(0,40)" id="star"></g><animate attributeName="x" from="0" to="0.5" dur="4.1s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#star)" stroke="black" stroke-width="3"/>'));
        }
        else if(rug.pattern == 5)
        {
            //SQUARES
            string[2] memory parts = [
                string(abi.encodePacked
                (
                    '<pattern id="moon" viewBox="0,-0.5,10,10" width="100%" height="100%"><rect width="10" height="10" fill="', colors[rug.colorOne],'" stroke="black" stroke-width="2" transform="translate(0.05,-0.5)"/><rect width="5" height="5" stroke="', colors[rug.colorTwo],'" fill="', colors[rug.colorOne],'" transform="translate(2.5,2)"/><rect width="4" height="4" stroke="black" fill="', colors[rug.colorOne],'" transform="translate(3,2.5)" stroke-width="0.3"/>'
                )), 
                string(abi.encodePacked
                (
                    '<rect width="6" height="6" stroke="black" fill="none" transform="translate(2,1.5)" stroke-width="0.3"/><circle cx="5" cy="4.5" r="1" stroke="', colors[rug.colorTwo],'" fill="', colors[rug.colorThree],'"/><g stroke="black" stroke-width="0.3" fill="none"><circle cx="5" cy="4.5" r="1.5"/><circle cx="5" cy="4.5" r="0.5"/> </g></pattern><pattern id="star" viewBox="7,-0.5,7,10" width="17%" height="20%"><g fill="url(#moon)" stroke="', colors[rug.background],'"><rect width="10" height="10" transform="translate(0,-0.5)"/><rect width="10" height="10" transform="translate(10,4.5)"/><rect width="10" height="10" transform="translate(10,-5.5)"/></g><animate attributeName="x" from="0" to="0.17" dur="1.43s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#star)" stroke-width="3" stroke="black"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1])));
        }
        else if(rug.pattern == 6)
        {
            //ENCORE
            string[3] memory parts = [
                string(abi.encodePacked
                (
                    '<radialGradient id="a" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="', colors[rug.background],'" stop-opacity="1" /><stop offset="100%" stop-color="', colors[rug.colorOne],'" stop-opacity="1" /></radialGradient><radialGradient id="b" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="', colors[rug.colorTwo],'" stop-opacity="1" /><stop offset="100%" stop-color="', colors[rug.colorThree],'" stop-opacity="1" /></radialGradient>'
                )), 
                string(abi.encodePacked
                (
                    '<pattern id="R" viewBox="0 0 16 16" width="13.42%" height="33%"><g stroke-width="1" stroke="black" fill="url(#a)"><circle cx="16" cy="16" r="8"/><circle cx="16" cy="14.9" r="6"/><circle cx="16" cy="13" r="4"/><circle cx="16" cy="12" r="2"/><circle cx="0" cy="16" r="8"/><circle cx="0" cy="14.9" r="6"/><circle cx="0" cy="13" r="4"/><circle cx="0" cy="12" r="2"/><circle cx="8" cy="8" r="8" fill="url(#b)"/><circle cx="8" cy="6.5" r="6" fill="url(#b)"/><circle cx="8" cy="5" r="4" fill="url(#b)"/><circle cx="8" cy="4" r="2" fill="url(#b)"/><circle cx="16" cy="0" r="8"/><circle cx="16" cy="-2" r="6"/>'
                )),
                string(abi.encodePacked
                (
                    '<circle cx="16" cy="-3.9" r="4"/><circle cx="0" cy="0" r="8"/><circle cx="0" cy="-2" r="6"/><circle cx="0" cy="-3.9" r="4"/></g><animate attributeName="x" from="0" to="0.4025" dur="3.35s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#R)" stroke-width="3" stroke="black"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2]));
        }
        else if(rug.pattern == 7)
        {
            //Kubrik
            string[3] memory parts = [
                string(abi.encodePacked
                (
                    '<linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="', colors[rug.colorOne],'" stop-opacity="1" /><stop offset="100%" stop-color="', colors[rug.colorTwo],'" stop-opacity="1" /></linearGradient><polygon points="0,0 0,55 128,55 128,0" fill ="url(#grad1)"/>    <pattern id="star" viewBox="5,-2.9,16,16" width="12%" height="20%">'
                )), 
                string(abi.encodePacked
                (
                    '<polygon points="13,6 10.5,10 5.5,10 2.5,5 5.5,0 10.5,0 13,4 21,4 26,-5 28,-5 22.5,5 29,17 27,17 21,6" fill="', colors[rug.background],'" stroke="black" stroke-width="0.3"/>    <polygon points="5,0 10,0 13,5 10,10 5,10 2,5" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="0.6" transform="translate(4.3 2.5) scale(0.5 0.5)"/>    <polygon points="21,6 12.5,6 10,10 5,10 2,5 5,0 10,0 12.5,4 20.5,4 25.5,-5 28,-5 22,5" transform="translate(24.5 8) scale(-1,1)" fill="', colors[rug.background],'" stroke="black" stroke-width="0.3"/>'
                )),
                string(abi.encodePacked
                (
                    '<polygon points="5,0 10,0 13,5 10,10 5,10 2,5" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="0.6" transform="translate(13.3 10.5) scale(0.5 0.5)"/>      <polygon points="20.5,6 12.5,6 10,10 5,10 2,5 5,0 10,0 12.5,4 21,4 22,5 28,17 26.5,17" transform="translate(24.5 -8) scale(-1,1)" fill="', colors[rug.background],'" stroke="black" stroke-width="0.3"/>     <polygon points="5,0 10,0 13,5 10,10 5,10 2,5" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="0.6" transform="translate(13.3 -5.5) scale(0.5 0.5)"/>    <animate attributeName="x" from="0" to="1.2" dur="9.8s" repeatCount="indefinite"/>    </pattern><rect width="128" height="55" fill="url(#star)" stroke="black" stroke-width="3"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2]));
        }
        else if(rug.pattern == 8)
        {
            //TRIANGLES
            string[2] memory parts = [
                string(abi.encodePacked
                (
                    '<polygon points="0,0 128,0 128,55 0,55" fill="', colors[rug.background],'"/><pattern id="R" viewBox="0 0 20 24" width="11.8%" height="33%"><g stroke-width="0.3" stroke="black"><polygon points="0,24 10,18 10,30" fill="', colors[rug.colorOne],'"/><polygon points="0,0 10,6 10,-6" fill="', colors[rug.colorOne],'"/><polygon points="10,6 20,12 20,0" fill="', colors[rug.colorTwo],'"/>'
                )), 
                string(abi.encodePacked
                (
                    '<polygon points="3,6 13,12 3,18" fill="', colors[rug.colorThree],'"/><polygon points="-7,12 3,18 -7,24" fill="', colors[rug.colorOne],'"/><polygon points="23,18 13,24 13,12" fill="', colors[rug.colorOne],'"/></g><animate attributeName="x" from="0" to="0.7085" dur="5.9s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#R)" stroke-width="3" stroke="black"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1])));
        }
        else if(rug.pattern == 9)
        {   
            rug.background  = combination[1];
            rug.colorOne    = combination[2];
            rug.colorTwo    = combination[3];
            rug.colorThree  = combination[4];
            rug.set         = (rug.colorOne == rug.colorTwo) && (rug.colorTwo == rug.colorThree);
            rug.combination = string(abi.encodePacked(Utils.uint2str(rug.pattern), Utils.uint2str(rug.background), Utils.uint2str(rug.colorOne), Utils.uint2str(rug.colorTwo) , Utils.uint2str(rug.colorThree)));
            string[1] memory parts = [
                string(abi.encodePacked
                (
                    '<pattern id="star" viewBox="5.5,-50,100,100" width="40%" height="50%"><polygon points="-100,-100 -100,300 300,300 300,-100" fill="white"/> <polyline points="11 1,7 1,7 5,11 5,11 3, 10 3" fill="none" stroke="', ngmiPalette[rug.background],'"/><polyline points="1 5,1 1,5 5,5 1" fill="none" stroke="', ngmiPalette[rug.colorOne],'"/><polyline points="13 5,13 1,15 3,17 1, 17 5" fill="none" stroke="', ngmiPalette[rug.colorTwo],'"/><polyline points="19 1, 23 1, 21 1, 21 5, 19 5, 23 5" fill="none" stroke="', ngmiPalette[rug.colorThree],'"/><animate attributeName="x" from="0" to="0.4" dur="3s" repeatCount="indefinite"/>   </pattern>  <rect width="128" height="55" fill="url(#star)" stroke="black" stroke-width="3"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0])));
        }
    
        svg = string(abi.encodePacked(svg, currentSvg));
        svg = string(abi.encodePacked(svg, '</svg>'));

        // Keep track of each pn So we can add a trait for each color
        string memory traits = string(abi.encodePacked('"attributes": [{"trait_type": "Pattern","value":"', patterns[rug.pattern],'"},'));
        if(rug.set)
            traits = string(abi.encodePacked(traits, string(abi.encodePacked('{"trait_type": "Set","value":"True"},'))));
        string memory traits2 = string(abi.encodePacked('{"trait_type": "Background","value":"', colors[rug.background],'"},{"trait_type": "Color One","value": "', colors[rug.colorOne],'"},{"trait_type": "Color Two","value": "', colors[rug.colorTwo],'"},{"trait_type": "Color Three","value": "', colors[rug.colorThree],'"}]'));
        string memory allTraits = string(abi.encodePacked(traits,traits2));
        rug.metadata = allTraits;

        return (rug, svg);
    }

    function isTryingToRug(address account) internal view returns (bool) 
    {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
library Utils 
{
    function uint2str(uint256 _i) internal pure returns (string memory str)
    {
        if (_i == 0)
        {
            return "0";
        }
        
        uint256 j = _i;
        uint256 length;
        
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        
        str = string(bstr);
        
        return str;
    }
}