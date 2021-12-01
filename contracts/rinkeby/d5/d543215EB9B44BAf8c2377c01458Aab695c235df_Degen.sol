// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Degen is VRFConsumerBase {  
  address admin_address;
  	
  //number of die faces
  uint constant PROB_DIV=10000;
  
  uint constant MAX_LEVEL=10;
  uint constant MAX_JACKPOTS_PER_MACHINE=2;
    
  uint public num_machines;
  uint public max_machines;   
  
  bytes32 internal keyHash;
  uint256 internal fee;
  uint256 roll_price = 10000000000000000; //0.01 ETH      

  struct Token {
    uint256 num_rolls;
    uint256 seed;
    uint256 spawned_by;   //the winning machine that spawned this one
    uint8 level;
    uint64 jackpots; //number of times this token payed out
    uint8 mint_passes; //increment on jackpot, number of passes remaining to be redeemed
    bool jackpot_flag; //if the jackpot has been hit
    uint8 s1;
    uint8 s2;
    uint8 s3;
  }
    
    uint256[MAX_LEVEL+1] public mint_pass_granted; //total number of each type of mint pass that has been granted
    uint256[MAX_LEVEL+1] public mint_pass_limit; //limit
    uint256[MAX_LEVEL+1] public jackpot_prob; //limit    
    
    mapping(bytes32 => uint256) request2token;
    mapping(uint256 => Token) tokens;    
  
    event eRoll(uint256 tokenId, uint256 num_rolls, bool jackpot_flag,
		bool won_mint_pass);

    event eRedeem(uint256 num_machines);
    
    modifier requireAdmin() {
      require(admin_address == msg.sender,"Requires admin privileges");
      _;
    }

    modifier requireOwner(uint256 oid) {
      //      require(msg.sender == orders[oid].owner,"Not owner of order");
      _;
    }

    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Rinkeby
     * Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * LINK token address:                0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     */
    constructor() VRFConsumerBase(
				  0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
				  0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
				  ) {
      
      keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
      fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
	
      admin_address = msg.sender;

      //limits for each type
      for (uint i=0;i<MAX_LEVEL;i++) {
	mint_pass_limit[i] = 2;
	max_machines += mint_pass_limit[i]; 
      }
      num_machines = mint_pass_limit[0];

      mint_pass_limit[0] = 4;
      mint_pass_limit[1] = 4;
      mint_pass_limit[2] = 4;
      mint_pass_limit[3] = 4;
      mint_pass_limit[4] = 4;
      mint_pass_limit[5] = 4;
      mint_pass_limit[6] = 4;
      mint_pass_limit[7] = 4;
      mint_pass_limit[8] = 4;
      mint_pass_limit[9] = 4;

      //probability table
      for (uint i=0;i<MAX_LEVEL;i++) {
	jackpot_prob[i] = 5000; //50% chance
      }
      jackpot_prob[0] = 5000;
      jackpot_prob[1] = 5000;
      jackpot_prob[2] = 5000;
      jackpot_prob[3] = 2500;
      jackpot_prob[4] = 1250;
      jackpot_prob[5] = 500;
      jackpot_prob[6] = 250;
      jackpot_prob[7] = 100;
      jackpot_prob[8] = 50;
      jackpot_prob[9] = 25;
      
      //      jackpot_prob[MAX_LEVEL-2] = 1; //last level is HARD
    }
    
    //get slot state of this token
    function machineState(uint256 tid) public view returns (uint8, uint8,uint8) {
      require(tid < num_machines, "out of range");
      return (tokens[tid].s1,tokens[tid].s2,tokens[tid].s3);
    }

    function getLinkBalance() public view returns (uint256) {
      return(LINK.balanceOf(address(this)));
    }

    
    function getToken(uint256 tid) public view returns (uint256 num_rolls, uint8 level, uint8 mint_passes, uint8 s1 , uint8 s2,uint8 s3,bool jackpot_flag,uint64 jackpots_won, uint256 spawned_by, uint256 seed) {
      require(tid < num_machines, "out of range");
      num_rolls = tokens[tid].num_rolls;
      level = tokens[tid].level;
      mint_passes = tokens[tid].mint_passes;
      s1 = tokens[tid].s1;
      s2 = tokens[tid].s2;
      s3 = tokens[tid].s3;
      jackpot_flag = tokens[tid].jackpot_flag;
      seed = tokens[tid].seed;

      jackpots_won = tokens[tid].jackpots;
      spawned_by = tokens[tid].spawned_by;
    }

    //read jackpot state
    function jackpot(uint256 tid) public view returns (bool) {
      return tokens[tid].jackpot_flag;
    }
    
    function redeem(uint256 tid) public payable returns(uint256) {
      require(tokens[tid].mint_passes > 0, "No mint passes for this token");
      require(tokens[tid].level < MAX_LEVEL, "Last jackpot can't be redeemed");
      require(num_machines < max_machines, "hard cap on machine supply");

      tokens[tid].mint_passes -= 1;

      //TODO mint(); 
      tokens[num_machines].level = tokens[tid].level+1;
      tokens[num_machines].spawned_by = tid;
      num_machines++;

      emit eRedeem(num_machines-1);
      
      return num_machines;
    }
    

    //transfers contract balance to GiveDirectly.org
    function donate() public payable requireAdmin {
      payable(0xc7464dbcA260A8faF033460622B23467Df5AEA42).transfer(address(this).balance);
    }

    // requires small payment that gets passed on to givedirectly
    function roll(uint256 tid) public payable returns (bytes32 r) {
      //TODO require (ownerOf(tid)==msg.sender)
      require(msg.value >= roll_price, "Must send minimum value to purchase!");
      require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
      bytes32 requestId =  requestRandomness(keyHash, fee);
      request2token[requestId] = tid;
      return requestId;
    }

    //TODO make this internal
    function fulfill_roll(uint256 tid) public {
      require(tid < num_machines,"machine non existant");

      bool emit_mint_pass = false;

      tokens[tid].jackpot_flag = false;
      tokens[tid].num_rolls++;

      uint256 a = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender)));
      uint256 b = a % PROB_DIV;


      if (b < jackpot_prob[tokens[tid].level]) {
	//JACKPOT
	tokens[tid].s1 = tokens[tid].level+2;
	tokens[tid].s2 = tokens[tid].level+2;
	tokens[tid].s3 = tokens[tid].level+2;
	
	tokens[tid].jackpot_flag = true;
	tokens[tid].jackpots++;
	
	if (tokens[tid].level >= MAX_LEVEL-1 ||
	    tokens[tid].jackpots > MAX_JACKPOTS_PER_MACHINE ||
	    mint_pass_granted[tokens[tid].level] >= mint_pass_limit[tokens[tid].level+1]) {
	  /* No mint pass is granted if:
	     - we've reached the final level
	     - machine has already produced max number of allowed jackpots
	     - all the mint passes for next level have already been claimed

	  */
	  emit_mint_pass = false;
	} else {
	  //grant a mint pass
	  tokens[tid].mint_passes++;
	  mint_pass_granted[tokens[tid].level]++;
	  emit_mint_pass = true;	  
	}	  
      } else {
	//no jackpot hit, regular roll
	tokens[tid].s1 = uint8((a >> 16*0) % uint256(tokens[tid].level+3));
	tokens[tid].s2 = uint8((a >> 16*1) % uint256(tokens[tid].level+3));
	tokens[tid].s3 = uint8((a >> 16*2) % uint256(tokens[tid].level+2)); //no possibility of jackpot
      }

      emit eRoll(tid,tokens[tid].num_rolls,tokens[tid].jackpot_flag,emit_mint_pass);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 r) internal override {
      uint256 tid = request2token[requestId];
      tokens[tid].num_rolls++;
      tokens[tid].seed = r;
      
      fulfill_roll(tid);
      

    }
    
    // set the ETH donation amount required to make a roll
    function setRollPrice(uint256 a) public requireAdmin {
      roll_price = a;
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