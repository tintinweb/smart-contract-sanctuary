// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "base64-sol/base64.sol";
import "./TreeGenerator.sol";

contract OnChainXmasTree is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public maxSupply=4646;
    uint256 public price=0.025 ether;
    uint256 public tokenCounter=0;
    bool public sale = true;

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId < tokenCounter);

        TreeGenerator.xmasTree memory xt;
        string memory svg;
        (xt, svg) = TreeGenerator.getTreeForSeed(tokenId);

        string[9] memory treeColAttr = ['Leafy Green','Snow White','Golden Sizzle','Alien Blue','Merry Red','Pink Berry','Icy Blue','Gorgeous Grey','Autumn Love'];
        string[8] memory treeAttr = ['Zip Zap','Nacho','Flow-ey','Pixelated','Paper Cut','Pyramid','Thorn-y','Cone-y'];
        string[5] memory giftAttr = ['No','1 Gift','2 Gifts','3 Gifts','4 Gifts'];
        string[2] memory capAttr = ['No','Yes'];
        string[8] memory colsAttr = ['Silver','Red','Orange','Green','Blue','Yellow','Purple','No'];
        string[11] memory bgAttr = ['Sliver Clouds','Peachy Noon','Pink Dawn','Northern Lights','Morning Green','Lavender Dusk','Misty Blue','Stormy Grey','Arabian Night','Violet Night','Night Sky'];  

        string memory json = string(abi.encodePacked(
            '{"name" : "OCXT#',Strings.toString(tokenId),'",',
            '"description": "100% on-chain generative Christmas Trees for you to own or share and keep your traditions alive on the blockchain.",', 
            '"attributes":[',
            '{"trait_type":"Background","value":"',bgAttr[xt.bgCol],'"},',
            '{"trait_type":"Tree Type","value":"',treeAttr[xt.treeType],'"},'));
        json = string(abi.encodePacked(json,
            '{"trait_type":"Tree Color","value":"',treeColAttr[xt.treeCol],'"},',
            '{"trait_type":"Snow Cap","value":"',capAttr[xt.snowCap],'"},'));

        if (xt.star==0) {json = string(abi.encodePacked(json,'{"trait_type":"Star","value":"No"},','{"trait_type":"Santa Hat","value":"No"},'));}
        if (xt.star==1) {json = string(abi.encodePacked(json,'{"trait_type":"Star","value":"',colsAttr[xt.starCol],'"},','{"trait_type":"Santa Hat","value":"No"},'));}
        if (xt.star==2) {json = string(abi.encodePacked(json,'{"trait_type":"Star","value":"No"},','{"trait_type":"Santa Hat","value":"',colsAttr[xt.starCol],'"},'));}

        string memory bulbAni = '';
        if(xt.bulbAni) {bulbAni = ' Animated';}
        json = string(abi.encodePacked(json,
            '{"trait_type":"Clouds","value":"',capAttr[xt.cloud],'"},',
            '{"trait_type":"Ribbon","value":"',colsAttr[xt.ribbonCol],'"},',
            '{"trait_type":"Bulbs","value":"',colsAttr[xt.bulbCol],bulbAni,'"},',
            '{"trait_type":"Gifts","value":"',giftAttr[xt.gifts],'"}',
            '],'
            '"image": "data:image/svg+xml;base64,', 
            Base64.encode(bytes(svg)),
            '"}'
        ));
        
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function claim(address a, uint256 x) public payable nonReentrant {
        require(tokenCounter < maxSupply, "All tokens minted");
        require(sale, "Sales are paused");
        require(x < 11, "Max Limit");
        require(balanceOf(a)+x < 26, "Wallet limit reached");
        require(price*x <= msg.value, "Incorrect ETH amount");
        for(uint256 i=0; i<x; i++) {
            _safeMint(a, tokenCounter);
            tokenCounter++;
            sanity();
        }
    }

    function supply(uint256 a) public onlyOwner {
        maxSupply = a;
    }

    function priceMod(uint256 a) public onlyOwner {
        price = a;
    }

    function claimOwn(address a, uint256 b) public onlyOwner {
        for(uint256 i=0; i<b; i++) {
            _safeMint(a, tokenCounter);
            tokenCounter++;
            sanity();
        }
    }

    function saleToggle() public onlyOwner {
        sale = !sale;
    }

    function withdrawAll() public onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function sanity() internal {
        uint16[27] memory id = [41,81,157,386,766,855,991,1071,1125,1134,1497,1678,1801,1973,1981,2072,2471,2510,2564,2922,2965,2996,3347,3437,3696,3960,4990];
        for(uint16 i=0; i<id.length;i++) {
            if(tokenCounter==id[i]) {
                tokenCounter++;
            }
        }
    }

    constructor() ERC721('Christmas Trees by Traditions On Chain','OCXT') Ownable() { 
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library TreeGenerator {

    struct xmasTree {
        uint256 bg;
        uint256 bgCol;
        uint256 cloud;
        uint256 treeType;
        uint256 treeCol;
        uint256 snowCap;
        uint256 star;
        uint256 starCol;
        uint256 ribbon;
        uint256 ribbonCol;
        uint256 bulb;
        uint256 bulbCol;
        uint256 gifts;
        bool bulbAni;
    }

    function getTreeForSeed(uint256 tokenId) external pure returns (xmasTree memory, string memory) {
        string[2] memory bg = ['<path d="M0 0 H500 V500 H0"/>','<filter x="0" y="0" width="100%" height="100%" id="a"><feTurbulence baseFrequency=".1 0.1" numOctaves="3"/><feColorMatrix values="0 0 0 9 -6 0 0 0 9 -6 0 0 0 9 -6 0 0 0 0 0.7"/></filter><path d="M0 0h500v500H0" fill="#BEE1E6"/><path d="M0 0h500v500H0" filter="url(#a)"/>'];
        string[11] memory bgCols = ['#BFBFBF','#D4A783','#F1A6AB','#ADC8C0','#93C9D1', '#B5C9FF','#87B5DF','#939DB2','#0C8696','#ABA0C2',''];
        string[2] memory cloud = ['','<g><animateTransform attributeName="transform" type="translate" from="-150 30" to="650 30" begin="0s" dur="20s" repeatCount="indefinite"/><path d="M112.34 41.05a13.7 13.7 0 0 0-16.3-16.95v-1.22a22.87 22.87 0 0 0-45.2-5A14.21 14.21 0 0 0 30.5 27a12.75 12.75 0 0 0-12.4-.75 12.84 12.84 0 0 0-7 14.35 7.72 7.72 0 0 0-3.62 5 7.6 7.6 0 1 0 5.78 12.75c2.94 3.05 9 5.15 16 5.15 4.67.13 9.3-.96 13.43-3.15a68.1 68.1 0 0 0 19.7 2.7c7 .1 14-.91 20.69-3a16.35 16.35 0 0 0 20.89-1.6 10.25 10.25 0 1 0 8.32-17.39h.06Z" fill="#fff"/></g><g><animateTransform attributeName="transform" type="translate" from="550 200" to="-150 200" begin="0s" dur="30s" repeatCount="indefinite"/><path d="M46.54 33.55s16.95 15 27.37.73c8.9-12.22-6.3-22-11.63-19.13 2.18-4.6-3.39-9.93-7.26-6.3C53.81.62 39.52-4.47 34.19 6.19 32.5.62 21.84-.6 21.84 8.37a4.44 4.44 0 0 0-6.3 5.57c-7.7-3.85-16.64 1-14.28 10.65 2.17 9 15.25 7.27 17.43 5.57-1 6.3 3.88 8.94 8.72 9.2a10.15 10.15 0 0 0 10.17-6.53c.97 6.05 7.51 4.84 8.96.72Z" fill="#fff"/></g>'];
        string memory setup = '<path d="M0 320c232-54 193 127 500-6v186H0" fill="#fff"/><ellipse cx="255" cy="400" fill="#efefef" rx="96.5" ry="14.5"/><path d="m245 400 12-150 13 150" fill="#8b4513"/>'; //snow, shadow and bark
        string[3] memory star = ['','<path d="m255 79-12 34 30-24h-36l30 24z"/>','<path d="m255 94-18 38H273L255 94z"/><path d="M273 126H236v6h37v-6z" fill="#fff"/><circle cx="255" cy="94" fill="#fff" r="6"/>'];
        string[2] memory snowCap = ['','<path d="M220 160c40 40 45-10 70 0l-35-60" fill="#fff"/>'];
        string[8] memory cols = ['#F3F3F3','#9B2424','#FF7A00','#427700','#1F95FC','#FFFF00','#792976','none'];
        string[2] memory ribbon = ['','<path d="m336 318.5-4.5-10c-66.055 19.767-103.507 28.463-171 40L154 362c72.583-10.511 112.561-19.48 182-43.5ZM310.5 239l-5-10.5c-47.195 21.782-74.009 32.304-123 45.5l-7.5 16c53.873-12.08 83.544-23.227 135.5-51ZM288.5 174l-3-6.5c-35.166 16.398-51.197 22.513-74.5 29l-4.5 10.5c33.152-8.483 51.168-15.466 82-33Z"/>'];
        
        xmasTree memory xt;

        uint256 rand = random(string(abi.encodePacked('Background', tokenId)))%100;
        if(rand < 90) {xt.bg = 0;} else {xt.bg = 1;}

        xt.bgCol = getAttr(tokenId, 'Background Color', bgCols.length-1);
        if(xt.bg == 1) {xt.bgCol=bgCols.length-1;}

        rand = random(string(abi.encodePacked('Cloud', tokenId)))%100;
        if(rand<10) {xt.cloud=1;} else {xt.cloud=0;}
        
        xt.treeType = getAttr(tokenId, 'Tree', 8);

        rand = random(string(abi.encodePacked('Tree Color', tokenId)))%100;
        if(rand < 20) {xt.treeCol = 0;}
        else if(rand < 30) {xt.treeCol = 1;}
        else if(rand < 40) {xt.treeCol = 2;}
        else if(rand < 50) {xt.treeCol = 3;}
        else if(rand < 60) {xt.treeCol = 4;}
        else if(rand < 70) {xt.treeCol = 5;}
        else if(rand < 80) {xt.treeCol = 6;}
        else if(rand < 90) {xt.treeCol = 7;}
        else {xt.treeCol = 8;}

        xt.snowCap = getAttr(tokenId, 'Snow Cap', snowCap.length);

        xt.star = getAttr(tokenId, 'Star or Cap', star.length);

        xt.starCol = getAttr(tokenId, 'Star or Cap Color', cols.length-1);
        if(xt.star == 0) {xt.starCol=cols.length-1;}

        xt.ribbon = getAttr(tokenId, 'Ribbon', ribbon.length);

        xt.ribbonCol = getAttr(tokenId, 'Ribbon Color', cols.length-1);
        if(xt.ribbon == 0) {xt.ribbonCol=cols.length-1;}
        
        xt.bulb = getAttr(tokenId, 'Bulbs', 2);

        xt.bulbCol = getAttr(tokenId, 'Bulbs Color', cols.length-1);
        if(xt.bulbCol==xt.ribbonCol) {xt.bulbCol=0; if(xt.ribbonCol==0) {xt.ribbonCol=1;}}
        if(xt.bulb == 0) {xt.bulbCol=cols.length-1;}

        if((xt.bulbCol!=0)&&(xt.bulb!=0)) {
            rand = random(string(abi.encodePacked('Bulb Animate', tokenId)))%100; 
            if(rand<20) {xt.bulbAni=true;} 
        }

        rand = random(string(abi.encodePacked('Gifts', tokenId)))%100; 
        if(rand < 50) {xt.gifts = 0;}
        else if(rand < 75) {xt.gifts = 1;}
        else if(rand < 90) {xt.gifts = 2;}
        else if(rand < 95) {xt.gifts = 3;}
        else {xt.gifts = 4;}

        string[8] memory parts;

        parts[0] = string(abi.encodePacked('<g fill="',bgCols[xt.bgCol],'">',bg[xt.bg],'</g>')); // background
        parts[1] = cloud[xt.cloud]; // cloud
        parts[2] = pluckTree(xt.treeType, xt.treeCol); // tree leaves and branches stucture
        parts[3] = snowCap[xt.snowCap]; //snow cap
        parts[4] = string(abi.encodePacked('<g fill="',cols[xt.starCol],'">',star[xt.star],'</g>')); // star
        parts[5] = string(abi.encodePacked('<g fill="',cols[xt.ribbonCol],'">',ribbon[xt.ribbon],'</g>')); //ribbon
        parts[6] = pluckBulb(xt.bulb, cols[xt.bulbCol], xt.bulbAni); //string lights with color
        parts[7] = pluckGift(xt.gifts);

        string memory output = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500">', parts[0], parts[1], setup, parts[2], parts[3], parts[4]));
        output = string(abi.encodePacked(output, parts[5], parts[6], parts[7], '</svg>'));

        return (xt,output);
    }

    function pluckBulb(uint256 rand, string memory color, bool ani) public pure returns (string memory) {
        string memory wire = '<path d="M289 177c-29 20-47 27-83 33M330 305c-65 19-101 27-166 35M204 231c34 31 63 41 125 47" fill="none" stroke="#000"/>';
        string[2] memory bulbs = ['<ellipse cx="-102.4" cy="-329.3" rx="2.6" ry="4.2" transform="matrix(.7914 -.6113 .65573 .755 291 179)" id="b1"/>','<ellipse cx="-297.8" cy="-75" rx="2.6" ry="4.2" transform="matrix(.81792 .57533 -.52743 .8496 204 228)" id="b2"/>'];
        
        uint16[24] memory b1x = [297,284,280,265,263,248,241,229,222,209,337,321,314,297,288,270,261,243,235,218,207,190,182,169];
        uint16[24] memory b1y = [187,187,199,197,208,204,215,210,219,214,314,312,323,319,330,325,336,331,342,336,346,340,350,345];
        uint16[13] memory b2x = [204,208,221,226,240,246,260,266,282,289,304,315,329];
        uint16[13] memory b2y = [235,247,246,261,259,272,268,279,274,284,278,288,282];
        

        if(rand==1) {
            string memory output;
            if(ani) {
                output = string(abi.encodePacked(wire, '<g><animate attributeName="fill" values="',color,';white;',color,'" dur="0.5s" repeatCount="indefinite" />',bulbs[0], bulbs[1]));
            } else {
                output = string(abi.encodePacked(wire, '<g fill="', color,'">',bulbs[0], bulbs[1]));
            }
            
            for (uint256 i=0;i<b1x.length;i++) {
                output = string(abi.encodePacked(output,'<use href="#b1" x="',Strings.toString(b1x[i]),'" y="',Strings.toString(b1y[i]),'"/>'));
            }
            for (uint256 i=0;i<b2x.length;i++) {
                output = string(abi.encodePacked(output,'<use href="#b2" x="',Strings.toString(b2x[i]),'" y="',Strings.toString(b2y[i]),'"/>'));
            }
            return string(abi.encodePacked(output,'</g>'));
        }
        return '';
    }

    function pluckGift(uint256 a) public pure returns (string memory) {
        string[5] memory gifts = ['','<path d="M260 420h73v-30h-73" fill="#853DBD"/><path d="M255 390h83v10h-83" fill="#A95BE7"/><path d="M292 420h10v-30h-10" fill="#F6A102"/><path d="M298 390c-34-5-12-32 0 0m0 0c4-28 40-10 0 0" stroke="#F6A102" stroke-width="3" fill="none"/>','<path d="M194 420h68v-61h-68" fill="#1F95FC"/><path d="M189 349h78v10h-78" fill="#4FBAFF"/><path d="M223 420h10v-71h-10" fill="#F6A102"/>','<path d="M132 432h68v-61h-68" fill="#AD4255"/><path d="M132 397v10h68v-10" fill="#F6A102"/>','<path d="M312 424h50v-45h-50" fill="#3A9981"/><path d="M307 369h60v10h-60" fill="#2E7B68"/><path d="M332 424h10v-55h-10" fill="#F6A102"/>'];
        if(a==0) { return '';}
        if(a==1) { return gifts[1];}
        if(a==2) { return string(abi.encodePacked(gifts[2], gifts[1])); }
        if(a==3) { return string(abi.encodePacked(gifts[2], gifts[3], gifts[1]));}
        return string(abi.encodePacked(gifts[1], gifts[3], gifts[2], gifts[4]));
    }

    function pluckTree(uint256 a, uint256 b) public pure returns (string memory) {
        string[8] memory trees = ['<path d="m149 371 31-64 141 22"/><path d="m282 202 77 167-181-53 103-114h1z"/><path d="m167 332 60-132 96 84-156 48z"/><path d="M274.617 176.521 335.32 296.25l-140.84-44.555 80.176-74.175-.039-.999z"/><path d="m230 172-56 120 127-75-70-45h-1z"/><path d="M312.5 243.5 270 145l-45 56 87.5 42.5z"/><path d="m254.5 103-55 117 82.5-55-27.5-62z"/><path d="m291 181-36-80-34.5 59h25"/>','<path d="m150 370 105-230 105 230"/><path d="m170 300 85-180 85 180"/><path d="m200 220 55-120 55 120"/><path d="m220 160 35-60 35 60"/>','<path d="M150 370c5-11 105-228 105-228s101 220 103 228-26-14-26-14.5c0 0-2 14-16 14s-15-14-15-14-6 14-21 14c-14 0-22-14-22-14s-6 16-20 14-19-14-19-14-8 14-21 14c-12 0-16-14-16-14s-35 26-30 14z"/><path d="M169 303c4-14 86-180 86-180s86 173 86 180-25-22-25-22 0 22-14 22-18-22-18-22-7 22-21 22-21-22-21-22-7 22-20 22-25-22-25-22-30 36-26 22z"/><path d="M200 222c2-12 55-120 55-120s51 112 55 123-22-22-22-22 5 17-8 18-22-19-22-19-4 21-17 21c-12 0-15-21-15-21s-27 33-25 21z"/><path d="M221 160c4-10 34-59 34-59s30 51 34 59-21-11-21-11-5 10-13 11c-7 1-11-11-11-11s-27 21-22 11h-1z"/>','<path d="M150 371c4-5 104-230 104-230s100 223 104 230c4 6-28 0-28 0s6 4 5 6c0 2-50 0-50 0s7 3 4 6-62 1-67 0 5-6 5-6-49.5 1-53 0c-3-1 4-6 4.5-6 0 0-33 5-29 0z"/><path d="M170 301c4-7 85-180 85-180s80 173 84 180-24 0-24 0 11 7 6 7h-28s11 7 5 7h-20s6 4 5 8-54 4-56 0c-1-4 5-8 5-8h-20c-6 0 5-7 5-7h-28c-5 0 5-7 5-7s-29 7-24 0z"/><path d="M200 221c2-5 55-120 55-120s52 116 55 120c2 4-15 0-15 0s7 5 4 5h-16s7 5 3 5h-17s5 2 3 5-31 2-34 0c-2-2 3-5 3-5h-17c-3 0 3-5 3-5h-14c-4 0 2-5 2-5s-18 5-15 0z"/><path d="M220 161c2-2 35-60 35-60s33 57 35 60c2 2-16 0-16 0s5 4 2 4h-13s3 2 0 3-17 1-20 0c-2-1 0-3 0-3h-12c-1 0 2-4 2-4s-16 2-13 0z"/>','<path d="m150 371 105-230 105 230-24 3-18-39 9 40-24 2-15-40 5 40-23 1-12-44v44h-23l-2-44-6 44-20-1 2-42-12 42-20-2 10-44-18 43-17-3z"/><path d="m170 301 85-180 85 180-21 3-17-38 10 40-22 3-11-38 2 40h-20l-4-39-4 39h-21l-3-41-4 40-24-3 9-38-18 37-20-3z"/><path d="m200 220 54-119 54 119-17 2-12-21 2 21-15 1-7-20-1 21h-17l-2-21-5 21-12-1 3-21-10 20-14-2z"/><path d="m220 161 35-60 34 60-14 3-7-13 3 14-13 1-2-14-3 14-12-1 1-15-6 14-14-4z"/>','<path d="m150 371 105-230 105 230-104-22-105 22z"/><path d="m170 301 85-180 84 179-84-20-85 21z"/><path d="m200 221 55-119 55 119-55-13-55 13z"/><path d="m220 161 35-60 35 60-34-9-35 9z"/>','<path d="m150 371 105-230 105 230-31-21-20 21-17-21-18 21-18-21-19 21-17-21-21 21.5-18-21.5-28 21z"/><path d="m170 301 85-180 85 180-29-19-19 19-19-19-20 19-22-19-17 19-18-19-24 19z"/><path d="m200 221 55-120 55 120-24-17-14 17-17-17-17 17-14-17-23 17z"/><path d="m220 161 35-60 35 60-21-11-13 11-15-11.5-19 11z"/>','<path d="M155.37 357.957C176.967 315.765 255.099 147 255.099 147s79.783 173.091 99.728 210.957c19.945 37.866-221.05 42.191-199.455 0z"/><path d="M175.5 289.569C193.674 253.855 255 107 255 107s60.714 150.517 77.5 182.569c16.785 32.053-175.175 35.714-157 0z"/><path d="M200.746 216.417C212.506 194.534 255.053 107 255.053 107s43.446 89.777 54.307 109.417c10.862 19.64-120.374 21.884-108.614 0z"/><path d="M220 161c7.58-12 35-60 35-60s28 49.23 35 60c7 10.77-77.579 12-70 0z"/>'];
        string[18] memory treeCols = ['#4D7C14','#8CB247','#FFFFFF','#CAE3FF','#F0AD15','#FFDA89','#213052','#6376A0','#831111','#E86161','#831177','#E861DA','#107099','#09BBF3','#5F5F5F','#9C9C9C','#E86F00','#FFA95A'];
        return string(abi.encodePacked('<defs><linearGradient id="tc" x2="0" y2="1"><stop offset="0" stop-color="',treeCols[b*2],'"/><stop offset="1" stop-color="',treeCols[(b*2)+1],'" /></linearGradient></defs>', '<g style="fill:url(#tc)">', trees[a], '</g>'));
    }

    function getAttr(uint256 tokenId, string memory key, uint256 length) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(key, tokenId)))%100;
        return rand%length;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}