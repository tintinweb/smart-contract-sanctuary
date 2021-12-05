// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./ERC721PresetMinterPauserAutoId.sol";

contract Cowboys is ERC721PresetMinterPauserAutoId {

  uint256 public MAX_SUPPLY = 8888;
  uint256 public MAX_PER_WALLET = 10;
  uint public MINIMUM_MINT_AMOUNT = 50000000000000000 wei;
  bool public GENERAL_SALE_LIVE = false;
  bool public PRESALE_LIVE = false;

  constructor(

    string memory _name,
    string memory _symbol,
    string memory _baseURI

  ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseURI) {}


    function mintCowboy(address to, uint256 _amount) public payable {

      require(GENERAL_SALE_LIVE, 'GENERAL SALE IS NOT LIVE YET!');
      require(totalSupply() + _amount < MAX_SUPPLY, 'MAX_SUPPLY REACHED');
      require(_amount > 0, "Must be trying to mint positive number of COWBOYS");
      require(msg.value >= _amount*MINIMUM_MINT_AMOUNT, "Must send along at least MINIMUM_MINT_AMOUNT * number COWBOYS");
      require(balanceOf(to) + _amount < MAX_PER_WALLET,"Must be trying to mint less than MAX_PER_WALLET");

      for(uint i; i < _amount; i++) {
          mint(to);
      }

    }

    function mintCowboyPresale(address to, uint256 _amount) public payable {

      require(PRESALE_LIVE, 'PRESALE IS NOT LIVE YET!');
      require(totalSupply() + _amount < MAX_SUPPLY, 'MAX_SUPPLY REACHED');
      require(_amount > 0, "Must be trying to mint positive number of COWBOYS");
      require(msg.value >= _amount*MINIMUM_MINT_AMOUNT, "Must send along at least MINIMUM_MINT_AMOUNT * number COWBOYS");
      require(balanceOf(to) + _amount < MAX_PER_WALLET,"Must be trying to mint less than MAX_PER_WALLET");

      for(uint i; i < _amount; i++) {
          mint(to);
      }

    }

    function changePrice(uint newPrice) public onlyOwner {

      MINIMUM_MINT_AMOUNT = newPrice;

    }

    function changeMax(uint newMax) public onlyOwner {

      MAX_PER_WALLET = newMax;

    }

    function airdrop(address[] memory winners) public onlyOwner {
      require(totalSupply() + winners.length < MAX_SUPPLY, "Airdropped amount must keep total supply under MAX SUPPLY");
      for (uint256 i = 0; i < winners.length; i++) {
          mint(winners[i]);
      }
    }

    function transferFunds(address to) public onlyOwner() {

      address payable recipient = payable(to);
      recipient.transfer(address(this).balance);

    }

    function setSaleStatus(bool status) public onlyOwner() {

      GENERAL_SALE_LIVE = status;

    }

    function setPresaleStatus(bool status) public onlyOwner() {

      PRESALE_LIVE = status;

    }

}