/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

contract Test3 {
    uint public myUint;

    function setUint(uint _myUint) public {
        myUint = 3*_myUint;
    }

    function killme() public {
        selfdestruct(payable(msg.sender));
    }

}