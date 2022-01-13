/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

pragma solidity ^0.8.7;
 
contract owned {
  address owner;
   
  constructor() {
    owner = msg.sender;
  }
   
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner  public {
    owner = newOwner;
  }
}
   
contract LicenseToken is owned {
  enum LicenseType {WIN, MAC}
  enum LicenseState {ACTIVE, INACTIVE, EXPIRED}
   
  uint constant LICENSE_LIFE_TIME = 30 days;
   
  struct LicenseInfo {
    LicenseType licenseType;
    uint registeredOn;
    uint expiresOn;
    LicenseState state;
    string deviceId;
  }
   
  LicenseInfo[] tokens;
   
  mapping (uint256 => address) public tokenIndexToOwner;
  mapping (address => uint256) ownershipTokenCount;
  mapping (uint256 => address) public tokenIndexToApproved;
   
  event LicenseGiven(address account, uint256 tokenId);
  event Transfer(address from, address to, uint256 tokenId);
  event Approval(address owner, address approved, uint256 tokenId);
   
  constructor()  {
  }
   
  // ERC-721 functions
  function totalSupply() public view returns (uint256 total) {
    return tokens.length;
  }
   
  function balanceOf(address _account) public view returns (uint256 balance) {
     return ownershipTokenCount[_account];
  }
   
  function ownerOf(uint256 _tokenId) public view returns (address owner) {
    owner = tokenIndexToOwner[_tokenId];
    require(owner != address(0));
   
    return owner;
  }
   
  function transferFrom(address _from, address _to, uint256 _tokenId) onlyOwner public {
    require(_to != address(0));
    require(_to != address(this));
    require(_owns(_from, _tokenId));
   
    _transfer(_from, _to, _tokenId);
  }
   
  function approve(address _to, uint256 _tokenId) public {
    require(_owns(msg.sender, _tokenId));
    tokenIndexToApproved[_tokenId] = _to;
    emit Approval(tokenIndexToOwner[_tokenId], tokenIndexToApproved[_tokenId], _tokenId);
  }
   
//   function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
//     // method is not implemented because it is not needed for licensing logic
//   }
   
//   function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public {
//     // method is not implemented because it is not needed for licensing logic
//   }
   
//   function setApprovalForAll(address _operator, bool _approved) public  pure{
//     // method is not implemented because it is not needed for licensing logic
//   }
   
//   function getApproved(uint256 _tokenId) public pure returns (address) {
//     // method is not implemented because it is not needed for licensing logic
//     return address(0);
//   }
   
//   function isApprovedForAll(address _owner, address _operator) public pure returns (bool) {
//     // method is not implemented because it is not needed for licensing logic
//     return false;
//   }
   
  // licensing logic
  function giveLicense(address _account, uint _type) onlyOwner public {
    uint256 tokenId = _mint(_account, _type);
    emit LicenseGiven(_account, tokenId);
  }
   
  function activate(uint _tokenId, string memory _deviceId) onlyOwner public {
    LicenseInfo storage token = tokens[_tokenId];
    require(token.registeredOn != 0);
    require(token.state == LicenseState.INACTIVE);
   
    token.state = LicenseState.ACTIVE;
    token.expiresOn = block.timestamp + LICENSE_LIFE_TIME;
    token.deviceId = _deviceId;
  }
   
  function burn(address _account, uint _tokenId) onlyOwner public {
    require(tokenIndexToOwner[_tokenId] == _account);
   
    ownershipTokenCount[_account]--;
    delete tokenIndexToOwner[_tokenId];
    delete tokens[_tokenId];
    delete tokenIndexToApproved[_tokenId];
  }
   
  function isLicenseActive(address _account, uint256 _tokenId) public view returns (uint state){
    require(tokenIndexToOwner[_tokenId] == _account);
   
    LicenseInfo memory token = tokens[_tokenId];
    if (token.expiresOn < block.timestamp && token.state == LicenseState.ACTIVE) {
       return uint(LicenseState.EXPIRED);
    }
   
    return uint(token.state);
  }
   
  function handleExpiredLicense(address _account, uint256 _tokenId) onlyOwner public {
    require(tokenIndexToOwner[_tokenId] == _account);
   
    LicenseInfo storage token = tokens[_tokenId];
    if (token.expiresOn < block.timestamp && token.state == LicenseState.ACTIVE) {
       burn(_account, _tokenId);
    }
  }
   
  // internal methods
  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return tokenIndexToOwner[_tokenId] == _claimant;
  }
   
  function _mint(address _account, uint _type) onlyOwner internal returns (uint256 tokenId) {
    // create new token
    LicenseInfo memory token = LicenseInfo({
        licenseType: LicenseType(_type),
        state: LicenseState.INACTIVE,
        registeredOn: block.timestamp,
        expiresOn: 0,
        deviceId: ""
    });
    tokens.push(token);
    uint id= tokens.length - 1;
    _transfer(address(0), _account, id);
    return id;
  }
   
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
   ownershipTokenCount[_to]++;
   tokenIndexToOwner[_tokenId] = _to;
   
   if (_from != address(0)) {
     ownershipTokenCount[_from]--;
     delete tokenIndexToApproved[_tokenId];
   }
   emit Transfer(_from, _to, _tokenId);
  }
}