/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


interface Token {
    function approve(address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

interface LegacyToken {
    function transfer(address, uint) external;
}

interface StakingPool {
    function disburseRewardTokens() external;
    function burnRewardTokens() external;
    function transferOwnership(address) external;
    function transferAnyERC20Token(address, address, uint) external;
    function transferAnyOldERC20Token(address, address, uint) external;
    
    function setContractVariables(
        uint newMagicNumber, 
        uint lockupTime,
        uint stakingFeeRateX100,
        uint unstakingFeeRateX100,
        address _uniswapV2RouterAddress,
        address newFeeRecipientAddress
    ) external;
    
    function declareEmergency() external;
    function claimAnyToken(address token, address recipient, uint amount) external;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    
    /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyPendingOwner() {
        assert(msg.sender != address(0));
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        pendingOwner = _newOwner;
    }
  
    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() onlyPendingOwner public {
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @title Governance
 * @dev Governance smart contract for staking pools
 * Takes in DYP as votes
 * Allows addition and removal of votes during a proposal is open
 * Allows withdrawal of all dyp once the latest voted proposal of a user is closed
 * Has a QUORUM requirement for proposals to be executed
 * CONTRACT VARIABLES must be changed to appropriate values before live deployment
 */
contract Governance is Ownable {
    using SafeMath for uint;

    // Contracts are not allowed to deposit, claim or withdraw
    modifier noContractsAllowed() {
        require(tx.origin == msg.sender, "No Contracts Allowed!");
        _;
    }
    
    // ============== CONTRACT VARIABLES ==============
    // Contract variables and hardcoded addresses must be updated 
    // to appropriate config before live deployment
    
    // voting token contract address
    address public constant TRUSTED_TOKEN_ADDRESS = 0x9194a964a6FAe46569b60280c0E715fB780e1011;
    
    // minimum number of votes required for a result to be valid
    // 1 token = 1 vote
    uint public QUORUM = 100e18;
    
    uint public constant ADMIN_FEATURES_EXPIRE_AFTER = 20 minutes;
    
    // Admin can transfer out Governance Tokens from this contract ADMIN_CAN_CLAIM_AFTER
    // duration since creation
    uint public ADMIN_CAN_CLAIM_AFTER = 40 minutes;
    
    // minimum number of tokens required to initialize a proposal
    uint public MIN_BALANCE_TO_INIT_PROPOSAL = 100e18;
    
    // duration since proposal creation till users can vote
    uint public constant VOTE_DURATION = 5 minutes;
    
    // duration after voting, since a proposal has passed
    // during which the proposed action may be executed
    uint public constant RESULT_EXECUTION_ALLOWANCE_PERIOD = 5 minutes;
    uint public constant EMERGENCY_WAIT_TIME = 5 minutes;
    
    // ============ END CONTRACT VARIABLES ============
    
    uint public immutable contractStartTime;
    
    event PoolCallSucceeded(StakingPool);
    event PoolCallReverted(StakingPool, string);
    event PoolCallReverted(StakingPool, bytes);
    
    event EmergencyDeclared(address admin);
    
    enum PoolGroupName {
        WETH,
        WBTC,
        USDT,
        USDC
    }
    
    enum Action {
        DISBURSE_OR_BURN,
        UPGRADE_GOVERNANCE,
        CHANGE_QUORUM,
        TEXT_PROPOSAL,
        CHANGE_MIN_BALANCE_TO_INIT_PROPOSAL,
        SET_CONTRACT_VARIABLES
    }
    
    enum Option {
        ONE, // disburse | yes
        TWO // burn | no
    }
    
    mapping (PoolGroupName => StakingPool[4]) public hardcodedStakingPools;
    
    constructor() public {
        contractStartTime = now;
        
        hardcodedStakingPools[PoolGroupName.WETH][0] = StakingPool(address(0));
        hardcodedStakingPools[PoolGroupName.WETH][1] = StakingPool(address(0));
        hardcodedStakingPools[PoolGroupName.WETH][2] = StakingPool(address(0));
        hardcodedStakingPools[PoolGroupName.WETH][3] = StakingPool(address(0));
        
        hardcodedStakingPools[PoolGroupName.WBTC][0] = StakingPool(address(0));
        hardcodedStakingPools[PoolGroupName.WBTC][1] = StakingPool(address(0));
        hardcodedStakingPools[PoolGroupName.WBTC][2] = StakingPool(address(0));
        hardcodedStakingPools[PoolGroupName.WBTC][3] = StakingPool(address(0));
        
        hardcodedStakingPools[PoolGroupName.USDT][0] = StakingPool(address(0));
        hardcodedStakingPools[PoolGroupName.USDT][1] = StakingPool(address(0));
        hardcodedStakingPools[PoolGroupName.USDT][2] = StakingPool(address(0));
        hardcodedStakingPools[PoolGroupName.USDT][3] = StakingPool(address(0));
        
        hardcodedStakingPools[PoolGroupName.USDC][0] = StakingPool(address(0));
        hardcodedStakingPools[PoolGroupName.USDC][1] = StakingPool(address(0));
        hardcodedStakingPools[PoolGroupName.USDC][2] = StakingPool(address(0));
        hardcodedStakingPools[PoolGroupName.USDC][3] = StakingPool(address(0));
    }
    
    bool public isEmergency = false;
    modifier notDuringEmergency() {
        require(!isEmergency, "Cannot execute during emergency!");
        _;
    }
    
    function declareEmergency() external onlyOwner notDuringEmergency {
        isEmergency = true;
        ADMIN_CAN_CLAIM_AFTER = now.add(EMERGENCY_WAIT_TIME).sub(contractStartTime);
        
        emit EmergencyDeclared(owner());
    }
    
    
    // proposal id => action
    mapping (uint => Action) public actions;
    
    // proposal id => option one votes
    mapping (uint => uint) public optionOneVotes;
    
    // proposal id => option two votes
    mapping (uint => uint) public optionTwoVotes;
    
    // proposal id => staking pool
    mapping (uint => StakingPool[]) public stakingPools;
    
    // proposal id => newGovernance
    mapping (uint => address) public newGovernances;
    
    // proposal id => unix time for proposal start
    mapping (uint => uint) public proposalStartTime;
    
    // proposal id => bool
    mapping (uint => bool) public isProposalExecuted;
    
    mapping (uint => uint) public newQuorums;
    mapping (uint => uint) public newMinBalances;
    mapping (uint => string) public proposalTexts;
    
    
    mapping (uint => address) public setContractVariables_farmContractAddress;
    
    mapping (uint => address) public setContractVariables_newRouterAddress;
    mapping (uint => address) public setContractVariables_newFeeRecipientAddress;
    mapping (uint => uint) public    setContractVariables_newMagicNumber;
    mapping (uint => uint) public    setContractVariables_newLockupTime;
    mapping (uint => uint) public    setContractVariables_newStakingFeeRateX100;
    mapping (uint => uint) public    setContractVariables_newUnstakingFeeRateX100;
    
    
    // address user => total deposited DYP
    mapping (address => uint) public totalDepositedTokens;
    
    // address user => uint proposal id => uint vote amounts
    mapping (address => mapping (uint => uint)) public votesForProposalByAddress;
    
    // address user => uint proposal id => Option voted for option
    mapping (address => mapping (uint => Option)) public votedForOption;
    
    // address user => uint start time for the latest proposal the user voted on
    mapping (address => uint) public lastVotedProposalStartTime;
    
    // uint last proposal id
    // proposal ids start at 1
    uint public lastIndex = 0;
    
    // view function to get proposal details
    function getProposal(uint proposalId) external view returns (
        uint _proposalId, 
        Action _proposalAction,
        uint _optionOneVotes,
        uint _optionTwoVotes,
        StakingPool[] memory _stakingPool,
        address _newGovernance,
        uint _proposalStartTime,
        bool _isProposalExecuted,
        uint _newQuorum,
        string memory _proposalText,
        uint _newMinBalance
        ) {
        _proposalId = proposalId;
        _proposalAction = actions[proposalId];
        _optionOneVotes = optionOneVotes[proposalId];
        _optionTwoVotes = optionTwoVotes[proposalId];
        _stakingPool = stakingPools[proposalId];
        _newGovernance = newGovernances[proposalId];
        _proposalStartTime = proposalStartTime[proposalId];
        _isProposalExecuted = isProposalExecuted[proposalId];
        _newQuorum = newQuorums[proposalId];
        _proposalText = proposalTexts[proposalId];
        _newMinBalance = newMinBalances[proposalId];
    }
    
    function changeQuorum(uint newQuorum) external onlyOwner {
        require(now < contractStartTime.add(ADMIN_FEATURES_EXPIRE_AFTER), "Change quorum feature expired!");
        QUORUM = newQuorum;
    }
    
    function changeMinBalanceToInitProposal(uint newMinBalanceToInitProposal) external onlyOwner {
        require(now < contractStartTime.add(ADMIN_FEATURES_EXPIRE_AFTER), "This admin feature has expired!");
        MIN_BALANCE_TO_INIT_PROPOSAL = newMinBalanceToInitProposal;
    }
    
    // Any DYP holder with a minimum required DYP balance may initiate a proposal
    // with the TEXT_PROPOSAL action for a given staking pool
    function proposeText(string memory text) external noContractsAllowed {
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        proposalStartTime[lastIndex] = now;
        actions[lastIndex] = Action.TEXT_PROPOSAL;
        proposalTexts[lastIndex] = text;
    }
    
    // Any DYP holder with a minimum required DYP balance may initiate a proposal
    // with the DISBURSE_OR_BURN action for a given staking pool
    function proposeDisburseOrBurn(PoolGroupName poolGroupName) external noContractsAllowed {
        require(poolGroupName == PoolGroupName.WETH ||
                poolGroupName == PoolGroupName.WBTC ||
                poolGroupName == PoolGroupName.USDT ||
                poolGroupName == PoolGroupName.USDC, "Invalid Pool Group Name!");
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        
        stakingPools[lastIndex] = hardcodedStakingPools[poolGroupName];
        
        proposalStartTime[lastIndex] = now;
        actions[lastIndex] = Action.DISBURSE_OR_BURN;
    }
    
    // Admin may initiate a proposal
    // with the UPGRADE_GOVERNANCE action for a given staking pool
    function proposeUpgradeGovernance(PoolGroupName poolGroupName, address newGovernance) external noContractsAllowed onlyOwner {
        require(poolGroupName == PoolGroupName.WETH ||
                poolGroupName == PoolGroupName.WBTC ||
                poolGroupName == PoolGroupName.USDT ||
                poolGroupName == PoolGroupName.USDC, "Invalid Pool Group Name!");
                
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        
        stakingPools[lastIndex] = hardcodedStakingPools[poolGroupName];
        
        newGovernances[lastIndex] = newGovernance;
        proposalStartTime[lastIndex] = now;
        actions[lastIndex] = Action.UPGRADE_GOVERNANCE;
    }
    
    // Admin may initiate a proposal
    // with the CHANGE_QUORUM action for the Governance
    function proposeNewQuorum(uint newQuorum) external noContractsAllowed onlyOwner {
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        newQuorums[lastIndex] = newQuorum;
        proposalStartTime[lastIndex] = now;
        actions[lastIndex] = Action.CHANGE_QUORUM;
    }
    
    // Admin may initiate a proposal
    // with the CHANGE_MIN_BALANCE_TO_INIT_PROPOSAL action for the Governance
    function proposeNewMinBalanceToInitProposal(uint newMinBalance) external noContractsAllowed onlyOwner {
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        newMinBalances[lastIndex] = newMinBalance;
        proposalStartTime[lastIndex] = now;
        actions[lastIndex] = Action.CHANGE_MIN_BALANCE_TO_INIT_PROPOSAL;
    }
    
    function proposeSetContractVariables(
        address trustedFarmContractAddress,
        
        uint newMagicNumber,
        uint newLockupTime,
        uint newStakingFeeRateX100,
        uint newUnstakingFeeRateX100,
        
        address newRouterAddress,
        address newFeeRecipientAddress
    ) external noContractsAllowed onlyOwner {
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        
        setContractVariables_farmContractAddress[lastIndex] = trustedFarmContractAddress;
        
        setContractVariables_newMagicNumber[lastIndex] = newMagicNumber;
        setContractVariables_newLockupTime[lastIndex] = newLockupTime;
        setContractVariables_newStakingFeeRateX100[lastIndex] = newStakingFeeRateX100;
        setContractVariables_newUnstakingFeeRateX100[lastIndex] = newUnstakingFeeRateX100;
        
        setContractVariables_newRouterAddress[lastIndex] = newRouterAddress;
        setContractVariables_newFeeRecipientAddress[lastIndex] = newFeeRecipientAddress;
        
        proposalStartTime[lastIndex] = now;
        actions[lastIndex] = Action.SET_CONTRACT_VARIABLES;
    }
    
    // Any DYP holder may add votes for a particular open proposal, 
    // with options YES / NO | DISBURSE / BURN | ONE / TWO
    // with `amount` DYP, each DYP unit corresponds to one vote unit
    
    // If user has already voted for a proposal with an option,
    // user may not add votes with another option, 
    // they will need to add votes for the same option
    function addVotes(uint proposalId, Option option, uint amount) external noContractsAllowed notDuringEmergency {
        require(amount > 0, "Cannot add 0 votes!");
        require(isProposalOpen(proposalId), "Proposal is closed!");
        
        require(Token(TRUSTED_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amount), "transferFrom failed!");
        
        // if user is voting for this proposal first time
        if (votesForProposalByAddress[msg.sender][proposalId] == 0) {
            votedForOption[msg.sender][proposalId] = option;
        } else {
            if (votedForOption[msg.sender][proposalId] != option) {
                revert("Cannot vote for both options!");
            }
        }
        
        if (option == Option.ONE) {
            optionOneVotes[proposalId] = optionOneVotes[proposalId].add(amount);
        } else {
            optionTwoVotes[proposalId] = optionTwoVotes[proposalId].add(amount);
        }
        totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(amount);
        votesForProposalByAddress[msg.sender][proposalId] = votesForProposalByAddress[msg.sender][proposalId].add(amount);
        
        if (lastVotedProposalStartTime[msg.sender] < proposalStartTime[proposalId]) {
            lastVotedProposalStartTime[msg.sender] = proposalStartTime[proposalId];
        }
    }
    
    // Any voter may remove their votes (DYP) from any proposal they voted for 
    // only when the proposal is open - removing votes refund DYP to user and deduct their votes
    function removeVotes(uint proposalId, uint amount) external noContractsAllowed {
        require(amount > 0, "Cannot remove 0 votes!");
        require(isProposalOpen(proposalId), "Proposal is closed!");
        
        require(amount <= votesForProposalByAddress[msg.sender][proposalId], "Cannot remove more tokens than deposited!");
        
        votesForProposalByAddress[msg.sender][proposalId] = votesForProposalByAddress[msg.sender][proposalId].sub(amount);
        totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(amount);
        
        if (votedForOption[msg.sender][proposalId] == Option.ONE) {
            optionOneVotes[proposalId] = optionOneVotes[proposalId].sub(amount);
        } else {
            optionTwoVotes[proposalId] = optionTwoVotes[proposalId].sub(amount);
        }
        
        require(Token(TRUSTED_TOKEN_ADDRESS).transfer(msg.sender, amount), "transfer failed");
    }

    // After the latest proposal the user voted for, is closed for voting,
    // The user may remove all DYP they added to this contract
    function withdrawAllTokens() external noContractsAllowed {
        require(now > lastVotedProposalStartTime[msg.sender].add(VOTE_DURATION), "Tokens are still in voting!");
        require(Token(TRUSTED_TOKEN_ADDRESS).transfer(msg.sender, totalDepositedTokens[msg.sender]), "transfer failed!");
        totalDepositedTokens[msg.sender] = 0;
    }
    
    // After votes for a proposal are closed, the proposal may be executed by anyone
    // If QUORUM is not reached, transaction must revert
    // If winning option has more votes than losing option, winning action is executed
    // Else losing action is executed
    // Each proposal may be executed only once
    function executeProposal(uint proposalId) external noContractsAllowed notDuringEmergency {
        require (actions[proposalId] != Action.TEXT_PROPOSAL, "Cannot programmatically execute text proposals");
        require (optionOneVotes[proposalId] != optionTwoVotes[proposalId], "This is a TIE! Cannot execute!");
        require (isProposalExecutible(proposalId), "Proposal Expired!");
        
        isProposalExecuted[proposalId] = true;
    
        Option winningOption;
        uint winningOptionVotes;
        
        if (optionOneVotes[proposalId] > optionTwoVotes[proposalId]) {
            winningOption = Option.ONE;
            winningOptionVotes = optionOneVotes[proposalId];
        } else {
            winningOption = Option.TWO;
            winningOptionVotes = optionTwoVotes[proposalId];
        }
        
        // no action will be taken if winningOptionVotes are less than QUORUM
        if (winningOptionVotes < QUORUM) {
            revert("QUORUM not reached!");
        }
        
        if (actions[proposalId] == Action.DISBURSE_OR_BURN) {
            if (winningOption == Option.ONE) {
                for (uint8 i = 0; i < 4; i++) {
                    StakingPool pool = stakingPools[proposalId][i];
                    try pool.disburseRewardTokens() {
                        emit PoolCallSucceeded(pool);
                    } catch Error(string memory reason) {
                        emit PoolCallReverted(pool, reason);
                    } catch (bytes memory lowLevelData) {
                        emit PoolCallReverted(pool, lowLevelData);
                    }
                }
            } else {
                for (uint8 i = 0; i < 4; i++) {
                    StakingPool pool = stakingPools[proposalId][i];
                    try pool.burnRewardTokens() {
                        emit PoolCallSucceeded(pool);
                    } catch Error(string memory reason) {
                        emit PoolCallReverted(pool, reason);
                    } catch (bytes memory lowLevelData) {
                        emit PoolCallReverted(pool, lowLevelData);
                    }
                }
            }
        } else if (actions[proposalId] == Action.UPGRADE_GOVERNANCE) {
            if (winningOption == Option.ONE) {
                for (uint8 i = 0; i < 4; i++) {
                    StakingPool pool = stakingPools[proposalId][i];
                    try pool.transferOwnership(newGovernances[proposalId]) {
                        emit PoolCallSucceeded(pool);
                    } catch Error(string memory reason) {
                        emit PoolCallReverted(pool, reason);
                    } catch (bytes memory lowLevelData) {
                        emit PoolCallReverted(pool, lowLevelData);
                    }
                }
            }
        } else if (actions[proposalId] == Action.CHANGE_QUORUM) {
            if (winningOption == Option.ONE) {
                QUORUM = newQuorums[proposalId];
            }
        } else if (actions[proposalId] == Action.CHANGE_MIN_BALANCE_TO_INIT_PROPOSAL) {
            if (winningOption == Option.ONE) {
                MIN_BALANCE_TO_INIT_PROPOSAL = newMinBalances[proposalId];
            }
        } else if (actions[proposalId] == Action.SET_CONTRACT_VARIABLES) {
            if (winningOption == Option.ONE) {
                StakingPool(setContractVariables_farmContractAddress[proposalId]).setContractVariables(
                    setContractVariables_newMagicNumber[proposalId],
                    setContractVariables_newLockupTime[proposalId],
                    setContractVariables_newStakingFeeRateX100[proposalId],
                    setContractVariables_newUnstakingFeeRateX100[proposalId],
                    setContractVariables_newRouterAddress[proposalId],
                    setContractVariables_newFeeRecipientAddress[proposalId]
                );
            }
        }
    }
    
    // view function to know whether voting for a particular proposal is open
    function isProposalOpen(uint proposalId) public view returns (bool) {
        if (now < proposalStartTime[proposalId].add(VOTE_DURATION)) {
            return true;
        }
        return false;
    }
    
    // View function to know whether voting for a proposal is closed AND 
    // The proposal is within the RESULT_EXECUTION_ALLOWANCE_PERIOD AND
    // Has not been executed yet
    function isProposalExecutible(uint proposalId) public view returns (bool) {
        if ((!isProposalOpen(proposalId)) && 
            (now < proposalStartTime[proposalId].add(VOTE_DURATION).add(RESULT_EXECUTION_ALLOWANCE_PERIOD)) &&
            !isProposalExecuted[proposalId] &&
            optionOneVotes[proposalId] != optionTwoVotes[proposalId]) {
                return true;
            }
        return false;
    }
    
    
    function transferAnyERC20Token(address tokenAddress, address recipient, uint amount) external onlyOwner {
        require (tokenAddress != TRUSTED_TOKEN_ADDRESS || now > contractStartTime.add(ADMIN_CAN_CLAIM_AFTER), "Cannot Transfer Out main tokens!");
        require (Token(tokenAddress).transfer(recipient, amount), "Transfer failed!");
    }
    
    function transferAnyLegacyERC20Token(address tokenAddress, address recipient, uint amount) external onlyOwner {
        require (tokenAddress != TRUSTED_TOKEN_ADDRESS || now > contractStartTime.add(ADMIN_CAN_CLAIM_AFTER), "Cannot Transfer Out main tokens!");
        LegacyToken(tokenAddress).transfer(recipient, amount);
    }
    
    function transferAnyERC20TokenFromPool(address pool, address tokenAddress, address recipient, uint amount) external onlyOwner {
        StakingPool(pool).transferAnyERC20Token(tokenAddress, recipient, amount);
    }
    
    function transferAnyLegacyERC20TokenFromPool(address pool, address tokenAddress, address recipient, uint amount) external onlyOwner {
        StakingPool(pool).transferAnyOldERC20Token(tokenAddress, recipient, amount);
    }
    
    
    function declareEmergencyForContract(address trustedFarmContractAddress) external onlyOwner {
        StakingPool(trustedFarmContractAddress).declareEmergency();
    }
    function claimAnyTokenFromContract(address trustedFarmContractAddress, address token, address recipient, uint amount) external onlyOwner {
        StakingPool(trustedFarmContractAddress).claimAnyToken(token, recipient, amount);
    }
    function emergencyTransferContractOwnership(address trustedFarmContractAddress, address newOwner) external onlyOwner {
        require(isEmergency, "Can only execute this during emergency");
        StakingPool(trustedFarmContractAddress).transferOwnership(newOwner);
    }
    
}