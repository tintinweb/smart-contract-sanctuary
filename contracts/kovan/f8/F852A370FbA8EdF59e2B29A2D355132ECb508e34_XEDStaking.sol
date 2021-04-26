// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./includes/Ownable.sol";

contract Whitelist is Ownable {
    mapping (address => bool) userAddr;

    event insertAddress(address user);
    function whitelistAddress (address user) public onlyOwner {
        userAddr[user] = true;
        emit insertAddress(user);
    }

    function whitelistAddressBatch (address[] memory users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            userAddr[users[i]] = true;
            emit insertAddress(users[i]);
        }
    }

    event removeAddress(address user);
    function removeWhitelistAddress (address user) public onlyOwner {
        userAddr[user] = false;
        emit removeAddress(user);
    }

    function removeWhitelistAddressBatch (address[] memory users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            userAddr[users[i]] = false;
            emit removeAddress(users[i]);
        }
    }

    function isWhitelisted (address _user) public view returns (bool) {
        return userAddr[_user];
    }

    modifier inWhitelist(address _user) {
        require(userAddr[_user] == true, "User isn't authorized to perform this operation.");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./includes/IERC20.sol";
import "./includes/Ownable.sol";
import "./includes/SafeMath.sol";
import "./Whitelist.sol";

contract XEDStaking is Whitelist {
    using SafeMath for uint256;
    using SafeMath for uint64;

    bool public active;
    uint256 public startTime;
    uint256 public cutoffTime;
    IERC20 internal immutable exeedme;

    enum poolNames {BRONZE, SILVER, GOLD}

    struct pool {
        uint256 maturityAPY;
        uint64 daysToMaturity;
        uint64 earlyWithdrawalAPY;
        uint64 daysToEarlyWithdrawal;
        uint256 maxPoolCapacity;
        uint256 rewardSupply;
        uint256 stakingFunds;
        uint256 userFunds;
        uint256 totalDeposited;
    }

    mapping(poolNames => pool) public pools;

    struct userDeposit {
        poolNames pool;
        uint256 amount;
        uint256 depositTime;
    }
    mapping(address => userDeposit[]) public userDeposits;

    uint256 public constant totalRewardSupply = (37808219 * 1 ether) / 100;
    uint256 public constant minStakingAmount = 2000 * 1 ether;

    constructor(IERC20 XedContract) public {
        //NFTProtocol = IERC20(0xB5a9f4270157BeDe68070df7A070525644fc782D); // Kovan
        //NFTProtocol = IERC20(0xcB8d1260F9c92A3A545d409466280fFdD7AF7042); // Mainnet
        exeedme = XedContract;

        pools[poolNames.BRONZE] = pool({
            maturityAPY: 20,
            daysToMaturity: 60,
            earlyWithdrawalAPY: 8,
            daysToEarlyWithdrawal: 30,
            maxPoolCapacity: 500000 * 1 ether,
            rewardSupply: (1643836 * 1 ether) / 100,
            stakingFunds: 0,
            userFunds: 0,
            totalDeposited: 0
        });

        pools[poolNames.SILVER] = pool({
            maturityAPY: 35,
            daysToMaturity: 120,
            earlyWithdrawalAPY: 14,
            daysToEarlyWithdrawal: 60,
            maxPoolCapacity: 1000000 * 1 ether,
            rewardSupply: (11506849 * 1 ether) / 100,
            stakingFunds: 0,
            userFunds: 0,
            totalDeposited: 0
        });

        pools[poolNames.GOLD] = pool({
            maturityAPY: 50,
            daysToMaturity: 180,
            earlyWithdrawalAPY: 20,
            daysToEarlyWithdrawal: 100,
            maxPoolCapacity: 1000000 * 1 ether,
            rewardSupply: (24657534 * 1 ether) / 100,
            stakingFunds: 0,
            userFunds: 0,
            totalDeposited: 0
        });
    }

    function deposit(uint256 depositAmount, poolNames _pool)
        external
        inWhitelist(msg.sender)
    {
        require(active == true, "staking has not begun yet");
        require(
            exeedme.balanceOf(msg.sender) >= depositAmount,
            "not enough NFT tokens"
        );
        require(
            exeedme.allowance(msg.sender, address(this)) >= depositAmount,
            "Check the XED allowance"
        );
        require(depositAmount >= minStakingAmount, "depositAmount too low");
        require(
            pools[_pool].totalDeposited < pools[_pool].maxPoolCapacity,
            "contract staking capacity exceeded"
        );
        require(
            block.timestamp < cutoffTime,
            "contract staking deposit time period over"
        );
        pools[_pool].totalDeposited = pools[_pool].totalDeposited.add(
            depositAmount
        );
        pools[_pool].userFunds = pools[_pool].userFunds.add(depositAmount);
        userDeposits[msg.sender].push(
            userDeposit({
                pool: _pool,
                amount: depositAmount,
                depositTime: block.timestamp
            })
        );
        exeedme.transferFrom(msg.sender, address(this), depositAmount);
    }

    event Withdraw(
        poolNames pool,
        address userAddress,
        uint256 principal,
        uint256 yield,
        uint256 userFundsRemaining,
        uint256 stakingFundsRemaining
    );

    function withdraw(poolNames _pool) 
        public 
        inWhitelist(msg.sender) 
    {
        require(active == true, "staking has not begun yet");
        uint256 withdrawalAmount = getUserDepositTotal(msg.sender, _pool);
        require(withdrawalAmount > 0, "nothing to withdraw");

        uint256 userYield = getUserYield(msg.sender, _pool);
        pools[_pool].userFunds = pools[_pool].userFunds.sub(withdrawalAmount);
        pools[_pool].stakingFunds = pools[_pool].stakingFunds.sub(userYield);
        for (uint256 i = 0; i < userDeposits[msg.sender].length; i++) {
            delete userDeposits[msg.sender][i];
        }
        uint256 totalToTransfer = withdrawalAmount.add(userYield);
        exeedme.transfer(msg.sender, totalToTransfer);
        emit Withdraw(
            _pool,
            msg.sender,
            withdrawalAmount,
            userYield,
            pools[_pool].userFunds,
            pools[_pool].stakingFunds
        );
    }

    event StakingBegins(uint256 timestamp, uint256 stakingFunds);

    function beginStaking() 
        external 
        onlyOwner 
    {
        require(
            exeedme.balanceOf(address(this)) == totalRewardSupply,
            "not enough staking rewards"
        );
        active = true;
        startTime = block.timestamp;
        cutoffTime = startTime.add(10 days);
        pools[poolNames.BRONZE].stakingFunds = pools[poolNames.BRONZE]
            .rewardSupply;
        pools[poolNames.SILVER].stakingFunds = pools[poolNames.SILVER]
            .rewardSupply;
        pools[poolNames.GOLD].stakingFunds = pools[poolNames.GOLD].rewardSupply;
        emit StakingBegins(startTime, totalRewardSupply);
    }

    function getYieldMultiplier(uint256 daysStaked, poolNames _pool)
        public
        view
        returns (uint256)
    {
        if (daysStaked >= pools[_pool].daysToMaturity)
            return pools[_pool].maturityAPY;
        if (daysStaked >= pools[_pool].daysToEarlyWithdrawal)
            return pools[_pool].earlyWithdrawalAPY;
        return 0;
    }

    function getUserDepositTotal(address userAddress, poolNames _pool)
        public
        view
        returns (uint256)
    {
        uint256 totalDeposit;
        for (uint256 i = 0; i < userDeposits[userAddress].length; i++) {
            if (userDeposits[userAddress][i].pool == _pool) {
                totalDeposit = totalDeposit.add(
                    userDeposits[userAddress][i].amount
                );
            }
        }
        return totalDeposit;
    }

    function getUserYield(address userAddress, poolNames _pool)
        public
        view
        returns (uint256)
    {
        uint256 totalYield;
        for (uint256 i = 0; i < userDeposits[userAddress].length; i++) {
            if (userDeposits[userAddress][i].pool == _pool) {
                uint256 daysStaked =
                    (block.timestamp -
                        userDeposits[userAddress][i].depositTime) / 1 days;
                uint256 yieldMultiplier = getYieldMultiplier(daysStaked, _pool);
                uint64 daysMultiplier = getNDays(daysStaked, _pool);
                totalYield = totalYield.add(
                    (userDeposits[userAddress][i].amount *
                        1 ether *
                        yieldMultiplier * daysMultiplier) / (1 ether * 100 * 365)
                );
            }
        }
        return totalYield;
    }

    function getNDays(uint256 daysStaked, poolNames _pool) 
        public 
        view 
        returns (uint64) 
    {
        if (daysStaked >= pools[_pool].daysToMaturity)
            return pools[_pool].daysToMaturity;
        if (daysStaked >= pools[_pool].daysToEarlyWithdrawal)
            return pools[_pool].daysToEarlyWithdrawal;
        return 0;
    }

    function getUserDeposits(address userAddress)
        external
        view
        returns (userDeposit[] memory)
    {
        return userDeposits[userAddress];
    }

    function getUserFunds(poolNames _pool) 
        external 
        view 
        returns (uint256) 
    {
        return pools[_pool].userFunds;
    }

    function getStakingFunds(poolNames _pool) 
        external 
        view 
        returns (uint256) 
    {
        return pools[_pool].stakingFunds;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}