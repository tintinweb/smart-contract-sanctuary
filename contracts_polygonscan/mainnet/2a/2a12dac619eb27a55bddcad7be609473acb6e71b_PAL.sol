/**
 *Submitted for verification at polygonscan.com on 2021-08-30
*/

pragma solidity ^0.5.7;

contract PAL {
    
    address payable admin; //address that deploys the contract
    //events for recording the details of point balance updates
    event PointUpdate (address studentAddress, int change, Reason  reason, string contentHash, string facilitatorHash);
    //stores the point balances of users
    mapping (address => int) public pointBalancesMap;
    //reasons of point balance change encoded as enums for 
    enum Reason {GET_UPVOTE, BEST_ANSWER, REPORT, DOWNVOTE_RECEIVED_UNDONE, DOWNVOTE_GIVEN_UNDONE, GET_DOWNVOTE, GIVE_DOWNVOTE,
    MISREPORT, UPVOTE_RECEIVED_UNDONE, REPORTED}
    //stores how the point balance will change with different reasons
    mapping (int => int) public pointChangesMap;
    
    //Initially, deploys the contract and record the logic of point balance change
    constructor () public  {
        admin = msg.sender;
        pointChangesMap[(int)(Reason.GET_UPVOTE)] = 20;
        pointChangesMap[(int)(Reason.BEST_ANSWER)] = 150;
        pointChangesMap[(int)(Reason.REPORT)] = 20;
        pointChangesMap[(int)(Reason.DOWNVOTE_RECEIVED_UNDONE)] = 20;
        pointChangesMap[(int)(Reason.DOWNVOTE_GIVEN_UNDONE)] = 5;
        pointChangesMap[(int)(Reason.GET_DOWNVOTE)] = -20;
        pointChangesMap[(int)(Reason.GIVE_DOWNVOTE)] = -5;
        pointChangesMap[(int)(Reason.MISREPORT)] = -20;
        pointChangesMap[(int)(Reason.UPVOTE_RECEIVED_UNDONE)] = -20;
        pointChangesMap[(int)(Reason.REPORTED)] = -1000;
    }
    
    //make sure only the admin address (our address) can call the contract
    modifier onlyAdmin { 
        require(msg.sender == admin, "Only admin is allowed to perform this function.");
        _;
    }
    
    //a function for the admin to destroy the contract
    function destroyContract () public onlyAdmin {
        selfdestruct (admin);
    }
    
    //this function called is whenever a user's virtual point balance changes
    function updatePointBalance (address _student, Reason _reason, string memory _contentHash, string memory _facilitatorHash) public onlyAdmin {
        int pointChange = pointChangesMap[(int)(_reason)]; //determine how many points to be gained/ lost from the reason
        int balance = pointBalancesMap[_student]; //Calcualte the new virtual balance
        balance += pointChange;
        if (balance < - 1000){
            pointBalancesMap[_student] = -1000;
        } else {
            pointBalancesMap[_student] = balance; //if the value does not fall below -1000, update the balance to this value
        }
        //trigger the event for recording the details of the point balance update
        emit PointUpdate(_student, pointChange, _reason, _contentHash, _facilitatorHash); 
    }
    
    function updatePointsLogic (Reason _reason, int _change) public onlyAdmin {
        pointChangesMap[(int)(_reason)] = _change;
    }
    
    function verifyWalletAddress (address _address) public onlyAdmin {
        
    }
    
}