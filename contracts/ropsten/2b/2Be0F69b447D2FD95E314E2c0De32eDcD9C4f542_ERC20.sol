/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;
interface IERC20{
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient,uint256 amount) external returns(bool);
    function allowance(address owner,address spender) external view returns(uint256);
    // This is to check that the person who we give Approval to transfer token fron 
    // our account.How many tokens Approval he still left;
    function approve(address spender,uint256 amount) external returns(bool);
    // This is to approve someone how to transfer certain amount of token from your 
    // account to someone else;
    function transferFrom(address sender,address recipient,uint256 amount) external returns(bool);
    // spender will use the function transferFrom to transfer amount;
    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}
contract ERC20 is IERC20{
    mapping (address=>uint256) private _balances;
    mapping (address=>mapping(address=>uint256)) private _allowances;

    uint256 private _totalSupply;
    address public owner;
    
    string public name;
    string public symbol;
    uint256 public decimals;
     uint256 private immutable _cap;
     // beneficiary of tokens after they are released
    address private immutable _beneficiary;
// timestamp when token release is enabled
    uint256 private immutable _releaseTime;
    uint256 private immutable _amount;
     
    constructor(
        uint256 amount_,
        address beneficiary_,
        uint256 releaseTime_
        
    ) {
        require(releaseTime_+block.timestamp > block.timestamp, "TokenTimelock: release time is before current time");
        _amount = amount_;
        _beneficiary = beneficiary_;
        _releaseTime =(block.timestamp + releaseTime_);
        name="Token made by Hafiz Sayyed Ali Hamdani";
        symbol="SAH";
        decimals=18;
        owner=msg.sender;
        _totalSupply=50*10**decimals;
        _balances[owner]= _totalSupply;
        _cap = 55*10**decimals;
        
        emit Transfer(address(this),owner,_totalSupply);
    }
    
    function totalSupply() public view override returns(uint256){
        return _totalSupply;
    }
     function balanceOf(address account) public override view returns(uint256){
         return _balances[account];
     }
     function transfer(address recipient,uint256 amount) public virtual override returns(bool){
         address sender=msg.sender;
         require(sender!=address(0),"address should not be 0");
         require(recipient!=address(0),"address should not be 0");
         require(_balances[sender]>amount,"transfer amount execdes balances");
         
         _balances[sender]=_balances[sender]-amount;
         
         _balances[recipient]=_balances[recipient]+amount;
         
         emit Transfer(sender,recipient,amount);
         return true;
     }
      function allowance(address tokenowner,address spender) public view virtual override returns(uint256){
          return _allowances[tokenowner][spender];
      }
      
       function approve(address spender,uint256 amount) public virtual override returns(bool){
           address tokenOwner=msg.sender;
           require(tokenOwner!=address(0),"approve from the zero address");
           require(spender!=address(0),"Approve from the zero address");
           
           _allowances[tokenOwner][spender]=amount;
           emit Approval(tokenOwner,spender,amount);
           return true;
           
       }
       
       function transferFrom(address tokenOwner,address recipient,uint256 amount) public virtual override returns(bool){
       address spender=msg.sender;
       uint256 _allowance=_allowances[tokenOwner][spender];
       require(_allowance>amount,"Transfer amount execdes allowance");
           _allowance=_allowance-amount;
           _balances[tokenOwner]=_balances[tokenOwner]-amount;
           _balances[recipient]=_balances[recipient]+amount;
             emit Transfer(tokenOwner,recipient,amount);
             _allowances[tokenOwner][spender]=_allowance;
             emit Approval(tokenOwner,recipient,amount);
         return true;
           
       }
       function cap() public view virtual returns (uint256) {
        return _cap;
    }
    function Generate_Token(uint256 amount) public{
        require(msg.sender==owner,"Only owner can generate token");
        require(_totalSupply + amount <= cap(), "ERC20Capped: cap exceeded");
        _totalSupply=_totalSupply+amount;
    }
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }
    function Amount() public view virtual returns (uint256) {
        return _amount;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }/**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");
        require(_amount > 0, "TokenTimelock: no tokens to release");
        transfer(beneficiary(), _amount);
    }
}