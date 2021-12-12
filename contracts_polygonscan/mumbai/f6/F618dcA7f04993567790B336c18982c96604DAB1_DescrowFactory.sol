//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Descrow.sol";

contract DescrowFactory {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Descrow[] public descrows;
    Counters.Counter private _contractIds;

    mapping(address => Descrow[]) public partyToContractMapping;
    mapping(address => uint ) public contractToIndexMapping;

    event ContractCreated(address indexed buyer, 
                          address indexed seller, 
                          uint price,
                          address contractAddress);

    function createContract(address payable _buyer, 
                            address payable _seller, 
                            uint _price) public {
        
        // Create a new Descrow contract
        Descrow descrow = new Descrow(_buyer, _seller, _price);

        // Store contract in an array
        descrows.push(descrow);

        // Map contract to particular index
        uint currIdx = _contractIds.current();
        address conAddr = descrow.contractAddress();
        contractToIndexMapping[conAddr] = currIdx; 
        _contractIds.increment();

        // Map contract to both parties involved
        partyToContractMapping[_buyer].push(descrow);
        partyToContractMapping[_seller].push(descrow);

        // Emit new contract creation event
        emit ContractCreated(_buyer, _seller, _price, conAddr);
    }

    // Return all contracts that a party is participating in
    function getContractsByParty(address _party) public view returns (Descrow[] memory) {
        return partyToContractMapping[_party];
    }

    // Return contract at a particular index
    function getContractByIndex(uint _index) public view returns (Descrow) {
        return descrows[_index];
    }

    // Return contract by its address
    function getContractByAddress(address _addr) public view returns (Descrow) {
        uint idx = contractToIndexMapping[_addr];
        return descrows[idx]; 
    }

    // Return all contracts
    function getAllContracts() public view returns (Descrow[] memory) {
        return descrows;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Descrow {
    using SafeMath for uint256;

    // Cannot be modified after contract creation.
    address payable private _buyer;
    address payable private _seller;
    uint private _salePrice;
    mapping(address => uint) private _stakeAmount;

    // Contract state variables
    mapping(address => bool) private _stakeStatus;
    mapping(address => bool) private _cancelStatus;
    bool private _isActive;
    bool private _isCancelled;

    // Contract address
    address public contractAddress;

    // Get contract status at a glance
    struct ContractStatus {
        address buyer;
        address seller;
        uint salePrice;
        bool buyerStake;
        bool sellerStake;
        bool buyerCancel;
        bool sellerCancel;
        bool active;
        bool cancelled;
        address conAddr;
    }

    // Event to detect change in contract state
    event ContractStateChanged(
        address indexed buyer,
        address indexed seller,
        ContractStatus state
    );

    
    // Set buyer, seller, and price during contract creation
    constructor(address payable _buyerParty, address payable _sellerParty, uint _price) {

        // Buyer and seller can't be the same
        require(_buyerParty != _sellerParty, "Buyer and seller can't be the same");

        // Set participating parties and agreed price
        _buyer = _buyerParty;
        _seller = _sellerParty;
        _salePrice = _price;

        // Set stake amounts
        _stakeAmount[_buyer] = _salePrice.mul(2);
        _stakeAmount[_seller] = _salePrice;

        // Set contract state to active
        _isActive = true;

        // Store contract address
        contractAddress = address(this);
    } 

    modifier onlyParties() {
        require(msg.sender == _buyer || msg.sender == _seller, 
                "Function can only be invoked by participating parties.");
        
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == _buyer, "Function can only be invoked by the buyer");

        _;
    }

    modifier onlyActive() {
        require(_isActive, "Contract is not active");

        _;
    }

    modifier contractLocked(bool _status) {
        bool contractLockStatus = _stakeStatus[_buyer] && _stakeStatus[_seller];
        require(contractLockStatus == _status, "Contract status does not permit this action.");
        _;
    }

    function stake() public payable onlyParties onlyActive contractLocked(false) {

        // Reject staking if already done before
        require(!_stakeStatus[msg.sender], "Party has already staked the correct amount.");

        // Check if correct amount was sent
        require(msg.value == _stakeAmount[msg.sender], "Incorrect staking amount sent.");
        
        // Set stake status of invoking party to true
        _stakeStatus[msg.sender] = true;

        // Emit state change event
        emit ContractStateChanged(_buyer, _seller, getStatus());
    }

    // Allow parties to withdraw amount if contract has not been locked yet
    function revokeStake() public payable onlyParties onlyActive contractLocked(false) {
        uint balance = address(this).balance;

        // Check if party has actually staked
        require(_stakeStatus[msg.sender], "Party does not have any amount staked.");

        // Check if contract has enough ether left to withdraw
        require(balance >= _stakeAmount[msg.sender], "Not enough ether left to withdraw.");

        // Attempt a transfer
        (bool success, ) = (msg.sender).call{value: _stakeAmount[msg.sender]}("");
        require(success, "Transfer failed.");

        // Set staking status of party to false
        _stakeStatus[msg.sender] = false;

        // Emit state change event
        emit ContractStateChanged(_buyer, _seller, getStatus());
    }

    // Allow parties to invoke cancellation if contract has been locked
    function cancel() public payable onlyParties onlyActive contractLocked(true) {
        
        // Check if party had already cancelled before
        require(!_cancelStatus[msg.sender], "Party has already issued a cancellation request.");

        // Set cancellation status of party to true
        _cancelStatus[msg.sender] = true;

        // Check if both parties have cancelled. If yes, refund amounts and set staking to false
        if (_cancelStatus[_buyer] && _cancelStatus[_seller]) {

            // Simple sanity check to see if balance exists
            require(address(this).balance >= _salePrice.mul(3), "Not enough ether left to give out.");

            (bool buyerRefunded, ) = (_buyer).call{value: _stakeAmount[_buyer]}("");
            (bool sellerRefunded, ) = (_seller).call{value: _stakeAmount[_seller]}("");
            require(buyerRefunded && sellerRefunded, "Transfer has failed");

            // Reset stake, cancel, and confirmation status
            address payable[2] memory parties = [_buyer, _seller];

            for (uint i = 0; i < parties.length; i++) {
                _cancelStatus[parties[i]] = false;
                _stakeStatus[parties[i]] = false;
            }

            // Set contract to inactive and cancelled
            _isActive = false;
            _isCancelled = true;
        }

        // Emit state change event
        emit ContractStateChanged(_buyer, _seller, getStatus());
    }

    // Revoke cancellation if possible
    function revokeCancellation() public onlyParties onlyActive contractLocked(true) {

        require(_cancelStatus[msg.sender], "Party doesn't have a cancellation request to revoke");
        _cancelStatus[msg.sender] = false;

        // Emit state change event
        emit ContractStateChanged(_buyer, _seller, getStatus());
    }

    // Confirm that the seller has honored the contract
    function confirm() public payable onlyBuyer onlyActive contractLocked(true) {

        // Require that no party has requested cancellation
        require(!_cancelStatus[_buyer] && !_cancelStatus[_seller], 
                "Cannot confirm as at least one party has requested cancellation.");

        // Simple sanity check to see if balance exists
        require(address(this).balance >= _salePrice.mul(3), "Not enough ether left to give out.");

        // Swap stake amounts
        (bool buyerRefunded, ) = (_buyer).call{value: _stakeAmount[_seller]}("");
        (bool sellerRefunded, ) = (_seller).call{value: _stakeAmount[_buyer]}("");
        require(buyerRefunded && sellerRefunded, "Transfer has failed");

        // Reset stake status
        _stakeStatus[_buyer] = false;
        _stakeStatus[_seller] = false;

        // Set contract to inactive
        _isActive = false;

        // Emit state change event
        emit ContractStateChanged(_buyer, _seller, getStatus());
    }

    // Get current status of contract
    function getStatus() public view returns (ContractStatus memory) {
        return ContractStatus(
            _buyer,
            _seller,
            _salePrice,
            _stakeStatus[_buyer],
            _stakeStatus[_seller],
            _cancelStatus[_buyer],
            _cancelStatus[_seller],
            _isActive,
            _isCancelled,
            contractAddress
        );
    }
}