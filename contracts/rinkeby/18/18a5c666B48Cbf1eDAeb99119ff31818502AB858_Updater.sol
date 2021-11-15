// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IRepurchase.sol";
import "../interface/IVolumeBook.sol";
import "../interface/ILottery.sol";
import "../interface/IOracle.sol";
// import "hardhat/console.sol";


contract Updater is Ownable {

    IVolumeBook public volumeBook;
    IRepurchase public repurchase;
    ILottery public lottery;
    IOracle public oracle;

    address public admin;

    constructor(
        address _volumeBook,
        address _repurchase,
        address _lottery,
        address _oracle
    ) public {
        require(_volumeBook != address(0), "Updater: zero address");
        require(_repurchase != address(0), "Updater: zero address");
        require(_lottery != address(0), "Updater: zero address");
        require(_oracle != address(0), "Updater: zero address");
        
        volumeBook = IVolumeBook(_volumeBook);
        repurchase = IRepurchase(_repurchase);
        lottery = ILottery(_lottery);
        oracle = IOracle(_oracle);
    }

    function setVolumeBook(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Updater: zero address");
        volumeBook = IVolumeBook(_newAddress);
    }

    function setRepurchase(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Updater: zero address");
        repurchase = IRepurchase(_newAddress);
    }

    function setLottery(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Updater: zero address");
        lottery = ILottery(_newAddress);
    }

    function setOracle(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Updater: zero address");
        oracle = IOracle(_newAddress);
    }


    // admin can be zero address so that no one can force update
    function setAdmin(address _newAddress) external {
        admin = _newAddress;
    }

    // invoke this when volumeBook can update
    // only can update when time satisfied and rewrad > 0 (no reward means nobody join)
    function update() external {
        if (volumeBook.canUpdate()) {
            uint256 length = volumeBook.getWhitelistLength();
        for (uint256 index = 0; index < length; index++) {
            address lpToken = volumeBook.getWhitelist(index);
            repurchase.updatePurchase(lpToken);
            oracle.updatePair(lpToken);
        }
        // if no reward token, toSpender will throw
        repurchase.toSpender();
        volumeBook.addCycleNum();
        }
    }

    // invoke this 10 minutes(delay time) after updating volumeBook
    function updateLottery() external {
        lottery.updateRewardNum();
    }

    // In case the whitelist is so long and we must update it manually
    function forceUpdate() external {
        require(msg.sender == admin, "Can only be force update by admin");
        volumeBook.addCycleNum();
    }
  
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
pragma solidity ^0.6.12;

interface IRepurchase {
    function purchase(address pair) external;
    function updatePurchase(address pair) external;
    function toSpender() external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
interface IVolumeBook {
    function addVolume(address user, address input, address output, uint256 amount) external returns (bool);
    function getUserVolume(address user, uint256 cycleNum) external view returns (uint256);
    function getTotalTradeVolume(uint256 cycleNum) external view returns (uint256);
    function currentCycleNum() external pure returns (uint256);
    function lastUpdateTime() external pure returns (uint256);
    function addCycleNum() external;
    function canUpdate() external view returns(bool);

    function getWhitelistLength() external view returns (uint256);
    function getWhitelist(uint256 _index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ILottery {
      function setSlot(address user) external;
      function updateRewardNum() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface IOracle {
    function factory() external pure returns (address);
    function update(address tokenA, address tokenB) external returns(bool);
    function updatePair(address pair) external returns(bool);
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
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

