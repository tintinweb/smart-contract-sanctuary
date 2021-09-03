// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './Ownable.sol';
import './ERC721Enumerable.sol';



contract Avatars is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string baseTokenURI;
    uint256 private price = 1*10**15; //0.001 ETH;
    bool public saleIsActive = true;
    uint public constant MAX_SUPPLY = 1000;
    
    mapping(address => bool) public hasMint;

    
    mapping(uint256 => bytes) private tokenToHash;
    mapping(bytes => uint256) private hashToToken;


    event mint(address indexed owner,uint256 indexed tokenId);
    
    constructor(string memory baseURI) ERC721("Avatars", "AVA")  {
        setBaseURI(baseURI);
        
    }
    
    modifier onlyValidTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "Token ID does not exist");
        _;
    }
    
    modifier onlyValidHash(bytes memory _bytes) {
        require((_bytes.length == 20),"TokenHash does not exist");
        require(_check(_bytes), "TokenHash does not exist");
        _;
    }
    
    function _bytesToUint(bytes memory b) internal pure returns (uint256){
        
        uint256 number;
        for(uint i= 0; i<b.length; i++){
            number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
        }
        return  number;
    }

    function _check(bytes memory _bytes) internal view returns (bool) {
        if(hashToToken[_bytes] == 0) {
            if(_exists(0)) {
                bytes memory hash = tokenToHash[0];
                if(_bytesToUint(hash) == _bytesToUint(_bytes)){
                    return true;
                } else{
                    return false;
                }
               
            } else {
                return false;
            }
           
        } else {
            return true;
        }
    }
    
    function createAvataaars() public payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale must be active to mint Tokens");
        require( supply < MAX_SUPPLY,  "Exceeds maximum supply" );
        require( msg.value >= price,"Ether sent is not correct" );
        
        require(!hasMint[msg.sender],"You already have the avatar");
        
        uint256 tokenId = supply;
        
        _safeMint(msg.sender, tokenId);
        
        hasMint[msg.sender] = true;
        
        tokenToHash[tokenId] = _toBytes(msg.sender);
        hashToToken[_toBytes(msg.sender)] = tokenId;

        emit mint(msg.sender,tokenId);

    }
    
    function _toBytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function tokenIdToHash(uint256 _tokenId) onlyValidTokenId(_tokenId) public view returns(bytes memory) {
        
        return tokenToHash[_tokenId];
    } 
    
     function hashToTokenId(bytes memory _bytes) onlyValidHash(_bytes) public view returns(uint256) {
        
        return hashToToken[_bytes];
    } 
    
    function tokensOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
         
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseTokenURI = _baseURI;
    }

    function setSaleState(bool _val) public onlyOwner {
        saleIsActive = _val;
            
    }
    
    function getFeature() public pure returns(string memory) {
        
        return 'var Features = { accessoriesType : ["Blank","Kurt","Prescription01","Prescription02","Round","Sunglasses","Wayfarers"],clotheType : ["BlazerShirt""BlazerSweater","CollarSweater","GraphicShirt","Hoodie","Overall","ShirtCrewNeck","ShirtScoopNeck","ShirtVNeck"],clotheColor : ["Black","Blue01","Blue02","Blue03","Gray01","Gray02","Heather","PastelBlue","PastelGreen","PastelOrange","PastelRed","PastelYellow","Pink","Red","White"],eyebrowType : ["Angry","AngryNatural","Default","DefaultNatural","FlatNatural","RaisedExcited","RaisedExcitedNatural","SadConcerned","SadConcernedNatural","UnibrowNatural","UpDown","UpDownNatural"],eyeType : ["Close","Cry","Default","Dizzy","EyeRoll","Happy","Hearts","Side","Squint","Surprised","Wink","WinkWacky"],facialHairColor : ["Auburn","Black","Blonde","BlondeGolden","Brown","BrownDark","PastelPink","Platinum","Red","SilverGray"],facialHairType : ["Blank","BeardMedium","BeardLight","BeardMagestic","MoustacheFancy","MoustacheMagnum"],graphicType : ["Bat","Cumbia","Deer","Diamond","Hola","Pizza","Resist","Selena","Bear","SkullOutline","Skull"],hairColor : ["Auburn","Black","Blonde","BlondeGolden","Brown","BrownDark","PastelPink","Platinum","Red","SilverGray"],mouthType : ["Concerned","Default","Disbelief","Eating","Grimace","Sad","ScreamOpen","Serious","Smile","Tongue","Twinkle","Vomit"],skinColor : ["Tanned","Yellow","Pale","Light","Brown","DarkBrown","Black"],topType : ["NoHair","Eyepatch","Hat","Hijab","Turban","WinterHat1","WinterHat2","WinterHat3","WinterHat4","LongHairBigHair","LongHairBob","LongHairBun","LongHairCurly","LongHairCurvy","LongHairDreads","LongHairFrida","LongHairFro","LongHairFroBand","LongHairNotTooLong","LongHairShavedSides","LongHairMiaWallace","LongHairStraight","LongHairStraight2","LongHairStraightStrand","ShortHairDreads01","ShortHairDreads02","ShortHairFrizzle","ShortHairShaggyMullet","ShortHairShortCurly","ShortHairShortFlat","ShortHairShortRound","ShortHairShortWaved","ShortHairSides","ShortHairTheCaesar","ShortHairTheCaesarSidePart"],topColor : ["Black","Blue01","Blue02","Blue03","Gray01","Gray02","Heather","PastelBlue","PastelGreen","PastelOrange","PastelRed","PastelYellow","Pink","Red","White"]}const generate = (address) => {var addStr = address.substr(2, address.length - 2);var attributes = [];var gap = addStr.length / 13;var sidx = 0;for(const fkey in Features){var features = {};var seed = addStr.substr(sidx,gap);var values = Features[fkey];var valLength = values.length;var seedInt = parseInt(seed,16);var vidx = seedInt % valLength;var fval = values[vidx];sidx += gap;features["trait_type"] = fkey;features["value"] = fval;attributes.push(features);}return attributes;}module.exports = {generate};';

    }
    

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}