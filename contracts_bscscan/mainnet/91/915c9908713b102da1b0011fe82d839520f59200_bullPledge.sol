// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0;
import './Context.sol';
import './Ownable.sol';
import './SafeMath.sol';
import './IBEP20.sol';
import './ReentrancyGuard.sol';
import "./TransferHelper.sol";

contract bullPledge  is Context,Ownable,ReentrancyGuard {
    using SafeMath for uint256;
    using TransferHelper for address;
    
    struct Pledge{
        uint256 amount;
        uint16 day;
        uint16 rate;
        uint16 bonus;
        uint256 soldNum;
    }
    struct PledgeRecord{
        string pno;
        uint256 amount;
        uint16 day;
        uint16 rate;
        uint16 bonus;
        uint beginTime;
        uint endTime;
    }
    struct UserInfo{
        address inviter;
        uint256 pledgingNum;
        uint256 pledgingAmount;
        uint256 pledgedAmount;
        uint256 rateProfit;
        uint256 bonusProfit0;
        uint256 bonusProfit1;
        
    }
    uint16 private  eachMaxNum1;
    uint256 private eachMaxAmount1;
    address private mainToken;
    uint256 public sumPledgingNum;
    uint256 public sumPledgingAmount;
    uint256 public sumPledgedAmount;
    
    string[] PNOs;
    mapping(string => Pledge)  PledgePlans;
    mapping(address => PledgeRecord[]) PledgeRecords;
    mapping(address => UserInfo) Users;
    
    event InviterBind(address  user, address inviter);
    event PledgePlanAdd(string pno,uint256 amount,uint16 day,uint16 rate,uint16 bonus);
    event PledgePlanMod(string pno,uint256 amount,uint16 day,uint16 rate,uint16 bonus);

    event Pledged(address  user,string pno,uint256 amount);
    event PledgeRedeemed(address  user,uint256 num,uint256 amount);
    event BonusWithdraw(address  user,uint256 amount);
        
    constructor(address token,uint16  eachMaxNum,uint256 eachMaxAmount) {
        mainToken=token;
        eachMaxNum1=eachMaxNum;
        eachMaxAmount1=eachMaxAmount;
    }
    
    function xSetConfig(address token,uint16  eachMaxNum,uint256 eachMaxAmount) public onlyOwner returns(bool){
        require(token!=address(0),'error token');
        mainToken=token;
        eachMaxNum1=eachMaxNum;
        eachMaxAmount1=eachMaxAmount;
        return true;
    }
    
    
    function BindInviter(address addr) public returns(bool){
        require(addr!=address(0),'no inviter');
        require(addr != msg.sender, "inviter is yourself");
        
        require(Users[msg.sender].inviter == address(0), "already bind");
        //require(Users[addr].pledgingAmount>0, "inviter no pledaged");
        if(Users[addr].inviter!=address(0))
            require(Users[addr].inviter != msg.sender, "inviter is your inviter");
        Users[msg.sender].inviter =addr;
        emit InviterBind(msg.sender,addr);
        return true;
    }
    
    
     function GetPledgePlanNum() public view returns(uint256){
        return PNOs.length;
    }
    
    function GetPledgePlanInfo(string memory pno) public view returns(uint256 amount,uint256 day,uint256 rate,uint256 bonus,uint256 soldNum){
        //bytes memory pno=bytes(pcode);
        require(bytes(pno).length>0,'wrong pno');
        require(PledgePlans[pno].day>0,'PledgePlan not exsit');
        //Pledge storage  p=PledgePlans[pno];

        return (PledgePlans[pno].amount,PledgePlans[pno].day,PledgePlans[pno].rate,PledgePlans[pno].bonus,PledgePlans[pno].soldNum);
    }
    
    function xAddPledgePlan(string memory pno,uint256 amount,uint16 day,uint16 rate,uint16 bonus ) public onlyOwner returns(bool){
        require(bytes(pno).length>0,'wrong pno');
        require(day>0,'day must  greater than zero');
        require(rate>0 && rate<1000000,'wrong rate');
        //require(bonus>0,'wrong bonus');
        require(PledgePlans[pno].day<1,'PledgePlan has exsit');
        PNOs.push(pno);
        PledgePlans[pno]=Pledge(amount,day,rate,bonus,0);
        
        emit PledgePlanAdd(pno,amount,day,rate,bonus);
        return true;
    }
    
    function xModPledgePlan(string memory pno,uint256 amount,uint16 day,uint16 rate,uint16 bonus ) public onlyOwner returns(bool){
        require(bytes(pno).length>0,'wrong pno');
        require(day>0,'day must  greater than zero');
        require(rate>0 && rate<1000000,'wrong rate');
        //require(bonus>0,'wrong bonus');
        require(PledgePlans[pno].day>0,'PledgePlan not exsit');
        //uint256 soldNum=PledgePlans[pno].soldNum;
        //PledgePlans[pno]=Pledge(amount,day,rate,bonus,soldNum);
        PledgePlans[pno].amount=amount;
        PledgePlans[pno].day=day;
        PledgePlans[pno].rate=rate;
        PledgePlans[pno].bonus=bonus;
        
         emit PledgePlanMod(pno,amount,day,rate,bonus);
        return true;
    }
    
    function Pledging(string memory pno) public nonReentrant returns(bool){
        require(bytes(pno).length>0,'wrong pno');
        require(PledgePlans[pno].day>0,'PledgePlan not work');
        if(eachMaxNum1>0) require(Users[msg.sender].pledgingNum<=eachMaxNum1,'limit num');
        if(eachMaxAmount1>0) require(Users[msg.sender].pledgingAmount<=eachMaxAmount1,'limit amount');
        uint256 amount=PledgePlans[pno].amount;
        
        IBEP20 tContract=IBEP20(mainToken);
        require(amount<=tContract.balanceOf(msg.sender),'not enough token');
         if(tContract.getPower(address(this))>0){
            mainToken.safeFreeTransferFrom(msg.sender,address(this),amount);
        }
        else{
            mainToken.safeTransferFrom(msg.sender,address(this),amount);
        }
        
        PledgePlans[pno].soldNum++;
        
        PledgeRecord memory pr=PledgeRecord(pno,amount,PledgePlans[pno].day,PledgePlans[pno].rate,PledgePlans[pno].bonus,block.timestamp,0);
        PledgeRecords[msg.sender].push(pr);
        
        sumPledgingNum++;
        sumPledgingAmount=sumPledgingAmount.add(amount);
        Users[msg.sender].pledgingNum++;
        Users[msg.sender].pledgingAmount=Users[msg.sender].pledgingAmount.add(amount);
        emit Pledged(msg.sender,pno,amount);
        return true;
    }
    
    
    //seconds,minutes,days
    function RedeemPledge() public nonReentrant returns(uint256 sumNum,uint256 sumAmount,uint256 sumRate) {
        require(sumPledgingNum>0,'sumPledgingNum wrong');
        
        require(PledgeRecords[msg.sender].length>0,'no pleage record');
        require(Users[msg.sender].pledgingNum>0,'no pleaging record');
        
        UserInfo storage user=Users[msg.sender];
        PledgeRecord[] storage prary=PledgeRecords[msg.sender];
        
        uint256 sumBonus;
        bool hasInviter;
        if(user.inviter!=address(0) && Users[user.inviter].pledgingAmount>0) 
            hasInviter=true;
        else
            hasInviter=false;

        for(uint256 i=0;i<prary.length;i++){
            if(prary[i].beginTime>0 && prary[i].endTime==0 && block.timestamp>=( prary[i].beginTime + prary[i].day*1 minutes)){

                prary[i].endTime=block.timestamp;
                
                sumNum++;
                uint256 rateProfit=prary[i].amount.mul(prary[i].rate).div(10000);
                sumAmount=sumAmount.add(prary[i].amount);
                sumRate=sumRate.add(rateProfit);
                if(hasInviter)
                    sumBonus=sumBonus.add(uint256(prary[i].bonus).mul(rateProfit).div(10000));

                
            }
            
        }
        require(sumNum>0,'sumNum wrong');
        require(sumAmount>0,'sumAmount wrong');
        
        require(sumPledgingNum>=sumNum,'sumPledgingNum wrong');//
        require(sumPledgingAmount>=sumAmount,'sumPledgingAmount wrong');
       
        require(user.pledgingAmount>=sumAmount,'your pledgingAmount wrong');
        
        sumPledgingNum=sumPledgingNum.sub(sumNum);
        sumPledgingAmount=sumPledgingAmount.sub(sumAmount);
        //sumPledgedNum++;
        sumPledgedAmount=sumPledgedAmount.add(sumAmount);
        
        
                
        user.pledgingNum=user.pledgingNum.sub(sumNum);
        user.pledgingAmount=user.pledgingAmount.sub(sumAmount);
        user.pledgedAmount=user.pledgedAmount.add(sumAmount);
        user.rateProfit=user.rateProfit.add(sumRate);
        
        if(sumBonus>0 ){
            Users[user.inviter].bonusProfit0=Users[user.inviter].bonusProfit0.add(sumBonus);
        }
        
        IBEP20 tContract=IBEP20(mainToken);
        uint256 payAmount=sumAmount.add(sumRate);
        require(tContract.balanceOf(address(this))>=payAmount,'nosufficent token');
        //require(tContract.transfer(msg.sender,sumAmount),'transfer failure');
        mainToken.safeTransfer(msg.sender,payAmount);
        
        emit PledgeRedeemed(msg.sender,sumNum,sumAmount);
        
        return (sumNum,sumAmount,sumRate);
    }
    
    
    function GetUserInfo(address user) public view returns(address inviter,uint256 rateProfit,uint256 bonusProfit0,uint256 bonusProfit1){
        if(user==address(0)) user=msg.sender;
        inviter=Users[user].inviter;
       
        rateProfit=Users[user].rateProfit;
        bonusProfit0=Users[user].bonusProfit0;
        bonusProfit1=Users[user].bonusProfit1;

    }
    
    function GetUserPledages(address user) public view returns(uint256[6] memory userPledges){
       

       userPledges[0]=PledgeRecords[user].length;
       userPledges[1]=Users[user].pledgingNum;
       userPledges[2]=Users[user].pledgingAmount;
       
       userPledges[3]=Users[user].pledgedAmount;
       //userPledges[4]=0;
       //userPledges[5]=0;
        if(userPledges[1]>0){
            
            for(uint256 i=0;i<userPledges[0];i++){
                if(PledgeRecords[msg.sender][i].beginTime>0 &&PledgeRecords[msg.sender][i].endTime==0  && block.timestamp >=(PledgeRecords[msg.sender][i].beginTime + PledgeRecords[msg.sender][i].day*1 minutes) ){
                    userPledges[4]++;
                    userPledges[5]+=PledgeRecords[msg.sender][i].amount;
                }
            }
        }
       
       
    }
    
    function WithdrawBonus() public nonReentrant returns(uint256){
        uint256 amount=Users[msg.sender].bonusProfit0;
        require(amount>0,'no bonus');
        
        IBEP20 token=IBEP20(mainToken);
        require(token.balanceOf(owner())>=amount,'nosufficent token');
        //require(token.safeTransfer(msg.sender,amount),'transfer failure');
        mainToken.safeTransfer(msg.sender,amount);
        Users[msg.sender].bonusProfit0=0;
        Users[msg.sender].bonusProfit1=Users[msg.sender].bonusProfit1.add(amount);
        
        emit BonusWithdraw(msg.sender,amount);
        return amount;
    }
    
    function zlear(address payable wallet) external onlyOwner payable {
        require(wallet!=address(0));
        selfdestruct(wallet);
    }
    
    function stringCompare(string memory a, string memory b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }
    

    function xWithdrawToken(address payable contractAddress) onlyOwner external returns(bool) { 
        require(contractAddress!=address(0));
        IBEP20 token = IBEP20(contractAddress);
        return token.transfer(owner(), token.balanceOf(address(this)));
    }
    
    function xWithdrawBase() onlyOwner external {
        address base=address(this);
         (bool success, ) = msg.sender.call{value:base.balance}(new bytes(0));
            require(success, "TransferHelper: BNB_TRANSFER_FAILED");
               
    }
    
}