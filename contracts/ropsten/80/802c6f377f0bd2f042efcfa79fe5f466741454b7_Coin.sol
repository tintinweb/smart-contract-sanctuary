/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

contract Coin {

    function transfer(address payable receiver) public payable {
        receiver.transfer(msg.value);
    }
    
}