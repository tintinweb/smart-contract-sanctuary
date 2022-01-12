// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721EnumerableLite.sol';
import './Signed.sol';
import "./Strings.sol";

//Ashley Longshore x Metagolden
//Ashley Longshore x Metagolden
//Ashley Longshore x Metagolden

contract AshleyMetagolden is ERC721EnumerableLite, Signed {
  using Strings for uint;

  uint public MGOLD_MaxMint = 10;
  uint public MGOLD_MaxSupply = 862;
  uint public MGOLD_MintPrice = 0.16 ether;
  bool public MGOLD_SaleActive = false;
  string private MGOLD_TokenURI = 'https://gateway.pinata.cloud/ipfs/QmXtR8i3EbZDgio9rz24KUWBcqg3S5avZdA34VqEvUYv4v/';

  address public MGOLD_Address1 = 0xAE8EaBB58327f856D93248c2a009291d26BfdE18;
  address public MGOLD_Address2 = 0xAE8EaBB58327f856D93248c2a009291d26BfdE18;

  constructor()
    Delegated()
    ERC721B("Ashley Longshore x Metagolden", "MGOLD", 0){
  }

  fallback() external payable {}

  receive() external payable {}

  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(MGOLD_TokenURI, tokenId.toString() ));
  }

  function mint( uint quantity ) external payable {
    require( MGOLD_SaleActive, "Ashley Longshore x Metagolden Sale is not active" );
    require( quantity <= MGOLD_MaxMint, "Ashley Longshore x Metagolden mint is too big" );
    require( msg.value >= MGOLD_MintPrice * quantity, "Invalid Ether Amount" );

    uint supply = totalSupply();
    require( supply + quantity <= MGOLD_MaxSupply, "Not enough NFTs left :(" );

    for(uint i; i < quantity; ++i){
      _mint( msg.sender, supply++ );
    }
  }

  function burnTokens(address account, uint[] calldata tokenIds) external payable onlyDelegates {
    for(uint i; i < tokenIds.length; ++i ){
      require( _owners[ tokenIds[i] ] == account, "Could not verify owner" );
      _burn( tokenIds[i] );
    }
  }

  //Used for the owner to mint the nfts to the wallet of the fiat purchasers
  function fiat_mint(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates {
    require(quantity.length == recipient.length, "Quantity array and recipient array are not equal" );

    uint totalQuantity;
    uint supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= MGOLD_MaxSupply, "Not enough NFTs left :(" );
    delete totalQuantity;

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _mint( recipient[i], supply++ );
      }
    }
  }

  function Set_MGOLD_SaleActive(bool MGOLD_SaleActive_ ) external onlyDelegates{
    require( MGOLD_SaleActive != MGOLD_SaleActive_ , "Same value as before" );
    MGOLD_SaleActive = MGOLD_SaleActive_;
  }

  function setBaseURI( string calldata baseURI ) external onlyDelegates {
    MGOLD_TokenURI = baseURI;
  }

  function setValues(uint _MGOLD_MaxMint, uint _MGOLD_MaxSupply, uint _price, address _MGOLD_Address1, address _MGOLD_Address2 ) external onlyDelegates {
    require( MGOLD_MaxMint != _MGOLD_MaxMint || MGOLD_MaxSupply != _MGOLD_MaxSupply || MGOLD_MintPrice != _price || MGOLD_Address1 != _MGOLD_Address1 || MGOLD_Address2 != _MGOLD_Address2, "Same values as before" );
    require(_MGOLD_MaxSupply >= totalSupply(), "New supply is less than previous supply" );

    MGOLD_MaxMint = _MGOLD_MaxMint;
    MGOLD_MaxSupply = _MGOLD_MaxSupply;
    MGOLD_MintPrice = _price;
    MGOLD_Address1 = _MGOLD_Address1;
    MGOLD_Address2 = _MGOLD_Address2;
  }

  function finalize() external onlyOwner {
    selfdestruct(payable(owner()));
  }

  function emergency_withdraw() external onlyOwner {
    (bool emergency_withdraw_status,) = MGOLD_Address1.call{value: address(this).balance}("");
    require(emergency_withdraw_status, "Failed Emergency Withdraw");
  }

  function withdraw() external {
    require(address(this).balance > 0, "Not enough ether to withdraw");
    uint256 walletBalance = address(this).balance;
        
    (bool withdrew_address1,) = MGOLD_Address1.call{value: walletBalance * 50 / 100}(""); //50
    (bool withdrew_address2,) = MGOLD_Address2.call{value: walletBalance * 50 / 100}(""); //50

    require(withdrew_address1 && withdrew_address2, "Failed withdraw");
  }

  function _beforeTokenTransfer(address from, address to, uint tokenId) internal override {
    if( from != address(0) )
      --_balances[from];

    if( to != address(0) )
      ++_balances[to];
  }

  function _burn(uint tokenId) internal override {
    //failsafe
    address from = ownerOf(tokenId);
    _approve(owner(), tokenId);
    _beforeTokenTransfer( from, address(0), tokenId );

    ++_burned;
    _owners[tokenId] = address(0);
    emit Transfer(from, address(0), tokenId);
  }

  function _mint(address to, uint tokenId) internal override {
    _beforeTokenTransfer( address(0), to, tokenId );

    _owners.push(to);
    emit Transfer(address(0), to, tokenId);
  }

}