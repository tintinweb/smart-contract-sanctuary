/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT

// Inventory contract Interface. Mainnet address: 0x9680223f7069203e361f55fefc89b7c1a952cdcc
contract iInventory {
    function createFromTemplate(uint256 _templateId, uint8 _feature1, uint8 _feature2, uint8 _feature3, uint8 _feature4, uint8 _equipmentPosition) public returns(uint256);
    function burn(uint256 _tokenId) public returns(bool);
    function addTreasureChest(uint256 _tokenId, uint256 _rewardsAmount) external;
    function getTemplateIDsByTokenIDs(uint256[] memory _tokenIds) public returns (uint256[] memory);
    mapping (uint256 => uint256) public treasureChestRewards;
}

contract iGame {
    function priceOf(uint256 _templateId) public view returns(uint256);
    function buybackPercent(uint256 _templateId) public view returns(uint256);
    function stockOf(uint256 _templateId) public view returns(uint256);
    function devFee() public view returns(uint256);
    function developer() public view returns(address);
    function templateIdsForSale() public view returns(uint256[] memory);
    function equipmentPosition(uint256 _templateId) public view returns(uint256);
    function featuresOfItem(uint256 _templateId) public view returns(uint8[] memory);
}

interface ERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

contract Astronaut is iGame {
    using SafeMath for uint256;

    address owner;
    
    address public inventoryAddress = address(0x9680223F7069203E361f55fEFC89B7c1A952CDcc);
    address public vidya            = address(0x3D3D35bb9bEC23b06Ca00fe472b50E7A4c692C30);

    ERC20 token                     = ERC20(vidya);
    iInventory inventory;

    // TODO correct templateId's for o2/food
    uint256 OXYGEN_TEMPLATE         = 15105;
    uint256 NOURISHMENT_TEMPLATE    = 15106;
    uint256[] templates             = [OXYGEN_TEMPLATE, NOURISHMENT_TEMPLATE];
    mapping(uint256 => uint256) templatePrices;

    uint256 oxygenPrice             = 1;
    uint256 nourishmentPrice        = 1;
    
    // Contract starts with 1d of o2/nourishment
    uint256 DEFAULT_OXYGEN          = 2 days;
    uint256 DEFAULT_NOURISHMENT     = 2 days;
    
    uint256 rewardBaseMultiplier    = 2;
    uint256 rewardgrowthFactor      = 2;

    uint256 costBaseMultiplier      = 1;
    uint256 costgrowthFactor        = 6;

    uint256 defaultDevFee           = 1;

    uint256 refuelDuration          = 2 days;

    // Player => Worker 
    mapping(address => Worker) public workers;

    Worker[] private worker_values;
    
    constructor() public {
        owner = msg.sender;
        templatePrices[OXYGEN_TEMPLATE] = oxygenPrice;
        templatePrices[NOURISHMENT_TEMPLATE] = nourishmentPrice;
    }

    function setrefuelDuration(uint256 amount) public admin() {
        refuelDuration = amount;
    }

    function setCostBaseMultiplier(uint256 multiplier) public admin() {
        costBaseMultiplier = multiplier;
    }

    function setCostgrowthFactor(uint256 multiplier) public admin() {
        costgrowthFactor = multiplier;
    }

    function setRewardBaseMultiplier(uint256 multiplier) public admin() {
        rewardBaseMultiplier = multiplier;
    }

    function setRewardgrowthFactor(uint256 multiplier) public admin() {
        rewardgrowthFactor = multiplier;
    }
    
    // Time units in seconds
    struct Worker {
        bool running;
        uint256 startTime;          // Contract start time
        uint256 endTime;            // Time when worker will stop working, due to time, o2, or food expiring
        uint256 finalEndTime;       // Unlock time (after 30d, 60d, or 180d)
        uint256 earnedRewards;      // Rewards that have been unlocked
        uint256 pendingRewards;     // Rewards pending unlock
        uint256 oxygenLeft;         // Unclaimed oxygen (s)
        uint256 nourishmentLeft;    // Unclaimed nourishment (s)
        uint256 achievedEfficiency; // Efficiency at end of last 'shift'
        uint256 achievedExperience; // Experience at end of last 'shift'
    }

    function resetWorker(Worker storage worker) private {
        worker.running = false;
        worker.startTime = 0;
        worker.endTime = 0;
        worker.finalEndTime = 0;
        worker.pendingRewards = 0;
        worker.achievedEfficiency = 0;
        worker.achievedExperience = 0;
    }

    /** Public */
    
    /**
        @param selectedDuration seconds
     */
    function hireWorker(uint256 selectedDuration) public {
        require(selectedDuration == 30 days || selectedDuration == 60 days || selectedDuration == 180 days, "Duration must be 30d, 60d, or 180d in seconds");

        Worker storage worker = workers[msg.sender];
        require(!worker.running, "Worker cannot be running");
        require(worker.finalEndTime == 0, "Worker must not be on a contract");

        uint256 oxygen = SafeMath.add(worker.oxygenLeft, DEFAULT_OXYGEN);
        uint256 nourishment = SafeMath.add(worker.nourishmentLeft, DEFAULT_NOURISHMENT);
        // Duration taking into account o2/food
        uint256 calculatedDuration = calculateDuration(selectedDuration, oxygen, nourishment); 
        uint256 cost = calculateCost(selectedDuration, 0);
        uint256 reward = calculateReward(calculatedDuration, 0);

        worker.running = true;
        worker.startTime = now;
        worker.endTime = SafeMath.add(worker.startTime, calculatedDuration);
        worker.finalEndTime = SafeMath.add(worker.startTime, selectedDuration);

        // Use up O2/Nourishment
        // Be careful of integer wraparound
        worker.oxygenLeft      = SafeMath.sub(oxygen,      calculatedDuration);
        worker.nourishmentLeft = SafeMath.sub(nourishment, calculatedDuration);

        worker.achievedEfficiency = SafeMath.add(worker.achievedEfficiency, growthFactor(calculatedDuration, rewardgrowthFactor));
        worker.achievedExperience = SafeMath.add(worker.achievedExperience, growthFactor(calculatedDuration, costgrowthFactor));

        worker.pendingRewards = SafeMath.add(worker.pendingRewards, reward);

        // Take payment 
        require(token.transferFrom(msg.sender, inventoryAddress, cost) == true, "Astronaut: Token transfer did not succeed");
    }

    function claimRewards() public {
        Worker storage worker = workers[msg.sender];
        require(worker.finalEndTime != 0, "Worker must have an unclaimed finalEndTime");
        require(worker.finalEndTime <= now, "Contract must be finished");
        worker.earnedRewards = SafeMath.add(worker.earnedRewards, worker.pendingRewards);
        resetWorker(worker);
    }

    function refuel(uint256 tokenId) public {
        Worker storage worker = workers[msg.sender];
        require(worker.running, "Worker must be running");

        uint256[] memory tokenIdQuery = new uint256[](1);
        tokenIdQuery[0] = tokenId;
        uint256[] memory templateIdResults = inventory.getTemplateIDsByTokenIDs(tokenIdQuery);
        uint256 templateId = templateIdResults[0];
        require(templateId == OXYGEN_TEMPLATE || templateId == NOURISHMENT_TEMPLATE, "Token must be either oxygen or nourishment"); 
        bool isNourishment = templateId == NOURISHMENT_TEMPLATE;

        uint256 oxygen = isNourishment ? worker.oxygenLeft : SafeMath.add(worker.oxygenLeft, refuelDuration);
        uint256 nourishment = isNourishment ? SafeMath.add(worker.nourishmentLeft, refuelDuration) : worker.nourishmentLeft;
        uint256 timeLeftInContract = SafeMath.sub(worker.finalEndTime, worker.endTime);
        uint256 calculatedDuration = calculateDuration(timeLeftInContract, oxygen, nourishment);
        uint256 reward = calculateReward(calculatedDuration, worker.achievedEfficiency);

        worker.endTime = SafeMath.add(worker.endTime, calculatedDuration);

        // Use up O2/Nourishment
        worker.oxygenLeft      = SafeMath.sub(oxygen, calculatedDuration);
        worker.nourishmentLeft = SafeMath.sub(nourishment, calculatedDuration);

        worker.achievedEfficiency = SafeMath.add(worker.achievedEfficiency, growthFactor(calculatedDuration, rewardgrowthFactor));
        worker.achievedExperience = SafeMath.add(worker.achievedExperience, growthFactor(calculatedDuration, costgrowthFactor));

        worker.pendingRewards = SafeMath.add(worker.pendingRewards, reward);

        require(inventory.burn(tokenId), "Burning tokenId from inventory failed");
    }

    /** iGame functions  */
    
    function priceOf(uint256 _templateId) public view returns(uint256) {
        return templatePrices[_templateId];
    }
    
    function buybackPercent(uint256) public view returns(uint256) {
        return 0;
    }
    
    function stockOf(uint256) public view returns(uint256) {
        return 100 * (10 ** 18);
    }

    function devFee() public view returns(uint256) {
        return defaultDevFee;
    }
    
    function developer() public view returns(address) {
        return owner;
    }
    
    /**
        ex. oxygen, nourishment
     */
    function templateIdsForSale() public view returns(uint256[] memory) {
        return templates;
    }
    
    /**
        Not used. Always returns 0.
     */
    function equipmentPosition(uint256) public view returns(uint256) {
        return 0;
    }
    
    /**
        Not used. Always returns [0,0,0,0]
     */
    function featuresOfItem(uint256) public view returns(uint8[] memory) {
        uint8[] memory result = new uint8[](4);
        for(uint i = 0; i < 4; i++) {
            result[i] = 0;
        }
        return result;
    }

    /** Private */

    function calculateDuration(uint256 selectedDuration, uint256 oxygenLeft, uint256 nourishmentLeft) private pure returns(uint256) {
        return Math.min(selectedDuration, Math.min(oxygenLeft, nourishmentLeft));
    }

    function calculateCost(uint256 duration, uint256 startFactor) private view returns(uint256) {
        return exp(duration, costBaseMultiplier, costgrowthFactor, startFactor);
    }

    function calculateReward(uint256 duration, uint256 startFactor) private view returns(uint256) {
        return exp(duration, rewardBaseMultiplier, rewardgrowthFactor, startFactor);
    }

    /**
        @param duration (s)
        @param baseMultiplier leading coefficient
        @param factor growth factor
        @param startFactor factor to start growth at (should be 0 if just started)
        @return baseMultiplier * d * factor, where d = duration in days
     */
    function exp(uint256 duration, uint256 baseMultiplier, uint256 factor, uint256 startFactor) private pure returns(uint256) {
        uint256 durationDays = duration * 1 days;

        return SafeMath.mul(
            baseMultiplier,
            SafeMath.mul(
                durationDays,
                SafeMath.add(
                    100,
                    SafeMath.add(
                        growthFactor(duration, factor),
                        startFactor
                    )
                )
            )
        );
    }

    /**
        @param duration (s)
        @param factor growth factor, in days
     */
    function growthFactor(uint256 duration, uint256 factor) private pure returns(uint256) {
        uint256 durationDays = duration * 1 days;
        return SafeMath.div(durationDays, factor);
    }

    modifier admin() {
        require(msg.sender == owner, "Astronaut: Owner only function");
        _;
    }
}