/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

pragma solidity ^0.8.7;

contract EarthRecoveryToken {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "RecoverEarthToken";
    string public symbol = "RET";
    uint public decimals = 18;
    
    mapping(address => bool) private exclidedFromFee;
    mapping(address => bool) private ListOfInvestors; // List of all Investors
    
    // for intern projects in Future
    address projectStoreWallet = 0xb7e59D2995A802668460b401fDD1E4ac0Fcc7876;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance not enough for transaction');

        uint BackupForProject = (value/1000)*1;     
        
        
        balances[to] += (value-BackupForProject);
        balances[projectStoreWallet] += BackupForProject;
        balances[msg.sender] -= (value);
        emit Transfer(msg.sender, to, (value-BackupForProject));
        
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        uint BackupForProject = (value/1000)*1;     
        
        require(balanceOf(from) >= value, 'balance not enough for transaction');
        require(allowance[from][msg.sender] >= value, 'allowance not enough for transaction');
        balances[to] += (value-BackupForProject);
        balances[projectStoreWallet] += BackupForProject;
        balances[from] -= value;
        emit Transfer(from, to,  (value-BackupForProject));
        
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}