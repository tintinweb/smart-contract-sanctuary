/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: NOLICENSED

pragma solidity  0.8.0;

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

    // constructor (){
        
    //     balance_of[msg.sender] = total_generated_tokens;
    //     owner = msg.sender;

    // }

    // function setTokenName(string memory _token_name) public {
    //     token_name = _token_name;
    // }

    // function setTokenSymbol(string memory _token_symbol) public {
    //     token_symbol = _token_symbol;
    // }

    // function setTotalGenerateTokens( uint _total_generated_tokens) public {
    //     total_generated_tokens = _total_generated_tokens;
    // }

    // function setUptodecimal(uint _upto_decimals) public {
    //     upto_decimals = _upto_decimals;
    // }

    mapping( address => mapping(address => uint)) private allowed_by;

    mapping(address => uint)  private balance_of;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);



    //Returns the amount of tokens in existence.
    function totalSupply () public view returns (uint){
       return balance_of[msg.sender];
    }

    function BalanceOf(address _this_account) public view checkOwner(owner)returns (uint){
        return balance_of[_this_account];
    }

    function transfer(address _from, address _to, uint _amount) public returns (bool success){
        
        require(balance_of[msg.sender] >= _amount, "You donot have the sufficent amount.");
        
        balance_of[msg.sender] = balance_of[msg.sender] - _amount;
        balance_of[_to] = balance_of[_to] + _amount;
        
        emit Transfer(_from, _to, _amount);

        return true;
    }

    function _mint(address account, uint256 amount)public virtual {
        
        require(account != address(0), "ERC20: mint to the zero address");
        
        total_generated_tokens = total_generated_tokens + amount;
        balance_of[account] = balance_of[account] + amount;
     
    }

     //Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) public view returns (uint){
       
        uint allowed_amount;
      
        // mapping( address => mapping(address => uint)) private allowed_by; 
        allowed_amount = allowed_by[_owner][_spender];
        return allowed_amount;
    
    }
    

    function approve(address _owner, address _spender, uint _amount) public returns(bool success){

        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        // mapping( address => mapping(address => uint)) private allowed_by;
        allowed_by[msg.sender][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);

        return true;
    }

    //real owner wo jo call kar rah aha jis ko allowed hain. //aproved sender
    //recipent wo jisko us nay send karnay hain. 
    //amout jitni amount approve hoii ha wo.
    function transferFrom(address real_owner,address recipient,uint256 amount) public returns (bool) {
        
        require (balance_of[real_owner] <= amount, "You are not approved.");

        uint256 currentAllowance = allowed_by[real_owner][msg.sender];
       
        require(currentAllowance >= amount, "You are not allowed to send this much money.");
        approve(real_owner, msg.sender, currentAllowance - amount);
        
        transfer(msg.sender,recipient, amount);
        
        return true;
    }





    modifier checkOwner(address _owner){
        require(msg.sender == owner, "Only the real onwer can send tokens.");
        _;
    }
}