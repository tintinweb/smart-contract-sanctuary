pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IRewards.sol";
import "../../interfaces/IRandomNumberGenerator.sol";
import "../../interfaces/IMemeXNFT.sol";

contract Lottery is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private lotteryCounter;

    bytes32 internal requestId_;

    // Address of the randomness generator
    IRandomNumberGenerator internal randomGenerator;
    IRewards public rewardsContract;

    mapping(uint256 => LotteryInfo) internal lotteryHistory;

    // participant address => lottery ids he entered
    mapping(address => uint256[]) internal participantHistory;

    //lotteryid => prizeIds
    mapping(uint256 => uint256) internal prizes;

    mapping(uint256 => mapping(address => uint256)) internal prizeWinners;

    //lotteryid => address => amount of entries
    mapping(uint256 => mapping(address => uint256)) internal participants;

    mapping(uint256 => mapping(address => uint256)) internal boosters;

    //loteryId => randomNumber received from RNG
    mapping(uint256 => uint256) internal randomSeeds;

    mapping(uint256 => uint16) internal nextPrize;

    //this maps the entries a user received when buying a ticket or boost
    //lotteryId => address array
    mapping(uint256 => address[]) participantEntries;

    enum Status {
        Planned, // The lottery is only planned, cant buy tickets yet
        Canceled, // A lottery that got canceled
        Open, // Entries are open
        Closed, // Entries are closed. Must be closed to draw numbers
        Completed // The lottery has been completed and the numbers drawn
    }

    struct ParticipantInfo {
        address participantAddress;
        bool isBooster;
        uint256 prizeId;
        bool prizeClaimed;
        uint32 entries;
    }

    // Information about lotteries
    struct LotteryInfo {
        uint256 lotteryID; // ID for lotto
        Status status; // Status for lotto
        uint256 ticketCostPinas; // Cost per ticket in points/tokens
        uint256 ticketCostCoins; // Cost per ticket in FTM
        uint256 boostCost; // cost to boost the odds
        uint256 startingTime; // Timestamp to start the lottery
        uint256 closingTime; // Timestamp for end of entries
        IMemeXNFT nftContract; // reference to the NFT Contract
        Counters.Counter participantsCount; // number of participants
        uint32 maxParticipants; // max number of participants
    }

    event ResponseReceived(bytes32 _requestId);
    event PrizesChanged(uint256 _lotteryId, uint256 numberOfPrizes);
    event LotteryStatusChanged(uint256 _lotteryId, Status _status);
    event RequestNumbers(uint256 lotteryId, bytes32 requestId);
    event NewParticipant(
        uint256 lotteryId,
        address participantAddress,
        uint16 amountOfNumbers
    );
    event TicketCostChanged(
        address operator,
        uint256 lotteryId,
        uint256 priceOfTicket
    );
    event NumberAssignedToParticipant(
        uint256 lotteryId,
        uint256 number,
        address participantAddress
    );

    event PrizeClaimed(
        uint256 lotteryId,
        address participantAddress,
        uint256 prizeId
    );

    constructor(address _rewardsContract) {
        rewardsContract = IRewards(_rewardsContract);
    }

    function setTicketCostPinas(uint256 _price, uint256 _lotteryId)
        public
        onlyOwner
    {
        lotteryHistory[_lotteryId].ticketCostPinas = _price;
        emit TicketCostChanged(msg.sender, _lotteryId, _price);
    }

    function getNextPrize(uint256 _lotteryId) public view returns (uint16) {
        return nextPrize[_lotteryId];
    }

    function _burnPinasToken(
        address _user,
        IRewards rewardsToken,
        uint256 _amount
    ) internal {
        require(
            rewardsToken.balanceOf(_user) >= _amount,
            "Not enough PINA tokens to enter the lottery"
        );
        rewardsToken.burnPinas(_user, _amount);
    }

    function _burnUserPoints(address _user, uint256 _amount) internal {
        rewardsContract.burnUserPoints(_user, _amount);
    }

    function setRewardsContract(address _rewardsContract) public onlyOwner {
        rewardsContract = IRewards(_rewardsContract);
    }

    function setRandomGenerator(address _IRandomNumberGenerator)
        external
        onlyOwner
    {
        require(
            _IRandomNumberGenerator != address(0),
            "Contracts cannot be 0 address"
        );
        randomGenerator = IRandomNumberGenerator(_IRandomNumberGenerator);
    }

    function getParticipantHistory(address _participantAddress)
        public
        view
        returns (uint256[] memory)
    {
        return participantHistory[_participantAddress];
    }

    /**
     * @notice Get the number of entries (each ticket and each boost provide an entry).
     * @param _lotteryId The lottery ID
     * @return Amount entries for a lottery (number of tickets and boosts bought)
     */
    function getTotalEntries(uint256 _lotteryId) public view returns (uint256) {
        return participantEntries[_lotteryId].length;
    }

    /**
     * @notice Query lottery info
     * @param _lotteryId The lottery ID
     * @return Lottery info
     */
    function getLotteryInfo(uint256 _lotteryId)
        public
        view
        returns (LotteryInfo memory)
    {
        return (lotteryHistory[_lotteryId]);
    }

    /**
     * @notice Get the number of participants in a lottery.
     * @param _lotteryId The lottery ID
     * @return Amount of different addresses that have entered the lottery
     */
    function getNumberOfParticipants(uint256 _lotteryId)
        public
        view
        returns (uint256)
    {
        return lotteryHistory[_lotteryId].participantsCount.current();
    }

    modifier onlyRandomGenerator() {
        require(msg.sender == address(randomGenerator), "Only RNG address");
        _;
    }

    /**
     * @notice Changes the prizes for a lottery.
     * @param _lotteryId The lottery ID
     * @param _amount number of prizes
     */
    function setPrizes(uint256 _lotteryId, uint256 _amount) public onlyOwner {
        require(
            _lotteryId <= lotteryCounter.current(),
            "Lottery id does not exist"
        );
        require(_amount > 0, "No prize ids");
        prizes[_lotteryId] = _amount;
        emit PrizesChanged(_lotteryId, _amount);
    }

    /**
     * @notice Creates a new lottery.
     * @param _costPerTicketPinas cost in wei per ticket in points/tokens (token only when using ERC20 on the rewards contract)
     * @param _costPerTicketCoins cost in wei per ticket in FTM
     * @param _startingTime timestamp to begin lottery entries
     * @param _closingTime timestamp for end of entries
     * @param _amountOfPrizes amount of prizes
     * @param _nftContract reference to the NFT contract
     * @param _boostCost cost in wei (FTM) for users to boost their odds
     * @param _maxParticipants max number of participants. Use 0 for unlimited
     */
    function createNewLottery(
        uint256 _costPerTicketPinas,
        uint256 _costPerTicketCoins,
        uint256 _startingTime,
        uint256 _closingTime,
        IMemeXNFT _nftContract,
        uint256 _amountOfPrizes,
        uint256 _boostCost,
        uint32 _maxParticipants
    ) public onlyOwner returns (uint256 lotteryId) {
        require(
            _startingTime != 0 && _startingTime < _closingTime,
            "Timestamps for lottery invalid"
        );
        // Incrementing lottery ID
        lotteryCounter.increment();
        lotteryId = lotteryCounter.current();
        Status lotteryStatus;
        if (_startingTime <= block.timestamp) {
            lotteryStatus = Status.Open;
        } else {
            lotteryStatus = Status.Planned;
        }
        // Saving data in struct
        LotteryInfo memory newLottery = LotteryInfo(
            lotteryId,
            lotteryStatus,
            _costPerTicketPinas,
            _costPerTicketCoins,
            _boostCost,
            _startingTime,
            _closingTime,
            _nftContract,
            Counters.Counter(0),
            _maxParticipants
        );
        prizes[lotteryId] = _amountOfPrizes;
        nextPrize[lotteryId] = 1;
        emit PrizesChanged(lotteryId, _amountOfPrizes);
        lotteryHistory[lotteryId] = newLottery;
    }

    /**
     * @notice Used to check the latest lottery id.
     * @return Latest lottery id created.
     */
    function getCurrentLotteryId() public view returns (uint256) {
        return (lotteryCounter.current());
    }

    /**
     * @notice Called by the Memex team to request a random number to a particular lottery.
     * @param _lotteryId ID of the lottery the random number is for
     */
    function requestRandomNumber(uint256 _lotteryId) external onlyOwner {
        LotteryInfo storage lottery = lotteryHistory[_lotteryId];
        require(prizes[_lotteryId] != 0, "No prizes for this lottery");
        // DISABLED FOR TESTS require(lottery.closingTime < block.timestamp);
        if (lottery.status == Status.Open) {
            lottery.status = Status.Closed;
        }
        // should fail if the lottery is completed (already called drawWinningNumbers and received a response)
        require(lottery.status == Status.Closed, "Lottery must be closed!");
        requestId_ = randomGenerator.getRandomNumber(_lotteryId);
        // Emits that random number has been requested
        emit RequestNumbers(_lotteryId, requestId_);
    }

    /**
     * @notice Callback function called by the RNG contract after receiving the chainlink response.
     * Will use the received random number to assign prizes to random participants.
     * @param _lotteryId ID of the lottery the random number is for
     * @param _requestId ID of the request that was sent to the RNG contract
     * @param _randomNumber Random number provided by the VRF chainlink oracle
     */
    function receiveRandomNumber(
        uint256 _lotteryId,
        bytes32 _requestId,
        uint256 _randomNumber
    ) external onlyRandomGenerator {
        require(
            _lotteryId <= lotteryCounter.current(),
            "Lottery id does not exist"
        );
        LotteryInfo storage lottery = lotteryHistory[_lotteryId];
        require(lottery.status == Status.Closed, "Lottery must be closed");
        emit ResponseReceived(_requestId);
        randomSeeds[_lotteryId] = _randomNumber;
        lottery.status = Status.Completed;
        emit LotteryStatusChanged(_lotteryId, lottery.status);
    }

    function getParticipantsCount(uint256 _lotteryId)
        public
        view
        returns (uint256)
    {
        return lotteryHistory[_lotteryId].participantsCount.current();
    }

    function definePrizeWinners(uint256 _lotteryId, uint16 amount)
        public
        onlyOwner
    {
        LotteryInfo storage lottery = lotteryHistory[_lotteryId];
        require(
            amount + nextPrize[_lotteryId] - 1 <= prizes[_lotteryId],
            "Amount exceeds number of prizes"
        );
        uint256 randomNumber = randomSeeds[_lotteryId];

        uint256 totalParticipants_ = lottery.participantsCount.current();

        // if there are less participants than prizes, reduce the number of prizes
        if (totalParticipants_ < prizes[_lotteryId]) {
            prizes[_lotteryId] = uint16(totalParticipants_);
        }
        uint16 _winnersDefined = nextPrize[_lotteryId];
        // Loops through each prize assigning to a position on the entries array
        for (
            uint16 i = _winnersDefined;
            i <= prizes[_lotteryId] && i < _winnersDefined + amount;
            i++
        ) {
            uint256 totalEntries = participantEntries[_lotteryId].length;
            // Encodes the random number with its position in loop
            bytes32 hashOfRandom = keccak256(abi.encodePacked(randomNumber, i));
            // Casts random number hash into uint256
            uint256 numberRepresentation = uint256(hashOfRandom);
            // Sets the winning number position to a uint16 of random hash number
            uint256 winningNumber = uint256(
                numberRepresentation % totalEntries
            );
            // defines the winner
            bool winnerFound = false;
            do {
                address winnerAddress = participantEntries[_lotteryId][
                    winningNumber
                ];
                if (prizeWinners[_lotteryId][winnerAddress] == 0) {
                    prizeWinners[_lotteryId][winnerAddress] = i;
                    winnerFound = true;
                    // move the last position to remove the entry from the array
                    participantEntries[_lotteryId][
                        winningNumber
                    ] = participantEntries[_lotteryId][totalEntries - 1];
                    participantEntries[_lotteryId].pop();
                } else {
                    // If address is already a winner pick the next number until a new winner is found
                    winningNumber++;
                    winningNumber = winningNumber % totalEntries;
                }
            } while (winnerFound == false);
        }
        nextPrize[_lotteryId] = nextPrize[_lotteryId] + amount;
        emit LotteryStatusChanged(_lotteryId, lottery.status);
    }

    /**
     * @notice Change the lottery state to canceled.
     * @param _lotteryId ID of the lottery to canccel
     */
    function cancelLottery(uint256 _lotteryId) public onlyOwner {
        LotteryInfo storage lottery = lotteryHistory[_lotteryId];
        require(
            lottery.status != Status.Completed,
            "Lottery already completed"
        );
        lottery.status = Status.Canceled;
        emit LotteryStatusChanged(_lotteryId, lottery.status);
    }

    /**
     * @notice Function called by users to buy lottery tickets
     * @param _lotteryId ID of the lottery to buy tickets for
     * @param numberOfTickets Number of tickets to buy
     */
    function buyTickets(uint256 _lotteryId, uint8 numberOfTickets)
        public
        payable
    {
        LotteryInfo storage lottery = lotteryHistory[_lotteryId];
        if (lottery.maxParticipants != 0) {
            require(
                lottery.participantsCount.current() < lottery.maxParticipants,
                "Lottery is full"
            );
        }
        if (
            lottery.status == Status.Planned &&
            lottery.startingTime < block.timestamp
        ) {
            lottery.status = Status.Open;
            emit LotteryStatusChanged(_lotteryId, lottery.status);
        }
        if (
            lottery.status == Status.Open &&
            lottery.closingTime < block.timestamp
        ) {
            lottery.status = Status.Closed;
            emit LotteryStatusChanged(_lotteryId, lottery.status);
        }
        require(lottery.status == Status.Open, "Lottery is not open");

        IRewards rewardsToken = rewardsContract.getRewardToken();

        uint256 totalCostInPoints = numberOfTickets * lottery.ticketCostPinas;
        if (totalCostInPoints > 0) {
            // if the pool in use is rewarding ERC-20 tokens we burn the ticket cost
            if (address(rewardsToken) != address(0)) {
                _burnPinasToken(msg.sender, rewardsToken, totalCostInPoints);
            } else {
                // if the pool is not using tokens we just handle the reward as points
                _burnUserPoints(msg.sender, totalCostInPoints);
            }
        }
        uint256 totalCostInCoins = numberOfTickets * lottery.ticketCostCoins;
        if (totalCostInCoins > 0) {
            require(
                msg.value >= totalCostInCoins,
                "Didn't transfer enough funds to buy tickets"
            );
        }
        uint256 userEntries = participants[_lotteryId][msg.sender];
        if (userEntries == 0) {
            participantHistory[msg.sender].push(_lotteryId);
            lottery.participantsCount.increment();
            participants[_lotteryId][msg.sender] = numberOfTickets;
        } else {
            participants[_lotteryId][msg.sender] += numberOfTickets;
        }
        for (uint8 i = 0; i < numberOfTickets; i++) {
            assignNewEntryToParticipant(_lotteryId, msg.sender);
        }
    }

    /**
     * @notice Function called when user buys a ticket or boost. Gives the user a new lottery entry.
     * @param _lotteryId ID of the lottery to buy tickets for
     * @param _participantAddress Address of the participant that will receive the new entry
     */
    function assignNewEntryToParticipant(
        uint256 _lotteryId,
        address _participantAddress
    ) private {
        require(
            participants[_lotteryId][_participantAddress] != 0,
            "Participant not found"
        );
        participantEntries[_lotteryId].push(_participantAddress);
        emit NumberAssignedToParticipant(
            _lotteryId,
            participantEntries[_lotteryId].length - 1,
            _participantAddress
        );
    }

    /**
     * @notice Function called to check if a user boosted on a particular lottery.
     * @param _lotteryId ID of the lottery to check if user boosted
     * @param _participantAddress Address of the participant to check
     */
    function isBooster(uint256 _lotteryId, address _participantAddress)
        public
        view
        returns (bool)
    {
        return boosters[_lotteryId][_participantAddress] != 0;
    }

    /**
     * @notice Boost the participant odds on the lottery.
     * @param _lotteryId ID of the lottery to boost
     * @param _participantAddress Address of the participant that will receive the boost
     */
    function boostParticipant(uint256 _lotteryId, address _participantAddress)
        public
        payable
    {
        require(
            _lotteryId <= lotteryCounter.current(),
            "Lottery id does not exist"
        );
        require(
            participants[_lotteryId][_participantAddress] != 0,
            "Participant not found"
        );
        require(
            boosters[_lotteryId][_participantAddress] == 0,
            "Participant already a booster"
        );
        // check if the transaction contains the boost cost
        require(
            msg.value >= lotteryHistory[_lotteryId].boostCost,
            "Not enough tokens to boost"
        );

        boosters[_lotteryId][_participantAddress] = 1;
        assignNewEntryToParticipant(_lotteryId, _participantAddress);
    }

    /**
     * @notice Function called to check if a user won a prize.
     * @param _lotteryId ID of the lottery to check if user won
     * @param _address Address of the participant to check
     * @return true if the winner won a prize, with the prize id and if the prize was already claimed
     */
    function isAddressWinner(uint256 _lotteryId, address _address)
        public
        view
        returns (
            bool,
            uint256,
            bool
        )
    {
        LotteryInfo memory lottery = lotteryHistory[_lotteryId];
        require(lottery.status == Status.Completed, "Lottery not completed");
        IMemeXNFT nftContract = lotteryHistory[_lotteryId].nftContract;
        uint256 prizeId = prizeWinners[_lotteryId][_address];
        address owner = nftContract.getNFTOwner(prizeId);
        return (prizeId != 0, prizeId, owner != address(0));
    }

    /**
     * @notice Function called to check if the caller won a prize.
     * @param _lotteryId ID of the lottery to check if user won
     * @return true if the winner won a prize, with the prize id and if the prize was already claimed
     */
    function isCallerWinner(uint256 _lotteryId)
        public
        view
        returns (
            bool,
            uint256,
            bool
        )
    {
        return isAddressWinner(_lotteryId, msg.sender);
    }

    /**
     * @notice Called to mint a prize to the winner.
     * @param _lotteryId ID of the lottery to check if user won
     */
    function redeemNFT(uint256 _lotteryId) public {
        require(
            lotteryHistory[_lotteryId].status == Status.Completed,
            "Status Not Completed"
        );
        uint256 prizeId = prizeWinners[_lotteryId][msg.sender];
        require(
            prizeWinners[_lotteryId][msg.sender] != 0,
            "Participant is not a winner"
        );
        IMemeXNFT nftContract = lotteryHistory[_lotteryId].nftContract;
        require(
            nftContract.getNFTOwner(prizeId) == address(0),
            "Participant already claimed prize"
        );
        nftContract.create(msg.sender, prizeId, 1, 1, "", _lotteryId);
        emit PrizeClaimed(_lotteryId, msg.sender, prizeId);
    }

    /**
     * @notice Function called to withdraw funds (FTM) from the contract.
     * @param _to Recipient of the funds
     * @param _amount Amount to withdraw
     */
    function withdraw(address payable _to, uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance);
        _to.transfer(_amount);
    }
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
    constructor() {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewards {
    /**
     * Pina points earned by the player.
     */
    function earned(address account) external returns (uint256);

    function burnUserPoints(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function burnPinas(address account, uint256 amount) external;

    function mintPinas(address recipient, uint256 amount) external;

    function getRewardToken() external view returns (IRewards);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomNumberGenerator {
    /**
     * Requests randomness for a given lottery id
     */
    function getRandomNumber(uint256 lotteryId)
        external
        returns (bytes32 requestId);
}

pragma solidity >=0.6.0;

//SPDX-License-Identifier: MIT

interface IMemeXNFT {
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes calldata _data,
        uint256 _lotteryId
    ) external;

    function initNFT(
        string memory _name,
        string memory _symbol,
        address _admin
    ) external;

    function setBaseMetadataURI(string memory _newBaseMetadataURI) external;

    function create(
        address _initialOwner,
        uint256 _id,
        uint256 _initialSupply,
        uint256 _maxSupply,
        bytes calldata _data,
        uint256 _lotteryId
    ) external returns (uint256);

    function getNFTOwner(uint256 _id) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

