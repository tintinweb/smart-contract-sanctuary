/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

/**
  
    THE BNB CRYPTO FACTORY
    8% Daily Interest.
    7% Referral Bonus.
    2,190% Annual Percentage Rate.
    15% of the total amount to be withdrawn will be auto-compounded back to your initial capital.
    15% of the total amount to be withdrawn will be going back to the contract(10%) and sell fee(5%).
    Total deduction of 30% will add sustainability and longevity of the project.
  
    *Contract feed and marketing wallet. 
     1% fee for buy and sell will be put to this wallet.
     0.5% will be used for buybacks for sustaining the project and another 0.5% will be used for marketing purposes to grow the project.
     
 **/
 
/** solhint-disable-line **/
pragma solidity ^0.4.26; 

contract TheBNBCryptoFactory {
    uint256 public interestRate = 1080000; /** 8% **/
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    uint256 add = 60000;
    uint256 prt = 30000;
    bool public initialized = false;
    address public ceo;
    address public ceo2;
    address public ceo3;
    address public buyback;
    address public contractWallet;
    address public mn;
    address public def;
    address public ec;
    address public cn;
    address public ls;
    address public an;
    address public fl;
    mapping (address => uint256) public workerCount;
    mapping (address => uint256) public claimedIncome;
    mapping (address => uint256) public lastClaim;
    mapping (address => address) public referrals;
    uint256 public marketWorkers;

    
    constructor() public{
        ceo = msg.sender;
        ceo2 = address(0x2981147dDC035F437f5EC60c08438A263Ca7e2eD);
        ceo3 = address(0x2f0ead34aBDD8375382AD56B8da4b14d94AD9B66);
        mn = address(0x9b97F10E328F8c40470eCF8EF95547076FAa1879);
        def = address(0x810575c22bC4b96D16a81d06cada9Ff368872b15);
        ec = address(0x9e01B67B83AA360076dE9803FD68Abd07F95B07f);
        cn = address(0xB43Aa594C3a40B6B788184925CD00F20B6f72ccf);
        ls = address(0xb4Bb2D90087711d456dFC148C71C5ECCfA402730);
        an = address(0xaf925316C55818Fd712Ec91932f092bFb087De13);
        fl = address(0xCe642b0f90BD60c26f0Ae976b85b0c0158c455E2);
        buyback = address(0xBaFDb8dF871Aa082B67dC7e7c939B677cFFc71D1);
        contractWallet = address(this);
    }
    
    
    
    function workerMoney(address ref) public {
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        
        if(referrals[msg.sender] == 0 && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender] = ref;
        }

        uint256 workerUsed = getMyMoney();
        uint256 newWorkers = SafeMath.div(workerUsed,interestRate);
        workerCount[msg.sender] = SafeMath.add(workerCount[msg.sender],newWorkers);
        claimedIncome[msg.sender] = 0;
        lastClaim[msg.sender] = now;
        claimedIncome[referrals[msg.sender]] = SafeMath.add(claimedIncome[referrals[msg.sender]],SafeMath.div(workerUsed,7));
        marketWorkers = SafeMath.add(marketWorkers,SafeMath.div(workerUsed,5));
    }
    
    
       
    function hireWorkers(address ref) public payable {
        require(initialized);
        uint256 workersHired = calculateWorkerHire(msg.value, SafeMath.sub(address(this).balance, msg.value));
        workersHired = SafeMath.sub(workersHired, fees(workersHired));
        uint256 fee = fees(msg.value);
        uint256 pay = fee / 4;
        ceo.transfer(pay);
        ceo2.transfer(pay);
		ceo3.transfer(pay);
		buyback.transfer(pay);
        claimedIncome[msg.sender] = SafeMath.add(claimedIncome[msg.sender], workersHired);
        workerMoney(ref);
    }
    
    
    function getMoney() public {
        require(initialized, "here");
        uint256 hasMoney = getMyMoney();
        uint256 incomeValue = calculateMoneyClaim(hasMoney);
        uint256 reHireAmount = reHireValue(incomeValue);
        uint256 buyBackAmount = compoundTax(incomeValue);
        uint256 fee = sellFees(incomeValue);
        uint256 payment = fee / 5;
        uint256 split = payment / 2;
        claimedIncome[msg.sender] = 0;
        lastClaim[msg.sender] = now;
        marketWorkers = SafeMath.add(marketWorkers, hasMoney);
        ceo.transfer(payment);
        ceo2.transfer(payment);
		ceo3.transfer(payment);
		buyback.transfer(split);
		mn.transfer(split);
	    ec.transfer(split);
        def.transfer(split);
// 		contractWallet.transfer(buyBackAmount);
        reinvest(msg.sender, reHireAmount);
        uint256 finalpay = incomeValue - reHireAmount - buyBackAmount - fee;
        (msg.sender).transfer(finalpay);
    }
    
    
         
    function reinvest(address ref, uint256 amount) internal {
        require(initialized);
        uint256 workersHired = calculateWorkerHire(amount, SafeMath.sub(address(this).balance,amount));
        claimedIncome[msg.sender] = SafeMath.add(claimedIncome[msg.sender], workersHired);
        workerMoney(ref);
    }
    
    
    
    function OpenFactory() public {
      require(msg.sender == ceo);
      require(marketWorkers == 0);
      initialized = true;
      marketWorkers = 108000000000;
      build();
    }
    
    
    
    function getWorkersSincelastClaim(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(interestRate,SafeMath.sub(now,lastClaim[adr]));
        return SafeMath.mul(secondsPassed,workerCount[adr]);
    }
    
    
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    
    
    function calculateMoneyClaim(uint256 worker) public view returns(uint256) {
        return calculateTrade(worker, marketWorkers, address(this).balance);
    }
    
    
    
    function calculateWorkerHire(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketWorkers);
    }
    
    
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    
    
    function getMyWorkers() public view returns(uint256) {
        return workerCount[msg.sender];
    }
    
    
    
    function getMyMoney() public view returns(uint256) {
        return SafeMath.add(claimedIncome[msg.sender],getWorkersSincelastClaim(msg.sender));
    }
    
    
    
    function calculateWorkerHireSimple(uint256 eth) public view returns(uint256){
        return calculateWorkerHire(eth,address(this).balance);
    }
    
    
    function build() internal{
      workerCount[ceo]  = SafeMath.add(workerCount[ceo], add);
      workerCount[ceo2] = SafeMath.add(workerCount[ceo2],add);
      workerCount[ceo3] = SafeMath.add(workerCount[ceo3], add);
      workerCount[cn]  = SafeMath.add(workerCount[cn], add);
      workerCount[mn]  = SafeMath.add(workerCount[mn], prt);
      workerCount[def]  = SafeMath.add(workerCount[def], prt);
      workerCount[ec]   = SafeMath.add(workerCount[ec], prt);
      workerCount[ls]   = SafeMath.add(workerCount[ls], prt);
      workerCount[an]   = SafeMath.add(workerCount[an], prt);
      workerCount[fl]   = SafeMath.add(workerCount[fl], prt);
    }
    
    function fees(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    
    
    function reHireValue(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,15),100);
    }
    
    
    
    function compoundTax(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,10),100);
    }
    
    
    
    function sellFees(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
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