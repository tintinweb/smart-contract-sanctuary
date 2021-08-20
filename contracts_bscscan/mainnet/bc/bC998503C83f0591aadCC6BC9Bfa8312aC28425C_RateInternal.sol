pragma solidity >= 0.5.0 < 0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";

contract RateInternal is Ownable {
    
    using SafeMath for uint256;
    
    uint public borrow_rate_level_one = 80;
    uint public borrow_rate_level_second = 90;
    uint public supply_rate_level_one = 80;
    uint public supply_rate_level_second = 90;
    uint public modulus_borrow_one_a = 1;
    uint public modulus_borrow_one_b = 0;
    uint public modulus_borrow_second_a = 1;
    uint public modulus_borrow_second_b = 0;
    uint public modulus_borrow_third_a = 1;
    uint public modulus_borrow_third_b = 0;
    uint public modulus_supply_one_a = 1;
    uint public modulus_supply_one_b = 0;
    uint public modulus_supply_second_a = 1;
    uint public modulus_supply_second_b = 0;
    uint public modulus_supply_third_a = 1;
    uint public modulus_supply_third_b = 0;
    
    function setBorrowRateLevelOne(uint level) external onlyOwner{
	    borrow_rate_level_one = level;
	} 
	function setBorrowRateLevelSecond(uint level) external onlyOwner{
	    borrow_rate_level_second = level;
	} 
	function setSupplyRateLevelOne(uint level) external onlyOwner{
	    supply_rate_level_one = level;
	} 
	function setSupplyRateLevelSecond(uint level) external onlyOwner{
	    supply_rate_level_second = level;
	} 
	
	function setModulusSupply(uint onea,uint oneb,uint seconda,uint secondb,uint thirda,uint thirdb) external onlyOwner{
	    modulus_supply_one_a = onea;
        modulus_supply_one_b = oneb;
         modulus_supply_second_a = seconda;
         modulus_supply_second_b = secondb;
         modulus_supply_third_a = thirda;
         modulus_supply_third_b = thirdb;
	} 
	function setModulusBorrow(uint onea,uint oneb,uint seconda,uint secondb,uint thirda,uint thirdb) external onlyOwner{
	   modulus_borrow_one_a = onea;
        modulus_borrow_one_b = oneb;
         modulus_borrow_second_a = seconda;
         modulus_borrow_second_b = secondb;
         modulus_borrow_third_a = thirda;
         modulus_borrow_third_b = thirdb;
	} 
	
	function getUsedRate(uint256 totalLoans,uint256 totalDeposits) public pure returns (uint256) {  
        require(totalDeposits > 0 ,"total deposite 0!");
		return totalLoans.mul(10**12).div(totalDeposits);
	}
	
	
	function getCurrentBorrowRate(int256 totalLoans,int256 totalDeposits) public view returns (uint ret) {  
	    uint usedRate = getUsedRate(uint(totalLoans), uint(totalDeposits)).div(10**10);
	    if(usedRate <= borrow_rate_level_one)
	    {
	        ret = getUsedRate(uint(totalLoans), uint(totalDeposits)).mul(100).mul(3).div(10).mul(modulus_borrow_one_a).add(modulus_borrow_one_b.add(1).mul(10**12));
	    }else if(usedRate <= borrow_rate_level_second)
	    {
	        ret = getUsedRate(uint(totalLoans), uint(totalDeposits)).mul(1100).div(10).mul(modulus_borrow_second_a).add(modulus_borrow_second_b.mul(10**12)).sub(63*(10**12));
	    }else {
	        ret = getUsedRate(uint(totalLoans), uint(totalDeposits)).mul(600).mul(modulus_borrow_third_a).add( modulus_borrow_third_b.mul(10**12)).sub(504*(10**12));
	    }
	    ret = ret.div(3153600000);
	   
	}
	
	function getCurrentSupplyRate(int256 totalLoans,int256 totalDeposits) public view returns (uint ret) { 
	    uint usedRate = getUsedRate(uint(totalLoans), uint(totalDeposits)).div(10**10);
	    if(usedRate <= supply_rate_level_one)
	    {
	        ret =  modulus_supply_one_a.mul(usedRate).mul(usedRate).mul(3).mul(10**9).add(modulus_supply_one_b.mul(10**12)).add(2*(10**11));
	    }else if(usedRate <= supply_rate_level_second)
	    {
	        ret =  modulus_supply_second_a.mul(usedRate).mul(usedRate).mul(6).mul(10**9).add(modulus_supply_second_b.mul(10**12)).sub(19*(10**12));
	    }else {
	        ret =  modulus_supply_third_a.mul(usedRate).mul(usedRate).mul(3).mul(10**10).add(modulus_supply_third_b.mul(10**12)).sub(2134*(10**11));
	    }
	    
	    ret = ret.div(3153600000);
	}
   
}