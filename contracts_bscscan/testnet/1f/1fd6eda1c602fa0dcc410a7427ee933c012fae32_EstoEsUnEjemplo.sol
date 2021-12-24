/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

pragma solidity ^0.8.6;

contract EstoEsUnEjemplo {

    mapping (address => uint) balanceOf;

    function Deposit() external payable {
        balanceOf[msg.sender] = balanceOf[msg.sender] + msg.value;
    }

    function Withdraw() external{
        require(balanceOf[msg.sender] > 0);

        uint256 withdraw_amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;

        payable(msg.sender).transfer(withdraw_amount);

        (bool sent, bytes memory data) = payable(msg.sender).call{value: withdraw_amount}("Example");
        
        if(!sent) {
            balanceOf[msg.sender] += withdraw_amount;
        }
    }

    function readBalances(address checkBalance) external view returns(uint256){
        return balanceOf[checkBalance];
    }
}