// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/VolumeOwnable.sol";
import "./token/IBEP20.sol";
import "./token/SafeBEP20.sol";
import "./interfaces/IVolumeBEP20.sol";
import "./interfaces/IVolumeEscrow.sol";
import './data/structs.sol';
import "./interfaces/IVolumeJackpot.sol";

contract VolumeJackpot is VolumeOwnable, ReentrancyGuard, IVolumeJackpot {

    using Address for address payable;
    using SafeBEP20 for IBEP20;

    uint256 constant public MAX_INT_TYPE = type(uint256).max;
    uint256 constant public BASE = 10 ** 18;

    address immutable escrow;

    // block number where this allocation of jackpot starts also referred to as the milestoneId in the code
    MileStone[] milestones;
    //   milestoneId => index of this milestone in the milestones array 
    mapping(uint256 => uint256) milestoneIndex; // startBlock => index
    //   milestoneId => address => amount
    mapping(uint256 => mapping(address => uint256)) participantsAmounts; // this will hold the index of each participant in the Milestone mapping (structs can't hold nested mapping)
    // milestoneID => user => fuelAddedToMilestone
    mapping(uint256 => mapping(address => uint256)) participantsAddedFuel;
    //   milestoneId => milestoneParticipants[]
    mapping(uint256 => address[]) milestoneParticipants; // this will hold the index of each participant in the Milestone mapping (structs can't hold nested mapping)

    //   milestoneId => winner => amount
    mapping(uint256 => mapping(address => uint256)) milestoneWinnersAmounts;
    mapping(uint256 => mapping(address => bool)) winningsClaimed;


    // for historical data
    // milestoneId => winners[]
    mapping(uint256 => address[]) winners;
    // milestoneId => winningAmounts[]
    mapping(uint256 => uint256[]) winningAmounts;

    mapping(address => bool) depositors;

    constructor (address multisig_, address escrow_)  VolumeOwnable(multisig_) {
        escrow = escrow_;

        IVolumeEscrow(escrow_).setVolumeJackpot(address(this));
        // link this jackpot to the escrow

        _createMilestone(0, 'genesis');
        // we occupy the 0 index with a dummy milestone (all indexes are stored in a uint mapping so every entry that was not created will return 0)
    }


    /**
     * @dev Throws if called by any account who is not a depositor the volumeBEP contract is always a depositor
     */
    modifier onlyDepositors() {
        require(depositors[_msgSender()] || _msgSender() == IVolumeEscrow(escrow).getVolumeAddress(), "Caller does not have the right to deposit");
        _;
    }

    /**
        @dev creates a new milestone at the start block , this will end the previous milestone at the startBlock-1
     */
    function createMilestone(uint256 startBlock_,string memory milestoneName_) override external {
        require(_msgSender() == owner() || _msgSender() == IVolumeEscrow(escrow).getVolumeAddress(), "VolumeJackpot: only owner or volume BEP20 can call");
        require(block.number < startBlock_, "VolumeJackpot: start block needs to be in to future ");
        if (milestones.length == 1) {
            _createMilestone(startBlock_, milestoneName_);
        } else {
            // set endblock for the previous milestone
            milestones[milestones.length - 1].endBlock = startBlock_ - 1;
            // create a new one 
            _createMilestone(startBlock_, milestoneName_);
        }
    }


    /**
        the order of the array is sorted according to the leader board
        winners should be the top fuel suppliers
        winners are halved each milestone down to a minimum of 10;
        pot is divided as follow
        first spot : 25%
        second place: 15%
        third place: 10%
        rest of participants 50% / rest 
    */
    function setWinnersForMilestone(uint milestoneId_, address[] memory winners_, uint256[] memory amounts_) override external onlyOwner {
        require(milestoneIndex[milestoneId_] != 0, "VolumeJackpot: This milestone does not exist");
        require(milestones[milestoneIndex[milestoneId_]].endBlock < block.number, "VolumeJackpot: milestone is not over yet");

        require(winners_.length == amounts_.length, 'VolumeJackpot: winners_ length != amounts_ length');
        require(winners[milestoneId_].length == 0 && winningAmounts[milestoneId_].length == 0, "VolumeJackpot: winners already set");
        winners[milestoneId_] = winners_;
        winningAmounts[milestoneId_] = amounts_;

        uint256 totalAmounts;
        uint256 prevParticipation = MAX_INT_TYPE;

        // max winners is 1000 for the first milestone 
        // next milestones will half the number of winners
        for (uint i = 0; i < winners_.length; i++) {
            require(prevParticipation >= participantsAmounts[milestoneId_][winners_[i]], 'VolumeJackpot: not sorted properly');
            milestoneWinnersAmounts[milestoneId_][winners_[i]] = amounts_[i];
            totalAmounts += amounts_[i];
            prevParticipation = participantsAmounts[milestoneId_][winners_[i]];
        }
        require(totalAmounts == milestones[milestoneIndex[milestoneId_]].amountInPot);
    }

    /**
        @dev Deposits amount_ to active milestone's jackpot and gives its credit to creditsTo_
         fuelContributed_ is the amounts of blocks this deposit has added (used for stats and other calculations)
     */
    function deposit(uint256 amount_, uint fuelContributed_, address creditsTo_) override external nonReentrant onlyDepositors {
        require(IVolumeEscrow(escrow).getVolumeAddress() != address(0), "VolumeJackpot: volume BEP20 address was not set yet");
        IBEP20(IVolumeEscrow(escrow).getVolumeAddress()).safeTransferFrom(_msgSender(), address(this), amount_);

        MileStone memory activeMilestone = getCurrentActiveMilestone();

        require(activeMilestone.startBlock != 0, "VolumeJackpot: no active milestone");

        milestones[milestoneIndex[activeMilestone.startBlock]].amountInPot += amount_;
        milestones[milestoneIndex[activeMilestone.startBlock]].totalFuelAdded += fuelContributed_;

        // if this creditor does not exists in our map
        if (participantsAmounts[activeMilestone.startBlock][creditsTo_] == 0) {
            milestoneParticipants[activeMilestone.startBlock].push(creditsTo_);
        }

        participantsAmounts[activeMilestone.startBlock][creditsTo_] += amount_;
        participantsAddedFuel[activeMilestone.startBlock][creditsTo_] += fuelContributed_;
    }

    /**
    @dev use this function to deposit an amount of volume to this milestone rewards 
        could be useful if we decide to use a portion of the marketing or  reward volume allocation as an incentive
        by adding it to the next milestone reward
     */
    function depositIntoMilestone(uint256 amount_, uint256 milestoneId_) override external onlyDepositors {
        require(milestoneIndex[milestoneId_] != 0, 'VolumeJackPot: milestone does not exist');
        require(milestones[milestoneIndex[milestoneId_]].endBlock >= block.number, "VolumeJackPot: milestone already passed");

        require(IVolumeEscrow(escrow).getVolumeAddress() != address(0), "VolumeJackpot: volume BEP20 address was not set yet");
        IBEP20(IVolumeEscrow(escrow).getVolumeAddress()).safeTransferFrom(_msgSender(), address(this), amount_);

        milestones[milestoneIndex[milestoneId_]].amountInPot += amount_;
    }

    /**
        claims the pending rewards for this user
     */
    function claim(address user_) override external {
        require(milestones.length > 1, "VolumeJackpot: no milestone set");

        uint256 amountOut;
        for (uint i = 1; i < milestones.length; i++) {
            amountOut += getClaimableAmountForMilestone(user_, milestones[i].startBlock);
            winningsClaimed[milestones[i].startBlock][user_] = true;
        }

        require(amountOut > 0, 'VolumeJackpot: nothing to claim');

        require(bytes(IVolumeBEP20(IVolumeEscrow(escrow).getVolumeAddress()).getNicknameForAddress(user_)).length > 0, 'VolumeJackpot: you have to claim a nickname first');

        IBEP20(IVolumeEscrow(escrow).getVolumeAddress()).safeTransfer(user_, amountOut);
    }


    /**
        @dev
     */
    function addDepositor(address allowedDepositor_) override external onlyOwner {
        depositors[allowedDepositor_] = true;
    }

    /**
        @dev
     */
    function removeDepositor(address depositorToBeRemoved_) override external onlyOwner {
        depositors[depositorToBeRemoved_] = false;
    }

    /**
        @dev
     */
    function isDepositor(address potentialDepositor_) override external view returns (bool){
        return depositors[potentialDepositor_];
    }

    /**
        `milestoneID` is the start block of the milestone
     */
    function getPotAmountForMilestone(uint256 milestoneId_) override external view returns (uint256){
        return milestones[milestoneIndex[milestoneId_]].amountInPot;
    }

    /*
        for historical data 
    */
    function getWinningAmount(address user_, uint256 milestone_) override external view returns (uint256){
        return milestoneWinnersAmounts[milestone_][user_];
    }

    /**
    
     */
    function getClaimableAmount(address user_) override external view returns (uint256 claimableAmount) {
        for (uint i = 1; i < milestones.length; i++) {
            claimableAmount += getClaimableAmountForMilestone(user_, milestones[i].startBlock);
        }
    }

    function getAllParticipantsInMilestone(uint256 milestoneId_) override external view returns (address[] memory) {
        return milestoneParticipants[milestoneId_];
    }

    function getParticipationAmountInMilestone(uint256 milestoneId_, address participant_) override external view returns (uint256){
        return participantsAmounts[milestoneId_][participant_];
    }

    function getFuelAddedInMilestone(uint256 milestoneId_, address participant_) override public view returns (uint256){
        return participantsAddedFuel[milestoneId_][participant_];
    }

    function getMilestoneForId(uint256 milestoneId_) override external view returns (MileStone memory){
        return milestones[milestoneIndex[milestoneId_]];
    }

    function getMilestoneAtIndex(uint256 milestoneIndex_) override external view returns (MileStone memory){
        return milestones[milestoneIndex_];
    }

    function getMilestoneIndex(uint256 milestoneId_) override external view returns (uint256){
        return milestoneIndex[milestoneId_];
    }

    function getAllMilestones() override external view returns (MileStone[] memory) {
        return milestones;
    }

    function getMilestonesLength() override external view returns (uint) {
        return milestones.length;
    }

    function getWinners(uint256 milestoneId_) override external view returns (address[] memory) {
        return winners[milestoneId_];
    }

    function getWinningAmounts(uint256 milestoneId_) override external view returns (uint256[] memory){
        return winningAmounts[milestoneId_];
    }

    /**
      *     Returns the amount available to claim by the user_ for milestone_
      */
    function getClaimableAmountForMilestone(address user_, uint256 milestone_) override public view returns (uint256 claimableAmount){
        if (!winningsClaimed[milestone_][user_]) {
            claimableAmount = milestoneWinnersAmounts[milestone_][user_];
        } else {
            claimableAmount = 0;
        }
    }

    function getCurrentActiveMilestone() override public view returns (MileStone memory) {

        for (uint i = 1; i < milestones.length; i++) {// starting to count from 1 is not a typo the 0 is filled with a dummy milestone
            if (milestones[i].startBlock <= block.number && milestones[i].endBlock >= block.number) {// if this is true this is the current milestone
                // add this amount to amountInPot
                return milestones[i];
            }
        }
        // should never happen
        return milestones[0];
    }

    function _createMilestone(uint256 start_, string memory name_) internal {
        milestones.push(
            MileStone(
                start_,
                MAX_INT_TYPE,
                name_,
                0,
                0
            ));
        milestoneIndex[start_] = milestones.length - 1;
    }
}

// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.4;

    struct MileStone {
        uint256 startBlock; // start block
        uint256 endBlock; // endblock 
        string name;
        uint256 amountInPot; // total Vol deposited for this milestone rewards
        uint256 totalFuelAdded; // total fuel added during this milestone
    }

// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.4;

import "../data/structs.sol";

interface IVolumeBEP20 {

    function setLPAddressAsCreditor(address lpPairAddress_) external;

    function setTakeOffBlock(uint256 blockNumber_, uint256 initialFuelTank, string memory milestoneName_) external;

    function addFuelCreditor(address newCreditor_) external;

    function removeFuelCreditor(address creditorToBeRemoved_) external;

    function addFreeloader(address newFreeloader_) external;

    function removeFreeloader(address freeLoaderToBeRemoved_) external;

    function addDirectBurner(address newDirectBurner_) external;

    function removeDirectBurner(address directBurnerToBeRemoved_) external;

    function directRefuel(uint256 fuel_) external;

    function directRefuelFor(uint256 fuel_, address fuelFor_) external;

    function directBurn(uint256 amount_) external;

    function claimNickname(string memory nickname_) external;

    function getNicknameForAddress(address address_) external view returns (string memory);

    function getAddressForNickname(string memory nickname_) external view returns (address);

    function canClaimNickname(string memory newUserName_) external view returns (bool);

    function changeNicknamePrice(uint256 newPrice_) external;

    function getNicknamePrice() external view returns (uint256);

    function getFuel() external view returns (uint256);

    function getTakeoffBlock() external view returns (uint256);

    function getTotalFuelAdded() external view returns (uint256);

    function getUserFuelAdded(address account_) external view returns (uint256);

    function isFuelCreditor(address potentialCreditor_) external view returns (bool);

    function isFreeloader(address potentialFreeloader_) external view returns (bool);

    function isDirectBurner(address potentialDirectBurner_) external view returns (bool);
}

// SPDX-License-Identifier: GPLV3
// contracts/VolumeEscrow.sol
pragma solidity ^0.8.4;

interface IVolumeEscrow {

    function initialize(uint256[] memory allocations_, address volumeAddress_) external;

    function sendVolForPurpose(uint id_, uint256 amount_, address to_) external;

    function addLPCreator(address newLpCreator_) external;

    function removeLPCreator(address lpCreatorToRemove_) external;

    function createLPWBNBFromSender(uint256 amount_, uint slippage) external;

    function createLPFromWBNBBalance(uint slippage) external;

    function transferToken(address token_, uint256 amount_, address to_) external;

    function setLPAddress(address poolAddress_) external;

    function setVolumeJackpot(address volumeJackpotAddress_) external;

    function isLPCreator(address potentialLPCreator_) external returns (bool);

    function getLPAddress() external view returns (address);

    function getVolumeAddress() external view returns (address);

    function getJackpotAddress() external view returns (address);

    function getAllocation(uint id_) external view returns (uint256);}

// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.4;

import '../data/structs.sol';

interface IVolumeJackpot {

    function createMilestone(uint256 startBlock_, string memory milestoneName_) external;

    function setWinnersForMilestone(uint milestoneId_, address[] memory winners_, uint256[] memory amounts_) external;

    function deposit(uint256 amount_, uint fuelContributed_, address creditsTo_) external;

    function depositIntoMilestone(uint256 amount_, uint256 milestoneId_) external;

    function claim(address user_) external;

    function addDepositor(address allowedDepositor_) external;

    function removeDepositor(address depositorToBeRemoved_) external;

    function isDepositor(address potentialDepositor_) external view returns (bool);

    function getPotAmountForMilestone(uint256 milestoneId_) external view returns (uint256);

    function getWinningAmount(address user_, uint256 milestone_) external view returns (uint256);

    function getClaimableAmountForMilestone(address user_, uint256 milestone_) external view returns (uint256);

    function getClaimableAmount(address user_) external view returns (uint256);

    function getAllParticipantsInMilestone(uint256 milestoneId_) external view returns (address[] memory);

    function getParticipationAmountInMilestone(uint256 milestoneId_, address participant_) external view returns (uint256);

    function getFuelAddedInMilestone(uint256 milestoneId_, address participant_) external view returns (uint256);

    function getMilestoneForId(uint256 milestoneId_) external view returns (MileStone memory);

    function getMilestoneAtIndex(uint256 milestoneIndex_) external view returns (MileStone memory);

    function getMilestoneIndex(uint256 milestoneId_) external view returns (uint256);

    function getAllMilestones() external view returns (MileStone[] memory);

    function getMilestonesLength() external view returns (uint);

    function getWinners(uint256 milestoneId_) external view returns (address[] memory);

    function getWinningAmounts(uint256 milestoneId_) external view returns (uint256[] memory);

    function getCurrentActiveMilestone() external view returns (MileStone memory);
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
pragma solidity ^0.8.4;

import "./IBEP20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
    unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
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