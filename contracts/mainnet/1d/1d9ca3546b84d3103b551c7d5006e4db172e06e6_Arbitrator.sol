pragma solidity ^0.4.18;

contract Owned {
    address public owner;

    function Owned() 
    public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) 
        onlyOwner 
    public {
        owner = newOwner;
    }
}

contract RealityCheckAPI {
    function setQuestionFee(uint256 fee) public;
    function finalizeByArbitrator(bytes32 question_id, bytes32 answer) public;
    function submitAnswerByArbitrator(bytes32 question_id, bytes32 answer, address answerer) public;
    function notifyOfArbitrationRequest(bytes32 question_id, address requester) public;
    function isFinalized(bytes32 question_id) public returns (bool);
    function withdraw() public;
}

contract Arbitrator is Owned {

    mapping(bytes32 => uint256) public arbitration_bounties;

    uint256 dispute_fee;
    mapping(bytes32 => uint256) custom_dispute_fees;

    event LogRequestArbitration(
        bytes32 indexed question_id,
        uint256 fee_paid,
        address requester,
        uint256 remaining
    );

    event LogSetQuestionFee(
        uint256 fee
    );

    event LogSetDisputeFee(
        uint256 fee
    );

    event LogSetCustomDisputeFee(
        bytes32 indexed question_id,
        uint256 fee
    );

    /// @notice Constructor. Sets the deploying address as owner.
    function Arbitrator() 
    public {
        owner = msg.sender;
    }

    /// @notice Set the default fee
    /// @param fee The default fee amount
    function setDisputeFee(uint256 fee) 
        onlyOwner 
    public {
        dispute_fee = fee;
        LogSetDisputeFee(fee);
    }

    /// @notice Set a custom fee for this particular question
    /// @param question_id The question in question
    /// @param fee The fee amount
    function setCustomDisputeFee(bytes32 question_id, uint256 fee) 
        onlyOwner 
    public {
        custom_dispute_fees[question_id] = fee;
        LogSetCustomDisputeFee(question_id, fee);
    }

    /// @notice Return the dispute fee for the specified question. 0 indicates that we won&#39;t arbitrate it.
    /// @param question_id The question in question
    /// @dev Uses a general default, but can be over-ridden on a question-by-question basis.
    function getDisputeFee(bytes32 question_id) 
    public constant returns (uint256) {
        return (custom_dispute_fees[question_id] > 0) ? custom_dispute_fees[question_id] : dispute_fee;
    }

    /// @notice Set a fee for asking a question with us as the arbitrator
    /// @param realitycheck The RealityCheck contract address
    /// @param fee The fee amount
    /// @dev Default is no fee. Unlike the dispute fee, 0 is an acceptable setting.
    /// You could set an impossibly high fee if you want to prevent us being used as arbitrator unless we submit the question.
    /// (Submitting the question ourselves is not implemented here.)
    /// This fee can be used as a revenue source, an anti-spam measure, or both.
    function setQuestionFee(address realitycheck, uint256 fee) 
        onlyOwner 
    public {
        RealityCheckAPI(realitycheck).setQuestionFee(fee);
        LogSetQuestionFee(fee);
    }

    /// @notice Submit the arbitrator&#39;s answer to a question.
    /// @param realitycheck The RealityCheck contract address
    /// @param question_id The question in question
    /// @param answer The answer
    /// @param answerer The answerer. If arbitration changed the answer, it should be the payer. If not, the old answerer.
    function submitAnswerByArbitrator(address realitycheck, bytes32 question_id, bytes32 answer, address answerer) 
        onlyOwner 
    public {
        delete arbitration_bounties[question_id];
        RealityCheckAPI(realitycheck).submitAnswerByArbitrator(question_id, answer, answerer);
    }

    /// @notice Request arbitration, freezing the question until we send submitAnswerByArbitrator
    /// @dev The bounty can be paid only in part, in which case the last person to pay will be considered the payer
    /// Will trigger an error if the notification fails, eg because the question has already been finalized
    /// @param realitycheck The RealityCheck contract address
    /// @param question_id The question in question
    function requestArbitration(address realitycheck, bytes32 question_id) 
    external payable returns (bool) {

        uint256 arbitration_fee = getDisputeFee(question_id);
        require(arbitration_fee > 0);

        arbitration_bounties[question_id] += msg.value;
        uint256 paid = arbitration_bounties[question_id];

        if (paid >= arbitration_fee) {
            RealityCheckAPI(realitycheck).notifyOfArbitrationRequest(question_id, msg.sender);
            LogRequestArbitration(question_id, msg.value, msg.sender, 0);
            return true;
        } else {
            require(!RealityCheckAPI(realitycheck).isFinalized(question_id));
            LogRequestArbitration(question_id, msg.value, msg.sender, arbitration_fee - paid);
            return false;
        }

    }

    /// @notice Withdraw any accumulated fees to the specified address
    /// @param addr The address to which the balance should be sent
    function withdraw(address addr) 
        onlyOwner 
    public {
        addr.transfer(this.balance); 
    }

    function() 
    public payable {
    }

    /// @notice Withdraw any accumulated question fees from the specified address into this contract
    /// @param realitycheck The address of the Reality Check contract containing the fees
    /// @dev Funds can then be liberated from this contract with our withdraw() function
    function callWithdraw(address realitycheck) 
        onlyOwner 
    public {
        RealityCheckAPI(realitycheck).withdraw(); 
    }

}