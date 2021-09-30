/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IERC20{
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient,uint256 amount) external returns(bool);
    function allowance(address owner,address spender) external view returns(uint256);
    function approve(address spender,uint256 amount) external returns(bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns(bool);
    
    
    event Transfer(address indexed from,address indexed to,uint256 amount);
    event Approval(address indexed owner,address indexed spender,uint256 amount);
}

contract EVToken is IERC20{
    mapping(address=>uint256) private _balances;
    mapping(address=>mapping(address=>uint256)) private _allowance;
    
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    
    constructor(){
        _name="ElvinToken";
        _symbol="EVT";
        _totalSupply=10000000;
    }
    
    function name() public view override returns(string memory){
        return _name;
    }
    
    function symbol() public view override returns(string memory){
        return _symbol;
    }
    
    function decimals() public pure override returns(uint8){
        return 0;
    }
    
    function totalSupply() public view override returns(uint256){
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns(uint256){
        return _balances[account];
    }
    
    function transfer(address recipient,uint256 amount) public override returns(bool){
        _transfer(msg.sender,recipient,amount);
        return true;
    }
    
    function transferFrom(address sender,address recipient,uint256 amount) public override returns(bool){

        uint256 currentAllowance=_allowance[sender][msg.sender];
        
        require(currentAllowance>=amount,"");
        
        _transfer(sender,recipient,amount);
        
        _approve(sender,msg.sender,currentAllowance-amount);
        
        return true;
        
    }
    
    function approve(address spender,uint256 amount) public override returns(bool){
        _approve(msg.sender,spender,amount);
        return true;
    }
    
    function allowance(address owner,address spender) public view override returns(uint256){
        return _allowance[owner][spender];
    }
    
    function increaseAllowance(address spender,uint256 addedValue) public returns(bool){
        _approve(msg.sender,spender,_allowance[msg.sender][spender]+addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender,uint256 subtractedValue) public returns(bool){
        uint256 currentAllowance=_allowance[msg.sender][spender];
        require(currentAllowance>=subtractedValue,"");
        
        _approve(msg.sender,spender,currentAllowance-subtractedValue);
        
        return true;
    }
    
    function _mint(address account,uint256 amount) internal{
        require(account!=address(0),"");
        
        _totalSupply+=amount;
        _balances[account]+=amount;
        
        emit Transfer(address(0),account,amount);
    }
    
    function _burn(address account,uint256 amount) internal{
        require(account!=address(0),"");
        
        uint256 accountBalance=_balances[account];
        require(accountBalance>=amount,"");
        
        _balances[account]=accountBalance-amount;
        
        _totalSupply-=amount;
        
        emit Transfer(account,address(0),amount);
    }
    
    
    function _transfer(address sender,address recipient,uint256 amount) internal{
        require(sender!=address(0),"");
        require(recipient!=address(0),"");
        
        uint256 senderBalance=_balances[sender];
        require(senderBalance>=amount);
        
        _balances[sender]=senderBalance-amount;
        _balances[recipient]+=amount;
        
        emit Transfer(sender,recipient,amount);
    }
    
    function _approve(address owner,address spender,uint256 amount) internal{
        require(owner!=address(0),"");
        require(spender!=address(0),"");
        
        _allowance[owner][spender]=amount;
        
        emit Approval(owner,spender,amount);
    }

}