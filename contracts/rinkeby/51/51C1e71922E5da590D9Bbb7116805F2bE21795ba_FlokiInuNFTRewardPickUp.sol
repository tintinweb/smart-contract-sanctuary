// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMintable.sol";

contract FlokiInuNFTRewardPickUp is Ownable {
    uint256 private constant NUM_REWARDS = 3;

    IMintable public immutable bronzeNFT;
    IMintable public immutable silverNFT;
    IMintable public immutable diamondNFT;

    mapping (uint256 => bytes8[]) private _rewards;
    mapping (bytes8 => bool) private _hasClaimed;

    constructor(
        address _bronzeNFT,
        address _silverNFT,
        address _diamondNFT
    )
        Ownable()
    {
        bronzeNFT = IMintable(_bronzeNFT);
        silverNFT = IMintable(_silverNFT);
        diamondNFT = IMintable(_diamondNFT);
    }

    function hasReward(address user) public view returns (bool) {
        for (uint256 i = 0; i < NUM_REWARDS; i++) {
            if (_hasReward(user, i)) {
                return true;
            }
        }

        return false;
    }

    function hasClaimed(address user) public view returns (bool) {
        return _hasClaimed[_encode(user)];
    }

    function claimReward() external {
        bytes8 hash = _encode(msg.sender);
        require(!hasClaimed(msg.sender), "FlokiInuNFTRewardPickUp::ALREADY_CLAIMED");
        _hasClaimed[hash] = true;

        uint256 reward = 0;
        while (reward < NUM_REWARDS) {
            if (_hasReward(msg.sender, reward)) {
                break;
            }

            reward++;
        }

        // No reward
        if (reward == NUM_REWARDS) {
            revert("FlokiInuNFTRewardPickUp::INELIGIBLE_ADDRESS");
        }

        if (reward > 1) {
            diamondNFT.mint(msg.sender);
        }

        if (reward > 0) {
            silverNFT.mint(msg.sender);
        }

        bronzeNFT.mint(msg.sender);
    }

    function addBatch(uint256 reward, address[] calldata batch) external onlyOwner {
        require(reward < NUM_REWARDS, "FlokiInuNFTRewardPickUp::INVALID_REWARD");

        for (uint256 i = 0; i < batch.length; i++) {
            _rewards[reward].push(_encode(batch[i]));
        }
    }

    function _hasReward(address user, uint256 reward) private view returns (bool) {
        require(reward < NUM_REWARDS, "FlokiInuNFTRewardPickUp::INVALID_REWARD");

        for (uint256 i = 0; i < _rewards[reward].length; i++) {
            if (_rewards[reward][i] == _encode(user)) {
                return true;
            }
        }

        return false;
    }

    function _encode(address user) private pure returns (bytes8) {
        return bytes8(keccak256(abi.encode(user)));
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
pragma solidity ^0.8.6;

interface IMintable {
    function mint(address to) external;
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

