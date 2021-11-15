pragma solidity 0.8.6;

interface IRealitio {
  function notifyOfArbitrationRequest ( bytes32 question_id, address requester, uint256 max_previous ) external;

  function isFinalized(bytes32 question_id) view external returns (bool);

  function submitAnswerByArbitrator ( bytes32 question_id, bytes32 answer, address answerer ) external;
  
  function assignWinnerAndSubmitAnswerByArbitrator( bytes32 question_id, bytes32 answer, address payee_if_wrong, bytes32 last_history_hash, bytes32 last_answer_or_commitment_id, address last_answerer ) external;
}


contract Arbitrator {
    IRealitio public realitio;

    /// @notice Set the Reality Check contract address
    /// @param addr The address of the Reality Check contract
    function setRealitio(address addr) public {
        realitio = IRealitio(addr);
    }

    /// @notice Request arbitration, freezing the question until we send submitAnswerByArbitrator
    /// @dev The bounty can be paid only in part, in which case the last person to pay will be considered the payer
    /// Will trigger an error if the notification fails, eg because the question has already been finalized
    /// @param question_id The question in question
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    function requestArbitration(bytes32 question_id, uint256 max_previous) 
    external payable returns (bool) {
        require(!realitio.isFinalized(question_id), "The question must not have been finalized");
        realitio.notifyOfArbitrationRequest(question_id, msg.sender, max_previous);
        return true;
    }

    /// @notice Submit the arbitrator's answer to a question.
    /// @param question_id The question in question
    /// @param answer The answer
    /// @param answerer The answerer. If arbitration changed the answer, it should be the payer. If not, the old answerer.
    function submitAnswerByArbitrator(bytes32 question_id, bytes32 answer, address answerer)  
    public {
        realitio.submitAnswerByArbitrator(question_id, answer, answerer);
    }
}

