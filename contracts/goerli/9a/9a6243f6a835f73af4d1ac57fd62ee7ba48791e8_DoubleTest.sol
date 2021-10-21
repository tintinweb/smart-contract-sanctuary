/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

contract DoubleTest {
    address nop;
    function send() external payable {
        payable(nop).transfer(msg.value);
    }
    function defineNop(address _nop) public {
        nop = _nop;
    }
}