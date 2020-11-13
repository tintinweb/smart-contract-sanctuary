pragma solidity 0.5.16;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface ILidCertifiableToken {
    function activateTransfers() external;
    function activateTax() external;
    function mint(address account, uint256 amount) external returns (bool);
    function addMinter(address account) external;
    function renounceMinter() external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function isMinter(address account) external view returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}


library BasisPoints {
    using SafeMath for uint;

    uint constant private BASIS_POINTS = 10000;

    function mulBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint amt, uint bp) internal pure returns (uint) {
        require(bp > 0, "Cannot divide by zero.");
        if (amt == 0) return 0;
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}


contract LidTeamLock is Initializable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint public releaseInterval;
    uint public releaseStart;
    uint public releaseBP;

    uint public startingLid;
    uint public startingEth;

    address payable[] public teamMemberAddresses;
    uint[] public teamMemberBPs;
    mapping(address => uint) public teamMemberClaimedEth;
    mapping(address => uint) public teamMemberClaimedLid;

    ILidCertifiableToken private lidToken;

    modifier onlyAfterStart {
        require(releaseStart != 0 && now > releaseStart, "Has not yet started.");
        _;
    }

    function() external payable { }

    function initialize(
        uint _releaseInterval,
        uint _releaseBP,
        address payable[] calldata _teamMemberAddresses,
        uint[] calldata _teamMemberBPs,
        ILidCertifiableToken _lidToken
    ) external initializer {
        require(_teamMemberAddresses.length == _teamMemberBPs.length, "Must have one BP for every address.");

        releaseInterval = _releaseInterval;
        releaseBP = _releaseBP;
        lidToken = _lidToken;

        for (uint i = 0; i < _teamMemberAddresses.length; i++) {
            teamMemberAddresses.push(_teamMemberAddresses[i]);
        }

        uint totalTeamBP = 0;
        for (uint i = 0; i < _teamMemberBPs.length; i++) {
            teamMemberBPs.push(_teamMemberBPs[i]);
            totalTeamBP = totalTeamBP.add(_teamMemberBPs[i]);
        }
        require(totalTeamBP == 10000, "Must allocate exactly 100% (10000 BP) to team.");
    }

    function claimLid(uint id) external onlyAfterStart {
        require(checkIfTeamMember(msg.sender), "Can only be called by team members.");
        require(msg.sender == teamMemberAddresses[id], "Sender must be team member ID");
        uint bp = teamMemberBPs[id];
        uint cycle = getCurrentCycleCount();
        uint totalClaimAmount = cycle.mul(startingLid.mulBP(bp).mulBP(releaseBP));
        uint toClaim = totalClaimAmount.sub(teamMemberClaimedLid[msg.sender]);
        if (lidToken.balanceOf(address(this)) < toClaim) toClaim = lidToken.balanceOf(address(this));
        teamMemberClaimedLid[msg.sender] = teamMemberClaimedLid[msg.sender].add(toClaim);
        lidToken.transfer(msg.sender, toClaim);
    }

    function claimEth(uint id) external {
        require(checkIfTeamMember(msg.sender), "Can only be called by team members.");
        require(msg.sender == teamMemberAddresses[id], "Sender must be team member ID");
        uint bp = teamMemberBPs[id];
        uint totalClaimAmount = startingEth.mulBP(bp);
        uint toClaim = totalClaimAmount.sub(teamMemberClaimedEth[msg.sender]);
        if (address(this).balance < toClaim) toClaim = address(this).balance;
        teamMemberClaimedEth[msg.sender] = teamMemberClaimedEth[msg.sender].add(toClaim);
        msg.sender.transfer(toClaim);
    }

    function startRelease() external {
        require(releaseStart == 0, "Has already started.");
        require(address(this).balance != 0, "Must have some ether deposited.");
        require(lidToken.balanceOf(address(this)) != 0, "Must have some lid deposited.");
        startingLid = lidToken.balanceOf(address(this));
        startingEth = address(this).balance;
        releaseStart = now.add(24 hours);
    }

    function migrateMember(uint i, address payable newAddress) external {
        require(msg.sender == teamMemberAddresses[0], "Must be project lead.");
        address oldAddress = teamMemberAddresses[i];
        teamMemberClaimedLid[newAddress] = teamMemberClaimedLid[oldAddress];
        delete teamMemberClaimedLid[oldAddress];
        teamMemberAddresses[i] = newAddress;
    }

    function resetTeam(
        address payable[] calldata _teamMemberAddresses,
        uint[] calldata _teamMemberBPs
    ) external {
        require(msg.sender == teamMemberAddresses[0], "Must be project lead.");
        delete teamMemberAddresses;
        delete teamMemberBPs;
        for (uint i = 0; i < _teamMemberAddresses.length; i++) {
            teamMemberAddresses.push(_teamMemberAddresses[i]);
        }

        uint totalTeamBP = 0;
        for (uint i = 0; i < _teamMemberBPs.length; i++) {
            teamMemberBPs.push(_teamMemberBPs[i]);
            totalTeamBP = totalTeamBP.add(_teamMemberBPs[i]);
        }
    }

    function getCurrentCycleCount() public view returns (uint) {
        if (now <= releaseStart) return 0;
        return now.sub(releaseStart).div(releaseInterval).add(1);
    }

    function checkIfTeamMember(address member) internal view returns (bool) {
        for (uint i; i < teamMemberAddresses.length; i++) {
            if (teamMemberAddresses[i] == member)
                return true;
        }
        return false;
    }

}