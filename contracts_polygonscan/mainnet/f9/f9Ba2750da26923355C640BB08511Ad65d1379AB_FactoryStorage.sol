//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract FactoryStorage {

  address public storage_admin;
  //address allowed to call some functions with onlyAdmin restrictions
  address public contract_admin;
  //owner of royalties
  address payable public royaltyRecipient;
  //address of the artist 
  address payable public artist;

  uint256 public NFT_ID;

  struct ModelNFT {
    string name;
    uint256 id;
    uint24 fee;
  }
  //Array with all NFT's minted
  ModelNFT [] public NFTModels;
  //map to get the amount of minted tokens according to the token id
  mapping(uint256 => uint256) public tokenAmount;

  constructor(address payable _artist) {
    artist = _artist;
    storage_admin = _msg_Sender();
    contract_admin = _msg_Sender();
    royaltyRecipient = payable(_msg_Sender());
    NFT_ID = 0;
  }
  /**
  * @dev Setter of 'storage_admin' 
  */
  function setNewAdmin(address _newAdmin) public onlyAdmin {
    require(storage_admin != _newAdmin, "this is already the address setted");
    storage_admin = _newAdmin;
  }
  /**
  * @dev Setter of 'contract_admin' 
  */
  function setNewContractAdmin(address _newAdmin) public onlyAdmin {
    require(contract_admin != _newAdmin, "this is already the address setted");
    contract_admin = _newAdmin;
  }
  /**
  * @dev Setter of 'royaltyRecipient' 
  */
  function setRoyaltyRecipient(address payable _royaltyRecipient) public onlyAdmin {
    require(royaltyRecipient != _royaltyRecipient, "this is already the address setted");
    royaltyRecipient = _royaltyRecipient;
  }
  /**
  * @dev called by 'contract_admin' when a token is minted in the logic contract and saves the new token data
  */
  function addNFT(string memory _name, uint256 _amount, uint24 _fee) public onlyContractAdmin returns (uint256){
    ModelNFT memory model = ModelNFT(_name, NFT_ID , _fee);
    NFTModels.push(model);
    tokenAmount[NFT_ID] = _amount;
    NFT_ID++;
    return (NFT_ID - 1);
  }
 /**
  * @dev Returns the Artist of the collection
  */
  function getArtist() public view returns (address payable) {
    return artist;
  }
  /**
  * @dev Returns the admins
  */
  function getAdmin() public view returns (address, address) {
    return (storage_admin, contract_admin);
  }
  /**
  * @dev Returns 'royaltyRecipient'
  */
  function getRoyaltyRecipient() public view returns (address) {
    return royaltyRecipient;
  }
  /**
  * @dev Returns 'NFT_ID'
  */
  function getNFT_ID() public view returns (uint256) {
    return NFT_ID;
  }

  /**
  * @dev Returns a NFT from 'NFTModels[]'
  */
  function getNFTModel(uint256 _tokenId) public view returns (ModelNFT memory) {
    return NFTModels[_tokenId];
  }

  /**
  * @dev Returns the amount of a minted token
  */
  function getTokenAmount(uint256 _tokenId) public view returns (uint256) {
    return tokenAmount[_tokenId];
  }
  /**
  * @dev Returns all info of a minted token
  */
  function getTokenInfo(uint256 _tokenId) public view returns (string memory name, uint24 fee,uint256 amount, address payable _artist) {
    return(
      NFTModels[_tokenId].name,
      NFTModels[_tokenId].fee,
      tokenAmount[_tokenId],
      artist
    );
  }
  /**
  * @dev Returns true if the token has been minted 
  */
  function _exists(uint256 tokenId) public view returns (bool) {
    return tokenAmount[tokenId] > 0;
  }

  function _msg_Sender() internal view returns (address) {
    return msg.sender;
  }

  modifier onlyAdmin() {
    require(storage_admin == _msg_Sender());
    _;
  }
  modifier onlyContractAdmin() {
    require(contract_admin == _msg_Sender());
    _;
  }

}