/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity ^0.8.6;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address from, address to, uint value) external;
    function balanceOf(address who) external returns (uint);
    function allowance(address owner, address spender) external returns (uint);
}

contract SampleEliteFarmEthUsdt {
    address public owner;
    uint public invEthCurId=0;
    uint public invUsdCurId=0;
    uint public userCurId=0;
    IERC20 usdtInst;
    
    struct User {
        uint id;
        uint pk;
        bool exist;
        uint ttlEthInvts;
        uint ttlUsdtInvts;
        uint creationTime;
        Investment[] usrEthInvsts;
        Investment[] usrUsdInvsts;
    }
    
    struct Investment{
        bool exist;
        uint id;
        uint plan;
        uint amount;
        uint creationTime;
    }
    
    uint public ETH_TOTAL_INVESTMENT = 0;
    uint public USD_TOTAL_INVESTMENT = 0;
    
    mapping (address => uint) public actvEthTttlInvs;
    mapping (address => uint) public actvUsdTttlInvs;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public pkToAddress;
    mapping (uint => uint) public plansEth;
    mapping (uint => uint) public plansUsdt;
    mapping(address => User) private users;

    event ETHPlanBought(address user,uint amount);
    event USDTPlanBought(address user,uint amount);
    
    function withdrawEthBal(uint amt,address payable addr) onlyOwner public {
      require(amt<=address(this).balance,"balance is less than withdraw amount");
      addr.transfer(amt);
    }
    
    function withdrawUsdtBal(uint amt,address payable addr) onlyOwner public {
      require(amt<=getContractUsdtBalance(),"balance is less than withdraw amount");
      usdtInst.transfer(addr,amt);
    }
    
    function getContractEthBalance() public view returns(uint) {
      return address(this).balance;
    }
    
    function getContractUsdtBalance() public returns(uint) {
      return usdtInst.balanceOf(address(this));
    }
    
    function userDetails(address addr) view public returns(uint id,uint pk,bool exist, uint totalUsdtInv, uint totalEthInv,uint creationDate) {
      return (users[addr].id,users[addr].pk,users[addr].exist,users[addr].ttlUsdtInvts,users[addr].ttlEthInvts,users[addr].creationTime);
    }
    
    function getUserInvestmentIds(address addr,uint which) view public returns(uint[] memory) {
        require(users[addr].exist,"user not exist");
        Investment[] memory invArr;
        if(which==1){
            invArr = users[addr].usrEthInvsts;
        }else if(which==2){
            invArr = users[addr].usrUsdInvsts;
        }
        uint[] memory idArr = new uint[](invArr.length);
        for(uint i=0;i<invArr.length;i++){
            idArr[i] = invArr[i].id;
        }
        
        return idArr;
    }
    
    function getUserInvestmentById(address addr,uint invId,uint which) view public returns(bool exist,uint id,uint amount,uint creationDate) {
        require(users[addr].exist,"user not exist");
        Investment[] memory invArr;
        if(which==1){
            invArr = users[addr].usrEthInvsts;
        }else if(which==2){
            invArr = users[addr].usrUsdInvsts;
        }
        for(uint i=0;i<invArr.length;i++){
            if(invArr[i].id == invId){
                return (invArr[i].exist,invArr[i].id,invArr[i].amount,invArr[i].creationTime);
            }
        }
    }
    
    constructor(address conAddr) {
      usdtInst = IERC20(conAddr);
      owner = msg.sender;
      
      plansEth[1] = 0.03 ether;
      plansEth[2] = 0.19 ether;
      plansEth[3] = 0.39 ether;
      plansEth[4] = 1.95 ether;
      plansEth[5] = 3.91 ether;
      plansEth[6] = 19.53 ether;
      
      plansUsdt[1] = 100 ether;
      plansUsdt[2] = 500 ether;
      plansUsdt[3] = 1000 ether;
      plansUsdt[4] = 5000 ether;
      plansUsdt[5] = 10000 ether;
      plansUsdt[6] = 50000 ether;
    
    }
    
    modifier onlyOwner(){
        require(msg.sender==owner,"only owner can run this");
        _;
    }
    
    function saveEthInvestment(uint planId,uint invAmt,address addr) private returns (bool) {
         require(invAmt>0,"Amount sent is zero");
         ETH_TOTAL_INVESTMENT = ETH_TOTAL_INVESTMENT + invAmt;
         require (plansEth[planId]==invAmt,"Plan amount is not correct");
         
         if(!users[addr].exist){
            userCurId++;
            users[addr] = users[addr];
            users[addr].exist = true;
            users[addr].id = (block.timestamp/10000)+userCurId;
            users[addr].pk = userCurId;
            users[addr].creationTime = block.timestamp;
            
            idToAddress[(block.timestamp/10000)+userCurId] = addr;
            pkToAddress[userCurId] = addr;
         }
         
         invEthCurId++;
         
         Investment memory invObj1 = Investment({
            exist:true,
            id:invEthCurId,
            plan:planId,
            amount:invAmt,
            creationTime:block.timestamp
         });
         users[addr].ttlEthInvts = users[addr].ttlEthInvts + invAmt;
         actvEthTttlInvs[addr] = actvEthTttlInvs[addr] + invAmt;
          
         users[addr].usrEthInvsts.push(invObj1);
    
         emit ETHPlanBought(addr,invAmt);
         return true;
    }
    
    function saveUsdtInvestment(uint planId,address addr) private returns (bool) {
         uint invAmt = plansUsdt[planId];
         USD_TOTAL_INVESTMENT = USD_TOTAL_INVESTMENT + invAmt;
         
         if(!users[addr].exist){
            userCurId++;
            users[addr] = users[addr];
            users[addr].exist = true;
            users[addr].id = (block.timestamp/10000)+userCurId;
            users[addr].pk = userCurId;
            users[addr].creationTime = block.timestamp;
            
            idToAddress[(block.timestamp/10000)+userCurId] = addr;
            pkToAddress[userCurId] = addr;
         }
         
         invUsdCurId++;
         
         Investment memory invObj1 = Investment({
            exist:true,
            id:invUsdCurId,
            plan:planId,
            amount:invAmt,
            creationTime:block.timestamp
         });
         users[addr].ttlUsdtInvts = users[addr].ttlUsdtInvts + invAmt;
         actvUsdTttlInvs[addr] = actvUsdTttlInvs[addr] + invAmt;
          
         users[addr].usrUsdInvsts.push(invObj1);
    
         emit USDTPlanBought(addr,invAmt);
         return true;
    }
    
    function investETH(uint planId) payable public returns (bool){
        return saveEthInvestment(planId,msg.value,msg.sender);
    }
    
    function investUSDT(uint planId) public returns(bool){
        uint tknRecv = usdtInst.allowance(msg.sender,address(this));
        require(tknRecv>=plansUsdt[planId],"usdt amount not corerct");
        usdtInst.transferFrom(msg.sender, address(this), tknRecv);
        return saveUsdtInvestment(planId,msg.sender);
    }
    
}