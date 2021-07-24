/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

pragma solidity >=0.4.22 <0.9.0;

contract testParam {
    uint256 number;
    uint256 pragma2;
    
    Voter pragma1;
   struct Voter1 {
        uint weight;
    }    
    
   struct Voter2 {
        uint weight;
        Voter1 vote1;
    }    
    struct Voter3 {
        uint weight;
        Voter2 vote2;
    }    
    
    struct Voter {
        uint weight;
        Voter3 vote3;
    }    
    
    function delegate (Voter memory p1, uint256 p2) public {
        pragma1=p1;
        pragma2=p2;
    }
    
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }    

}