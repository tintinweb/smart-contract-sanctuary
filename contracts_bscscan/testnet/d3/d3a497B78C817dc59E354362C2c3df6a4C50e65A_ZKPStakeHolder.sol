pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IZKPToken.sol";
import "./interfaces/IZKPVesting.sol";

contract ZKPStakeHolder is Ownable {
    struct Tranche {
        uint16 unlockOnStart; // percentage of unlock amount
        uint16 period; // period in day
        bool isPreMinted; // option for pre-mint
    }

    struct Stake {
        uint32 trancheId;
        uint256 amount;
        uint256 vested;
        uint256 start;
    }

    mapping(address => Stake) public stakes;
    mapping(uint256 => Tranche) public tranches;
    mapping(address => bool) public stakeHolders;

    uint256 public trancheID;
    uint16 public constant MAX_UNLOCK_ONSTART = 100;
    IZKPVesting private zkpVesting;

    event StakeAdded(address indexed _holder, uint32 indexed _id, uint256 _amount, uint256 vested, uint256 _start);
    event StakeVestedUpdated(address indexed _holder, uint32 indexed _id, uint256 vested);
    event TrancheAdded(uint256 indexed _id, uint16 _unlockOnStart, uint16 _period);
    event TrancheRemoved(uint256 indexed _id);

    modifier onlyStakeHolder(address _holder) {
        require(stakeHolders[_holder], "ZKPStakeH: invalid stake holder");
        _;
    }

    constructor(address _vestingAddress) {
        zkpVesting = IZKPVesting(_vestingAddress);
    }

    function ZKPVesting() public view returns (address) {
        return address(zkpVesting);
    }

    //////////////////
    //// Owner ////
    //////////////////

    function allowStake(address _holder) external onlyOwner {
        require(_holder != address(0), "ZKPStakeH: invalid holder");
        stakeHolders[_holder] = true;
    }

    function denyStake(address _holder) external onlyOwner {
        require(_holder != address(0), "ZKPStakeH: invalid holder");
        stakeHolders[_holder] = false;
    }

    function addTranche(
        uint16 _unlockOnStart,
        uint16 _period,
        bool _isPreMinted
    ) external onlyOwner {
        require(_unlockOnStart <= MAX_UNLOCK_ONSTART, "ZKPStakeH: invalid unlockOnStart");
        require(_period > 0, "ZKPStakeH: invalid tranche period");
        tranches[trancheID] = Tranche(_unlockOnStart, _period, _isPreMinted);
        emit TrancheAdded(trancheID, _unlockOnStart, _period);
        trancheID++;
    }

    function removeTranche(uint16 _id) external onlyOwner {
        require(_id < trancheID, "ZKPStakeH: invliad identifier");
        delete tranches[_id];
        emit TrancheRemoved(_id);
    }

    function addStake(
        uint32 _trancheID,
        address _holder,
        uint256 _amount,
        uint256 _start
    ) external onlyOwner {
        require(!stakeHolders[_holder], "ZKPStakeH: holder existed");
        require(_trancheID <= trancheID, "ZKPStakeH: invalid tranche");
        require(_amount > 0, "ZKPStakeH: invalid amount");
        require(_start >= block.timestamp, "ZKPStakeH: invalid timestamp");

        Tranche memory stakeTranche = tranches[_trancheID];
        require(stakeTranche.period > 0, "ZKPStakeH: empty tranche");

        stakes[_holder] = Stake(_trancheID, _amount, 0, _start);
        emit StakeAdded(_holder, _trancheID, _amount, 0, _start);
    }

    /////////////////////
    //// StakeHolder ////
    /////////////////////

    function splitStake(
        address _newHolder,
        uint256 _amount,
        uint256 _start,
        bool _vestPending
    ) external onlyStakeHolder(_msgSender()) {
        Stake storage userStake = stakes[_msgSender()];
        require(_newHolder != address(0), "ZKPStakeH: invalid address");
        require(_newHolder != _msgSender(), "ZKPStakeH: the address is same");
        require(_amount <= userStake.amount - userStake.vested, "ZKPStakeH: invalid amount");
        require(_start >= block.timestamp, "ZKPStakeH: invalid timestamp");

        _stopVesting(_msgSender(), _vestPending);
        require(_amount <= userStake.amount - userStake.vested, "ZKPStakeH: invalid amount");
        userStake.amount = userStake.amount - _amount;
        stakes[_newHolder] = Stake(userStake.trancheId, _amount, 0, _start);

        _startVesting(_msgSender());
        _startVesting(_newHolder);
    }

    //////////////////
    //// Internal ////
    //////////////////

    function _startVesting(address _holder) internal {
        Stake memory userStake = stakes[_holder];
        Tranche memory stakeTranche = tranches[userStake.trancheId];

        zkpVesting.addVestingPool(
            _holder,
            uint32(userStake.start),
            stakeTranche.period * 3600,
            uint8(stakeTranche.unlockOnStart),
            uint96(userStake.amount),
            stakeTranche.isPreMinted,
            true
        );
        emit StakeVestedUpdated(_holder, userStake.trancheId, (userStake.amount * stakeTranche.unlockOnStart) / 100);
    }

    function _stopVesting(address _holder, bool _vestPending) internal onlyStakeHolder(_holder) {
        zkpVesting.stopVestingPool(_holder, _vestPending);
    }

    function _updateStakeHolder(address _holder) internal onlyStakeHolder(_holder) {
        Stake storage userStake = stakes[_holder];
        userStake.vested = zkpVesting.vestedAmount(_holder);
        emit StakeVestedUpdated(_holder, userStake.trancheId, userStake.vested);
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

interface IZKPToken {
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

    function mint(address account, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKPVesting {
    function vestedAmount(address beneficiary) external view returns (uint256);

    function releasableAmount(address beneficiary) external view returns (uint96);

    function addVestingPool(
        address beneficiary,
        uint32 start,
        uint16 duration,
        uint8 unlocked,
        uint96 amount,
        bool isPreMinted,
        bool isAdjustable
    ) external;

    function stopVestingPool(address _beneficiary, bool _vestPending) external;

    function updatePoolStart(address _beneficiary, uint32 _start) external;

    function updatePoolDuration(address _beneficiary, uint16 _duration) external;

    event Released(address indexed beneficiary, uint256 amount);

    event VestingPoolAdded(address indexed beneficiary, uint256 amount);
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

