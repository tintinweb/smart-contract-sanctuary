/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

pragma solidity 0.8.6;


contract Faucet {
    // Accept any incoming amount
    receive() external payable {}

    // Give out ether to anyone who asks
    function withdraw(uint withdraw_amount) public {


        payable(msg.sender).transfer(withdraw_amount);
    }
    function balance()external view returns(uint256){
        return payable(address(this)).balance;
    }

    function balancemsgsender()external view returns(uint256){
        return payable(msg.sender).balance;
    }
}