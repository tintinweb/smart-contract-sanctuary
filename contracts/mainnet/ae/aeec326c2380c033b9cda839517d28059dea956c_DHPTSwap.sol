/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020-2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//

// File: contracts/ISynthetix.sol

pragma solidity ^0.6.2;

interface ISynthetix {
    function exchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint256 amountReceived);

    function synths(bytes32 key)
        external
        view
        returns (address synthTokenAddress);

    function settle(bytes32 currencyKey)
        external
        returns (
            uint256 reclaimed,
            uint256 refunded,
            uint256 numEntriesSettled
        );
}

// File: contracts/ISynth.sol

pragma solidity ^0.6.2;

interface ISynth {
    function proxy() external view returns (address);

    // Mutative functions
    function transferAndSettle(address to, uint256 value)
        external
        returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File: contracts/IAddressResolver.sol

pragma solidity ^0.6.2;

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);
}

// File: contracts/IExchanger.sol

pragma solidity ^0.6.2;

interface IExchanger {

    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint);

    function settlementOwing(address account, bytes32 currencyKey)
        external
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries
        );

}

// File: contracts/IExchangeRates.sol

pragma solidity ^0.6.2;

interface IExchangeRates {
    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256);

    function rateForCurrency(bytes32 currencyKey)
        external
        view
        returns (uint256);
}

// File: contracts/IDHedge.sol

pragma solidity ^0.6.2;

interface IDHedge {

    function totalSupply() external view returns (uint256);
    function getSupportedAssets() external view returns (bytes32[] memory);
    function assetValue(bytes32 key) external view returns (uint256);
    function getAssetProxy(bytes32 key) external view returns (address);
    function setLastDeposit(address investor) external;
    function tokenPriceAtLastFeeMint() external view returns (uint256);
    function availableManagerFee() external view returns (uint256);
}

// File: contracts/IPoolDirectory.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//

pragma solidity ^0.6.2;

interface IPoolDirectory {
    function isPool(address pool) external view returns (bool);
}

// File: contracts/IHasFeeInfo.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//

pragma solidity ^0.6.2;

interface IHasFeeInfo {
    // Manager fee
    function getPoolManagerFee(address pool) external view returns (uint256, uint256);
    function setPoolManagerFeeNumerator(address pool, uint256 numerator) external;

    function getMaximumManagerFeeNumeratorChange() external view returns (uint256);
    function getManagerFeeNumeratorChangeDelay() external view returns (uint256);
   
    // Exit fee
    function getExitFee() external view returns (uint256, uint256);
    function getExitFeeCooldown() external view returns (uint256);

    // Synthetix tracking
    function getTrackingCode() external view returns (bytes32);
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


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

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
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

    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/cryptography/ECDSA.sol

pragma solidity ^0.6.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: contracts/DHPTSwap.sol

pragma solidity ^0.6.2;














contract DHPTSwap is Initializable, OwnableUpgradeSafe {
    using SafeMath for uint256;

    IAddressResolver public addressResolver;
    address public factory;
    address public oracle;

    bool public enableBuy;
    bool public enableSell;
    bool public enableOracleBuy;
    bool public enableOracleSell;
    
    uint8 public oracleBlockBias;

    mapping(address => uint256) public dhptWhitelist;

    bytes32 private constant _EXCHANGE_RATES_KEY = "ExchangeRates";
    bytes32 private constant _EXCHANGER_KEY = "Exchanger";
    bytes32 private constant _SYNTHETIX_KEY = "Synthetix";
    bytes32 private constant _SUSD_KEY = "sUSD";
    address public dao;
    mapping(bytes32 => bool) public dhptFromEnabled;
    mapping(address => uint8) public stableCoins;

    event SellDHPT(
        address fundAddress,
        address investor,
        uint256 susdAmount,
        uint256 dhptAmount,
        uint256 tokenPrice,
        uint256 time,
        bool oracleSwap
    );

    event BuyDHPT(
        address fundAddress,
        address investor,
        uint256 susdAmount,
        uint256 dhptAmount,
        uint256 tokenPrice,
        uint256 time,
        bool oracleSwap
    );

    event SwapDHPT(
        address fundAddressA,
        uint256 tokenPriceA,
        uint256 amountA,
        address fundAddressB,
        uint256 tokenPriceB,
        uint256 amountB,
        address investor,
        uint256 time,
        bool oracleSwap
    );

    function initialize(IAddressResolver _addressResolver, address _factory, address _oracle) public initializer {
        OwnableUpgradeSafe.__Ownable_init();

        enableBuy = true;
        enableSell = true;
        enableOracleBuy = false;
        enableOracleSell = false;

        addressResolver = _addressResolver;
        factory = _factory;
        oracle = _oracle;
        oracleBlockBias = 25;
    }

    function setStableCoin(address stableCoin, uint8 tokenPrecision) public onlyOwner {
        stableCoins[stableCoin] = tokenPrecision;
    }

    // BUY & SELL

    // user selling DHPT for sUSD
    function sellDHPT(address poolAddress, uint256 dhptAmount, address stableCoin) public {
        uint8 stableCoinPrecision = stableCoins[stableCoin];
        require(stableCoinPrecision > 0, "selected stable coin is disabled");

        require(enableSell, "sell disabled");
        require(_canSellDhpt(poolAddress, dhptAmount), "unable to sell tokens");
        require(dhptAmount > 10000, "amount too small");
       
        uint256 poolPrice = tokenPriceWithSettle(poolAddress);
        require(poolPrice > 0, "poolPrice is not valid value");

        require(
            IERC20(poolAddress).transferFrom(
                msg.sender,
                address(this),
                dhptAmount
            ),
            "token transfer failed"
        );

        uint256 precisionDiff = uint(18+18-stableCoinPrecision);
        uint256 stableCoinAmount = dhptAmount.mul(poolPrice).div(10**uint(precisionDiff));

        require(
            IERC20(stableCoin).transfer(
                msg.sender, stableCoinAmount
            ),
            "stable coin transfer failed"
        );
        
        emit SellDHPT(
            poolAddress,
            msg.sender,
            stableCoinAmount,
            dhptAmount,
            poolPrice,
            block.timestamp,
            false
        );
    }

    // user buying DHPT for sUSD. consider DHPT 24h lockup
    function buyDHPT(address poolAddress, address stableCoin, uint256 stableCoinAmount) public {
        uint8 stableCoinPrecision = stableCoins[stableCoin];
        require(stableCoinPrecision > 0, "selected stable coin is disabled");
        
        require(enableBuy, "buy disabled");
        require(dhptWhitelist[poolAddress] > 0, "pool not whitelisted");
        require(stableCoinAmount > 10000, "amount too small");

        uint256 poolPrice = tokenPriceWithSettle(poolAddress);
        uint256 precisionDiff = uint(18+18-stableCoinPrecision);
        uint256 dhptAmount = stableCoinAmount.mul(10**uint(precisionDiff)).div(poolPrice);
        IDHedge(poolAddress).setLastDeposit(msg.sender);
        
        require(
            IERC20(stableCoin).transferFrom(
                msg.sender,
                address(this),
                stableCoinAmount
            ),
            "stable coin transfer failed"
        );
      
        require(
            IERC20(poolAddress).transfer(msg.sender, dhptAmount),
            "pool-token transfer failed"
        );

        emit BuyDHPT(
            poolAddress,
            msg.sender,
            stableCoinAmount,
            dhptAmount,
            poolPrice,
            block.timestamp,
            false
        );
    }
    
    // user buying DHPT for sUSD. consider DHPT 24h lockup
    function swapDHPT(address poolAddressA, uint256 poolAmountA, address poolAddressB) public {
       require(enableBuy, "buy disabled");
       require(enableSell, "sell disabled");
       require(dhptWhitelist[poolAddressA] > 0, "from-token not whitelisted");
       require(poolAmountA > 10000, "amount too small");
       require(dhptWhitelist[poolAddressB] > 0, "to-token not whitelisted");

       uint256 poolPriceA = tokenPriceWithSettle(poolAddressA);
       uint256 sUsdAmount = poolAmountA.mul(poolPriceA).div(10**18);

       uint256 poolPriceB = tokenPriceWithSettle(poolAddressB);
       uint256 poolAmountB = sUsdAmount.mul(10**18).div(poolPriceB);
       IDHedge(poolAddressB).setLastDeposit(msg.sender);

        require(
            IERC20(poolAddressA).transferFrom(
                msg.sender,
                address(this),
                poolAmountA
            ),
            "from-token transfer failed"
        );
      
        require(
            IERC20(poolAddressB).transfer(msg.sender, poolAmountB),
            "to-token transfer failed"
        );

        emit SwapDHPT(
            poolAddressA,
            poolPriceA,
            poolAmountA,
            poolAddressB,
            poolPriceB,
            poolAmountB,
            msg.sender,
            block.timestamp,
            false
        );
    }
    

    // ORACLE FUNCTIONS
    
    function oracleBuyDHPT(address poolAddress, address stableCoin, uint256 stableCoinAmount, uint256 blockNumber, uint256 poolPrice, bytes memory signature)
       public
    {
        _requireOracle(enableOracleBuy, stableCoinAmount, blockNumber);
        uint8 stableCoinPrecision = stableCoins[stableCoin];
        require(stableCoinPrecision > 0, "selected stable coin is disabled");
        
        require(dhptWhitelist[poolAddress] > 0, "pool not whitelisted");
        require(_isOracleSigValid(msg.sender, blockNumber, poolAddress, poolPrice, stableCoinAmount, signature), "signature invalid");
        uint256 precisionDiff = uint(18+18-stableCoinPrecision);
        uint256 dhptAmount = stableCoinAmount.mul(10**uint(precisionDiff)).div(poolPrice);
        IDHedge(poolAddress).setLastDeposit(msg.sender);
        
        require(
            IERC20(stableCoin).transferFrom(
                msg.sender,
                address(this),
                stableCoinAmount
            ),
            "stable coin transfer failed"
        );

        require(
            IERC20(poolAddress).transfer(msg.sender, dhptAmount),
            "token transfer failed"
        );

        emit BuyDHPT(
            poolAddress,
            msg.sender,
            stableCoinAmount,
            dhptAmount,
            poolPrice,
            block.timestamp,
            true
        );
        
    }
    
    function oracleSellDHPT(address poolAddress, address stableCoin, uint256 dhptAmount, uint256 blockNumber, uint256 poolPrice, bytes memory signature)
       public
    {
        _requireOracle(enableOracleSell, dhptAmount, blockNumber);
        uint8 stableCoinPrecision = stableCoins[stableCoin];
        require(stableCoinPrecision > 0, "selected stable coin is disabled");        
        require(_canSellDhpt(poolAddress, dhptAmount), "unable to sell tokens");
       
        uint256 precisionDiff = uint(18+18-stableCoinPrecision);
        uint256 stableCoinAmount = dhptAmount.mul(poolPrice).div(10**uint(precisionDiff));
        require(_isOracleSigValid(msg.sender, blockNumber, poolAddress, poolPrice, stableCoinAmount, signature), "signature invalid");
        
        require(
            IERC20(poolAddress).transferFrom(
                msg.sender,
                address(this),
                dhptAmount
            ),
            "token transfer failed"
        );

       
        require(
            IERC20(stableCoin).transfer(
                msg.sender, stableCoinAmount
            ),
            "stable coin transfer failed"
        );

        emit SellDHPT(
            poolAddress,
            msg.sender,
            stableCoinAmount,
            dhptAmount,
            poolPrice,
            block.timestamp,
            true
        );
    }

    // oracle swap buy DHPT from external sources of DHPT liquidity
    function oracleBuyDHPTFrom(address poolAddress, address fromAddress, uint256 susdAmount, uint256 blockNumber, uint256 poolPrice, bytes memory signature) 
        public
    {
        _requireOracle(enableOracleBuy, susdAmount, blockNumber);
        require(_isOracleSigValid(msg.sender, blockNumber, poolAddress, poolPrice, susdAmount, signature), "signature invalid");
        require(dhptWhitelist[poolAddress] > 0, "pool not whitelisted");

        uint256 dhptAmount = susdAmount.mul(10**18).div(poolPrice);
        require(_dhptFromEnabled(poolAddress, fromAddress), "source liquidity disabled");
        IDHedge(poolAddress).setLastDeposit(msg.sender);

        require(
            IERC20(_getAssetProxy(_SUSD_KEY)).transferFrom(
                msg.sender,
                fromAddress,
                susdAmount
            ),
            "susd transfer failed"
        );

        require(
            IERC20(poolAddress).transferFrom(
                fromAddress,
                msg.sender,
                dhptAmount
            ),
            "token transfer failed"
        );

        emit BuyDHPT(
            poolAddress,
            msg.sender,
            susdAmount,
            dhptAmount,
            poolPrice,
            block.timestamp,
            true
        );
    }

    function oracleSwapDHPT(address poolAddressA, uint256 poolAmountA, uint256 poolPriceA, address poolAddressB,
                             uint256 poolPriceB, uint256 blockNumber, bytes memory signature)
        public
    {
        _requireOracle(enableOracleBuy && enableOracleSell, poolAmountA, blockNumber);
        require(_canSellDhpt(poolAddressA, poolAmountA), "unable to sell tokens");
        require(dhptWhitelist[poolAddressB] > 0, "pool not whitelisted");

       //swap logic starts here
       require(_isOracleSwapSigValid(msg.sender, blockNumber, poolAddressA, poolPriceA, poolAmountA, poolAddressB, poolPriceB, signature), "signature invalid");

        require(
            IERC20(poolAddressA).transferFrom(
                msg.sender,
                address(this),
                poolAmountA
            ),
            "from-token transfer failed"
        );

        uint256 poolAmountB = (poolAmountA.mul(poolPriceA)).div(poolPriceB);

        require(
            IERC20(poolAddressB).transfer(msg.sender, poolAmountB),
            "to-token transfer failed"
        );

        emit SwapDHPT(
            poolAddressA,
            poolPriceA,
            poolAmountA,
            poolAddressB,
            poolPriceB,
            poolAmountB,
            msg.sender,
            block.timestamp,
            true
        );
    }

    function _requireOracle(bool enableOracle, uint256 amount, uint256 blockNumber)
        internal
        view
    {
        require(blockNumber.add(oracleBlockBias) > block.number, "transaction timed out");
        require(enableOracle, "oracle disabled");
        require(amount > 10000, "amount too small");
        require(blockNumber <= block.number, "invalid block number");
    }
    
    function _isOracleSigValid(address sender, uint256 blockNumber, address poolAddress, uint256 poolPrice, uint256 amount, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(abi.encodePacked(sender, blockNumber, poolAddress, poolPrice, amount));
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(hash);
        
        if (ECDSA.recover(ethHash, signature) == oracle) {
            return true;
        } else {
            return false;
        }
    }

    function _isOracleSwapSigValid(address sender, uint256 blockNumber, address poolAddressA, uint256 poolPriceA, uint256 poolAmountA, address poolAddressB, uint256 poolPriceB, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(abi.encodePacked(sender, blockNumber, poolAddressA, poolPriceA, poolAmountA, poolAddressB, poolPriceB ));
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(hash);
        
        if (ECDSA.recover(ethHash, signature) == oracle) {
            return true;
        } else {
            return false;
        }
    }

    function dhptFromLiquidity(address poolAddress, address fromAddress)
    public
    view
    returns (uint256)
    {
        if (_dhptFromEnabled(poolAddress, fromAddress)) {
            return IERC20(poolAddress).allowance(fromAddress, address(this));
        } else {
            return 0;
        }
    }

    function enableLiquidity(address[] memory poolAddresses, bool[] memory enabled)
        public
    {
        require(poolAddresses.length == enabled.length, "invalid input lengths");

        for (uint256 i = 0; i < poolAddresses.length; i++) {
            bytes32 hash = keccak256(abi.encodePacked(poolAddresses[i], msg.sender));
            dhptFromEnabled[hash] = enabled[i];
        }
    }

    function _dhptFromEnabled(address poolAddress, address fromAddress)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(abi.encodePacked(poolAddress, fromAddress));
        return dhptFromEnabled[hash];
    }


    // ADMIN

    // whitelist dHEDGE pools the contract will accept tokens from
    function whitelistDhpt(address[] memory addresses, uint256[] memory amounts)
        public
        onlyOwner
    {
        require(addresses.length == amounts.length, "invalid input lengths");

        for (uint256 i = 0; i < addresses.length; i++) {
            require(IPoolDirectory(factory).isPool(addresses[i]), "not a pool");

            dhptWhitelist[addresses[i]] = amounts[i];
        }
    }

    function setAddressResolver(IAddressResolver _addressResolver)
        public
        onlyOwner
    {
        addressResolver = _addressResolver;
    }
    
    function setFactory(address _factory)
        public
        onlyOwner
    {
        factory = _factory;
    }

    function setDao(address _dao)
        public
        onlyOwner
    {
        dao = _dao;
    }
    
    function setOracle(address _oracle)
        public
        onlyOwner
    {
        oracle = _oracle;
    }
    
    function setOracleBlockBias(uint8 _oracleBlockBias)
        public
        onlyOwner
    {
        oracleBlockBias = _oracleBlockBias;
    }

    function withdrawToken(address tokenAddress, uint256 amount)
        public
        onlyDao
    {
        require(
            IERC20(tokenAddress).transfer(
                dao,
                amount
            ),
            "token transfer failed"
        );
    }

    function withdrawTokenTo(address tokenAddress, uint256 amount, address toAddress)
        public
        onlyDao
    {
        require(
            IERC20(tokenAddress).transfer(
                toAddress,
                amount
                ),
            "token transfer failed"
            );
    }

    function enableBuySell(bool _enableBuy, bool _enableSell, bool _enableOracleBuy, bool _enableOracleSell)
        public
        onlyOwner
    {
        enableBuy = _enableBuy;
        enableSell = _enableSell;
        enableOracleBuy = _enableOracleBuy;
        enableOracleSell = _enableOracleSell;
    }
    

    // VIEWS

    function _canSellDhpt(address poolAddress, uint256 dhptAmount)
        internal
        view
        returns (bool)
    {
        uint256 dhptBalance = tokenBalanceOf(poolAddress);
        if (dhptWhitelist[poolAddress] >= dhptBalance.add(dhptAmount)) {
            return true;
        } else {
            return false;
        }
    }

    function tokenBalanceOf(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function _availDhptToSell(address poolAddress)
        internal
        view
        returns (uint256)
    {
        uint256 dhptBalance = tokenBalanceOf(poolAddress);
        return dhptWhitelist[poolAddress].sub(dhptBalance);
    }

    // maximum DHPT that can be sold by the user taking into account contract sUSD balance
    function maxDhptToSell(address poolAddress) public view returns (uint256) {
        uint256 availDhpt = _availDhptToSell(poolAddress);
        uint256 susdBalance = IERC20(_getAssetProxy(_SUSD_KEY)).balanceOf(
            address(this)
        );
        uint256 poolPrice = tokenPriceWithSettle(poolAddress);
        require(poolPrice > 0, "invalid pool price");
        // how much DHPT the contract can buy with its sUSD balance
        uint256 susdForDhpt = susdBalance.mul(10**18).div(poolPrice);

        if (susdForDhpt > availDhpt) {
            return availDhpt;
        } else {
            return susdForDhpt;
        }
    }

    // maximum sUSD that can be sold by the user taking into account contract DHPT balance
    function maxSusdToSell(address poolAddress) public view returns (uint256) {
        uint256 dhptBalance = IERC20(poolAddress).balanceOf(address(this));
        uint256 poolPrice = tokenPriceWithSettle(poolAddress);
        require(poolPrice > 0, "invalid pool price");
        // how much sUSD the contract can buy with its DHPT balance
        uint256 dhptForSusd = dhptBalance.mul(poolPrice).div(10**18);

        return dhptForSusd;
    }

    // returns token price accounting for any pending Synthetix settlement amounts and manager fees
    function tokenPriceWithSettle(address poolAddress)
        public
        view
        returns (uint256)
    {
        IDHedge dhpool = IDHedge(poolAddress);
        IExchanger ex = IExchanger(addressResolver.getAddress(_EXCHANGER_KEY));

        uint256 totalValue = 0;
        bytes32[] memory supportedAssets = dhpool.getSupportedAssets();
        uint256 totalSupply = dhpool.totalSupply();

        require(totalSupply > 0, "pool is empty");

        for (uint256 i = 0; i < supportedAssets.length; i++) {
            uint256 assetTotal = IERC20(_getAssetProxy(supportedAssets[i]))
                .balanceOf(poolAddress);

            if (assetTotal > 0) {
                uint256 waitingPeriod = ex.maxSecsLeftInWaitingPeriod(
                    poolAddress,
                    supportedAssets[i]
                );
                require(waitingPeriod == 0, "wait for settlement");

                (
                    uint256 reclaimAmount,
                    uint256 rebateAmount,
                    /*uint256 entries*/
                ) = ex.settlementOwing(poolAddress, supportedAssets[i]);

                if (rebateAmount > 0) {
                    assetTotal = assetTotal.add(rebateAmount);
                }
                if (reclaimAmount > 0) {
                    assetTotal = assetTotal.sub(reclaimAmount);
                }

                IExchangeRates exchangeRates = IExchangeRates(
                    addressResolver.getAddress(_EXCHANGE_RATES_KEY)
                );
                totalValue = totalValue.add(
                    exchangeRates
                        .rateForCurrency(supportedAssets[i])
                        .mul(assetTotal)
                        .div(10**18)
                );
            }
        }
        uint256 lastFeeMintPrice = dhpool.tokenPriceAtLastFeeMint();
        uint256 tokenPrice = totalValue.mul(10**18).div(totalSupply);

        if (lastFeeMintPrice.add(1000) < tokenPrice) {
            return tokenPrice.mul(totalSupply).div(_getTotalSupplyPostMint(poolAddress, tokenPrice, lastFeeMintPrice, totalSupply));
        } else {
            return tokenPrice;
        }
    }
    
    // token price at which the manager's fee was last minted
    function getLastFeeMintPrice(address poolAddress) public view returns (uint256) {
        IDHedge dhpool = IDHedge(poolAddress);
        return dhpool.tokenPriceAtLastFeeMint();
    }

    // token supply after manager fee minting
    function _getTotalSupplyPostMint(address poolAddress, uint256 tokenPrice, uint256 lastFeeMintPrice, uint256 totalSupply) internal view returns (uint256) {
        uint256 managerFeeNumerator;
        uint256 managerFeeDenominator;
        (managerFeeNumerator, managerFeeDenominator) = IHasFeeInfo(factory).getPoolManagerFee(poolAddress);
        uint256 priceFraction = tokenPrice.sub(lastFeeMintPrice).mul(managerFeeNumerator).div(managerFeeDenominator);
        return priceFraction.mul(totalSupply).div(tokenPrice).add(totalSupply);
    }

    function _getAssetProxy(bytes32 key) internal view returns (address) {
        address synth = ISynthetix(addressResolver.getAddress(_SYNTHETIX_KEY))
            .synths(key);
        require(synth != address(0), "invalid key");
        address proxy = ISynth(synth).proxy();
        require(proxy != address(0), "invalid proxy");
        return proxy;
    }

    // MODIFIERS
    modifier onlyDao() {
        require(msg.sender == dao, "only dao");
        _;
    }

}