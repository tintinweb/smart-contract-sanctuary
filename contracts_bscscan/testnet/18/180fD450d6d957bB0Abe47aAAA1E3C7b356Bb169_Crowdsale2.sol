/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

pragma solidity ^0.4.24;

interface token{
    function transfer(address receiver, uint amount) external;
}

contract Crowdsale2{
    
    uint public hardcap;
    uint public softcap;
    bool public softcapReached = false;
    bool public crowdsaleClosed = false;
    uint public roomLeft;
    address public beneficiary;
    uint public amountRaised;
    uint public startTime;
    uint public endTime;
    uint public price;
    token public tokenReward;
    uint public decimals;
    address public moonscout = 0xBFa909483f41CCE0eD149f0CCC526350B892a9DE;
    uint clientShare;
    uint moonscoutShare;
    mapping(address => uint256) public balanceOf;
    
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    constructor(
        uint hardcapInBNB,
        uint softcapInBNB,
        address beneficiaryAddress,
        uint startTimeTimestamp,
        uint endTimeTimestamp,
        uint tokensPerBNB,
        address addressOfTokenUsedAsReward,
        uint coinDecimals
    ) public {
        hardcap = hardcapInBNB * 1000000000 wei;
        softcap = softcapInBNB * 1000000000 wei;
        roomLeft = hardcapInBNB * 1000000000 wei;
        beneficiary = beneficiaryAddress;
        startTime =  startTimeTimestamp;
        endTime = endTimeTimestamp;
        price = 1000000000 wei / 10**coinDecimals / tokensPerBNB;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
    function () payable public {
        require(now > startTime && now < endTime && amountRaised < hardcap && msg.value <= roomLeft);
        roomLeft = roomLeft - msg.value;
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
    }
    
    modifier afterDeadline(){
        if(now >= endTime || amountRaised == hardcap) _;
    }
    
    function checkGoalReached() public afterDeadline {
        if(amountRaised >= softcap && now >= endTime){
            softcapReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }
    
    function safeWithdrawal() public afterDeadline{
        //if funding goal didnt reach return BNB to backer
        if(!softcapReached && msg.sender != beneficiary && crowdsaleClosed){
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if(amount > 0){
                if(msg.sender.send(amount)){
                    emit FundTransfer(msg.sender, amount, false);
                }else {
                    balanceOf[msg.sender] = amount;
                }
            }
        } 
        //if funding goal did reach return tokens to backer
        else if(softcapReached && msg.sender != beneficiary && crowdsaleClosed){
            tokenReward.transfer(msg.sender, balanceOf[msg.sender]/price);
            emit FundTransfer(msg.sender, amount, true);
            balanceOf[msg.sender] = 0;
        }
        
        //if funding goal did reach return BNB to beneficiary
        if(softcapReached && beneficiary == msg.sender && crowdsaleClosed){
            clientShare = amountRaised / 20 * 19;
            moonscoutShare = amountRaised / 20;
            if(beneficiary.send(clientShare)){
                emit FundTransfer(beneficiary, clientShare, false);
                if(moonscout.send(moonscoutShare)){
                    emit FundTransfer(moonscout, moonscoutShare, false);
                }
            }
        }
    }
}