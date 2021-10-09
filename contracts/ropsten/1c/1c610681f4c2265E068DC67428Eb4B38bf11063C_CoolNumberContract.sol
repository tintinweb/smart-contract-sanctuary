/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

contract CoolNumberContract {
    uint public coolNumber = 10;
    
    function setCoolNumber(uint _coolNumber) public {
        coolNumber = _coolNumber;
    }
}