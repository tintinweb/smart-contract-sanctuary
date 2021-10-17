/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

pragma solidity ^0.4.26; // solhint-disable-line

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract TheCryptoFactory {
    
    address busd = 0x2dA7daE64D1cf0122096aA52A67C4bCA363Cc372; 
    uint256 public MONEY_TO_PRINT_1=1440000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress1;
    address public partner1;
    address public partner2;
    mapping (address => uint256) public workerMoneys;
    mapping (address => uint256) public claimedMoneys;
    mapping (address => uint256) public lastClaim;
    mapping (address => address) public referrals;
    uint256 public marketWorkers;
    constructor() public{
        ceoAddress=msg.sender;
        ceoAddress1=address(0x2981147dDC035F437f5EC60c08438A263Ca7e2eD);
        partner1=address(0x810575c22bC4b96D16a81d06cada9Ff368872b15);
        partner2=address(0x87cb806192eC699398511c7aB44b3595C051D13C);
    }
    function workerMoney(address ref) public {
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender]=ref;
        }
        uint256 workerUsed=getMyMoney();
        uint256 newWorkers=SafeMath.div(workerUsed,MONEY_TO_PRINT_1);
        workerMoneys[msg.sender]=SafeMath.add(workerMoneys[msg.sender],newWorkers);
        claimedMoneys[msg.sender]=0;
        lastClaim[msg.sender]=now;
        
        claimedMoneys[referrals[msg.sender]]=SafeMath.add(claimedMoneys[referrals[msg.sender]],SafeMath.div(workerUsed,12));

        marketWorkers=SafeMath.add(marketWorkers,SafeMath.div(workerUsed,5));
    }
    function getMoney() public {
        require(initialized);
        uint256 hasMoney=getMyMoney();
        uint256 moneyValue=calculateMoneyClaim(hasMoney);
        uint256 fee=devFee(moneyValue);
        uint256 fee2=fee/4;
        claimedMoneys[msg.sender]=0;
        lastClaim[msg.sender]=now;
        marketWorkers=SafeMath.add(marketWorkers,hasMoney);
        ERC20(busd).transfer(ceoAddress, fee2);
        ERC20(busd).transfer(ceoAddress1, fee2);
        ERC20(busd).transfer(partner1, fee2);
        ERC20(busd).transfer(partner2, fee2);
        ERC20(busd).transfer(address(msg.sender), SafeMath.sub(moneyValue,fee));
    }
    function buyWorkers(address ref, uint256 amount) public {
        require(initialized);
    
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        
        uint256 balance = ERC20(busd).balanceOf(address(this));
        uint256 workersBought=calculateWorkerBuy(amount,SafeMath.sub(balance,amount));
        workersBought=SafeMath.sub(workersBought,devFee(workersBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee/2;
        ERC20(busd).transfer(ceoAddress, fee2);
        ERC20(busd).transfer(ceoAddress1, fee2);
        claimedMoneys[msg.sender]=SafeMath.add(claimedMoneys[msg.sender],workersBought);
        workerMoney(ref);
    }
    //magic happens here
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateMoneyClaim(uint256 worker) public view returns(uint256) {
        return calculateTrade(worker,marketWorkers,ERC20(busd).balanceOf(address(this)));
    }
    function calculateWorkerBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketWorkers);
    }
    function calculateWorkerBuySimple(uint256 eth) public view returns(uint256){
        return calculateWorkerBuy(eth,ERC20(busd).balanceOf(address(this)));
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,4),100);
    }
    function seedMarket(uint256 amount) public {
        require(msg.sender == ceoAddress, "Only Ceo");
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        require(marketWorkers==0);
        initialized=true;
        marketWorkers=144000000000;
        workerMoneys[msg.sender]=SafeMath.add(workerMoneys[msg.sender],50000);
        workerMoneys[ceoAddress1]=SafeMath.add(workerMoneys[ceoAddress1],50000);
        workerMoneys[partner1]=SafeMath.add(workerMoneys[partner1],50000);
        workerMoneys[partner2]=SafeMath.add(workerMoneys[partner2],50000);
    }
    function getBalance() public view returns(uint256) {
        return ERC20(busd).balanceOf(address(this));
    }
    function getMyWorkers() public view returns(uint256) {
        return workerMoneys[msg.sender];
    }
    function getMyMoney() public view returns(uint256) {
        return SafeMath.add(claimedMoneys[msg.sender],getWorkersSincelastClaim(msg.sender));
    }
    function getWorkersSincelastClaim(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(MONEY_TO_PRINT_1,SafeMath.sub(now,lastClaim[adr]));
        return SafeMath.mul(secondsPassed,workerMoneys[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
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