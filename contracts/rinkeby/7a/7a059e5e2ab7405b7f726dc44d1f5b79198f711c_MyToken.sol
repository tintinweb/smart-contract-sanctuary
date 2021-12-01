/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

contract MyToken {
    address public controller;

    function changeController(address newController) external {
        controller = newController;
    }
}