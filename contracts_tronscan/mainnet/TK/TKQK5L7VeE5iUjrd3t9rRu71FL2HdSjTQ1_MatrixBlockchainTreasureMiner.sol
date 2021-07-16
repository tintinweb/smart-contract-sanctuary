//SourceUnit: MATRIXTreasureMiner.sol

pragma solidity >=0.4.25 <0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library Object{
    struct Element{
        bool isTRC10;
        uint tokenId;
        address trc20Address;
        uint availableHarvestBalance;
        uint totalUserBalance;
    }

    struct Strain{
        uint[] inElements;
        uint[] ratioInElements;
        uint[] outElements;
        uint[] ratioOutElements;
        uint timeToGrown;
    }

    struct GrowthXP{
        uint elementId;
        uint elementConsum;
        uint minutesBonus;
    }

    struct Plant{
        uint startTime;
        uint bonusTime;
        uint harvestTime;
        uint mulSeed;
        uint strainId;
    }

}
 
interface TRC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external  returns (bool success);
}

contract Managable {
    address public owner;
    mapping(address => bool) public admins;
    bool public locked;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
        locked = false;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    function setAdminStatus(address adminAccount, bool isActive) public onlyOwner {
        require(adminAccount != address(0));
        admins[adminAccount] = isActive;
    }

    modifier isNotLocked() {
        require(!locked);
        _;
    }

    function setLock(bool _value) onlyAdmin public {
        locked = _value;
    }
}

contract MatrixBlockchainTreasureMiner is Managable {
    using SafeMath for uint;

    uint constant TIME_UNIT = 1 minutes;
    Object.Element[] private elements;
    Object.Strain[] private strains;
    Object.GrowthXP[] private growthXPs;
    mapping (address => mapping (uint => uint)) public balanceElements;
    mapping(address => Object.Plant[]) public plants;

    function addElementTrc10(uint tokenId) public onlyAdmin {
        elements.push(Object.Element(true,tokenId,address(0),0,0));
    }

    function addElementTrc20(address trc20Address) public onlyAdmin {
        elements.push(Object.Element(false,0,address(trc20Address),0,0));
    }

    function getElementsCount() public view returns(uint) {
        return elements.length;
    }

    function getElement(uint elementId) public view returns(bool, uint, address, uint, uint){
        Object.Element storage element = elements[elementId];
        return (element.isTRC10, element.tokenId, element.trc20Address, element.availableHarvestBalance, element.totalUserBalance);
    }

    function addGrowthXP(uint elementId, uint elementConsum, uint minutesBonus) public onlyAdmin{
        require(elementId < elements.length, "Don't exits this element");
        growthXPs.push(Object.GrowthXP(elementId, elementConsum, minutesBonus));
    }

    function getElementGrowthXPCount() public view returns(uint){
        return growthXPs.length;
    }
    
    function getElementGrowthXP(uint growthXPId) public view returns(uint elementId, uint elementConsum, uint minutesBonus){
        return (growthXPs[growthXPId].elementId, growthXPs[growthXPId].elementConsum, growthXPs[growthXPId].minutesBonus);
    }

    function addStrain(uint[] inElements, uint[] ratioInElements, uint[] outElements, uint[] ratioOutElements, uint timeToGrown) public onlyAdmin{
        strains.push(Object.Strain(inElements, ratioInElements, outElements, ratioOutElements,timeToGrown));
    }

    function getStrainsCount() public view returns(uint) {
        return strains.length;
    }

    function getStrainElementsCount(uint strainId) public view returns(uint inElementsCount, uint outElementsCount){
        return (strains[strainId].inElements.length,strains[strainId].outElements.length);
    }

    function getStrainData(uint strainId, uint idInOutElement, bool isIn, bool isRatio) public view returns(uint){
        if(isIn){
            if(isRatio){
                return strains[strainId].ratioInElements[idInOutElement];
            }
            else{
                return strains[strainId].inElements[idInOutElement];
            }
        }
        else{
            if(isRatio){
                return strains[strainId].ratioOutElements[idInOutElement];
            }
            else{
                return strains[strainId].outElements[idInOutElement];
            }
        }
    }

    function getStrainTimeToGrown(uint strainId) public view returns(uint){
        return strains[strainId].timeToGrown;
    }

    function injectElementFund(uint elementId, uint value) public payable {
        require(elementId < elements.length, "Element ID does not exist");
        if(elements[elementId].isTRC10){
            require(msg.tokenid == elements[elementId].tokenId, "Please inject the right token");
            elements[elementId].availableHarvestBalance = elements[elementId].availableHarvestBalance.add(msg.tokenvalue);
        }
        else{
            TRC20Interface trc20 = TRC20Interface(elements[elementId].trc20Address);
            bool result = trc20.transferFrom(msg.sender,address(this),value);
            require(result,"Can't deposit trc20, make sure unlock for this contract");
            elements[elementId].availableHarvestBalance = elements[elementId].availableHarvestBalance.add(value);
        }
    }

    function fixUntrackableFund(uint elementId) public onlyAdmin{
        require(elementId < elements.length, "Element ID does not exist");
        uint untrackableFund = 0;
        if(elements[elementId].isTRC10){
            untrackableFund = address(this).tokenBalance(elements[elementId].tokenId).sub(elements[elementId].availableHarvestBalance).sub(elements[elementId].totalUserBalance);
        }
        else{
            TRC20Interface trc20 = TRC20Interface(elements[elementId].trc20Address);
            uint currentBalance = trc20.balanceOf(address(this));
            untrackableFund = currentBalance.sub(elements[elementId].availableHarvestBalance).sub(elements[elementId].totalUserBalance);
        }
        require(untrackableFund > 0, "Not have untrackable");
        elements[elementId].availableHarvestBalance = elements[elementId].availableHarvestBalance.add(untrackableFund);
    }

    function depositElement(uint elementId, uint value) public payable returns(uint) {
        require(elementId < elements.length, "Element ID does not exist");
        if(elements[elementId].isTRC10){
            require(msg.tokenid == elements[elementId].tokenId,"Wrong TRC10 deposit");
            require(msg.tokenvalue > 0, "Please send amount token > 0");
            balanceElements[msg.sender][elementId] = balanceElements[msg.sender][elementId].add(msg.tokenvalue);
            elements[elementId].totalUserBalance = elements[elementId].totalUserBalance.add(msg.tokenvalue);
        }
        else{
            TRC20Interface trc20 = TRC20Interface(elements[elementId].trc20Address);
            bool result = trc20.transferFrom(msg.sender,address(this), value);
            require(result,"Can't deposit trc20, make sure unlock for this contract");
            balanceElements[msg.sender][elementId] = balanceElements[msg.sender][elementId].add(value);
            elements[elementId].totalUserBalance = elements[elementId].totalUserBalance.add(value);
        }
    }

    function withdrawElement(uint elementId, uint amount) public payable returns(uint) {
        require(elementId < elements.length, "Element ID does not exist");
        require(balanceElements[msg.sender][elementId] >= amount,"Not enough balance");
        balanceElements[msg.sender][elementId] = balanceElements[msg.sender][elementId].sub(amount);
        elements[elementId].totalUserBalance = elements[elementId].totalUserBalance.sub(amount);
        if(elements[elementId].isTRC10){
            require(address(this).tokenBalance(elements[elementId].tokenId) >= amount,"Contract does not contain enough element balance to withdraw!");
            address(msg.sender).transferToken(amount, elements[elementId].tokenId);
        }
        else{
            TRC20Interface trc20 = TRC20Interface(elements[elementId].trc20Address);
            require(trc20.balanceOf(address(this)) >= amount,"Contract not enough element balance to withdraw!");
            bool result = trc20.transfer(msg.sender,amount);
            require(result,"Can't withdraw trc20, make sure unlock for this contract");
        }
    }
    
    function getMyPlantsCount() public view returns(uint) {
        return plants[msg.sender].length;
    }

    function plant(uint strainId, uint mulSeed) public returns(uint plantId){
        //mulSeed is times of strain. ex: strain need 1 elementX + 2 elemntY = 1 elementZ, mulSeed is 2 mean need, 1*2 elementX, 2*2=4 elementY to grown 1*2 = 2 elementZ
        require(strainId < strains.length, "Treasure does not exist");
        Object.Strain storage strain = strains[strainId];
        for(uint i=0; i < strain.inElements.length; i++){
            require(balanceElements[msg.sender][strain.inElements[i]] >= strain.ratioInElements[i].mul(mulSeed), "Not enough input element");
        }
        for(i=0; i < strain.inElements.length; i++){
            uint amountElementConsum = strain.ratioInElements[i].mul(mulSeed);
            balanceElements[msg.sender][strain.inElements[i]] = balanceElements[msg.sender][strain.inElements[i]].sub(amountElementConsum);
            elements[strain.inElements[i]].availableHarvestBalance = elements[strain.inElements[i]].availableHarvestBalance.add(amountElementConsum);
            elements[strain.inElements[i]].totalUserBalance = elements[strain.inElements[i]].totalUserBalance.sub(amountElementConsum);
        }
        plants[msg.sender].push(Object.Plant(now, 0, 0, mulSeed, strainId));
        return plants[msg.sender].length-1;
    }

    function growthXP(uint plantId, uint growthXPId, uint mulBonus) public {//mulBonus * base value (price and minutes redure) => total price and minus will redure
        require(plantId < plants[msg.sender].length, "TreasureMine does not exist");
        Object.Plant storage plant = plants[msg.sender][plantId];
        Object.Strain storage strain = strains[plant.strainId];
        require(plant.harvestTime == 0, "TreasureMine was mined! Does not need miningxp");
        require(growthXPId < growthXPs.length, "MiningXP does not exist");
        require((now.sub(plant.startTime.sub(plant.bonusTime.mul(TIME_UNIT))) < strain.timeToGrown.mul(TIME_UNIT)), "This treasure completed mining, please vault!");
        uint amountMinusBonus = growthXPs[growthXPId].minutesBonus.mul(mulBonus).sub(1);
        require((now.sub(plant.startTime.sub(plant.bonusTime.add(amountMinusBonus).mul(TIME_UNIT))) < strain.timeToGrown.mul(TIME_UNIT)), "This treasure mining is over bonus time");
        require(balanceElements[msg.sender][growthXPs[growthXPId].elementId] >= growthXPs[growthXPId].elementConsum.mul(mulBonus), "Not enough miningxp element");
        uint amountElementConsum = growthXPs[growthXPId].elementConsum.mul(mulBonus);
        balanceElements[msg.sender][growthXPs[growthXPId].elementId] = balanceElements[msg.sender][growthXPs[growthXPId].elementId].sub(amountElementConsum);
        elements[growthXPs[growthXPId].elementId].availableHarvestBalance = elements[growthXPs[growthXPId].elementId].availableHarvestBalance.add(amountElementConsum);
        elements[growthXPs[growthXPId].elementId].totalUserBalance = elements[growthXPs[growthXPId].elementId].totalUserBalance.sub(amountElementConsum);
        plants[msg.sender][plantId].bonusTime = plants[msg.sender][plantId].bonusTime.add(growthXPs[growthXPId].minutesBonus.mul(mulBonus));
    }

    function harvest(uint plantId) public returns(bool isSuccess) {
        require(plantId < plants[msg.sender].length, "TreasureMine does not exist");
        isSuccess = false;
        Object.Plant storage plant = plants[msg.sender][plantId];
        require(plant.harvestTime == 0, "TreasureMine was mined! Can't do it again");
        Object.Strain storage strain = strains[plant.strainId];
        require((now.sub(plant.startTime.sub(plant.bonusTime.mul(TIME_UNIT))) >= strain.timeToGrown.mul(TIME_UNIT)), "This plan does not complete");
        plant.harvestTime = now;
        for(uint i = 0; i < strain.outElements.length; i++){
            uint outElementId = strain.outElements[i];
            uint ratioElement = strain.ratioOutElements[i];
            uint elementWillGet = ratioElement.mul(plant.mulSeed);
            require(elements[outElementId].availableHarvestBalance >= elementWillGet, "Contract does not have enough mineable elements");
            balanceElements[msg.sender][outElementId] = balanceElements[msg.sender][outElementId].add(elementWillGet);
            elements[outElementId].availableHarvestBalance = elements[outElementId].availableHarvestBalance.sub(elementWillGet);
            elements[outElementId].totalUserBalance = elements[outElementId].totalUserBalance.add(elementWillGet);
        }
        isSuccess = true;
        return isSuccess;
    }
}