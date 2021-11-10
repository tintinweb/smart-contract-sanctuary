// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                          DEFAULT OS MODULE (BASE)                                 //
///////////////////////////////////////////////////////////////////////////////////////


contract OS_Module is Ownable {
    DefaultOS public OS;

    constructor(DefaultOS os) {
        OS = os;
        transferOwnership(address(OS));
    }

    function rescue(IERC20 token_) external onlyOwner {
        require (msg.sender == address(OS), "Caller must be the OS");
        token_.transfer(address(OS), token_.balanceOf(address(this)));
    }
}


///////////////////////////////////////////////////////////////////////////////////////
//                               OS SYSTEM CONTRACT                                  //
///////////////////////////////////////////////////////////////////////////////////////


// Core contracts are atomic contracts that don't have any dependencies on other contracts.
contract OS_SYS is OS_Module {

    constructor (DefaultOS os) OS_Module(os) {}

    bytes3 private _KEYCODE;

    function KEYCODE() external view virtual returns (bytes3) {
        return _KEYCODE;
    }

    modifier viaApprovedPolicy {
        require (OS.APP_REGISTRY(msg.sender), "Only installed policies can call this function");
        _;
    }
}


///////////////////////////////////////////////////////////////////////////////////////
//                                  OS APP CONTRACT                                  //
///////////////////////////////////////////////////////////////////////////////////////

// App contacts are contracts that depend on one or more core contracts, and usually contain the business logic.
contract OS_APP is OS_Module {

    constructor (DefaultOS os) OS_Module(os) {}
    
    modifier onlyOS {
        require (msg.sender == OS.owner(), "Only owner of the OS can call this function");
        _;
    }

    function requireSystem(bytes3 keycode) view internal returns (address system) {
        require (OS.SYSTEM(keycode) != address(0), "System cannot be found");
        return OS.SYSTEM(keycode);
    }
}


///////////////////////////////////////////////////////////////////////////////////////
//                                     OS CORE LOGIC                                 //
///////////////////////////////////////////////////////////////////////////////////////


contract DefaultOS is Ownable {
    
    // ******************************* DEPENDENCY MANAGEMENT ******************************* //

    mapping(bytes3 => address) public SYSTEM; // get contract for system keycode
    mapping(address => bool) public APP_REGISTRY; // whitelisted apps

    function installSystem(OS_SYS sys) external onlyOwner {
        require(SYSTEM[sys.KEYCODE()] == address(0), "Existing system already present");
        SYSTEM[sys.KEYCODE()] = address(sys);
    }

    // Add app to whitelist
    function approvePolicy(OS_APP app) external onlyOwner {
        require(APP_REGISTRY[address(app)] == false, "Policy is already installed");
        APP_REGISTRY[address(app)] = true;
    }

    function transferModule(OS_Module module, address newOwner) external onlyOwner {
        module.transferOwnership(newOwner);
    }


    // ******************************* TOKEN MANAGEMENT ******************************* //

    // to approve of any smart contract interactions for the DAO (like put in treasury, etc.)
    function approveTokenForApp(IERC20 token, address app, uint256 amount) external onlyOwner {
        require (APP_REGISTRY[app], "Can only approve for installed apps"); 
        token.approve(app, amount);
    }

    // rescue funds from contract
    function rescueToken(OS_Module module, IERC20 token) external onlyOwner {
        module.rescue(token);
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

/*
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