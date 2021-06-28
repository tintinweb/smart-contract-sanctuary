/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity >=0.8.0;



contract SpeedWagonFondToken{
    string public constant name = 'SpeedwagonFond';
    string public constant symbol = 'SWF';
    uint8 public constant decimals = 3;
    uint totalSupply = 0;
    
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    
    event Transfer(address, address, uint);
    event Approval(address, address, uint);
    
    address owner;
    constructor(){
        owner = msg.sender;
    }
    
    modifier OwnerRequired(){
        require(msg.sender == owner);
        _;
    }
    
    
    function mint(address _address, uint _amount) OwnerRequired public payable{
        require(totalSupply + _amount > totalSupply, "Too many tokens issued");
        balances[_address] += (_amount / (10*decimals));
        totalSupply += (_amount / (10*decimals));   
    }
    
    function balanceOf(address _addr) public view returns(uint){
        return balances[_addr];
    }
    
    function balanceOf() public view returns(uint){
        return balances[msg.sender];
    }
    
    function transfer(address _reciever, uint value) public payable{
        address myAddr = msg.sender;
        require(balances[myAddr] - value >= 0 && balances[_reciever] + value >= balances[_reciever]);
        require(allowance(msg.sender, _reciever) > 0);
        balances[myAddr] -= value;
        balances[_reciever] += value;
        allowed[msg.sender][_reciever] -= value;
        emit Transfer(msg.sender, _reciever, value);
    }
    
    
    function transferFrom(address _sender, address _reciever, uint value) public payable{
        require(balances[_sender] - value >= 0 && balances[_reciever] + value >= balances[_reciever]);
        require(allowance(_sender, _reciever) > 0);
        balances[_sender] -= value;
        balances[_reciever] += value;
        allowed[_sender][_reciever] -= value;
        emit Transfer(_sender, _reciever, value);
        emit Approval(_sender, _reciever, value);
    }
    
    function approve(address _reciever, uint value) public payable{
        require(balances[msg.sender] >= value);
        allowed[msg.sender][_reciever] = value;
        emit Approval(msg.sender, _reciever, value);
    }
    
    function allowance(address _sender, address _reciever) public view returns(uint){
        return allowed[_sender][_reciever];
    }
}