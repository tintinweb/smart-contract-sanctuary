pragma solidity ^0.4.21;

import "./FlashLoanReceiver.sol";
import "./CNSToken.sol";

contract HW3 {
    address owner;
    CNSToken cnsToken;
    address public tokenAddr;
    struct Student {
        mapping (uint => bool) solved;
        uint score;
    }

    // studentID: lowercase and number. ex: b02902055
    mapping (string => Student) students;

    // challenge 0: call me, 10 points
    function callMeFirst(string studentID) public {
        uint challengeID = 0;
        uint point = 10;
        require(students[studentID].solved[challengeID] != true);

        students[studentID].solved[challengeID] = true;
        students[studentID].score += point;
    }

    // challenge 1: bribe me ether, 20 points
    function bribeMe(string studentID) public payable {
        uint challengeID = 1;
        uint point = 20;
        require(students[studentID].solved[challengeID] != true);
        require(msg.value == 1 ether);
        students[studentID].solved[challengeID] = true;
        students[studentID].score += point;
    }

    // challenge 2: guess random number, 50 points
    uint16 c2Ans;
    function guessRandomNumber(string studentID, uint16 numberGuessed) public {
        uint challengeID = 2;
        uint point = 50;
        require(students[studentID].solved[challengeID] != true);
        
        if (numberGuessed != c2Ans) {
            return;
        }
        students[studentID].solved[challengeID] = true;
        students[studentID].score += point;
    }
    
    // challenge 3: easy reentry, 70 points
    uint16 c3Flag = 0; 
    function reentry(string studentID) public{
        uint challengeID = 3;
        uint point = 70;
        require(students[studentID].solved[challengeID] != true);
        c3Flag += 1;
        msg.sender.call.value(0)();
        if(c3Flag == 2){
            students[studentID].solved[challengeID] = true;
            students[studentID].score += point;
        }
        c3Flag = 0;
    }
    
    // bonus : prove that you have enough cns tokens by using flash loan! 100point
    
    uint8 public flashloaning = 0;
    function flashloan(uint256 amount) public{
        require(amount <= cnsToken.balanceOf(address(this)));
        flashloaning += 4;
        cnsToken.transfer(msg.sender,amount);
        require(IFlashLoanReceiver(msg.sender).execute(address(cnsToken), address(this), amount),"Flash loan execute error!");
        require(cnsToken.transferFrom(msg.sender,address(this),amount),"You need to return fund!");
        flashloaning -= 4;
    }
    
    function bonus_verify(string studentID) public{
        uint challengeID = 4;
        uint point = 100;
        require(flashloaning == 0,"You are doing flashloan!");
        require(students[studentID].solved[challengeID] != true);
        if(cnsToken.balanceOf(msg.sender) >= 10000){
            students[studentID].solved[challengeID] = true;
            students[studentID].score += point;
            // give you one CNS token as reward!
            cnsToken.transfer(msg.sender,1);
        }
    }

    function getScore(string studentID) view public returns (uint) {
        return students[studentID].score;
    }
    
    function getSolvedStatus(string studentID) view public returns (bool[]) {
        bool[] memory ret = new bool[](4);
        for(uint i=0;i<4;i++){
            ret[i] = students[studentID].solved[i];
        }
        return ret;
    }
    
    function setTokenAddr(address CNS_addr) public{
        require(msg.sender == owner);
        tokenAddr = CNS_addr;
        cnsToken = CNSToken(CNS_addr);
    }

    constructor() public {
        owner = msg.sender;
        c2Ans = uint16(keccak256(blockhash(block.number - 1), block.timestamp));
    }
    
    function destroy()
    public
    {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}