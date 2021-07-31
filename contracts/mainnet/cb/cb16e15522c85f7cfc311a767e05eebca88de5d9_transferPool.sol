/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ERCToken {
    function transfer(address to, uint256 value) external returns (bool success);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}
contract transferPool {
    
    receive() external payable {}
    fallback() external payable {}
    address private owner;
    ERCToken private token;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
    
    function transferETH( address[] memory _tos) public payable returns(bool){
        require(msg.value > 0, 'send ETH must > 0');
        require(_tos.length > 0, '_tos.length must > 0');
        require(msg.value > _tos.length, 'value must > _tos.length');
        uint256 average = (msg.value / _tos.length);
        for (uint32 i = 0; i < _tos.length; i++) {
            payable(_tos[i]).transfer(average);
        }
        return true;
    }
	//调用之前要先approve,合约才有权限转当前地址的币
    function transferToken(address contract_address, address[] memory _tos, uint256 amount) public returns(bool){
        require(amount > 0, 'send Token must > 0');
        require(_tos.length>0,'_tos.length must > 0');
        require(amount > _tos.length, 'amount must > _tos.length');
        token = ERCToken(contract_address);
        uint256 average = (amount / _tos.length);
        for(uint32 i=0;i<_tos.length;i++){
            bool success = token.transferFrom(msg.sender, _tos[i] ,average);
            require(success==true,'transferFrom fail');
        }
        return true;
    }
    
    function claimETH() public onlyOwner{
        payable(owner).transfer(address(this).balance);
    }
    function claimToken(address contract_address) public onlyOwner {
        token = ERCToken(contract_address);
        bool success = token.transfer(owner,token.balanceOf(address(this)));
        require(success==true,'transfer fail');
    }
    
}