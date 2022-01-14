// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './IERC20.sol';
import './AccessControl.sol';

contract Gateway is AccessControl {    
    // External token address, should be able to reset this by an owner
    IERC20 public token;

    // Escrow Status
    uint256 public currentEscrowId;
    uint8 constant DEFAULT = 0;
    uint8 constant DISPUTE = 1;
    uint8 constant REFUNDABLE = 2;
    uint8 constant COMPLETED = 3;
    uint8 constant REFUNDED = 4;

    // Dispute Status
    uint256 public currentDisputeId;
    uint8 constant INIT = 0;
    uint8 constant WAITING = 1;
    uint8 constant REVIEW = 2;
    uint8 constant WIN = 3;
    uint8 constant FAIL = 4;

    // Agent Status
    uint256 constant _INIT = 0;
    uint256 constant _WAITING = 1;
    uint256 constant _REVIEW = 2;
    uint256 constant _APPROVED = 3;
    uint256 constant _DISAPPROVED = 4;
    uint256 constant _EARNED = 5;
    uint256 constant _LOST = 6;
    uint256 constant _BAN = 7;

    // Agent related params, should be able to reset this by an owner
    uint256 public initialAgentScore = 100;
    uint256 public criteriaScore = 70;
    uint256 public disputeBonusAmount  = 10 * (10 ** 18);
    uint256 public scoreUp = 10;
    uint256 public scoreDown = 10;
    uint256 public disputeReviewGroupCount = 3;
    uint256 public disputeReviewConsensusCount = 2;
    uint256 public agentPaticipateAmount = 5 * (10 ** 18);

    struct Escrow {
        uint256 productId;
        address buyerAdderss;
        address merchantAddress;
        uint256 amount;
        uint256 escrowWithdrawableTime;
        uint256 escrowDisputableTime;
        uint256 status;
        uint256 createdAt;
    }
    struct Dispute {
        uint256 escrowId;
        uint256 approvedCount; // (default: 0)
        uint256 disapprovedCount; // (default: 0)
        uint256 status; // (default: 0)  0: init, 1: waiting, 2: review, 3: win, 4: fail
        uint256 createdAt;
        uint256 updatedAt;
    }
    struct Agent {
        uint256 score; // (default: initial_agent_score)
        uint256 participationCount;
        uint256 accumulatedAmount;
        uint256 assignedDisputeId;
        uint256 status;
    }

    mapping(uint256 => Escrow) public escrows;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => Agent) public agents;
    mapping(uint256 => address[]) public reviewers;

    event Escrowed(address indexed _from, uint256 indexed _productID, uint256 _amount, uint256 indexed _escrowId);
    event Disputed(address indexed _from, uint256 indexed _disputeId, uint256 indexed _escrowId);
    event AgentParticipated(address indexed _agentAddress);
    event AssignAgent(address indexed _agentAddress, uint256 indexed _disputeId);
    event SubmittedDispute(address indexed _agentAddress, uint256 indexed _disputeId, uint256 indexed _decision);
    event Withdraw(address indexed _withdrawer,  uint256 indexed _escrowId, uint256 _amount);
    event Refunded(address indexed _withdrawer,  uint256 indexed _escrowId, uint256 _amount);
	event DisputeApproved(uint256 indexed _disputeId);
	event DisputeDisapproved(uint256 indexed _disputeId);

    event AgentWithdraw(address indexed _withdrawer, uint256 _amount);

    constructor(address _token) setOwner(msg.sender) {
        currentEscrowId = 0;
        currentDisputeId = 0;
        token = IERC20(_token);
    }

    function resetTokenAddress(address _newTokenAddress) external isOwner(msg.sender) {
        require(_newTokenAddress != address(0) && _newTokenAddress != address(this), "Invalid Token Address");
        token = IERC20(_newTokenAddress);
    }

    function resetInitialAgentScore(uint256 _newInitialAgentScore) external isOwner(msg.sender) {
        require(_newInitialAgentScore > 0, "Invalid value");
        initialAgentScore = _newInitialAgentScore;
    }

    function resetCriteriaScore(uint256 _newCriteriaScore) external isOwner(msg.sender) {
        require(_newCriteriaScore >= 0, "Invalid value");
        criteriaScore = _newCriteriaScore;
    }

    function resetDisputeBonusAmount(uint256 _newDisputeBonusAmount) external isOwner(msg.sender) {
        require(_newDisputeBonusAmount >= 0, "Invalid value");
        disputeBonusAmount = _newDisputeBonusAmount * (10 ** 18);
    }

    function resetScoreUp(uint256 _newScoreUp) external isOwner(msg.sender) {
        require(_newScoreUp >= 0, "Invalid value");
        scoreUp = _newScoreUp;
    }

    function resetScoreDown(uint256 _newScoreDown) external isOwner(msg.sender) {
        require(_newScoreDown >= 0, "Invalid value");
        scoreDown = _newScoreDown;
    }

    function resetDisputeReviewGroupCount(uint256 _newDisputeReviewGroupCount) external isOwner(msg.sender) {
        require(_newDisputeReviewGroupCount > 0, "Invalid value");
        require(_newDisputeReviewGroupCount >= disputeReviewConsensusCount, "Should be larger number than the Consensus count");
        disputeReviewGroupCount = _newDisputeReviewGroupCount;
    }

    function resetDisputeReviewConsensusCount(uint256 _newDisputeReviewConsensusCount) external isOwner(msg.sender) {
        require(_newDisputeReviewConsensusCount > 0, "Invalid value");
        require(_newDisputeReviewConsensusCount <= disputeReviewGroupCount, "Should be smaller number than the Group count");
        disputeReviewConsensusCount = _newDisputeReviewConsensusCount;
    }

    function resetAgentPaticipateAmount(uint256 _newAgentPaticipateAmount) external isOwner(msg.sender) {
        require(_newAgentPaticipateAmount > 0, "Invalid value");
        agentPaticipateAmount = _newAgentPaticipateAmount * (10 ** 18);
    }

    // _escrowDisputableTime(Epoch time in seconds) - After this time, a customer can make a dispute case
    // _escrowWithdrawableTime(Epoch time in seconds) - After this time, a merchant can withdraw funds from an escrow contract
    function purchase(uint256 _productId, address _merchantAddress, uint256 _amount, uint256 _escrowWithdrawableTime, uint256 _escrowDisputableTime) public {
        require(_merchantAddress != address(0), "Invalid Merchant Address");
        require(_amount > 0, "Amount should be bigger than zero");
        require(token.balanceOf(msg.sender) >= _amount, "You don't have enough token amount");
        require(token.allowance(msg.sender, address(this)) >= _amount, "You should approve token transfer to this contract first");
        require(_escrowDisputableTime > block.timestamp, "Disputable time should be later than current time");
        require(_escrowWithdrawableTime > _escrowDisputableTime, "Withdraw Time should be later than Disputable time");

        escrows[currentEscrowId + 1] = Escrow(
            _productId,
            msg.sender,
            _merchantAddress,
            _amount,
            _escrowWithdrawableTime,
            _escrowDisputableTime,
            0,
            block.timestamp
        );
        // Should call the approve() function of token contract before calling this purchase function
        token.transferFrom(msg.sender, address(this), _amount);
        currentEscrowId = currentEscrowId + 1;
        emit Escrowed(msg.sender, _productId, _amount, currentEscrowId);
    }

    function withdraw(uint256 _escrowId) public {
        require(escrows[_escrowId].status == DEFAULT || escrows[_escrowId].status == REFUNDABLE, "Invalid Status");
        require(block.timestamp > escrows[_escrowId].escrowWithdrawableTime, "Escrowd time has not passed yet");
        require(msg.sender == escrows[_escrowId].buyerAdderss || msg.sender == escrows[_escrowId].merchantAddress, "Caller is neither Buyer nor Merchant");
        require(token.balanceOf(address(this)) >= escrows[_escrowId].amount, "Contract doesn't have enough funds");

        if (escrows[_escrowId].status == DEFAULT && escrows[_escrowId].buyerAdderss == msg.sender) {
            revert("Buyer cannot withdraw in default status");
        }
        if (escrows[_escrowId].status == REFUNDABLE && escrows[_escrowId].merchantAddress == msg.sender) {
            revert("Merchant cannot withdraw in refund status");
        }

        if (escrows[_escrowId].status == REFUNDABLE && escrows[_escrowId].buyerAdderss == msg.sender) {
            // Transfers tokens to buyer
            token.transfer(escrows[_escrowId].buyerAdderss, escrows[_escrowId].amount);
            // Update the escrow status as REFUNDED
            escrows[_escrowId].status = REFUNDED;
            emit Withdraw(msg.sender, _escrowId,  escrows[_escrowId].amount);
        } else if (escrows[_escrowId].status == DEFAULT && escrows[_escrowId].merchantAddress == msg.sender) {
            // Transfers tokens to merchant
            token.transfer(escrows[_escrowId].merchantAddress, escrows[_escrowId].amount);
            // Update the escrow status as COMPLETED
            escrows[_escrowId].status = COMPLETED;
            emit Withdraw(msg.sender, _escrowId,  escrows[_escrowId].amount);
        }
    }

    function dispute(uint256 _escrowId) public {
        require(escrows[_escrowId].status == DEFAULT, "Escrow status must be on the DEFAULT status");
        require(msg.sender == escrows[_escrowId].buyerAdderss, "Caller is not buyer");
        require(escrows[_escrowId].escrowDisputableTime <= block.timestamp, "Please wait until the disputable time");
        require(escrows[_escrowId].escrowWithdrawableTime >= block.timestamp, "Disputable time was passed already");
        
        escrows[_escrowId].status = DISPUTE;
        disputes[currentDisputeId + 1] = Dispute(
            _escrowId,
            0,
            0,
            INIT,
            block.timestamp,
            block.timestamp
        );

        currentDisputeId = currentDisputeId + 1;
        emit Disputed(msg.sender, currentDisputeId, _escrowId);
    }

    // Call this function to get credits as an Agent, should call approve function of Token contract before calling this function
    function participate() external {
        require(agents[msg.sender].status == _INIT || agents[msg.sender].status == _LOST, "Wrong status");
        require(token.balanceOf(msg.sender) >= agentPaticipateAmount, "Not correct amount");

        if (agents[msg.sender].participationCount != 0 && agents[msg.sender].score < criteriaScore) {
            revert("Your agent score is too low, so can't participate any more");
        }
        
        token.transferFrom(msg.sender, address(this), agentPaticipateAmount);

        if (agents[msg.sender].participationCount == 0) {
            agents[msg.sender] = Agent(
                initialAgentScore,
                0,
                agentPaticipateAmount,
                0,
                _WAITING
            );
        } else {
            agents[msg.sender] = Agent(
                agents[msg.sender].score,
                agents[msg.sender].participationCount,
                agents[msg.sender].accumulatedAmount + agentPaticipateAmount,
                0,
                _WAITING
            );
        }
        
        emit AgentParticipated(msg.sender);
    }

    function assignAgent(uint256 _disputeId, address _agentAddress) external isOwner(msg.sender) {
        require(agents[_agentAddress].status == _WAITING, "Agent is not in waiting state");
        require(agents[_agentAddress].score >= criteriaScore, "Low agent score");
        require(disputes[_disputeId].escrowId != 0, "Invalid dispute id");
        require(disputes[_disputeId].status == INIT || disputes[_disputeId].status == WAITING, "Dispute is not in init nor in waiting status");
        
        disputes[_disputeId].status = REVIEW;
        agents[_agentAddress].status = REVIEW;
        agents[_agentAddress].assignedDisputeId = _disputeId;

        emit AssignAgent(_agentAddress, _disputeId);
    }

    // Need to have MTO transfered beforehand
    function submit(uint256 _disputeId, uint256 _decision) external {
        require(agents[msg.sender].score >= criteriaScore, "Too low score as an Agent");
        require(agents[msg.sender].accumulatedAmount >= (agents[msg.sender].participationCount + 1) * agentPaticipateAmount, "You didn't fund enough amount");
        require(agents[msg.sender].status == _REVIEW, "Agent status should be review");
        require(agents[msg.sender].assignedDisputeId == _disputeId, "disputeID is not assigned");
        require(disputes[agents[msg.sender].assignedDisputeId].escrowId != 0, "DisputeID is not valid");
        require(_decision == _APPROVED || _decision == _DISAPPROVED, "Invalid decision value");

        if (_decision == _APPROVED && disputes[_disputeId].approvedCount + 1 >= disputeReviewConsensusCount) {

            agents[msg.sender].status = _EARNED;
            agents[msg.sender].score += scoreUp;
            agents[msg.sender].assignedDisputeId = 0;

            disputes[_disputeId].status = WIN;
            disputes[_disputeId].approvedCount += 1;
            disputes[_disputeId].updatedAt = block.timestamp;
			emit DisputeApproved(_disputeId);

            escrows[disputes[_disputeId].escrowId].status = REFUNDED; // REFUNDABLE; In case not returing the funds back to a customer in this function
            // Transfer the funds to a customer for chargeback as a dipsute case got approved
            token.transfer(escrows[disputes[_disputeId].escrowId].buyerAdderss, escrows[disputes[_disputeId].escrowId].amount);
            emit Refunded(escrows[disputes[_disputeId].escrowId].buyerAdderss, disputes[_disputeId].escrowId, escrows[disputes[_disputeId].escrowId].amount);

            for (uint256 i = 0; i < reviewers[_disputeId].length; i++) {
                if (agents[reviewers[_disputeId][i]].status == _APPROVED) {
                    agents[reviewers[_disputeId][i]].status = _EARNED;
                    agents[reviewers[_disputeId][i]].score += scoreUp;
                    agents[reviewers[_disputeId][i]].assignedDisputeId = 0;
                }
                else if (agents[reviewers[_disputeId][i]].status == _DISAPPROVED) {
                    agents[reviewers[_disputeId][i]].status = _LOST;
                    agents[reviewers[_disputeId][i]].score -= scoreDown;
                    agents[reviewers[_disputeId][i]].assignedDisputeId = 0;
                }
            }

        } 
        else if (_decision == _DISAPPROVED && disputes[_disputeId].disapprovedCount + 1 >= disputeReviewConsensusCount) {

            agents[msg.sender].status = _EARNED;
            agents[msg.sender].score += scoreUp;
            agents[msg.sender].assignedDisputeId = 0;

            disputes[_disputeId].status = FAIL;
            disputes[_disputeId].disapprovedCount += 1;
            disputes[_disputeId].updatedAt = block.timestamp;
			emit DisputeDisapproved(_disputeId);

            escrows[disputes[_disputeId].escrowId].status = COMPLETED; // DEFAULT; In case not returing the funds to a merchant in this function
            // Transfer the funds to a merchant for selling the product as a dipsute case(by a customer) got disapproved
            token.transfer(escrows[disputes[_disputeId].escrowId].merchantAddress, escrows[disputes[_disputeId].escrowId].amount);
            emit Withdraw(escrows[disputes[_disputeId].escrowId].merchantAddress, disputes[_disputeId].escrowId, escrows[disputes[_disputeId].escrowId].amount);

            for (uint256 i = 0; i < reviewers[_disputeId].length; i++) {
                if (agents[reviewers[_disputeId][i]].status == _DISAPPROVED) {
                    agents[reviewers[_disputeId][i]].status = _EARNED;
                    agents[reviewers[_disputeId][i]].score += scoreUp;
                    agents[reviewers[_disputeId][i]].assignedDisputeId = 0;
                }
                else if (agents[reviewers[_disputeId][i]].status == _APPROVED) {                    
                    agents[reviewers[_disputeId][i]].status = _LOST;
                    agents[reviewers[_disputeId][i]].score -= scoreDown;
                    agents[reviewers[_disputeId][i]].assignedDisputeId = 0;
                }
            }

        }
        else if (_decision == _APPROVED && disputes[_disputeId].approvedCount + 1 < disputeReviewConsensusCount && disputes[_disputeId].approvedCount + disputes[_disputeId].disapprovedCount + 1 >= disputeReviewGroupCount) {
            
            agents[msg.sender].status = _LOST;
            agents[msg.sender].score -= scoreDown;
            agents[msg.sender].assignedDisputeId = 0;
            
            disputes[_disputeId].status = INIT;
            disputes[_disputeId].approvedCount = 0;
            disputes[_disputeId].disapprovedCount = 0;
            disputes[_disputeId].updatedAt = block.timestamp;
            
            for (uint256 i = 0; i < reviewers[_disputeId].length; i++) {  
                agents[reviewers[_disputeId][i]].status = _LOST;
                agents[reviewers[_disputeId][i]].score -= scoreDown;
                agents[reviewers[_disputeId][i]].assignedDisputeId = 0;
            }

        }
        else if (_decision == _DISAPPROVED && disputes[_disputeId].disapprovedCount + 1 < disputeReviewConsensusCount && disputes[_disputeId].approvedCount + disputes[_disputeId].disapprovedCount + 1 >= disputeReviewGroupCount) {
            
            agents[msg.sender].status = _LOST;
            agents[msg.sender].score -= scoreDown;
            agents[msg.sender].assignedDisputeId = 0;
            
            disputes[_disputeId].status = INIT;
            disputes[_disputeId].approvedCount = 0;
            disputes[_disputeId].disapprovedCount = 0;
            disputes[_disputeId].updatedAt = block.timestamp;
            
            for (uint256 i = 0; i < reviewers[_disputeId].length; i++) {                
                agents[reviewers[_disputeId][i]].status = _LOST;
                agents[reviewers[_disputeId][i]].score -= scoreDown;
                agents[reviewers[_disputeId][i]].assignedDisputeId = 0;
            }

        }
        else {
            agents[msg.sender].participationCount += 1;
            agents[msg.sender].status = _decision;
            agents[msg.sender].assignedDisputeId = 0;
            
            reviewers[_disputeId].push(msg.sender);
            
            disputes[_disputeId].status = WAITING;
            disputes[_disputeId].updatedAt = block.timestamp;
            
            if (_decision == _APPROVED) disputes[_disputeId].approvedCount += 1;
            else if (_decision == _DISAPPROVED) disputes[_disputeId].disapprovedCount += 1;
        }

        if (agents[msg.sender].score < criteriaScore && agents[msg.sender].status != _BAN) {
            agents[msg.sender].status = _BAN;
        }

        emit SubmittedDispute(msg.sender, _disputeId, _decision);
    }

    function agentWithdraw() external {
        require(agents[msg.sender].status == _EARNED, "Cannot withdraw unearned tokens");

        agents[msg.sender].status = _INIT;
        token.transfer(msg.sender, disputeBonusAmount);

        emit AgentWithdraw(msg.sender, disputeBonusAmount);
    }

    function adminWithdrawToken(uint256 _amount) external isOwner(msg.sender) {
        require(token.balanceOf(address(this)) > _amount, "Not enough balance");
        token.transfer(msg.sender, _amount);
    }

    // TODO 1: fee, 2: reset global variables 3: auto assign system

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessControl {
    address private owner = address(0);

    modifier isOwner(address _owner) {
        require(owner == _owner, "Caller is not owner");
        _;
    }

    modifier setOwner(address _owner) {
        require(
            owner == address(0) || msg.sender == owner,
            "Only current owner can handle access control"
        );
        owner = _owner;
        _;
    }
}