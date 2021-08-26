/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity 0.4.17;

contract Faucet {
    function withdrow(uint256 amount) public {
        require(amount <= 10**17);
        msg.sender.transfer(amount);
    }
    function () public payable{}
}