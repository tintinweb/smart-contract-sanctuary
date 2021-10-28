/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

// contracts/TokenVesting.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.5;


library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract GhospTokenVesting is Context, Ownable {
    using SafeMath for uint256;

    struct VestingAddress{
        uint256 amount;
        bool isSent;
    }

    address[] public members;
    uint256[] public vestingTimeList;
    string[] public vestingDateList;
    uint256 releasedVestingId;
    mapping(address => bool) public admins;
    uint256 public totalDepositedAmount;

    uint256 public initialTotalAmount = 75000000;

    mapping(uint256 => mapping(address => VestingAddress)) public vestingTimeScheduleList;

    uint256 mockTime = 0;

    IBEP20 immutable public _token;

    event Deposit(address token, address granter, uint amount);
    event AddAdmin(address _address);
    event UnlockTokens(string date);

    modifier onlyAdmin() {
        require(_msgSender() != address(0x0) && admins[_msgSender()], "Caller is not the admin");
        _;
    }

    constructor(address token_) {
        require(token_ != address(0x0));
        _token = IBEP20(token_);
        releasedVestingId = 0;

        initialData();
    }

    function initialData() private {
        members.push(address(0x0C25363022587299510774E036ad078682991256));
        members.push(address(0x026116102Ae7e558Cd436325158d54020EFCf0eF));
        members.push(address(0x4B674Da5E20067B8213263720d958B5e7AbD7d8c));
        members.push(address(0xD157D2Ff5393c509777765Cf612284d53d38dE30));
        members.push(address(0xFcf2668C4EC68D2bbd36a476e30227744A0f5EB8));
        members.push(address(0x3719D24Fa12f32877f894c6F51FeECF91F16b44f));
        members.push(address(0xc0eaA0018b1192dE0c8ca46E57B84Ee907e01baC));
        members.push(address(0xc50dD8028B1C6914B67F4657F0155e5D2cE1E226));
        members.push(address(0x5B588e36FF358D4376A76FB163fd69Da02A2A9a5));
        members.push(address(0xA5664dC01BB8369EDc6116d3B267d6014681dD2F));
        members.push(address(0xBDAae79a63F982Eb49DCFF180801313c5B9A9A4c));


        vestingTimeList.push(1635526800); // 2021-10-30
        vestingTimeList.push(1638205200); // 2021-11-30
        vestingTimeList.push(1640883600); // 2021-12-31
        vestingTimeList.push(1643562000); // 2022-01-31
        vestingTimeList.push(1645981200); // 2022-02-28
        vestingTimeList.push(1648659600); // 2022-03-31
        vestingTimeList.push(1651251600); // 2022-04-30
        vestingTimeList.push(1653930000); // 2022-05-31
        vestingTimeList.push(1656522000); // 2022-06-30
        vestingTimeList.push(1659200400); // 2022-07-31
        vestingTimeList.push(1661878800); // 2022-08-31
        vestingTimeList.push(1664470800); // 2022-09-30
        vestingTimeList.push(1667149200); // 2022-10-31
        vestingTimeList.push(1669741200); // 2022-11-30
        vestingTimeList.push(1672419600); // 2022-12-31
        vestingTimeList.push(1675098000); // 2023-01-31
        vestingTimeList.push(1677517200); // 2023-02-28
        vestingTimeList.push(1680195600); // 2023-03-31
        vestingTimeList.push(1682787600); // 2023-04-30
        vestingTimeList.push(1685466000); // 2023-05-31
        vestingTimeList.push(1688058000); // 2023-06-30
        vestingTimeList.push(1690736400); // 2023-07-31
        vestingTimeList.push(1693414800); // 2023-08-31
        vestingTimeList.push(1696006800); // 2023-09-30
        vestingTimeList.push(1698685200); // 2023-10-31
        vestingTimeList.push(1701277200); // 2023-11-30
        vestingTimeList.push(1703955600); // 2023-12-31


        vestingDateList.push("2021-10-30");
        vestingDateList.push("2021-11-30");
        vestingDateList.push("2021-12-31");
        vestingDateList.push("2022-01-31");
        vestingDateList.push("2022-02-28");
        vestingDateList.push("2022-03-31");
        vestingDateList.push("2022-04-30");
        vestingDateList.push("2022-05-31");
        vestingDateList.push("2022-06-30");
        vestingDateList.push("2022-07-31");
        vestingDateList.push("2022-08-31");
        vestingDateList.push("2022-09-30");
        vestingDateList.push("2022-10-31");
        vestingDateList.push("2022-11-30");
        vestingDateList.push("2022-12-31");
        vestingDateList.push("2023-01-31");
        vestingDateList.push("2023-02-28");
        vestingDateList.push("2023-03-31");
        vestingDateList.push("2023-04-30");
        vestingDateList.push("2023-05-31");
        vestingDateList.push("2023-06-30");
        vestingDateList.push("2023-07-31");
        vestingDateList.push("2023-08-31");
        vestingDateList.push("2023-09-30");
        vestingDateList.push("2023-10-31");
        vestingDateList.push("2023-11-30");
        vestingDateList.push("2023-12-31");

        // private wallets

        // for 2021-10-30
        vestingTimeScheduleList[vestingTimeList[0]][members[0]] = addVestingSchedule(75000 ether);
        vestingTimeScheduleList[vestingTimeList[0]][members[1]] = addVestingSchedule(87000 ether);
        vestingTimeScheduleList[vestingTimeList[0]][members[2]] = addVestingSchedule(75000 ether);
        vestingTimeScheduleList[vestingTimeList[0]][members[3]] = addVestingSchedule(12500 ether);
        vestingTimeScheduleList[vestingTimeList[0]][members[4]] = addVestingSchedule(3125 ether);
        vestingTimeScheduleList[vestingTimeList[0]][members[5]] = addVestingSchedule(3125 ether);
        vestingTimeScheduleList[vestingTimeList[0]][members[6]] = addVestingSchedule(37500 ether);
        vestingTimeScheduleList[vestingTimeList[0]][members[7]] = addVestingSchedule(425 ether);
        vestingTimeScheduleList[vestingTimeList[0]][members[8]] = addVestingSchedule(75 ether);

        // for other months by 2022-04
        for (uint256 j = 1; j < 7; j++) {
            vestingTimeScheduleList[vestingTimeList[j]][members[0]] = addVestingSchedule(237500 ether);
            vestingTimeScheduleList[vestingTimeList[j]][members[1]] = addVestingSchedule(275500 ether);
            vestingTimeScheduleList[vestingTimeList[j]][members[2]] = addVestingSchedule(98958.33 ether);
            vestingTimeScheduleList[vestingTimeList[j]][members[3]] = addVestingSchedule(39583.33 ether);
            vestingTimeScheduleList[vestingTimeList[j]][members[4]] = addVestingSchedule(9895.83 ether);
            vestingTimeScheduleList[vestingTimeList[j]][members[5]] = addVestingSchedule(9895.83 ether);
            vestingTimeScheduleList[vestingTimeList[j]][members[6]] = addVestingSchedule(118750 ether);
            vestingTimeScheduleList[vestingTimeList[j]][members[7]] = addVestingSchedule(1345.83 ether);
            vestingTimeScheduleList[vestingTimeList[j]][members[8]] = addVestingSchedule(237.5 ether);
        }

        // smart contract address

        // 2021-10-30
        vestingTimeScheduleList[vestingTimeList[0]][members[9]] = addVestingSchedule(2650000 ether);
        vestingTimeScheduleList[vestingTimeList[0]][members[10]] = addVestingSchedule(1600000 ether);

        // 2021-11-30 and 2021-12-31
        for (uint256 j = 1; j < 3; j++) {
            vestingTimeScheduleList[vestingTimeList[j]][members[9]] = addVestingSchedule(3622916.67 ether);
            vestingTimeScheduleList[vestingTimeList[j]][members[10]] = addVestingSchedule(2241666.67 ether);
        }

        // 2022-01-31 ~ 2022-04-31
        for (uint256 j = 3; j < 7; j++) {
            vestingTimeScheduleList[vestingTimeList[j]][members[9]] = addVestingSchedule(2872916.67 ether);
            vestingTimeScheduleList[vestingTimeList[j]][members[10]] = addVestingSchedule(1741666.67 ether);
        }

        // 2022-05-30 ~ 2022-10-31
        for (uint256 j = 7; j < 13; j++) {
            vestingTimeScheduleList[vestingTimeList[j]][members[9]] = addVestingSchedule(2081250 ether);
            vestingTimeScheduleList[vestingTimeList[j]][members[10]] = addVestingSchedule(158333.33 ether);
        }

        // 2022-11-30 ~ 2023-10-31, for Treasury
        for (uint256 j = 13; j < 25; j++) {
            vestingTimeScheduleList[vestingTimeList[j]][members[9]] = addVestingSchedule(1843750 ether);
        }
    }

//    function addVestingTimeSchedule(uint256 startTime, address memory member, uint256 amount) external {
//
//    }

    function addVestingSchedule(uint256 amount) private pure returns (VestingAddress memory) {
        VestingAddress memory vestingAddress = VestingAddress(amount, false);
        return vestingAddress;
    }


    function getContractBalance() public view returns (uint256) {
		return _token.balanceOf(address(this));
	}

    function getToken() external view returns(address){
        return address(_token);
    }

    function addAdmin(address _address) external onlyOwner {
        require(_address != address(0x0), "Zero address");
        require(!admins[_address], "This address is already added as an admin");
        admins[_address] = true;
        emit AddAdmin(_address);
    }

    function unlockToken() external onlyAdmin {

        uint256 currentTime = getCurrentTime();
        uint256 startTime = vestingTimeList[releasedVestingId];
        require(currentTime >= startTime, "You can't run unlockToken function now");
        if (releasedVestingId == 0) {
            require(_token.balanceOf(address(this)) >= initialTotalAmount, "You need to deposit 75000000 GHSPs into this contract before you start this contract.");
        }
        for (uint256 i = 0; i < members.length; i++) {
            VestingAddress memory vestingAddress = vestingTimeScheduleList[startTime][members[i]];
            if (!vestingAddress.isSent) {
                require(_token.transfer(members[i], vestingTimeScheduleList[startTime][members[i]].amount));
            }
        }
        emit UnlockTokens(vestingDateList[releasedVestingId]);
        releasedVestingId = releasedVestingId + 1;
    }

    function withdraw() external onlyOwner {
        _token.transfer(_msgSender(), _token.balanceOf(address(this)));
    }

    function getBalance(address _address) external view returns(uint256) {
        require(_address != address(0x0));
        return _token.balanceOf(_address);
    }

//    function getCurrentTime() internal virtual view returns(uint256){
//        return block.timestamp;
//    }

    function setCurrentTime(uint256 _time)
        external{
        mockTime = _time;
    }

    function getCurrentTime() internal virtual view returns(uint256){
        return mockTime;
    }

    function getLastUnlockDate() public view returns(string memory) {
        if (releasedVestingId == 0) {
            return "Don't start unlock";
        }
        return vestingDateList[releasedVestingId - 1];
    }

    function getReleasedVestingId() public view returns(uint256) {
        return releasedVestingId;
    }
}