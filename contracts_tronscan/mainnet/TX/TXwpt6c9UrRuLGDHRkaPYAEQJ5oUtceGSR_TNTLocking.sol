//SourceUnit: TronNinjaTeamVesting.sol

pragma solidity >=0.5.0 <0.6.0;


/*

The TronNinjas TNT vesting contract - This contact is used to lock in the team 100 million TNT for 12 months from today, 24/01/22 – 
After this date, only 1 Million TNT can be taken out per month after  the initial year period.

Special thanks to Crypto Rhino - Tron Ninjas Team

*/


contract ITRC20 {
    function balanceOf(address account) external view returns (uint){}
    function transfer(address recipient, uint amount) external returns (bool){}
    function allowance(address owner, address spender) external view returns (uint){}
    function approve(address spender, uint amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint amount) external returns (bool){}
    function decimals() public view returns (uint8) {}
}


contract TNTLocking{
    address owner;
    uint YEAR1 = 31536000;
    uint MONTH1 = 2628000;
    ITRC20 TNTToken;
    uint nextAllowanceTime;
    uint lockStartTime;
    uint lockAmount;
    uint monthNumber=0;
    uint monthlyAllow = 1e12;
    constructor(address tntTokenAddr) public{
        TNTToken = ITRC20(tntTokenAddr);
        owner = msg.sender;
    }
	// used in case of error in main contract
    function failsafe() public{
        require(now>=lockStartTime+(YEAR1*2));
        TNTToken.transfer(owner, TNTToken.balanceOf(address(this)));
    }
    
    function lockTNT(uint amount) public{
        require(msg.sender == owner);
        require(TNTToken.transferFrom(owner, address(this), amount));
        lockStartTime = now;
        nextAllowanceTime = lockStartTime+YEAR1;
    }
    
    function monthlyAllowance() view public returns(uint){
        if(monthlyAllow>TNTToken.balanceOf(address(this))){
            return TNTToken.balanceOf(address(this));
        }else{
            return monthlyAllow;
        }
    }
    
    function claimMonthly() public{
        require(msg.sender == owner);
        require(now>=nextAllowanceTime);
        TNTToken.transfer(owner, monthlyAllowance());
        nextAllowanceTime = nextAllowanceTime+MONTH1;
    }
}