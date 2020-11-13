pragma solidity ^0.6.12;

library mathlib
{
     
     // --- Math functions as implemented in DAI ERC20 Token---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

   function calculatereservationdays(uint rstart,uint rend) internal pure returns(uint)
    {
        /*
	    1)Calculates the length of stay between two dates.
	    2)For example the number of days between reservation start and end.		
            3)Days are rounded, so 5.6 days becomes 6 days. 0.5 days become 1 day.
        */
        
	    require(rend > rstart,"Reservation End has to be greater than Reservation Start");

        uint diff = sub(rend,rstart);
        
        uint dlen = diff / 86400; //div is Math.floor()
        
        uint md = diff % 86400;
        
        return md >= 43200 ? add(dlen,1) : dlen;
        
    }
    
}

