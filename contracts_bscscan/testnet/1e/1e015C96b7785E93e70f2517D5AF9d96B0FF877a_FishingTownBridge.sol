/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

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


// File contracts/interfaces/IERC20.sol



pragma solidity ^0.8.0;

interface IERC20 {
    function mint(address to, uint256 amount) external;
}


// File contracts/BridgeBase.sol


pragma solidity 0.8.10;


contract BridgeBase is Ownable {

    event Mint(
        address indexed sender,
        uint256 indexed id,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );

    IERC20 public token;
    mapping(uint256 => bool) public nonces;

    constructor(address _token) {
        require(_token != address(0), "token address cannot be zero");

        token = IERC20(_token);
    }

    function mint(
        uint256 nonce,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(nonces[nonce] == false, "nonce already used");
        nonces[nonce] = true;
        token.mint(to, amount);
        emit Mint(msg.sender, nonce, to, amount, block.timestamp);
    }

}


// File contracts/FishingTownBridge.sol


pragma solidity 0.8.10;

contract FishingTownBridge is BridgeBase {
    
    constructor(address _token) BridgeBase(_token) {}
    
}