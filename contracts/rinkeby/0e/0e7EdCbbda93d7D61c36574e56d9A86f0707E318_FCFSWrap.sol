// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RaffleWrap.sol";

contract FCFSWrap is RaffleWrap {
    
    event Initialization(uint256 regStart, uint256 saleStart, uint256 fcfsStart);

    modifier afterFCFSSale() {
        uint256 x = 0;
        if(isFCFSNeeded()) {
            x = fcfsDuration;
        }
        require(isInitialized, "Not Initialized Yet");
        require(fcfsStarts + x <= block.timestamp, "FCFS: Sale Not Ended Yet");
        _;
    }

    constructor (
        address _stakerAddress,
        address _nativeTokenAddress,
        address _idoTokenAddress,
        uint256 _idoAmount,
        uint256 _price
    ) RaffleWrap (
        _stakerAddress,
        _nativeTokenAddress,
        _idoTokenAddress,
        _idoAmount,
        _price
    ) {

    }

    function initialize(uint256 time) external onlyOwner notInitialized {
        require(time >= block.timestamp, "IDO Can't Be in Past");

        regStarts = time;
        saleStarts = regStarts + saleStartsAfter;
        fcfsStarts = saleStarts + saleDuration;

        require(idoToken.balanceOf(address(this)) >= idoTokenSum, "Not Enough Tokens In Contract");

        emit Initialization(regStarts, saleStarts, fcfsStarts);
    }

    function isFCFSNeeded() public view returns(bool) {
        if(remainingIDOTokens > 0) return true;
        return false;
    }

    function swapPrice(uint256 amount) public view returns(uint256 price) {
        price = (amount * idoTotalPrice) / idoTokenSum;
    }

    function fcfsBuy(uint256 amount) public payable nonReentrant {
        uint256 price = swapPrice(amount);

        require(isFCFSNeeded(), "FCFS: Not Needed");
        require(getRegistrationStatus(msg.sender), "FCFS: You are not registered");
        require(block.timestamp >= saleStarts + saleDuration, "FCFS: Tier Sale not Ended Yet");
        require(amount != 0 && amount <= remainingIDOTokens, "FCFS: Invalid Amount");
        require(msg.value == price, "FCFS: Invalid Eth Value");

        idoToken.transfer(msg.sender, amount);
        remainingIDOTokens -= amount;

        emit Purchase(msg.sender, amount, price);
    }

    function recoverEth(address to) external onlyOwner afterFCFSSale {
        (bool sent,) = address(to).call{value : address(this).balance}("");
        require(sent, 'Unable To Recover Eth');
    }

    function recoverERC20(
        address tokenAddress,
        address to
    ) external onlyOwner afterFCFSSale {
        IERC20Metadata tok = IERC20Metadata(tokenAddress);
        tok.transfer(to, tok.balanceOf(address(this)));
    }

    function isAfterFCFS() public view afterFCFSSale returns(bool) {
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Staker.sol';
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract IDO is Ownable, ReentrancyGuard {

    Staker public staker;
    IERC20Metadata public nativeToken; // The token staked
    IERC20Metadata public idoToken; // The token sale in iDO
    uint256 public idoTokenSum; // Amount of Tokens to be Sold
    uint256 public idoTotalPrice; // Price of 1 Tokens in Wei

    uint256 public totalPoolShares; // Total no of pool shares
    uint256 public remainingIDOTokens; // Tokens Not Sold Yet
    address public treasuryAddress = 0x27380034Afa75eC72652769112800619E7C8bAFe;

    // Time Stamps
    uint256 public constant unit = 1 minutes; // use seconds for testing
    uint256 public constant lockDuration = 10 * unit;
    uint256 public constant regDuration = 10 * unit;
    uint256 public constant saleStartsAfter = regDuration + 1 * unit;
    uint256 public constant saleDuration = 10 * unit;
    uint256 public constant fcfsDuration = 10 * unit;
    uint256 public regStarts;
    uint256 public saleStarts;
    uint256 public fcfsStarts;

    event Registration(address indexed account, uint256 poolNo);
    event Purchase(address indexed, uint256 tokens, uint256 price);

    struct UserLog {
        bool isRegistered;
        uint256 registeredPool;
        bool purchased;
    }
    mapping(address => UserLog) public userlog;
    address[] public participantList;

    bool public isInitialized;

    struct PoolInfo {
        string name;
        uint256 minNativeToken; // min token required to particitate in the pool
        uint256 weight;
        uint256 participants;
    } 
    PoolInfo[] public pools;

    modifier verifyPool(uint256 _poolNo) {
        require(1 <= _poolNo && _poolNo <= 5, "invalid Pool no");

        uint256 stakedAmount = staker.stakedBalance(msg.sender);
        require(pools[_poolNo].minNativeToken <= stakedAmount, "Can't Participate in the Pool");

        _;
    }

    modifier validRegistration() {
        uint256 t = block.timestamp;

        require(isInitialized, "Not Initialized Yet");
        require(!userlog[msg.sender].isRegistered, "Already registered");
        require(regStarts <= t && t <= regStarts + regDuration, "Not in Registration Period");
        _;
    }

    modifier validSale() {
        uint256 t = block.timestamp;

        require(isInitialized, "Not Initialized Yet");
        require(userlog[msg.sender].isRegistered, "Not registered");
        require(!userlog[msg.sender].purchased, "Already Purchased");
        require(saleStarts <= t && t <= saleStarts + saleDuration, "Not in Sale Period");
        _;
    }

    modifier notInitialized() {
        require(!isInitialized, "Already Initialized");
        _;
        isInitialized = true;
    }

    constructor (
        address _stakerAddress,
        address _nativeTokenAddress,
        address _idoTokenAddress,
        uint256 _idoTokenSum,
        uint256 _price
    ) {
        
        staker = Staker(_stakerAddress);
        nativeToken = IERC20Metadata(_nativeTokenAddress);
        idoToken = IERC20Metadata(_idoTokenAddress);
        idoTokenSum = _idoTokenSum;
        idoTotalPrice = _price;

        remainingIDOTokens = idoTokenSum;

        uint256 dec = uint256(nativeToken.decimals());
        pools.push(PoolInfo("Null", 0, 0, 0));
        pools.push(PoolInfo("Knight", 1000 * 10**dec, 1,  0));
        pools.push(PoolInfo("Bishop", 1500 * 10**dec, 4,  0));
        pools.push(PoolInfo("Rook",   3000 * 10**dec, 8,  0));
        pools.push(PoolInfo("King",   6000 * 10**dec, 16, 0));
        pools.push(PoolInfo("Queen",  9000 * 10**dec, 21, 0));

    }

    function register(uint256 _poolNo) 
    external 
    validRegistration 
    verifyPool(_poolNo)
    nonReentrant {
        staker.lock(msg.sender, saleStarts + saleDuration + lockDuration);
        _register(msg.sender, _poolNo);
    }

    function _register(address account, uint256 _poolNo) internal {
        userlog[account].isRegistered = true;
        userlog[account].registeredPool = _poolNo;
        pools[_poolNo].participants += 1;
        totalPoolShares += pools[_poolNo].weight;
        
        participantList.push(account);

        emit Registration(msg.sender, _poolNo);
    }

    function getPoolNo(address account) public view returns(uint256) {
        return userlog[account].registeredPool;
    }

    function noOfParticipants() public view returns(uint256) {
        return participantList.length;
    }

    function getRegistrationStatus(address account) public view returns(bool) {
        return userlog[account].isRegistered;
    }

    function tokensAndPriceByPoolNo(uint256 _poolNo) public view returns(uint256, uint256) {

        PoolInfo memory pool = pools[_poolNo];
        uint256 poolWeight = pool.weight;

        if(_poolNo == 0 || pool.participants == 0) {
            return (0, 0);
        }

        uint256 tokenAmount = (idoTokenSum * poolWeight) / totalPoolShares; // Token Amount per Participants
        uint256 price = (idoTotalPrice * poolWeight) / totalPoolShares; // Token Amount per Participants

        return (tokenAmount, price);
    }

    function allocationByAddress(address account) public view returns(uint256 tokens, uint256 price) {
        (tokens, price) = tokensAndPriceByPoolNo(userlog[account].registeredPool); // Normal Allocation
        (uint256 rTokens, uint256 rPrice) = _raffleAllocation(account); // Raffle Allocation

        tokens += rTokens;
        price += rPrice;
    }

    // This will be implemented in RaffleWrap
    function _raffleAllocation(address account) internal view virtual returns(uint256 tokens, uint256 price);

    function buyNow() external 
    payable 
    validSale
    nonReentrant {
        UserLog storage usr = userlog[msg.sender];
        (uint256 amount, uint256 price) = allocationByAddress(msg.sender);
        require(price != 0 && amount != 0, "Values Can't Be Zero");
        require(price == msg.value, "Not Valid Eth Amount");

        usr.purchased = true;
        remainingIDOTokens -= amount;
        idoToken.transfer(msg.sender, amount);

        emit Purchase(msg.sender, amount, price);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";
import "./IDO.sol";

abstract contract Random is VRFConsumerBase {

    bytes32 internal keyHash;
    uint256 internal fee;
    
    bytes32 public reqId;
    uint256 public randomResult;

    bool isGeneratedOnce;
    modifier once() {
        require(!isGeneratedOnce, "Already Generated Once");
        isGeneratedOnce = true;
        _;
    }

    constructor () VRFConsumerBase (
        0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
        0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
    ) {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 100000000000000000; // 0.1 LINK
    }

    /** 
     * Requests randomness from a user-provided seed
     */
    function _getRandomNumber(uint256 userProvidedSeed) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        reqId = requestId;
        randomResult = randomness;
        _afterGeneration();
    }

    bool _isFulfilled = false;
    function isFulfilled() public view returns(bool) {
        return _isFulfilled;
    }

    // Generating Multiple Random Numbers From a Single One
    function _randomList(uint256 _from, uint256 _to, uint256 _size) internal view returns(uint256[] memory rands) {

        rands = new uint256[](_size);
        uint256 r = randomResult;
        uint256 len = _to - _from;
        
        require(len >= _size, "Invalid Size");

        uint256 i = 251;
        uint256 count = 0;

        while(count < _size) {
            uint256 rand = (r + i**2) % len + _from;
            bool exists = false;

            for(uint256 j = 0; j < count + 1; j++) {
                if (rand == rands[j]) {
                    exists = true;
                    break;
                }
            }

            if(!exists) {
                rands[count] = rand;
                count += 1;
            }

            i += 1;
        }
    }

    // This will execute after generation of Random Number
    function _afterGeneration() internal virtual;

}

abstract contract RaffleWrap is IDO, Random {

    uint256 public ticketsSold; // No of tickets sold
    mapping(uint256 => address) public ticketToOwner; // owner of a ticket
    mapping(address => uint256) public addressToTicketCount; // No Of Tickets Owned By an Address
    mapping(address => uint256[]) public addressToTicketsOwned; // Tickets That an address own
    mapping(address => bool) public hasWonRaffle;

    uint256 public constant RAFFLE_POOL = 2;
    uint256 public constant ticketPrice = 3 * 10 ** 18; // Price of a ticket(no. of tokens)

    modifier raffleParticipationPeriod() {
        require(regStarts <= block.timestamp, "Raffle: Participation Didn't Begin");
        require(regStarts + regDuration >= block.timestamp, "Raffle: Participation Ended");
        _;
    }

    modifier raffleResultPeriod() {
        require(regStarts + regDuration <= block.timestamp, "Raffle: Participation Didn't End");
        require(saleStarts >= block.timestamp, "Raffle: Out Of Time");
        _;
    }

    constructor (
        address _stakerAddress,
        address _nativeTokenAddress,
        address _idoTokenAddress,
        uint256 _idoAmount,
        uint256 _price
    ) IDO(
        _stakerAddress,
        _nativeTokenAddress,
        _idoTokenAddress,
        _idoAmount,
        _price
    ) {

    }

    
    // Buy Tickets
    function buyTickets(uint256 _noOfTickets) external raffleParticipationPeriod nonReentrant {
        require(isRaffleEligible(msg.sender), "Already Participated In IDO");
        uint256 nextTicket = ticketsSold;
        nativeToken.transferFrom(msg.sender, treasuryAddress, _noOfTickets * ticketPrice);

        for(uint256 i=0; i<_noOfTickets; i++) {
            ticketToOwner[nextTicket + i] = msg.sender;
            addressToTicketsOwned[msg.sender].push(nextTicket + i);
        }

        addressToTicketCount[msg.sender] += _noOfTickets;
        ticketsSold += _noOfTickets;
    }

    // Check if Account Is Eligible For Raffle Or Not
    function isRaffleEligible(address account) public view returns(bool) {
        return !getRegistrationStatus(account) || getPoolNo(account) != RAFFLE_POOL;
    }

    function _raffleAllocation(address account) internal view override returns(uint256 tokens, uint256 price) {
        tokens = price = 0;
        if(hasWonRaffle[account]) {
            (tokens, price) = tokensAndPriceByPoolNo(RAFFLE_POOL);
        }
    }

    // Generates The Random Winners
    function genRandom() external once raffleResultPeriod nonReentrant {
        uint256 seed = uint256(keccak256(abi.encodePacked(msg.sender)));
        _getRandomNumber(seed);
    }

    // Function Extended From Random Contract
    function _afterGeneration() internal override {
        _isFulfilled = true;
        _executeRaffle();
    }

    // Raffle Entry For Winners
    function _executeRaffle() internal {

        address[] memory list = _getWinners();
        for(uint256 i=0; i<list.length; i++) {
            address account = list[i];
            uint256 _poolNo = RAFFLE_POOL; // Raffle Entry Pool

            if(!hasWonRaffle[account] && getPoolNo(account) != _poolNo) {
                hasWonRaffle[account] = true;
                pools[_poolNo].participants++;
                totalPoolShares += pools[_poolNo].weight;
            }
        }
    }

    // Gets The Address Of The Winners
    function _getWinners() internal view returns(address[] memory list) {
        uint256 n = _noOfWinners(ticketsSold);
        list = new address[](n);
        uint256[] memory winners = _randomList(0, ticketsSold, n);

        for(uint256 i=0; i<n; i++) {
            address winner = ticketToOwner[winners[i]];
            list[i] = winner;
        }
    }

    function getWinners() external view returns(address[] memory) {
        require(isFulfilled(), "Winner Not Decided Yet");
        return _getWinners();
    }

    function getTicketsWon() external view returns(uint256[] memory) {
        require(isFulfilled(), "Winner Not Decided Yet");
        uint256 n = _noOfWinners(ticketsSold);
        return _randomList(0, ticketsSold, n);
    }

    // Calculates The Number Of Winners
    function _noOfWinners(uint256 _ticketsSold) internal pure returns(uint256) {
        return _ticketsSold / 100 + 1;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staker is Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    IERC20 _token; 
    mapping (address => uint256) _balances;
    mapping (address => uint256) _unlockTime;
    mapping (address => bool) _isIDO;
    bool halted;

    event Stake(address indexed account, uint256 timestamp, uint256 value);
    event Unstake(address indexed account, uint256 timestamp, uint256 value);
    event Lock(address indexed account, uint256 timestamp, uint256 unlockTime, address locker);

    constructor(address _tokenAddress) {
        _token = IERC20(_tokenAddress);
    }

    function stakedBalance(address account) external view returns (uint256) {
        return _balances[account];
    }

    function unlockTime(address account) external view returns (uint256) {
        return _unlockTime[account];
    }

    function isIDO(address account) external view returns (bool) {
        return _isIDO[account];
    }

    function stake(uint256 value) external notHalted {
        require(value > 0, "Staker: stake value should be greater than 0");
        _token.transferFrom(_msgSender(), address(this), value);

        _balances[_msgSender()] = _balances[_msgSender()].add(value);
        emit Stake(_msgSender(), block.timestamp, value);
    }

    function unstake(uint256 value) external lockable {
        require(_balances[_msgSender()] >= value, 'Staker: insufficient staked balance');

        _balances[_msgSender()] = _balances[_msgSender()].sub(value,"Staker: insufficient staked balance");
        _token.transfer(_msgSender(), value);
        emit Unstake(_msgSender(), block.timestamp, value);
    }

    function lock(address user, uint256 unlock_time) external onlyIDO {
        require(unlock_time >  block.timestamp, "Staker: unlock is in the past");
        if (_unlockTime[user] < unlock_time) {
            _unlockTime[user] = unlock_time;
            emit Lock(user, block.timestamp, unlock_time, _msgSender());
        }
    }

    function halt(bool status) external onlyOwner {
        halted = status;
    }

    function addIDO(address account) external onlyOwner {
        require(account != address(0), "Staker: cannot be zero address");
        _isIDO[account] = true;
    }

    modifier onlyIDO() {
        require(_isIDO[_msgSender()],"Staker: only IDOs can lock");
        _;
    }

    modifier lockable() {
        require(_unlockTime[_msgSender()] <=  block.timestamp, "Staker: account is locked");
        _;
    }

    modifier notHalted() {
        require(!halted, "Staker: Deposits are paused");
        _;
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

    constructor () {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

