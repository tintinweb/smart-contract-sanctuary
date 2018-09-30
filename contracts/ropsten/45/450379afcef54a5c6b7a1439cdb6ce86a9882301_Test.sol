pragma solidity ^0.4.24;

contract Test {
    uint256 public kickOff;
    
    uint256[] public periods;
    uint8[] percentages;
    
    constructor() public {
        kickOff = 0;
        
        periods.push(120);
        periods.push(180);
        periods.push(240);
        periods.push(320);
        periods.push(380);
        
        percentages.push(5);
        percentages.push(10);
        percentages.push(15);
        percentages.push(20);
        percentages.push(50);
    }
    
    function start() public returns (bool) {
        kickOff = now + 60 * 5;
    }
    
    function getUnlockedPercentage() public view returns (uint256) {
        if (kickOff == 0 ||
            kickOff > now)
        {
            return 100;
        }
        
        uint256 unlockedPercentage = 0;
        for (uint256 i = 0; i < periods.length; i++) {
            if (kickOff + periods[i] <= now) {
                unlockedPercentage = unlockedPercentage + percentages[i];
            }
        }
        
        if (unlockedPercentage > 100) {
            return 0;
        }
        
        return 100 - unlockedPercentage;
    }
    
    function getPeriods() public view returns (uint256[]) {
        return periods;
    }
    
    function getPercentages() public view returns (uint8[]) {
        return percentages;
    }
    
    function getNow() public view returns (uint256) {
        return now;
    }
}