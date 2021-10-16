// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/IZombieToken.sol";
import "./access/Ownable.sol";

/**
 * @title Catacombs
 * @author Saad Sarwar
 */

contract Catacombs is Ownable {
    uint256 public totalCatacombs = 0;
    address public burnAddr = 0x000000000000000000000000000000000000dEaD; // Burn address
    uint256 public burnAmount; // Burn amount
    address public zombie; // zombie token contract address

    constructor (uint256 _burnAmount, address _zombie) {
        burnAmount = _burnAmount;
        zombie = _zombie;
    }

    // Info of each user.
    struct UnlockedCatacombsInfo {
        uint256 amount;     // How many Zombie tokens the user has provided.
        uint256 burnDate;   // Date burned.
        uint256 catacombId; // id of the catacomb unlocked.
    }

    mapping (address => UnlockedCatacombsInfo) public unlockedCatacombsInfo;

    function UnlockCatacombs() public returns (bool) {
        // just one per wallet
        require(isUnlocked(msg.sender), "Only one catacomb allowed per address.");
        IZombieToken(zombie).transferFrom(msg.sender, burnAddr, burnAmount);
        unlockedCatacombsInfo[msg.sender] = UnlockedCatacombsInfo(burnAmount, block.timestamp, totalCatacombs + 1);
        totalCatacombs = totalCatacombs + 1;
        return true;
    }

    function setBurnAmount(uint _burnAmount) onlyOwner public {
        burnAmount = _burnAmount;
    }

    function isUnlocked(address _user) public view returns(bool) {
        return unlockedCatacombsInfo[_user].catacombId != 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// ZombieToken interface.
interface IZombieToken {
    function mint(address _to, uint256 _amount) external;
    function delegates(address delegator) external view returns (address);
    function delegate(address delegatee) external;
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
    function transferOwnership(address newOwner) external;
    function getCurrentVotes(address account) external view returns (uint256);
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function liftLaunchWhaleDetection() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    constructor()  {
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