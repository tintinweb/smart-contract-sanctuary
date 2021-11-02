pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./IOracle.sol";
import "./IDtecT.sol";

contract SwapWithOracles is Ownable, ERC2771Context {

    address private _platform;

    struct Pair {
        IOracle oracle;
        address provider;
        uint256 commission;
        bool exist;
    }

    mapping (bytes32 => Pair)  private _pairs;

    uint256 public constant COMMISSION_EXPONENT = 1000000;

    event Swap(IOracle indexed oracleAddress, uint256 indexed oracleRoundId, bytes32 indexed platformCommission);
    event PairUpdate(IDtecT indexed fromToken, IDtecT indexed toToken);
    event PairRemove(IDtecT indexed fromToken, IDtecT indexed toToken);

    constructor(address admin, address forwarder, address platform_) ERC2771Context(forwarder) Ownable(){
        transferOwnership(admin);
        _platform = platform_;
    }

    function getOracleHash(IDtecT fromToken, IDtecT toToken) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(fromToken, toToken));
    }

    function addPair(IDtecT fromToken, IDtecT toToken, IOracle oracle, address provider, uint256 commission) external onlyOwner {
        bytes32 oracleHash = getOracleHash(fromToken, toToken);
        require(!_pairs[oracleHash].exist, "Defined");
        _pairs[oracleHash] = Pair(oracle, provider, commission, true);
        emit PairUpdate(fromToken, toToken);
    }

    function removePair(IDtecT fromToken, IDtecT toToken) external onlyOwner {
        bytes32 oracleHash = getOracleHash(fromToken, toToken);
        Pair storage pair =  _pairs[oracleHash];
        require(pair.exist, "Undefined");
        pair.provider = address(0x0);
        pair.oracle = IOracle(pair.provider);
        pair.commission = 0;
        pair.exist = false;
        emit PairRemove(fromToken, toToken);
    }

    function getPair(IDtecT fromToken, IDtecT toToken) external view returns (IOracle oracle, address provider, uint256 commission) {
        bytes32 oracleHash = getOracleHash(fromToken, toToken);
        Pair memory pair_ = _pairs[oracleHash];
        require(pair_.exist, "Undefined");
        oracle = pair_.oracle;
        provider = pair_.provider;
        commission = pair_.commission;
    }

    function updatePair(IDtecT fromToken, IDtecT toToken, IOracle oracle, address provider, uint256 commission) external onlyOwner {
        bytes32 oracleHash = getOracleHash(fromToken, toToken);
        Pair storage pair = _pairs[oracleHash];
        require(pair.exist, "Undefined");
        pair.oracle = oracle;
        pair.provider = provider;
        pair.commission = commission;
        emit PairUpdate(fromToken, toToken);
    }

    function swap(IDtecT fromToken, IDtecT toToken, uint256 fromAmount, uint80 oracleRoundId, bytes32 operationId) external {
        bytes32 oracleHash = getOracleHash(fromToken, toToken);
        Pair memory pair_ = _pairs[oracleHash];
        require(pair_.exist, "Undefined");

        (uint80 roundID, int answer, uint8 decimals) = pair_.oracle.getLastRound();
        require(oracleRoundId == roundID, "Outdated round");

        uint256 price = uint256(answer);
        uint256 platformCommission = (fromAmount * pair_.commission) / COMMISSION_EXPONENT;
        uint256 toAmount = (fromAmount * 10 ** decimals) / price;

        fromToken.operateTransferFrom(_msgSender(), pair_.provider, fromAmount);
        toToken.transferFrom(pair_.provider, _msgSender(), toAmount);
        fromToken.operateTransferFrom(_msgSender(), _platform, platformCommission);

        emit Swap(pair_.oracle, oracleRoundId, operationId);
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function platform() external view returns(address) {
        return _platform;
    }

    function setPlatform(address platform_) external onlyOwner {
        _platform = platform_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address private _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function getLastRound() external view returns (uint80 roundId, int256 answer, uint8 decimals);
}

// contracts/DtecT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDtecT is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function operateTransferFrom(address sender, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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