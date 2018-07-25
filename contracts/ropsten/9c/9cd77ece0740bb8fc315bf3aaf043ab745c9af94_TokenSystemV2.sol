pragma solidity ^0.4.24;

contract TokenSystemV2 {
    
    address owner;
    mapping(address => uint256) public balances;
    mapping(address => address[]) public allowance;
    
    constructor() public{
        owner = msg.sender;
        balances[msg.sender] = 10000;
    }
    
    function transfer(address to, uint amount) public{
        if(balances[msg.sender] < amount){
            revert();
        }
        balances[to] += amount;
        balances[msg.sender] -= amount;
    }
    
    function isAllowed(address a) private view returns(bool){
        bool isAllowedAddress = false;
        for(uint i=0; i<allowance[msg.sender].length; i++){
            isAllowedAddress = isAllowedAddress && (allowance[msg.sender][i] == a);
        }
        return isAllowedAddress;
    }
    
    function allow(address _toAllow) public {
        
        for(uint i = 0; i<allowance[msg.sender].length; i++){
            if(allowance[msg.sender][i] == 0x0){
               allowance[msg.sender][i] = _toAllow; 
            }
        }
        
    }
    
    function getBalanaceOf(address x) public view returns(uint b) {
        return balances[x];
    }
}