/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

contract ContractA {
    receive() external payable {
        if (msg.value > 0) {
            revert("IS THIS A REVERT?");
        }
    }
}
/* can I add comments to this */
/* without messing up */
/* etherscan source code checking? */