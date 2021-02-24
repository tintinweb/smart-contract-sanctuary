/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

pragma solidity 0.8.1;

// SPDX-License-Identifier: MIT

 interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
  }

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
 }

contract Owned is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
 }

contract Staking_Pool_1 is Owned {
  using SafeMath for uint256;

  constructor() {
    synPerTKNPerYear = 2000 *10**18;
    startTime = block.timestamp;
    endTime =  block.timestamp.add(365 days);
    totalSynRewards = 2 * 10**6 * 10**18;
  }

  IERC20 public TENFI = IERC20(0x95b63Ff88960D1B3B23625B20391Cd7372B0aeBC);
  IERC20 public LPTKN = IERC20(0x5743F129a4897488dbEebABdb3aAE70ba8D4E908);
  
  // 20% reward for dev
  uint256 public percentForDev = 20;
  
  // dev address
  address public devaddress = 0xaA442F2FB678425571E78693bc2e6e9d328f69c3;
  
  uint256 public synPerTKNPerYear;
  uint256 public startTime;
  uint256 public endTime;

  uint256 public totalSynRewards;
  uint256 public totalStaked;
  uint256 public totalTime;
  uint256 public totalStaking;
  uint256 public forDev;

  mapping(address => uint256) public balances;
  mapping(address => uint256) public timeEntered;

  function stake(uint256 amount) public {
    require(amount > 0);
    uint256 time = timeEntered[msg.sender];
    claimDivs();
    if(block.timestamp < endTime && block.timestamp >= startTime) {
      require(LPTKN.transferFrom(msg.sender, address(this), amount));
      if(time == timeEntered[msg.sender]) timeEntered[msg.sender] = block.timestamp;
      totalStaking = totalStaking.add(amount);
      balances[msg.sender] = balances[msg.sender].add(amount);
    }
  }
  function withdraw() public {
    require(balances[msg.sender] > 0);
    claimDivs();
    uint256 amount = balances[msg.sender];
    totalStaking = totalStaking.sub(amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    LPTKN.transfer(msg.sender, amount);
  }
  function claimDivs() public {
    updateTotals();
    if(timeEntered[msg.sender] != 0) {
      uint256 syndue = getPendingDivs(balances[msg.sender], timeEntered[msg.sender]);
      if(syndue > 0) {
          forDev = syndue.mul(percentForDev).div(100);
        timeEntered[msg.sender] = block.timestamp > endTime ? endTime : block.timestamp;
        TENFI.transfer(msg.sender, syndue);
        TENFI.transfer(address(devaddress), forDev);
      }
    }
  }
  function updateTotals() public {
    uint256 time = block.timestamp > endTime ? endTime : block.timestamp;
    uint256 timediff = time.sub(totalTime);
    uint256 reward = totalStaking.mul(timediff).mul(synPerTKNPerYear).div(365 days).div(10**18);
    if(reward > 0) totalStaked = totalStaked.add(reward);
    if(totalTime != time) totalTime = time;
    if(totalStaked >= totalSynRewards && block.timestamp == time)
      endTime = block.timestamp;
  }
  //GET BACK LP TOKENS WITHOUT CLAIMING TENFI REWARDS
  function emergencyRemove(uint256 amount) public {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    totalStaking = totalStaking.sub(amount);
    LPTKN.transfer(msg.sender, amount);
  }

  //VIEW
  function getPendingDivs(uint256 amount, uint256 time) public view returns(uint256) {
    uint256 timediff = block.timestamp > endTime ? endTime.sub(time) : block.timestamp.sub(time);
    uint256 reward = amount.mul(timediff).mul(synPerTKNPerYear).div(365 days).div(10**18);
    return(reward);
  }

  //ADMIN
  function setStartTime(uint256 time) public onlyOwner() {
    startTime = time;
  }
  
  function setEndTime(uint256 time) public onlyOwner() {
    endTime = time;
  }
  
  function setSynPerTKNPerYear(uint256 amount) public onlyOwner() {
    synPerTKNPerYear = amount;
  }
  
  function setPercentForDev(uint256 _percentForDev) public onlyOwner() {
    percentForDev = _percentForDev;
  }
  
  function setDevaddress(address _devaddress) public onlyOwner() {
    devaddress = _devaddress;
  }
  
  function setTotalSynRewards(uint256 amount) public onlyOwner() {
    totalSynRewards = amount;
  }
  
  function setLPTKN(IERC20 token) public onlyOwner() {
    LPTKN = token;
  }
  
  function setTENFI(IERC20 token) public onlyOwner() {
    TENFI = token;
  }
  
  function tokenremove(IERC20 token, uint256 amount) public onlyOwner() {
    require(token != LPTKN);
    token.transfer(msg.sender, amount);
  }
  
}