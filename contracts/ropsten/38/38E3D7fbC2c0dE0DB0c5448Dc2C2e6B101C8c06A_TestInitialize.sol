/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

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

// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)




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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface BMEX {
    // Context
    function _msgSender() external view returns (address);
    function _msgData() external view returns (bytes calldata);

    //IERC20
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    //IERC20Metadata
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    //BlacklistManagerRole
    event BlacklistManagerAdded(address indexed _blacklistManager);
    event BlacklistManagerRemoved(address indexed _blacklistManager);

    function isBlacklistManager(address _blacklistManager) external view returns (bool);
    function addBlacklistManager(address _blacklistManager) external;
    function removeBlacklistManager(address _blacklistManager) external;

    //Pausable
    event Paused(address account);
    event Unpaused(address account);
    function paused() external view returns (bool);
    function _pause() external;
    function _unpause() external;

    //BMEX
    event Blacklisted(address wallet);
    event Whitelisted(address wallet);

    function initialize() external;
    function pause() external;
    function unpause() external;
    function blacklisted(address _wallet) external view returns (bool);
    function blacklist(address _wallet) external;
    function whitelist(address _wallet) external;
    function burn(uint256 amount) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) external;
    function _mint(address account, uint256 amount) external;
    function _burn(address account, uint256 amount) external;
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) external;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external;

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external;

}

// contract SampleContract {
//     function initialize() virtual;
// } 

contract TestInitialize is Ownable{
    address public _tokenContract;

    constructor (address owner, address tokenContract) {
        _transferOwnership(owner);
        _tokenContract = tokenContract;
    }

    function callExternalInit() public onlyOwner {
        BMEX(_tokenContract).initialize();
    }

    function changeTokenAddress(address newAddress) public onlyOwner {
        _tokenContract = newAddress;
    }
}