/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

contract Faucet{
    function withdraw(uint withdraw_amount) public{
        require(withdraw_amount <= 100000000000000000);

        msg.sender.transfer(withdraw_amount);
    }

    function () payable public {
        
    }
}