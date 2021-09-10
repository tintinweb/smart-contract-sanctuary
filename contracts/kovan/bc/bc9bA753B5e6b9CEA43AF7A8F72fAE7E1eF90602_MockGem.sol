/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

contract MockGem {
    
    uint public count = 0;
    uint public lk = 0;
    uint public ls = 0;
    
    function mine(uint kind, uint salt) external {
        require(kind < salt, "Error: kind >= salt");
        count++;
        lk = kind;
        ls = salt;
    }

}