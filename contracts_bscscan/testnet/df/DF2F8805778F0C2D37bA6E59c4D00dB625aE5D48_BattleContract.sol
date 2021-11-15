// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";

contract BattleContract is VRFConsumerBase, Ownable {
    enum STATUS {
        READY,
        END
    }
    struct Battle {
        uint256 id;
        string uri;
        uint256 startTime;
        uint256 endTime;
        uint256 level;
        uint256 award;
        STATUS status;
    }

    struct Participant {
        uint256 nftId;
        address nftOwner;
        bool isClaimedNFT;
        bool isClaimedGFX;
    }

    uint256 internal BATTLE_TIME = 1 minutes;

    Battle[] public battles;
    uint256 public battlesCount;

    // BattleLevel => Battle ID
    mapping(uint256 => uint256) public battlesByLevel;

    // BattleLevel => Battles Count
    mapping(uint256 => uint256) public battlesCountByLevel;

    // BattleId => Participant[]
    mapping(uint256 => Participant[]) public participants;

    // BattleId => Number of Participants
    mapping(uint256 => uint256) public participantsCount;

    // BattleID => Winner
    mapping(uint256 => Participant) public battleHistories;

    // Chainlink RNG
    bytes32 internal keyHash;
    uint256 internal fee;
    address internal requester;

    // Chainlink Request Id => Battle ID
    uint256 public currentBattleId;
    mapping(bytes32 => uint256) public requestBattleIds;
    mapping(uint256 => uint256) public battleRandomness;
    mapping(uint256 => uint256) public battleWinnerIndexes;

    // Contract Interfaces
    IERC20 internal gfx_;
    INFTContract internal nft_;

    // -------------- Event Trigers -----------------
    /**
     * @param battleId Battle Id
     * @param uri Battle URI
     * @param level Battle level
     * @param award Battle GFX Award
     * @param startTime Battle start timestamp
     * @param endTime Battle end timestamp
     */
    event NewBattleCreated(
        uint256 battleId,
        string uri,
        uint256 level,
        uint256 award,
        uint256 startTime,
        uint256 endTime
    );

    /**
     * @param battleId Battle Id
     * @param nftId New Participant NFT id
     * @param total number of participant
     */
    event NewParticipantJoined(uint256 battleId, uint256 nftId, uint256 total);

    /**
     * @param battleId Battle Id
     */
    event CompleteBattle(uint256 battleId);

    /**
     * @param battleId Battle Id
     * @param nftId Winner NFT Id
     */
    event NewWinner(uint256 battleId, uint256 nftId, address nftOwner);

    /**
     * @param nftId Claimed NFT Id
     * @param nftOwner NFT Owner Address
     * @param amount GFX Amount
     */
    event ClaimedGFX(uint256 nftId, address nftOwner, uint256 amount);

    /**
     * @param nftId Claimed NFT Id
     * @param nftOwner NFT Owner Address
     */
    event ClaimedNFT(uint256 nftId, address nftOwner);

    event RequestRNG(uint256 battleId, bytes32 requestId);

    event ResponseRNG(uint256 battleId, uint256 randomness, bytes32 requestId);

    /**
     * BattleContract constructor
     * @param _vrfCoordinator address of Chainlink VRFCoordinator
     * @param _linkToken address of Chainlink Token Address
     * @param _keyHash hash
     */
    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyHash;
        fee = 0.1 * (10**18);

        battlesCount = 0;
    }

    /**
     * Initalize Interfaces
     * @param _nft NFTContract address
     * @param _gfx GFX Token Contract address
     */
    function initialize(address _nft, address _gfx) external onlyOwner {
        gfx_ = IERC20(_gfx);
        nft_ = INFTContract(_nft);
    }

    // ---------------------------------------- Modifiers ------------------------------------
    /**
     * Validate Battle ID
     * @param _battleId Battle ID
     */
    modifier _checkValidBattleId(uint256 _battleId) {
        require(
            _battleId < battlesCount,
            "BattleContract: _battleId is invalid number"
        );
        _;
    }

    /**
     * Validate NFT Owner
     * @param _nftId NFT ID
     */
    modifier _onlyOwner(uint256 _nftId) {
        address nftOwner = nft_.ownerOf(_nftId);
        require(
            msg.sender == nftOwner,
            "BattleContract: You are not NFT owner"
        );
        _;
    }

    /**
     * Can participate battle
     * @param _battleId Battle ID
     * @param _nftId NFT ID
     */
    modifier _canParticipateBattle(uint256 _battleId, uint256 _nftId) {
        Battle memory battle = battles[_battleId];
        require(
            battle.startTime >= block.timestamp,
            "BattleContract: Not able to Join Battle"
        );
        require(
            battle.status == STATUS.READY,
            "BattleContract: Battle had already been ended"
        );

        address nftOwner = nft_.ownerOf(_nftId);
        bool wasParticipated = false;
        for (uint256 i = 0; i < participantsCount[_battleId]; i++) {
            if (participants[_battleId][i].nftOwner == nftOwner) {
                wasParticipated = true;
            }
        }

        require(!wasParticipated, "BattleContract: Already participated");
        _;
    }

    /**
     * Can complete battle
     * @param _battleId Battle ID
     */
    modifier _canCompleteBattle(uint256 _battleId) {
        Battle memory battle = battles[_battleId];
        require(
            battle.endTime <= block.timestamp,
            "BattleContract: Not able to complete Battle"
        );
        require(
            battle.status == STATUS.READY,
            "BattleContract: Battle had already been ended"
        );
        _;
    }

    /**
     * Check winner
     * @param _battleId Battle ID
     */
    modifier _isWinner(uint256 _battleId) {
        Participant memory winner = battleHistories[_battleId];
        require(
            winner.nftOwner == msg.sender,
            "BattleContract: You are not a winner"
        );
        _;
    }

    // ----------------------------------------- Private Functions -------------------------------
    /**
     * Generate Random Number by Chainlink VRF
     * @param _battleId Battle ID
     */
    function _generateRandomNumber(uint256 _battleId, uint256 _seed) private {
        require(keyHash != bytes32(0), "Must have valid key hash");
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );

        currentBattleId = _battleId;

        bytes32 requestId = requestRandomness(keyHash, fee, _seed);

        emit RequestRNG(_battleId, requestId);

        requestBattleIds[requestId] = _battleId + 1;
    }

    /**
     * Chainlink VRF RNG Callback
     * @param requestId Request ID
     * @param randomness Random Number
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        emit ResponseRNG(currentBattleId, randomness, requestId);

        require(
            currentBattleId >= 0,
            "BattleContract: Invalid Chainlink Request"
        );

        battleRandomness[currentBattleId] = randomness;
        battleWinnerIndexes[currentBattleId] = randomness;
        uint256 winnerIndex = randomness % participantsCount[currentBattleId];

        Participant memory participant = participants[currentBattleId][
            winnerIndex
        ];
        battleHistories[currentBattleId] = participant;

        // _burnNFT(currentBattleId, winnerIndex);

        nft_.setNFTLevelUp(participant.nftId);
        nft_.setNFTURI(participant.nftId, battles[currentBattleId].uri);

        emit NewWinner(
            currentBattleId,
            participant.nftId,
            participant.nftOwner
        );
    }

    /**
     * Burn Lose NFTs
     * @param _battleId Battle ID
     * @param _winnerIndex Winner Index of participants
     */
    function _burnNFT(uint256 _battleId, uint256 _winnerIndex) private {
        for (uint256 i = 0; i < participantsCount[_battleId]; i++) {
            if (_winnerIndex != i) {
                nft_.burnNFT(participants[_battleId][i].nftId);
            }
        }
    }

    // ------------------------------------------ Public Functions -------------------------------
    /**
     * Create New Battle
     * @param _uri Battle URI
     * @param _level Battle Level
     * @param _award Battle GFX Award
     * @param _startTime Battle Start Time
     */
    function createNewBattle(
        string memory _uri,
        uint256 _level,
        uint256 _award,
        uint256 _startTime
    ) public onlyOwner returns (uint256) {
        require(
            _startTime > block.timestamp,
            "BattleContract: StartTime is over"
        );

        Battle memory battle;
        battle.id = battlesCount;
        battle.uri = _uri;
        battle.level = _level;
        battle.award = _award;
        battle.startTime = _startTime;
        battle.endTime = _startTime + BATTLE_TIME;
        battle.status = STATUS.READY;

        battles.push(battle);
        battlesCount++;

        // Sort battles by level
        battlesByLevel[_level] = battle.id;
        battlesCountByLevel[_level]++;

        // Initialize the number of battle participants
        participantsCount[battle.id] = 0;
        // Trigger newBattleCreated event
        emit NewBattleCreated(
            battle.id,
            battle.uri,
            battle.level,
            battle.award,
            battle.startTime,
            battle.endTime
        );

        return battle.id;
    }

    /**
     * Participate Battle
     * @param _battleId Battle ID
     * @param _nftId NFT ID
     */
    function participateBattle(uint256 _battleId, uint256 _nftId)
        public
        _checkValidBattleId(_battleId)
        _onlyOwner(_nftId)
        _canParticipateBattle(_battleId, _nftId)
    {
        Participant memory participant;
        participant.nftId = _nftId;
        participant.nftOwner = nft_.ownerOf(_nftId);
        participant.isClaimedNFT = false;
        participant.isClaimedGFX = false;

        participants[_battleId].push(participant);
        participantsCount[_battleId]++;

        nft_.transferNFT(address(this), _nftId);

        emit NewParticipantJoined(
            _battleId,
            _nftId,
            participantsCount[_battleId]
        );
    }

    /**
     * Complete Battle
     * @param _battleId Battle ID
     */
    function completeBattle(uint256 _battleId, uint256 _seed)
        public
        onlyOwner
        _checkValidBattleId(_battleId)
        _canCompleteBattle(_battleId)
    {
        battles[_battleId].status = STATUS.END;

        if (participantsCount[_battleId] > 0) {
            _generateRandomNumber(_battleId, _seed);
        }

        emit CompleteBattle(_battleId);
    }

    /**
     * Claim NFT
     * @param _battleId Battle ID
     */
    function _claimNFT(uint256 _battleId) private {
        Participant storage winner = battleHistories[_battleId];
        require(!winner.isClaimedNFT, "BattleContract: Already Claimed NFT");

        nft_.transferNFT(winner.nftOwner, winner.nftId);
        winner.isClaimedNFT = true;

        emit ClaimedNFT(winner.nftId, winner.nftOwner);
    }

    /**
     * Claim GFX Award
     * @param _battleId Battle ID
     */
    function _claimGFX(uint256 _battleId) private {
        Participant storage winner = battleHistories[_battleId];
        require(!winner.isClaimedGFX, "BattleContract: Already Claimed GFX");

        uint256 amount = battles[_battleId].award * (10**18);
        gfx_.transfer(winner.nftOwner, amount);
        winner.isClaimedGFX = true;

        emit ClaimedGFX(
            winner.nftId,
            winner.nftOwner,
            battles[_battleId].award
        );
    }

    /**
     * Claim
     * @param _battleId Battle ID
     */
    function claimPresent(uint256 _battleId) public _isWinner(_battleId) {
        Participant memory winner = battleHistories[_battleId];
        require(
            !winner.isClaimedGFX && !winner.isClaimedNFT,
            "BattleContract: Already Claimed"
        );

        _claimNFT(_battleId);
        _claimGFX(_battleId);
    }

    /**
     * Refund all of NFTs
     * @param _battleId Battle ID
     */
    function refundNFTs(uint256 _battleId) public onlyOwner {
        Participant[] storage nfts = participants[_battleId];
        for (uint256 i = 0; i < nfts.length; i++) {
            if (!nfts[i].isClaimedNFT) {
                nft_.transferNFT(nfts[i].nftOwner, nfts[i].nftId);
                nfts[i].isClaimedNFT = true;

                emit ClaimedNFT(nfts[i].nftId, nfts[i].nftOwner);
            }
        }

        battleHistories[_battleId].isClaimedNFT = true;
    }

    // function mintTestNFT(uint256 _nftCount, address _owner) public onlyOwner {
    //     for (uint256 i = 0; i < _nftCount; i++) {
    //         nft_.mint(_owner, "test-nft", "test-nft-link");
    //     }
    // }

    // function participateTestNFT(
    //     uint256 _battleId,
    //     uint256 _start,
    //     uint256 _end
    // ) public onlyOwner {
    //     for (uint256 i = _start; i < _end; i++) {
    //         participateBattle(_battleId, i);
    //     }
    // }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface INFTContract {
    function nfts(uint256 nftId)
        external
        view
        returns (
            uint256,
            string memory,
            string memory,
            uint256,
            bool,
            uint256
        );

    function nftOwners(uint256 nftId) external view returns (address);

    function mint(
        address _from,
        string memory _name,
        string memory _uri
    ) external;

    function burnNFT(uint256 _nftId) external;

    function transferNFT(address _to, uint256 _nftId) external;

    function getNFTLevelById(uint256 _nftId) external returns (uint256);

    function getNFTById(uint256 _nftId)
        external
        returns (
            uint256,
            string memory,
            string memory,
            uint256
        );

    function setNFTLevelUp(uint256 _nftId) external;

    function setNFTURI(uint256 _nftId, string memory _uri) external;

    function ownerOf(uint256 _nftId) external returns (address);

    function balanceOf(address _from) external returns (uint256);
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

