/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity ^0.8.1;

contract PAL {
    
    address payable admin; 
    event PointUpdate (address studentAddress, int change, Reason  reason, string contentHash, string facilitatorHash);
    mapping (address => int) public pointBalancesMap;
    enum Reason {GETPVOTE, BESTANSWER, REPORT, DOWNVOTEUNDONE, GETDOWNVOTE, GIVEDOWNVOTE, MISREPORT,
    UPVOTEUNDONE, REPORTED}
    
    mapping (Reason => int) public pointChangesMap;
    
    constructor () {
        admin = payable(msg.sender);
        pointChangesMap[Reason.GETPVOTE] = 100;
        pointChangesMap[Reason.BESTANSWER] = 150;
        pointChangesMap[Reason.REPORT] = 50;
        pointChangesMap[Reason.DOWNVOTEUNDONE] = 100;
        pointChangesMap[Reason.GETDOWNVOTE] = -20;
        pointChangesMap[Reason.GIVEDOWNVOTE] = -10;
        pointChangesMap[Reason.MISREPORT] = -20;
        pointChangesMap[Reason.UPVOTEUNDONE] = -100;
        pointChangesMap[Reason.REPORTED] = -1000;
    }
    
    modifier onlyAdmin { 
        require(msg.sender == admin, "Only admin is allowed to perform this function.");
        _;
    }
    
    
    function destroyContract () public onlyAdmin {
        selfdestruct (admin);
    }
    
    
    function updatePointBalance (address _student, Reason _reason, string memory _contentHash, string memory _facilitatorHash) public onlyAdmin {
        int pointChange = pointChangesMap[_reason];
        int balance = pointBalancesMap[_student];
        balance += pointChange;
        if (balance < - 1000){
            pointBalancesMap[_student] = -1000;
        } else {
            pointBalancesMap[_student] = balance;
        }
        emit PointUpdate(_student, pointChange, _reason, _contentHash, _facilitatorHash);
    }
    
    
}