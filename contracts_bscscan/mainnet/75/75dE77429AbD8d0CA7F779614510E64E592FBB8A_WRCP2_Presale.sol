/**
 *Submitted for verification at BscScan.com on 2021-12-01
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

contract WRCP2_Presale {
    using SafeMath for uint256;

    uint256 public  _minimumDepositBNBAmount = .14 ether; // Equivalent to .14 BNB minimum deposit
    uint256 public  _maximumDepositBNBAmount = 7 ether; // Equivalent to 7 BNB maximum deposit

    uint256 public constant _bnbAmountCap = 350 ether; // Allow cap at 350 BNB
    uint256 public _tokenValuePerBNB = 7143;

    bool public _isPresale1Ended; // Has admin decided t o end presale1? 

    address payable public _admin; // Admin address
    address public _erc20Contract =0x30786a60ED79e15829908C44EE269BE1C88207a4; // External erc20 contract

    uint256 public _totalAddressesDepositAmount; // Total addresses deposit amount

    uint256 public _depositAddressesNumber; // Number of deposit addresses
    mapping(uint256 => address) public _depositAddresses; // Deposit addresses
    mapping(address => bool) public _depositAddressesStatus; // Deposit addresses' whitelist status
    mapping(address => uint256) public _depositAddressesBNBAmount; // Address' deposit amount

    uint256 public _startDepositAddressIndex; // start ID of deposit addresses list
    mapping(address => uint256)
    public _depositAddressesAwardedTotalErc20CoinAmount; // Total awarded ERC20 coin amount for an address

    constructor() {
        _admin = msg.sender;
    }

    // Modifier
    modifier onlyAdmin() {
        require(_admin == msg.sender);
        _;
    }

    /**
     * Update minimum deposit
     */
    function setMinimumDeposit(uint256 amount) external onlyAdmin{
      _minimumDepositBNBAmount = amount;
    }
    /**
     * Update maximum deposit
     */
    function setMaximumDeposit(uint256 amount) external onlyAdmin{
      _maximumDepositBNBAmount = amount;
    }
    //Set Token Contract Address
    function setTokenAddress(address tokenAddress) external onlyAdmin {
        _erc20Contract = tokenAddress;
    }

    // Deposit event
    event Deposit(address indexed _from, uint256 _value);

    // Transfer owernship
    function transferOwnership(address payable admin) public onlyAdmin {
        require(admin != address(0), "Zero address");
        _admin = admin;
    }


    function Buy() external payable {

        // require(block.timestamp >= _presale1DateStarts && block.timestamp <= _presale1DateEnds, "Deposit rejected, presale1 has either not yet started or not yet overed");
        require(!_isPresale1Ended, 'Admin has ended presale earlier');
        require(_totalAddressesDepositAmount < _bnbAmountCap, "Deposit rejected, already reached the cap amount");
        require(msg.value >= _minimumDepositBNBAmount,"Deposit rejected, it is lesser than minimum amount");
        require(msg.value <= _maximumDepositBNBAmount,"Deposit rejected, it is more than maximum amount");
        require(_depositAddressesBNBAmount[msg.sender].add(msg.value) <= _maximumDepositBNBAmount, "Deposit rejected, every address cannot deposit more than 7 bnb");

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
    function endPresale1(bool stmt) external onlyAdmin {
        _isPresale1Ended = stmt;
    }
    // Allow admin to withdraw all the deposited BNB
    function withdrawAll() external onlyAdmin {
        _admin.transfer(address(this).balance);
    }
}