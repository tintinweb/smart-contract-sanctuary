// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

import './interfaces/IPlearnLucky.sol';
import './interfaces/IRandomNumberGenerator.sol';

contract PlearnLucky is IPlearnLucky, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public operatorAddress;
    address public burningAddress; //Send tokens from every deposit to burn

    uint256 internal _currentLuckyId;
    uint256 internal _currentTicketId;
    uint32 internal _currentLuckyNumber;

    uint256 public maxNumberTicketsPerBuyOrClaim;
    uint256 public maxPriceTicketInPlearn;
    uint256 public minPriceTicketInPlearn;
    uint256 public maxDiffPriceUpdate;

    uint256 public maxLengthRound;
    uint256 public minLengthRound;

    IERC20Upgradeable public plearnToken;
    IRandomNumberGenerator public randomGenerator;

    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }

    struct Lucky {
        Status status;
        uint256 startTime;
        uint256 endTime;
        uint256 priceTicketInPlearn;
        uint256 priceTicketInBUSD;
        uint256 discountDivisor;
        uint32[] countLuckyNumbersPerBracket;
        uint256 firstTicketId;
        uint256 firstTicketIdNextLottery;
        uint256 amountCollectedInPlearn;
        uint256 maxTicketsPerRound;
        uint256 maxTicketsPerUser;
        uint32[] luckyNumbers;
    }

    struct Ticket {
        uint32 number;
        address owner;
        uint32 bracket;
    }

    // Mapping are cheaper than arrays
    mapping(uint256 => Lucky) private _lucks;
    mapping(uint256 => Ticket) private _tickets;

    // Keep track of user ticket ids for a given round Id
    mapping(address => mapping(uint256 => uint256[])) private _userTicketIdsPerLuckyId;

    modifier notContract() {
        require(!_isContract(msg.sender), 'Contract not allowed');
        require(msg.sender == tx.origin, 'Proxy contract not allowed');
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, 'Not operator');
        _;
    }

    event AdminTokenRecovery(address token, uint256 amount);
    event NewManagingAddresses(address operator, address burningAddress);
    event NewRandomGenerator(address indexed randomGenerator);

    event LuckyNumbersDrawn(uint256 indexed luckyId, uint32[] luckyNumbers);
    event LuckyClose(uint256 indexed luckyId, uint256 firstTicketIdNextLottery);
    event LuckyOpen(
        uint256 indexed luckyId,
        uint256 startTime,
        uint256 endTime,
        uint256 priceTicketInPlearn,
        uint256 priceTicketInBUSD,
        uint32[] countLuckyNumbersPerBracket,
        uint256 firstTicketId,
        uint256 maxTicketsPerRound,
        uint256 maxTicketsPerUser
    );
    event TicketsPurchase(address indexed buyer, uint256 indexed roundId, uint256 numberTickets);

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _plearnTokenAddress: address of the Plearn token
     * @param _randomGeneratorAddress: address of the RandomGenerator contract used to work with ChainLink VRF
     */
    function initialize(address _plearnTokenAddress, address _randomGeneratorAddress) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        // Initializes values
        maxNumberTicketsPerBuyOrClaim = 100; //type(uint256).max;
        maxPriceTicketInPlearn = 50 ether;
        minPriceTicketInPlearn = 0.005 ether;
        maxDiffPriceUpdate = 1500; //Difference between old and new price given from oracle

        minLengthRound = 1 hours - 5 minutes; // 1 hours
        maxLengthRound = 60 days + 5 minutes; // 60 days

        plearnToken = IERC20Upgradeable(_plearnTokenAddress);
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
    }

    /**
     * @notice Buy tickets for the current lucky
     * @param _luckyId: lucky id
     * @param _numberTickets: number of ticket want to buy
     * @dev Callable by users
     */
    function buyTickets(uint256 _luckyId, uint256 _numberTickets) external override notContract nonReentrant {
        require(_lucks[_luckyId].status == Status.Open, 'Lucky is not open');
        require(block.timestamp < _lucks[_luckyId].endTime, 'Lucky is over');
        require(_numberTickets != 0, 'Number of tickets must be > 0');
        require(_numberTickets <= maxNumberTicketsPerBuyOrClaim, 'Too many tickets');
        require(
            (_userTicketIdsPerLuckyId[msg.sender][_luckyId].length + _numberTickets) <=
                _lucks[_luckyId].maxTicketsPerUser,
            'Limit tickets per user each a round'
        );
        require((_currentTicketId + _numberTickets) <= _lucks[_luckyId].maxTicketsPerRound, 'Ticket not enough');

        // Calculate number of Plearn to this contract
        uint256 amountPlearnToTransfer = calculateTotalPriceForTickets(
            _lucks[_luckyId].discountDivisor,
            _lucks[_luckyId].priceTicketInPlearn,
            _numberTickets
        );

        // Transfer Plearn tokens to this contract
        plearnToken.safeTransferFrom(address(msg.sender), address(this), amountPlearnToTransfer);

        // Increment the total amount collected for the lottery round
        _lucks[_luckyId].amountCollectedInPlearn += amountPlearnToTransfer;

        uint256 thisTicketId = _currentTicketId;
        uint32 thisLuckyNumber = _currentLuckyNumber;

        for (uint256 i = 0; i < _numberTickets; i++) {
            _userTicketIdsPerLuckyId[msg.sender][_luckyId].push(thisTicketId);
            _tickets[thisTicketId] = Ticket({number: thisLuckyNumber, owner: msg.sender, bracket: 0});

            // Increase ticket id and lucky number
            thisTicketId++;
            thisLuckyNumber++;
        }

        _currentTicketId += _numberTickets;
        _lucks[_luckyId].firstTicketIdNextLottery = _currentTicketId;

        emit TicketsPurchase(msg.sender, _luckyId, _numberTickets);
    }

    /**
     * @notice Calculate final price for bulk of tickets
     * @param _discountDivisor: divisor for the discount (the smaller it is, the greater the discount is)
     * @param _priceTicket: price of a ticket (in Plearn)
     * @param _numberTickets: number of tickets purchased
     */
    function calculateTotalPriceForTickets(
        uint256 _discountDivisor,
        uint256 _priceTicket,
        uint256 _numberTickets
    ) public pure returns (uint256) {
        require(_numberTickets != 0, 'Number of tickets must be > 0');
        if (_discountDivisor != 0) {
            return (_priceTicket * _numberTickets * (_discountDivisor + 1 - _numberTickets)) / _discountDivisor;
        } else {
            return _priceTicket * _numberTickets;
        }
    }

    /**
     * @notice Close lucky round
     * @param _luckyId: lucky id
     * @dev Callable by operator
     */
    function closeLucky(uint256 _luckyId) external override onlyOperator nonReentrant {
        require(_lucks[_luckyId].status == Status.Open, 'Lucky not open');
        require(block.timestamp > _lucks[_luckyId].endTime, 'Lucky not over');

        // Request a random number from the generator
        if (_getCountTicketsInRound(_luckyId) != 0) {
            randomGenerator.clearRandomResults();
            randomGenerator.requestRandomNumber();
        }
        _lucks[_luckyId].status = Status.Close;

        emit LuckyClose(_luckyId, _currentTicketId);
    }

    /**
     * @notice Change the random generator
     * @dev The calls to functions are used to verify the new generator implements them properly.
     * It is necessary to wait for the VRF response before starting a round.
     * Callable only by the contract owner
     * @param _randomGeneratorAddress: address of the random generator
     */
    function changeRandomGenerator(address _randomGeneratorAddress) external onlyOwner {
        require(_lucks[_currentLuckyId].status == Status.Claimable, 'Lucky not in claimable');

        // Request a random number from the generator based on a seed
        IRandomNumberGenerator(_randomGeneratorAddress).requestRandomNumber();

        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        IRandomNumberGenerator(_randomGeneratorAddress).getRandomResults();

        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

        emit NewRandomGenerator(_randomGeneratorAddress);
    }

    /**
     * @notice Confirm a set of lucky tickets
     * @param _luckyId: lucky id
     * @param _ticketIds: array of ticket ids
     * @param _brackets: array of bracket for the ticket ids
     * @dev Callable by users only, not contract!
     */
    function confirmTickets(
        uint256 _luckyId,
        uint256[] calldata _ticketIds,
        uint32[] calldata _brackets
    ) external override notContract nonReentrant {
        require(_ticketIds.length == _brackets.length, 'Not same length');
        require(_ticketIds.length != 0, 'Length must be >0');
        require(_ticketIds.length <= maxNumberTicketsPerBuyOrClaim, 'Too many tickets');
        require(_lucks[_luckyId].status == Status.Claimable, 'Lucky not claimable');

        for (uint256 i = 0; i < _ticketIds.length; i++) {
            uint256 ticketId = _ticketIds[i];
            uint32 bracket = _brackets[i];
            require(_lucks[_luckyId].firstTicketIdNextLottery >= ticketId, 'TicketId too high');
            require(_lucks[_luckyId].firstTicketId <= ticketId, 'TicketId too low');
            require(bracket != 0, 'Bracket must be >0');
            require(msg.sender == _tickets[ticketId].owner, 'Not the owner');

            (, uint32[] memory countAvailablesPerBracket) = getBracketStatus(_luckyId);
            uint32 bracketIndex = bracket - 1;

            require(countAvailablesPerBracket[bracketIndex] != 0, 'Bracket not available');
            _tickets[ticketId].bracket = bracket;
        }
    }

    /**
     * @notice Draw the lucky numbers
     * @param _luckyId: lucky id
     * @param _autoAllocateBracket: //auto allowcate barcket to lucky tickets
     * @dev Callable by operator
     */
    function drawLuckyNumbersAndMakeTicketConfirmable(uint256 _luckyId, bool _autoAllocateBracket)
        external
        override
        onlyOperator
        nonReentrant
    {
        require(_lucks[_luckyId].status == Status.Close, 'Lucky not close');
        require(_luckyId == randomGenerator.getLastedLuckyId(), 'Lucky numbers not drawn');

        // Calculate the winner numbers based on the randomResult generated by ChainLink's fallback
        uint32[] memory luckyNumbers = randomGenerator.getRandomResults();
        require(_lucks[_luckyId].luckyNumbers.length == luckyNumbers.length, 'Lucky numbers not same length');

        // Allocate winner tickets to brackets
        if (_autoAllocateBracket) {
            uint256 count = 0;
            uint32 bracketIndex = 0;
            uint32 countLuckyNumbersPerBracket = _lucks[_luckyId].countLuckyNumbersPerBracket[bracketIndex];

            for (uint256 i = 0; i < luckyNumbers.length; i++) {
                uint32 luckyNumber = luckyNumbers[i];
                uint256 firstTicketId = _lucks[_luckyId].firstTicketId;
                uint256 ticketId = firstTicketId + (luckyNumber % 100000);
                _tickets[ticketId].bracket = (bracketIndex + 1);
                count++;
                if (count == countLuckyNumbersPerBracket) {
                    count = 0;
                    bracketIndex++;
                    if (bracketIndex < _lucks[_luckyId].countLuckyNumbersPerBracket.length) {
                        countLuckyNumbersPerBracket = _lucks[_luckyId].countLuckyNumbersPerBracket[bracketIndex];
                    }
                }
            }
        }

        // Update internal statuses for round
        _lucks[_luckyId].luckyNumbers = luckyNumbers;
        if (!_autoAllocateBracket) {
            _lucks[_luckyId].status = Status.Claimable;
        }

        emit LuckyNumbersDrawn(_luckyId, _lucks[_luckyId].luckyNumbers);
    }

    //TODO("Add note message")
    function getBracketStatus(uint256 _luckyId) public view returns (uint32[] memory, uint32[] memory) {
        uint256 firstTicketId = _lucks[_luckyId].firstTicketId;
        uint256 firstTicketIdNextLottery = _lucks[_luckyId].firstTicketIdNextLottery;
        uint32[] memory countLuckyNumbersPerBracket = _lucks[_luckyId].countLuckyNumbersPerBracket;
        uint32[] memory countAvailablesPerBracket = countLuckyNumbersPerBracket;

        for (uint256 i = firstTicketId; i < firstTicketIdNextLottery; i++) {
            if (_tickets[i].bracket != 0) {
                uint32 bracketIndex = _tickets[i].bracket - 1;
                uint32 countAvailable = countAvailablesPerBracket[bracketIndex];
                countAvailable--;
                countAvailablesPerBracket[bracketIndex] = countAvailable;
            }
        }

        return (countLuckyNumbersPerBracket, countAvailablesPerBracket);
    }

    /**
     * @notice Return count of lucky numbers each a round
     */
    function getCountLuckyNumbersPerRound(uint256 _luckyId) external view override returns (uint32) {
        uint32 countLuckyNumbersPerRound = 0;
        for (uint32 i = 0; i < _lucks[_luckyId].countLuckyNumbersPerBracket.length; i++) {
            uint32 count = _lucks[_luckyId].countLuckyNumbersPerBracket[i];
            countLuckyNumbersPerRound += count;
        }
        return countLuckyNumbersPerRound;
    }

    function getCountTicketsInRound(uint256 _luckyId) external view override returns (uint256) {
        return _getCountTicketsInRound(_luckyId);
    }

    /**
     * @notice Return current lucky id
     */
    function getCurrentLuckyId() external view override returns (uint256) {
        return _currentLuckyId;
    }

    /**
     * @notice Return current ticket id
     */
    function getCurrentTicketId() external view returns (uint256) {
        return _currentTicketId;
    }

    /**
     * @notice Return first ticket number and last ticket number each a round
     * @param _luckyId: lucky id
     */
    function getFirstAndLasTicketNumberInRound(uint256 _luckyId) external view override returns (uint32, uint32) {
        if (_lucks[_luckyId].firstTicketIdNextLottery > _lucks[_luckyId].firstTicketId) {
            return (
                _tickets[_lucks[_luckyId].firstTicketId].number,
                _tickets[_lucks[_luckyId].firstTicketIdNextLottery - 1].number
            );
        } else {
            return (0, 0);
        }
    }

    /**
     * @notice Get round information
     * @param _luckyId: round id
     */
    function getLuckyInfo(uint256 _luckyId) external view returns (Lucky memory) {
        return _lucks[_luckyId];
    }

    /**
     * @notice View user ticket ids, and statuses of user for a given lucky
     * @param _user: user address
     * @param _luckyId: lucky id
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     */
    function getUserInfoForLuckyId(
        address _user,
        uint256 _luckyId,
        uint256 _cursor,
        uint256 _size
    )
        external
        view
        returns (
            uint256[] memory,
            uint32[] memory,
            bool[] memory,
            uint256
        )
    {
        uint256 length = _size;
        uint256 numberTicketsBoughtAtLuckyId = _userTicketIdsPerLuckyId[_user][_luckyId].length;

        if (length > (numberTicketsBoughtAtLuckyId - _cursor)) {
            length = numberTicketsBoughtAtLuckyId - _cursor;
        }

        uint256[] memory lotteryTicketIds = new uint256[](length);
        uint32[] memory ticketNumbers = new uint32[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            lotteryTicketIds[i] = _userTicketIdsPerLuckyId[_user][_luckyId][i + _cursor];
            ticketNumbers[i] = _tickets[lotteryTicketIds[i]].number;
            // True = ticket confirmed
            if (_tickets[lotteryTicketIds[i]].bracket != 0) {
                ticketStatuses[i] = true;
            } else {
                // ticket not confirmed (includes the ones that not lucky)
                ticketStatuses[i] = false;
            }
        }

        return (lotteryTicketIds, ticketNumbers, ticketStatuses, _cursor + length);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(plearnToken), 'Cannot be Plearn token');

        IERC20Upgradeable(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Set Plearn price ticket upper/lower limit
     * @dev Only callable by owner
     * @param _minPriceTicketInPlearn: minimum price of a ticket in Plearn
     * @param _maxPriceTicketInPlearn: maximum price of a ticket in PLearn
     */
    function setMinAndMaxTicketPriceInPlearn(uint256 _minPriceTicketInPlearn, uint256 _maxPriceTicketInPlearn)
        external
        onlyOwner
    {
        require(_minPriceTicketInPlearn <= _maxPriceTicketInPlearn, 'minPrice must be < maxPrice');
        minPriceTicketInPlearn = _minPriceTicketInPlearn;
        maxPriceTicketInPlearn = _maxPriceTicketInPlearn;
    }

    /**
     * @notice Set max number of tickets
     * @dev Only callable by owner
     */
    function setMaxNumberTicketsPerBuy(uint256 _maxNumberTicketsPerBuy) external onlyOwner {
        require(_maxNumberTicketsPerBuy != 0, 'Must be > 0');
        maxNumberTicketsPerBuyOrClaim = _maxNumberTicketsPerBuy;
    }

    /**
     * @notice Set max difference between old and new price when update from oracle
     * @dev Only callable by owner
     */
    function setMaxDiffPriceUpdate(uint256 _maxDiffPriceUpdate) external onlyOwner {
        require(_maxDiffPriceUpdate != 0, 'Must be > 0');
        maxDiffPriceUpdate = _maxDiffPriceUpdate;
    }

    /**
     * @notice Set operator, and burning addresses
     * @dev Only callable by owner
     * @param _operatorAddress: address of the operator
     * @param _burningAddress: address to collect burn tokens
     */
    function setManagingAddresses(address _operatorAddress, address _burningAddress) external onlyOwner {
        require(_operatorAddress != address(0), 'Cannot be zero address');
        require(_burningAddress != address(0), 'Cannot be zero address');

        operatorAddress = _operatorAddress;
        burningAddress = _burningAddress;

        emit NewManagingAddresses(_operatorAddress, _burningAddress);
    }

    /**
     * @notice Start lucky round
     * @dev Callable by operator
     * @param _endTime: endTime of ther lucky
     * @param _priceTicketInPlearn: price of a ticket in Plearn
     * @param _priceTicketInBUSD: price of a ticket in BUSD
     * @param _discountDivisor: the divisor to calculate the discount magnitude for bulks
     * @param _countLuckyNumbersPerBracket: array of number of lucky in each round
     * @param _maxTicketsPerRound: maximum of ticket to salable in each round
     * @param _maxTicketsPerUser: maximum of ticket to salable for user in each round
     */
    function startLucky(
        uint256 _endTime,
        uint256 _priceTicketInPlearn, //For now
        uint256 _priceTicketInBUSD,
        uint256 _discountDivisor,
        uint32[] calldata _countLuckyNumbersPerBracket,
        uint256 _maxTicketsPerRound,
        uint256 _maxTicketsPerUser
    ) external override onlyOperator {
        require(
            (_currentLuckyId == 0) || (_lucks[_currentLuckyId].status == Status.Claimable),
            'Not time to start lucky'
        );

        require(
            ((_endTime - block.timestamp) > minLengthRound) && ((_endTime - block.timestamp) < maxLengthRound),
            'Round length outside of range'
        );

        //TODO()
        //Calculation price in Plern
        //uint256 _priceTicketInPlearn = _getPriceInPlearn(_priceTicketInBUSD);

        require(
            (_priceTicketInPlearn >= minPriceTicketInPlearn) && (_priceTicketInPlearn <= maxPriceTicketInPlearn),
            'Price ticket in Plearn Outside of limits'
        );

        uint32 countLuckyNumbersPerRound = 0;
        for (uint32 i = 0; i < _countLuckyNumbersPerBracket.length; i++) {
            uint32 count = _countLuckyNumbersPerBracket[i];
            countLuckyNumbersPerRound += count;
        }
        require(countLuckyNumbersPerRound != 0, 'Number of luckies per round must be > 0');

        _currentLuckyNumber = 1000000;
        _currentLuckyId++;

        _lucks[_currentLuckyId] = Lucky({
            status: Status.Open,
            startTime: block.timestamp,
            endTime: _endTime,
            priceTicketInPlearn: _priceTicketInPlearn,
            priceTicketInBUSD: _priceTicketInBUSD,
            discountDivisor: _discountDivisor,
            countLuckyNumbersPerBracket: _countLuckyNumbersPerBracket,
            firstTicketId: _currentTicketId,
            firstTicketIdNextLottery: _currentTicketId,
            amountCollectedInPlearn: 0,
            maxTicketsPerRound: _maxTicketsPerRound,
            maxTicketsPerUser: _maxTicketsPerUser,
            luckyNumbers: new uint32[](countLuckyNumbersPerRound)
        });

        emit LuckyOpen(
            _currentLuckyId,
            block.timestamp,
            _endTime,
            _priceTicketInPlearn,
            _priceTicketInBUSD,
            _countLuckyNumbersPerBracket,
            _currentTicketId,
            _maxTicketsPerRound,
            _maxTicketsPerUser
        );
    }

    /**
     * @notice Tranfer a set of tickets to other address
     * @param _to: the address to tranfer ownership of ticket
     * @param _ticketIds: array of ticket ids
     * @dev Callable by users only, not contract!
     */
    function tranferTickets(address _to, uint256[] calldata _ticketIds) external override {
        bool isOwner = true;
        for (uint256 i = 0; i < _ticketIds.length; i++) {
            uint256 ticketId = _ticketIds[i];
            if (_tickets[ticketId].owner != msg.sender) {
                isOwner = false;
                break;
            }
        }
        require(isOwner, 'Not the owner');

        for (uint256 i = 0; i < _ticketIds.length; i++) {
            uint256 ticketId = _ticketIds[i];
            _tickets[ticketId].owner = _to;
        }
    }

    function _getCountTicketsInRound(uint256 _luckyId) internal view returns (uint256) {
        if (_lucks[_luckyId].firstTicketIdNextLottery > _lucks[_luckyId].firstTicketId) {
            return _lucks[_luckyId].firstTicketIdNextLottery - _lucks[_luckyId].firstTicketId;
        } else {
            return 0;
        }
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPlearnLucky {
    /**
     * @notice Buy tickets for the current lucky
     * @param _luckyId: lucky id
     * @param _numberTickets: number of ticket want to buy
     * @dev Callable by users
     */
    function buyTickets(uint256 _luckyId, uint256 _numberTickets) external;

    /**
     * @notice Close lucky round
     * @param _luckyId: lucky id
     * @dev Callable by operator
     */
    function closeLucky(uint256 _luckyId) external;

    /**
     * @notice Confirm a set of lucky tickets
     * @param _luckyId: lucky id
     * @param _ticketIds: array of ticket ids
     * @param _brackets: array of bracket for the ticket ids
     * @dev Callable by users only, not contract!
     */
    function confirmTickets(
        uint256 _luckyId,
        uint256[] calldata _ticketIds,
        uint32[] calldata _brackets
    ) external;

    /**
     * @notice Draw the lucky numbers
     * @param _luckyId: lucky id
     * @param _autoAllocateBracket: //auto allowcate barcket to lucky tickets
     * @dev Callable by operator
     */
    function drawLuckyNumbersAndMakeTicketConfirmable(uint256 _luckyId, bool _autoAllocateBracket) external;

    //TODO("Add note message")
    //function getBracketStatus(uint256 _luckyId) external returns (uint32[] memory, uint32[] memory);

    /**
     * @notice Return count of lucky numbers each a round
     */
    function getCountLuckyNumbersPerRound(uint256 _luckyId) external returns (uint32);

    function getCountTicketsInRound(uint256 _luckyId) external returns (uint256);

    /**
     * @notice Return current lucky id
     */
    function getCurrentLuckyId() external returns (uint256);

    /**
     * @notice Return first ticket number and last ticket number each a round
     * @param _luckyId: lucky id
     */
    function getFirstAndLasTicketNumberInRound(uint256 _luckyId)
        external
        returns (uint32 firstTicketNnmber, uint32 lastTicketNumber);

    /**
     * @notice Start lucky round
     * @dev Callable by operator
     * @param _endTime: endTime of ther lucky
     * @param _priceTicketInPlearn: price of a ticket in Plearn
     * @param _priceTicketInBUSD: price of a ticket in BUSD
     * @param _discountDivisor: the divisor to calculate the discount magnitude for bulks
     * @param _countLuckyNumbersPerBracket: array of number of lucky in each round
     * @param _maxTicketsPerRound: maximum of ticket to salable in each round
     * @param _maxTicketsPerUser: maximum of ticket to salable for user in each round
     */
    function startLucky(
        uint256 _endTime,
        uint256 _priceTicketInPlearn, //For now
        uint256 _priceTicketInBUSD,
        uint256 _discountDivisor,
        uint32[] calldata _countLuckyNumbersPerBracket,
        uint256 _maxTicketsPerRound,
        uint256 _maxTicketsPerUser
    ) external;

    /**
     * @notice Tranfer a set of tickets to other address
     * @param _to: the address to tranfer ownership of ticket
     * @param _ticketIds: array of ticket ids
     * @dev Callable by users only, not contract!
     */
    function tranferTickets(address _to, uint256[] calldata _ticketIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRandomNumberGenerator {

    /**
     * @notice Clear previous random result before start new round 
     */
    function clearRandomResults() external;

    /**
     * @notice Return latest lucky id that random numbers has generated
     */
    function getLastedLuckyId() external view returns (uint256);

    /**
     * @notice Return array of randomness number
     */
    function getRandomResults() external view returns (uint32[] memory);

    /**
     * @notice Requests to generate random numbers
     */
    function requestRandomNumber() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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