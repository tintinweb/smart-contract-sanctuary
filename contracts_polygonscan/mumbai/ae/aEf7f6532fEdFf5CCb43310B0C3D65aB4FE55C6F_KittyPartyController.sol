// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./KittyPartyStateTransition.sol";
import './interfaces/IKittyPartyInit.sol';
import './interfaces/IKittyPartyWinnerStrategy.sol';
import "./interfaces/IKittyPartyYieldGenerator.sol";

/// @title Kitty Party Controller
contract KittyPartyController is KittyPartyStateTransition, IKittenPartyInit {
    bytes32 private inviteHash;
    uint constant MIN_KITTENS = 2;
    uint256[] public partyRoundKittens;

    IKittyPartyWinnerStrategy kpWinnerSelectStrategy;

    KittyInitiator public kittyInitiator;
    KittyPartyFactoryArgs public kPFactory;
    KittyPartyControllerVars public kittyPartyControllerVars;

    IERC20 public dai;
    bytes public calldataForLock;
    bytes public callDataForUnwind;

    /****** EVENTS *******/

    event RefundRequested(uint refund);
    event StopStaking(address party, uint amount);
    event PaidFees(address party, uint fees);
    event WinnersDecided(address party, uint[] winners);
    event PartyCompleted(address party, uint internalState);

    /****** MODIFIERS *******/

    modifier knownKitten(bytes32 _invitedHash) {
        require(inviteHash == _invitedHash);
        _;
    }

    modifier kittenExists(address _kitten) {
        bytes memory checkExistsKitten = abi.encodeWithSignature("checkExists(address,address)", address(this), msg.sender);
        (bool success, bytes memory returnData) = address(kPFactory.litterAddress).staticcall(checkExistsKitten);
        require(success, "NE");
        (bool exists) = abi.decode(returnData, (bool));
        require(exists == true, "NR");
        _;
    }

    modifier minimumKittens(uint numberOfKittens) {
        require(numberOfKittens >= MIN_KITTENS);
        _;
    }

    modifier onlyKreator(){
        require(msg.sender == kittyPartyControllerVars.kreator);
        _;
    }

    /****** STATE MUTATING FUNCTIONS *******/
    
    ///@dev initialize the contract after deploying
    function initialize(
        KittyInitiator calldata _kittyInitiator,
        KittyYieldArgs calldata _kittyYieldArgs,
        KittyPartyFactoryArgs calldata _kPFactory,
        address _kreator,
        uint256 _kreatorStake
    ) 
        public 
    {
        require(kittyPartyControllerVars.internalState == 0, "Already Initialized");
        kittyPartyControllerVars.internalState = 1;
        kittyInitiator = _kittyInitiator;
        kPFactory = _kPFactory;
        kittyPartyControllerVars.kreator = _kreator;
        kittyPartyControllerVars.kreatorStake = _kreatorStake;
        dai = IERC20(_kittyInitiator.daiAddress);
        kpWinnerSelectStrategy = IKittyPartyWinnerStrategy(kittyInitiator.winnerStrategy);

        IKittyPartyYieldGenerator(kittyInitiator.yieldContract).setPartyInfo(
            _kittyYieldArgs.sellTokenAddress,
            _kittyYieldArgs.lpTokenAddress);
        
        durationInDays = _kittyInitiator.durationInDays;
        _initState(_kittyInitiator.timeToCollection);
    }
    
    function setActivityInterval(uint8 _timeToCollection) external onlyKreator {
        timeToCollection = _timeToCollection;
    }

    function setInviteHash(bytes32 _inviteHash) external onlyKreator {
        inviteHash = _inviteHash;
    }

    ///@dev Calling this can change the state without checking conditions!!! Use cautiously!
    function changeState() external onlyKreator returns (bool success) {
        _timedTransitions();
        return true;
    }

    ///@dev perform the actual value transfer and add Kitten to the party
    function depositAndAddKittenToParty(bytes32 _inviteHash) 
        external 
        knownKitten(_inviteHash)
        returns (bool)
    {
        _timedTransitions();
        _atStage(KittyPartyStages.InitialCollection);
        kittyPartyControllerVars.localKittens = kittyPartyControllerVars.localKittens + 1;

        require(kittyInitiator.maxKittens >= kittyPartyControllerVars.localKittens);
        require(msg.sender != kittyPartyControllerVars.kreator, "Kreator cannot join own party");
        require(numberOfRounds == 0, "Rounds were already initiated");
       
        bytes memory addKitten = abi.encodeWithSignature("addKitten(address)", msg.sender);
        (bool success,) = address(kPFactory.litterAddress).call(addKitten);
        require(success, "Kitten not added");
        
        depositForYield();
        IKittyPartyYieldGenerator(kittyInitiator.yieldContract).createLockedValue(calldataForLock);

        return true;
    }

    function setCallDataForYield(bytes memory _calldataForLock, bytes memory _callDataForUnwind) external onlyKreator {
        calldataForLock = _calldataForLock;
        callDataForUnwind = _callDataForUnwind;
    }

    ///@dev This function adds deposits for each round
    function addRoundDeposits() 
        external 
        kittenExists(msg.sender) 
        returns (bool)
    {        
        _timedTransitions();
        _atStage(KittyPartyStages.Collection);
        depositForYield();
        IKittyPartyYieldGenerator(kittyInitiator.yieldContract).createLockedValue(calldataForLock);
        return true;
    }

    function depositForYield()
        internal
    {
        uint256 daiBalance = dai.balanceOf(address(msg.sender)); 
        require(daiBalance >= kittyInitiator.amountInDAIPerRound, "Not enough balance");
        uint256 allowance = dai.allowance(msg.sender, address(this));
        require(allowance >= kittyInitiator.amountInDAIPerRound, "Please approve amount");
        require(dai.transferFrom(address(msg.sender), address(kittyInitiator.yieldContract), kittyInitiator.amountInDAIPerRound), 'Transfer Failed');
        
        bytes memory getIndex = abi.encodeWithSignature("getIndex(address,address)",address(this),msg.sender);
        (bool success, bytes memory kittenIndex) = address(kPFactory.litterAddress).call(getIndex);
        require(success, "Kitten not added");
        (uint256 index) = abi.decode(kittenIndex, (uint256));
        partyRoundKittens.push(index);
    }

    ///@dev This is called by the kreator once the kreator verifies that all the kittens have deposited initial amount for the first round.
    function applyInitialVerification() 
        external
        minimumKittens(kittyPartyControllerVars.localKittens)
    {
        _timedTransitions();
        _atStage(KittyPartyStages.Staking);
        require(kittyPartyControllerVars.internalState == 1, "Rounds were already initiated");
        kittyPartyControllerVars.internalState = 2;

        if(kittyPartyControllerVars.kreatorStake >= kittyInitiator.amountInDAIPerRound * kittyInitiator.maxKittens) {
            //Multiple Rounds
            numberOfRounds = kittyPartyControllerVars.localKittens;
        } else {
            //only minimum stake so only single round
            numberOfRounds = 0;
        }
    }

    ///@dev This is used for changing state from Collection -> Staking
    function startStakingMultiRound() external {
        _atStage(KittyPartyStages.Collection);
        require(partyRoundKittens.length == kittyPartyControllerVars.localKittens, "Kitten Missing!");
        _timedTransitions();
        _atStage(KittyPartyStages.Staking);
    }

    ///@dev This is used for changing state from Payout -> Collection for multiRound
    function startNextRound() external {
        _atStage(KittyPartyStages.Payout);
        _timedTransitions();
        _atStage(KittyPartyStages.Collection);
    }


    ///@dev Stop the staking and push the yield generated for the specific kitty party to the treasury
    function stopStaking() external {
        _timedTransitions();
        _atStage(KittyPartyStages.Payout);
        
        kpWinnerSelectStrategy.initiateCheckWinner(kittyPartyControllerVars.localKittens);
        IKittyPartyYieldGenerator(kittyInitiator.yieldContract).unwindLockedValue(callDataForUnwind);
        
        bytes memory yieldGenerated = abi.encodeWithSignature("yieldGenerated(address)",address(this));
        (bool successYield, bytes memory returnData) = address(kittyInitiator.yieldContract).staticcall(yieldGenerated);
        require(successYield, "YE1");
        (kittyPartyControllerVars.profit) = abi.decode(returnData, (uint256));
        emit StopStaking(address(this), kittyPartyControllerVars.profit);
    }

     /// @dev pay system and kreator fees
    function payOrganizerFees() external {
        _atStage(KittyPartyStages.Payout);
        require(kittyPartyControllerVars.profit > 0);
        uint256 amountToSendKreator = kittyPartyControllerVars.profit * kittyInitiator.kreatorFeesInBasisPoints / 10000;
        uint256 amountToSendDAO = kittyPartyControllerVars.profit * kittyInitiator.daoFeesInBasisPoints / 10000;
        kittyPartyControllerVars.profitToSplit = kittyPartyControllerVars.profit - (amountToSendKreator + amountToSendDAO);
        kittyPartyControllerVars.profit = 0;
        mintTokens(kittyPartyControllerVars.kreator, amountToSendKreator, 0);
        mintTokens(kPFactory.daoTreasuryContract, amountToSendDAO, 0);
        emit PaidFees(address(this), amountToSendKreator + amountToSendDAO);
    }

    ///@notice send KPR to the winners to redeem the actual amount from the treasury contract
    function applyWinnerStrategy() external {
        _atStage(KittyPartyStages.Payout);
        require(kittyPartyControllerVars.profitToSplit > 0);

        uint256 amountToSend = (kittyPartyControllerVars.profitToSplit 
                                / kpWinnerSelectStrategy.getLength());
        kittyPartyControllerVars.profitToSplit = 0;
        uint[] memory winners = kpWinnerSelectStrategy.getWinners();
        batchMintReceiptTokens(winners, amountToSend);
        delete partyRoundKittens;//clear the current round participants
        emit WinnersDecided(address(this), winners);
    }
    
    ///@notice This is to be called after party completion to mint the NFT's and tokens to the kittens and kreator
    function applyCompleteParty() external {
        _timedTransitions();
        _atStage(KittyPartyStages.Completed);
        require(kittyPartyControllerVars.internalState == 2);
        kittyPartyControllerVars.internalState = 3;
        bytes memory payload = abi.encodeWithSignature(
            "transferBadgesOnCompletion(address,address)", 
            kPFactory.litterAddress,
            address(this)
        );
        (bool success,) = address(kPFactory.accountantContract).call(payload);
        require(success);

        //Finally give the Kreator a kreator badge for completing the round and also return all the DAI tokens
        mintTokens(kittyPartyControllerVars.kreator, 1, 4);
        mintTokens(kittyPartyControllerVars.kreator, kittyPartyControllerVars.kreatorStake, 0);
        emit PartyCompleted(address(this), kittyPartyControllerVars.internalState);  
    }

    /// @dev mint receipt tokens via the Kitty Party Accountant, receipt tokens can be claimed from the treasury
    function mintTokens(
        address mintTo, 
        uint256 amount, 
        uint256 tokenType
    ) 
        private
    {
        require(mintTo != address(0));
        bytes memory payload = abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)", 
            mintTo, 
            tokenType, 
            amount, 
            ""
        );
        // for kittyPartyControllerVars.profit to be calculated we need to unwind the position succesfuly the kittyPartyControllerVarsprofit - X% to kreator and Y% to contract becomes the winning
        (bool success,) = address(kPFactory.accountantContract).call(payload);
        require(success);
    }

    function batchMintReceiptTokens(
        uint256[] memory kittenIndexes,
        uint256 amountToSend
    )
        private
    {
        bytes memory payload = abi.encodeWithSignature(
            "mintToKittens(address,address,uint256[],uint256)",
            kPFactory.litterAddress,
            address(this), 
            kittenIndexes, 
            amountToSend
        );

        (bool success,) = address(kPFactory.accountantContract).call(payload);
        require(success, "Batch receipt failed");
    }

    /// @dev if the MIN_KITTENS have not joined in time, the kreator can seek refund before the internal state changes to party started
    function issueRefund() 
        external
        onlyKreator
    {
        require(stage != KittyPartyStages.Payout, "Cannot refund in payout");
        require(stage != KittyPartyStages.Completed, "Cannot refund in Completed");
        require(kittyPartyControllerVars.internalState  != 3, "Cannot refund");
        kittyPartyControllerVars.internalState = 3; // set the party as finished
        _nextStage(5);

        if(kittyPartyControllerVars.localKittens > 0) {
            IKittyPartyYieldGenerator(kittyInitiator.yieldContract).unwindLockedValue(callDataForUnwind);
            batchMintReceiptTokens(partyRoundKittens, kittyInitiator.amountInDAIPerRound);
            delete partyRoundKittens;//clear the current round participants
        }
        // The fees here are taking into account a sybil attack
        uint kreatorRefundedAmount = kittyPartyControllerVars.kreatorStake * kittyInitiator.daoFeesInBasisPoints / 100;
        mintTokens(kittyPartyControllerVars.kreator, kreatorRefundedAmount, 0);
        emit RefundRequested(kreatorRefundedAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;

contract KittyPartyStateTransition {

    enum KittyPartyStages {
        InitialCollection,
        Collection,
        Staking,
        Payout,
        Completed,
        Refund
    }   
    //Set of valid states for the kitty party contract
    //InitialCollection: This collection is different because it is before start of the rounds
    //Collection: Pre-Round verification completed, collection criteria can be checked for
    //Staking: The colection has been completed successfully, the asset can now be staked on respective protocols, we open up for bids in this state
    //Payout: The assets are withdrawn from the repective contracts, a winner is chosen at random
    //Completed: The kitty-party is over
    //Refund: Invalid state jump goto Refund -> create a provision to exit system for all stakeholders and refund only allowed to transition from Initial Collection
    KittyPartyStages public stage = KittyPartyStages.InitialCollection;
    //initial state is verification state
    uint256 public lastStageTime;
    uint16 public durationInDays;
    uint8 public currentRound;
    uint8 public timeToCollection;
    uint16 public numberOfRounds;

    event Completed();
    event StageTransition(uint prevStage, uint nextStage);
    
    modifier transitionAfter() {
        _;
        _nextStage(1);
    }
    
    function getStage() external view returns (uint) {
      return uint(stage);
    }

    function timeSinceChange() external view returns (uint) {
        return block.timestamp - lastStageTime;
    }

    function _atStage(KittyPartyStages _stage) internal view {
        require(stage == _stage, "Not in the expected stage");
    }

    function isTransitionRequired() external view returns(uint8) {
        if ((stage == KittyPartyStages.InitialCollection && (block.timestamp >= (lastStageTime + (timeToCollection * 1 hours)))) ||
            (stage == KittyPartyStages.Collection && block.timestamp >= (lastStageTime + (24 * 1 hours))) ||
            (stage == KittyPartyStages.Staking && block.timestamp >= (lastStageTime + (durationInDays * 1 hours))) ||
            (stage == KittyPartyStages.Payout && block.timestamp >= (lastStageTime + (8 * 1 hours)) && (numberOfRounds > currentRound)) ||
            (stage == KittyPartyStages.Payout && block.timestamp >= (lastStageTime + (8 * 1 hours)) && (numberOfRounds <= currentRound))) {
            return (uint8(stage) + (uint8(stage) <= 2 ? 0:(numberOfRounds > currentRound ? 0 : 1)));
        } else {
            return (88);
        }
    }
    
    function _timedTransitions() internal {
        if (stage == KittyPartyStages.InitialCollection && (block.timestamp >= (lastStageTime + (timeToCollection * 1 hours)))) {
           _nextStage(2);
        }
        else if (stage == KittyPartyStages.Collection && block.timestamp >= (lastStageTime + (24 * 1 hours))) {
            _nextStage(1);
        }
        else if (stage == KittyPartyStages.Staking && block.timestamp >= (lastStageTime + (durationInDays * 1 hours))) {
            _nextStage(1);
        }
        else if (stage == KittyPartyStages.Payout && block.timestamp >= (lastStageTime + (8 * 1 hours)) && (numberOfRounds > currentRound)) {
            stage = KittyPartyStages(1);
            currentRound++;
        }
        else if (stage == KittyPartyStages.Payout && block.timestamp >= (lastStageTime + (8 * 1 hours)) && (numberOfRounds <= currentRound)) {
           _nextStage(1);
        }
    }

    function _nextStage(uint8 jumpTo) internal {
        uint nextStageValue = uint(stage) + jumpTo;
        if(nextStageValue > 6){
            nextStageValue = 6;
        }
        emit StageTransition(uint(stage), nextStageValue);
        stage = KittyPartyStages(nextStageValue);
        lastStageTime = block.timestamp;
    }

    function _initState(uint8 _timeToCollection) internal {
        require(stage ==  KittyPartyStages.InitialCollection, "Not in the InitialCollection stage");
        lastStageTime = block.timestamp;
        timeToCollection = _timeToCollection;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IKittenPartyInit {
    struct KittyInitiator { 
        uint8 kreatorFeesInBasisPoints;
        uint8 daoFeesInBasisPoints;
        uint8 winningStrategy;
        uint8 timeToCollection; 
        uint16 maxKittens;
        uint16 durationInDays;
        uint256 amountInDAIPerRound;
        bytes32 partyName;
        address daiAddress;
        address yieldContract; 
        address winnerStrategy; 
    }

    struct KittyYieldArgs {
        address sellTokenAddress;
        address lpTokenAddress;
    }
    
    struct KittyPartyFactoryArgs {
        address tomCatContract;
        address accountantContract;
        address litterAddress;
        address daoTreasuryContract;
        address keeperContractAddress;
    }

    struct KittyPartyControllerVars {
        address kreator;
        uint256 kreatorStake;
        uint profit;
        uint profitToSplit;
        // The number of kittens inside that party
        uint8 localKittens;
        // A state representing whether the party has started and completed
        uint8 internalState;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Kitty Party Yield Generator
 */
interface IKittyPartyWinnerStrategy {
function initiateCheckWinner(uint _numberOfKittens) external;
function getWinners() external view returns (uint256[] memory);
function getWinnerAtLocation(uint i) external view returns (uint256);
function getLength() external view returns (uint);
}

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Kitty Party Yield Generator
 */
interface IKittyPartyYieldGenerator {
    struct KittyPartyYieldInfo { 
      uint256 lockedAmount;
      uint256 yieldGeneratedInLastRound;
      address sellTokenAddress;
      address poolAddress;
      address lpTokenAddress;
    }
    
    /**
     * @dev Create a new LockedValue in the pool
     */
    function createLockedValue(bytes calldata) external payable returns (uint256);
 
    /**
     * @dev Unwind a LockedValue in the pool
     */
    function unwindLockedValue(bytes calldata) external returns (uint256);

    /**
     * @dev Returns the address of the treasury contract
     */
    function treasuryAddress() external view returns (address);

    /**
     * @dev Returns the amount of tokens staked for a specific kitty party.
     */
    function lockedAmount(address) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens staked for a specific kitty party.
     */
    function yieldGenerated(address) external view returns (uint256);

    /**
     * @dev Returns the pool in which the kitty party tokens were staked
     */
    function lockedPool(address) external view returns (address);

    /**
     * @dev Returns the pool in which the kitty party tokens were staked
     */
    function setPlatformRewardContractAddress(address payable,address) external;
    function setPlatformDepositContractAddress(address payable) external;
    function setPlatformWithdrawContractAddress(address payable) external;
    function setPartyInfo(address, address) external;
}