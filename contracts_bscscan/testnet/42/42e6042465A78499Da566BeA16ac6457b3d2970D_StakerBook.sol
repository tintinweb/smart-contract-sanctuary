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

import "./Context.sol";

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
    constructor(address _owner_) {
        _setOwner(_owner_);
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
        require(owner() == _msgSender(), "Only Owner!");
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
pragma solidity ^0.8.4;

interface IStaker {
    
    function stake(address staker) external;

    function refer(address staker, address referer) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStakingManager {

    function stakings(address sender) external view returns (bool);

    function stakingAddress(address staingToken) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../interface/IStaker.sol";
import "../../interface/IStakingManager.sol";
import "../../common/Ownable.sol";

contract StakerBook is IStaker {

    // staker -> staked
    mapping(address => bool) public staked;
    // stakers
    address[] public stakers;
    // staker -> referer
    mapping(address => address) public referers;
    

    IStakingManager public ism;

    modifier onlyStakings() {
        require(ism.stakings(msg.sender) == true, "Only staking!");
        _;
    }

    constructor(address _ism){
        ism = IStakingManager(_ism);
    }


    // ------------------------------------------------------------------------
    // plain stake
    // ------------------------------------------------------------------------
    function stake(address staker) external override onlyStakings {
        if (!staked[staker]) {
            // staked
            staked[staker] = true;
            stakers.push(staker);
        }
    }


    // ------------------------------------------------------------------------
    // staker with referer
    // ------------------------------------------------------------------------
    function refer(address staker, address referer) external override onlyStakings {
        if (!staked[staker]) {
            // staked
            staked[staker] = true;
            stakers.push(staker);
            if (referer != address(0))
                referers[staker] = referer;
        }
    }


    //****************
    // Views
    //****************

    function getStakersLength() external view returns (uint256){
        return stakers.length;
    }


    function getStakers() external view returns (address[] memory){
        return stakers;
    }


    function getStakersLimit(uint256 start, uint256 end) external view returns (address[] memory values){
        uint256 _length = stakers.length;
        end = end > _length ? _length : end;
        values = new address[](end - start);

        uint256 index = 0;
        for (uint256 i = start; i < end; i++) {
            values[index] = stakers[i];
            index++;
        }
    }

}