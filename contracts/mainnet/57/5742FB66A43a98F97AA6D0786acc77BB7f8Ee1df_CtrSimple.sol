/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

contract CtrSimple {
    uint public myUint = 10;
    
    function setUint(uint _myUint) public {
        myUint = _myUint;
    }
    
    function doubleUint() public {
        myUint = 2 * myUint;
    }
    
}