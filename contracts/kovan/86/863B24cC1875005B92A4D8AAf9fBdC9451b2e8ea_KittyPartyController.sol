// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./KittyPartyWinnerSelectStrategy.sol";
import "./KittyPartyStateTransition.sol";
import './interfaces/IKittyPartyInit.sol';

/// @title Kitty Party Controller
contract KittyPartyController is KittyPartyStateTransition, IKittenPartyInit {
    bytes32 private inviteHash;

    KittyPartyWinnerSelectStrategy kpWinnerSelectStrategy;
    
    address accountantContract;
    address yieldGeneratorAddress;
    address kittyPartyDAOTreasury;
    address oracleAddress;
    address litterAddress;
    uint256 kreatorStake;
    bool vrfEnabled = true;
    //TODO: increase to 2 in production
    uint8 constant MIN_KITTENS = 1;
    uint16 maxKittens;

    address public kreator;
    uint8 public internalState;
    uint16 public localKittens;
    uint256 public amountInDAIPerRound;
    uint256 public kreatorFeesInBasisPoints = 1000; //10% to kreator
    uint256 public daoFeesInBasisPoints = 100; //1% to DAO - both are out of profit and not principle
    bytes32 public partyName;
    IERC20 public dai;

    /****** MODIFIERS *******/

    modifier knownKitten(bytes32 _invitedHash) {
        require(inviteHash == _invitedHash);
        _;
    }

    modifier kittenExists(address _kitten) {
        bytes memory checkExistsKitten = abi.encodeWithSignature("checkExists(address,address)", address(this), msg.sender);
        (bool success, bytes memory returnData) = address(litterAddress).staticcall(checkExistsKitten);
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
        require(msg.sender == kreator);
        _;
    }

    modifier onlyDAOAddress(){
        require(msg.sender == kittyPartyDAOTreasury);
        _;
    }
    
    modifier onlyOracle(){
        require(msg.sender == oracleAddress);
        _;
    }

    /****** STATE MUTATING FUNCTIONS *******/
    
    ///@dev initialize the contract after deploying
    function initialize(
        KittyInitiator calldata _kittyInitiator,
        address _accountantContract,
        address _kittyPartyDAOTreasury,
        address _kreator,
        address _oracleAddress,
        address _litterAddress,
        uint256 _kreatorStake
    ) 
        public 
    {
        require(internalState == 0, "Already Initialized");
        internalState = 1;
        partyName = _kittyInitiator.partyName;
        durationInDays = _kittyInitiator.durationInDays;
        amountInDAIPerRound = _kittyInitiator.amountInDAIPerRound;
        kpWinnerSelectStrategy = new KittyPartyWinnerSelectStrategy(
            _kittyInitiator.winningStrategy,
            _kittyInitiator.vrfEnabled
        );

        accountantContract = _accountantContract;
        yieldGeneratorAddress = _kittyInitiator.yieldContract;
        kittyPartyDAOTreasury = _kittyPartyDAOTreasury;
        oracleAddress = _oracleAddress;
        litterAddress = _litterAddress;
        timeToCollection = _kittyInitiator.timeToCollection;
        maxKittens = _kittyInitiator.maxKittens;
        dai = IERC20(_kittyInitiator.daiAddress);
        kreator = _kreator;
        kreatorStake = _kreatorStake;

        _initState();
    }
    
    //TODO: DAO related updates should be at factory level
    function setKreatorFees(uint8 _kreatorFeesInBasisPoints) external onlyDAOAddress {
        kreatorFeesInBasisPoints = _kreatorFeesInBasisPoints;
    }

    function setDAOFees(uint8 _daoFeesInBasisPoints) external onlyDAOAddress {
        daoFeesInBasisPoints = _daoFeesInBasisPoints;
    }

    function setActivityInterval(uint8 _timeToCollection) external onlyKreator {
        timeToCollection = _timeToCollection;
    }

    function setInviteHash(bytes32 _inviteHash) external onlyKreator {
        inviteHash = _inviteHash;
    }

    function changeState() external returns (bool success) {
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
        require(msg.sender != kreator, "Kreator cannot join own party");
        uint256 daiBalance = dai.balanceOf(address(msg.sender));
        require(daiBalance >= amountInDAIPerRound, "Not enough balance");
        require(numberOfRounds == 0, "Rounds were already initiated");
        uint256 allowance = dai.allowance(msg.sender, address(this));

        require(allowance >= amountInDAIPerRound, "Please approve");

        bytes memory addKitten = abi.encodeWithSignature("addKitten(address)", msg.sender);
        (bool success,) = address(litterAddress).call(addKitten);
        require(success, "NK");
        localKittens = localKittens + 1;
        require(maxKittens >= localKittens);
    
        require(dai.transferFrom(address(msg.sender), address(yieldGeneratorAddress), amountInDAIPerRound), 'Transfer Failed');
        return true;
    }

    ///@dev add deposits for each round
    //TODO: Streamline this depositAndAddKittenToParty and above and reduce code.
    function addRoundDeposits() 
        external 
        kittenExists(msg.sender) 
        returns (bool)
    {        
        _timedTransitions();
        _atStage(KittyPartyStages.Collection);
        uint256 daiBalance = dai.balanceOf(address(msg.sender)); 
        require(daiBalance >= amountInDAIPerRound, "Not enough balance");
        uint256 allowance = dai.allowance(msg.sender, address(yieldGeneratorAddress));
        require(allowance >= amountInDAIPerRound, "Please approve amount");
        require(dai.transferFrom(address(msg.sender), address(yieldGeneratorAddress), amountInDAIPerRound), 'Transfer Failed');
        return true;
    }

    ///@dev This is called by the kreator once the kreator verifies that all the kittens have deposited initial amount for the first round.
    function applyInitialVerification() 
        external
        onlyKreator()
        minimumKittens(localKittens)
    {
        //We check whether the admin has kept stake, if the party is not fully covered it will only do single round
        //TODO: split this logic so that there is more flexibility, that is keep no of rounds separate from no of Kittens
        //TODO: create a refund state such that balance amount gets returned in case this is not called by kreator, signalling that they do not want to start
        _timedTransitions();
        _atStage(KittyPartyStages.InitialCollection);
        require(internalState == 1, "Rounds were already initiated");
        internalState = 2;
        
        if(kreatorStake >= amountInDAIPerRound * maxKittens) {
            //Multiple Rounds
            numberOfRounds = localKittens;
        } else {
            //only minimum stake so only single round
            numberOfRounds = 0;
        }
    }

    ///@dev This will be auto called by the oracle later for testing we keep it as public
    ///@dev this is where the receipts are given to the winners to redeem the actual amount from the treasury contract
    ///TODO: If state was never transition here and time passes, then how to give users payout
    function applyWinnerStrategy() external {
        _timedTransitions();
        _atStage(KittyPartyStages.Payout);
        kpWinnerSelectStrategy.initiateCheckWinner(localKittens);
        //below for loop only required for winner address and also add kreator and the treasury contract
        // bytes memory yieldGenerated = abi.encodeWithSignature("yieldGenerated()");
        // (bool successYield, bytes memory returnData) = address(yieldGeneratorAddress).staticcall(yieldGenerated);
        // require(successYield);
        (uint profit) = 20000000000000000000;// abi.decode(returnData, (uint256)); //commented for testing

        uint256 amountToSendKreator = profit * kreatorFeesInBasisPoints / 10000;
        uint256 amountToSendDAO = profit * daoFeesInBasisPoints / 10000;
        uint256 profitToSplitAmongstWinners = profit - (amountToSendKreator + amountToSendDAO);
        mintTokens(kreator, amountToSendKreator, 0);
        mintTokens(kittyPartyDAOTreasury, amountToSendDAO, 0);

        uint  amountToSend = amountInDAIPerRound + (profitToSplitAmongstWinners / kpWinnerSelectStrategy.getLength());
        uint[] memory winners = kpWinnerSelectStrategy.getWinners();
        bytes memory payload = abi.encodeWithSignature(
            "mintToWinners(address,address,uint256[],uint256)", 
            litterAddress,
            address(this), 
            winners, 
            amountToSend
        );
        (bool success,) = address(accountantContract).call(payload);
        require(success);
    }
    
    ///@dev This is to be called after party completion to mint the NFT's and tokens to the kittens and kreator
    function applyCompleteParty() external {
        _timedTransitions();
        _atStage(KittyPartyStages.Completed);
        require(internalState == 2);
        internalState = 3;
        bytes memory payload = abi.encodeWithSignature(
            "transferBadgesOnCompletion(address,address)", 
            litterAddress,
            address(this)
        );
        (bool success,) = address(accountantContract).call(payload);
        require(success);

        //Finally give the Kreator a kreator badge for completing the round and also return all the DAI tokens
        mintTokens(kreator, 1, 4);
        mintTokens(kreator, kreatorStake, 0);
    }


    function mintTokens(
        address mintTo, 
        uint256 amount, 
        uint256 tokenType
    ) 
        private 
    {
        bytes memory payload = abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)", 
            mintTo, 
            tokenType, 
            amount, 
            ""
        );
        // for profit to be calculated we need to unwind the position succesfuly the profit - X% to kreator and Y% to contract becomes the winning
        (bool success,) = address(accountantContract).call(payload);
        require(success);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "./base/KittyPartyWinnerSelectionOptions.sol";

contract KittyPartyWinnerSelectStrategy is  KittyPartyWinnerSelectionOptions {
    uint256 public randomness;
    uint256 internal fee;
    uint256 numberOfKittens;

    uint256[] public winnerIndexes;
    uint256[] public prevWinnerIndexes;
    address kittens;
    
    bytes32 internal keyHash;

    bytes32 constant NULL = "";

    constructor(uint8 _winnerStrategy, bool _vrfEnabled) 
      // VRFConsumerBase(
      //     0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
      //     0x326C977E6efc84E512bB9C30f76E30c160eD06FB // LINK Token
      // )
      KittyPartyWinnerSelectionOptions(_winnerStrategy, _vrfEnabled)
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; 
    }

    function initiateCheckWinner(uint _numberOfKittens) external {
      //clear previous winners
      delete winnerIndexes;
      //check strategy call relevant functions based on strategy call
      //Also implement a better strategy for a random user provided seed
      numberOfKittens = _numberOfKittens;
      if (winnerStrategy == WinningStrategy.DistributeEqual) {
          for (uint i = 0; i < numberOfKittens; i++) {
              winnerIndexes.push(i);
          }
      } else if (winnerStrategy == WinningStrategy.Bid) {
        //check the lowest bid value and call setWinner
      } else{ 
        runLottery();
      }
    }
        
    function runLottery()
        private
        returns (bytes32 requestId)
    {
        if (vrfEnabled == false) {
          fulfillRandomness(NULL, uint256(keccak256(abi.encode(block.timestamp + block.difficulty))));
          return NULL;
        } else {
          // require(
          //     LINK.balanceOf(address(this)) >= fee,
          //     "Not enough LINK - fill contract with faucet"
          // );
          // return requestRandomness(keyHash, fee);
        }
    }

    /**
    * Callback function used by VRF Coordinator
    */
    function fulfillRandomness(bytes32, uint256 _randomness)
        internal
        // override
    {
        randomness = _randomness;
        //do a callback to msg.sender
        setLotteryWinner();
    }

    function setLotteryWinner() private {
      if (winnerStrategy == WinningStrategy.SingleLosslessLotteryWinnerPerRound) {
        uint256 randomResult = (randomness % numberOfKittens) + 1;

        winnerIndexes[0] = randomResult;
        // winnerAddresses.push(Kittens(kittens).getValueAt(randomResult));
      } else { 
        //use randomness to choose 3 individual winners
      }
    }

    function getWinners() external view returns (uint256[] memory) {
        return winnerIndexes;
    }

    function getWinnerAtLocation(uint i) external view returns (uint256){
        return winnerIndexes[i];
    }

    function getLength() external view returns (uint) {
        return winnerIndexes.length;
    }
}

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;

//

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
    
    //TODO: Change to days from hours/ minutes/ seconds before deployment
    function _timedTransitions() internal {
        if (stage == KittyPartyStages.InitialCollection && (block.timestamp >= (lastStageTime + (timeToCollection * 1 days)))) {
           _nextStage(2);
        }
        if (stage == KittyPartyStages.Collection && block.timestamp >= (lastStageTime + (3 * 1 hours))) {
            _nextStage(1);
        }
        if (stage == KittyPartyStages.Staking && block.timestamp >= (lastStageTime + (durationInDays * 1 days))) {
            _nextStage(1);
        }
        if (stage == KittyPartyStages.Payout && block.timestamp >= (lastStageTime + (8 * 1 hours)) && (numberOfRounds > currentRound)) {
            stage = KittyPartyStages(1);
            currentRound++;
        }
        if (stage == KittyPartyStages.Payout && block.timestamp >= (lastStageTime + (8 * 1 hours)) && (numberOfRounds <= currentRound)) {
           _nextStage(1);
        }
    }

    function _nextStage(uint8 jumpTo) internal {
        uint nextStageValue = uint(stage) + jumpTo;
        emit StageTransition(uint(stage), nextStageValue);
        stage = KittyPartyStages(nextStageValue);
        lastStageTime = block.timestamp;
    }

    function _initState() internal {
        require(stage ==  KittyPartyStages.InitialCollection, "Not in the InitialCollection stage");
        lastStageTime = block.timestamp;
    }
}

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.2;

interface IKittenPartyInit {
    struct KittyInitiator {      
        address daiAddress;
        uint8 winningStrategy;
        bool vrfEnabled; 
        address yieldContract; 
        uint16 maxKittens;
        uint16 durationInDays;
        uint8 timeToCollection; 
        uint256 amountInDAIPerRound;
        bytes32 partyName;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;


/// @title Kitty Party Types and options
/// @notice Utilized by factory while deciding what party to start
/// There are three parties 
contract KittyPartyWinnerSelectionOptions {
  bool internal vrfEnabled;
  enum WinningStrategy {
    Bid,
    DistributeEqual,
    SingleLosslessLotteryWinnerPerRound,
    SingleLotteryWinnerPerRound,
    MultipleLotteryWinnersPerRound
  }
  
  //default winning strategy
  WinningStrategy public winnerStrategy = WinningStrategy.SingleLosslessLotteryWinnerPerRound;
  constructor(
    uint8 _winningStrategy, 
    bool _vrfEnabled
  ) {
    winnerStrategy = WinningStrategy(_winningStrategy);
    vrfEnabled = _vrfEnabled;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}