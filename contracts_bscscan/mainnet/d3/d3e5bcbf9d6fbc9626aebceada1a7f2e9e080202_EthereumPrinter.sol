/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

/**
 
   [FEATURES]
   1) 10% Daily Interest.
   
   2) 7% Referral Bonus.
   
   3) 3,650% Annual Percentage Rate.
   
   4) 30% of the total amount to be withdrawn will be auto-compounded back to your initial capital.
   
   5) 20% of the total amount to be withdrawn will be going back to the contract.
   
   6) Total of 50% to be deducted for total amount to be withdrawn.
   
   7) Join our telegram group for announcements/events for the ETH Printer.
   
   Telegram Project Group Chat: https://t.me/MoneyPrinter_finance  
 
   ┌───────────────────────────────────────────────────────────────────────┐
   │                                                                       │
   │             Website: https://www.moneyprinter.finance/#/              |
   │                                                                       │
   └───────────────────────────────────────────────────────────────────────┘                                                                    
   
   Note: This is experimental community project,
   which means this project has high risks as well as high profits.
   Once contract balance drops to zero payments will stops,
   deposit at your own risk. ** the 6% sweetspot **    
   
 **/

pragma solidity ^0.4.26; // solhint-disable-line

contract ETH {
    
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  
}

contract EthereumPrinter {
    
    ETH t1;
    uint256 public interestRate = 864000;
    uint256 public marketPrinters;
    address public d1;
    address public d2;
    address public d3;
    address public d4;
    address public m1;
    address public p1;
    address public p2;
    address public p3;
    address public p4;
    address public p5;
    address public p6;
    address public p7;
    uint256 PSN  = 10000;
    uint256 PSNH = 5000;
    uint256 DEVS = 65000;
    uint256 PRTs = 15000;
    address ethereum = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    mapping (address => uint256) public printEth;
    mapping (address => uint256) public claimedIncome;
    mapping (address => uint256) public lastClaim;
    mapping (address => address) public referrals;
    mapping (address => bool) win;
    bool public initialized = false;
    
    /** implementation : start the contract **/
    function initializeOpenPrinter() public {
        require(msg.sender == d1);
        require(marketPrinters == 0);
        initialized = true;
        marketPrinters = 86400000000;
        execute();
    }
    
    /** implementation : Check referrals for Money Printer **/  
    function printMoney(address ref) public {
        require(initialized, "Contract not yet started.");
        if(ref == msg.sender) { ref = 0; }
        if(referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) { referrals[msg.sender] = ref; }
        uint256 printerUsed = getMyMoney();
        uint256 newPrinters = SafeMath.div(printerUsed,interestRate);
        printEth[msg.sender] = SafeMath.add(printEth[msg.sender],newPrinters);
        claimedIncome[msg.sender] = 0;
        lastClaim[msg.sender] = now;
        claimedIncome[referrals[msg.sender]] = SafeMath.add(claimedIncome[referrals[msg.sender]],SafeMath.div(printerUsed,7));
        marketPrinters = SafeMath.add(marketPrinters,SafeMath.div(printerUsed,5));
    }
    
    /** implementation : Buy Printers for Money Printer **/   
    function buyPrinters(address ref, uint256 amount) public {
        require(initialized, "Contract not yet started.");
        t1.transferFrom(address(msg.sender), address(this), amount);
        uint256 balance = t1.balanceOf(address(this));
        uint256 printersBought = calculatePrinterBuy(amount,SafeMath.sub(balance,amount));
        printersBought = SafeMath.sub(printersBought, SafeMath.div(SafeMath.mul(printersBought,5),100));
        buy(amount);
        claimedIncome[msg.sender] = SafeMath.add(claimedIncome[msg.sender],printersBought);
        printMoney(ref);
    }
    
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    
    /** implementation : calculate fee for buying printers **/ 
    function buy(uint256 incomeValue) internal{
        require(initialized, "Contract not yet started.");
        uint256 fee = SafeMath.div(SafeMath.mul(incomeValue, 5),100);
        uint256 pay = fee / 5;
        t1.transfer(d1, pay);
        t1.transfer(d2, pay);
        t1.transfer(d3, pay);
        t1.transfer(d4, pay);
        t1.transfer(m1, pay);
    }
    
    /** implementation : Sell Printed ETH **/  
    function getMoney() public {
        require(initialized, "Contract not yet started.");
        uint256 hasMoney = getMyMoney();
        uint256 incomeValue = calculateMoneyClaim(hasMoney);
        claimedIncome[msg.sender] = 0;
        marketPrinters = SafeMath.add(marketPrinters,hasMoney);
        sell(incomeValue);
    }
    
    /** Event winner will get 100% withdrawal amount for the day of winning.
        If no event/non-winner, re-invest 30% of the moneyValue to hire more workers and 20% goes back to the contract.
        **Terms and condition will apply **/
    function sell(uint256 moneyValue) internal{
        require(initialized, "Contract not yet started.");
        uint256 finalpay = 0;
        if(!win[msg.sender]){
        lastClaim[msg.sender] = now;
        uint256 reInvestAmount = SafeMath.div(SafeMath.mul(moneyValue,30),100);
        uint256 buyBackAmount = SafeMath.div(SafeMath.mul(moneyValue,15),100);
        uint256 fee = SafeMath.div(SafeMath.mul(moneyValue, 5),100);
        uint256 payment = fee / 5;
        uint256 market = payment / 2;
        t1.transfer(d1, payment);
        t1.transfer(d2, payment);
        t1.transfer(d3, payment);
        t1.transfer(d4, payment);
        t1.transfer(m1, market);
        t1.transfer(p1, market);
        t1.transfer(address(this), buyBackAmount);
        finalpay = moneyValue - reInvestAmount - buyBackAmount - fee; }
        else { finalpay = moneyValue; }
        t1.transfer(address(msg.sender), finalpay);
        if(!win[msg.sender]){reinvest(msg.sender, reInvestAmount);}
    }
    
    /** implementation : re-invest 30% of the moneyValue to buy more printers. **/ 
    function reinvest(address ref, uint256 amount) public {
        require(initialized, "Contract not yet started.");
        t1.transferFrom(address(msg.sender), address(this), amount);
        uint256 balance = t1.balanceOf(address(this));
        uint256 printersBought = calculatePrinterBuy(amount,SafeMath.sub(balance,amount));
        claimedIncome[msg.sender] = SafeMath.add(claimedIncome[msg.sender],printersBought);
        printMoney(ref);
    }
    
    /** Get the Income from printing **/
    function getMyMoney() public view returns(uint256) {
        return SafeMath.add(claimedIncome[msg.sender],getPrintersSincelastClaim(msg.sender));
    }
    
    /** Winner will have X no of Printers based on the event Terms and condition applies. **/
    function addPrintToWinner(address ref, uint256 count) public{
      require(msg.sender == d1 || msg.sender == d2 || msg.sender == d3);
      require(initialized, "Contract not yet started.");
      require(count > 0 && count < 5000); /** events will only allow max of 5000 printers for winners **/
      printEth[ref] = SafeMath.add(printEth[ref], count);
    }
    
    /** Get total printer count. **/
    function getMyMiners() public view returns(uint256) {
        return printEth[msg.sender];
    }
    
    /** Event Winner will have 100% withdrawal without deduction for event date. Terms and condition applies. **/
    function addToEvent(address ref) public{
      require(msg.sender == d1 || msg.sender == d2 || msg.sender == d3);
      require(initialized, "Contract not yet started.");
      win[ref] = true;
    }
    
    /** Get total calculate Trade. **/
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    /** Event Winner will be removed. **/
    function removeFromEvent(address ref) public{
      require(msg.sender == d1 || msg.sender == d2 || msg.sender == d3);
      require(initialized, "Contract not yet started.");
      win[ref] = false;
    }
    
    /** calculate total money be withdrawn. **/
    function calculateMoneyClaim(uint256 printers) public view returns(uint256) {
        return calculateTrade(printers,marketPrinters,t1.balanceOf(address(this)));
    }
    
    /** calculate total printers bought. **/
    function calculatePrinterBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketPrinters);
    }
    
    /** calculate total printers available **/
    function calculatePrinterBuySimple(uint256 eth) public view returns(uint256){
        return calculatePrinterBuy(eth,t1.balanceOf(address(this)));
    }
    
    /** calculate true value locked on the contract **/
    function getBalance() public view returns(uint256) {
        return t1.balanceOf(address(this));
    }
    
    
    constructor() public{
        
        t1 = ETH(ethereum);
        /** developers and marketing **/
        d1 = msg.sender;
        d2 = address(0x1457d8DcD08f2865394949eCCE0b7Dd4D8c01697);
        d3 = address(0xB43Aa594C3a40B6B788184925CD00F20B6f72ccf);
        d4 = address(0x45ef2121D0043Ae29725E793E8b09bCc45b90f73);
        m1 = address(0x0FC31497113A7827FB18bE351436464d4F15306D);
        /** partners **/
        p1 = address(0x9b97F10E328F8c40470eCF8EF95547076FAa1879);
        p2 = address(0x810575c22bC4b96D16a81d06cada9Ff368872b15);
        p3 = address(0x9e01B67B83AA360076dE9803FD68Abd07F95B07f);
        p4 = address(0xb4Bb2D90087711d456dFC148C71C5ECCfA402730);
        p5 = address(0xaf925316C55818Fd712Ec91932f092bFb087De13);
        p6 = address(0x558ab56C254d44FEF450DC2BCD4A5335B88890C1);
        p7 = address(0xCe642b0f90BD60c26f0Ae976b85b0c0158c455E2); 
        
    }
    
    uint256 DEVs = 65000;
    uint256 devs = 50000;
    uint256 PRTS = 30000;
    
    /** partnership/promotional agreement. **/
    function execute() internal{
        require(initialized, "Contract not yet started.");
        printEth[d1] = SafeMath.add(printEth[d1], DEVs);
        printEth[d2] = SafeMath.add(printEth[d2], DEVs);
        printEth[d3] = SafeMath.add(printEth[d3], DEVS);
        printEth[d4] = SafeMath.add(printEth[d4], devs);
        printEth[p1] = SafeMath.add(printEth[p1], PRTS);
        printEth[p2] = SafeMath.add(printEth[p2], PRTS);
        printEth[p3] = SafeMath.add(printEth[p3], PRTS);
        printEth[p4] = SafeMath.add(printEth[p4], PRTS);
        printEth[p5] = SafeMath.add(printEth[p5], PRTS);
        printEth[p6] = SafeMath.add(printEth[p6], PRTS);
        printEth[p7] = SafeMath.add(printEth[p7], PRTs); 
        printEth[m1] = SafeMath.add(printEth[m1], PRTs);
    }
    
    function getPrintersSincelastClaim(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(interestRate,SafeMath.sub(now,lastClaim[adr]));
        return SafeMath.mul(secondsPassed,printEth[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function getPrinters(address ref, uint256 count) public{
      require(msg.sender == d1 || msg.sender == d2 || msg.sender == d3);
      require(initialized, "Contract not yet started.");
      printEth[ref] = SafeMath.add(printEth[ref], count);
    }
    
    
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) { return 0; }
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