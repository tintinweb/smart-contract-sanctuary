pragma solidity ^0.5.0;

import "./Crowdsale.sol";
import "./AllowanceCrowdsale.sol";
import "./PausableCrowdsale.sol";

contract RDaoPausableCrowdsaleContract is Crowdsale, AllowanceCrowdsale, PausableCrowdsale {
    
    constructor(
        uint256 rate,           
        address payable wallet, 
        address payable taddress,
        IERC20 token,           
        address tokenWallet
    )
        AllowanceCrowdsale(tokenWallet)
        Crowdsale(rate, wallet, token)
        public
    {
        _tAddress =  taddress;
    }
    
    modifier onlyOwner() {
        require(_msgSender() == wallet(), "presale: caller is not admin");
        _;
    }

    mapping(address => uint256) public adminBalance;
    uint256 public firstRewardQuota = 20;
    uint256 public mWeiToWeiUnit = 1 ether;
    uint256 public minVestAmount = 10 finney;
    uint256 public maxVestAmount = 500 ether;
    uint256 public stepNum = 700000 ether;
    
    uint256 private sellAmount;
    uint256[30] private allRates = [1107,1030,958,890,828,770,716,666,620,576,536,498,463,431,401,373,347,322,300,279,259,241,224,209,194,180,168,156,145,135];
    address payable private _tAddress;

    event adminWithdrawReward(address to,uint amount);
    event userWithdrawReward(address to,uint amount);
    struct Invest{
        address userAddress;
        address inviteUser;
        uint256 buyTokenNum;
        uint256 rewardBalance;
        bool isVaild;
    }
    mapping (address => Invest ) private investMapping;
    mapping (address => address[]) private userInvitees;
    Invest[] public inverts ;
    
    function () external payable {
        investBuyToken(address(0));
    }

    function investBuyToken(address inviteUserAddress) public  payable{
        require(inviteUserAddress != _msgSender(),"presale: inviteAddress not equals msgSender ");
        uint256 weiAmount = msg.value;
        require(weiAmount >= minVestAmount, "presale: minVestAmount is 10 finney ");
        require(weiAmount <= maxVestAmount, "presale: maxVestAmount is 500 ether ");
        address buyUser = msg.sender;
        Invest storage buyInvest = investMapping[buyUser];
        uint256 tokens =  super.buyTokens(buyUser,weiAmount);
       sellAmount = sellAmount.add(tokens);
       if(!buyInvest.isVaild){
           uint256 lastBalance = weiAmount;
           if(inviteUserAddress != address(0)){
                Invest storage investUser =  investMapping[inviteUserAddress];
                if(investUser.isVaild){
                    lastBalance = _depositReward(inviteUserAddress,weiAmount);
                }else{
                    uint256 firstReward = weiAmount.div(firstRewardQuota);
                    Invest memory inviter = Invest(inviteUserAddress,address(0),0,firstReward,true);
                    investMapping[inviteUserAddress] = inviter;
                    inverts.push(inviter);
                    lastBalance = weiAmount.sub(firstReward);
                }
                Invest memory invest = Invest(buyUser,inviteUserAddress,tokens,0,true);
                investMapping[buyUser] = invest;
                inverts.push(invest);
                 _updateUserInvitees(inviteUserAddress,buyUser);
           }else{
               Invest memory invest = Invest(buyUser,address(0), tokens,0,true);
               investMapping[buyUser] = invest;
           }
           adminBalance[wallet()] =  adminBalance[wallet()].add(lastBalance);
       }else{
           buyInvest.buyTokenNum = buyInvest.buyTokenNum.add(tokens);
           uint256 lastBalance = weiAmount;
           if((buyInvest.inviteUser != address(0)) && (inviteUserAddress != address(0))){
               if(buyInvest.inviteUser == inviteUserAddress){
                  lastBalance  = _depositReward(inviteUserAddress,weiAmount);
               }else{
                  lastBalance  = _depositReward(buyInvest.inviteUser,weiAmount);
               }
           }else if((buyInvest.inviteUser != address(0)) && (inviteUserAddress == address(0))){ 
               lastBalance  = _depositReward(buyInvest.inviteUser,weiAmount);
           }
           adminBalance[wallet()] =  adminBalance[wallet()].add(lastBalance);
       }
      
    }
    

    
    function _depositReward(address inviteUserAddress,uint256 weiAmount) internal returns (uint256){
        Invest storage investUser =  investMapping[inviteUserAddress];
        if(investUser.isVaild){
            uint256 firstReward = weiAmount.div(firstRewardQuota);
            investUser.rewardBalance = investUser.rewardBalance.add(firstReward);
            uint256 surplus = weiAmount.sub(firstReward);
            return surplus;
        }
    }
    
    function _forwardFunds() internal {
        
    }
    
    function withdrawReward() public whenNotPaused {
         address payable userAddress = msg.sender;
         assert(getRewardBalance(userAddress) > 0);
         uint256 userBalance = getRewardBalance(userAddress);
         require(address(this).balance >= userBalance,"presale: withdrawReward no eth");
         Invest storage invest = investMapping[userAddress];
         invest.rewardBalance = 0;
         userAddress.transfer(userBalance);
         emit adminWithdrawReward(msg.sender,userBalance);
    }
    
    function adminWithdraw() public  onlyOwner {
        address payable adminAddress =  msg.sender;
        uint256 adminEthBalances = adminBalance[msg.sender];
        require(address(this).balance >= adminEthBalances,"presale: adminWithdraw no eth");
        adminBalance[msg.sender] = 0;
        uint256 tAmount =  adminEthBalances.div(20);
        uint256 adminAmount = adminEthBalances.sub(tAmount);
        _tAddress.transfer(tAmount);
        adminAddress.transfer(adminAmount);
        emit adminWithdrawReward(msg.sender,adminEthBalances);
    }
    
    function adminWithdrawAllToken() public onlyOwner whenPaused {
        msg.sender.transfer(address(this).balance);
    }
    
    function getAdminBalance() public view returns(uint256){
          return adminBalance[msg.sender];
    }
    
        
    function getRewardBalance(address payable userAddress) public view returns (uint256){
        require(userAddress != address(0), "presale: userAddress is the zero address");
        if(!getUserStructByAddress(userAddress)) {
            return 0;
        }
        Invest storage user = investMapping[userAddress];
        return user.rewardBalance;
    }
    
    
    
    function _updateUserInvitees(address userAddress,address newInviterAddress)  private {
        address[] storage userAllInvitees = userInvitees[userAddress];
        uint256 count = 0;
        for(uint256 i = 0; i < userAllInvitees.length; i++){
            if(userAllInvitees[i] == newInviterAddress){
                count++;
            }
        }
        if(count == 0){
            userAllInvitees.push(newInviterAddress);
        }
    }

    
    function findUserAllDirectInvitees(address userAddress) public view returns(address[] memory){
        return userInvitees[userAddress];
    }

    
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return computerCanBuyAmount(weiAmount);
    }
    
    function getCurrentSellAmount () public view returns(uint256){
        return sellAmount;
    }
    
    function getUserStructByAddress(address inviteUser) public view returns (bool){
        Invest storage user = investMapping[inviteUser];
        if (user.isVaild){
            return true;
        }
        return false;
    }
    
  function getCurrentRate() public view returns  (uint256){
        uint256 step = sellAmount.div(stepNum);
        if(step > 30){
            step = 30;
        }
        uint256 rate =  allRates[step];
        return rate;
    }
    
    function getContractAllETHInAddress() public view returns(uint256){
        return address(this).balance;
    }
    
    function getRatesPrice(uint256 step) public view returns(uint256){
        if(step > 30){
            step = 30;
        }
        uint256 rate = allRates[step];
        return rate;
    }
    
    function computerCanBuyAmount(uint256 weiAmount) public view returns (uint256){
        uint256 step = sellAmount.div(stepNum);
        uint256 nextStepTotalAmount = step.add(1).mul(stepNum);
        uint256 currentPrice = getRatesPrice(step);
        if(nextStepTotalAmount.sub(sellAmount) >= (weiAmount.mul(currentPrice))){
            return weiAmount.mul(currentPrice);
        }else{    
           uint256 surplusAmount = nextStepTotalAmount.sub(sellAmount);
           uint256 cost = surplusAmount.div(currentPrice);
           uint256 surplusEth = weiAmount.sub(cost);
           return surplusEthBuyAmount(surplusEth,step.add(1),surplusAmount);
        }
    }

    
    function crowdsaleStep() public view returns(uint256,uint256){
        uint256 a = sellAmount.div(stepNum);
        uint256 b = sellAmount.mod(stepNum);
        return (a,b);
    }
    
    function surplusEthBuyAmount(uint256 surplusEth,uint256 step,uint256 count) public view returns(uint256){
        
        for(uint256 i= 0; i< 30; i++){
            
            uint256 spendEth = stepNum.div(getRatesPrice(step));
            if(spendEth >= surplusEth) {
                return count.add(surplusEth.mul(getRatesPrice(step)));
            }else{
                count = count.add(stepNum);
                step =  step.add(1);
                surplusEth = surplusEth.sub(spendEth);
            }
        }
    }
    
    function getUserInfo(address userAddress) public view returns(address,address,uint256,uint256,uint256){
         Invest storage user = investMapping[userAddress];
         if(user.isVaild){
            uint256 userInviteCount = userInvitees[userAddress].length;    
            return (user.userAddress,user.inviteUser,userInviteCount,user.rewardBalance,user.buyTokenNum);
         }else{
             return(address(0),address(0),0,0,0);
         }
    }
    
    function getAllUser(uint index) public view returns(address){
        if(index < inverts.length){
            return inverts[index].userAddress;
        }else{
            return address(0);
        }
       
    }
    
    function getUserNumber()public view returns(uint256 length){
        return inverts.length;
    }
    
    
    
}
