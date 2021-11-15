// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Splitter child contract for splitting ether
/// @author The Systango Team

import "./Splitter.sol";

contract Factory {

    // The array of contracts produced by this factory contract.
    address[] public contracts;

    // Event to trigger the creation of new Child contract address.
    event SplitterCreated(address indexed contractAddress);

    // Returns the length of all the contracts deployed through this factory contract.
    function getContractCount() public view returns (uint256) {
        return contracts.length;
    }

    // This function is called when a new child contract has to be created.

    /// @param owner The owner of the new child contract which will be created. 
    /// @param payeeAddresses The address array of the new contract in which the funds 
    /// will be splitted.
    /// @param payeeShare The precentage array of the respective ethereum addresses
    /// provided for the funds to get splitted.

    function registerContract(
        address owner,
        address payable[] memory payeeAddresses,
        uint256[] memory payeeShare
    ) public {
        Splitter splitter = new Splitter(false, payeeAddresses, payeeShare);
        contracts.push(address(splitter));
        splitter.transferOwnership(owner);
        emit SplitterCreated(address(splitter));
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Splitter child contract for splitting ether
/// @author The Systango Team

import "./SafeMath.sol";
import "./Killable.sol";

contract Splitter is Killable {

    // The struct of ethereum addresses and its respective share provided at the time 
    // of contract genertaion in which the funds will be spiltted.
    struct Payee {
        address payable payeeAddress;
        uint256 share;
    }

    Payee[] public payees;

    // Event to trigger the receiving of ether amount.
    event ReceivedEth(address indexed fromAddress, uint256 amount);

    // Event to trigger the split of ether amount successfully.
    event SplittedEth(uint256 amount, Payee[] payees);

    using SafeMath for uint256;

    // This is the constructor of the contract. It is called at deploy time.
    
    /// @param _paused The pause status of teh child contract  
    /// @param payeeAddresses The address array of the new contract in which the funds 
    /// will be splitted.
    /// @param payeeShare The precentage array of the respective ethereum addresses
    /// provided for the funds to get splitted.

    constructor(
        bool _paused,
        address payable[] memory payeeAddresses,
        uint256[] memory payeeShare
    ) Pausable(_paused) {
        sanityCheck(payeeAddresses, payeeShare);
        for (uint256 i = 0; i < payeeAddresses.length; i++) {
            Payee memory payee = Payee(payeeAddresses[i], payeeShare[i]);
            payees.push(payee);
        }
    }

    // This function is the intermediate function to implement a few checks over the 
    // constructor of the contract when it is called.

    /// @param payeeAddresses The address array of the new contract in which the funds 
    /// will be splitted.
    /// @param payeeShares The precentage array of the respective ethereum addresses
    /// provided for the funds to get splitted.

    function sanityCheck(
        address payable[] memory payeeAddresses,
        uint256[] memory payeeShares
    ) internal pure {
        uint256 length = payeeAddresses.length;
        require(
            length == payeeShares.length,
            "Mismatch between payees and share arrays"
        );

        uint256 shareSum;
        for (uint256 i; i < payeeShares.length; i++) {
            shareSum += payeeShares[i];
        }
        require(shareSum <= 100, "The sum of payee share cannot exceed 100%");
    }

    // This function will be run when a transaction is sent to the contract
    // without any data and call the split method to split the fund in the percentage 
    // ratio as provided at the time of creation of the contract.

    receive() external payable whenRunning whenAlive {
        emit ReceivedEth(msg.sender, msg.value);
        require(msg.value > 0, "Fund value 0 is not allowed");
        split(msg.value);
    }

    // This function would split the ethers in the perccentage ratio as provided at the time 
    // of creation of the contract.

    /// @param amount The ether amount which will be splitted.

    function split(uint256 amount) internal {
        for (uint256 i = 0; i < payees.length; i++) {
            address payable payee = payees[i].payeeAddress;
            payee.transfer(amount.div(100).mul(payees[i].share)); // transfer percentage share
        }
        emit SplittedEth(amount, payees);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Pausable is Ownable {
    bool private _paused;
    event LogPaused(address indexed account);
    event LogResumed(address indexed account);

    constructor (bool paused) {
        _paused = paused;
    }

    function isPaused() public view returns (bool) {
        return _paused;
    }

    function pause() public onlyOwner whenRunning  {
        _paused = true;
        emit LogPaused(msg.sender);
    }

    function resume() public onlyOwner whenPaused {
        _paused = false;
        emit LogResumed(msg.sender);
    }

    modifier whenRunning () {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract not paused");
        _;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;
    event LogTransferredOwnership(address indexed oldOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Contract need an owner");
        require(newOwner != _owner, "Same owner");
        address oldOwner = _owner;
        _owner = newOwner;
        emit LogTransferredOwnership(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Pausable.sol";

abstract contract Killable is Pausable {
    bool private _killed;
    event LogKilled(address indexed account);

    constructor () {
        _killed = false;
    }

    function isKilled() public view returns (bool) {
        return _killed;
    }

    function kill() public onlyOwner whenPaused whenAlive {
        _killed = true;
        emit LogKilled(msg.sender);
    }

    modifier whenAlive() {
        require(!_killed, "Contract is dead");
        _;
    }

    modifier whenDead() {
        require(_killed, "Contract is alive");
        _;
    }
}

