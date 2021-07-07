/**
 *Submitted for verification at polygonscan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

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


// solhint-disable-next-line compiler-version
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
}


interface ILottery {

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getMaxRange() external view returns(uint32);

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    function numbersDrawn(
        uint256 _lotteryId,
        bytes32 _requestId,
        uint256 _randomNumber
    )
    external;
}


contract Ticket is Ownable, Initializable {
    // State variables
    address internal lotteryContract_;

    uint256 internal totalSupply_;

    // Storage for ticket information
    struct TicketInfo {
        address owner;
        uint16[] numbers;
        bool claimed;
        uint256 lotteryId;
    }
    // Token ID => Token information
    mapping(uint256 => TicketInfo) internal ticketInfo_;
    // lottery ID => tickets count
    mapping(uint256 => uint256) internal ticketsCount_;
    // User address => Lottery ID => Ticket IDs
    mapping(address => mapping(uint256 => uint256[])) internal userTickets_;

    // These stated is fixed due to technical implementation
    // Lottery size, power number not included
    uint8 public constant sizeOfLottery_ = 3;
    //  if require 3 numbers match, use value of 2^3 - 1
     uint8 public constant sizeOfIndex_ = 8;
    // lotteryId => hash => count
    // the hash is combined from ticked numbers
    mapping(uint256 => mapping(uint256 => uint256)) internal ticketHashes_;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event InfoBatchMint(address indexed receiving, uint256 lotteryId, uint256 amountOfTokens, uint256[] tokenIds);

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------

    /**
     * @notice  Restricts minting of new tokens to only the lotto contract.
     */
    modifier onlyLotto() {
        require(msg.sender == lotteryContract_, "Only Lotto can mint");
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    constructor() {}

    function initialize(address _lotto) external initializer onlyOwner {
        lotteryContract_ = _lotto;
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getTotalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @param   _ticketID: The unique ID of the ticket
     * @return  uint32[]: The chosen numbers for that ticket
     */
    function getTicketNumbers(uint256 _ticketID) external view returns (uint16[] memory) {
        return ticketInfo_[_ticketID].numbers;
    }

    /**
     * @param   _ticketID: The unique ID of the ticket
     * @return  address: Owner of ticket
     */
    function getOwnerOfTicket(uint256 _ticketID) external view returns (address) {
        return ticketInfo_[_ticketID].owner;
    }

    function getTicketInfo(uint256 _ticketID) external view returns (TicketInfo memory) {
        return ticketInfo_[_ticketID];
    }

    function getTicketClaimStatus(uint256 _ticketID) external view returns (bool) {
        return ticketInfo_[_ticketID].claimed;
    }

    function getTicketClaimStatuses(uint256[] calldata ticketIds)
    external
    view
    returns (bool[] memory ticketStatuses)
    {
        ticketStatuses = new bool[](ticketIds.length);
        for (uint256 i = 0; i < ticketIds.length; i++) {
            ticketStatuses[i] = ticketInfo_[ticketIds[i]].claimed;
        }
    }

    function getUserTickets(uint256 _lotteryId, address _user) external view returns (uint256[] memory) {
        return userTickets_[_user][_lotteryId];
    }

    function getListTicketNumbers(uint256[] calldata ticketIds)
    external
    view
    returns (uint256[] memory ticketNumbers)
    {
        ticketNumbers = new uint256[](ticketIds.length * sizeOfLottery_);
        for (uint256 i = 0; i < ticketIds.length; i++) {
            uint16[] memory ticketNumber = ticketInfo_[ticketIds[i]].numbers;
            for (uint256 j = 0; j < ticketNumber.length; j++) {
                ticketNumbers[sizeOfLottery_ * i + j] = ticketNumber[j];
            }
        }
    }

    function getNumberOfTickets(uint256 _lotteryId) external view returns (uint256) {
        return ticketsCount_[_lotteryId];
    }

    function getUserTicketsPagination(
        address _user,
        uint256 _lotteryId,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > userTickets_[_user][_lotteryId].length - cursor) {
            length = userTickets_[_user][_lotteryId].length - cursor;
        }
        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = userTickets_[_user][_lotteryId][cursor + i];
        }
        return (values, cursor + length);
    }

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    /**
     * @param   _to The address being minted to
     * @param   _numberOfTickets The number of NFT's to mint
     * @notice  Only the lotto contract is able to mint tokens.
        // uint8[][] calldata _lottoNumbers
     */
    function batchMint(
        address _to,
        uint256 _lotteryId,
        uint8 _numberOfTickets,
        uint16[] calldata _numbers
    ) external onlyLotto() returns (uint256[] memory) {
        // Storage for the amount of tokens to mint (always 1)
        uint256[] memory amounts = new uint256[](_numberOfTickets);
        // Storage for the token IDs
        uint256[] memory tokenIds = new uint256[](_numberOfTickets);
        for (uint8 i = 0; i < _numberOfTickets; i++) {
            // Incrementing the tokenId counter
            totalSupply_ = totalSupply_ + 1;
            tokenIds[i] = totalSupply_;
            amounts[i] = 1;
            // Getting the start and end position of numbers for this ticket
            uint16 start = uint16(i * sizeOfLottery_);
            uint16 end = uint16((i + 1) * sizeOfLottery_);
            // Splitting out the chosen numbers
            uint16[] calldata numbers = _numbers[start:end];
            // Storing the ticket information
            ticketInfo_[totalSupply_] = TicketInfo(_to, numbers, false, _lotteryId);
            userTickets_[_to][_lotteryId].push(totalSupply_);
            indexTicket(_lotteryId, numbers);
        }
        ticketsCount_[_lotteryId] = ticketsCount_[_lotteryId] + _numberOfTickets;
        // Emitting relevant info
        emit InfoBatchMint(_to, _lotteryId, _numberOfTickets, tokenIds);
        // Returns the token IDs of minted tokens
        return tokenIds;
    }

    function indexTicket(
        uint256 _lotteryId,
        uint16[] memory _numbers
    ) internal {
        uint256[sizeOfIndex_] memory indexes = generateNumberIndexKey(_numbers);
        for (uint256 j = 0; j < indexes.length; j++) {
            ticketHashes_[_lotteryId][indexes[j]]++;
        }
    }

    function claimTicket(uint256 _ticketID, uint256 _lotteryId) external onlyLotto() returns (bool) {
        require(ticketInfo_[_ticketID].claimed == false, "Ticket already claimed");
        require(ticketInfo_[_ticketID].lotteryId == _lotteryId, "Ticket not for this lottery");
        uint256 maxRange = ILottery(lotteryContract_).getMaxRange();
        for (uint256 i = 0; i < ticketInfo_[_ticketID].numbers.length; i++) {
            if (ticketInfo_[_ticketID].numbers[i] > maxRange) {
                return false;
            }
        }

        ticketInfo_[_ticketID].claimed = true;
        return true;
    }

    function setLottery(address _lottery) external onlyOwner {
        require(_lottery != address(0), "Invalid address");
        lotteryContract_ = _lottery;
    }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    /**
     * calculate the index for matching
     */
    function generateNumberIndexKey(uint16[] memory numbers) public pure returns (uint256[sizeOfIndex_] memory result) {
        uint256 len = numbers.length;
        for (uint256 val = 0; val < sizeOfIndex_; val++) {
            uint256 cnt = 0;
            for (uint256 index = 0; index < len; index++) {
                uint256 value = 1 << (len - index -1);
                if ((val & value) != 0) {
                   cnt++;
                }
            }
            for (uint256 index = 0; index < len; index++) {
                uint256 value = 1 << (len - index -1);
                if ((val & value) != 0) {
                    result[val] = result[val]  + numbers[index] * (256 ** (cnt - 1));
                    cnt--;
                }
            }
        }
    }

    function countMatch(
        uint256 _lotteryId,
        uint16[] calldata _winningNumbers
    ) external view returns (uint256[] memory results) {
        results = new uint256[](sizeOfLottery_);
        uint256[sizeOfIndex_] memory keys = generateNumberIndexKey(_winningNumbers);
        results[0] = ticketHashes_[_lotteryId][keys[sizeOfIndex_ - 1]];
        // We hardcoded here to reduce the unnecessary computation
        results[1] = ticketHashes_[_lotteryId][keys[3]] + ticketHashes_[_lotteryId][keys[5]] + ticketHashes_[_lotteryId][keys[6]]  - 3 * results[0];
        results[2] = ticketHashes_[_lotteryId][keys[1]] + ticketHashes_[_lotteryId][keys[2]] + ticketHashes_[_lotteryId][keys[4]] -  3 * results[0] - 2 * results[1];
    }
}