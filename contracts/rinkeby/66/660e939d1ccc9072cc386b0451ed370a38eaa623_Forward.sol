/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

contract Forward {
    function forward(address payable target) payable public {
        target.transfer(msg.value);
    }
}