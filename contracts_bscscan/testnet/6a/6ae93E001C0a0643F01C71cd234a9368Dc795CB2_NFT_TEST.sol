/*
 
*/


// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
 
import "./crnft-metadata.sol";
import "./ownable.sol";



 
contract NFT_TEST is NFTokenMetadata, Ownable {
    
  uint8 private _total = 0;
  uint256 public price = 15 * 10**17;
  uint8 public maxMints = 100;
  mapping (address => uint256) _addresses;
  address payable operator; 
  string private  uri;
  uint256[] idList_of_owner;
  bool inGetIdListFromOwner;
  
  
   /*modifier lockTheSwap {
        inGetIdListFromOwner = true;
        _;
        inGetIdListFromOwner = false;
    }*/
    
 
  constructor() {
    nftName = "NFT_TEST";
    nftSymbol = "NFT_TEST";
    uri = 'https://ipfs.io/ipfs/QmeswHitwXe4U8EWX33VXMXiXk7ZkdMEBWtXSQ9Pjvqm99';
    
  }
  
  function totalSupply() public view returns (uint8) {
        return _total;
  }
 
  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
    require (maxMints >= _total, "Err3");
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
    _total = _total + 1;
  }
  
   function setOperatorAddress(address payable _operator) public onlyOwner {
        operator = _operator;
    }
  
  
    function buy() public payable {
        require (msg.value >= price, "Err1"); 
        require (_addresses[msg.sender] == 0, "Err2");
        require (maxMints >= _total, "Err3");
        
        operator.transfer(msg.value);
        
        _mintIt(msg.sender, _total, uri);
        _addresses[msg.sender] = block.timestamp;
    }
    
    function _mintIt(address _to, uint256 _tokenId, string memory _uri) internal  {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
    _total = _total + 1;
    }
    
    
   /*function getUri() internal returns(string memory){
        return uri;
    }*/
  
    /*function getArrayLength() public view returns(uint count) {
    return idList_of_owner.length;
    }
    
    function getIdListFromOwner (address _owner) public view lockTheSwap returns (uint256[] memory)  {
        
        for (uint256 i = getArrayLength(); i < getArrayLength(); i++)
        {
            idList_of_owner.pop();
        }
        
        for (uint256 i = 0; i <= _total; i++)
        {
            if (idToOwner[i] == _owner)
                 idList_of_owner.push(i);
        }
        return idList_of_owner;
    }*/
    
    
    function updatePrice (uint256 amount)  external onlyOwner {
        
        price = amount;
        
    }
    
    
    /*function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
    )
    external
    override
    canTransfer(_tokenId)
    validNFToken(_tokenId)
   {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
   }

    
    function _transfer(
    address _to,
    uint256 _tokenId
    )
    internal
    {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
    }*/


}