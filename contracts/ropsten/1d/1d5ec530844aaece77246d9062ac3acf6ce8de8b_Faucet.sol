/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

//pragma solidity ^0.8.0;
//pragma solidity ^0.8.0
pragma solidity ^0.4.19;
contract Faucet {
    function withdraw(uint amount) public {
        require (amount <= 100000000000000000000000);

        msg.sender.transfer(amount);
    }

    function () public payable {}
}