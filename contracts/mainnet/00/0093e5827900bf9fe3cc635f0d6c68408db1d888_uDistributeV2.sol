/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity ^0.8.0;

abstract contract ERC20 {
    function balanceOf(address who) public virtual view returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
}

contract uDistributeV2 {

   struct distribution{
        uint tokenIndex;        //token Index
        uint recipientIndex;      //recipient
        uint p;                 //period
        uint a;                 //amount per period
        uint touchpoint;        //Withdrawal touch point, when the initial waiting period has ended, or the last withdrawal has occured
        uint totalAmount;       //totalAmount Distributed
    }

    event Distribution(address token,address distributor,address recipient,uint256 index,uint256 amount,string description);
	event Withdrawal(address token,address recipient,uint256 index,uint256 amount);

    mapping(uint => distribution[]) public distributions;

    mapping(address => uint) public recipientIndexes;
    address[] public recipientList;

    mapping(address => uint) public tokenIndexes;
    address[] public tokenList;

    constructor() {
        tokenList.push(address(0));
        tokenIndexes[0x92e52a1A235d9A103D970901066CE910AAceFD37] = 1;
        tokenList.push(0x92e52a1A235d9A103D970901066CE910AAceFD37);
        recipientList.push(address(0));
    }

    function distribute(address token, address recipient,uint waitTime, uint period, uint amountPerPeriod, uint amount, string memory description) public{
        ERC20(token).transferFrom(msg.sender,address(this),amount);

        uint touchPoint = block.timestamp + waitTime;

        uint rIndex = _getRecipientIndex(recipient);

        emit Distribution(token,msg.sender,recipient,numDistributions(recipient),amount,description);

        distributions[rIndex].push(distribution(
            getTokenIndex(token),
            rIndex,
            period,
            amountPerPeriod,
            touchPoint,
            amount)
        );
    }

    function withdraw(uint index) public {
        distribution memory d = distributions[getRecipientIndex(msg.sender)][index];
        require(index<numDistributions(msg.sender), "Requested distribution does not exist");
        uint toWithdraw = getWithdrawable(msg.sender,index);
        require(block.timestamp>=d.touchpoint, "waiting period is not over yet");
        require(toWithdraw>0,"Nothing to Withdraw");

        ERC20(tokenList[d.tokenIndex]).transfer(msg.sender,toWithdraw);

        distributions[getRecipientIndex(msg.sender)][index].touchpoint = block.timestamp;
        distributions[getRecipientIndex(msg.sender)][index].totalAmount -= toWithdraw;

        emit Withdrawal(tokenList[d.tokenIndex],msg.sender,index,toWithdraw);
    }

    function getWithdrawable(address recipient,uint index) public view returns (uint){
        distribution memory d = distributions[getRecipientIndex(recipient)][index];
        uint toWithdraw;
        uint elapsedPeriods;

        if(block.timestamp<d.touchpoint){
            return(0);
        }

        elapsedPeriods = (block.timestamp - d.touchpoint)/d.p;

        if(elapsedPeriods<=0){
            return(0);
        }

        toWithdraw = d.a*elapsedPeriods;

        if(toWithdraw>d.totalAmount){
            return(d.totalAmount);
        }

        return(toWithdraw);
    }

    function getRecipientIndex(address recipient) public view returns(uint){
        return(recipientIndexes[recipient]);
    }

    function _getRecipientIndex(address recipient) internal returns(uint){
        if (recipientIndexes[recipient]==0){
            recipientIndexes[recipient]= recipientList.length;
            recipientList.push(recipient);
        }
        return(recipientIndexes[recipient]);
    }

    function getTokenIndex(address token) internal returns(uint){
        if (tokenIndexes[token]==0){
            tokenList.push(token);
            tokenIndexes[token]= tokenList.length;
        }
        return(tokenIndexes[token]);
    }

    function numDistributions(address recipient) public view returns(uint) {
        return distributions[getRecipientIndex(recipient)].length;
    }
}