/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity ^0.7.0;

contract HelloBlockchain
{
     //Set of States
    enum StateType { Request, Respond }

    //List of properties
    StateType public  State;
    address public  Requestor;
    address public  Responder;

    string public RequestMessage;
    string public ResponseMessage;

    event StateChanged(string stateData);

    // constructor function
    constructor(string memory message)
    {
        RequestMessage = message;
        State = StateType.Request;

        emit StateChanged('Request');
    }

    // call this function to send a request
    function SendRequest(string memory requestMessage) public
    {
        Requestor = msg.sender;

        RequestMessage = requestMessage;
        State = StateType.Request;
    }

    // call this function to send a response
    function SendResponse(string memory responseMessage) public
    {
        Responder = msg.sender;

        // call ContractUpdated() to record this action
        ResponseMessage = responseMessage;
        State = StateType.Respond;

        emit StateChanged('Response');
    }
}