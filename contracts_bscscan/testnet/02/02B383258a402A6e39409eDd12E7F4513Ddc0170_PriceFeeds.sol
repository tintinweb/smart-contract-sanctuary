/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/Ownable.sol";
import "../interfaces/IERC20.sol";
import "./PriceFeedsConstants.sol";


interface IPriceFeedsExt {
  function latestAnswer() external view returns (uint256);
}

contract PriceFeeds is Constants, Ownable {
    using SafeMath for uint256;

    event GlobalPricingPaused(
        address indexed sender,
        bool indexed isPaused
    );

    mapping (address => IPriceFeedsExt) public pricesFeeds;     // token => pricefeed
    mapping (address => uint256) public decimals;               // decimals of supported tokens

    uint256 public protocolTokenEthPrice = 0.0002 ether;

    bool public globalPricingPaused = false;

    constructor(
        address _wbaseTokenAddress,
        address _protocolTokenAddress,
        address _baseTokenAddress)
        public
    {
        // set decimals for ether
        decimals[address(0)] = 18;
        decimals[_wbaseTokenAddress] = 18;
        _setWbaseToken(_wbaseTokenAddress);
        _setProtocolTokenAddress(_protocolTokenAddress);
        _setBaseToken(_baseTokenAddress);
    }

    function queryRate(
        address sourceToken,
        address destToken)
        public
        view
        returns (uint256 rate, uint256 precision)
    {
        return _queryRate(
            sourceToken,
            destToken
        );
    }

    function queryPrecision(
        address sourceToken,
        address destToken)
        public
        view
        returns (uint256)
    {
        return sourceToken != destToken ?
            _getDecimalPrecision(sourceToken, destToken) :
            10**18;
    }

    //// NOTE: This function returns 0 during a pause, rather than a revert. Ensure calling contracts handle correctly. ///
    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount)
        public
        view
        returns (uint256 destAmount)
    {
        (uint256 rate, uint256 precision) = _queryRate(
            sourceToken,
            destToken
        );

        destAmount = sourceAmount
            .mul(rate)
            .div(precision);
    }

    function checkPriceDisagreement(
        address sourceToken,
        address destToken,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 maxSlippage)
        public
        view
        returns (uint256 sourceToDestSwapRate)
    {
        (uint256 rate, uint256 precision) = _queryRate(
            sourceToken,
            destToken
        );

        sourceToDestSwapRate = destAmount
            .mul(precision)
            .div(sourceAmount);

        uint256 spreadValue = sourceToDestSwapRate > rate ?
            sourceToDestSwapRate - rate :
            rate - sourceToDestSwapRate;

        if (spreadValue != 0) {
            spreadValue = spreadValue
                .mul(10**20)
                .div(sourceToDestSwapRate);

            require(
                spreadValue <= maxSlippage,
                "price disagreement"
            );
        }
    }

    function amountInEth(
        address tokenAddress,
        uint256 amount)
        public
        view
        returns (uint256 ethAmount)
    {
        if (tokenAddress == address(wbaseToken)) {
            ethAmount = amount;
        } else {
            (uint toEthRate, uint256 toEthPrecision) = queryRate(
                tokenAddress,
                address(wbaseToken)
            );
            ethAmount = amount
                .mul(toEthRate)
                .div(toEthPrecision);
        }
    }

    function getMaxDrawdown(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 margin)
        public
        view
        returns (uint256 maxDrawdown)
    {
        uint256 loanToCollateralAmount;
        if (collateralToken == loanToken) {
            loanToCollateralAmount = loanAmount;
        } else {
            (uint256 rate, uint256 precision) = queryRate(
                loanToken,
                collateralToken
            );
            loanToCollateralAmount = loanAmount
                .mul(rate)
                .div(precision);
        }

        uint256 combined = loanToCollateralAmount
            .add(
                loanToCollateralAmount
                    .mul(margin)
                    .div(10**20)
                );

        maxDrawdown = collateralAmount > combined ?
            collateralAmount - combined :
            0;
    }

    function getCurrentMarginAndCollateralSize(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        public
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount)
    {
        (currentMargin,) = getCurrentMargin(
            loanToken,
            collateralToken,
            loanAmount,
            collateralAmount
        );

        collateralInEthAmount = amountInEth(
            collateralToken,
            collateralAmount
        );
    }
    
    /**
     * current margin = (total position size - loan)/ loan 
     * the collateral amount passed as parameter equals the total position size. 
     * */
    function getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        public
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate)
    {
        uint256 collateralToLoanAmount;
        if (collateralToken == loanToken) {
            collateralToLoanAmount = collateralAmount;
            collateralToLoanRate = 10**18;
        } else {
            uint256 collateralToLoanPrecision;
            (collateralToLoanRate, collateralToLoanPrecision) = queryRate(
                collateralToken,
                loanToken
            );

            collateralToLoanRate = collateralToLoanRate
                .mul(10**18)
                .div(collateralToLoanPrecision);

            collateralToLoanAmount = collateralAmount
                .mul(collateralToLoanRate)
                .div(10**18);
        }

        if (loanAmount != 0 && collateralToLoanAmount >= loanAmount) {
            return (
                collateralToLoanAmount
                    .sub(loanAmount)
                    .mul(10**20)
                    .div(loanAmount),
                collateralToLoanRate
            );
        } else {
            return (
                0,
                collateralToLoanRate
            );
        }
    }

    function shouldLiquidate(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        public
        view
        returns (bool)
    {
        (uint256 currentMargin,) = getCurrentMargin(
            loanToken,
            collateralToken,
            loanAmount,
            collateralAmount
        );

        return currentMargin <= maintenanceMargin;
    }
    



    /*
    * Owner functions
    */

    function setProtocolTokenEthPrice(
        uint256 newPrice)
        external
        onlyOwner
    {
        require(newPrice != 0, "invalid price");
        protocolTokenEthPrice = newPrice;
    }

    function setPriceFeed(
        address[] calldata tokens,
        IPriceFeedsExt[] calldata feeds)
        external
        onlyOwner
    {
        require(tokens.length == feeds.length, "count mismatch");

        for (uint256 i = 0; i < tokens.length; i++) {
            pricesFeeds[tokens[i]] = feeds[i];
        }
    }

    function setDecimals(
        IERC20[] calldata tokens)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            decimals[address(tokens[i])] = tokens[i].decimals();
        }
    }

    function setGlobalPricingPaused(
        bool isPaused)
        external
        onlyOwner
    {
        if (globalPricingPaused != isPaused) {
            globalPricingPaused = isPaused;

            emit GlobalPricingPaused(
                msg.sender,
                isPaused
            );
        }
    }

    /*
    * Internal functions
    */

    function _queryRate(
        address sourceToken,
        address destToken)
        internal
        view
        returns (uint256 rate, uint256 precision)
    {
        require(!globalPricingPaused, "pricing is paused");

        if (sourceToken != destToken) {
            uint256 sourceRate;
            if (sourceToken != address(baseToken) && sourceToken != protocolTokenAddress) {
                IPriceFeedsExt _sourceFeed = pricesFeeds[sourceToken];
                require(address(_sourceFeed) != address(0), "unsupported src feed");
                sourceRate = _sourceFeed.latestAnswer();
                require(sourceRate != 0 && (sourceRate >> 128) == 0, "price error");
            } else {
                sourceRate = sourceToken == protocolTokenAddress ?
                    protocolTokenEthPrice :
                    10**18;
            }

            uint256 destRate;
            if (destToken != address(baseToken) && destToken != protocolTokenAddress) {
                IPriceFeedsExt _destFeed = pricesFeeds[destToken];
                require(address(_destFeed) != address(0), "unsupported dst feed");
                destRate = _destFeed.latestAnswer();
                require(destRate != 0 && (destRate >> 128) == 0, "price error");
            } else {
                destRate = destToken == protocolTokenAddress ?
                    protocolTokenEthPrice :
                    10**18;
            }

            rate = sourceRate
                .mul(10**18)
                .div(destRate);

            precision = _getDecimalPrecision(sourceToken, destToken);
        } else {
            rate = 10**18;
            precision = 10**18;
        }
    }

    function _getDecimalPrecision(
        address sourceToken,
        address destToken)
        internal
        view
        returns(uint256)
    {
        if (sourceToken == destToken) {
            return 10**18;
        } else {
            uint256 sourceTokenDecimals = decimals[sourceToken];
            if (sourceTokenDecimals == 0)
                sourceTokenDecimals = IERC20(sourceToken).decimals();

            uint256 destTokenDecimals = decimals[destToken];
            if (destTokenDecimals == 0)
                destTokenDecimals = IERC20(destToken).decimals();

            if (destTokenDecimals >= sourceTokenDecimals)
                return 10**(SafeMath.sub(18, destTokenDecimals-sourceTokenDecimals));
            else
                return 10**(SafeMath.add(18, sourceTokenDecimals-destTokenDecimals));
        }
    }


}

pragma solidity >=0.5.0 <0.6.0;

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

    function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}

pragma solidity >=0.5.0 <0.6.0;

import "./Context.sol";


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
        require(isOwner(), "unauthorized");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;


contract IERC20 {
    string public name;
    uint8 public decimals;
    string public symbol;
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../interfaces/IWbaseERC20.sol";
import "../openzeppelin/Address.sol";


contract Constants {
    IWbaseERC20 public wbaseToken;
    IWbaseERC20 public baseToken;
    address internal protocolTokenAddress;

    function _setWbaseToken(
        address _wbaseTokenAddress)
        internal
    {
        require(Address.isContract(_wbaseTokenAddress), "_wbaseTokenAddress not a contract");
        wbaseToken = IWbaseERC20(_wbaseTokenAddress);
    }

    function _setProtocolTokenAddress(
        address _protocolTokenAddress)
        internal
    {
        require(Address.isContract(_protocolTokenAddress), "_protocolTokenAddress not a contract");
        protocolTokenAddress = _protocolTokenAddress;
    }
    
    function _setBaseToken(
        address _baseTokenAddress) 
        internal
    {
        require(Address.isContract(_baseTokenAddress), "_baseTokenAddress not a contract");
        baseToken = IWbaseERC20(_baseTokenAddress);
    }
}

pragma solidity >=0.5.0 <0.6.0;

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

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;

import "./IWbase.sol";
import "./IERC20.sol";


contract IWbaseERC20 is IWbase, IERC20 {}

pragma solidity >=0.5.0 <0.6.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;


interface IWbase {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}