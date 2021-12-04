// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract CryptoNekosPresale is Ownable, Pausable {
  using SafeMath for uint;

  uint constant public PRESALE_END_TIMESTAMP = 1633957199;

  uint constant public NORMAL_NEKOBOX_PRICE     = 0.001 * (10**18); // 0.1 BNB
  uint constant public EPIC_NEKOBOX_PRICE       = 0.002 * (10**18); // 0.2 BNB
  uint constant public LEGENDARY_NEKOBOX_PRICE  = 0.004 * (10**18); // 0.4 BNB
  uint constant public UNIQUE_NEKOBOX_PRICE     = 0.007 * (10**18); // 0.7 BNB

  uint constant public MAX_TOTAL_NORMAL_NEKOBOX = 10; // 2000;
  uint constant public MAX_TOTAL_EPIC_NEKOBOX = 8; // 1500;
  uint constant public MAX_TOTAL_LEGENDARY_NEKOBOX = 6; // 800;
  uint constant public MAX_TOTAL_UNIQUE_NEKOBOX = 4; // 100;

  uint constant public MAX_MINT_AMMOUNT = 5; //6;
  uint constant public MAX_UNIQUE_MINT_AMMOUNT = 2;

  uint public _totalAdoptedNormalNeko;
  uint public _totalAdoptedEpicNeko;
  uint public _totalAdoptedLegendaryNeko;
  uint public _totalAdoptedUniqueNeko;

  address public _contractOwner;

  mapping(address => uint) public _adopters;
  mapping(address => uint) public _normalAdopters;
  mapping(address => uint) public _epicAdopters;
  mapping(address => uint) public _legendaryAdopters;
  mapping(address => uint) public _uniqueAdopters;

  event NekoAdopted(address indexed adopter);
  event GetBalance(uint balance);

  constructor() {
    _contractOwner = msg.sender;
  }

  function adoptNormalNeko() public payable whenNotPaused {
    //require(block.timestamp <= PRESALE_END_TIMESTAMP, "The presale has ended");
    require(_totalAdoptedNormalNeko.add(1) <= MAX_TOTAL_NORMAL_NEKOBOX, "Can't adopt more Normal Nekos");
    require(_adopters[msg.sender].add(1) <= MAX_MINT_AMMOUNT, "Max mint ammount per wallet address exceeded");
    require(msg.value >= NORMAL_NEKOBOX_PRICE, "Insufficient BNB ammount");
    
    _normalAdopters[msg.sender] = _normalAdopters[msg.sender].add(1);
    _adopters[msg.sender] = _adopters[msg.sender].add(1);

    _totalAdoptedNormalNeko = _totalAdoptedNormalNeko.add(1);

    emit NekoAdopted(msg.sender);
  }

    function adoptEpicNeko() public payable whenNotPaused {
    //require(block.timestamp <= PRESALE_END_TIMESTAMP, "The presale has ended");
    require(_totalAdoptedEpicNeko.add(1) <= MAX_TOTAL_EPIC_NEKOBOX, "Can't adopt more Epic Nekos");
    require(_adopters[msg.sender].add(1) <= MAX_MINT_AMMOUNT, "Max mint ammount per wallet address exceeded");
    require(msg.value >= EPIC_NEKOBOX_PRICE, "Insufficient BNB ammount");
    
    _epicAdopters[msg.sender] = _epicAdopters[msg.sender].add(1);
    _adopters[msg.sender] = _adopters[msg.sender].add(1);

    _totalAdoptedEpicNeko = _totalAdoptedEpicNeko.add(1);

    emit NekoAdopted(msg.sender);
  }

  function adoptLegendaryNeko() public payable whenNotPaused {
    //require(block.timestamp <= PRESALE_END_TIMESTAMP, "The presale has ended");
    require(_totalAdoptedLegendaryNeko.add(1) <= MAX_TOTAL_LEGENDARY_NEKOBOX, "Can't adopt more Legendary Nekos");
    require(_adopters[msg.sender].add(1) <= MAX_MINT_AMMOUNT, "Max mint ammount per wallet address exceeded");
    require(msg.value >= LEGENDARY_NEKOBOX_PRICE, "Insufficient BNB ammount");
    
    _legendaryAdopters[msg.sender] = _legendaryAdopters[msg.sender].add(1);
    _adopters[msg.sender] = _adopters[msg.sender].add(1);

    _totalAdoptedLegendaryNeko = _totalAdoptedLegendaryNeko.add(1);

    emit NekoAdopted(msg.sender);
  }

  function adoptUniqueNeko() public payable whenNotPaused {
    //require(block.timestamp <= PRESALE_END_TIMESTAMP, "The presale has ended");
    require(_totalAdoptedUniqueNeko.add(1) <= MAX_TOTAL_UNIQUE_NEKOBOX, "Can't adopt more Unique Nekos");
    require(_adopters[msg.sender].add(1) <= MAX_MINT_AMMOUNT, "Max mint ammount per wallet address exceeded");
    require(msg.value >= UNIQUE_NEKOBOX_PRICE, "Insufficient BNB ammount");
    
    _uniqueAdopters[msg.sender] = _uniqueAdopters[msg.sender].add(1);
    _adopters[msg.sender] = _adopters[msg.sender].add(1);
   _totalAdoptedUniqueNeko = _totalAdoptedUniqueNeko.add(1);

    emit NekoAdopted(msg.sender);
  }


  /**
   * @dev Transfer all BNB held by the contract to the owner.
   */
  function reclaimBNB() external onlyOwner {
      payable(_contractOwner).transfer(address(this).balance);
  }

  function getBalance() external onlyOwner {
    emit GetBalance(address(this).balance);
  }
  
}