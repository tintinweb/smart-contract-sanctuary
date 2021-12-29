/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

pragma solidity ^0.8.9;

contract TimacumToken{

    string public name ="Timacum";
    string public symbol="TMC";
    uint256 public totalSupply = 1000000000000000;

    uint public decimals=8;
    mapping(address => uint256) balances;
    address public owner;
 address public addr1=0xdba24d6953Dc13864138d9A652B3926082fa46AA;
    address public addr2=0xB15347EBC39CA60D839E8a77d6569B6eeD39F1a8;
    address public addr3=0xaF4357C70456b78b043FcAB62E01F9e7650dC895;
     uint256 public newTotalSupply;
constructor(){
    owner = msg.sender;
    balances[owner]= 100000000000000;//10 posto
    newTotalSupply = totalSupply-balances[owner];
    balances[addr1]=newTotalSupply/3;
    balances[addr2]=newTotalSupply/3;
    balances[addr3]=newTotalSupply/3;
}

   function transfer(address to, uint256 amount) external {
       
        require(balances[msg.sender] >= amount, "Not enough tokens");

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

}