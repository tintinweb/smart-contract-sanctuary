pragma solidity ^0.6.9;

import "./BetToken/BetTokenHolder.sol";
import "./BetToken/BetTokenRecipient.sol";
import "./BetToken/BetTokenSender.sol";

abstract contract BetToken is BetTokenHolder, BetTokenSender, BetTokenRecipient {
    constructor (
        address tokenAddress
    ) public BetTokenHolder(tokenAddress) {}
}

pragma solidity ^0.6.9;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";

contract BetTokenHolder {
    IERC777 token;

    constructor (address tokenAddress) public {
        token = IERC777(tokenAddress);
    }

    modifier isRightToken () {
        require(msg.sender == address(token), "Not a valid token");
        _;
    }
}

pragma solidity ^0.6.9;

import "./BetTokenHolder.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";


abstract contract BetTokenRecipient is BetTokenHolder, IERC777Recipient {
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    constructor () public {
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override isRightToken {
        bet(from, amount, userData);
    }

    function bet (address from, uint amount, bytes memory betData) internal virtual {}
}

pragma solidity ^0.6.9;

import "./BetTokenHolder.sol";

import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/introspection/ERC1820Implementer.sol";

abstract contract BetTokenSender is BetTokenHolder, IERC777Sender, ERC1820Implementer {
    bytes32 constant public TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");

    constructor () public {
        _registerInterfaceForAddress(TOKENS_SENDER_INTERFACE_HASH, address(this));
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override isRightToken {}

    function send (address to, uint amount) internal {
        token.send(to, amount, "");
    }
}

pragma solidity ^0.6.9;

import "./BetToken.sol";
import "./Logic/BetBettingLogic.sol";

contract Deathbet is BetBettingLogic, BetToken {
    constructor (
        address tokenAddress,
        uint _ticketPrice
    ) public
        BetToken(tokenAddress)
        BetBettingLogic(_ticketPrice)
    {}

    // Implements "./BetToken/BetTokenSender.sol"
    function bet (address better, uint amountSent, bytes memory betData) internal override {
    // Routs to "./Logic/BetBettingLogic"
        _bet(better, amountSent, betData);
    }
}

pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import "./BetDataStructure.sol";

import "../../../imty-token/contracts/Statistics.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BetWinner.sol";
import "../BetToken/BetTokenSender.sol";

abstract contract BetBettingLogic is ReentrancyGuard, BetDataStructure, Ownable, BetWinner, BetTokenSender {
    SignableStatistics public stats;

    uint public ticketPrice;

    constructor (uint _ticketPrice) public {
        ticketPrice = _ticketPrice;
    }

    function setTicketPrice (uint _ticketPrice) public onlyOwner {
        ticketPrice = _ticketPrice;
    }

    function changeClaimPercentage (uint _claimPercentage) public onlyOwner {
        claimPercentage = _claimPercentage;
    }

    event AddedBet (uint weekId, address better, uint ticketPrice, uint32 deaths, uint32 infections, uint betId);
    event WeekConcluded (uint weekId, uint32 deaths, uint32 infections, address winner, uint32 winningDeaths, uint32 winningInfections, uint winningBetId);

    function _bet (address better, uint amountSent, bytes memory betData) internal _allowedToBet nonReentrant {
        require(amountSent == ticketPrice);
        (uint32 deaths, uint32 infections) = abi.decode(betData, (uint32, uint32));

        BetWeek storage betWeek = betWeeks[getWeek()];

        betWeek.betters.push(better);
        betWeek.deaths.push(deaths);
        betWeek.infections.push(infections);
        betWeek.total += ticketPrice;

        emit AddedBet(getWeek(), better, amountSent, deaths, infections, (betWeek.infections.length - 1));
    }

    function concludeWeek (uint weekId, uint32 deaths, uint32 infections, uint winnerIndex) public onlyOwner {
        require(weekId < getWeek(), "Still in week");
        BetWeek storage week = betWeeks[weekId];
        require(week.concluded == false, "Week already concluded");

        week.finalDeaths = deaths;
        week.finalInfections = infections;
        week.concluded = true;

        address winnerAddress = week.betters[winnerIndex];
        uint32 winningDeaths = week.deaths[winnerIndex];
        uint32 winningInfections = week.infections[winnerIndex];

        send(winnerAddress, (week.total / 100) * (100 - claimPercentage));
        send(owner(), (week.total / 100) * claimPercentage);

        emit WeekConcluded (weekId, deaths, infections, winnerAddress, winningDeaths, winningInfections, winnerIndex);

        week.concluded = true;
    }

    modifier _allowedToBet () {
        require(allowedToBet(), "Betting is not open today");
        _;
    }

    uint8 closeDay = 4;
    uint8 startDay = 10;

    function setCloseDay (uint8 _closeDay) onlyOwner public {
        closeDay = _closeDay;
    }

    function setStartDay (uint8 _startDay) onlyOwner public {
        startDay = _startDay;
    }

    function allowedToBet () public view returns (bool) {
        uint8 currentDay = getDay();
        // uint currentWeek = getWeek();
        if (startDay == 10) {
            return currentDay < closeDay;
        } else {
            return currentDay > startDay && currentDay < closeDay;
        }
    }

    function getDay () public view returns (uint8 _day) {
        _day = uint8((block.timestamp / 1 days) % 7);
    }

    function getWeek () public view returns (uint _week) {
        _week = block.timestamp / 1 weeks;       
    }
}

pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

contract BetDataStructure {
    uint public claimPercentage = 20;

    struct BetWeek {
        uint total;
        bool concluded;
        address[] betters;
        uint32[] deaths;
        uint32[] infections;
        uint32 finalDeaths;
        uint32 finalInfections;
    }

    mapping(uint => BetWeek) public betWeeks;

    function getBetWeek (uint _weekId) public view returns (
        uint total,
        bool concluded,
        address[] memory betters,
        uint32[] memory deaths,
        uint32[] memory infections,
        uint32 finalDeaths,
        uint32 finalInfections

    ) {
        BetWeek memory betWeek = betWeeks[_weekId];

        total = betWeek.total;
        concluded = betWeek.concluded;
        betters = betWeek.betters;
        deaths = betWeek.deaths;
        infections = betWeek.infections;
        finalDeaths = betWeek.finalDeaths;
        finalInfections = betWeek.finalInfections;
    }
}

pragma solidity ^0.6.9;

import "./BetDataStructure.sol";




contract BetWinner is BetDataStructure {
}

library UIntArrayUtils {
    function merge (uint32[] memory a, uint32[] memory b)
        internal
        pure
        returns (uint32[] memory)
    {
        uint32[] memory res = new uint32[](a.length);
        for (uint32 i = 0; i < a.length; i++) {
            res[i] = a[i] + b[i];
        }
        return res;
    }

    function reduce (uint[] memory a, function(uint, uint) pure returns (uint) f)
        internal
        pure
        returns (uint)
    {
        uint r = a[0];
        for (uint i = 1; i < a.length; i++) {
            r = f(r, a[i]);
        }
        return r;
    }
}

//Write your own contracts here. Currently compiles using solc v0.4.15+commit.bbb8e64f.
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StatisticsDataStructure {
    uint public lastFilledWeek;
    uint public startWeek;

    mapping (uint => Datapoint) weeklyData;
    struct Datapoint {
        uint deaths;
        uint infections;
        bool filled;
    }
    event WeeklyData (uint deaths, uint infections, uint weekId);

    constructor (uint deaths, uint infections) public {
        lastFilledWeek = block.timestamp / 1 weeks;
        startWeek = block.timestamp / 1 weeks;

        pushWeeklyData(getCurrentWeek(), deaths, infections);
    }

    function pushWeeklyData (uint weekId, uint deaths, uint infections) internal {
        Datapoint storage target = weeklyData[weekId];

        require(target.filled == false, "target week is already filled");
        
        target.deaths = deaths;
        target.infections = infections;
        target.filled = true;

        lastFilledWeek = weekId;

        emit WeeklyData(deaths, infections, weekId);
    }

    function getCurrentWeek () public view returns (uint) {
        return block.timestamp / 1 weeks;
    }

    function getNextWeek () public view returns (uint) {
        return lastFilledWeek + 1;
    }

    function getWeeklyData (uint weekId) verifyWeekId(weekId) public view returns (uint deaths, uint infections) {
        require(weeklyData[weekId].filled == true, "No data for selected week");
        return (weeklyData[weekId].deaths, weeklyData[weekId].infections);
    }

    modifier verifyWeekId (uint weekId) {
        require(weekId >= startWeek, "No data recorded for given weekId");
        require(weekId <= getCurrentWeek(), "weekId bigger than recorded weeklyData");
        _;
    }
}

contract SignableStatistics is StatisticsDataStructure {
    address signerOne;
    address signerTwo;

    bool public signerOneApproval;
    bool public signerTwoApproval;

    uint public proposedDeaths;
    uint public proposedInfections;
    uint public proposedWeek;


    function resetApproval () private {
        signerOneApproval = false;
        signerTwoApproval = false;
    }

    constructor (
        address _signerOne,
        address _signerTwo,
        uint thisWeeksDeaths,
        uint thisWeeksInfections
    ) StatisticsDataStructure(
        thisWeeksDeaths,
        thisWeeksInfections
    ) public {
        signerOne = _signerOne;
        signerTwo = _signerTwo;
    }

    function pushProposal () public isApproved {
        pushWeeklyData(proposedWeek, proposedDeaths, proposedInfections);
        _clearProposal();
    }

    function propose (uint _proposedDeaths, uint _proposedInfections) isSigner public {
        uint nextWeek = getNextWeek();

        require(lastFilledWeek < nextWeek, "Data for this week has already been recorded");
        require(getCurrentWeek() >= nextWeek, "Suggested data is for a date later than the current date");

        resetApproval();

        proposedDeaths = _proposedDeaths;
        proposedInfections = _proposedInfections;
        proposedWeek = nextWeek;
    }

    function clearProposal () isSigner public {
        _clearProposal();
    }
    function _clearProposal () isSigner private {
        proposedDeaths = 0;
        proposedInfections = 0;
        proposedWeek = 0;
        signerOneApproval = false;
        signerTwoApproval = false;
    }

    function approve () public {
        bool success;

        if (msg.sender == signerOne) {
            success = true;
            signerOneApproval = true;
        }
        if (msg.sender == signerTwo) {
           success = true;
           signerTwoApproval = true;
        }

        require(success, 'Not authorized');
    }

    modifier isApproved () {
        bool success;

        if (signerOneApproval == true && signerTwoApproval == true) {
            success = true;
        }
        require(success, "Not everybody has approved the proposed values");
        _;
    }

    modifier isSigner () {
        bool isIndeedSigner;
        if (msg.sender == signerOne || msg.sender == signerTwo) {
            isIndeedSigner = true;
        }
        require(isIndeedSigner, "");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.6.0;

import "./IERC1820Implementer.sol";

/**
 * @dev Implementation of the {IERC1820Implementer} interface.
 *
 * Contracts may inherit from this and call {_registerInterfaceForAddress} to
 * declare their willingness to be implementers.
 * {IERC1820Registry-setInterfaceImplementer} should then be called for the
 * registration to be complete.
 */
contract ERC1820Implementer is IERC1820Implementer {
    bytes32 constant private _ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

    mapping(bytes32 => mapping(address => bool)) private _supportedInterfaces;

    /**
     * See {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) public view override returns (bytes32) {
        return _supportedInterfaces[interfaceHash][account] ? _ERC1820_ACCEPT_MAGIC : bytes32(0x00);
    }

    /**
     * @dev Declares the contract as willing to be an implementer of
     * `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer} and
     * {IERC1820Registry-interfaceHash}.
     */
    function _registerInterfaceForAddress(bytes32 interfaceHash, address account) internal virtual {
        _supportedInterfaces[interfaceHash][account] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface for an ERC1820 implementer, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820#interface-implementation-erc1820implementerinterface[EIP].
 * Used by contracts that will be registered as implementers in the
 * {IERC1820Registry}.
 */
interface IERC1820Implementer {
    /**
     * @dev Returns a special value (`ERC1820_ACCEPT_MAGIC`) if this contract
     * implements `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  {updateERC165Cache} with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 *  their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Sender {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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

