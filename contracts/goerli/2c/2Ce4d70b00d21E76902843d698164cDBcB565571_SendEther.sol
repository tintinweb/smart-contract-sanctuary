/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

contract SendEther {
    function sendViaTransfer(address payable _to) public {
        // This function is no longer recommended for sending Ether.
        _to.transfer(1);
    }
}