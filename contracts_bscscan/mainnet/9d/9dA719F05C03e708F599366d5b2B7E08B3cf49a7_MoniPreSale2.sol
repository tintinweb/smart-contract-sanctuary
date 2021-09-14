pragma solidity 0.6.0;

import "./SafeMath.sol";

interface IErc20Contract {
  function transferPresale2(address recipient, uint amount) external returns (bool);
}

contract MoniPreSale2 {
  using SafeMath for uint;

  uint public constant _minimumDepositBNBAmount = 0.1 ether; // Minimum deposit is 0.1 BNB
  uint public constant _bnbAmountCap = 3150 ether; // Allow cap at 3150 BNB, return remaining amount back to deposit address
  uint public constant _SEP_15_2021_00_00_00 = 1_631_664_000; // Presale2 starts at Sept 15 12am
  uint public constant _SEP_15_2021_18_00_00 = 1_631_728_800; // Presale2 ends at Sept 15 6pm
  
  uint public constant _Sep_16_2021_1800 = 1_631_815_200; // 1st distribution - TGE date
  uint public constant _Sep_30_2021  = 1_632_960_000; // 2nd distribution - Week 2 
  uint public constant _Oct_16_2021 = 1_634_342_400; // 3rd distribution - Month 2

  bool public _shouldPresale2EndEarlier; // Has Admin decided to end preSale2 earlier? 

  address payable public _admin; // Admin address
  address public _erc20Contract; // External erc20 contract

  uint public _totalAddressesDepositAmount; // Total addresses' deposit amount
  uint public _distributeFirstIndex;  // index to start distributeFirst
  uint public _distributeSecondIndex;  // index to start distributeSecond
  uint public _distributeThirdIndex;  // index to start distributeThird
  uint public _startDepositAddressIndex;  // start ID of deposit addresses list
  uint public _depositAddressesNumber;  // Number of deposit addresses
  mapping(uint => address) public _depositAddresses; // Deposit addresses
  mapping(address => bool) public _depositAddressesStatus; // Deposit addresses' whitelist status
  mapping(address => uint) public _depositAddressesBNBAmount; // Address' deposit amount

  mapping(address => uint) public _depositAddressesAwardedTotalErc20CoinAmount; // Total awarded ERC20 coin amount for an address
  mapping(address => uint) public _depositAddressesAwardedDistribution1Erc20CoinAmount; // Awarded 1st distribution ERC20 coin amount for an address
  mapping(address => uint) public _depositAddressesAwardedDistribution2Erc20CoinAmount; // Awarded 2nd distribution ERC20 coin amount for an address
  mapping(address => uint) public _depositAddressesAwardedDistribution3Erc20CoinAmount; // Awarded 3rd distribution ERC20 coin amount for an address

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
  function transferOwnership(address payable admin) external onlyAdmin {
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
    require(block.timestamp < _SEP_15_2021_00_00_00, "Presale2 already started");
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
    _distributeThirdIndex = i;
  }

  // Receive BNB deposit
  receive() external payable {
    require(block.timestamp >= _SEP_15_2021_00_00_00 && block.timestamp <= _SEP_15_2021_18_00_00,
      'Deposit rejected, presale2 has either not yet started or not yet overed');
    require(!_shouldPresale2EndEarlier, 'Admin has ended presale2 earlier');
    require(_depositAddressesStatus[msg.sender], 'Deposit rejected, deposit address is not yet whitelisted');
    require(msg.value >= _minimumDepositBNBAmount, 'Deposit rejected, it is lesser than minimum amount');

    _depositAddressesBNBAmount[msg.sender] = _depositAddressesBNBAmount[msg.sender].add(msg.value);
    _totalAddressesDepositAmount = _totalAddressesDepositAmount.add(msg.value);

    emit Deposit(msg.sender, msg.value);
  }

  // Return leftOver BNB
  // number - number of addresses to process at once
  function returnBNB(uint number) external{
    require(block.timestamp > _SEP_15_2021_18_00_00 || _shouldPresale2EndEarlier , 'Presale2 has not yet overed');
    // use local variables to reduce gas usage
    uint totalAddressesDepositAmount = _totalAddressesDepositAmount;
    uint leftOverBNBBalance = totalAddressesDepositAmount.sub(_bnbAmountCap);
    uint i = _startDepositAddressIndex;
    uint last = i + number;
    if (last > _depositAddressesNumber) last = _depositAddressesNumber;
    require(i < last, "Already returned");
    for (; i < last; i++) {
      address depositor = _depositAddresses[i];
      uint deposited = _depositAddressesBNBAmount[depositor];      
      uint giveBackBNBAmount = deposited.mul(leftOverBNBBalance).div(totalAddressesDepositAmount);
      payable(depositor).transfer(giveBackBNBAmount);

      uint contributedAmount = deposited.mul(_bnbAmountCap).div(totalAddressesDepositAmount);
      _depositAddressesAwardedTotalErc20CoinAmount[depositor] = _depositAddressesAwardedTotalErc20CoinAmount[depositor].add(contributedAmount.mul(2400));
      _depositAddressesAwardedDistribution1Erc20CoinAmount[depositor] = _depositAddressesAwardedDistribution1Erc20CoinAmount[depositor].add(contributedAmount.mul(600));
      _depositAddressesAwardedDistribution2Erc20CoinAmount[depositor] = _depositAddressesAwardedDistribution2Erc20CoinAmount[depositor].add(contributedAmount.mul(600));
      _depositAddressesAwardedDistribution3Erc20CoinAmount[depositor] = _depositAddressesAwardedDistribution3Erc20CoinAmount[depositor].add(contributedAmount.mul(1200));
    }
    _startDepositAddressIndex = i;
  }

  // First distribution of ERC20 coin (Only 25% coin distributed)
  // number - number of addresses to process at once
  function distributeFirst(uint number) external {
    _distributeFirstIndex = _distribute(_Sep_16_2021_1800, 600, _distributeFirstIndex, number);
  }

  // Second distribution of ERC20 coin (Only 25% coin distributed)
  // number - number of addresses to process at once
  function distributeSecond(uint number) external {
    _distributeSecondIndex = _distribute(_Sep_30_2021, 600, _distributeSecondIndex, number);
  }

  // Third distribution of ERC20 coin (Only 50% coin distributed)
  // number - number of addresses to process at once
  function distributeThird(uint number) external {
    _distributeThirdIndex = _distribute(_Oct_16_2021, 1200, _distributeThirdIndex, number);
  }

  // Main distribution logic
  function _distribute(uint date, uint amount, uint i, uint number) private returns (uint){
    require(block.timestamp > date, 'Distribution fail, have not reached the distribution date');

    IErc20Contract erc20Contract = IErc20Contract(_erc20Contract);

    uint last = i + number;
    if (last > _depositAddressesNumber) last = _depositAddressesNumber;
    require(i < last, "Already distributed");
    // use local variables to reduce gas usage
    uint totalAddressesDepositAmount = _totalAddressesDepositAmount;
    uint bnbAmountCap = _bnbAmountCap;
    for (; i < last; i++) {
      address depositor = _depositAddresses[i];
      uint deposited = _depositAddressesBNBAmount[depositor];
      if (deposited != 0) {
        uint contributedAmount = deposited.mul(bnbAmountCap).div(totalAddressesDepositAmount);
        erc20Contract.transferPresale2(depositor, contributedAmount.mul(amount));
      }
    }
    return i;
  }

  // Allow admin to end Presale2 earlier
  function endPreSale2Earlier() external onlyAdmin {
      _shouldPresale2EndEarlier = true;
  }

  // Allow admin to withdraw all the deposited BNB
  function withdrawAll() external onlyAdmin {
    _admin.transfer(address(this).balance);
  }
}