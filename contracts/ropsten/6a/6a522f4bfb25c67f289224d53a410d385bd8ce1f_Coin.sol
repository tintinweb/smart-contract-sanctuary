/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

contract Coin {

    function transfer(address payable receiver, uint256 amount) public payable {
        receiver.transfer(amount);
    }
    
}