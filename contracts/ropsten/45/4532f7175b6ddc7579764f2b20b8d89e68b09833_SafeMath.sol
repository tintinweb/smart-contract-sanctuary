pragma solidity ^0.4.15;

library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        constant 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function pwr(uint256 x, uint256 y)
        internal 
        constant 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
    
    function pwrFloat(uint256 tar,uint256 numerator,uint256 denominator,uint256 pwrN) public constant returns(uint256) {
        for(uint256 i=0;i<pwrN;i++){
            tar = tar * numerator / denominator;
        }
        return tar ;
        
    }

    
    function mulRate(uint256 tar,uint256 rate) public constant returns (uint256){
        return tar *rate / 100;
    }
 
    
    
}