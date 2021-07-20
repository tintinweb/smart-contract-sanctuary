/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface BEP20Interface {

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    return add(a, b, "SafeMath: addition overflow");
  }


  function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);

    return c;
  }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }


  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }


  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }


  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }


  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }


  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = msg.sender;
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Presale is Ownable {
    using SafeMath for uint256;

    uint256 public presaleCost;
    uint256 public depositMaxAmount;

    BEP20Interface public dexf;
    BEP20Interface public usdc;

    mapping(address => bool) public whiteList;
    uint256 public whiteListLength;
    address public reservior;

    mapping(address => uint256) depositedAmount;
    mapping(address => uint256) paidOut;

    uint256 public totalDepositedAmount; // total deposited USDC amount
    uint256 public totalPaidOut; // total paid out DEXF amount
    uint256 public participants;

    event Deposited(address indexed account, uint256 depositedAmount, uint256 paidOut);

    constructor() {
        dexf = BEP20Interface(0xD44341F788FF3cc4779c40Db353A873BCB7faD4a);
        usdc = BEP20Interface(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        reservior = address(0xb357929b957E3B36204Cc2D02DD52e59Ab762177);

        presaleCost = 100000000000000000000;
        depositMaxAmount = 40000000000000000000;
    }

    // View functions

    function getDepositedAmount(address user) public view returns(uint256) {
      return depositedAmount[user];
    }

    function getPaidOut(address user) public view returns(uint256) {
      return paidOut[user];
    }

    function getExpectedPayOut(uint256 usdcAmount) public view returns(uint256) {
      return presaleCost.mul(usdcAmount).div(10 ** 18);
    }

    function checkWhiteListByAddress(address _one) public view returns(bool) {
        return whiteList[_one];
    }

    // write functions

    function setPresaleCost(uint256 cost) external onlyOwner {
      presaleCost = cost;
    }

    function setDexfToken(address _dexf) external onlyOwner {
      dexf = BEP20Interface(_dexf);
    }

    function setReservior(address _reservior) external onlyOwner {
      reservior = _reservior;
    }

    function setBuyToken(address token) external onlyOwner {
      usdc = BEP20Interface(token);
    }

    function setDepositMaxAmount(uint256 amount) external onlyOwner {
      depositMaxAmount = amount;
    }

    function setWhiteList(address[] memory _whiteList) external onlyOwner {
        uint256 length = _whiteList.length;

        for (uint256 i = 0; i < length; i++) {
            if (!whiteList[_whiteList[i]]) {
              whiteList[_whiteList[i]] = true;
              whiteListLength++;
            }
        }
    }

    function addOneToWhiteList(address _one) public onlyOwner {
        require(_one != address(0), "Invalid address to add");
        require(!whiteList[_one], "Already added");

        whiteList[_one] = true;
        whiteListLength++;
    }

    function removeOneFromWhiteList(address _one) external onlyOwner {
        require(_one != address(0), "Invalid address to remove");
        require(whiteList[_one], "Not exists");

        whiteList[_one] = false;
        whiteListLength--;
    }

    function deposit(uint256 amount) external {
        require(!_isContract(msg.sender), "Sender could not be a contract");
        require(whiteList[msg.sender], "Address not allowed");
        require(depositedAmount[msg.sender].add(amount) <= depositMaxAmount, "Invalid amount to deposit");

        usdc.transferFrom(msg.sender, address(this), amount);
        totalDepositedAmount = totalDepositedAmount.add(amount);

        if (depositedAmount[msg.sender] == 0)
          participants++;

        depositedAmount[msg.sender] = depositedAmount[msg.sender].add(amount);

        uint256 payOut = getExpectedPayOut(amount);
        dexf.transferFrom(reservior, address(this), payOut);
        totalPaidOut = totalPaidOut.add(payOut);
        paidOut[msg.sender] = paidOut[msg.sender].add(payOut);

        // send usdc to reservior
        usdc.transfer(reservior, amount);

        // send dexf to users
        dexf.transfer(msg.sender, payOut);

        emit Deposited(msg.sender, amount, payOut);
    }

    // check if address is contract
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}