// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './Ownable.sol';
import './ERC721Enumerable.sol';



contract MarkArts is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _maxMint = 3;
    uint256 private _price = 1*10**16; //0.01 ETH;
    bool public saleIsActive = false;
    uint public constant MAX_SUPPLY = 1000;
    mapping(uint256 => bytes32) private tokenIdToHash;
    mapping(bytes32 => uint256) private hashToTokenId;
    
    event mint(address indexed owner,uint256 indexed tokenId);
    


    constructor(string memory baseURI) ERC721("MarkArts", "MKAT")  {
        setBaseURI(baseURI);
        
    }
    
    modifier onlyValidTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "Token ID does not exist");
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
    

    function mintNFT(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(num > 0 && num <= _maxMint, "Exceeded max token purchase");
        require( supply + num <= MAX_SUPPLY,  "Exceeds maximum supply" );
        require( msg.value >= _price * num,"Ether sent is not correct" );
        


        for(uint256 i; i < num; i++){
            uint256 tokenId = supply + i;
            _safeMint(msg.sender, tokenId);
            bytes32 hash = keccak256(abi.encodePacked(tokenId,block.number,msg.sender));
            tokenIdToHash[tokenId] = hash;
            hashToTokenId[hash] = tokenId;
            emit mint(msg.sender,tokenId);
        }
            
              
           
    }
    
     function tokenIdToByte32Hash(uint _tokenId) onlyValidTokenId(_tokenId)  public view returns(bytes32) {
        
        return tokenIdToHash[_tokenId];
    }
    function byte32HashToTokenId(bytes32 _bytes32) onlyValidHash(_bytes32) public view returns(uint) {
  
        return hashToTokenId[_bytes32];
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

    function getMaxMint() public view returns (uint256){
        return _maxMint;
    }

    function setMaxMint(uint256 _newMaxMint) public onlyOwner() {
        _maxMint = _newMaxMint;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setSaleState(bool val) public onlyOwner {
        saleIsActive = val;
            
    }
    

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}