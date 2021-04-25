//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../interfaces/ILendingPool.sol";
import "../interfaces/ISoloMargin.sol";
import "../interfaces/ICToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAaveAddressProvider {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address);
}

interface IProtocolDataProvider {
    function getUserReserveData(address reserve, address user)
        external
        view
        returns (
            uint256 currentATokenBalance
        );
}

contract Investments is Ownable{
    using SafeMath for uint256;

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    mapping(address => address) internal cTokens;
    mapping(address => uint256) internal dydxMarkets;

    IAaveAddressProvider aaveProvider = IAaveAddressProvider(
        0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
    );

    IProtocolDataProvider aaveDataProviderV2 = IProtocolDataProvider(
        0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d
    );

    ISoloMargin solo = ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    struct Balance {
        uint256 dydx;
        uint256 compound;
        uint256 aave;
        uint256 aaveV2;
    }

    constructor() {
        cTokens[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5; // ETH
        cTokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 0x39AA39c021dfbaE8faC545936693aC917d5E7563; // USDC
        cTokens[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643; // DAI
        cTokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9; // USDT

        dydxMarkets[ETH] = 1;
        dydxMarkets[WETH] = 1;
        dydxMarkets[USDC] = 3;
        dydxMarkets[DAI] = 4;    
    }

    function getCToken(address token) public view returns (address) {
        return cTokens[token];
    }

    function addCToken(address token, address _cToken) external onlyOwner{
        cTokens[token] = _cToken;
    }

    function getMarketId(address token) public view returns (uint256) {
        return dydxMarkets[token] -1;
    }

    function addDydxMarket(address token, uint marketId) external onlyOwner{
        dydxMarkets[token] = marketId;
    }

    function getDydxBalance(address token, address user)
        public
        view
        returns (uint256)
    {
        uint256 marketId = getMarketId(token);
        if (marketId == uint256(-1)) return 0;

        ISoloMargin.Wei memory accountWei = solo.getAccountWei(
            ISoloMargin.Info(user, 0),
            marketId
        );
        return accountWei.sign ? accountWei.value : 0;
    }

    function getCompoundBalance(address token, address user)
        public
        view
        returns (uint256)
    {
        (, uint256 balance, , uint256 rate) = CTokenInterface(getCToken(token)).getAccountSnapshot(user);

        return balance.mul(rate).div(1 ether);
    }

    function getAaveBalance(address token, address account)
        public
        view
        returns (uint256 balance)
    {
        (balance, , ) = ILendingPool(aaveProvider.getLendingPool())
            .getUserReserveData(token, account);
    }

    function getAaveBalanceV2(address token, address account)
        public
        view
        returns (uint256)
    {
        return aaveDataProviderV2.getUserReserveData(token == ETH ? WETH:token, account);
    }

    function getBalances(address[] calldata tokens, address user)
        external
        view
        returns (Balance[] memory)
    {
        Balance[] memory balances = new Balance[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i].compound = getCompoundBalance(tokens[i], user);
            balances[i].aave = getAaveBalance(tokens[i], user);
            balances[i].aaveV2 = getAaveBalanceV2(tokens[i], user);
            balances[i].dydx = getDydxBalance(tokens[i], user);
        }

        return balances;
    }
}

pragma solidity ^0.7.0;

interface ILendingPool {
    function deposit(
        address reserve,
        uint256 amount,
        uint16 referralCode
    ) external payable;

    function borrow(
        address reserve,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode
    ) external;

    function repay(
        address _reserve,
        uint256 amount,
        address payable onBehalfOf
    ) external payable;

    function rebalanceStableBorrowRate(address reserve, address user) external;

    function getReserveData(address reserve)
        external
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsStable,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 utilizationRate
            // uint256 liquidityIndex,
            // uint256 variableBorrowIndex,
            // address aTokenAddress,
            // uint40 lastUpdateTimestamp
        );

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalLiquidityETH,
            uint256 totalCollateralETH,
            uint256 totalBorrowsETH,
            uint256 totalFeesETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getUserReserveData(address reserve, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentBorrowBalance,
            uint256 principalBorrowBalance
            // uint256 borrowRateMode,
            // uint256 borrowRate,
            // uint256 liquidityRate,
            // uint256 originationFee,
            // uint256 variableBorrowIndex,
            // uint256 lastUpdateTimestamp,
            // bool usageAsCollateralEnabled
        );

    function setUserUseReserveAsCollateral(
        address _reserve,
        bool _useAsCollateral
    ) external;
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

abstract contract ISoloMargin {
    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Rate {
        uint256 value;
    }

    // Total borrow and supply values for a market
    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (externally)
        Sell, // sell an amount of some token (externally)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    function operate(Info[] memory accounts, ActionArgs[] memory actions)
        public virtual;

    function getAccountWei(Info memory account, uint256 marketId)
        public
        virtual
        view
        returns (Wei memory);

    function getMarketInterestRate(uint256 marketId)
        public
        virtual
        view
        returns (Rate memory);

    function getMarketTotalPar(uint256 marketId)
        public
        virtual
        view
        returns (TotalPar memory);
}

pragma solidity ^0.7.0;

interface CTokenInterface {
    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);

    function liquidateBorrow(address borrower, address cTokenCollateral)
        external
        payable;

    function exchangeRateCurrent() external returns (uint256);

    function getCash() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalReserves() external view returns (uint256);
    
    function totalBorrows() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function getAccountSnapshot(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function underlying() external returns (address);

    function mint(uint mintAmount) external returns (uint);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}