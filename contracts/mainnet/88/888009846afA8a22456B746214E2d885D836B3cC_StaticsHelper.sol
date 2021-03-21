pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IVault.sol";

contract StaticsHelper is Ownable {
    using SafeMath for uint256;

    mapping(address => address) public priceFeeds;
    mapping(address => address) public lpSubTokens;
    mapping(address => address) public rewardPools;

    function setPriceFeed(address token, address feed) external onlyOwner {
        priceFeeds[token] = feed;
    }

    function setLpSubToken(address token, address subToken) external onlyOwner {
        lpSubTokens[token] = subToken;
    }

    function setRewardPool(address vault, address rewardPool)
        external
        onlyOwner
    {
        rewardPools[vault] = rewardPool;
    }

    function getBalances(address[] memory tokens, address user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            if (tokens[i] == address(0)) {
                amounts[i] = user.balance;
            } else {
                amounts[i] = IERC20(tokens[i]).balanceOf(user);
            }
        }
        return amounts;
    }

    function getTotalSupplies(address[] memory tokens)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            amounts[i] = IERC20(tokens[i]).totalSupply();
        }
        return amounts;
    }

    function getTokenAllowances(
        address[] memory tokens,
        address[] memory spenders,
        address user
    ) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            amounts[i] = IERC20(tokens[i]).allowance(user, spenders[i]);
        }
        return amounts;
    }

    function getTotalDeposits(address[] memory vaults)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory deposits = new uint256[](vaults.length);
        for (uint256 i = 0; i < vaults.length; i += 1) {
            deposits[i] = IVault(vaults[i]).totalDeposits();
        }
        return deposits;
    }

    function underlyingBalanceWithInvestment(address[] memory vaults)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](vaults.length);
        for (uint256 i = 0; i < vaults.length; i += 1) {
            amounts[i] = IVault(vaults[i]).underlyingBalanceWithInvestment();
        }
        return amounts;
    }

    function getChainlinkPrice(address token) public view returns (uint256) {
        if (priceFeeds[token] == address(0)) return 0;
        (, int256 price, , , ) =
            AggregatorV3Interface(priceFeeds[token]).latestRoundData();
        uint256 decimals =
            uint256(AggregatorV3Interface(priceFeeds[token]).decimals());
        uint256 uPrice = uint256(price);
        if (decimals < 18) {
            return uPrice.mul(10**(18 - decimals));
        } else if (decimals > 18) {
            return uPrice.div(10**(decimals - 18));
        }
        return uPrice;
    }

    function getLPPrice(address lp) public view returns (uint256) {
        if (lpSubTokens[lp] == address(0)) return 0;
        address subToken = lpSubTokens[lp];
        uint256 subTokenPrice = getChainlinkPrice(subToken);
        address _lp = lp;
        uint256 lpPrice =
            IERC20(subToken)
                .balanceOf(_lp)
                .mul(2)
                .mul(subTokenPrice)
                .mul(1e18)
                .div(IERC20(_lp).totalSupply())
                .div(10**uint256(ERC20Detailed(subToken).decimals()));
        return lpPrice;
    }

    function getPrices(address[] memory tokens)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            amounts[i] = getPrice(tokens[i]);
        }
        return amounts;
    }

    function getPrice(address token) public view returns (uint256) {
        if (priceFeeds[token] != address(0)) {
            return getChainlinkPrice(token);
        }
        if (lpSubTokens[token] != address(0)) {
            return getLPPrice(token);
        }
        return 0;
    }

    function getPortfolio(address[] memory tokens, address user)
        public
        view
        returns (uint256)
    {
        uint256 portfolio;
        uint256[] memory balances = getBalances(tokens, user);
        uint256[] memory prices = getPrices(tokens);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            portfolio = portfolio.add(
                prices[i].mul(balances[i]).div(
                    10**uint256(ERC20Detailed(tokens[i]).decimals())
                )
            );
        }
        return portfolio;
    }

    function getTVL(address[] memory vaults) public view returns (uint256) {
        uint256 tvl;
        for (uint256 i = 0; i < vaults.length; i += 1) {
            uint256 price = getPrice(IVault(vaults[i]).underlying());
            uint256 investment =
                IVault(vaults[i]).underlyingBalanceWithInvestment();
            tvl = tvl.add(price.mul(investment));
        }
        return tvl;
    }

    function getVaultEarning(address vault)
        public
        view
        returns (uint256, uint256)
    {
        address underlying = IVault(vault).underlying();
        uint256 totalEarning =
            IVault(vault).underlyingBalanceWithInvestment().sub(
                IVault(vault).totalDeposits()
            );
        uint256 totalEarningInUSD =
            totalEarning.mul(getPrice(underlying)).div(
                10**uint256(ERC20Detailed(underlying).decimals())
            );
        return (totalEarning, totalEarningInUSD);
    }

    function getUserVaultEarning(address vault, address user)
        public
        view
        returns (uint256, uint256)
    {
        (uint256 totalEarning, uint256 totalEarningInUSD) =
            getVaultEarning(vault);
        uint256 position =
            IERC20(vault).balanceOf(user).add(
                IERC20(rewardPools[vault]).balanceOf(user)
            );
        uint256 vaultTotalSupply = IERC20(vault).totalSupply();
        uint256 userEarning = totalEarning.mul(position).div(vaultTotalSupply);
        uint256 userEarningInUSD =
            totalEarningInUSD.mul(position).div(vaultTotalSupply);
        return (userEarning, userEarningInUSD);
    }

    function getUserVaultEarning(address[] memory vaults, address user)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory earnings = new uint256[](vaults.length);
        uint256[] memory earningsInUSD = new uint256[](vaults.length);
        for (uint256 i = 0; i < vaults.length; i += 1) {
            (earnings[i], earningsInUSD[i]) = getUserVaultEarning(
                vaults[i],
                user
            );
        }
        return (earnings, earningsInUSD);
    }
}

pragma solidity 0.5.16;

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceWithInvestment() external view returns (uint256);

    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function setVaultFractionToInvest(uint256 numerator, uint256 denominator)
        external;

    function deposit(uint256 amountWei) external;

    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;

    function withdraw(uint256 numberOfShares) external;

    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder)
        external
        view
        returns (uint256);

    // force unleash should be callable only by the controller (by the force unleasher) or by governance
    function forceUnleashed() external;

    function rebalance() external;

    function totalDeposits() external view returns (uint256);
}

pragma solidity >=0.5.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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