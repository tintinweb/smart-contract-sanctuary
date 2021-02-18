// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./interfaces/IBuybackInitializer.sol";
import "./interfaces/IPresale.sol";
import "./interfaces/ITokenDistributor.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IFarmActivator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

contract Presale is Ownable, IPresale, ITokenDistributor {
    event PresaleStarted();
    event FcfsActivated();
    event PresaleEnded();
    event ContributionAccepted(
        address indexed _contributor,
        uint256 _partialContribution,
        uint256 _totalContribution,
        uint256 _receivedTokens,
        uint256 _contributions
    );
    event ContributionRefunded(address indexed _contributor, uint256 _contribution);

    using SafeMath for uint256;

    uint256 public constant BUYBACK_ALLOCATION_PERCENT = 40;
    uint256 public constant LIQUIDITY_ALLOCATION_PERCENT = 20;
    uint256 public constant PRESALE_MAX_SUPPLY = 60000 * 10**18; // if hardcap reached, otherwise leftover burned
    uint256 public constant LIQUIDITY_MAX_SUPPLY = 5400 * 10**18; // if hardcap reached, otherwise leftover burned
    uint256 public constant RC_FARM_SUPPLY = 100000 * 10**18;
    uint256 public constant RC_ETH_FARM_SUPPLY = 160000 * 10**18;

    uint256 private hardcap;
    uint256 private collected;
    uint256 private maxContribution;
    uint256 private contributorTokensPerCollectedEth;
    uint256 private liquidityTokensPerCollectedEth;
    address private token;
    address private uniswapPair;
    address private buyback;
    address private liquidityLock;
    address private uniswapRouter;
    address private rcFarm;
    address private rcEthFarm;
    bool private isPresaleActiveFlag;
    bool private isFcfsActiveFlag;
    bool private wasPresaleEndedFlag;
    mapping(address => bool) private contributors;
    mapping(address => uint256) private contributions;

    modifier presaleActive() {
        require(isPresaleActiveFlag, "Presale is not active.");
        _;
    }

    modifier presaleNotActive() {
        require(!isPresaleActiveFlag, "Presale is active.");
        _;
    }

    modifier presaleNotEnded() {
        require(!wasPresaleEndedFlag, "Presale was ended.");
        _;
    }

    modifier sufficientSupply(address _token) {
        uint256 supply = IERC20(_token).balanceOf(address(this));
        require(supply >= getMaxSupply(), "Insufficient supply.");
        _;
    }

    modifier senderEligibleToContribute() {
        require(isFcfsActiveFlag || contributors[msg.sender], "Not eligible to participate.");
        _;
    }

    function getMaxSupply() public view override returns (uint256) {
        return PRESALE_MAX_SUPPLY.add(LIQUIDITY_MAX_SUPPLY).add(RC_FARM_SUPPLY).add(RC_ETH_FARM_SUPPLY);
    }

    function tokenAddress() external view override returns (address) {
        return token;
    }

    function uniswapPairAddress() external view override returns (address) {
        return uniswapPair;
    }

    function buybackAddress() external view override returns (address) {
        return buyback;
    }

    function liquidityLockAddress() external view override returns (address) {
        return liquidityLock;
    }

    function uniswapRouterAddress() external view override returns (address) {
        return uniswapRouter;
    }

    function rcFarmAddress() external view override returns (address) {
        return rcFarm;
    }

    function rcEthFarmAddress() external view override returns (address) {
        return rcEthFarm;
    }

    function collectedAmount() external view override returns (uint256) {
        return collected;
    }

    function hardcapAmount() external view override returns (uint256) {
        return hardcap;
    }

    function maxContributionAmount() external view override returns (uint256) {
        return maxContribution;
    }

    function isPresaleActive() external view override returns (bool) {
        return isPresaleActiveFlag;
    }

    function isFcfsActive() external view override returns (bool) {
        return isFcfsActiveFlag;
    }

    function wasPresaleEnded() external view override returns (bool) {
        return wasPresaleEndedFlag;
    }

    function isWhitelisted(address _contributor) external view override returns (bool) {
        return contributors[_contributor];
    }

    function contribution(address _contributor) external view override returns (uint256) {
        return contributions[_contributor];
    }

    function addContributors(address[] memory _contributors) public override onlyOwner {
        for (uint256 i; i < _contributors.length; i++) {
            bool isAlreadyAdded = contributors[_contributors[i]];
            if (isAlreadyAdded) {
                continue;
            }
            contributors[_contributors[i]] = true;
        }
    }

    function start(
        uint256 _hardcap,
        uint256 _maxContribution,
        address _token,
        address _uniswapPair,
        address _buyback,
        address _liquidityLock,
        address _uniswapRouter,
        address _rcFarm,
        address _rcEthFarm,
        address[] calldata _contributors
    ) external override onlyOwner presaleNotActive presaleNotEnded sufficientSupply(_token) {
        isPresaleActiveFlag = true;
        hardcap = _hardcap;
        maxContribution = _maxContribution;
        contributorTokensPerCollectedEth = PRESALE_MAX_SUPPLY.mul(10**18).div(hardcap);
        liquidityTokensPerCollectedEth = LIQUIDITY_MAX_SUPPLY.mul(10**18).div(hardcap);
        token = _token;
        uniswapPair = _uniswapPair;
        buyback = _buyback;
        liquidityLock = _liquidityLock;
        uniswapRouter = _uniswapRouter;
        rcFarm = _rcFarm;
        rcEthFarm = _rcEthFarm;
        addContributors(_contributors);
        emit PresaleStarted();
    }

    function activateFcfs() external override onlyOwner presaleActive {
        if (isFcfsActiveFlag) {
            return;
        }
        isFcfsActiveFlag = true;
        emit FcfsActivated();
    }

    function end(address payable _team) external override onlyOwner presaleActive {
        IERC20 rollerCoaster = IERC20(token);
        uint256 totalCollected = address(this).balance;

        // calculate buyback and execute it
        uint256 buybackEths = totalCollected.mul(BUYBACK_ALLOCATION_PERCENT).div(100);
        uint256 minTokensToHoldForBuybackCall = maxContribution.mul(contributorTokensPerCollectedEth).div(10**18);
        IBuybackInitializer(buyback).init{ value: buybackEths }(token, uniswapRouter, minTokensToHoldForBuybackCall);

        // calculate liquidity share
        uint256 liquidityEths = totalCollected.mul(LIQUIDITY_ALLOCATION_PERCENT).div(100);
        uint256 liquidityTokens = liquidityTokensPerCollectedEth.mul(totalCollected).div(10**18);

        // approve router and add liquidity
        rollerCoaster.approve(uniswapRouter, liquidityTokens);
        IUniswapV2Router02(uniswapRouter).addLiquidityETH{ value: liquidityEths }(
            token,
            liquidityTokens,
            liquidityTokens,
            liquidityEths,
            liquidityLock,
            block.timestamp
        );

        // transfer team share
        uint256 teamEths = totalCollected.sub(liquidityEths).sub(buybackEths);
        _team.transfer(teamEths);

        // transfer farm shares
        rollerCoaster.transfer(rcFarm, RC_FARM_SUPPLY);
        rollerCoaster.transfer(rcEthFarm, RC_ETH_FARM_SUPPLY);

        // start farming
        IFarmActivator(rcFarm).startFarming(token, token);
        IFarmActivator(rcEthFarm).startFarming(token, uniswapPair);

        // burn the remaining balance and unlock token
        IToken(token).burnDistributorTokensAndUnlock();

        // end presale
        isPresaleActiveFlag = false;
        wasPresaleEndedFlag = true;
        emit PresaleEnded();
    }

    receive() external payable presaleActive senderEligibleToContribute {
        uint256 totalContributionLeft = PRESALE_MAX_SUPPLY.sub(collected);
        uint256 senderContributionLeft = maxContribution.sub(contributions[msg.sender]);
        uint256 contributionLeft = Math.min(totalContributionLeft, senderContributionLeft);

        uint256 valueToAccept = Math.min(msg.value, contributionLeft);
        if (valueToAccept > 0) {
            collected = collected.add(valueToAccept);
            contributions[msg.sender] = contributions[msg.sender].add(valueToAccept);

            uint256 tokensToTransfer = contributorTokensPerCollectedEth.mul(valueToAccept).div(10**18);
            IERC20(token).transfer(msg.sender, tokensToTransfer);

            emit ContributionAccepted(
                msg.sender,
                valueToAccept,
                contributions[msg.sender],
                tokensToTransfer,
                collected
            );
        }

        uint256 valueToRefund = msg.value.sub(valueToAccept);
        if (valueToRefund > 0) {
            _msgSender().transfer(valueToRefund);

            emit ContributionRefunded(msg.sender, valueToRefund);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IBuybackInitializer {
    function init(address _token, address _uniswapRouter, uint256 _minTokensToHold) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IFarmActivator {
    function startFarming(address _rewardToken, address _farmToken) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IPresale {
    event PresaleStarted();

    event FcfsActivated();

    event PresaleEnded();

    event ContributionAccepted(
        address indexed _contributor,
        uint256 _partialContribution,
        uint256 _totalContribution,
        uint256 _receivedTokens,
        uint256 _contributions
    );

    event ContributionRefunded(address indexed _contributor, uint256 _contribution);

    function tokenAddress() external view returns (address);

    function uniswapPairAddress() external view returns (address);

    function buybackAddress() external view returns (address);

    function liquidityLockAddress() external view returns (address);

    function uniswapRouterAddress() external view returns (address);

    function rcFarmAddress() external view returns (address);

    function rcEthFarmAddress() external view returns (address);

    function collectedAmount() external view returns (uint256);

    function hardcapAmount() external view returns (uint256);

    function maxContributionAmount() external view returns (uint256);

    function isPresaleActive() external view returns (bool);

    function isFcfsActive() external view returns (bool);

    function wasPresaleEnded() external view returns (bool);

    function isWhitelisted(address _contributor) external view returns (bool);

    function contribution(address _contributor) external view returns (uint256);

    function addContributors(address[] calldata _contributors) external;

    function start(
        uint256 _hardcap,
        uint256 _maxContribution,
        address _token,
        address _uniswapPair,
        address _buyback,
        address _liquidityLock,
        address _uniswapRouter,
        address _rcFarm,
        address _rcEthFarm,
        address[] calldata _contributors
    ) external;

    function activateFcfs() external;

    function end(address payable _team) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken {
    function uniswapPairAddress() external view returns (address);

    function setUniswapPair(address _uniswapPair) external;

    function burnDistributorTokensAndUnlock() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ITokenDistributor {
    function getMaxSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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