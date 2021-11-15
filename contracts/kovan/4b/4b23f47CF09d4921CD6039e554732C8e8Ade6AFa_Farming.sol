// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./FarmingFromNFT.sol";

contract Farming is FarmingFromNFT {
    using SafeMath for uint256;

    // Total amount of collateral in the platform
    uint256 totalETHCollateral;

    struct CollateralProvider {
        uint256 ethCollateralProvided; // ETH provided in collateral
        uint256 rewardDebtFromETH;
    }

    mapping(address => CollateralProvider) public collateralProvider;

    // Allow Owner to start rewards pools
    function startPOOLS() external onlyOwner {
        require(
            NFT_POOL_lastRewardBlock == 0 &&
                COLLATERAL_POOL_lastRewardBlock == 0,
            "Mining already started"
        );
        NFT_POOL_MULTIPLIER_UPDATED = block.number;
        NFT_POOL_lastRewardBlock = block.number;
        COLLATERAL_POOL_lastRewardBlock = block.number;
        //Define the end period of creating vesting Instance
        // 6 weeks
        VESTING_END_BLOCK = block.number.add(270000);
    }

    // =========================================================================================
    // Farming
    // =========================================================================================

    // Define how many NFTR is reward per block
    uint256 public COLLATERAL_POOL_MULTIPLIER = 1 * 1E18;
    uint256 public COLLATERAL_POOL_MULTIPLIER_UPDATED;

    uint256 public COLLATERAL_POOL_lastRewardBlock;

    // value reduce token per block each weeks (60 / 100 = 0,6)
    uint256 public COLLATERAL_POOL_UPDATER = 60;

    function _COLLATERAL_POOL_getReward(uint256 _from, uint256 _to)
        private
        view
        returns (uint256)
    {
        uint256 blocks;
        if (block.number > COLLATERAL_POOL_lastRewardBlock) {
            blocks = _to.sub(_from);
        }

        return blocks.mul(COLLATERAL_POOL_MULTIPLIER);
    }

    function _COLLATERAL_POOL_update() private {
        if (COLLATERAL_POOL_lastRewardBlock == 0 || totalETHCollateral == 0) {
            COLLATERAL_POOL_lastRewardBlock = block.number;
            return;
        }

        uint256 reward =
            _COLLATERAL_POOL_getReward(
                COLLATERAL_POOL_lastRewardBlock,
                block.number
            );

        accTokensPerETH = accTokensPerETH.add(
            reward.mul(1e12).div(totalETHCollateral)
        );
        COLLATERAL_POOL_lastRewardBlock = block.number;

        if (
            block.number >=
            COLLATERAL_POOL_MULTIPLIER_UPDATED.add(MULTIPLIER_UPDATE_EVERY)
        ) {
            COLLATERAL_POOL_MULTIPLIER_UPDATED = block.number;
            COLLATERAL_POOL_MULTIPLIER = COLLATERAL_POOL_MULTIPLIER
                .mul(COLLATERAL_POOL_UPDATER)
                .div(100);
        }
    }

    // Allow to see the reward from this pool for msg.sender
    function COLLATERAL_POOL_pendingReward(address _user)
        external
        view
        returns (uint256)
    {
        return _COLLATERAL_POOL_pendingReward(collateralProvider[_user]);
    }

    function _COLLATERAL_POOL_pendingReward(CollateralProvider memory u)
        private
        view
        returns (uint256)
    {
        uint256 _accTokensPerETH = accTokensPerETH;

        if (
            block.number > COLLATERAL_POOL_lastRewardBlock &&
            totalETHCollateral != 0
        ) {
            uint256 _pending =
                _COLLATERAL_POOL_getReward(
                    COLLATERAL_POOL_lastRewardBlock,
                    block.number
                );
            _accTokensPerETH = _accTokensPerETH.add(
                _pending.mul(1e12).div(totalETHCollateral)
            );
        }

        return
            u.ethCollateralProvided.mul(_accTokensPerETH).div(1e12).sub(
                u.rewardDebtFromETH
            );
    }

    function _COLLATERAL_POOL_harvest(address a) private {
        CollateralProvider storage u = collateralProvider[a];
        uint256 pendingNFTR = _COLLATERAL_POOL_pendingReward(u);

        _COLLATERAL_POOL_update();

        if (pendingNFTR > 0) {
            if (block.number > VESTING_END_BLOCK) {
                // if vesting period ended
                // Direct transfer tokens
                _safeTokenTransfer(a, pendingNFTR);
            } else {
                // else create vesting instance
                _createVestingInstance(a, pendingNFTR);
            }

            u.rewardDebtFromETH = u
                .ethCollateralProvided
                .mul(accTokensPerETH)
                .div(1e12);
        }

        u.rewardDebtFromETH = u.ethCollateralProvided.mul(accTokensPerETH).div(
            1e12
        );
    }

    // Allow platform to stake for an user with the amount of ETH he provide collateral in the platform
    function COLLATERAL_POOL_stake(address _user, uint256 amount)
        external
        onlyPlatform
    {
        _COLLATERAL_POOL_harvest(_user);
        totalETHCollateral = totalETHCollateral.add(amount.div(1E12));

        CollateralProvider storage u = collateralProvider[_user];
        u.ethCollateralProvided = u.ethCollateralProvided.add(amount.div(1E12));
        u.rewardDebtFromETH = u
            .ethCollateralProvided
            .mul(totalETHCollateral)
            .div(1e12);
    }

    // Allow platform to unstake when an user withdraw hhis collateral
    function COLLATERAL_POOL_unstake(address _user, uint256 amount)
        external
        onlyPlatform
    {
        CollateralProvider storage u = collateralProvider[_user];
        require(amount > 0, "Unstaking 0 Collateral.");
        require(
            u.ethCollateralProvided >= amount.div(1E12),
            "Unstaking more than currently staked."
        );

        _COLLATERAL_POOL_harvest(_user);
        totalETHCollateral = totalETHCollateral.sub(amount.div(1E12));

        u.ethCollateralProvided = u.ethCollateralProvided.sub(amount.div(1E12));
        u.rewardDebtFromETH = u
            .ethCollateralProvided
            .mul(totalETHCollateral)
            .div(1e12);
    }

    // General Harvest, allow user to harvest from 2 pools
    function globalHarvest() external notBanned {
        require(
            totalETHCollateral > 0 || totalNFTOnContract > 0,
            "Pools hasn't started yet."
        );

        if (
            _COLLATERAL_POOL_pendingReward(collateralProvider[msg.sender]) > 0
        ) {
            _COLLATERAL_POOL_harvest(msg.sender);
        }
        if (_NFT_POOL_pendingReward(nftProvider[msg.sender]) > 0) {
            _NFT_POOL_harvest(msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./VestingContract.sol";

contract FarmingFromNFT is VestingContract {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Total of NFT provided in the platform
    uint256 public totalNFTOnContract;

    struct NftProvider {
        uint256 NFTprovided; // NFT provided
        uint256 rewardDebtFromNFT;
    }

    mapping(address => NftProvider) public nftProvider;

    // =========================================================================================
    // Farming
    // =========================================================================================

    uint256 public NFT_POOL_MULTIPLIER = 1 * 1E18;
    uint256 public NFT_POOL_MULTIPLIER_UPDATED;
    uint256 public constant MULTIPLIER_UPDATE_EVERY = 45000; // 1 week (blocks)
    uint256 public NFT_POOL_lastRewardBlock;
    uint256 public accTokensPerNFT;
    uint256 public accTokensPerETH;

    uint256 public NFT_POOL_UPDATER = 60; // value reduce token per block each weeks (60 / 100 = 0,6)

    function _NFT_POOL_getReward(uint256 _from, uint256 _to)
        private
        view
        returns (uint256)
    {
        uint256 blocks;

        if (block.number > NFT_POOL_lastRewardBlock) {
            blocks = _to.sub(_from);
        }

        return blocks.mul(NFT_POOL_MULTIPLIER);
    }

    function _NFT_POOL_update() private {
        if (NFT_POOL_lastRewardBlock == 0 || totalNFTOnContract == 0) {
            NFT_POOL_lastRewardBlock = block.number;
            return;
        }

        uint256 reward =
            _NFT_POOL_getReward(NFT_POOL_lastRewardBlock, block.number);

        accTokensPerNFT = accTokensPerNFT.add(
            reward.mul(1e12).div(totalNFTOnContract)
        );
        NFT_POOL_lastRewardBlock = block.number;

        if (
            block.number >=
            NFT_POOL_MULTIPLIER_UPDATED.add(MULTIPLIER_UPDATE_EVERY)
        ) {
            NFT_POOL_MULTIPLIER_UPDATED = block.number;
            NFT_POOL_MULTIPLIER = NFT_POOL_MULTIPLIER.mul(NFT_POOL_UPDATER).div(
                100
            );
        }
    }

    // Allow to see the reward from this pool for msg.sender
    function NFT_POOL_pendingReward(address _user)
        external
        view
        returns (uint256)
    {
        return _NFT_POOL_pendingReward(nftProvider[_user]);
    }

    function _NFT_POOL_pendingReward(NftProvider memory u)
        internal
        view
        returns (uint256)
    {
        uint256 _accTokensPerNFT = accTokensPerNFT;

        if (
            block.number > NFT_POOL_lastRewardBlock && totalNFTOnContract != 0
        ) {
            uint256 _pending =
                _NFT_POOL_getReward(NFT_POOL_lastRewardBlock, block.number);
            _accTokensPerNFT = _accTokensPerNFT.add(
                _pending.mul(1e12).div(totalNFTOnContract)
            );
        }

        return
            u.NFTprovided.mul(_accTokensPerNFT).div(1e12).sub(
                u.rewardDebtFromNFT
            );
    }

    function _NFT_POOL_harvest(address a) internal {
        NftProvider storage u = nftProvider[a];
        uint256 pendingNFTR = _NFT_POOL_pendingReward(u);
        _NFT_POOL_update();

        if (pendingNFTR > 0) {
            if (block.number > VESTING_END_BLOCK) {
                // if vesting period ended
                // Direct transfer tokens
                _safeTokenTransfer(a, pendingNFTR);
            } else {
                // else create vesting instance
                _createVestingInstance(a, pendingNFTR);
            }
        }

        u.rewardDebtFromNFT = u.NFTprovided.mul(accTokensPerNFT).div(1e12);
    }

    // Allow platform to stake for an user with 1 NFT he provide for renting in the platform
    function NFT_POOL_stake(address _user) external onlyPlatform {
        _NFT_POOL_harvest(_user);
        totalNFTOnContract = totalNFTOnContract.add(1);

        NftProvider storage u = nftProvider[_user];
        u.NFTprovided = u.NFTprovided.add(1);
        u.rewardDebtFromNFT = u.NFTprovided.mul(accTokensPerNFT).div(1e12);
    }

    // Allow platform to unstake when an user withdraw hhis collateral
    function NFT_POOL_unstake(address _user) external onlyPlatform {
        NftProvider storage u = nftProvider[_user];
        require(u.NFTprovided >= 1, "Unstaking more than currently staked.");

        _NFT_POOL_harvest(msg.sender);
        totalNFTOnContract = totalNFTOnContract.sub(1);

        u.NFTprovided = u.NFTprovided.sub(1);
        u.rewardDebtFromNFT = u.NFTprovided.mul(accTokensPerNFT).div(1e12);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract VestingContract is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public NFTR;

    address public platform;

    constructor() {
        VESTING_END_BLOCK = block.number.add(180000);
    }

    function setNFTR(address _nftr) public onlyOwner {
        NFTR = IERC20(_nftr);
    }

    mapping(address => bool) public isBanned;

    modifier notBanned() {
        require(!isBanned[msg.sender]);
        _;
    }

    function bannishUser(address _user) external onlyPlatform {
        isBanned[_user] = true;
    }

    modifier onlyPlatform() {
        require(msg.sender == platform);
        _;
    }

    function setPlatform(address _platform) public onlyOwner {
        platform = _platform;
    }

    // =========================================================================================
    // VESTING NFTR REWARDS
    // =========================================================================================

    struct Vesting {
        uint256 totalReward;
        uint256 lastCall;
        uint256 nextValueCall;
        uint256 callRemaining;
    }

    mapping(address => Vesting) public myVesting;

    uint256 public VESTING_END_BLOCK;

    function _createVestingInstance(address a, uint256 amount) internal {
        // create a vesting instance
        // 10% of reward is directly transfered
        // 90% go to vesting of user, 10% unlocked each 4 weeks
        Vesting storage v = myVesting[a];

        // if no vesting opened, create one
        if (v.totalReward == 0) {
            // first transfer 10%
            _safeTokenTransfer(a, amount.div(10));
            // Then create
            myVesting[a] = Vesting(
                amount.mul(90).div(100),
                block.number,
                amount.div(10),
                9
            );
        } else {
            // If user have a claimable possibility
            if (block.number > v.lastCall.add(180000)) {
                _claimMyVesting(v);
            }

            // first transfer 10%
            _safeTokenTransfer(a, amount.div(10));

            // add 90% of pending to vesting
            v.totalReward = v.totalReward.add(amount.mul(90).div(100));

            // Calculate the futur claimable value
            v.nextValueCall = v.nextValueCall.add(amount.div(10));
        }
    }

    function claimMyVesting() public notBanned {
        Vesting storage v = myVesting[msg.sender];
        require(v.totalReward > 0, "You don't have any token to claim");
        require(
            block.number > v.lastCall.add(180000),
            "You have to wait 4 weeks between 2 claims"
        );

        _claimMyVesting(v);
    }

    function _claimMyVesting(Vesting memory _v) internal {
        // calculate number of period (1 period is 4 weeks)
        // If 8 weeks passed from last call, period = 2 and unlock 20 %...

        // Calculate number of block since last call
        uint256 _numberOfBlocks = block.number.sub(_v.lastCall);

        // calculate number of period
        // 1 period is 180000 blocks
        // 180001 block = 2 periods
        uint256 _period =
            (_numberOfBlocks.sub(_numberOfBlocks.mod(180000))).div(180000);

        // update last call
        // not really the last call, but the minimal block when the user could claim
        _v.lastCall = _v.lastCall.add(_period.mul(180000));

        // update number of remaining call
        _v.callRemaining = _v.callRemaining.sub(_period);

        // update total reward
        _v.totalReward = _v.totalReward.sub(_period.mul(_v.nextValueCall));

        // transfer tokens
        _safeTokenTransfer(msg.sender, _period.mul(_v.nextValueCall));
    }

    // PREVENT ROUNDING ERRORS

    function _safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 bal = NFTR.balanceOf(address(this));
        if (_amount > bal) {
            NFTR.transfer(_to, bal);
        } else {
            NFTR.transfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

