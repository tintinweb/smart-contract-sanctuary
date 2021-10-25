/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    

    mapping(address => uint256) _balances;
    
    function deposit() public payable{
        require(msg.value >= uint256(200000000000000000), "Not enough ETH!");
        _balances[msg.sender] += ethToWei(1);
    }
    
    function withdraw() public payable{
        payable(msg.sender).transfer(ethToWei(1));
        _balances[msg.sender] -= ethToWei(1);
    }
    
    function checkBalance() public view returns(uint256 balance){
        return _balances[msg.sender];
    }
    function checkBalance2(address addr_input) public view returns(uint256 balance){
        return _balances[addr_input];
    }
    function ethToWei(uint256 eth_value) internal returns(uint256 ethwei){
        return uint256(eth_value * 1000000000000000000);
    }
    
    function weiToEth(uint256 wei_value) internal returns(uint256 weieth){
        return uint256(wei_value / 1000000000000000000);
    }


}