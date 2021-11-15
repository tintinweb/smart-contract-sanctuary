// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.4;

import "../utils/VolumeOwnable.sol";
import "../token/IBEP20.sol";

contract VolumeFaucet is VolumeOwnable {
    uint256 constant ONE_DAY_IN_BLOCKS = 24 * 60 * 60 / 3;  // 3seconds per block one day worth of blocks

    uint256 claimableAmount = 10000 * 10 ** 18;
    address immutable volume;
    mapping(address => uint256) public lastClaimedOn;

    constructor (address owner_, address volumeAddress) VolumeOwnable(owner_){
        volume = volumeAddress;
    }

    function sendVolTo(uint256 amount, address receiver) external onlyOwner {
        IBEP20(volume).transfer(receiver, amount);
    }

    function ChangeClaimableAmount(uint256 newAmount) external onlyOwner {
        claimableAmount = newAmount;
    }

    function resetCounterFor(address user_) external onlyOwner {
        lastClaimedOn[user_] = 0;
    }

    function claimTestVol() external {
        require(canClaim(_msgSender()), "Can only claim once a day");
        IBEP20(volume).transfer(_msgSender(), claimableAmount);
        lastClaimedOn[_msgSender()] = block.number;
    }

    function getLastClaimedOn(address user_) external view returns (uint256) {
        return lastClaimedOn[user_];
    }

    function canClaim(address user_) public view returns (bool) {
        return block.number - lastClaimedOn[user_] > ONE_DAY_IN_BLOCKS;
    }
}

// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.4;

/**
 * As defined in the ERC20 EIP
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
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
abstract contract VolumeOwnable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the provided multisig as the initial owner.
     */
    constructor (address multiSig_) {
        require(multiSig_ != address(0), "multisig_ can't be address zero");
        _owner = multiSig_;
        emit OwnershipTransferred(address(0), multiSig_);
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

