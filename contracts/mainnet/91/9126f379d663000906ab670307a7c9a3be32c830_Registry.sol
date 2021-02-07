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

// File: browser/Registry.sol

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

contract RegistryDataLayout is LibraryLock {
    address public owner;
    
    struct whitelistVotes {
        uint32 yesVotes;
        uint32 noVotes;
        address[] managers;
    }
    mapping(address => whitelistVotes) public whitelistContract;
    
    mapping(address => bool) public whitelist;
    
    struct queuedContract {
        uint256 finalizationBlock;
        bool result;
    }
    mapping(address => queuedContract) public queuedContracts;
    address[] public queueList;
    
    using SafeMath for uint32;
    using SafeMath for uint256;
    
    address public fundContract = 0x2c9728ad35C1CfB16E3C1B5045bC9BA30F37FAc5;
    address public connector = 0x60d70dF1c783b1E5489721c443465684e2756555;
    address public devFund = 0xd66A9D2B706e225204F475c9e70A4c09eEa62199;
    address public rewardsContract = 0x868f7622F57b62330Db8b282044d7EAf067fAcfe;
    address public contractManager;
    address public nyanManager;
    address public selfManager;
    address public nyanVoting;
}

interface usedContract {
    function getManagerLimit() external returns(uint32);
    function sendFundETH(address _manager) external payable;
    function getFundETH(uint256 amount) external;
    function returnFundETH() external payable;
    function fundLog(address manager, string calldata reason, address recipient) external payable;
    function isFundManager(address manager) view external returns(bool);
    function checkFundManagerAllowance(address _manager, uint256 ETH) external returns(bool);
    function checkManagerAllowance(address _manager, uint256 ETH) external returns(bool);
    function adjustFundManagerAllowance(address _manager, uint256 ETH, uint256 profit) external;
    function adjustManagerAllowance(address _manager, uint256 ETH, uint256 profit) external;
}

contract Registry is RegistryDataLayout, Proxiable {
    constructor() public {
        
    }
    
    function initRegistry(address _nyanManager) public {
        require(!initialized);
        owner = msg.sender;
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
    
    function setContracts(address _contractManager, 
                          address _nyanManager, 
                          address _selfManager,
                          address _nyanVoting) public {
                              require(msg.sender == owner);
                              contractManager = _contractManager;
                              nyanManager = _nyanManager;
                              selfManager = _selfManager;
                              nyanVoting = _nyanVoting;
    }
    
    function useFundETH(address manager, uint256 ETH, address recipient) public delegatedOnly payable {
        require(whitelist[msg.sender]);
        bool canSpend = usedContract(nyanManager).checkFundManagerAllowance(manager, ETH);
        require(canSpend);
        usedContract(connector).getFundETH(ETH);
        usedContract(connector).fundLog(manager, "used ETH for an investment", recipient);
        require(whitelist[recipient]);
        usedContract(recipient).sendFundETH{value: ETH}(manager);
    }
    
    function returnFundETH(address manager, uint256 profit) public delegatedOnly payable {
        require(whitelist[msg.sender]);
        if (profit > 100) {
            rewardsContract.call{value: profit.mul(40).div(100).sub(10)}("");
            manager.call{value: profit.mul(20).div(100)}("");
            devFund.call{value: profit.mul(10).div(100)}("");
            usedContract(connector).returnFundETH{value: msg.value.sub(profit.mul(70).div(100))}();
        } else {
            usedContract(connector).returnFundETH{value: msg.value}();
        }
        usedContract(connector).fundLog(manager, "returned ETH from an investment", fundContract);
        usedContract(nyanManager).adjustFundManagerAllowance(manager, msg.value, profit);
    }
    
    function useManagerETH(address manager, uint256 ETH, address recipient) public delegatedOnly payable {
        require(whitelist[msg.sender]);
        bool canSpend = usedContract(selfManager).checkManagerAllowance(manager, ETH);
        require(canSpend);
        usedContract(connector).getFundETH(ETH);
        usedContract(connector).fundLog(manager, "used ETH for an investment", recipient);
        require(whitelist[recipient]);
        usedContract(recipient).sendFundETH{value: ETH}(manager);
    }
    
    function returnManagerETH(address manager, uint256 profit) public delegatedOnly payable {
        require(whitelist[msg.sender]);
        if (profit > 100) {
            rewardsContract.call{value: profit.mul(10).div(100).sub(10)}("");
            manager.call{value: profit.mul(20).div(100)}("");
            usedContract(connector).returnFundETH{value: msg.value.sub(profit.mul(30).div(100))}();
            profit = profit.sub(profit.mul(30).div(100));
        } else {
            usedContract(connector).returnFundETH{value: msg.value}();
        }
        usedContract(connector).fundLog(manager, "returned ETH from an investment", fundContract);
        usedContract(selfManager).adjustManagerAllowance(manager, msg.value, profit);
    }
    
    //function to vote on contract to whitelist or blacklist
    function manageContract(address _contract, address _manager, bool vote) public delegatedOnly {
        require(msg.sender == nyanVoting);
        require(usedContract(nyanManager).isFundManager(_manager));
        //check if manager has already voted on contract this round
        bool hasVoted;
        for(uint32 i; i < whitelistContract[_contract].managers.length; i++) {
            if (whitelistContract[_contract].managers[i] == msg.sender) {
                hasVoted = true;
            }
        }
        require(!hasVoted, "You've already voted");
        //add manager's vote to contract
        if (vote) {
            whitelistContract[_contract].yesVotes = uint32(whitelistContract[_contract].yesVotes.add(1));
        } else {
            whitelistContract[_contract].noVotes = uint32(whitelistContract[_contract].noVotes.add(1));
        }
        whitelistContract[_contract].managers.push(msg.sender);
        
        //if all have voted in a direction, contract is whitelisted or blacklisted
        if (whitelistContract[_contract].yesVotes.add(whitelistContract[_contract].noVotes) == usedContract(nyanManager).getManagerLimit()) {
            if (whitelistContract[_contract].yesVotes > whitelistContract[_contract].noVotes) {
                queueList.push(_contract);
                queuedContracts[_contract].finalizationBlock = block.number.add(45500);
                queuedContracts[_contract].result = true;
            }
            if (whitelistContract[_contract].yesVotes < whitelistContract[_contract].noVotes) {
                queueList.push(_contract);
                queuedContracts[_contract].finalizationBlock = block.number.add(45500);
                queuedContracts[_contract].result = false;
            }
        }
    }
    
    function finalizeWhitelist(address _contract) public {
        bool isInQueue;
        for (uint32 i; i < queueList.length; i++) {
            if (queueList[i] == _contract) {
                if (queuedContracts[queueList[i]].finalizationBlock < block.number) {
                    whitelist[_contract] = queuedContracts[queueList[i]].result;
                    removeFromQueue(i);
                    return;
                }
            }
        }
    }
    
    function removeFromQueue(uint index) internal {
        queueList[index] = queueList[queueList.length-1];
        delete queueList[queueList.length-1];
        queueList.pop();
    }
    
    function createWhitelist(address _contract) public {
        require(msg.sender == owner);
        whitelist[_contract] = true;
    }
    
    function checkRegistry(address _contract) public view returns(bool) {
        return whitelist[_contract];
    }
    
    receive() external payable {
        
    }

}