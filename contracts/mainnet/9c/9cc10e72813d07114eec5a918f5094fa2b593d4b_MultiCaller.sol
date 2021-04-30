/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract MultiCaller  {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

  
    address public owner = msg.sender;

    string public name;
    string public symbol;


    constructor  ()  {
        name = "MultiCaller";
        symbol = "MKC";
  
    }

   
    function withdrawAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        require(owner==msg.sender);
        return IERC20(tokenAddress).transfer(owner, tokens);
    }
    
        
    function withdrawETH(address payable to, uint amount) public returns (bool) {
        require(msg.sender==owner);
        to.transfer(amount);
        return true;
    }
    
     function ercBalanceMultiple(address[] memory tokenAddress, address walletAddress) public view returns  (uint [] memory ,address []  memory) {
         uint[]    memory allBalance = new uint[](tokenAddress.length);
         address[]    memory allContract = new address[](tokenAddress.length);
         for(uint i=0; i<tokenAddress.length;i++){
            allBalance[i]=IERC20(tokenAddress[i]).balanceOf(walletAddress);
            allContract[i]=tokenAddress[i];
           
            
         }
         return (allBalance,allContract);
    }
    
    receive() external payable {}
    
    function ercSingleBalancee(address tokenAddress, address userAddr) public view returns  (uint  balance,address  contractAddr) {
         
        balance=IERC20(tokenAddress).balanceOf(userAddr);
        contractAddr=tokenAddress;
            
        return (balance,contractAddr);
    }
    
  

  
}