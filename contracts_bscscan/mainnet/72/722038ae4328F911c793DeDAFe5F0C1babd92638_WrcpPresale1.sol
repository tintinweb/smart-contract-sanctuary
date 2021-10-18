/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

interface IErc20Contract {
    function transferPresale1(address recipient, uint256 amount)
        external
        returns (bool);
}

contract WrcpPresale1 {
    using SafeMath for uint256;

    uint256 public constant _minimumDepositBNBAmount = .14 ether; // Equivalent to .14 BNB minimum deposit
    uint256 public constant _maximumDepositBNBAmount = 14 ether; // Equivalent to 14 BNB maximum deposit

    uint256 public constant _bnbAmountCap = 4200 ether; // Allow cap at 4200 BNB
    uint256 public _presale1DateStarts = 1637020800;
    uint256 public _presale1DateEnds = 1637798400;
    uint256 public _tokenValuePerBNB = 7143;

    bool public _isPresale1Ended; // Has admin decided to end presale1? 

    address payable public _admin; // Admin address
    address public _erc20Contract; // External erc20 contract

    uint256 public _totalAddressesDepositAmount; // Total addresses deposit amount

    uint256 public _depositAddressesNumber; // Number of deposit addresses
    mapping(uint256 => address) public _depositAddresses; // Deposit addresses
    mapping(address => bool) public _depositAddressesStatus; // Deposit addresses' whitelist status
    mapping(address => uint256) public _depositAddressesBNBAmount; // Address' deposit amount

    uint256 public _startDepositAddressIndex; // start ID of deposit addresses list
    mapping(address => uint256)
        public _depositAddressesAwardedTotalErc20CoinAmount; // Total awarded ERC20 coin amount for an address

    constructor(address erc20Contract) {
        _admin = msg.sender;
        _erc20Contract = erc20Contract;
    }

    // Modifier
    modifier onlyAdmin() {
        require(_admin == msg.sender);
        _;
    }

    // Deposit event
    event Deposit(address indexed _from, uint256 _value);

    // Transfer owernship
    function transferOwnership(address payable admin) public onlyAdmin {
        require(admin != address(0), "Zero address");
        _admin = admin;
    }

    //Adjust presale1 date starts
    function setPresale1DateStarts(uint256 _newDate) external onlyAdmin {
        _presale1DateStarts = _newDate;
    }
    //Adjust presale1 date ends
    function setPresale1DateEnds(uint256 _newDate) external onlyAdmin {
        _presale1DateEnds = _newDate;
    }

    // Add deposit addresses and whitelist them
    function addDepositAddress(address[] calldata depositAddresses)
        external
        onlyAdmin
    {
        uint256 depositAddressesNumber = _depositAddressesNumber;
        for (uint256 i = 0; i < depositAddresses.length; i++) {
            if (!_depositAddressesStatus[depositAddresses[i]]) {
                _depositAddresses[depositAddressesNumber] = depositAddresses[i];
                _depositAddressesStatus[depositAddresses[i]] = true;
                depositAddressesNumber++;
            }
        }
        _depositAddressesNumber = depositAddressesNumber;
    }

    // Remove deposit addresses and unwhitelist them
    function removeAllDepositAddress(uint256 number) external onlyAdmin {

        require(block.timestamp < _presale1DateStarts,"Presale1 already started");

        uint256 i = _startDepositAddressIndex;
        uint256 last = i + number;
        if (last > _depositAddressesNumber) last = _depositAddressesNumber;
        for (; i < last; i++) {
            _depositAddressesStatus[_depositAddresses[i]] = false;
            _depositAddresses[i] = address(0);
        }
        _startDepositAddressIndex = i;
    }

    function Buy() external payable {

        require(block.timestamp >= _presale1DateStarts && block.timestamp <= _presale1DateEnds, "Deposit rejected, presale1 has either not yet started or not yet overed");
        require(!_isPresale1Ended, 'Admin has ended presale1 earlier');
        require(_totalAddressesDepositAmount < _bnbAmountCap, "Deposit rejected, already reached the cap amount");
        require(_depositAddressesStatus[msg.sender],"Deposit rejected, deposit address is not yet whitelisted");
        require(msg.value >= _minimumDepositBNBAmount,"Deposit rejected, it is lesser than minimum amount");
        require(msg.value <= _maximumDepositBNBAmount,"Deposit rejected, it is more than maximum amount");
        require(_depositAddressesBNBAmount[msg.sender].add(msg.value) <= _maximumDepositBNBAmount, "Deposit rejected, every address cannot deposit more than 14 bnb");

        if (_totalAddressesDepositAmount.add(msg.value) > _bnbAmountCap) {
            // If total deposit + deposit greater than bnb cap amount
            uint256 value = _bnbAmountCap.sub(_totalAddressesDepositAmount);
            _depositAddressesBNBAmount[msg.sender] = _depositAddressesBNBAmount[msg.sender].add(value);
            _totalAddressesDepositAmount = _totalAddressesDepositAmount.add(value);

            msg.sender.transfer(msg.value.sub(value)); // Transfer back extra BNB

            uint256 value2 = msg.value;
            emit Deposit(msg.sender, msg.value);

            IErc20Contract erc20Contract = IErc20Contract(_erc20Contract);

            erc20Contract.transferPresale1(msg.sender, value2.mul(_tokenValuePerBNB));

        } else {

            _depositAddressesBNBAmount[msg.sender] = _depositAddressesBNBAmount[msg.sender].add(msg.value);
            _totalAddressesDepositAmount = _totalAddressesDepositAmount.add(msg.value);

            uint256 value = msg.value;
            emit Deposit(msg.sender, msg.value);

            IErc20Contract erc20Contract = IErc20Contract(_erc20Contract);

            erc20Contract.transferPresale1(msg.sender,value.mul(_tokenValuePerBNB));
        }
    }

    // Allow admin to end Presale1 earlier
    function endPresale1() external onlyAdmin {
        _isPresale1Ended = true;
    }
    // Allow admin to withdraw all the deposited BNB
    function withdrawAll() external onlyAdmin {
        _admin.transfer(address(this).balance);
    }
}