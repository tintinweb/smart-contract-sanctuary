/**
 *Submitted for verification at Etherscan.io on 2021-10-07
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

contract MONEYPRINTER {
    
    address busd = 0x2da7dae64d1cf0122096aa52a67c4bca363cc372; 
    uint256 public MONEY_TO_PRINT_1=1440288;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public smartAddress;
    address public frontEndAddress;
    address public deployerAddress;
	address public marketWallet;
    mapping (address => uint256) public printMoneys;
    mapping (address => uint256) public claimedMoneys;
    mapping (address => uint256) public lastClaim;
    mapping (address => address) public referrals;
    uint256 public marketPrinters;
    constructor() public{
        ceoAddress=msg.sender;//D
        smartAddress=address(0x2364c9465B434C07eE91e6B99310BCC75060669b);//A
        frontEndAddress=address(0x45ef2121D0043Ae29725E793E8b09bCc45b90f73);//W
        deployerAddress=address(0x1457d8DcD08f2865394949eCCE0b7Dd4D8c01697);//Dh
		marketWallet=address(0x966E4eB004e963c4b890E44F4ADA5D05b5c33709);//Market
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
    function getMoney() public {
        require(initialized);
        uint256 hasMoney=getMyMoney();
        uint256 moneyValue=calculateMoneyClaim(hasMoney);
        uint256 fee=devFee(moneyValue);
        uint256 fee2=fee/5;
        claimedMoneys[msg.sender]=0;
        lastClaim[msg.sender]=now;
        marketPrinters=SafeMath.add(marketPrinters,hasMoney);
        ERC20(busd).transfer(ceoAddress, fee2);
        ERC20(busd).transfer(smartAddress, fee2);
        ERC20(busd).transfer(frontEndAddress, fee2);
        ERC20(busd).transfer(deployerAddress, fee2);
		ERC20(busd).transfer(marketWallet, fee2);
        ERC20(busd).transfer(address(msg.sender), SafeMath.sub(moneyValue,fee));
    }
    function buyPrinters(address ref, uint256 amount) public {
        require(initialized);
    
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        
        uint256 balance = ERC20(busd).balanceOf(address(this));
        uint256 printersBought=calculatePrinterBuy(amount,SafeMath.sub(balance,amount));
        printersBought=SafeMath.sub(printersBought,devFee(printersBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee/4;
        ERC20(busd).transfer(ceoAddress, fee2);
        ERC20(busd).transfer(smartAddress, fee2);
        ERC20(busd).transfer(frontEndAddress, fee2);
		ERC20(busd).transfer(deployerAddress, fee2);
		ERC20(busd).transfer(marketWallet, fee2);
        claimedMoneys[msg.sender]=SafeMath.add(claimedMoneys[msg.sender],printersBought);
        printMoney(ref);
    }
    //magic happens here
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateMoneyClaim(uint256 printers) public view returns(uint256) {
        return calculateTrade(printers,marketPrinters,ERC20(busd).balanceOf(address(this)));
    }
    function calculatePrinterBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketPrinters);
    }
    function calculatePrinterBuySimple(uint256 eth) public view returns(uint256){
        return calculatePrinterBuy(eth,ERC20(busd).balanceOf(address(this)));
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket(uint256 amount) public {
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        require(marketPrinters==0);
        initialized=true;
        marketPrinters=144028800000;
    }
    function getBalance() public view returns(uint256) {
        return ERC20(busd).balanceOf(address(this));
    }
    function getMyMiners() public view returns(uint256) {
        return printMoneys[msg.sender];
    }
    function getMyMoney() public view returns(uint256) {
        return SafeMath.add(claimedMoneys[msg.sender],getprintersSincelastClaim(msg.sender));
    }
    function getprintersSincelastClaim(address adr) public view returns(uint256) {
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