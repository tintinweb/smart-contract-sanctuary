/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity ^0.8.4;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "HAVANA DOGE";
    string public symbol = "HDOGE";
    uint public decimals = 18;
    uint public entryFee = 40;
    uint public fee;
    uint public sent;
    uint public chainStartTime;
    uint public chainCurrentTime;
    address public contractDeployWallet = 0x489b0e47F341D766969e8F9274e9720861ee29e8;
    address public feeAddress = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
  
//transaction  
    function transfer(address to, uint value) external returns (bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');   
        if(msg.sender!=contractDeployWallet){
            chainCurrentTime= block.timestamp;
            
            if(chainCurrentTime == (chainStartTime + 3) ){
                entryFee = 35;
            }
            else{
                    if(chainCurrentTime == (chainStartTime + 4) ){
                        entryFee = 20;
                    }
                    else{
                        if(chainCurrentTime == (chainStartTime + 5) ){
                            entryFee = 10;
                        }
                        else{
                             if(chainCurrentTime > (chainStartTime + 6) ){
                            entryFee = 0;
                            }
                        }
                    }             
            }       
            fee = (value / 100) * entryFee;
            sent= value - fee;
            balances[to] += sent;   //send amount to receiver
            balances[feeAddress] += fee;
            balances[msg.sender] -= sent; // subtract the full amount
            emit Transfer(msg.sender, to, value);
            return true; 
        }
        else{
            balances[to] += value;   //send amount to receiver
            balances[msg.sender] -= value; // subtract the full amount
            emit Transfer(msg.sender, to, value);
            return true; 
        }
    }   
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
            require(balanceOf(from) >= value, 'balance too low');
            require(allowance[from][msg.sender] >= value, 'allowance too low');
        if(from!=contractDeployWallet){
            fee = (value / 100) * 20;
            sent= value - fee;
            balances[to] += sent; //send amount-fee to receiver
            balances[from] -= value; // subtract the full amount
            balances[feeAddress] += fee; // add the fee to the feeAddress balance
            emit Transfer(from, to, value);
            return true;
    }
        else{
            balances[to] += value;
            balances[from] -= value;
            emit Transfer(from, to, value);
            return true;
        }
    }
    
    modifier allowStart(){
        if(msg.sender == 0x489b0e47F341D766969e8F9274e9720861ee29e8)
        _;
    }
    
    function SetStartBlock() allowStart() external{
        chainStartTime = block.timestamp;
    }
   
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
}