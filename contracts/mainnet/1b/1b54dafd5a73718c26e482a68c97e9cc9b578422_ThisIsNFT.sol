// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "./StringUtils.sol";
import "./ERC721.sol";
import "./Ownable.sol";



/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ThisIsNFT is  Ownable, ERC721 {
    
    using Strings for uint256;
    using Strings for uint8;

    string public artist = "Eivind Kleiven";
    string public description = "\"This is NFT\" is an onchain project showing what NFT is at its simplest form, a TokenID with transferable ownership in a contract. Anyone can mint for the price of gas and gas price (in gwei) is set as TokenID.";
    
    string[4] private colors = ['ffe94d','a6e276','ff9c92','da95d1'];
    uint8[4][24] private palettes = [[0,1,2,3],[1,0,2,3],[2,0,1,3],[0,2,1,3],[1,2,0,3],[2,1,0,3],[2,1,3,0],[1,2,3,0],[3,2,1,0],[2,3,1,0],[1,3,2,0],[3,1,2,0],[3,0,2,1],[0,3,2,1],[2,3,0,1],[3,2,0,1],[0,2,3,1],[2,0,3,1],[1,0,3,2],[0,1,3,2],[3,1,0,2],[1,3,0,2],[0,3,1,2],[3,0,1,2]];

    
    string private _pBaseURI;
    bool private _tokenURIAsJson = false;
    
    /**
     * Mapping from tokenId to array where first element is index of palette and second element index of pattern
     */
    mapping(uint256 => uint8) public tokenProperties;

    
    /**
    * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
    */
    constructor () ERC721("This is NFT", "YESITIS") {
        
    }
    
    function color(uint256 tokenId, uint256 index) public view returns (string memory){
        return colors[palettes[tokenProperties[tokenId]][index]];
    }
  

    function getRandomPaletteIndex(uint256 tokenId) internal view returns (uint8) {
       
        uint8 index = uint8(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId)))%100);
        
        if(index >= 40){
            return (index-40)/10+18;
        }
        else if(index >=20){
            return (index-20)/5+14;
        }else if(index >=8){
            return (index-8)/2+8;
        }
            
        return index;
    }
    
    function setBaseURI(string memory baseURI) onlyOwner public {
        _pBaseURI = baseURI;
    }
    
    
    function returnJsonFromTokenURI(bool yesorno) onlyOwner public {
        _tokenURIAsJson = yesorno;
    }
    
    function mint() public {
        uint tokenId = tx.gasprice/1000000000;
        _mint(_msgSender(), tokenId);
        tokenProperties[tokenId] = getRandomPaletteIndex(tokenId);
    }
    
    
    function svg(uint256 tokenId) public view returns (string memory) {
        
        string memory part1 = string(abi.encodePacked("<svg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 900 900' style='background-color:#",color(tokenId,0),";fill:#",color(tokenId,1),";' font-family='Arial' font-size='30'><text x='76' y='280' fill='#",color(tokenId,2),"' font-weight='bold' font-size='130'>THIS IS NFT</text><text transform='matrix(1 0 0 1 100 400)'><tspan x='0' y='0' font-weight='bold' >Account</tspan><tspan x='0' y='36'>",toAsciiString(ownerOf(tokenId)),"</tspan><tspan x='0' y='144' font-weight='bold'>Is holder of TokenId</tspan><a href='data:text/html,%3C%21DOCTYPE%20html>%3Chtml%20lang%3D%22en%22>%3Chead>%3Ctitle>This%20is%20NFT%20%23",tokenId.toString(),"%3C%2Ftitle>%3Cmeta%20charset%3D%22UTF-8%22>%3Cmeta%20name%3D%22viewport%22%20content%3D%22width%3Ddevice-width%2C%20initial-scale%3D1.0%22>%3Cmeta%20name%3D%22apple-mobile-web-app-capable%22%20content%3D%22yes%22>%3Cstyle>%2A{touch-action%3Anone%3Buser-select%3Anone%3B-webkit-user-select%3Anone%3B-ms-user-select%3Anone%3B-moz-user-select%3Anone%3Bbox-sizing%3Aborder-box}img{pointer-events%3Anone}body{margin%3A0%3Bpadding%3A0%3Bmin-height%3A100vh%3Boverflow%3Ahidden%3Bbackground-color%3A%23202020}%23content{min-height%3A100vh}%23wrapper{min-height%3A100vh}%23scene{--size%3A0px%3B--scale%3A0.65%3Bheight%3Avar%28--size%29%3Bwidth%3Avar%28--size%29%3Bperspective%3A3000px}%23cube{height%3A100%25%3Bposition%3Arelative%3B--rotation-x%3A-40deg%3B--rotation-y%3A45deg%3Btransform-style%3Apreserve-3d%3Btransform%3AtranslateZ%28calc%28-1%2A%28var%28--size%29%2F2%29%29%29%20scale3d%28var%28--scale%29%2C%20var%28--scale%29%2C%20var%28--scale%29%29%20rotateX%28var%28--rotation-x%29%29%20rotateY%28var%28--rotation-y%29%29}.face{display%3Aflex%3Bjustify-content%3Aspace-around%3Balign-items%3Acenter%3Bposition%3Aabsolute%3Bwidth%3Avar%28--size%29%3Bheight%3Avar%28--size%29}.front{transform%3ArotateY%280deg%29%20translateZ%28calc%28var%28--size%29%2F2%29%29}.right{transform%3ArotateY%2890deg%29%20translateZ%28calc%28var%28--size%29%2F2%29%29}.back{transform%3ArotateY%28180deg%29%20translateZ%28calc%28var%28--size%29%2F2%29%29}.left{transform%3ArotateY%28-90deg%29%20translateZ%28calc%28var%28--size%29%2F2%29%29}.top{transform%3ArotateX%2890deg%29%20translateZ%28calc%28var%28--size%29%2F2%29%29}.bottom{transform%3ArotateX%28-90deg%29%20translateZ%28calc%28var%28--size%29%2F2%29%29}%40keyframes%20spin{0%25{transform%3AtranslateZ%28calc%28-1%2Avar%28--size%29%2F2%29%29%20scale3d%28var%28--scale%29%2C%20var%28--scale%29%2C%20var%28--scale%29%29%20rotateX%28var%28--rotation-x%29%29%20rotateY%28calc%28var%28--rotation-y%29%29%29}100%25{transform%3AtranslateZ%28calc%28-1%2Avar%28--size%29%2F2%29%29%20scale3d%28var%28--scale%29%2C%20var%28--scale%29%2C%20var%28--scale%29%29%20rotateX%28var%28--rotation-x%29%29%20rotateY%28calc%28var%28--rotation-y%29%20%2B%20360deg%29%29}}%3C%2Fstyle>%20%3Cscript>let%20svg%2Cwrapper%3Ddocument.getElementById%28%22wrapper%22%29%2Cscene%3Ddocument.getElementById%28%22scene%22%29%2Ccube%3Ddocument.getElementById%28%22cube%22%29%2Cp1ScreenX%3D-1%2Cp1ScreenY%3D-1%2Cp1PointerId%3D-1%2Cp2ScreenX%3D-1%2Cp2ScreenY%3D-1%2Cp2PointerId%3D-1%2CprevDiff%3D-1%3Bfunction%20getRotationYFrom3DMatrix%28e%29{var%20t%3DparseFloat%28getComputedStyle%28cube%29.getPropertyValue%28%22--scale%22%29%29%2Cn%3D%28n%3D%28n%3De.split%28%22%28%22%29%5B1%5D%29.split%28%22%29%22%29%5B0%5D%29.split%28%22%2C%22%29%2Cr%3DMath.sign%28n%5B0%5D%29%2Co%3DMath.abs%28n%5B0%5D%2Ft%29%2Ce%3Dr%2A%28o-Math.floor%28o%29%29%2Ct%3Dn%5B1%5D%2Co%3Dn%5B2%5D%2Cn%3Dn%5B3%5D%2Ce%3DMath.round%28Math.acos%28e%29%2A%28180%2FMath.PI%29%29%2Ct%3DMath.round%28Math.asin%28t%29%2A%28180%2FMath.PI%29%29%2Co%3DMath.round%28-1%2AMath.asin%28o%29%2A%28180%2FMath.PI%29%29%2Cr%3D%28Math.round%28Math.acos%28n%29%2A%28180%2FMath.PI%29%29%2C1%29%3Bt%3C0%3FMath.sign%28t%29%3D%3DMath.sign%28o%29%26%26%28r%3D-1%29%3A0%3Ct%26%26Math.sign%28t%29%21%3DMath.sign%28o%29%26%26%28r%3D-1%29%3Bo%3DparseInt%28getComputedStyle%28cube%29.getPropertyValue%28%22--rotation-x%22%29.substr%280%2CgetComputedStyle%28cube%29.getPropertyValue%28%22--rotation-x%22%29.indexOf%28%22deg%22%29%29%29%3Breturn%2090%3C%3DMath.abs%28o%29%26%26Math.abs%28o%29%3C270%26%26%28r%2A%3D-1%29%2Cr%2Ae}function%20setSize%28%29{stopSpin%28%29%2Cscene.style.setProperty%28%22--size%22%2C%220px%22%29%2Cwrapper.style.marginRight%3D%220px%22%2Cwrapper.style.marginLeft%3D%220px%22%3Bvar%20e%3Dwrapper.offsetHeight%2Ct%3Dwrapper.offsetWidth%2B2%2Awrapper.offsetLeft%3Blet%20n%3D0%2Cr%3Dt%3Be%3Ct%26%26%28n%3Dt-e%2Cr%3De%29%2Cwrapper.style.marginRight%3DMath.ceil%28n%2F2%29%2B%22px%22%2Cwrapper.style.marginLeft%3DMath.floor%28n%2F2%29%2B%22px%22%2Cscene.style.setProperty%28%22--size%22%2Cr%2B%22px%22%29%2CstartSpin%28%29}function%20zoom%28e%29{stopSpin%28%29%2Cscene.style.setProperty%28%22--scale%22%2CMath.max%28%2BMath.sign%28e%29%2F80%2BparseFloat%28getComputedStyle%28scene%29.getPropertyValue%28%22--scale%22%29%29%2C.01%29%29}function%20pointerdown_handler%28e%29{stopSpin%28%29%2C-1%3D%3Dp1PointerId%3F%28p1PointerId%3De.pointerId%2Cp1ScreenX%3De.screenX%2Cp1ScreenY%3De.screenY%29%3A-1%3D%3Dp2PointerId%26%26%28p2PointerId%3De.pointerId%2Cp2ScreenX%3De.screenX%2Cp2ScreenY%3De.screenY%29}function%20pointerup_handler%28e%2Ct%29{startSpin%28%29%2Cp1PointerId%3D-1%2Cp1ScreenX%3D-1%2Cp1ScreenY%3D-1%2Cp2PointerId%3D-1%2Cp2ScreenX%3D-1%2C%28p2ScreenY%3D-1%29%21%3Dp1PointerId%26%26-1%21%3Dp2PointerId||%28prevDiff%3D-1%29}function%20pointermove_handler%28n%29{if%28n.preventDefault%28%29%2C-1%21%3Dp1PointerId%29{let%20e%3D0%2Ct%3D0%3Bn.pointerId%3D%3Dp1PointerId%3F%28e%3Dn.screenX-p1ScreenX%2Ct%3Dn.screenY-p1ScreenY%2Cp1ScreenX%3Dn.screenX%2Cp1ScreenY%3Dn.screenY%29%3An.pointerId%3D%3Dp2PointerId%26%26%28p2ScreenX%3Dn.screenX%2Cp2ScreenY%3Dn.screenY%29%2C-1%21%3Dp1PointerId%26%26-1%3D%3Dp2PointerId%3Frotate%28e%2Ct%29%3A-1%21%3Dp1PointerId%26%26-1%21%3Dp2PointerId%26%26%28n%3DMath.sqrt%28Math.pow%28p1ScreenX-p2ScreenX%2C2%29%2BMath.pow%28p1ScreenY-p2ScreenY%2C2%29%29%2C0%3CprevDiff%26%26zoom%28n-prevDiff%29%2CprevDiff%3Dn%29}}function%20rotate%28e%2Ct%29{t%3D%28parseInt%28getComputedStyle%28cube%29.getPropertyValue%28%22--rotation-x%22%29.substr%280%2CgetComputedStyle%28cube%29.getPropertyValue%28%22--rotation-x%22%29.indexOf%28%22deg%22%29%29%29%2B-1%2At%29%25360%2B%22deg%22%2Ce%3DparseInt%28getComputedStyle%28cube%29.getPropertyValue%28%22--rotation-y%22%29.substr%280%2CgetComputedStyle%28cube%29.getPropertyValue%28%22--rotation-y%22%29.indexOf%28%22deg%22%29%29%29%2Be%2B%22deg%22%3Bcube.style.setProperty%28%22--rotation-x%22%2Ct%29%2Ccube.style.setProperty%28%22--rotation-y%22%2Ce%29}function%20stopSpin%28%29{var%20e%3Dwindow.getComputedStyle%28cube%29.getPropertyValue%28%22transform%22%29%3Bcube.style.animation%3D%22none%22%3Be%3DgetRotationYFrom3DMatrix%28e%29%3Bcube.style.setProperty%28%22--rotation-y%22%2Ce%2B%22deg%22%29}function%20startSpin%28%29{cube.style.animation%3D%22spin%2020s%20linear%20infinite%22}window.addEventListener%28%22DOMContentLoaded%22%2C%28%29%3D>{wrapper%3Ddocument.getElementById%28%22wrapper%22%29%2Cscene%3Ddocument.getElementById%28%22scene%22%29%2Ccube%3Ddocument.getElementById%28%22cube%22%29%2Csvg%3Ddocument.getElementsByTagName%28%22svg%22%29%5B0%5D%2Ccube.children%5B1%5D.appendChild%28svg.cloneNode%28%210%29%29%2Ccube.children%5B2%5D.appendChild%28svg.cloneNode%28%210%29%29%2Ccube.children%5B3%5D.appendChild%28svg.cloneNode%28%210%29%29%2Ccube.children%5B4%5D.appendChild%28svg.cloneNode%28%210%29%29%2Ccube.children%5B5%5D.appendChild%28svg.cloneNode%28%210%29%29%2Cscene.addEventListener%28%22pointerup%22%2Cpointerup_handler%29%2Cscene.addEventListener%28%22pointermove%22%2Cpointermove_handler%29%2Cscene.addEventListener%28%22pointerdown%22%2Cpointerdown_handler%29%2Cscene.addEventListener%28%22pointerleave%22%2Cpointerup_handler%29%2Cscene.addEventListener%28%22pointercancel%22%2Cpointerup_handler%29%2Cscene.addEventListener%28%22wheel%22%2Ce%3D>{zoom%28-1%2Ae.deltaY%29}%29%2CsetSize%28%29%2Cvoid%200%21%3D%3Dwindow.onresize%3Fwindow.onresize%3DsetSize%3Avoid%200%21%3D%3Dwindow.onorientationchange%26%26%28window.onorientationchange%3DsetSize%29}%29%3B%3C%2Fscript>%20%3C%2Fhead>%3Cbody>%3Cdiv%20id%3D%22content%22>%3Cdiv%20id%3D%22wrapper%22>%3Cdiv%20id%3D%22scene%22>%3Cdiv%20id%3D%22cube%22%20class%3D%22cube%22>%3Cdiv%20class%3D%22face%20front%22>%20%3Csvg%20version%3D%221.1%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20xmlns%3Axlink%3D%22http%3A%2F%2Fwww.w3.org%2F1999%2Fxlink%22%20viewBox%3D%220%200%20900%20900%22%20style%3D%22background-color%3A%23",color(tokenId,0),"%3Bfill%3A%"));
        string memory part2 = string(abi.encodePacked("23",color(tokenId,1),"%3B%22%20font-family%3D%22Arial%22%20font-size%3D%2230%22>%20%3Ctext%20x%3D%2276%22%20y%3D%22280%22%20fill%3D%22%23",color(tokenId,2),"%22%20font-weight%3D%22bold%22%20font-size%3D%22130%22>THIS%20IS%20NFT%3C%2Ftext>%20%3Ctext%20transform%3D%22matrix%281%200%200%201%20100%20400%29%22>%20%3Ctspan%20x%3D%220%22%20y%3D%220%22%20font-weight%3D%22bold%22%20>Account%3C%2Ftspan>%20%3Ctspan%20x%3D%220%22%20y%3D%2236%22>",toAsciiString(ownerOf(tokenId)),"%3C%2Ftspan>%20%3Ctspan%20x%3D%220%22%20y%3D%22144%22%20font-weight%3D%22bold%22>Is%20holder%20of%20TokenId%3C%2Ftspan>%20%3Ctspan%20x%3D%220%22%20y%3D%22180%22>",tokenId.toString(),"%3C%2Ftspan>%20%3Ctspan%20x%3D%220%22%20y%3D%22288%22%20font-weight%3D%22bold%22>In%20contract%3C%2Ftspan>%20%3Ctspan%20x%3D%220%22%20y%3D%22324%22>",toAsciiString(address(this)),"%3C%2Ftspan>%20%3C%2Ftext>%20%3Ccircle%20cx%3D%22425%22%20cy%3D%22150%22%20r%3D%2220%22%20fill%3D%22%23",color(tokenId,3),"%22>%3C%2Fcircle>%20%3C%2Fsvg>%3C%2Fdiv>%3Cdiv%20class%3D%22face%20back%22>%3C%2Fdiv>%3Cdiv%20class%3D%22face%20right%22>%3C%2Fdiv>%3Cdiv%20class%3D%22face%20left%22>%3C%2Fdiv>%3Cdiv%20class%3D%22face%20top%22>%3C%2Fdiv>%3Cdiv%20class%3D%22face%20bottom%22>%3C%2Fdiv>%3C%2Fdiv>%3C%2Fdiv>%3C%2Fdiv>%3C%2Fdiv>%3C%2Fbody>%3C%2Fhtml>'><tspan x='0' y"));
        string memory part3 = string(abi.encodePacked("='180' fill='#",color(tokenId,1),"'>",tokenId.toString(),"</tspan></a><tspan x='0' y='288' font-weight='bold'>In contract</tspan><tspan x='0' y='324'>",toAsciiString(address(this)),"</tspan></text><circle cx='425' cy='150' r='20' fill='#",color(tokenId,3),"'></circle></svg>"));
       
        return string(abi.encodePacked(part1,part2,part3));
        
    }
    
    function metadata(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked("{\"name\":\"This is NFT #",tokenId.toString(),"\",\"createdBy\":\"Eivind Kleiven\",\"yearCreated\":\"2021\",\"description\": \"Still don't know what the hells a NFT?\",\"image_data\":\"",svg(tokenId),"\",\"attributes\":[{\"trait_type\":\"Palette\",\"value\":\"",tokenProperties[tokenId].toString(),"\"}]}"));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if(_tokenURIAsJson){
            return metadata(tokenId);
        }
        
        string memory part1 = string(abi.encodePacked(_pBaseURI,"?t=",tokenId.toString(),"&a=",toAsciiString(ownerOf(tokenId)),"&c=",toAsciiString(address(this))));
        string memory part2 = string(abi.encodePacked("&p=",tokenProperties[tokenId].toString(),"&c0=",color(tokenId,0),"&c1=",color(tokenId,1),"&c2=",color(tokenId,2),"&c3=",color(tokenId,3)));
        
        return string(abi.encodePacked(part1,part2));
        
    }
    
    
    
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(abi.encodePacked("0x",s));
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    
}