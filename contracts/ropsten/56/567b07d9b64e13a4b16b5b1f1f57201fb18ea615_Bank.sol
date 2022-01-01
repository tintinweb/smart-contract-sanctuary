/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IERC20{
    
    function totaleSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient,  uint256 amount) external returns(bool);
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Bank is IERC20{
    
    string public constant name="THE MASTER'S BANK COIN";
    string public constant symbol="TMBC";
    string public constant decimals="18";
    uint256 totaleSupply_ =1000000000;
    
    address admin;
   
    event Approval(address indexed tokenOwner, address indexed spender,uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
       mapping(address => uint) balances;
       mapping(address => mapping(address => uint)) allowed;
    
    

    constructor() public{
        
        balances[msg.sender] = totaleSupply_;
        admin =msg.sender;
    }
    function totaleSupply() public override view returns (uint256){
        return totaleSupply_;
    }
    function balanceOf(address tokenOwner) public override view returns (uint256){
        return balances[tokenOwner];
    }
    function transfer(address receiver,uint256 numTokens) public override returns (bool){
        
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    modifier onlyAdmin{
        require (msg.sender == admin, " Only Admin can run thi function");
        _;
    }
    function mint(uint256 _qty) public onlyAdmin returns(uint256){
        totaleSupply_ += _qty;
        balances[msg.sender] += _qty;
        
        return totaleSupply_;
    }
    
     function burn(uint256 _qty) public onlyAdmin returns(uint256){
        require(balances[msg.sender]>= _qty);
        totaleSupply_ -= _qty;
        balances[msg.sender] -= _qty;
        
        return totaleSupply_;
    }
    function allowance(address _owner,address _spender) public view returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
    
     function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        uint256 allowance1 =allowed[_from][msg.sender];
        require(balances[_from]>= _value && allowance1 >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        // if (allowance < MAX_UINT256){
        //     allowed[_from][msg.sender] -= _value;
            
        // }
        allowed[_from][msg.sender]-= _value;
        emit Transfer(_from,_to,_value);
        return true;
    }
    
    }