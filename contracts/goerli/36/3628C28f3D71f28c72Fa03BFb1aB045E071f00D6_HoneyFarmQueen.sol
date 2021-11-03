// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/BearsDeluxeI.sol";
import "../interfaces/HoneyTokenI.sol";
import "../interfaces/BeesDeluxeI.sol";
import "../interfaces/HoneyHiveI.sol";

contract HoneyFarmQueen is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    address public bears;

    address public honey;

    address public hive;

    address public bees;

    struct Bee {
        uint256 id;
        uint8 active;
        uint16 claimCounter;
        uint8 staked;
        uint256 becameInactiveTime;
        uint256 lastRewardTime;
    }

    //this is 1
    uint16 public HONEY_BEARS_REWARDS_PER_ROUND = 100;
    //this is 0.13
    uint16 public HONEY_UNSTAKED_BEE_REWARDS_PER_ROUND = 13;
    //this is 0.09
    uint16 public HONEY_STAKED_BEE_REWARDS_PER_ROUND = 9;
    uint256 public REWARDS_COOLOFF = 86400; //86400 also make this constant
    uint256 public HIVE_CLAIM_COOLOFF = 86400; //one day also make this constant
    uint256 public STARTING_POINT = 1635005744;

    uint256 public constant MIN_BURN_AMOUNT_FOR_BEE = 23;
    uint256 public constant MIN_USAGE_PER_HIVE = 3;
    uint256 public constant MIN_USAGE_PER_BEE = 10;
    uint256 public constant MIN_AMOUNT_FOR_ACTIVATE_HIVE = 69;
    uint256 public constant MIN_AMOUNT_FOR_ACTIVATE_BEE = 7;
    uint256 public constant REWARD_FOR_BURNING_BEE = 12;
    uint256 public constant REWARD_FOR_STAKING_BEE = 7;
    //this is 0.23
    uint256 public constant AMOUNT_TO_KEEP_ACTIVE = 23;

    // mapping(address => uint16[]) stakedBearsDeluxe;
    mapping(uint16 => uint256) private lastRewardOfHoneyPerBears;
    // mapping(uint256 => uint256) private lastRewardOfHoneyPerBee;
    mapping(uint256 => uint256) private lastClaimedBeePerHive;
    // mapping(address => mapping(uint256 => Bee)) private beesPerOwner;
    mapping(uint256 => Bee) private idsAndBees;
    // mapping(uint256 => address) private beesIdsAndOwners;
    uint16[] private bearsStakedIds;

    /***********Events**************/
    event BearsDeluxeStaked(uint16[] _ids);
    event HoneyClaimed(address indexed _to, uint256 _amount);
    event HoneyHiveClaimed(address indexed _to, uint256 _amount);
    event BeeClaimed(address indexed _to, uint256 _amount);
    event HiveActivated(address indexed _owner, uint256 indexed _hiveId);
    event BeesActivated(address indexed _owner, uint256 indexed _beeId);
    event BeeKeptActive(address indexed _owner, uint256 indexed _beeId);
    event BeeBurnt(address indexed _owner, uint256 indexed _beeId);
    event BeeStaked(address indexed _owner, uint256 indexed _beeId);
    event BeeUnstaked(address indexed _owner, uint256 indexed _beeId);
    event StartingPointChanged(uint256 startingPoint);

    constructor() {}

    /***********Public**************/

    /***********External**************/

    function claimBearsHoney(uint16[] calldata _bearsIds) external nonReentrant {
        uint256 amount;
        for (uint16 i = 0; i < _bearsIds.length; i++) {
            uint16 id = _bearsIds[i];

            //if not owner of the token then no rewards, usecase when someone tries to get rewards for
            //a token that isn't his or when he tries to get the rewards for an old token of his
            if (!BearsDeluxeI(bears).exists(id)) continue;
            if (IERC721(bears).ownerOf(id) != msg.sender) continue;

            uint256 roundsToReward;
            if (lastRewardOfHoneyPerBears[id] > 0) {
                roundsToReward = (block.timestamp - lastRewardOfHoneyPerBears[id]) / REWARDS_COOLOFF;
            } else {
                // if no rewards before, then he gets rewards from when the rewards started.
                roundsToReward = (block.timestamp - STARTING_POINT) / REWARDS_COOLOFF;
            }
            // console.log(string(abi.encodePacked("ID = ", Strings.toString(id))));
            // console.log(string(abi.encodePacked("Rounds = ", Strings.toString(roundsToReward))));
            // console.log(string(abi.encodePacked("Timestamp = ", Strings.toString(block.timestamp))));
            // console.log(string(abi.encodePacked("Last reward = ", Strings.toString(lastRewardedPerToken[id]))));
            amount += HONEY_BEARS_REWARDS_PER_ROUND * roundsToReward;
            lastRewardOfHoneyPerBears[id] = block.timestamp;
        }
        require(amount > 0, "Nothing to claim");

        //can not mint more than maxSupply
        if (HoneyTokenI(honey).totalSupply() + amount > HoneyTokenI(honey).maxSupply())
            amount = (HoneyTokenI(honey).maxSupply() - HoneyTokenI(honey).totalSupply()) / 1e18;

        HoneyTokenI(honey).mint(msg.sender, (amount * 1e18) / 100);
        emit HoneyClaimed(msg.sender, (amount * 1e18) / 100);
    }

    function claimBeesHoney(uint256[] calldata _beesIds) external nonReentrant {
        uint256 amount = 0;
        for (uint256 i = 0; i < _beesIds.length; i++) {
            uint256 id = _beesIds[i];

            if (!BeesDeluxeI(bees).exists(id)) continue;
            if (BeesDeluxeI(bees).ownerOf(id) != msg.sender) continue;

            Bee storage bee = idsAndBees[id];

            if (bee.id == 0 || bee.active == 0) continue;

            uint16 roundsToReward;
            if (bee.lastRewardTime > 0) {
                roundsToReward = uint16((block.timestamp - bee.lastRewardTime) / REWARDS_COOLOFF);
            } else {
                // if no rewards before, then he gets rewards from when the rewards started.
                roundsToReward = uint16((block.timestamp - STARTING_POINT) / REWARDS_COOLOFF);
            }

            uint16 nonRewardsRounds = 0;
            if (bee.staked == 0 && roundsToReward > bee.claimCounter) {
                nonRewardsRounds = roundsToReward - bee.claimCounter;
                bee.active = 0;
                bee.becameInactiveTime = block.timestamp;
                bee.claimCounter = 10;
                roundsToReward = bee.claimCounter;
            }

            if (bee.staked == 0) amount += HONEY_UNSTAKED_BEE_REWARDS_PER_ROUND * roundsToReward;
            else amount += HONEY_STAKED_BEE_REWARDS_PER_ROUND * roundsToReward;

            bee.lastRewardTime = block.timestamp;
            bee.claimCounter -= roundsToReward;
            if (bee.staked == 0 && bee.claimCounter == 0) {
                bee.active = 0;
                bee.becameInactiveTime = block.timestamp;
            }
        }
        require(amount > 0, "Nothing to claim");

        //can not mint more than maxSupply
        if (HoneyTokenI(honey).totalSupply() + amount > HoneyTokenI(honey).maxSupply())
            amount = (HoneyTokenI(honey).maxSupply() - HoneyTokenI(honey).totalSupply()) / 1e18;

        HoneyTokenI(honey).mint(msg.sender, (amount * 1e18) / 100);
        emit HoneyClaimed(msg.sender, (amount * 1e18) / 100);
    }

    function mintHive(uint256 _bearsId) external nonReentrant {
        require(msg.sender != address(0), "Can not mint to address 0");
        HoneyHiveI(hive).mint(msg.sender, _bearsId);
        emit HoneyHiveClaimed(msg.sender, _bearsId);
    }

    function mintBee(uint256 _hiveId) external nonReentrant {
        require(msg.sender != address(0), "Can not mint to address 0");

        require(HoneyHiveI(hive).balanceOf(msg.sender) > 0, "No Hive owned");
        require(IERC721(bears).balanceOf(msg.sender) > 0, "No Bears owned");

        require(HoneyTokenI(honey).balanceOf(msg.sender) >= MIN_BURN_AMOUNT_FOR_BEE * 1e18, "Not enough Honey");

        require(HoneyHiveI(hive).getUsageOfMintingBee(_hiveId) < 3, "Inactive Hive, burn 69 Honey");

        require(lastClaimedBeePerHive[_hiveId] < block.timestamp - HIVE_CLAIM_COOLOFF, "Mint bee cooloff");

        uint256 beeId = randBeeId();

        lastClaimedBeePerHive[_hiveId] = block.timestamp;

        idsAndBees[beeId] = Bee(beeId, 1, 10, 0, STARTING_POINT, 0);

        HoneyTokenI(honey).burn(msg.sender, MIN_BURN_AMOUNT_FOR_BEE * 1e18);

        BeesDeluxeI(bees).mint(msg.sender, beeId);
        HoneyHiveI(hive).increaseUsageOfMintingBee(_hiveId);

        emit BeeClaimed(msg.sender, beeId);
    }

    function activateHive(uint256 _hiveId) external nonReentrant {
        require(HoneyHiveI(hive).ownerOf(_hiveId) == msg.sender, "Not your hive");
        require(HoneyHiveI(hive).getUsageOfMintingBee(_hiveId) >= MIN_USAGE_PER_HIVE, "Cap not reached");
        require(HoneyTokenI(honey).balanceOf(msg.sender) >= MIN_AMOUNT_FOR_ACTIVATE_HIVE * 1e18, "Not enough Honey");
        HoneyTokenI(honey).burn(msg.sender, MIN_AMOUNT_FOR_ACTIVATE_HIVE * 1e18);
        HoneyHiveI(hive).resetUsageOfMintingBee(_hiveId);
        emit HiveActivated(msg.sender, _hiveId);
    }

    function activateBees(uint256[] calldata _beesIds) external nonReentrant {
        uint256 amountOfHoney = 0;
        for (uint256 i = 0; i < _beesIds.length; i++) {
            uint256 _beeId = _beesIds[i];
            Bee storage bee = idsAndBees[_beeId];
            if (bee.id == 0) continue;
            if (BeesDeluxeI(bees).ownerOf(_beeId) != msg.sender) continue;
            amountOfHoney += MIN_AMOUNT_FOR_ACTIVATE_BEE * 1e18;
            bee.active = 1;
            bee.claimCounter = 10;
            emit BeesActivated(msg.sender, _beeId);
        }

        require(amountOfHoney > 0, "Nothing to active");
        require(HoneyTokenI(honey).balanceOf(msg.sender) >= amountOfHoney, "Not enough honey");
        HoneyTokenI(honey).burn(msg.sender, amountOfHoney);
    }

    function keepBeesActive(uint256[] calldata _beesIds) external nonReentrant {
        uint256 amountOfHoney = 0;
        for (uint256 i = 0; i < _beesIds.length; i++) {
            uint256 _beeId = _beesIds[i];
            Bee storage bee = idsAndBees[_beeId];
            if (bee.id == 0) continue;
            if (BeesDeluxeI(bees).ownerOf(_beeId) != msg.sender) continue;
            //this bee can not be kept active as it is inactive already, need to burn 7 honey
            if (bee.active == 0) continue;

            amountOfHoney += (AMOUNT_TO_KEEP_ACTIVE * 1e18) / 100;
            bee.active = 1;
            bee.claimCounter = 10;
            emit BeeKeptActive(msg.sender, _beeId);
        }

        require(amountOfHoney > 0, "Nothing to keep active");
        require(HoneyTokenI(honey).balanceOf(msg.sender) >= amountOfHoney, "Not enough honey");
        HoneyTokenI(honey).burn(msg.sender, amountOfHoney);
    }

    function burnBees(uint256[] calldata _beesIds) external nonReentrant {
        uint256 amountOfHoney = 0;
        for (uint256 i = 0; i < _beesIds.length; i++) {
            uint256 _beeId = _beesIds[i];

            //in case a bee is burnt from BeesDeluxe contract, should neved happen.
            if (BeesDeluxeI(bees).ownerOf(_beeId) == address(0)) {
                delete idsAndBees[_beeId];
                return;
            }
            if (BeesDeluxeI(bees).ownerOf(_beeId) != msg.sender) continue;
            delete idsAndBees[_beeId];
            amountOfHoney += REWARD_FOR_BURNING_BEE * 10**18;
            BeesDeluxeI(bees).burnByQueen(_beeId);
            emit BeeBurnt(msg.sender, _beeId);
        }
        if (HoneyTokenI(honey).totalSupply() + amountOfHoney > HoneyTokenI(honey).maxSupply())
            amountOfHoney = (HoneyTokenI(honey).maxSupply() - HoneyTokenI(honey).totalSupply()) / 1e18;

        if (amountOfHoney > 0) HoneyTokenI(honey).mint(msg.sender, amountOfHoney);
    }

    function stakeBees(uint256[] calldata _beesIds) external {
        uint256 amountOfHoney = 0;
        for (uint256 i = 0; i < _beesIds.length; i++) {
            uint256 _beeId = _beesIds[i];
            Bee storage bee = idsAndBees[_beeId];
            if (bee.staked == 1) continue;
            if (BeesDeluxeI(bees).ownerOf(_beeId) != msg.sender) continue;
            amountOfHoney += REWARD_FOR_STAKING_BEE;
            bee.staked = 1;
            emit BeeStaked(msg.sender, _beeId);
        }

        require(amountOfHoney > 0, "Nothing to stake");
        require(HoneyTokenI(honey).balanceOf(msg.sender) >= amountOfHoney * 1e18, "Not enough honey");
        if (amountOfHoney > 0) HoneyTokenI(honey).burn(msg.sender, amountOfHoney * 1e18);
    }

    function unstakeBees(uint256[] calldata _beesIds) external {
        for (uint256 i = 0; i < _beesIds.length; i++) {
            uint256 _beeId = _beesIds[i];
            Bee storage bee = idsAndBees[_beeId];
            if (bee.staked == 0) continue;
            if (BeesDeluxeI(bees).ownerOf(_beeId) != msg.sender) continue;
            bee.staked = 0;
            emit BeeUnstaked(msg.sender, _beeId);
        }
    }

    /***********Private**************/

    /***********Internal**************/
    function randBeeId() internal view returns (uint256 _id) {
        uint256 lastBeeToken = 0;
        if (BeesDeluxeI(bees).totalSupply() > 0)
            lastBeeToken = BeesDeluxeI(bees).tokenByIndex(BeesDeluxeI(bees).totalSupply() - 1);

        return uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, lastBeeToken)));
    }

    /***********Views**************/
    function getLastRewardedByBears(uint16 _bearId) external view returns (uint256) {
        return lastRewardOfHoneyPerBears[_bearId];
    }

    function getLastRewardedByBees(uint256 _beeId) external view returns (uint256) {
        return idsAndBees[_beeId].lastRewardTime;
    }

    function getBeeState(uint256 _beeId) external view returns (Bee memory) {
        return idsAndBees[_beeId];
    }

    function getBeesState(uint256[] calldata _beesIds) external view returns (Bee[] memory beesToReturn) {
        beesToReturn = new Bee[](_beesIds.length);
        for (uint256 i = 0; i < _beesIds.length; i++) {
            beesToReturn[i] = idsAndBees[_beesIds[i]];
        }
        return beesToReturn;
    }

    /***********Settes & Getters**************/

    function setBears(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        bears = _contract;
    }

    function setHoney(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        honey = _contract;
    }

    function setHive(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        hive = _contract;
    }

    function setBees(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        bees = _contract;
    }

    function setInitialStartingPoint(uint256 _startingPoint) external onlyOwner {
        STARTING_POINT = _startingPoint;
        emit StartingPointChanged(_startingPoint);
    }

    function getInitialStartingPoint() external view returns (uint256) {
        return STARTING_POINT;
    }

    //TODO delete this
    function setRewardCoolOff(uint256 _coolOff) external onlyOwner {
        REWARDS_COOLOFF = _coolOff;
    }

    function setHiveClaimCoolOff(uint256 _coolOff) external onlyOwner {
        HIVE_CLAIM_COOLOFF = _coolOff;
    }

    /***********Modifiers**************/
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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract BearsDeluxeI is Ownable, IERC721 {
    function mint(address _owner, uint256 _tokenId) external virtual;

    function exists(uint256 _tokenId) external view virtual returns (bool);

    function getMaxSupply() external virtual returns (uint32);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract HoneyTokenI is Ownable, IERC20 {
    function mint(address _owner, uint256 _amount) external virtual;
    function burn(address _owner, uint256 _amount) external virtual;

    function maxSupply() external pure virtual returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

abstract contract BeesDeluxeI is Ownable, IERC721, IERC721Enumerable {
    function mint(address _owner, uint256 _tokenId) external virtual;

    function exists(uint256 _tokenId) external view virtual returns (bool);

    function getMaxSupply() external virtual returns (uint32);

    function tokensOfOwner(address _owner) external view virtual returns (uint256[] memory);

    function totalSupply() public view virtual returns (uint256);

    function burnByQueen(uint256 _tokenId) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract HoneyHiveI is Ownable, IERC721 {
    function mint(address _owner, uint256 _tokenId) external virtual;

    function exists(uint256 _tokenId) external view virtual returns (bool);

    function getMaxSupply() external virtual returns (uint32);

    function increaseUsageOfMintingBee(uint256 _hiveId) external virtual;

    function getUsageOfMintingBee(uint256 _hiveId) external view virtual returns (uint8);

    function resetUsageOfMintingBee(uint256 _hiveId) external virtual;

    function totalSupply() public view virtual returns (uint256);

    function eligibleToMint(uint256 _bearsId) external view virtual returns (bool eligible);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}