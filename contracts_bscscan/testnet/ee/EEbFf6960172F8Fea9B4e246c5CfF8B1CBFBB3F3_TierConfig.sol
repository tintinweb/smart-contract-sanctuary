// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

// define query stake data interface for https://bscscan.com/address/0x2f9fbb154e6c3810f8b2d786cb863f8893e43354#code
interface ICATEStake {
    // the Stake
    struct Stake {
        // opening timestamp
        uint256 startDate;
        // amount staked
        uint256 amount;
        // interest accrued, this will be available only after closing stake
        uint256 interest;
        // penalty charged, if any
        uint256 penalty;
        // closing timestamp
        uint256 finishedDate;
        // is closed or not
        bool closed;
    }

    // stakes that the owner have
    function stakesOfOwner(address account, uint256 inx) external view returns (uint256, uint256, uint256, uint256, uint256, bool);
    function stakesOfOwnerLength(address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface ITierConfig {
    function isTier(address account, uint8 tier) external view returns (bool);
    function isTierAtTimestamp(address account, uint8 tier, uint256 t) external view  returns (bool);
    
    // get account best tier
    function getHandsomeTier(address account) external view returns (uint8);
    function getHandsomeTierAtTimestamp(address account, uint256 t) external view returns (uint8);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICATEStake.sol";
import "./ITierConfig.sol";

contract TierConfig is ITierConfig, Ownable {

    event TierStakeChanged(address indexed _operator, uint256[] _tierStakeArray);
    event StakeEffectiveTimeSecondsChanged(address indexed _operator, uint256 _stakeEffectiveTimeSeconds);

    // Cate stake contract address 
    ICATEStake public cateStake;
    uint256[] public tierStakeArray;

    // stake take effect time
    uint256 stakeEffectiveTimeSeconds;

    constructor(ICATEStake _cateStake) {
        cateStake = _cateStake;
        // stake take effect after 1 day
        stakeEffectiveTimeSeconds = 60 * 60 * 24;
    }

    modifier tierIsValid(uint8 tier) {
        require(tier > 0 && tier <= tierStakeArray.length, "TierConfig: invalid tier");
        _;
    }

    function getTierStakeArray() public view returns (uint256[] memory) {
        return tierStakeArray;
    }
    
    function modifyTierStake(uint256[] memory _tierStakeArray) public onlyOwner {
        require(_tierStakeArray.length < 100, "TierConfig: invalid tierStakeArray length");
        tierStakeArray = _tierStakeArray;
        emit TierStakeChanged(msg.sender, _tierStakeArray);
    }

    function modifyStakeEffectiveTimeSeconds(uint256 _stakeEffectiveTimeSeconds) public onlyOwner {
        require(_stakeEffectiveTimeSeconds < block.timestamp, "TierConfig: invalid stake effective time");
        stakeEffectiveTimeSeconds = _stakeEffectiveTimeSeconds;
        emit StakeEffectiveTimeSecondsChanged(msg.sender, _stakeEffectiveTimeSeconds);
    }

    function getMaxTier() public view returns (uint256) {
        return tierStakeArray.length;
    }

    // get account take effect stake amount at specific timestamp
    function getAccountEffectiveStakeAtTimestamp(address _account, uint256 t) public view returns (uint256) {
        uint256 accumulated = 0;
        uint256 stakeCount = cateStake.stakesOfOwnerLength(_account);
        for(uint256 i=0; i<stakeCount; i++){
            (uint256 stakeStartDate, uint256 stakeAmount, , , , bool stakeClosed) = cateStake.stakesOfOwner(_account, i);
            if (stakeClosed) {
                continue;
            }
            if (t - stakeStartDate < stakeEffectiveTimeSeconds) {
                continue;
            }
            accumulated += stakeAmount;
        }
        return accumulated;
    }


    // get account take effect stake amount
    function getAccountStake(address _account) public view returns (uint256) {
        return getAccountEffectiveStakeAtTimestamp(_account, block.timestamp);
    }
    
    // get account satisfy the tier at specific timestamp
    function isTierAtTimestamp(address account, uint8 tier, uint256 t) override public view tierIsValid(tier) returns (bool) {
        uint256 stakeAmount = getAccountEffectiveStakeAtTimestamp(account, t);
        return stakeAmount >= tierStakeArray[tier - 1];
    }

    // get account satisfy the tier 
    function isTier(address account, uint8 tier) override public view tierIsValid(tier) returns (bool) {
        return isTierAtTimestamp(account, tier, block.timestamp);
    }

    // get account best tier at specific timestamp
    function getHandsomeTierAtTimestamp(address account, uint256 t) override public view returns (uint8) {
        if (tierStakeArray.length == 0) {
            return 0;
        }
        uint256 stakeAmount = getAccountEffectiveStakeAtTimestamp(account, t);
        for (uint i = 0; i < tierStakeArray.length; i++) {
            if (stakeAmount >= tierStakeArray[i]) {
                return uint8(i + 1);
            }
        }
        return 0;
    }
    

    // get account best tier
    function getHandsomeTier(address account) override public view returns (uint8) {
        return getHandsomeTierAtTimestamp(account, block.timestamp);
    }
}