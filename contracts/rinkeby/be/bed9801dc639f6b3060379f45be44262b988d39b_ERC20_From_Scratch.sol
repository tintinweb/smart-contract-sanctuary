/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity > 0.8.0;
contract ERC20_From_Scratch{
    string public token_name;
    string public token_symbol;
    uint   public total_generated_tokens;
    uint public upto_decimals;
    address public owner;
    constructor (string memory _token_name, string memory _token_symbol, 
    uint _total_generated_tokens, uint _upto_decimals){
        token_name = _token_name;
        token_symbol = _token_symbol;
        total_generated_tokens = _total_generated_tokens;
        upto_decimals = _upto_decimals;
        balance_of[msg.sender] = total_generated_tokens;
        owner = msg.sender;
    }

    mapping( address => mapping(address => uint)) private allowed_by;
    mapping(address => uint)  private balance_of;
    //Returns the amount of tokens in existence.
    function totalSupply () public view returns (uint){
       return balance_of[msg.sender];
    }
    function BalanceOf(address _this_account) public view checkOwner(owner)returns (uint){
        return balance_of[_this_account];
    }
    function transfer(address _to, uint _amount) public returns (bool success){
        
        require(balance_of[msg.sender] >= _amount, "You donot have the sufficent amount.");
        
        balance_of[msg.sender] = balance_of[msg.sender] - _amount;
        balance_of[_to] = balance_of[_to] + _amount;
        
        return true;
    }
    //Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) public view returns (uint){
        return allowed_by[_owner][_spender];
    
    }
    function _mint(address account, uint256 amount)public virtual {
        
        require(account != address(0), "ERC20: mint to the zero address");
        
        total_generated_tokens = total_generated_tokens + amount;
        balance_of[account] = balance_of[account] + amount;
     
    }
    function approve(address _owner, address _spender, uint _amount) public returns(bool success){
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowed_by[msg.sender][_spender] = _amount;
        return true;
    }
    // function transferFrom(address _sender,address _spender,uint _amount) external returns (bool){
    //     allowed_by[_sender][_spender] = _amount;
    // }
    modifier checkOwner(address _owner){
        require(msg.sender == owner, "Only the real onwer can send tokens.");
        _;
    }
}