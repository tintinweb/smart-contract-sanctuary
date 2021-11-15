// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOilerOptionBaseFactory} from "./interfaces/IOilerOptionBaseFactory.sol";
import {IOilerOptionBase} from "./interfaces/IOilerOptionBase.sol";
import {IOilerOptionsRouter} from "./interfaces/IOilerOptionsRouter.sol";

contract OilerRegistry is Ownable {
    uint256 public constant PUT = 1;
    uint256 public constant CALL = 0;

    /**
     * @dev Active options store, once the option expires the mapping keys are replaced.
     * option type => option contract.
     */
    mapping(bytes32 => address[2]) public activeOptions;

    /**
     * @dev Archived options store.
     * Once an option expires and is replaced it's pushed to an array under it's type key.
     * option type => option contracts.
     */
    mapping(bytes32 => address[]) public archivedOptions;

    /**
     * @dev Stores supported types of options.
     */
    bytes32[] public optionTypes; // Array of all option types ever registered

    /**
     * @dev Indicates who's the factory of specific option types.
     * option type => factory.
     */
    mapping(bytes32 => address) public factories;

    IOilerOptionsRouter public optionsRouter;

    constructor(address _owner) Ownable() {
        Ownable.transferOwnership(_owner);
    }

    function registerOption(address _optionAddress, string memory _optionType) external {
        require(address(optionsRouter) != address(0), "OilerRegistry.registerOption: router not set");
        bytes32 optionTypeHash = keccak256(abi.encodePacked(_optionType));
        // Check if caller is factory registered for current option.
        require(factories[optionTypeHash] == msg.sender, "OilerRegistry.registerOption: not a factory."); // Ensure that contract under address is an option.
        require(
            IOilerOptionBaseFactory(msg.sender).isClone(_optionAddress),
            "OilerRegistry.registerOption: invalid option contract."
        );
        uint256 optionDirection = IOilerOptionBase(_optionAddress).put() ? PUT : CALL;
        // Ensure option is not being registered again.
        require(
            _optionAddress != activeOptions[optionTypeHash][optionDirection],
            "OilerRegistry.registerOption: option already registered"
        );
        // Ensure currently set option is expired.
        if (activeOptions[optionTypeHash][optionDirection] != address(0)) {
            require(
                !IOilerOptionBase(activeOptions[optionTypeHash][optionDirection]).isActive(),
                "OilerRegistry.registerOption: option still active"
            );
        }
        archivedOptions[optionTypeHash].push(activeOptions[optionTypeHash][optionDirection]);
        activeOptions[optionTypeHash][optionDirection] = _optionAddress;
        optionsRouter.setUnlimitedApprovals(IOilerOptionBase(_optionAddress));
    }

    function setOptionsTypeFactory(string memory _optionType, address _factory) external onlyOwner {
        bytes32 optionTypeHash = keccak256(abi.encodePacked(_optionType));
        require(_factory != address(0), "Cannot set factory to 0x0");
        require(factories[optionTypeHash] != address(0), "OptionType wasn't yet registered");
        if (_factory != address(uint256(-1))) {
            // Send -1 if you want to remove the factory and disable this optionType
            require(
                optionTypeHash ==
                    keccak256(
                        abi.encodePacked(
                            IOilerOptionBase(IOilerOptionBaseFactory(_factory).optionLogicImplementation()).optionType()
                        )
                    ),
                "The factory is for different optionType"
            );
        }
        factories[optionTypeHash] = _factory;
    }

    function registerFactory(address factory) external onlyOwner {
        bytes32 optionTypeHash = keccak256(
            abi.encodePacked(
                IOilerOptionBase(IOilerOptionBaseFactory(factory).optionLogicImplementation()).optionType()
            )
        );
        require(factories[optionTypeHash] == address(0), "The factory for this OptionType was already registered");
        factories[optionTypeHash] = factory;
        optionTypes.push(optionTypeHash);
    }

    function setOptionsRouter(IOilerOptionsRouter _optionsRouter) external onlyOwner {
        optionsRouter = _optionsRouter;
    }

    function getOptionTypesLength() external view returns (uint256) {
        return optionTypes.length;
    }

    function getOptionTypeAt(uint256 _index) external view returns (bytes32) {
        return optionTypes[_index];
    }

    function getOptionTypeFactory(string memory _optionType) external view returns (address) {
        return factories[keccak256(abi.encodePacked(_optionType))];
    }

    function getAllArchivedOptionsOfType(bytes32 _optionType) external view returns (address[] memory) {
        return archivedOptions[_optionType];
    }

    function getAllArchivedOptionsOfType(string memory _optionType) external view returns (address[] memory) {
        return archivedOptions[keccak256(abi.encodePacked(_optionType))];
    }

    function checkActive(string memory _optionType) public view returns (bool, bool) {
        bytes32 id = keccak256(abi.encodePacked(_optionType));
        return checkActive(id);
    }

    function checkActive(bytes32 _optionType) public view returns (bool, bool) {
        return (
            activeOptions[_optionType][CALL] != address(0)
                ? IOilerOptionBase(activeOptions[_optionType][CALL]).isActive()
                : false,
            activeOptions[_optionType][PUT] != address(0)
                ? IOilerOptionBase(activeOptions[_optionType][PUT]).isActive()
                : false
        );
    }

    function getActiveOptions(bytes32 _optionType) public view returns (address[2] memory result) {
        (bool isCallActive, bool isPutActive) = checkActive(_optionType);

        if (isCallActive) {
            result[0] = activeOptions[_optionType][0];
        }

        if (isPutActive) {
            result[1] = activeOptions[_optionType][1];
        }
    }

    function getActiveOptions(string memory _optionType) public view returns (address[2] memory result) {
        return getActiveOptions(keccak256(abi.encodePacked(_optionType)));
    }

    function getArchivedOptions(bytes32 _optionType) public view returns (address[] memory result) {
        (bool isCallActive, bool isPutActive) = checkActive(_optionType);

        uint256 extraLength = 0;
        if (!isCallActive) {
            extraLength++;
        }
        if (!isPutActive) {
            extraLength++;
        }

        uint256 archivedLength = getArchivedOptionsLength(_optionType);

        result = new address[](archivedLength + extraLength);

        for (uint256 i = 0; i < archivedLength; i++) {
            result[i] = archivedOptions[_optionType][i];
        }

        uint256 cursor;
        if (!isCallActive) {
            result[archivedLength + cursor++] = activeOptions[_optionType][0];
        }

        if (!isPutActive) {
            result[archivedLength + cursor++] = activeOptions[_optionType][1];
        }

        return result;
    }

    function getArchivedOptions(string memory _optionType) public view returns (address[] memory result) {
        return getArchivedOptions(keccak256(abi.encodePacked(_optionType)));
    }

    function getArchivedOptionsLength(string memory _optionType) public view returns (uint256) {
        return archivedOptions[keccak256(abi.encodePacked(_optionType))].length;
    }

    function getArchivedOptionsLength(bytes32 _optionType) public view returns (uint256) {
        return archivedOptions[_optionType].length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IOilerOptionBaseFactory {
    function optionLogicImplementation() external view returns (address);

    function isClone(address _query) external view returns (bool);

    function createOption(
        uint256 _strikePrice,
        uint256 _expiryTS,
        bool _put,
        address _collateral,
        uint256 _collateralToPushIntoAmount,
        uint256 _optionsToPushIntoPool
    ) external returns (address optionAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";
import {IOilerCollateral} from "./IOilerCollateral.sol";

interface IOilerOptionBase is IERC20, IERC20Permit {
    function optionType() external view returns (string memory);

    function collateralInstance() external view returns (IOilerCollateral);

    function isActive() external view returns (bool active);

    function hasExpired() external view returns (bool);

    function hasBeenExercised() external view returns (bool);

    function put() external view returns (bool);

    function write(uint256 _amount) external;

    function write(uint256 _amount, address _writer) external;

    function write(
        uint256 _amount,
        address _writer,
        address _holder
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./IOilerOptionBase.sol";
import "./IOilerRegistry.sol";
import "./IBRouter.sol";

interface IOilerOptionsRouter {
    // TODO add expiration?
    struct Permit {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function registry() external view returns (IOilerRegistry);

    function bRouter() external view returns (IBRouter);

    function setUnlimitedApprovals(IOilerOptionBase _option) external;

    function write(IOilerOptionBase _option, uint256 _amount) external;

    function write(
        IOilerOptionBase _option,
        uint256 _amount,
        Permit calldata _permit
    ) external;

    function writeAndAddLiquidity(
        IOilerOptionBase _option,
        uint256 _amount,
        uint256 _liquidityProviderCollateralAmount
    ) external;

    function writeAndAddLiquidity(
        IOilerOptionBase _option,
        uint256 _amount,
        uint256 _liquidityProviderCollateralAmount,
        Permit calldata _writePermit,
        Permit calldata _liquidityAddPermit
    ) external;
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

pragma solidity ^0.7.0;

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

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";

interface IOilerCollateral is IERC20, IERC20Permit {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./IOilerOptionsRouter.sol";

interface IOilerRegistry {
    function PUT() external view returns (uint256);

    function CALL() external view returns (uint256);

    function activeOptions(bytes32 _type) external view returns (address[2] memory);

    function archivedOptions(bytes32 _type, uint256 _index) external view returns (address);

    function optionTypes(uint256 _index) external view returns (bytes32);

    function factories(bytes32 _optionType) external view returns (address);

    function optionsRouter() external view returns (IOilerOptionsRouter);

    function getOptionTypesLength() external view returns (uint256);

    function getOptionTypeAt(uint256 _index) external view returns (bytes32);

    function getArchivedOptionsLength(string memory _optionType) external view returns (uint256);

    function getArchivedOptionsLength(bytes32 _optionType) external view returns (uint256);

    function getOptionTypeFactory(string memory _optionType) external view returns (address);

    function getAllArchivedOptionsOfType(string memory _optionType) external view returns (address[] memory);

    function getAllArchivedOptionsOfType(bytes32 _optionType) external view returns (address[] memory);

    function registerFactory(address factory) external;

    function setOptionsTypeFactory(string memory _optionType, address _factory) external;

    function registerOption(address _optionAddress, string memory _optionType) external;

    function setOptionsRouter(IOilerOptionsRouter _optionsRouter) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IBPool} from "./IBPool.sol";

interface IBRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256 poolTokens);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 poolAmountIn
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function getPoolByTokens(address tokenA, address tokenB) external view returns (IBPool pool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IBPool {
    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function balanceOf(address whom) external view returns (uint256);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function finalize() external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function setSwapFee(uint256 swapFee) external;

    function setPublicSwap(bool publicSwap) external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function isBound(address token) external view returns (bool);

    function getBalance(address token) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function isPublicSwap() external view returns (bool);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function EXIT_FEE() external view returns (uint256);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountIn);

    function getCurrentTokens() external view returns (address[] memory tokens);
}

