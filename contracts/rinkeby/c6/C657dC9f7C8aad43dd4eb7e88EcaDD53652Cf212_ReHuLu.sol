// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
// import '@openzeppelin/contracts/access/Ownable.sol';




import './Ownable.sol';
import './ERC721Enumerable.sol';



contract ReHuLu is ERC721Enumerable, Ownable{
    
    struct Trait {
        uint size;
        uint color;
        uint level;

    }
    
    struct FeatureBase {
        string name;
        string style;
        uint max;
        uint min;
    }
    
    

    using Strings for uint256;
    
    string _baseTokenURI;
    uint256 private _price = 3 * 10**16; //0.03 ETH;
    bool public _paused = true;
    uint public constant MAX_SUPPLY = 1000;
    mapping(uint256 => bytes32) private tokenIdToHash;
    mapping(bytes32 => uint256) private hashToTokenId;
    mapping(bytes32 => uint256[]) private hashToRadomValues;

    mapping(uint256 => Trait) traits;
    uint256[] private traitValues;
    FeatureBase private feature1;
    FeatureBase private feature2;
    FeatureBase private feature3;


    string _featuresJSON;

    
    constructor(string memory baseURI) ERC721("ReHuLu", "RHL")  {
        setBaseURI(baseURI);
        feature1.name = "size";
        feature1.style = "range";
        feature1.max = 100;
        feature1.min = 1;
        feature2.name = "color";
        feature2.style = "range";
        feature2.max = 50;
        feature2.min = 1;
        feature3.name = "level";
        feature3.style = "range";
        feature3.max = 10;
        feature3.min = 1;
        
    }
    modifier onlyValidTokenId(uint _tokenId) {
        require(_checkTokenId(_tokenId), "TokenId not exist");
        _;
    }
    
    
    modifier onlyValidHash(bytes32 _bytes32) {
        require(_checkHash(_bytes32), "TokenHash not exist");
        _;
    }
    
    function _checkHash(bytes32 _bytes32) internal view returns (bool) {
        
        require(uint(_bytes32) != 0,"bytes32 not 0x00");
        uint tokenId = hashToTokenId[_bytes32];
        if(tokenId == 0) {
            bytes32 b1 = tokenIdToHash[0];
            if(uint(b1) != uint(_bytes32)) {
                return false;
            } else{
                return true;
            }
        } 
        
  
        return true;
    }
    
    function _checkTokenId(uint _tokenId) internal view returns(bool){
        bytes32 hash = tokenIdToHash[_tokenId];
        if(uint(hash) != 0){
            return true;
        }
        return false;
    }
    
    
    function mint(address to) external {
         
        if(msg.sender != owner()) {
          require(!_paused, "Mint Paused");
        }
        require(totalSupply() < MAX_SUPPLY, "Max limit");
        
       uint256 tokenId = totalSupply();
       bytes32 hash = keccak256(abi.encodePacked(tokenId));
       
       tokenIdToHash[tokenId] = hash;
       hashToTokenId[hash] = tokenId;
       
       tokenHashToValue(tokenId,hash);
       
       _safeMint(to,  tokenId);
        
    }
    
    function bytes1ToUint(bytes1 _bytes1)  internal returns (uint256 ){
    
        uint256 number;
        for(uint i = 0; i < _bytes1.length; i++){
            number = number + uint8(_bytes1[i])*(2**(8*(_bytes1.length-(i+1))));
       
        }
        return  number;
    }
    
    function tokenHashToValue(uint _tokenId, bytes32 _hash ) internal {
         
         uint temp = 0;
         delete traitValues;
         for(uint i=0;i<_hash.length;i++) {
            bytes1 a = _hash[i];
            uint t =  bytes1ToUint(a); 
            temp = temp + t;
            if(i%4 == 0) {
                 traitValues.push(temp % 100);
                 temp = 0;
            }
         }
         hashToRadomValues[_hash] = traitValues;
         traits[_tokenId].size =  feature1.min + traitValues[0] % (feature1.max - feature1.min + 1);
         traits[_tokenId].color = feature2.min + traitValues[1] % (feature2.max - feature2.min + 1);
         traits[_tokenId].level = feature3.min + traitValues[2] % (feature3.max - feature3.min + 1);
         
        
         
    }
    
    function tokenIdToHashValue(uint256 _tokenId) public view returns(uint256[] memory) {
        bytes32 hash = tokenIdToHash[_tokenId];
        return  hashToRadomValues[hash];
    }
    
    function tokenIdToTrait(uint256 _tokenId) public view returns (uint256 size, uint256 color, uint256 level) {
        require(_checkTokenId(_tokenId),"tokenId not exist");
        size = traits[_tokenId].size;
        color = traits[_tokenId].color;
        level = traits[_tokenId].level;
   
    }


    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getPrice() public view returns (uint256){
        if(msg.sender == owner()) {
            return 0;
        }
        return _price;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }
    
    function tokenIdToByte32Hash(uint _tokenId) onlyValidTokenId(_tokenId)  public view returns(bytes32) {
        
        return tokenIdToHash[_tokenId];
    }
    function byte32HashToTokenId(bytes32 _bytes32) onlyValidHash(_bytes32) public view returns(uint) {
  
        return hashToTokenId[_bytes32];
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    function getFeatures() public view returns (string memory f1_name,string memory f1_style,uint f1_max,uint f1_min,string memory f2_name,string memory f2_style,uint f2_max,uint f2_min,string memory f3_name,string memory f3_style,uint f3_max,uint f3_min) {
        f1_name  = feature1.name;
        f1_style = feature1.style;
        f1_max   = feature1.max;
        f1_min   = feature1.min;
        
        f2_name  = feature2.name;
        f2_style = feature2.style;
        f2_max   = feature2.max;
        f2_min   = feature2.min;
        
        f3_name  = feature3.name;
        f3_style = feature3.style;
        f3_max   = feature3.max;
        f3_min   = feature3.min;
    }
    
    function updateFeatures1(uint _sizeMax,uint _sizeMin) onlyOwner public {
        require(_sizeMax > _sizeMin, "_sizeMax must be greater than _sizeMin");
        feature1.max = _sizeMax;
        feature1.min = _sizeMin;
    }
    
    function updateFeatures2(uint _colorMax,uint _colorMin) onlyOwner public {
        require(_colorMax > _colorMin, "_colorMax must be greater than _colorMin");
        feature2.max = _colorMax;
        feature2.min = _colorMin;
    }
    
    function updateFeatures3(uint _levelMax,uint _levelMin) onlyOwner public {
        require(_levelMax > _levelMin, "_levelMax must be greater than _levelMin");
        feature3.max = _levelMax;
        feature3.min = _levelMin;
    }
    
    function compareStr(string memory s1, string memory s2) public pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
    
 
    

}