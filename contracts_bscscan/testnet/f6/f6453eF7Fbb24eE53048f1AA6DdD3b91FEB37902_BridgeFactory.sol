// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Bridge.sol";
import "./interfaces/IBridgeFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BridgeFactory is Ownable, IBridgeFactory {
    bytes32 public constant override INIT_CODE_HASH = keccak256(abi.encodePacked(type(Bridge).creationCode));

    address[] public override allBridges;
    address public override feeTo;

    mapping(bytes32 => address) public override saltToAddress;
    mapping(address => uint256) public override bridgeToIdx;

    function allBridgesLength() external view override returns (uint256) {
        return allBridges.length;
    }

    function createBridge(bytes32 salt) external override onlyOwner returns (address bridge) {
        bytes memory bytecode = type(Bridge).creationCode;
        require(bytecode.length != 0, "Factory: bytecode length is zero");
        require(saltToAddress[salt] == address(0), "Factory: address exists");
        assembly {
            bridge := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(bridge != address(0), "Factory: Failed on deploy");
        IBridge(bridge).initialize(msg.sender);

        allBridges.push(bridge);
        saltToAddress[salt] = bridge;
        bridgeToIdx[bridge] = allBridges.length;

        emit BridgeCreated(bridge, allBridges.length, salt);
    }

    function setFeeTo(address _feeTo) external override onlyOwner {
        feeTo = _feeTo;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IBridge.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bridge is IBridge {
    address public override owner;
    address public override factory;

    modifier onlyOwner() {
        require(msg.sender == owner, "Bridge: FORBIDDEN");
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _owner) external override {
        require(msg.sender == factory, "Bridge: FORBIDDEN");
        owner = _owner;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function lock() external payable override {
        require(!_isContract(msg.sender), "Bridge: IS_CONTRACT");
        emit Lock(msg.sender, address(this), msg.value);
    }

    function lockToken(address token, uint256 amount) external override {
        require(!_isContract(msg.sender), "Bridge: IS_CONTRACT");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit LockToken(token, msg.sender, address(this), amount);
    }

    function withdraw(address recipient, uint256 amount) external override onlyOwner {
        require(address(this).balance >= amount, "Bridge: BALANCE_EXCEED");
        payable(recipient).transfer(amount);
    }

    function withdrawToken(
        address token,
        address recipient,
        uint256 amount
    ) external override onlyOwner {
        IERC20(token).transfer(recipient, amount);
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBridgeFactory {
    event BridgeCreated(address bridge, uint256, bytes32 salt);

    function INIT_CODE_HASH() external view returns (bytes32);

    function feeTo() external view returns (address);

    function saltToAddress(bytes32) external view returns (address);

    function bridgeToIdx(address) external view returns (uint256);

    function allBridges(uint256) external view returns (address);

    function allBridgesLength() external view returns (uint256);

    function createBridge(bytes32 salt) external returns (address);

    function setFeeTo(address) external;
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

interface IBridge {
    event Lock(address indexed from, address indexed to, uint256 amount);
    event LockToken(address indexed token, address indexed from, address indexed to, uint256 amount);

    function owner() external view returns (address);

    function factory() external view returns (address);

    function initialize(address) external;

    function withdraw(address recipient, uint256 amount) external;

    function withdrawToken(
        address token,
        address recipient,
        uint256 amount
    ) external;

    function lock() external payable;

    function lockToken(address token, uint256 amount) external;
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