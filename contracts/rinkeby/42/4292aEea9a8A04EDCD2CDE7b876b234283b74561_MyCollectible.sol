// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
// import '@openzeppelin/contracts/access/Ownable.sol';

import './Ownable.sol';
import './ERC721Enumerable.sol';

contract MyCollectible is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _maxMint = 20;
    uint256 private _price = 3 * 10**16; //0.03 ETH;
    bool public _paused = true;
    uint public constant MAX_ENTRIES = 10000;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;

    constructor(string memory baseURI) ERC721("ReHuLu", "RHL")  {
        setBaseURI(baseURI);

        // team gets the first 50
        //mint(msg.sender, 10);
    }
    modifier onlyValidTokenHash(bytes32 _bytes32) {
        require(_check(_bytes32), "TokenHash does not exist");
        _;
    }
    
    function _check(bytes32 _bytes32) internal view returns (bool) {
        if(hashToTokenId[_bytes32] > 0) {
            return true;
        } else {
            return false;
        }
    }
    
    function mint(address _to, uint256 _count) external returns (uint256 _tokenId) {
          

        if(msg.sender != owner()) {
          require(!_paused, "Sale Paused");
        }
        
        require(totalSupply() + _count <= MAX_ENTRIES, "Max limit");
        require(totalSupply() < MAX_ENTRIES, "Sale end");
        require(_count <= 20, "Exceeds 20");
        // require( msg.value >= _price * _count,"Ether sent is not correct" );

        for(uint256 i=0; i < _count; i++){
         
          _safeMint( _to, totalSupply());
           bytes32 hash = keccak256(abi.encodePacked(totalSupply(),block.number, block.timestamp, msg.sender));
           tokenIdToHash[totalSupply()]=hash;
           hashToTokenId[hash] = totalSupply();
        }
        
    }


    // function mint(address _to, uint256 num) public payable {
    //     uint256 supply = totalSupply();
    //     uint256 tokenIdToBe;
    //     if(msg.sender != owner()) {
    //       require(!_paused, "Sale Paused");
    //       require( num < (_maxMint+1),"You can adopt a maximum of _maxMint Penguins" );
    //       require( msg.value >= _price * num,"Ether sent is not correct" );
    //     }

    //     require( supply + num < MAX_ENTRIES,            "Exceeds maximum supply" );

    //     for(uint256 i; i < num; i++){
    //         tokenIdToBe = supply + i + 1;
    //       _safeMint( _to,  tokenIdToBe);
    //       bytes32 hash = keccak256(abi.encodePacked(tokenIdToBe,block.number, block.timestamp, msg.sender));
    //       tokenIdToHash[tokenIdToBe]=hash;
    //       hashToTokenId[hash] = tokenIdToBe;
    //     }
    // }
    
    function hashTrait(bytes32 _bytes32) external view onlyValidTokenHash(_bytes32) returns (uint256 ) {
        
        
        return hashToTokenId[_bytes32];
        // return 123;
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

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}