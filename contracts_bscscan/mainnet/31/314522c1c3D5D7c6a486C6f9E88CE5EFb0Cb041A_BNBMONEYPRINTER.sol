/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

pragma solidity ^0.4.26; // solhint-disable-line

contract BNBMONEYPRINTER{
    uint256 public MONEY_TO_PRINT_1=1440000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public senderAddress;
    address public smartAddress;
    address public deployerAddress;
    address public frontEndAddress;
    mapping (address => uint256) public printMoneys;
    mapping (address => uint256) public claimedMoneys;
    mapping (address => uint256) public lastClaim;
    mapping (address => address) public referrals;
    uint256 public marketPrinters;
    constructor() public{
        senderAddress=msg.sender;
        smartAddress=address(0x2364c9465B434C07eE91e6B99310BCC75060669b);
        frontEndAddress=address(0x45ef2121D0043Ae29725E793E8b09bCc45b90f73);
        deployerAddress=address(0x0C2b52c970d643Ebfa2318f64Ddf0D322C2322b6);
    }
    function printMoney(address ref) public {
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender]=ref;
        }
        uint256 printerUsed=getMyMoney();
        uint256 newPrinters=SafeMath.div(printerUsed,MONEY_TO_PRINT_1);
        printMoneys[msg.sender]=SafeMath.add(printMoneys[msg.sender],newPrinters);
        claimedMoneys[msg.sender]=0;
        lastClaim[msg.sender]=now;
        claimedMoneys[referrals[msg.sender]]=SafeMath.add(claimedMoneys[referrals[msg.sender]],SafeMath.div(printerUsed,10));

        marketPrinters=SafeMath.add(marketPrinters,SafeMath.div(printerUsed,5));
    }
    function getMoney() public{
        require(initialized);
        uint256 hasMoney=getMyMoney();
        uint256 moneyValue=calculateMoneyClaim(hasMoney);
        uint256 fee=devFee(moneyValue);
        uint256 fee2=fee/4;
        claimedMoneys[msg.sender]=0;
        lastClaim[msg.sender]=now;
        marketPrinters=SafeMath.add(marketPrinters,hasMoney);
        senderAddress.transfer(fee2);
        smartAddress.transfer(fee2);
		deployerAddress.transfer(fee2);
		frontEndAddress.transfer(fee2);
        msg.sender.transfer(SafeMath.sub(moneyValue,fee));
    }
    function buyPrinters(address ref) public payable{
        require(initialized);
        uint256 printersBought=calculatePrinterBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        printersBought=SafeMath.sub(printersBought,devFee(printersBought));
        uint256 fee=devFee(msg.value);
        uint256 fee2=fee/4;
        senderAddress.transfer(fee2);
        smartAddress.transfer(fee2);
		deployerAddress.transfer(fee2);
		frontEndAddress.transfer(fee2);
        claimedMoneys[msg.sender]=SafeMath.add(claimedMoneys[msg.sender],printersBought);
        printMoney(ref);
    }
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateMoneyClaim(uint256 printers) public view returns(uint256){
        return calculateTrade(printers,marketPrinters,address(this).balance);
    }
    function calculatePrinterBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketPrinters);
    }
    function calculatePrinterBuySimple(uint256 eth) public view returns(uint256){
        return calculatePrinterBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket() public payable{
        require(marketPrinters==0);
        initialized=true;
        marketPrinters=144000000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return printMoneys[msg.sender];
    }
    function getMyMoney() public view returns(uint256){
        return SafeMath.add(claimedMoneys[msg.sender],getprintersSincelastClaim(msg.sender));
    }
    function getprintersSincelastClaim(address adr) public view returns(uint256){
        uint256 secondsPassed=min(MONEY_TO_PRINT_1,SafeMath.sub(now,lastClaim[adr]));
        return SafeMath.mul(secondsPassed,printMoneys[adr]);
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