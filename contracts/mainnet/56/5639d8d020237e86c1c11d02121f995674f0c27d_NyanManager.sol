/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: browser/NyanManager.sol

pragma solidity ^0.6.7;


contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract LibraryLockDataLayout {
  bool public initialized = false;
}

contract LibraryLock is LibraryLockDataLayout {
    // Ensures no one can manipulate the Logic Contract once it is deployed.
    // PARITY WALLET HACK PREVENTION

    modifier delegatedOnly() {
        require(initialized == true, "The library is locked. No direct 'call' is allowed");
        _;
    }
    function initialize() internal {
        initialized = true;
    }
}

contract ManagerDataLayout is LibraryLock {
    address public owner;
    address public nyanVoting;
    address[] public managers;
    struct eachManager {
        uint256 allowance;
        uint256 totalAllowanceReturned;
        uint256 profits;
        uint32 ROI;
        uint256 lastCheckInBlock;
        bool isManager;
        address[] usedContracts;
        string name;
        uint256[] profitHistory;
        uint256[] holdingsHistory;
        uint256 collateral;
    }
    mapping(address => eachManager) public managerStruct;
    
    uint256 public initialAllowance;
    uint256 public nextVotingPeriod;
    uint256 public votingBuffer;
    bool public canBeginVoting;
    
    
    struct eachCandidate {
        uint256 votes;
        uint256 lastVotingBlock;
        string name;
    }
    mapping(address => eachCandidate) public managerCandidates;
    address public topCandidate;
    uint256 public topCandidateVotes;
    address[] public allCandidates;
    bool public isSelfManager;
    uint32 public managerLimit;
    
    using SafeMath for uint32;
    using SafeMath for uint256;
    
    address public fundContract = 0x2c9728ad35C1CfB16E3C1B5045bC9BA30F37FAc5;
    address public connectorContract = 0x60d70dF1c783b1E5489721c443465684e2756555;
    address public rewardsContract = 0x868f7622F57b62330Db8b282044d7EAf067fAcfe;
    address public devFund = 0xd66A9D2B706e225204F475c9e70A4c09eEa62199;
    address public registry = 0x66BFd3ed6618D9C62DcF1eF706D9Aacd5FdBCCD6;
    address public contractManager;
    address public selfManager;
}

interface usedContract {
    function liquidateHoldings(address _manager) external returns(bool);
    function sendETH(address _manager) external payable;
    function isSelfManager(address _manager) external view returns(bool);
}

contract connector {
    function fundLog(address manager, string calldata reason, address recipient) public payable {}
}

contract NyanManager is Proxiable, ManagerDataLayout {
    
    modifier _onlyOwner() {
      require(msg.sender == owner);
      _;
    }
    
    constructor() public {
        
    }
    
    function initConstructor(uint32 _managerLimit, uint256 _votingBuffer, uint256 _initialAllowance) public {
        require(!initialized);
        owner = msg.sender;
        managerLimit = _managerLimit;
        votingBuffer = _votingBuffer;
        initialAllowance = _initialAllowance;
        nextVotingPeriod = block.number;
        initialize();
    }
    
    function updateCode(address newCode) public delegatedOnly  {
        if (owner == address(0)) {
            require(msg.sender == contractManager);
        } else {
            require(msg.sender == owner);
        }
        updateCodeAddress(newCode);
    }
    
    function relinquishOwnership()public _onlyOwner delegatedOnly {
        owner = address(0);
    } 
    
    function setContracts(address _contractManager, address _selfManager) public _onlyOwner delegatedOnly {
        contractManager = _contractManager;
        selfManager = _selfManager;
    }
    
    function registerCandidate(string memory name) public payable delegatedOnly {
        require(!usedContract(selfManager).isSelfManager(msg.sender), "This address is self managing");
        if (managers.length == managerLimit) {
            require(block.number > nextVotingPeriod, "Voting period has not started");
        }
        require(msg.value >= .05 ether);
        bool isCandidate;
        for(uint32 i; i < allCandidates.length; i++) {
            if (allCandidates[i] == msg.sender) {
                isCandidate = true;
            }
        }
        if (!isCandidate) {
            managerCandidates[msg.sender].name = name;
            managerCandidates[msg.sender].votes = msg.value;
            allCandidates.push(msg.sender);
        }
        connector(connectorContract).fundLog(msg.sender, "manager application", fundContract);
        rewardsContract.call{value: msg.value.div(2).sub(5)}("");
    }
    
    
    function setManagerLimit(uint32 limit) public _onlyOwner delegatedOnly {
        managerLimit = limit;
    }
    
    function replaceManager(address newManager, uint256 index) public payable delegatedOnly {
        require(canBeginVoting);
        require(block.number > nextVotingPeriod, "Voting period has not started");
        if (managerLimit == managers.length) {
            require(block.number < nextVotingPeriod.add(votingBuffer), "Voting period has ended");
        } else {
            require(block.number < nextVotingPeriod.add(13000), "Voting period has ended");
        }
        
        require(allCandidates[index] == newManager);
        if (managerCandidates[newManager].lastVotingBlock < nextVotingPeriod) {
            managerCandidates[newManager].votes = 0;
        }
        managerCandidates[newManager].votes = managerCandidates[newManager].votes.add(msg.value);
        //if candidate total votes are higher than topCandidate,
        //candidate is the new top candidate
        if (managerCandidates[newManager].votes > topCandidateVotes) {
            topCandidate = newManager;
        }
        managerCandidates[newManager].lastVotingBlock = block.number;
        connector(connectorContract).fundLog(newManager, "manager vote", fundContract);
        rewardsContract.call{value: msg.value.div(2).sub(5)}("");
    }
    
    function finalizeNewManager() public delegatedOnly {
        if (managers.length == managerLimit) {
            require(block.number > nextVotingPeriod.add(votingBuffer), "Voting period has not entered finalize period");
        }
        require(topCandidate != address(0));
        address[] memory emptyArr;
        
        if (managerLimit == managers.length) {
            //remove lowest profiting manager from array and reset struct
            address lowestManager = managers[0];
            uint256 lowestManagerProfits = managerStruct[managers[0]].profits;
            uint index;
            for(uint32 i; i < managers.length; i++) {
                if (managerStruct[managers[i]].profits < lowestManagerProfits) {
                    address lowestManager = managers[i];
                    uint256 lowestManagerProfits = managerStruct[managers[i]].profits;
                    index = i;
                }
            }
            //remove manager from array
            removeManager(index);
            //liquidate old manager
            liquidateOldManager(lowestManager);
            //reset lowestManager
            managerStruct[lowestManager].allowance = 0;
            managerStruct[lowestManager].lastCheckInBlock = block.number;
            managerStruct[lowestManager].isManager = false;
            managerStruct[lowestManager].collateral = 0;
            managerStruct[lowestManager].usedContracts = emptyArr;
            //add topCandidate to array and set up struct
        }
        
        managers.push(topCandidate);
        managerStruct[topCandidate].isManager = true;
        //reset topCandidate
        topCandidate = address(0);
        topCandidateVotes = 0;
        
        if (managerLimit > managers.length) {
            nextVotingPeriod = block.number.add(13000);
        } else {
            nextVotingPeriod = block.number.add(votingBuffer);
            allCandidates = emptyArr;
        }
    }
    
    function removeManager(uint index) internal {
        managers[index] = managers[managers.length-1];
        delete managers[managers.length-1];
        managers.pop();
    }
    
    function liquidateOldManager(address manager) internal {
        //loop through manager's used contracts and call liquidate function
        for (uint32 i; i < managerStruct[manager].usedContracts.length; i++) {
            bool liquidated = usedContract(managerStruct[manager].usedContracts[i]).liquidateHoldings(manager);
        }
    }
    
    function getManagerLimit() public returns(uint32) {
        return managerLimit;
    }
    
    function beginVoting() public delegatedOnly {
        require(msg.sender == owner);
        canBeginVoting = true;
        nextVotingPeriod = block.number;
    }
    
    function checkFundManagerAllowance(address _manager, uint256 ETH) public delegatedOnly returns(bool) {
        require(msg.sender == registry);
        require(managerStruct[_manager].allowance >= ETH, "Fund Manager: Insufficient allowance");
        managerStruct[_manager].allowance = managerStruct[_manager].allowance.sub(ETH);
        managerStruct[_manager].holdingsHistory.push(managerStruct[_manager].allowance);
        return true;
    }
    
    function adjustFundManagerAllowance(address _manager, uint256 ETH, uint256 profit) public delegatedOnly {
        require(msg.sender == registry);
        //increase holdings by ETH
        managerStruct[_manager].allowance = managerStruct[_manager].allowance.add(ETH);
        //update holdings history
        managerStruct[_manager].holdingsHistory.push(managerStruct[_manager].allowance);
        //increase profits by profit amount
        managerStruct[_manager].profits = managerStruct[_manager].profits.add(profit);
        //update profit history
        managerStruct[_manager].profitHistory.push(managerStruct[_manager].profits);
    }
    
    function isFundManager(address manager) public view returns(bool) {
        return managerStruct[manager].isManager;
    }
    
    function updateROI() internal {
       
    }
    
    function checkIn(address _manager) internal delegatedOnly {
        if(block.number.sub(managerStruct[_manager].lastCheckInBlock) > 6500) {
            managerStruct[_manager].lastCheckInBlock = block.number;
        }
    }
    
    function manualCheckIn() public delegatedOnly {
        managerStruct[msg.sender].lastCheckInBlock = block.number;
    }
    
    
    receive() external payable {
        
    }
}