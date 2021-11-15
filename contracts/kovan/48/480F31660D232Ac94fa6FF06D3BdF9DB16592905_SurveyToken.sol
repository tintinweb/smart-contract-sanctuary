//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8;

/**
 * Import statements for integration of interfaces and other implementations
 **/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";             // ERC20 interface by openzeppelin
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";     // Chainlinks Verifiable Randomness


contract SurveyToken is ERC20, VRFConsumerBase {
    string private _name;                                       // Title of the survey              (-> Set in constructor)
    string private _symbol;                                     // Representation of the token      (-> Set in constructor)
    uint8 private _decimals = 0;                                // Tokens are integers              Overload the value in OpenZeppelin
    uint256 private _totalsupply = 5000;                        // Up to 5000 pending particpants at a time, constant


    enum ContractState {                                        // The different states the contract might be in chronological order
        CREATED,                                                    // Survey was created, sharing tokens possible, answering not yet allowed
        ACTIVE,                                                     // Survey active: Answering, Participation in lottery, Token Transfers
        EXPIRED,                                                    // Survey timed out: Call prepareRandomNumber and runLottery
        PAYOUT,                                                     // Winners may claim their prizes
        FINISHED }                                                  // Winners may still claim prizes, contract can be deleted (optionally)
    ContractState private currentState;                         // Current state of the survey

    address private owner;                                      // The address of the owner of the contract (the survey's creator)
    uint32[] private answersList;                               // A list containing all the answers

    address[] private raffleParticipants;                       // List of all the participants in the raffle
    address[] private raffleWinners;                            // The addresses of the winners of the raffle
    
    // Oracle configuration: Depending on network -> Set via Constructor
    address private coordinatorAddress;     // Chainlink VRF Coordinator address
    address private linkTokenAddress;       // LINK token address
    bytes32 internal keyHash ;              // ChainLink Key Hash
    uint256 internal fee;  // Fee in LINK (18 decimals: e.g. 1 LINK = 1 * 10**18 )

    uint256 private randomNumber;                       // The random number for the raffle. Will be determined after the survey is done.
    bool private randomNumberDrawn = false;             // Holds, if a RN is already drawn
    bytes32 randomNumberRequestId;                      // The ID of the request we make to ChainLink
    uint256 private randomNumberQueryTimestamp = 0;     // Holds the timestamp, when a RN was queried from the oracle

    uint256[] private prizes;                          // Amount of ETH in Gwei for the prizes, starting with 1st (1st, 2nd, 3rd, …)

    uint256 private timestampEndOfSurvey;               // Holds the timestamp when the survey will be over (in seconds after Epoch)
    uint256 private durationCollectionPeriod;           // Holds the duration of the collection period
    uint256 private timestampEndOfCollection;           // Holds the timestamp when the survey payout is over (in seconds after Epoch)
    /**
     * Timestamp with Timestamp of end of survey + amount of time (in SECONDS) for the winners to claim their prize after they have been drawn;
     * Should be at least 2 Weeks (= 1209600 Seconds)
     * After that period the contract may be destroyed by the owner and the prizes expire.
     * This destruction is optional though, since the owner can decide to leave the contract.
     **/
    
    // NOTE: Current values are for testing only, will be increased for real deployment
    uint256 minDurationActiveSeconds = 30;          // Minimum duration a survey has to be active before expiring
    uint256 maxDurationActiveSeconds = 31536000;    // Maximum duration a survey may be active before expiring, ~1 year = 31536000s
    uint256 minDurationPayoutSeconds = 30;          // Minimum payout phase duration a surv˚ey is in before anything can be deleted/ ETH can be transferred back, should be > 1 week usually
    uint256 oracleWaitPeriodSeconds = 30;         // Time to wait for a callback from the oracle before enabling the fallback randomness source


    constructor(string memory _tokenName, string memory _tokenSymbol, address _coordinatorAddress, address _linkTokenAddress, bytes32 _keyHash, uint256 _fee) 
        ERC20(
            _tokenName,
             _tokenSymbol
        )
        VRFConsumerBase(
            _coordinatorAddress, // VRF Coordinator
            _linkTokenAddress  // LINK Token
        )
        {
        coordinatorAddress = _coordinatorAddress;
        linkTokenAddress = _linkTokenAddress;
        keyHash = _keyHash;
        fee = _fee;
        _symbol = _tokenSymbol;
        _name = _tokenName;
        _mint(msg.sender, _totalsupply);            // Get the initial Supply into the contract: Amount of tokens that exist in total
        owner = msg.sender;                         // The creator of the contract (and the survey) is also the owner
        currentState = ContractState.CREATED;       // We start in this state
    }
    

    // ------ ------ ------ ------ ------ ------
    // ------ Access modifiers definitions -----
    // ------ ------ ------ ------ ------ ------

    // Only the owner of the contract has access
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner of this contract may invoke this function.");
        _;
    }

    // Only accounts with at least one token have access
    modifier onlyWithToken() {
        require(balanceOf(msg.sender) > 0);
        _;
    }
    
    modifier onlyActiveSurvey() {
        require(currentState == ContractState.ACTIVE , "The survey is not active.");
        require(block.timestamp <= timestampEndOfSurvey, "Survey is not active anymore.");
        _;
    }
    
    modifier onlyExpiredSurvey(){
        require(block.timestamp > timestampEndOfSurvey, "The survey is still active.");
        require(currentState > ContractState.CREATED, "The survey was not yet created.");
        require(currentState <= ContractState.EXPIRED, "The survey is not in the active or expired state."); // Only ACTIVE or EXPIRED are allowed
        currentState = ContractState.EXPIRED; // Update the state again
        _;
    }
    
    modifier onlyPayoutSurvey(){
        require(currentState >= ContractState.PAYOUT, "The survey is not ready to payout, yet.");
        _;
    }
    
    modifier onlyFinishedSurvey() {
        require(timestampEndOfCollection < block.timestamp, "The collection period is not over, yet.");
        require(currentState >= ContractState.PAYOUT, "The survey state is still too low.");
        currentState = ContractState.FINISHED;
        _;
    }


    // ------ ------ ------ ------ ------ ------ //
    // ------ Fallback-function ----- //
    // ------ ------ ------ ------ ------ ------ //

    /**
     * This function gets called when no other function matches (-> Will fail in this case) or when paying in some ETH
     */
    fallback () external payable {
        revert(); // We do not allow calls that do not match any function
    }

    /**
    *   This function is called when no data is supplied in the call. It is used to add ETH to this contract.
    */
    receive () external payable {
        // 'address(this).balance' gets updated automatically with the sent ETH
    }
    
    
    
    // ------ ------ ------ ------ ------ ------ ----- ----- //
    // ------ Checking the current state of the contract --- //
    // ------ ------ ------ ------ ------ ------ ----- ----- // 


    /**
        Returns the current state of the survey
    */
    function getSurveyState() external view returns (ContractState){
        return currentState;
    }

    /**
        Overrides the value in OpenZeppelin, which would be 18 by default
    */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    

    // ------ ------ ------ ------ ------ ------ //
    // ------ Starting the survey ----- //
    // ------ ------ ------ ------ ------ ------ //

    /**
     * This function checks if all prerequisites of the survey are fulfilled and starts the
     * survey.
     * CAUTION: Starting a survey cannot be reverted and leads to drawing a winner after the set timeframe has passed
     *          The contract cannot be reused after it has been started and completed, therefore only start if everything is set and ready!
     * @param surveyDurationSeconds: Duration of the survey in SECONDS (!!)
     * @param payoutPeriodSeconds: Duration of the collection/ payout period in SECONDS (!!)
     * @param prizesInGwei: The prizes that are payed to the winners; Starting with the highest one (1. prize, 2nd prize, ...)
     * The balance of the contract MUST be > than the sum of all prizes and some headroom for gas, otherwise this function will revert
     * prize expires
     **/
    function startSurvey(uint256 surveyDurationSeconds, uint256 payoutPeriodSeconds, uint256[] memory prizesInGwei) public onlyOwner{
        require(currentState == ContractState.CREATED, "The survey has already been started");

        require(
            surveyDurationSeconds > minDurationActiveSeconds,
            "Duration must be longer than the set minimum duration"
        );
        require(
            surveyDurationSeconds < maxDurationActiveSeconds,
            "Duration must not be longer than set maximum duration."
        ); 
        timestampEndOfSurvey = add(block.timestamp, surveyDurationSeconds); // Adding with safeMath here, even though we checked the input previously
        
        require(
            payoutPeriodSeconds > minDurationPayoutSeconds,
            "Payout period must be at least the set minimum duration"
        );
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK"); // You have to add some chainLink to start
        durationCollectionPeriod = payoutPeriodSeconds; // Note down this value

        uint256 totalPrizes;
        for (uint256 i = 0; i < prizesInGwei.length; i++) {
            add(totalPrizes, prizesInGwei[i]); // Update the total
            prizes.push(prizesInGwei[i]); // Add to our list
        }
        require(
            address(this).balance > totalPrizes,
            "The contract does not have enough funds for giving out the prizes."
        );
        currentState = ContractState.ACTIVE;
    }


    // ------ ------ ------ ------ ------ ------ //
    // ------ ACTIVE STATE FUNCTIONS ---- ----- //
    // ------ ------ ------ ------ ------ ------ //

    /**
     * Allows to autheticate a user for starting a SurveyToken
     * @return true on token possession, false otherwise
     **/

    function auth_user() public view onlyActiveSurvey returns (bool) {
        if (balanceOf(msg.sender) > 0) {
            return true;
        }
        if (msg.sender == owner) return true;       // The owner can be authenticated by default
        return false;
    }

    /**
     * Adds the answer to the array of answers and removes one token, adds participation to raffle
     * @param hash: Hash value of the answers given by the participant
     **/
    function add_answer_hash(uint32 hash)
        public
        onlyWithToken
        onlyActiveSurvey
    {
        require(msg.sender != owner, "The owner cannot participate");
        answersList.push(hash); // Add the hash to the list

        increaseAllowance(msg.sender, 1); // Make transferFrom possible
        transferFrom(msg.sender, owner, 1); // Remove one token and add it back to the owners account

        raffleParticipants.push(msg.sender); // Participate last, in case anything else fails
    }

    /*
    * Sends tokens from the user's account to the addresses from the parameter
    * Maximum of 100 transfers at a time
    **/
    function distributeTokens(address[] memory receivers) public{
        require(receivers.length <= 100, "Only leq than 100 transfers at a time.");
        increaseAllowance(msg.sender, receivers.length); // Make transferFrom possible
        for(uint32 i = 0; i < receivers.length; i++){
            transferFrom(msg.sender, receivers[i], 1); // Send one token each
        }
    }


    // ------ ------ ------ ------ ------ ------  //
    // ------ Expired State Functions ---- ------ //
    // ------ ------ ------ ------ ------ ------  //
    
    /**
     * Issues generation of a random number. May be recalled, if the oracle fails within 10 minutes, to use backup RNG (with lower security guarantee) for the contract not getting stuck in the expired STATE
     **/ 
    function prepareRandomNumber() external onlyExpiredSurvey{
        require(!randomNumberDrawn, "There is already a random number");
        if(randomNumberQueryTimestamp == 0){
            require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - transfer some linkl to this contract for the fee");
            randomNumberQueryTimestamp = block.timestamp;
            randomNumberRequestId = requestRandomness(keyHash, fee, uint256(blockhash(block.number-1))); // Use ChainLink to request randomness; Using the last blockhash as user defined seed. 
        }else{ 
            // NOTE: This case is only invoked as a last resort to unstuck the contract, if the oracle fails. 
            require(block.timestamp > add(randomNumberQueryTimestamp, oracleWaitPeriodSeconds), "We wait some time for the oracle to provide a random number, before using the fallback RNG.");
            randomNumber = uint256(blockhash(block.number-1) ^ blockhash(block.number-2) ^ blockhash(block.number-3)); // Using the XOR of the last three blockhashes
            randomNumberDrawn = true;
        }
    }

    /**
     * Callback function used by VRF Coordinator to add the random number
     * Only accepted from ChainLink Coordinator to prevent others introducing wrong random numbers
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(msg.sender == coordinatorAddress && randomNumberRequestId == requestId, "Randomness not accepted"); // We add this to guarantee the sender of the RN corresponds to the real oracle
        randomNumber = randomness;
        randomNumberDrawn = true;
    }

    // After the random number has been prepared, the winners get drawn and the payout state is set
    // ONLY WORKS, if prepareRandomNumber() has been called before!
    // Previously called 'finishSurvey()'
    function preparePayout() external onlyExpiredSurvey{        
        require(randomNumberDrawn, "First, a random number has to be drawn");

        if(raffleParticipants.length == 0) return; // No participants -> No winners
        uint winner_count = prizes.length;
        if(winner_count == 0) return;
        for (uint i = 0; i < winner_count; i++) {
            uint256 winner_number =
                (add(randomNumber, i)) % raffleParticipants.length; // Generate the index of the winner
            raffleWinners.push(raffleParticipants[winner_number]);
        }
        
        timestampEndOfCollection = add(timestampEndOfSurvey, durationCollectionPeriod); // Calculate the timestamp relative to the end of the active period starting from now
        currentState = ContractState.PAYOUT; // Survey is not active anymore
    }

    /**
     * Returns the random number that was drawn
     **/
    function get_random_number() external view returns (uint256){
        return randomNumber;
    }


    // ------ ------ ------ ------ ------ ------ ------ //
    // ------ PAYOUT STATE FUNCTIONS --------   ----- //
    // ------ ------ ------ ------ ------ ------ ------ //
    
    /**
     * Returns the array with all the winners
     **/
    function get_winners() external view onlyPayoutSurvey returns (address[] memory){
        return raffleWinners;
    }
    
    /**
     * Returns if the caller is a winner
     **/
    function didIWin() public view onlyPayoutSurvey returns (bool) {
        for(uint i = 0; i < raffleWinners.length; i++){
            if(raffleWinners[i] == msg.sender) return true;
        }
        return false;
    }

    /**
    * Allows the winner to claim the prize associated with its address
    * Does not pay attention to gas needs of a calling contract, as only external parties are able to withdraw funds (as only those should be able to participate in a survey)
    */
    function claimPrize() external onlyPayoutSurvey {
        bool prizeWon = false;  // Only set to true, if one or more prizes were won
        for(uint i = 0; i < raffleWinners.length; i++){
            if(raffleWinners[i] == msg.sender){
                //require(i < prizes.length, "Length mismatch"); // Should never happen, only through programmatical error
                uint prizeGwei = prizes[i];
                if(prizeGwei <= 0){ // We do not bother if there is no prize left
                    continue;
                }
                prizes[i] = 0; // Reset the prize before transfer
                (payable(msg.sender)).transfer(prizeGwei * 1000000000); // Send the prize in Wei
                prizeWon = true;
            }
        }
        // If there was no transfer, we revert. Otherwise, the transfers are allowed
        if(!prizeWon){
            revert("There is no prize to claim for you");
        }
    }
    
    /**
     * Returns all given answerHashes
     * @return A list of all answerHashes
     **/
    function get_answer_list() external view returns (uint32[] memory) {
        return answersList;
    }

    /**
     * Allows to get the total count of answers
     * @return Total count of answers
     **/
    function get_answer_count() external view returns (uint256) {
        return answersList.length;
    }
    
    
    // ------ ------ ------ ------ ------ ------ ------ //
    // ------ FINISHED STATE FUNCTIONS --------   ----- //
    // ------ ------ ------ ------ ------ ------ ------ //
    
    // Frees memory on the blockchain to get back some gas; COMPLETELY DESTROYS THE CONTRACT
    // WARNING: Data can not be retrieved via the respective functions anymore, after calling this function 
    // WARNING: Data is not deleted for good, just not included in newer blocks anymore. You cannot delete data from a blockchain by design.
    function cleanup() onlyOwner onlyFinishedSurvey external {
        address payable creator = payable(msg.sender);
        selfdestruct(creator); // Gets back all ETH and destroys the contract completely
    }   
    
    // Return all ETH of this contract to the owners account without deleting any of the data
    function getBackRemainingEth() onlyOwner onlyFinishedSurvey external{
        address payable creator = payable(msg.sender);
        creator.transfer(address(this).balance);
    }


    // ------ ------ ------ ------ ------ ------ ------ //
    // ------ Helper functions (pure functions)   ----- //
    // ------ ------ ------ ------ ------ ------ ------ //

    /** From OpenZeppelin SafeMath
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/LinkTokenInterface.sol";

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
   * @param _seed seed mixed into the input of the VRF.
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee,
    uint256 _seed
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

