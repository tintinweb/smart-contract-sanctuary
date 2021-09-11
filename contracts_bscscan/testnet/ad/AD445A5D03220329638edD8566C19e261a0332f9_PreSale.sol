// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "./SafeMath.sol";

interface IErc20Contract {
  function transferPresale1(address recipient, uint amount) external returns (bool);
}

contract PreSale {
  using SafeMath for uint;

  uint public constant _minimumDepositBNBAmount = 1 ether; // Minimum deposit is 1 BNB
  uint public constant _maximumDepositBNBAmount = 10 ether; // Maximum deposit is 10 BNB

  uint public constant _bnbAmountCap = 200 ether; // Allow cap at 200 BNB
  uint public constant _SEP_8_2021 = 1_631_059_200; // Presale1 starts at Sept 8 12am
  uint public constant _SEP_14_2021 = 1_631_577_600; // Presale1 ends at Sept 14 12am

  uint constant public _Sep_16_2021_1800 = 1_631_815_200; // 1st distribution - TGE date 
  uint constant public _Nov_16_2021 = 1_637_020_800; // 2nd distribution - Month 3 

  address payable public _admin; // Admin address
  address public _erc20Contract; // External erc20 contract

  uint public _totalAddressesDepositAmount; // Total addresses' deposit amount

  uint public _distributeFirstIndex;  // index to start distributeFirst
  uint public _distributeSecondIndex;  // index to start distributeSecond
  uint public _startDepositAddressIndex;  // start ID of deposit addresses list
  uint public _depositAddressesNumber;  // Number of deposit addresses
  mapping(uint => address) public _depositAddresses; // Deposit addresses
  mapping(address => bool) public _depositAddressesStatus; // Deposit addresses' whitelist status
  mapping(address => uint) public _depositAddressesBNBAmount; // Address' deposit amount

  mapping(address => uint) public _depositAddressesAwardedTotalErc20CoinAmount; // Total awarded ERC20 coin amount for an address
  mapping(address => uint) public _depositAddressesAwardedDistribution1Erc20CoinAmount; // Awarded 1st distribution ERC20 coin amount for an address
  mapping(address => uint) public _depositAddressesAwardedDistribution2Erc20CoinAmount; // Awarded 2nd distribution ERC20 coin amount for an address

  constructor(address erc20Contract) public {
    _admin = msg.sender;
    _erc20Contract = erc20Contract;
  }

  // Modifier
  modifier onlyAdmin() {
    require(_admin == msg.sender);
    _;
  }

  // Deposit event
  event Deposit(address indexed _from, uint _value);

  // Transfer owernship
  function transferOwnership(address payable admin) public onlyAdmin {
    require(admin != address(0), "Zero address");
    _admin = admin;
  }

  // Add deposit addresses and whitelist them
  function addDepositAddress(address[] calldata depositAddresses) external onlyAdmin {
    uint depositAddressesNumber = _depositAddressesNumber;
    for (uint i = 0; i < depositAddresses.length; i++) {
      if (!_depositAddressesStatus[depositAddresses[i]]) {
        _depositAddresses[depositAddressesNumber] = depositAddresses[i];
        _depositAddressesStatus[depositAddresses[i]] = true;
        depositAddressesNumber++;
      }
    }
    _depositAddressesNumber = depositAddressesNumber;
  }

  // Remove deposit addresses and unwhitelist them
  // number - number of addresses to process at once
  function removeAllDepositAddress(uint number) external onlyAdmin {
    require(block.timestamp < _SEP_8_2021, "Presale1 already started");
    uint i = _startDepositAddressIndex;
    uint last = i + number;
    if (last > _depositAddressesNumber) last = _depositAddressesNumber;
    for (; i < last; i++) {
      _depositAddressesStatus[_depositAddresses[i]] = false;
      _depositAddresses[i] = address(0);
    }
    _startDepositAddressIndex = i;
    _distributeFirstIndex = i;
    _distributeSecondIndex = i;
  }

  // Receive BNB deposit
  receive() external payable {
    require(block.timestamp >= _SEP_8_2021 && block.timestamp <= _SEP_14_2021,
      'Deposit rejected, presale1 has either not yet started or not yet overed');
    require(_totalAddressesDepositAmount < _bnbAmountCap, 'Deposit rejected, already reached the cap amount');
    require(_depositAddressesStatus[msg.sender], 'Deposit rejected, deposit address is not yet whitelisted');
    require(msg.value >= _minimumDepositBNBAmount, 'Deposit rejected, it is lesser than minimum amount');
    require(msg.value <= _maximumDepositBNBAmount, 'Deposit rejected, it is more than maximum amount');
    require(_depositAddressesBNBAmount[msg.sender].add(msg.value) <= _maximumDepositBNBAmount,
      'Deposit rejected, every address cannot deposit more than 10 bnb');

    if(_totalAddressesDepositAmount.add(msg.value) > _bnbAmountCap){
      // If total deposit + deposit greater than bnb cap amount
      uint value = _bnbAmountCap.sub(_totalAddressesDepositAmount);
      _depositAddressesBNBAmount[msg.sender] = _depositAddressesBNBAmount[msg.sender].add(value);
      _totalAddressesDepositAmount = _totalAddressesDepositAmount.add(value);
      msg.sender.transfer(msg.value.sub(value)); // Transfer back extra BNB

      _depositAddressesAwardedTotalErc20CoinAmount[msg.sender] = _depositAddressesAwardedTotalErc20CoinAmount[msg.sender].add(value.mul(2700));
      _depositAddressesAwardedDistribution1Erc20CoinAmount[msg.sender] = _depositAddressesAwardedDistribution1Erc20CoinAmount[msg.sender].add(value.mul(270));
      _depositAddressesAwardedDistribution2Erc20CoinAmount[msg.sender] = _depositAddressesAwardedDistribution2Erc20CoinAmount[msg.sender].add(value.mul(2430));

      emit Deposit(msg.sender, value);
    } else {
      _depositAddressesBNBAmount[msg.sender] = _depositAddressesBNBAmount[msg.sender].add(msg.value);
      _totalAddressesDepositAmount = _totalAddressesDepositAmount.add(msg.value);

      _depositAddressesAwardedTotalErc20CoinAmount[msg.sender] = _depositAddressesAwardedTotalErc20CoinAmount[msg.sender].add(msg.value.mul(2700));
      _depositAddressesAwardedDistribution1Erc20CoinAmount[msg.sender] = _depositAddressesAwardedDistribution1Erc20CoinAmount[msg.sender].add(msg.value.mul(270));
      _depositAddressesAwardedDistribution2Erc20CoinAmount[msg.sender] = _depositAddressesAwardedDistribution2Erc20CoinAmount[msg.sender].add(msg.value.mul(2430));

      emit Deposit(msg.sender, msg.value);
    }
  }

  // First distribution of ERC20 coin (Only 10% coin distributed)
  // number - number of addresses to process at once
  function distributeFirst(uint number) external {
    _distributeFirstIndex = _distribute(_Sep_16_2021_1800, 270, _distributeFirstIndex, number);
  }

  // Second distribution of ERC20 coin (Only 90% coin distributed)
  // number - number of addresses to process at once
  function distributeSecond(uint number) external {
    _distributeSecondIndex = _distribute(_Nov_16_2021, 2430, _distributeSecondIndex, number);
  }

  // Main distribution logic
  function _distribute(uint date, uint amount, uint i, uint number) private returns (uint){
    require(block.timestamp > date, "Distribution fail, have not reached the distribution date");

    IErc20Contract erc20Contract = IErc20Contract(_erc20Contract);

    uint last = i + number;
    if (last > _depositAddressesNumber) last = _depositAddressesNumber;
    require(i < last, "Already distributed");

    for (; i < last; i++) {
      address depositor = _depositAddresses[i];
      uint deposited = _depositAddressesBNBAmount[depositor];
      if (deposited != 0)
        erc20Contract.transferPresale1(depositor, deposited.mul(amount));
    }
    return i;
  }

  // Allow admin to withdraw all the deposited BNB
  function withdrawAll() external onlyAdmin {
    _admin.transfer(address(this).balance);
  }
}