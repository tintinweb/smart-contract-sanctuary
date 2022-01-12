// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721EnumerableLite.sol';
import './Signed.sol';
import "./Strings.sol";

contract SwipaTheFox is ERC721EnumerableLite, Signed {
  using Strings for uint;

  uint public maxMint = 5;
  uint public maxSupply = 2255; //presale amount change to 10005 for mainsale
  uint public mintPrice = 0.07 ether;
  bool public isSaleActive = false;
  bool public withdrew_initial = false;
  string private _tokenURI_Prefix = '';

  address public devAddress1 = 0x2Dd146bcf2Dae32851fCeE09e5F3a4E886eFe076;
  address public devAddress2 = 0x3e81D9B5E4fD4C7C3f69bb4396A857d41D1A3471;
  address public NFTA_Address = 0x855A67D331a52C8701306B7bfa62EaBa68F25F44;
  address public CommunityAddress = 0x266Db4743755109a5926D6fDeD5ED6F6a284aB98;
  address public oAddress = 0x6662DF22aE83a8cCfc9c99C641aA54dE8E120407;
  address public pop1Address = 0x39fF53cEAA56f6761bB938500a1449Eee67d9399;
  address public pop2Address = 0x8e90fd7C6642B653965c8B65013711C53c847bd7;

  constructor()
    Delegated()
    ERC721B("Swipa The Fox", "SWIPA", 0){
  }

  fallback() external payable {}

  receive() external payable {}

  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURI_Prefix, tokenId.toString() ));
  }

  function mint( uint quantity ) external payable {
    require( isSaleActive, "Swipa sale is not active" );
    require( quantity <= maxMint, "Swipa amount too big" );
    require( msg.value >= mintPrice * quantity, "Not enough ether sent" );

    uint supply = totalSupply();
    require( supply + quantity <= maxSupply, "Order exceeds supply" );

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

  //Giveaway nfts, etc.
  function ownerMint(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates {
    require(quantity.length == recipient.length, "The arrays must be equal" );

    uint totalQuantity;
    uint supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= maxSupply, "Order exceeds supply" );
    delete totalQuantity;

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _mint( recipient[i], supply++ );
      }
    }
  }

  function setSaleActive(bool isSaleActive_ ) external onlyDelegates{
    require( isSaleActive != isSaleActive_ , "Values are not valid" );
    isSaleActive = isSaleActive_;
  }


  function setBaseURI( string calldata baseURI ) external onlyDelegates {
    _tokenURI_Prefix = baseURI;
  }

  function setValues(uint _maxMint, uint _maxSupply, uint _price ) external onlyDelegates {
    require( maxMint != _maxMint || maxSupply != _maxSupply || mintPrice != _price, "Values are not valid" );
    require(_maxSupply >= totalSupply(), "New supply is less than previous supply" );

    maxMint = _maxMint;
    maxSupply = _maxSupply;
    mintPrice = _price;
  }

  function finalize() external onlyOwner {
    selfdestruct(payable(owner()));
  }

  function withdraw_initial() external onlyOwner {
        require(address(this).balance > 25.19 ether, "Not enough ether to withdraw");
        require(withdrew_initial == false, "Already withdrew initial");
        (bool initial1WithdrawStatus,) = NFTA_Address.call{value: 23.22 ether}("");
        (bool initial2WithdrawStatus,) = devAddress1.call{value: 0.98 ether}("");
        (bool initial3WithdrawStatus,) = devAddress2.call{value: 0.99 ether}("");

        withdrew_initial = true;
        require(initial1WithdrawStatus && initial2WithdrawStatus && initial3WithdrawStatus, "Failed withdrawing inital");
  }

  function emergencyWithdraw() external onlyOwner {
      (bool emergencyWithdrawStatus,) = devAddress1.call{value: address(this).balance}("");
      require(emergencyWithdrawStatus, "Failed Emergency Withdraw");
  }

  function emergencyWithdraw2() external onlyOwner {
      (bool emergencyWithdrawStatus2,) = devAddress2.call{value: address(this).balance}("");
      require(emergencyWithdrawStatus2, "Failed Emergency Withdraw");
  }

  function withdraw() external {
    require(address(this).balance > 0, "Not enough ether to withdraw");
    require(withdrew_initial == true, "Have not withdrew initial");
    uint256 walletBalance = address(this).balance;
        
    (bool withdraw_1,) = devAddress1.call{value: walletBalance * 425 / 10000}(""); //4.25 
    (bool withdraw_2,) = devAddress2.call{value: walletBalance * 425 / 10000}(""); //4.25
    (bool withdraw_3,) = NFTA_Address.call{value: walletBalance * 365 / 1000}(""); //36.5
    (bool withdraw_4,) = CommunityAddress.call{value: walletBalance * 10 / 100}(""); //10
    (bool withdraw_5,) = oAddress.call{value: walletBalance * 40 / 100}(""); //40
    (bool withdraw_6,) = pop1Address.call{value: walletBalance * 3 / 100}(""); //3
    (bool withdraw_7,) = pop2Address.call{value: walletBalance * 2 / 100}(""); //2

    require(withdraw_1 && withdraw_2 && withdraw_3 && withdraw_4 && withdraw_5 && withdraw_6 && withdraw_7, "Failed withdraw");
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