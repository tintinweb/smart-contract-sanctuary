//SourceUnit: Lottery_flattened.sol

pragma solidity ^0.5.4;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable{
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

pragma solidity ^0.5.4;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address payable private _owner;
    mapping(address => bool) private _owners;
    event OwnershipGiven(address indexed newOwner);
    event OwnershipTaken(address indexed previousOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address payable msgSender = msg.sender;
        _addOwnership(msgSender);
        _owner = msgSender;
        emit OwnershipGiven(msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() private view returns (address payable) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner 1");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _owners[msg.sender];
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function addOwnership(address payable newOwner) public onlyOwner {
        _addOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _addOwnership(address payable newOwner) private {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipGiven(newOwner);
        _owners[newOwner] = true;
    }

    function _removeOwnership(address payable __owner) private {
        _owners[__owner] = false;
        emit OwnershipTaken(__owner);
    }

    function removeOwnership(address payable __owner) public onlyOwner {
        _removeOwnership(__owner);
    }
}


pragma solidity ^0.5.4;




contract Sender is Ownable, Pausable {
    function sendTRX(
        address payable _to,
        uint256 _amount,
        uint256 _gasForTransfer
    ) external whenPaused onlyOwner {
        _to.call.value(_amount).gas(_gasForTransfer)("");
    }

    function sendTRC20(
        address payable _to,
        uint256 _amount,
        ITRC20 _token
    ) external whenPaused onlyOwner {
        _token.transfer(_to, _amount);
    }
}




pragma solidity ^0.5.4;



contract TRC20List is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private enabled;
    mapping(address => uint256) private ratioTrx;
    address [] private whiteList;
    uint256 private ratioDecimals;

    event EnableToken(address token_, uint256 ratio_);
    event DisableToken(address token_);

    constructor() public {
        ratioDecimals = 1000 * 1000 * 1000;
    }

    /**
    For enable new token or update existing
    token_  address of TRC20 smart contract
    ratio_  multiplier for determine amount of Trx corresponding this token
     */
    function enableToken(address token_, uint256 ratio_) public onlyOwner {
        require(token_ != address(0), "You must set address");
        if (enabled[token_] == 0) {
            enabled[token_] = 1;
            whiteList.push(token_);
        }
        ratioTrx[token_] = ratio_;
        emit EnableToken(token_, ratio_);
    }

    function disableToken(address token_) public onlyOwner {
        require(token_ != address(0), "You must set address");
        enabled[token_] = 0;
        removeTokenFromList(token_);
        emit DisableToken(token_);
    }

    function getRationDecimals() public view returns (uint256) {
        return ratioDecimals;
    }

    function isTokenEnabled(address token_) public view returns (bool) {
        return enabled[token_] != 0;
    }

    function getRatioTrx(address token_) public view returns (uint256) {
        require(enabled[token_] != 0, "Token not enabled");
        return ratioTrx[token_];
    }

    function removeTokenFromList(address token_) private {
        uint i = 0;
        while (whiteList[i] != token_) {
            i++;
        }
        bool found = i < whiteList.length;
        while (i < whiteList.length - 1) {
            whiteList[i] = whiteList[i + 1];
            i++;
        }
        if (found)
            whiteList.length--;
    }

    function getWhiteListAt(uint index_) public view returns (address) {
        require(whiteList.length > 0 && index_ < whiteList.length, "Index above that exist");
        return whiteList[index_];
    }

    function getWhiteListSize() public view returns (uint256) {
        return whiteList.length;
    }

    function tokenToSun(address token_, uint256 amount_) public view returns (uint256)
    {
        return amount_.mul(getRationDecimals()).div(getRatioTrx(token_));
    }
}

pragma solidity ^0.5.4;


contract ITRC20List is Ownable {
    event EnableToken(address token_, uint256 ratio_);
    event DisableToken(address token_);
    function enableToken(address token_, uint256 ratio_) public;
    function disableToken(address token_) public;
    function getRationDecimals() public view returns (uint256);
    function isTokenEnabled(address token_) public view returns (bool);
    function getRatioTrx(address token_) public view returns (uint256);
    function getElementOfEnabledList(uint index_) public view returns (address);
    function getSizeOfEnabledList() public view returns (uint256);
    function tokenToSun(address token_, uint256 amount_) public view returns (uint256);
}




pragma solidity ^0.5.4;




contract TRC20Holder is Ownable {
    ITRC20List whiteList;

    function setTRC20List(address whiteList_) public onlyOwner {
        whiteList = ITRC20List(whiteList_);
    }

    function getTRC20List() external view returns (address) {
        return address(whiteList);
    }

    modifier onlyEnabledToken(address token_) {
        require(address(whiteList) != address(0), "You must set address of token");
        require(whiteList.isTokenEnabled(token_), "This token not enabled");
        _;
    }

    function getTokens(address token_, uint256 amount_) internal onlyEnabledToken(token_) {
        require(ITRC20(token_).allowance(msg.sender, address(this)) >= amount_, "Approved less than need");
        bool res = ITRC20(token_).transferFrom(msg.sender, address(this), amount_);
        require(res);
    }

    function withdrawToken(address receiver_, address token_, uint256 amount_) internal onlyEnabledToken(token_) {
        require(ITRC20(token_).balanceOf(address(this)) >= amount_, "Can't make withdraw with this amount");
        bool res = ITRC20(token_).transfer(receiver_, amount_);
        require(res);
    }
}

pragma solidity ^0.5.4;


/**
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


pragma solidity ^0.5.4;


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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


pragma solidity ^0.5.4;







contract Lottery is Sender {
    using SafeMath for *;

    event TicketBuy(
        address indexed player,
        uint256 indexed roundId,
        bytes32 indexed ticketHash,
        uint256[5] numbers,
        uint256 totalTickets
    );

    event Drawn(
        uint256 indexed roundId,
        uint256 indexed winnerLength,
        bytes32 indexed winnerHash,
        uint256 amount,
        uint256[5] numbers,
        address payable[] winners,
        uint256[] amountsTRC20
    );

    event BlockNumber(uint256 indexed roundId, uint256 indexed blockNumber);

    event FailedPrizeTransfer(
        uint256 indexed roundId,
        uint256 indexed prize,
        address indexed player
    );

    event SetHash(
        uint256 indexed roundId,
        uint256 indexed blockNumber,
        string blockHash
    );


    uint256 public currentRoundId = 0;
    Round[] public rounds;
    uint256 public transferredWeeks;
    uint256 private lastDrawAt;

    Round public currentRound;

    address private winrContract;
    address private routerContract;

    uint256 gasForTransferTRX = 3000;

    function setGasForTRXTransfer(uint256 _gasForTransferAmount)
        external
        onlyOwner
    {
        gasForTransferTRX = _gasForTransferAmount;
    }

    struct Ticket {
        address payable[] playersArray;
        mapping(address => bool) playersMapping;
        uint256[5] numbers;
    }

    struct Round {
        uint256 roundId;
        uint256 totalTicketCount;
        uint256 blockNumber;
        bool transferred;
        string bitcoinBlockHash;
        uint256[5] randoms;
        address payable[] players;
        address payable[] winners;
        mapping(bytes32 => Ticket) tickets;
        mapping(address => bytes32[]) playersToTickets;
    }

    constructor(address _winrContract, address _routerContract) public {
        winrContract = _winrContract;
        routerContract = _routerContract;
        transferredWeeks = 0;
        lastDrawAt = now;
        rounds.push(
            Round(
                0,
                0,
                0,
                false,
                "",
                [uint256(0), 0, 0, 0, 0],
                new address payable[](0),
                new address payable[](0)
            )
        );
        currentRound = rounds[currentRoundId];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getWinrContract() public view returns (address) {
        return winrContract;
    }

    function getCurrentTicketsNumber(address _player)
        public
        view
        returns (uint256)
    {
        return rounds[currentRoundId].playersToTickets[_player].length;
    }

    function getCurrentTicket(address _player, uint256 _ticketIndex)
        public
        view
        returns (
            uint256[5] memory,
            bytes32,
            uint256
        )
    {
        bytes32 ticketHash = rounds[currentRoundId]
            .playersToTickets[_player][_ticketIndex];
        return (
            rounds[currentRoundId].tickets[ticketHash].numbers,
            ticketHash,
            rounds[currentRoundId].roundId
        );
    }

    function getTicketsNumber(address _player, uint256 _roundId)
        public
        view
        returns (uint256)
    {
        return rounds[_roundId].playersToTickets[_player].length;
    }

    function getTicket(
        address _player,
        uint256 _roundId,
        uint256 _ticketIndex
    )
        public
        view
        returns (
            uint256[5] memory,
            bytes32,
            uint256
        )
    {
        bytes32 ticketHash = rounds[_roundId]
            .playersToTickets[_player][_ticketIndex];
        return (
            rounds[_roundId].tickets[ticketHash].numbers,
            ticketHash,
            rounds[_roundId].roundId
        );
    }

    function getCurrentRound()
        public
        view
        returns (
            uint256,
            uint256,
            address payable[] memory,
            uint256,
            uint256[5] memory,
            string memory,
            address payable[] memory,
            bool
        )
    {
        return (
            rounds[currentRoundId].roundId,
            rounds[currentRoundId].totalTicketCount,
            rounds[currentRoundId].players,
            rounds[currentRoundId].blockNumber,
            rounds[currentRoundId].randoms,
            rounds[currentRoundId].bitcoinBlockHash,
            rounds[currentRoundId].winners,
            rounds[currentRoundId].transferred
        );
    }

    function getRoundById(uint256 _roundId)
        public
        view
        returns (
            uint256,
            uint256,
            address payable[] memory,
            uint256,
            uint256[5] memory,
            string memory,
            address payable[] memory,
            bool
        )
    {
        Round memory round = rounds[_roundId];
        return (
            round.roundId,
            round.totalTicketCount,
            round.players,
            round.blockNumber,
            round.randoms,
            round.bitcoinBlockHash,
            round.winners,
            round.transferred
        );
    }

    function changeWinrContract(address _contract) external onlyOwner {
        winrContract = _contract;
    }

    function getRouterContract() public view returns (address) {
        return routerContract;
    }

    function changeRouterContract(address _contract) external onlyOwner {
        routerContract = _contract;
    }

    function getLastDrawTime() public view returns (uint256 lastDrawTime) {
        lastDrawTime = lastDrawAt;
    }

    function buy(uint256[5] calldata _numbers, address payable player)
        external
        whenNotPaused
    {
        require(
            rounds[currentRoundId].blockNumber == 0,
            "Ticket sales are over for this round"
        );
        require(
            msg.sender == winrContract,
            "Only winr contract can send buy request"
        );


        bytes32 ticketHash = keccak256(abi.encode(_numbers));
        if (
            rounds[currentRoundId].tickets[ticketHash].playersArray.length == 0
        ) {
            rounds[currentRoundId].tickets[ticketHash].numbers = _numbers;
        } else {
            require(
                !rounds[currentRoundId].tickets[ticketHash]
                    .playersMapping[player],
                "Player can't buy one ticket twice"
            );
        }

        if (rounds[currentRoundId].playersToTickets[player].length == 0) {
            rounds[currentRoundId].players.push(player);
        }

        rounds[currentRoundId].tickets[ticketHash].playersArray.push(player);
        rounds[currentRoundId].tickets[ticketHash]
            .playersMapping[player] = true;
        rounds[currentRoundId].playersToTickets[player].push(ticketHash);

        rounds[currentRoundId].totalTicketCount += 1;

        emit TicketBuy(
            player,
            currentRoundId,
            ticketHash,
            _numbers,
            rounds[currentRoundId].totalTicketCount
        );
    }

    /**
     * @dev Set BTC block number to the current round and stop tickets sales
     * @param _blockNumber block number whose hash will be used for generating random numbers
     */
    function setBTCBlockNumber(uint256 _blockNumber) external onlyOwner {
        rounds[currentRoundId].blockNumber = _blockNumber;
        emit BlockNumber(currentRoundId, _blockNumber);
    }

    uint256 public ticketNumberRange = 20;

    function setRange(uint256 _newRange) public {
        ticketNumberRange = _newRange;
    }

    /**
     * @dev Get unsorted array of unique random numbers in range [1,_range] from string which represents bitcoin block hash
     * @param _bitcoinBlockHash block hash which is used for generating random numbers
     * @param _range range which is used for generating random numbers
     */
    function getRandomNumbersFromHash(
        string memory _bitcoinBlockHash,
        uint256 _range
    ) public pure returns (uint256[5] memory numbers) {
        uint256 pointer = 0;
        for (uint256 i = 0; i < 5; i++) {
            bool alreadyExists;
            do {
                alreadyExists = false;
                numbers[i] = getRandomNumberFromHash(
                    _bitcoinBlockHash,
                    _range,
                    pointer
                );
                pointer++;
                for (uint256 j = 0; j < i; j++) {
                    if (numbers[i] == numbers[j]) {
                        alreadyExists = true;
                        break;
                    }
                }
            } while (alreadyExists);
        }
    }

    /**
     * @dev Get random number from hash of the seed string in range [1,_range] and by the pointer. You can get a few different random numbers from seed passing different pointers.
     * @param _seedString seed string which is used for generating random number
     * @param _range range which is used for generating random number
     * @param _pointer pointer which is used for generating random number
     */
    function getRandomNumberFromHash(
        string memory _seedString,
        uint256 _range,
        uint256 _pointer
    ) public pure returns (uint256 number) {
        uint256 random = uint256(
            keccak256(abi.encodePacked(_seedString))
        );
        if (_pointer == 0) {
            number = random.mod(_range).add(1);
        } else {
            number = random.div(_range.mul(_pointer)).mod(_range).add(1);
        }
    }

    /**
     * @dev Calculate random numbers, draw trx to winners and create next round
     * @param _bitcoinBlockHash bitcoin block hash for generating random numbers
     */
    function draw(string calldata _bitcoinBlockHash) external onlyOwner {
        require(
            rounds[currentRoundId].blockNumber != 0,
            "Block number must be set"
        );
        uint256[5] memory randomNumbers;
        randomNumbers = getRandomNumbersFromHash(
            _bitcoinBlockHash,
            ticketNumberRange
        );
        uint256 n = randomNumbers.length;
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (randomNumbers[j] > randomNumbers[j + 1]) {
                    uint256 temp = randomNumbers[j];
                    randomNumbers[j] = randomNumbers[j + 1];
                    randomNumbers[j + 1] = temp;
                }
            }
        }

        rounds[currentRoundId].randoms = randomNumbers;

        rounds[currentRoundId].bitcoinBlockHash = _bitcoinBlockHash;
        emit SetHash(
            currentRoundId,
            rounds[currentRoundId].blockNumber,
            _bitcoinBlockHash
        );

        bytes32 winnerHash;

        winnerHash = keccak256(abi.encode(rounds[currentRoundId].randoms));

        rounds[currentRoundId].winners = rounds[currentRoundId]
            .tickets[winnerHash]
            .playersArray;
        uint256 winnerCount = rounds[currentRoundId].winners.length;
        uint256 totalPrize = address(this).balance;

        TRC20List trc20List = TRC20List(
            TRC20Holder(routerContract).getTRC20List()
        );

        ITRC20[] memory tokens = new ITRC20[](trc20List.getWhiteListSize());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ITRC20(trc20List.getWhiteListAt(i));
        }

        uint256[] memory totalPrizesTRC20 = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            totalPrizesTRC20[i] = tokens[i].balanceOf(address(this));
        }

        emit Drawn(
            currentRoundId,
            rounds[currentRoundId].winners.length,
            winnerHash,
            totalPrize,
            rounds[currentRoundId].randoms,
            rounds[currentRoundId].winners,
            totalPrizesTRC20
        );

        if (winnerCount > 0) {
            uint256 prize = address(this).balance.div(winnerCount);
            if (prize > 0) {
                for (uint256 k = 0; k < winnerCount; k++) {
                    (bool success, ) = rounds[currentRoundId].winners[k]
                        .call
                        .value(prize)
                        .gas(gasForTransferTRX)("");
                    if (!success) {
                        emit FailedPrizeTransfer(
                            currentRoundId,
                            prize,
                            rounds[currentRoundId].winners[k]
                        );
                    }
                }
            }

            for (uint256 i = 0; i < tokens.length; i++) {
                uint256 prizeTRC20 = totalPrizesTRC20[i].div(winnerCount);
                if (prizeTRC20 > 0) {
                    for (uint256 k = 0; k < winnerCount; k++) {
                        tokens[i].transfer(
                            rounds[currentRoundId].winners[k],
                            prizeTRC20
                        );
                    }
                }
            }
            transferredWeeks = 0;
        } else {
            rounds[currentRoundId].transferred = true;
            transferredWeeks += 1;
        }

        currentRoundId++;
        rounds.push(
            Round(
                currentRoundId,
                0,
                0,
                false,
                "",
                [uint256(0), 0, 0, 0, 0],
                new address payable[](0),
                new address payable[](0)
            )
        );
        currentRound = rounds[currentRoundId];
        lastDrawAt = now;
    }

    function() external payable {}
}