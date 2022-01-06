// SPDX-License-Identifier: MIT
/**
 * Created on 2021-08-27
 * @summary: Jibrel Compound Tranche Protocol Helper
 * @author: Jibrel Team
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./interfaces/IQiErc20.sol";
import "./interfaces/IJBenQiHelper.sol";


contract JBenQiHelper is OwnableUpgradeable, IJBenQiHelper {
    using SafeMathUpgradeable for uint256;

    // address public jCompoundAddress;

    function initialize (/*address _jCompAddr*/) public initializer {
        OwnableUpgradeable.__Ownable_init();
        // jCompoundAddress = _jCompAddr;
    }
/*
    /**
     * @dev modifiers
     */
/*    modifier onlyJCompound() {
        require(msg.sender == jCompoundAddress, "!JCompound");
        _;
    }

    /**
     * @dev send an amount of tokens to corresponding compound contract (it takes tokens from this contract). Only allowed token should be sent
     * @param _underToken underlying token contract address
     * @param _qiToken qiToken contract address
     * @param _numTokensToSupply token amount to be sent
     * @return mint result
     */
/*    function sendErc20ToCompoundHelper(address _underToken, 
            address _qiToken, 
            uint256 _numTokensToSupply) public override onlyJCompound returns(uint256) {
        require(_qiToken != address(0), "!Accept");
        // i.e. DAI contract, on Kovan: 0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa
        IERC20Upgradeable underlying = IERC20Upgradeable(_underToken);

        // i.e. cDAI contract, on Kovan: 0xf0d0eb522cfa50b716b3b1604c4f0fa6f04376ad
        IQiErc20 qiToken = IQiErc20(_qiToken);

        SafeERC20Upgradeable.safeApprove(underlying, _qiToken, _numTokensToSupply);
        require(underlying.allowance(jCompoundAddress, _qiToken) >= _numTokensToSupply, "!AllowqiToken");

        uint256 mintResult = qiToken.mint(_numTokensToSupply);
        return mintResult;
    }

    /**
     * @dev redeem an amount of qiTokens to have back original tokens (tokens remains in this contract). Only allowed token should be sent
     * @param _qiToken qiToken contract address
     * @param _amount qiToken amount to be sent
     * @param _redeemType true or false, normally true
     */
/*    function redeemQiErc20TokensHelper(address _qiToken, 
            uint256 _amount, 
            bool _redeemType) public override onlyJCompound returns (uint256 redeemResult) {
        require(_qiToken != address(0),  "!Accept");
        // i.e. cDAI contract, on Kovan: 0xf0d0eb522cfa50b716b3b1604c4f0fa6f04376ad
        IQiErc20 qiToken = IQiErc20(_qiToken);

        if (_redeemType) {
            // Retrieve your asset based on a qiToken amount
            redeemResult = qiToken.redeem(_amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = qiToken.redeemUnderlying(_amount);
        }
        return redeemResult;
    }
*/
    /**
     * @dev get qiToken stored exchange rate from compound contract
     * @param _qiTokenAddress qiToken address
     * @return exchRateMantissa exchange rate qiToken mantissa
     */
    function getQiTokenExchangeRate(address _qiTokenAddress) public view returns (uint256 exchRateMantissa) {
        // Amount of current exchange rate from qiToken to underlying
        return exchRateMantissa = IQiErc20(_qiTokenAddress).exchangeRateStored(); // it returns something like 210615675702828777787378059 (cDAI contract) or 209424757650257 (cUSDT contract)
    }

    /**
     * @dev get compound mantissa
     * @param _underDecs underlying decimals
     * @param _qiTokenDecs qiToken decimals
     * @return mantissa tranche mantissa (from 16 to 28 decimals)
     */
    function getMantissaHelper(uint256 _underDecs, uint256 _qiTokenDecs) public pure override returns (uint256 mantissa) {
        mantissa = (uint256(_underDecs)).add(18).sub(uint256(_qiTokenDecs));
        return mantissa;
    }

    /**
     * @dev get compound pure price for a single tranche
     * @param _qiTokenAddress qiToken address
     * @return purePrice protocol current pure price
     */
    function getBenQiPurePriceHelper(address _qiTokenAddress) public view override returns (uint256 purePrice) {
        purePrice = getQiTokenExchangeRate(_qiTokenAddress);
        return purePrice;
    }

     /**
     * @dev get compound price for a single tranche scaled by 1e18
     * @param _qiTokenAddress qiToken address
     * @param _underDecs underlying decimals
     * @param _qiTokenDecs qiToken decimalsr
     * @return normPrice compound current normalized price
     */
    function getBenQiPriceHelper(address _qiTokenAddress, uint256 _underDecs, uint256 _qiTokenDecs) public view override returns (uint256 normPrice) {
        normPrice = getBenQiPurePriceHelper(_qiTokenAddress);

        uint256 mantissa = getMantissaHelper(_underDecs, _qiTokenDecs);
        if (mantissa < 18) {
            normPrice = normPrice.mul(10 ** (uint256(18).sub(mantissa)));
        } else {
            normPrice = normPrice.div(10 ** (mantissa.sub(uint256(18))));
        }
        return normPrice;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQiErc20 {
    function mint(uint256) external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function setExchangeRateStored(uint256 rate) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBenQiHelper {
    // function sendErc20ToCompoundHelper(address _underToken, address _cToken, uint256 _numTokensToSupply) external returns(uint256);
    // function redeemQiErc20TokensHelper(address _cToken, uint256 _amount, bool _redeemType) external returns (uint256 redeemResult);

    function getMantissaHelper(uint256 _underDecs, uint256 _cTokenDecs) external pure returns (uint256 mantissa);
    function getBenQiPurePriceHelper(address _cTokenAddress) external view returns (uint256 compoundPrice);
    function getBenQiPriceHelper(address _cTokenAddress, uint256 _underDecs, uint256 _cTokenDecs) external view returns (uint256 compNormPrice);
}