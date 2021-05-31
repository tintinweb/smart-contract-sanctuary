/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

pragma solidity ^0.4.23;
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
}


contract Tools{
    
    function batchTransferETH(uint256 eachAmount,address[] tos) payable public returns (bool){
        uint256 addressCount=tos.length;
        require(msg.value==eachAmount*addressCount,"amount not match");
        
        for(uint256 i=0;i<addressCount;i++){
            address(tos[i]).transfer(eachAmount);
        }
        return true;
    }
    
    //需要先approve给合约权限
    function batchTransferERC20(address erc20Contract,uint256 eachAmount,address[] tos) public returns (bool){
        ERC20 erc20=ERC20(erc20Contract);
        uint256 addressCount=tos.length;
        
        for(uint256 i=0;i<addressCount;i++){
            erc20.transferFrom(msg.sender,tos[i],eachAmount);
        }
        return true;
    }
}