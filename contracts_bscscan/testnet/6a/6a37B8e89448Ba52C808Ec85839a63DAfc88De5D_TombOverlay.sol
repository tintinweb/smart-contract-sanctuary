// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./access/Ownable.sol";
import "./interfaces/IRugZombieNft.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IPriceConsumerV3.sol";
import "./interfaces/IDrFrankenstein.sol";
import "./token/BEP20/IBEP20.sol";
import "./vrf/VRFConsumerBase.sol";

contract TombOverlay is Ownable, VRFConsumerBase {
    uint public bracketBStart = 500;      // The percentage of the pool required to be in the second bracket
    uint public bracketCStart = 1000;      // The percentage of the pool required to be in the third bracket

    struct UserInfo {
        uint256 lastNftMintDate;    // The next date the NFT is available to mint
        bool    isMinting;          // Flag for if the user is currently minting
        uint    randomNumber;       // The random number that is returned from Chainlink
    }

    struct PoolInfo {
        uint            poolId;             // The DrFrankenstein pool ID for this overlay pool
        bool            isEnabled;          // Flag for it the pool is active        
        uint256         mintingTime;        // The time it takes to mint the reward NFT
        uint256         mintTimeFromStake;  // The time it takes to mint the reward NFT based on the staking timer from DrF
        IRugZombieNft   commonReward;       // The common reward NFT
        IRugZombieNft   uncommonReward;     // The uncommon reward NFT
        IRugZombieNft   rareReward;         // The rare reward NFT
        IRugZombieNft   legendaryReward;    // The legendary reward NFT
        BracketOdds[]   odds;               // The odds brackets for the pool
    }

    struct BracketOdds {
        uint commonTop;
        uint uncommonTop;
        uint rareTop;
    }

    struct RandomRequest {
        uint poolId;
        address user;
    }

    PoolInfo[]          public  poolInfo;           // The array of pools
    IDrFrankenstein     public  drFrankenstein;     // Dr Frankenstein - the man, the myth, the legend
    IPriceConsumerV3    public  priceConsumer;      // Price consumer for Chainlink Oracle
    address             payable treasury;           // Wallet address for the treasury
    bytes32             public  keyHash;            // The Chainlink VRF keyhash 
    uint256             public  linkFee;            // The Chainlink VRF fee
    uint256             public  mintingFee;         // The fee charged in BNB to cover Chainlink costs
    IRugZombieNft       public  topPrize;           // The top prize NFT

    // Mapping of request IDs to requests
    mapping (bytes32 => RandomRequest) public randomRequests;
    
    // Mapping of user info to address mapped to each pool
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    event MintNft(address indexed to, uint date, address nft, uint indexed id, uint random);

    // Constructor for constructing things
    constructor(
        address _drFrankenstein,
        address _treasury,
        address _priceConsumer,
        uint256 _mintingFee,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _linkFee,
        address _topPrize
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        drFrankenstein = IDrFrankenstein(_drFrankenstein);
        treasury = payable(_treasury);
        priceConsumer = IPriceConsumerV3(_priceConsumer);
        mintingFee = _mintingFee;
        keyHash = _keyHash;
        linkFee = _linkFee;
        topPrize = IRugZombieNft(_topPrize);
    }

    // Modifier to ensure a user can start minting
    modifier canStartMinting(uint _pid) {
        UserInfo memory user = userInfo[_pid][msg.sender];
        PoolInfo memory pool = poolInfo[_pid];
        IDrFrankenstein.UserInfoDrFrankenstien memory tombUser = drFrankenstein.userInfo(pool.poolId, msg.sender);
        require(_pid <= poolInfo.length - 1, 'Overlay: Pool does not exist');
        require(tombUser.amount > 0, 'Overlay: You are not staked in the pool');        
        require(!user.isMinting, 'Overlay: You already have a pending minting request');
        require(block.timestamp >= (user.lastNftMintDate + pool.mintingTime) && 
            block.timestamp >= (tombUser.tokenWithdrawalDate + pool.mintTimeFromStake),
            'Overlay: Minting time has not elapsed');        
        _;
    }

    // Modifier to ensure a user's pending minting request is ready
    modifier canFinishMinting(uint _pid) {
        UserInfo memory user = userInfo[_pid][msg.sender];
        require(user.isMinting && user.randomNumber > 0, 'Overlay: Minting is not ready');
        _;
    }

    // Function to add a pool
    function addPool(
        uint _poolId,
        uint256 _mintingTime,
        uint256 _mintTimeFromStake,
        address _commonNft,
        address _uncommonNft,
        address _rareNft,
        address _legendaryNft
    ) public onlyOwner() {
        poolInfo.push();
        uint id = poolInfo.length - 1;

        poolInfo[id].poolId = _poolId;
        poolInfo[id].mintingTime = _mintingTime;
        poolInfo[id].mintTimeFromStake = _mintTimeFromStake;
        poolInfo[id].commonReward = IRugZombieNft(_commonNft);
        poolInfo[id].uncommonReward = IRugZombieNft(_uncommonNft);
        poolInfo[id].rareReward = IRugZombieNft(_rareNft);
        poolInfo[id].legendaryReward = IRugZombieNft(_legendaryNft);

        // Lowest bracket: 70% common, 15% uncommon, 10% rare, 5% legendary, 0% mythic
        poolInfo[id].odds.push(BracketOdds({
            commonTop: 7000,
            uncommonTop: 8500,
            rareTop: 9500
        }));

        // Middle bracket: 50% common, 25% uncommon, 15% rare, 10% legendary, 0% mythic
        poolInfo[id].odds.push(BracketOdds({
            commonTop: 5000,
            uncommonTop: 7500,
            rareTop: 9000
        }));

        // Top bracket: 20% common, 30% uncommon, 30% rare, 20% legendary, 0% mythic
        poolInfo[id].odds.push(BracketOdds({
            commonTop: 2000,
            uncommonTop: 5000,
            rareTop: 8000
        }));
    }

    // Uses ChainLink Oracle to convert from USD to BNB
    function mintingFeeInBnb() public view returns(uint) {
        return priceConsumer.usdToBnb(mintingFee);
    }

    // Function to set the enabled state of a pool
    function setIsEnabled(uint _pid, bool _enabled) public onlyOwner() {
        poolInfo[_pid].isEnabled = _enabled;
    }

    // Function to set the common reward NFT for a pool
    function setCommonRewardNft(uint _pid, address _nft) public onlyOwner() {
        poolInfo[_pid].commonReward = IRugZombieNft(_nft);
    }

    // Function to set the uncommon reward NFT for a pool
    function setUncommonRewardNft(uint _pid, address _nft) public onlyOwner() {
        poolInfo[_pid].uncommonReward = IRugZombieNft(_nft);
    }

    // Function to set the rare reward NFT for a pool
    function setRareRewardNft(uint _pid, address _nft) public onlyOwner() {
        poolInfo[_pid].rareReward = IRugZombieNft(_nft);
    }

    // Function to set the legendary reward NFT for a pool
    function setLegendaryRewardNft(uint _pid, address _nft) public onlyOwner() {
        poolInfo[_pid].legendaryReward = IRugZombieNft(_nft);
    }

    // Function to set the minting time for a pool
    function setMintingTime(uint _pid, uint256 _mintingTime) public onlyOwner() {
        poolInfo[_pid].mintingTime = _mintingTime;
    }

    // Function to set the mint time from staking timer for a pool
    function setMintTimeFromStake(uint _pid, uint256 _mintTimeFromStake) public onlyOwner() {
        poolInfo[_pid].mintTimeFromStake = _mintTimeFromStake;
    }

    // Function to set the price consumer
    function setPriceConsumer(address _priceConsumer) public onlyOwner() {
        priceConsumer = IPriceConsumerV3(_priceConsumer);
    }

    // Function to set the treasury address
    function setTreasury(address _treasury) public onlyOwner() {
        treasury = payable(_treasury);
    }

    // Function to set the start of the second bracket
    function setBracketBStart(uint _value) public onlyOwner() {
        bracketBStart = _value;
    }

    // Function to set the start of the third bracket
    function setBracketCStart(uint _value) public onlyOwner() {
        bracketCStart = _value;
    }

    // Function to set the minting fee
    function setmintingFee(uint256 _fee) public onlyOwner() {
        mintingFee = _fee;
    }

    // Function to change the top prize NFT
    function setTopPrize(address _nft) public onlyOwner() {
        topPrize = IRugZombieNft(_nft);
    }

    // Function to set the odds for a pool
    function setPoolOdds(
        uint _pid, 
        uint _bracket, 
        uint _commonTop, 
        uint _uncommonTop, 
        uint _rareTop
    ) public onlyOwner() {
        BracketOdds memory odds = BracketOdds({
            commonTop: _commonTop,
            uncommonTop: _uncommonTop,
            rareTop: _rareTop
        });
        poolInfo[_pid].odds[_bracket] = odds;
    }

    // Function to get the number of pools
    function poolCount() public view returns(uint) {
        return poolInfo.length;
    }

    // Function to get a user's NFT mint date
    function nftMintTime(uint _pid, address _userAddress) public view returns (uint256) {
        UserInfo memory user = userInfo[_pid][_userAddress];
        PoolInfo memory pool = poolInfo[_pid];
        IDrFrankenstein.UserInfoDrFrankenstien memory tombUser = drFrankenstein.userInfo(pool.poolId, _userAddress);

        if (tombUser.amount == 0) {
            return 2**256 - 1;
        } else if (block.timestamp >= (user.lastNftMintDate + pool.mintingTime) && block.timestamp >= (tombUser.tokenWithdrawalDate + pool.mintTimeFromStake)) {
            return 0;
        } else if (block.timestamp <= (tombUser.tokenWithdrawalDate + pool.mintTimeFromStake)) {
            return (tombUser.tokenWithdrawalDate + pool.mintTimeFromStake) - block.timestamp;
        } else {
            return user.lastNftMintDate + pool.mintingTime;
        }
    }

    // Function to recover LINK balance from contract in case of retirement
    function recoverLink() public onlyOwner() {
        LINK.approve(msg.sender, LINK.balanceOf(address(this)));
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }

    // Function to start minting a NFT
    function startMinting(uint _pid) public payable canStartMinting(_pid) returns (bytes32) {
        require(msg.value >= mintingFeeInBnb(), 'Minting: Insufficient BNB for minting fee');
        require(LINK.balanceOf(address(this)) >= linkFee, 'Admin: LINK balance failure');
        UserInfo storage user = userInfo[_pid][msg.sender];

        treasury.transfer(msg.value);
        user.isMinting = true;
        user.randomNumber = 0;

        RandomRequest memory request = RandomRequest(_pid, msg.sender);
        bytes32 id = requestRandomness(keyHash, linkFee);

        randomRequests[id] = request;
        return id;
    }

    // Function to finish minting a NFT
    function finishMinting(uint _pid) public canFinishMinting(_pid) returns (uint, uint) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        IDrFrankenstein.PoolInfoDrFrankenstein memory tombPool = drFrankenstein.poolInfo(pool.poolId);
        IDrFrankenstein.UserInfoDrFrankenstien memory tombUser = drFrankenstein.userInfo(pool.poolId, msg.sender);

        if (block.timestamp < (tombUser.tokenWithdrawalDate + pool.mintTimeFromStake)) {
            user.isMinting = false;
            require(false, 'Overlay: Stake change detected - minting cancelled');
        }

        IBEP20 lptoken = IBEP20(tombPool.lpToken);
        
        uint poolTotal = lptoken.balanceOf(address(drFrankenstein));
        uint percentOfPool = calcBasisPoints(poolTotal, tombUser.amount);
        BracketOdds memory userOdds;
        
        if (percentOfPool < bracketBStart) {
            userOdds = pool.odds[0];
        } else if (percentOfPool < bracketCStart) {
            userOdds = pool.odds[1];
        } else {
            userOdds = pool.odds[2];
        }

        uint rarity;
        IRugZombieNft nft;
        if (user.randomNumber <= userOdds.commonTop) {
            nft = pool.commonReward;
            rarity = 0;
        } else if (user.randomNumber <= userOdds.uncommonTop) {
            nft = pool.uncommonReward;
            rarity = 1;
        } else if (user.randomNumber <= userOdds.rareTop) {
            nft = pool.rareReward;
            rarity = 2;
        } else if (user.randomNumber == 10000) {
            nft = topPrize;
            rarity = 3;
        } else {
            nft = pool.legendaryReward;
            rarity = 3;
        }

        uint tokenId = nft.reviveRug(msg.sender);
        user.lastNftMintDate = block.timestamp;
        user.isMinting = false;
        emit MintNft(msg.sender, block.timestamp, address(nft), tokenId, user.randomNumber);
        return (rarity, tokenId);
    }

    // Function to handle Chainlink VRF callback
    function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber) internal override {
        RandomRequest memory request = randomRequests[_requestId];
        uint randomNumber = (_randomNumber % 10000) + 1;
        userInfo[request.poolId][request.user].randomNumber = randomNumber;
    }

    // Get basis points (percentage) of _portion relative to _amount
    function calcBasisPoints(uint _amount, uint  _portion) public pure returns(uint) {
        if(_portion == 0 || _amount == 0) {
            return 0;
        } else {
            uint _basisPoints = (_portion * 10000) / _amount;
            return _basisPoints;
        }
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

pragma solidity ^0.8.4;

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

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRugZombieNft {
    function totalSupply() external view returns (uint256);
    function reviveRug(address _to) external returns(uint);
    function transferOwnership(address newOwner) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPriceConsumerV3 {
    function getLatestPrice() external view returns (uint);
    function unlockFeeInBnb(uint) external view returns (uint);
    function usdToBnb(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDrFrankenstein {
    struct UserInfoDrFrankenstien {
        uint256 amount;                 // How many LP tokens the user has provided.
        uint256 rewardDebt;             // Reward debt. See explanation below.
        uint256 tokenWithdrawalDate;    // Date user must wait until before early withdrawal fees are lifted.
        // User grave info
        uint256 rugDeposited;               // How many rugged tokens the user deposited.
        bool paidUnlockFee;                 // true if user paid the unlock fee.
        uint256  nftRevivalDate;            // Date user must wait until before harvesting their nft.
    }

    struct PoolInfoDrFrankenstein {
        address lpToken;                        // Address of LP token contract.
        uint256 allocPoint;                     // How many allocation points assigned to this pool. ZMBEs to distribute per block.
        uint256 lastRewardBlock;                // Last block number that ZMBEs distribution occurs.
        uint256 accZombiePerShare;              // Accumulated ZMBEs per share, times 1e12. See below.
        uint256 minimumStakingTime;             // Duration a user must stake before early withdrawal fee is lifted.
        // Grave variables
        bool isGrave;                           // True if pool is a grave (provides nft rewards).
        bool requiresRug;                       // True if grave require a rugged token deposit before unlocking.
        address ruggedToken;                    // Address of the grave's rugged token (casted to IGraveStakingToken over IBEP20 to save space).
        address nft;                            // Address of reward nft.
        uint256 unlockFee;                      // Unlock fee (In BUSD, Chainlink Oracle is used to convert fee to current BNB value).
        uint256 minimumStake;                   // Minimum amount of lpTokens required to stake.
        uint256 nftRevivalTime;                 // Duration a user must stake before they can redeem their nft reward.
        uint256 unlocks;                        // Number of times a grave is unlocked
    }

    function poolLength() external view returns (uint256);
    function userInfo(uint pid, address userAddress) external view returns (UserInfoDrFrankenstien memory);
    function poolInfo(uint pid) external view returns (PoolInfoDrFrankenstein memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    constructor()  {
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