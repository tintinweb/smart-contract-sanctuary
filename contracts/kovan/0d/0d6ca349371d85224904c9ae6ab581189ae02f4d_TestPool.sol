/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: MIT

//pragma solidity ^0.6.12;
pragma solidity ^0.6.0;

library SafeMathChainlink {
    /**
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

    /**
      * @dev Returns the subtraction of two unsigned integers, reverting on
      * overflow (when the result is negative).
      *
      * Counterpart to Solidity's `-` operator.
      *
      * Requirements:
      * - Subtraction cannot overflow.
      */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
      * @dev Returns the multiplication of two unsigned integers, reverting on
      * overflow.
      *
      * Counterpart to Solidity's `*` operator.
      *
      * Requirements:
      * - Multiplication cannot overflow.
      */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
      * @dev Returns the integer division of two unsigned integers. Reverts on
      * division by zero. The result is rounded towards zero.
      *
      * Counterpart to Solidity's `/` operator. Note: this function uses a
      * `revert` opcode (which leaves remaining gas untouched) while Solidity
      * uses an invalid opcode to revert (consuming all remaining gas).
      *
      * Requirements:
      * - The divisor cannot be zero.
      */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
      * Reverts when dividing by zero.
      *
      * Counterpart to Solidity's `%` operator. This function uses a `revert`
      * opcode (which leaves remaining gas untouched) while Solidity uses an
      * invalid opcode to revert (consuming all remaining gas).
      *
      * Requirements:
      * - The divisor cannot be zero.
      */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


interface LinkTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256 remaining);
    function approve(address spender, uint256 value) external returns (bool success);
    function balanceOf(address owner) external view returns (uint256 balance);
    function decimals() external view returns (uint8 decimalPlaces);
    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
    function increaseApproval(address spender, uint256 subtractedValue) external;
    function name() external view returns (string memory tokenName);
    function symbol() external view returns (string memory tokenSymbol);
    function totalSupply() external view returns (uint256 totalTokensIssued);
    function transfer(address to, uint256 value) external returns (bool success);
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

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
    function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
        address _requester, uint256 _nonce)
    internal pure returns (uint256)
    {
        return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
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
        bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

abstract contract VRFConsumerBase is VRFRequestIDBase {

    using SafeMathChainlink for uint256;

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
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

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
    function requestRandomness(bytes32 _keyHash, uint256 _fee)
    internal returns (bytes32 requestId)
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
        nonces[_keyHash] = nonces[_keyHash].add(1);
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
    constructor(address _vrfCoordinator, address _link) public {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}


library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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

contract TestPool is Ownable, VRFConsumerBase {
    using SafeMath for uint256;

    // history storage
    struct Game {
        uint256 gameId;
        uint256 ticketPrice;
        uint256 tokenBuybackFee;
        uint256 pricePoolTarget;
        bool isActive;
        address winner;
        bytes32 requestId;
    }
    mapping (uint256 => Game) _games;

    // global vars
    address public _admin;

    // lottery state vars
    bool public _isEnabled;
    bool public _isGameCompleted;
    bool public _isWinnerDrawing;
    bool public _isWinnerDrawn;
    bool public _isWinnerRewarded;
    bool public _isLastGame;
    // lottery vars
    uint256 public _finishedGames = 0;
    mapping (address => uint256) public _rewards;
    struct Entry {
        address player;
        uint256 from;
        uint256 to;
    }
    mapping (uint256 => Entry) public _entries;
    uint256 public _nextEntryId = 0;

    // game vars
    uint256 public _gameId = 0;
    uint256 public _ticketPrice = 10 ** 14; // 0.0001 ETH/BNB
    uint256 public _tokenBuyBackFee = 10; // 10%
    uint256 public _pricePoolTarget = 10 ** 15; // 0,001 ETH/BNB
    uint256 public _pricePoolBalance = 0;
    uint256 public _totalTickets = 0;
    uint256 public _availableTickets = 0;
    uint256 public _nextTicketId = 0;

    // randomness vars
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public _randomResult;

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor()
    VRFConsumerBase(
        0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
        0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    ) public {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        _admin = _msgSender();

        _isEnabled = true;
        _isLastGame = false;

        createNextGame();
    }


    modifier onlyAdmin() {
        require(msg.sender == _admin, "only admin allowed");
        _;
    }




    /**** ADMIN FUNCTIONS ****/

    function pauseLottery() public onlyAdmin {
        _isEnabled = false;
    }

    function unpauseLottery() public onlyAdmin {
        _isEnabled = true;
    }


    /** LOTTERY FUNCTIONS **/

    function createNextGame() private {
        _gameId = _finishedGames;
        _totalTickets = _pricePoolTarget / getTicketShareForPricePool();
        _availableTickets = _totalTickets;
        _nextTicketId = 0;
        _pricePoolBalance = 0;
        _randomResult = 0;

        _games[_gameId] = Game(
            _gameId,
            _ticketPrice,
            _tokenBuyBackFee,
            _pricePoolTarget,
            true,
            address(0),
            0
        );

        _isGameCompleted = false;
        _isWinnerDrawing = false;
        _isWinnerDrawn = false;
        _isWinnerRewarded = false;
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() private returns (bytes32 requestId) {
        require(_randomResult == 0, 'random result is not 0');
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        _randomResult = randomness;
        _isWinnerDrawing = false;
        _isWinnerDrawn = true;
    }



    /**** PUBLIC GAME FUNCTIONS ****/

    function startNewGame() public {
        require(_isEnabled, "Lottery is not enabled");
        require(_isGameCompleted, "Current game is not completed");
        require(_isWinnerDrawn, "Winner not drawn so far");
        require(_isWinnerRewarded, "Winner not rewarded so far");
        require(!_isLastGame, "Sorry, this was the last game");

        createNextGame();
    }

    function buyTickets(uint256 amount) public payable {
        require(_isEnabled, "Lottery is not enabled");
        require(!_isGameCompleted, "Game is completed");

        uint256 ticketsToBuy = msg.value / _ticketPrice;
        //uint256 ticketsToBuy = amount;
        require(ticketsToBuy == amount, "Payment doesnt match ticket amount");

        require(ticketsToBuy <= getAvailableTickets(), "You cant buy more tickets then available");

        uint256 to = _nextTicketId + ticketsToBuy - 1;
        _entries[_nextEntryId] = Entry(
            msg.sender,
            _nextTicketId,
            to
        );
        _pricePoolBalance = _pricePoolBalance + (ticketsToBuy * getTicketShareForPricePool());

        _nextEntryId = _nextEntryId + 1;
        _nextTicketId = _nextTicketId + ticketsToBuy;

        _availableTickets = _availableTickets - ticketsToBuy;

        // game is done when all tickets are sold
        if(_availableTickets == 0) {
            _isGameCompleted = true;
        }
    }


    function drawWinner() public {
        require(_isEnabled, "Lottery is not enabled");
        require(_isGameCompleted, "Game is not completed");
        require(!_isWinnerDrawing, "Drawing winner atm");
        require(!_isWinnerDrawn, "Winner already drawn");

        _games[_gameId].requestId = getRandomNumber();

        _isWinnerDrawing = true;
    }



    function rewardWinner() public {
        require(_isEnabled, "Lottery is not enabled");
        require(_isGameCompleted, "Game is not completed");
        require(!_isWinnerDrawing, "Drawing winner atm");
        require(_isWinnerDrawn, "Winner not drawn so far");
        require(!_isWinnerRewarded, "Winner already rewarded");

        uint256 winnigTicketId = getWinningTicketId();
        address winner = address(0);

        uint256 i = 0;
        for(i = 0; i < _nextEntryId; i++) {
            if(_entries[i].from <= winnigTicketId && _entries[i].to >= winnigTicketId) {
                winner = _entries[i].player;
            }
        }

        _rewards[winner] = _rewards[winner] + _pricePoolBalance;
        _pricePoolBalance = 0;

        _games[_gameId].winner = winner;
        _games[_gameId].isActive = false;

        _finishedGames = _finishedGames + 1;
        _randomResult = 0;

        _isWinnerRewarded = true;
    }

    function claimWin() public {
        require(_rewards[msg.sender] > 0, "Nothing to withdraw for you");
    }



    /**** SETTER ****/

    function setPricePoolTarget(uint256 newTarget) public onlyAdmin {
        _pricePoolTarget = newTarget;
    }

    function setTokenBuybackFeeRate(uint256 newFeeRate) public onlyAdmin {
        _tokenBuyBackFee = newFeeRate;
    }

    function setTicketPrice(uint256 newTicketPrice) public onlyAdmin {
        _ticketPrice = newTicketPrice;
    }

    function setAdmin(address newAdmin) public onlyAdmin {
        _admin = newAdmin;
    }



    /**** GETTER ****/
    function getWinningTicketId() public view returns(uint256) {
        return _randomResult % _totalTickets;
    }

    /*function getGameInfo(uint256 gameId) public returns(Game memory) {
        return _games[gameId];
    }*/

    function getPricePoolReached() public view returns(uint256) {
        return getTicketShareForPricePool() * getSoldTickets();
    }

    function getPricePoolSize() public view returns(uint256) {
        return getTicketShareForPricePool() * _totalTickets;
    }

    function getNextTicketId() public view returns(uint256) {
        return _nextTicketId;
    }

    function getTicketShareForPricePool() public view returns(uint256) {
        return _ticketPrice / 100 * (100 - _tokenBuyBackFee);
    }

    function getSoldTickets() public view returns(uint256) {
        return _totalTickets - _availableTickets;
    }

    function getAvailableTickets() public view returns(uint256) {
        return _availableTickets;
    }

    function getTotalTickets() public view returns(uint256) {
        return _totalTickets;
    }
}