/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

contract DeCalled {
    address public owner;
    
    function transfer(uint256 amount) public payable {
        payable(owner).transfer(amount);
    }
}