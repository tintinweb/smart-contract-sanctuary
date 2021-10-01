/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// SPDX-License-Identifier: MIT

//      About
//      QueenBeeFinance, headquartered in Singapore and established in 2020, is a private fund team focusing on DEFI.

//      Website
//          https://www.queenbee.finance/

//      Contact Us 
//          Cooperate: [email protected]
//          Help: [email protected]

pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Fund {
    function invest(address investToken,uint256 investAmount)external ; 
    function redeem(address investToken,uint256 redeemAmount)external;
    
}
contract QueenBeeFinance_PrivateFund_V3{
    address public owner;
    address public fundAddress;
    address public fundCallAddress;    
    bool public statusForFundAddressCalling;
    mapping (address=> mapping (address => uint256)) public userInvestAmount;//user-token-amount
    mapping (address=> mapping (address => uint256)) public userRewardDebt;//user-token-amount
    mapping (address=>uint256) public rewardAccumulatedPerToken;//token-amount
    mapping (address=>uint256) public lastRewardUpdateTime;//token-time    
    mapping (address=>uint256) public totalInvestAmount;//token-amount
    mapping (address=>uint256) public perSecondRateForPerToken;//token-amount   
    mapping (address=>bool) public receiveTokenList;//token-status    
    constructor () {
        owner=msg.sender;
        fundAddress=msg.sender;
    }
    
    function invest(address investToken,uint256 investAmount)external {
        require(receiveTokenList[investToken]==true,"investToken not support");
        harvest(msg.sender,investToken);
        IERC20(investToken).transferFrom(msg.sender,address(this),investAmount);
        IERC20(investToken).transfer(fundAddress,investAmount);
        userInvestAmount[msg.sender][investToken]+=investAmount;
        totalInvestAmount[investToken]+=investAmount;
        
        
        if(statusForFundAddressCalling==true){
            Fund(fundCallAddress).invest(investToken,investAmount);
        }
    }
    
    
    function redeem(address investToken,uint256 redeemAmount)external {
        require(receiveTokenList[investToken]==true,"investToken not support");        
        require(userInvestAmount[msg.sender][investToken]>=redeemAmount,"exceed invest amount");
        harvest(msg.sender,investToken);
        if(statusForFundAddressCalling==true){
            Fund(fundCallAddress).redeem(investToken,redeemAmount);
        }        
        IERC20(investToken).transferFrom(fundAddress,address(this),redeemAmount);
        IERC20(investToken).transfer(msg.sender,redeemAmount);
        userInvestAmount[msg.sender][investToken]-=redeemAmount;
        totalInvestAmount[investToken]-=redeemAmount;
        
    }
    
    function harvest(address user,address investToken)public{
        require(receiveTokenList[investToken]==true,"investToken not support");        
         rewardUpdate( investToken);
         uint256 claimableSingle=rewardAccumulatedPerToken[investToken]-userRewardDebt[user][investToken];
         uint256 claimable=claimableSingle*userInvestAmount[user][investToken]/1e18;
         IERC20(investToken).transferFrom(fundAddress,address(this),claimable);
         IERC20(investToken).transfer(user,claimable);
         userRewardDebt[user][investToken]=rewardAccumulatedPerToken[investToken];
    }
    
    function claimableReward(address user,address investToken)public view returns(uint256 _claimable){
         uint256 claimableSingle=rewardAccumulatedPerToken[investToken]-userRewardDebt[user][investToken];
         _claimable=claimableSingle*userInvestAmount[user][investToken]/1e18;        
        
    }
    
    function rewardUpdate(address investToken)public{
        require(receiveTokenList[investToken]==true,"investToken not support");        
        if(lastRewardUpdateTime[investToken]==0){
            lastRewardUpdateTime[investToken]=block.timestamp;
        }else{
            rewardAccumulatedPerToken[investToken]+=perSecondRateForPerToken[investToken]*(block.timestamp-lastRewardUpdateTime[investToken]);
            lastRewardUpdateTime[investToken]=block.timestamp;
        }
    }
        
    function setRewardAccumulatedPerToken(address investToken,uint256 value)public {
        require(msg.sender==owner,"!owner");
        rewardAccumulatedPerToken[investToken]+=value;
    }
    
    function setPerSecondRateForPerToken(address investToken,uint256 value)public {
        require(msg.sender==owner,"!owner");
        perSecondRateForPerToken[investToken]=value;
    }
                
    function emergencySetRewardAccumulatedPerToken(address investToken,uint256 value)public {
        require(msg.sender==owner,"!owner");
        rewardAccumulatedPerToken[investToken]=value;
    }
    function setfundAddress(address _fundAddress,bool _statusForFundAddressCalling)public {
        require(msg.sender==owner,"!owner");
        fundCallAddress=_fundAddress;
        statusForFundAddressCalling=_statusForFundAddressCalling;
    }    
    function setReceiveTokenList(address _receiveToken,bool _status)public {
        require(msg.sender==owner,"!owner");
        receiveTokenList[_receiveToken]=_status;
    }        
    
    function inCaseTokensGetStuck(address withdrawaddress,address _token,uint _amount)  public  {

        require(msg.sender == owner, "!governance");
 
        require(withdrawaddress != address(0), "WITHDRAW-ADDRESS-REQUIRED");  
        IERC20(_token).transfer(withdrawaddress, _amount);
    }
         
    
}