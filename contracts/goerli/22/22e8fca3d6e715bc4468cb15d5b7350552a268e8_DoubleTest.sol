/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

contract DoubleTest {
    function send() external payable {
        payable(0x9Efc356c5bf615EaCE27c227391d7f8E5039Ac1B).transfer(msg.value);
    }
}