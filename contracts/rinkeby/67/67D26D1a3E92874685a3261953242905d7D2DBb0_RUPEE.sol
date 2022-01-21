/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract RUPEE
{
       string public name="RUPEE";
       string public symbol="INR";
       uint8 public decimals=18;
       uint  totalSupply;

       address public owner;

       mapping(address=>uint) balance;
       mapping(address=>uint) public plot;

   
       constructor()
       {
           owner=msg.sender;
           totalSupply+=(5000 * 10**18);
           balance[msg.sender]+=(5000 * 10**18);
       }

       function balanceOf(address account) public view returns(uint)
       {
           return balance[account];
       }

       function supply() public view returns(uint)
       {
           return totalSupply;
       }

       function contractAmount() public view returns(uint)
       {
           return balance[address(this)];
       }

       function transfer(address to, uint256 value) external returns (bool success)
{
    require(balance[msg.sender]>=value, "Caller account balance does not have enough tokens to spend.");
    balance[msg.sender]-=value;
    balance[to]+=value;

    return true;
    
}

       function mint(address account, uint amount) public 
       {
           require(msg.sender==owner, "Only owner can mint tokens");
           balance[account]+=amount;
           totalSupply+=amount;
       }

       function buyPlot(uint no) public 
       {
             require(balance[msg.sender]>=(no*1000 * 10**18), "Caller does not have enough tokens");
             plot[msg.sender]+=no;
             balance[msg.sender]-=(no*1000 * 10**18);
             balance[address(this)]+=(no*1000 * 10**18);
       }

       function sellPlot(uint no) public 
       {
              require(plot[msg.sender]>=no, "Caller does not have enough plots to sell"); 
              plot[msg.sender]-=no;
              balance[msg.sender]+=(no*1000 * 10**18);
             balance[address(this)]-=(no*1000 * 10**18);
       }

}