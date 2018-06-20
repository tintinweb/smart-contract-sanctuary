pragma solidity ^0.4.23;

contract ToadFarmer {
    uint256 public EGGS_TO_HATCH_1TOAD = 43200; // Half a day&#39;s worth of seconds to hatch
    uint256 TADPOLE = 10000;
    uint256 PSNHTOAD = 5000;
    bool public initialized = false;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryToad;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;

    constructor() public {
        ceoAddress = msg.sender;
    }

    function hatchEggs(address ref) public {
        require(initialized);
        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newToad = SafeMath.div(eggsUsed, EGGS_TO_HATCH_1TOAD);
        hatcheryToad[msg.sender] = SafeMath.add(hatcheryToad[msg.sender], newToad);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        // Send referral eggs
        claimedEggs[referrals[msg.sender]] = SafeMath.add(claimedEggs[referrals[msg.sender]], SafeMath.div(eggsUsed, 5));
        
        // Boost market to stop toad hoarding
        marketEggs = SafeMath.add(marketEggs, SafeMath.div(eggsUsed, 10));
    }

    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = SafeMath.add(marketEggs, hasEggs);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue, fee));
    }
    
    function buyEggs() public payable {
        require(initialized);
        uint256 eggsBought = calculateEggBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        eggsBought = SafeMath.sub(eggsBought, devFee(eggsBought));
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender], eggsBought);
        ceoAddress.transfer(devFee(msg.value));
    }

    // Trade balancing algorithm
    function calculateTrade(uint256 riggert, uint256 starboards, uint256 bigship) public view returns(uint256) {
        // (TADPOLE*bigship) /
        // (PSNHTOAD+((TADPOLE*starboards+PSNHTOAD*riggert)/riggert));
        return SafeMath.div(SafeMath.mul(TADPOLE, bigship),
        SafeMath.add(PSNHTOAD, SafeMath.div(SafeMath.add(SafeMath.mul(TADPOLE, starboards),SafeMath.mul(PSNHTOAD, riggert)), riggert)));
    }

    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs, marketEggs, address(this).balance);
    }

    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth, address(this).balance);
    }

    function devFee(uint256 amount) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 4), 100);
    }

    function seedMarket(uint256 eggs) public payable {
        require(marketEggs == 0);
        initialized = true;
        marketEggs = eggs;
    }

    function getFreeToad() public {
        require(initialized);
        require(hatcheryToad[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        hatcheryToad[msg.sender] = uint(blockhash(block.number-1))%400 + 1; // &#39;Randomish&#39; 1-400 free eggs
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getMyToad() public view returns(uint256) {
        return hatcheryToad[msg.sender];
    }

    function getMyEggs() public view returns(uint256) {
        return SafeMath.add(claimedEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
    }

    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1TOAD, SafeMath.sub(now, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, hatcheryToad[adr]);
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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