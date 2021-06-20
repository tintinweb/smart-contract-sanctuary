/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// 'Bull Token' token contract
//
// Deployed to : 0xdFdC8d107C2f6d9ab087f66F563a6397bAB1D2FB
// Symbol      : BLL
// Name        : Bull Token
// Total supply: 50000000000
// Decimals    : 18
//
// (c) by Marco De Dilectis & Federico Lazzarotto 06/2021. (Unlicense)).
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    // It returns 0,0001 percentual rounded down to previous Integer
    function mulDiv(uint a) internal pure returns (uint c) {
        if(a>=10000000000000000000000){
            return a / 10000;
        }
        else return 0;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract BTInterface {
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address recipient, uint amount) public returns (bool success);
    function approve(address spender, uint amount) public returns (bool success);
    function checkGivenAllowance (address spender) public view returns (uint256);
    function checkReceivedAllowance (address owner) public view returns (uint256);
    function thirdPartTransaction(address spender, address recipient, uint256 amount) public returns (bool);
    function myBlockedToken() public view returns(uint256);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract BullToken is BTInterface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 public _totalSupply;
    uint256 private _burning;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping (address => uint256) public _blocked_token;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "BLL";
        name = "Bull Token";
        decimals = 18;
        _totalSupply = 50000000000000000000000000000;
        balances[0xdFdC8d107C2f6d9ab087f66F563a6397bAB1D2FB] = _totalSupply;
        emit Transfer(address(0), 0xdFdC8d107C2f6d9ab087f66F563a6397bAB1D2FB, _totalSupply);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }
    
    function _msgSender() internal view returns (address){
        return msg.sender;
    }
    
        function decimals() public constant returns(uint8){
        return decimals;
    }
    
        function myBalance() public view returns(uint256){
        return balances[_msgSender()];
    }
    
        function myAvailableBalance() public view returns(uint256){
        return balances[_msgSender()] - _blocked_token[_msgSender()];
    }
    
        function myBlockedToken() public view returns(uint256){
        return _blocked_token[_msgSender()];
    }
    
    // restituisce la quantità dei token che spender può spendere per conto dell'owner
    function checkGivenAllowance(address spender) public view returns (uint256){
        return allowed[_msgSender()][spender];
    }

    // restituisce la quantità dei token che spender può spendere per conto dell'owner
    function checkReceivedAllowance(address owner) public view returns (uint256){
        return allowed[owner][_msgSender()];
    }
    
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address recipient, uint amount) public returns (bool success) {
        require(_msgSender() != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(balances[_msgSender()] >= amount, "Transfer amount exceeds balance");
        require(balances[_msgSender()] - _blocked_token[_msgSender()] >= amount, "You are trying to use suspended token, check your allowances");
        
        
        _burning = (mulDiv(amount));
        require(balances[_msgSender()] >= (amount + _burning), "Transfer amount exceeds balance plus fee");
        require(balances[_msgSender()] - _blocked_token[_msgSender()] >= amount + _burning, "Transfer amount exceeds balance plus fee");
        
        if(_burning != 0){
            _burn(_msgSender(), _burning); // fai controlli, leva i token da bruciare dal wallet del sender e li manda a adress(0)
        }
        balances[_msgSender()] -= amount;
        balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint amount) public returns (bool success) {
        require(balances[_msgSender()] >= amount, "You are not allowed to authorize more than your balance");
        require(_msgSender() != spender, "You're already allowed to use your token");
        require(_msgSender() != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve from the zero address");
        _blocked_token[_msgSender()] = amount;
        
        allowed[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferThirdPart(address sender, address recipient, uint amount) internal returns (bool success) {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(balances[sender] >= amount, "Transfer amount exceeds balance");
        require(_blocked_token[sender] >= amount, "You are trying to use suspended token, check your allowances");

        _burning = (mulDiv(amount));
        require(balances[sender] >= (amount + _burning), "Transfer amount exceeds balance plus fee");
        require(_blocked_token[sender] >= amount + _burning, "Transfer amount exceeds balance plus fee");

        if (_burning != 0){
            _burnThirdPart(sender, _burning); // fai controlli, leva i token da bruciare dal wallet del sender e li manda a adress(0)
        }
        balances[sender] -= amount;
        balances[recipient] += amount;
        _blocked_token[sender] -= (amount + _burning);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) internal constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // It burns token decreasing totalSupply
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    
        // It burns token decreasing totalSupply
    function _burnThirdPart(address account, uint256 burning) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        require(balances[account] >= burning, "ERC20: burn amount exceeds balance");
        balances[account] -= burning;
        _totalSupply -= burning;
        emit Transfer(account, address(0), burning);
    }
    
        // lo spender che è stato abilitato a spendere i token può trasferire i miei token dal mio conto ad un altro conto
    function thirdPartTransaction(address sender, address recipient, uint256 amount) public returns (bool){
        require(amount <= allowed[sender][_msgSender()], "Amount exeeds allowance");
        
        transferThirdPart(sender, recipient, amount);
        _burning = (mulDiv(amount));
        allowed[sender][_msgSender()]-= (amount + _burning);
        emit Approval(sender, _msgSender(), amount);

        return true;
    }

    // It increase allowance of "addedValue"
    function increaseAllowance(address spender, uint256 addedValue) public returns(bool){
        require(balances[_msgSender()] >= addedValue, "It's not allowed to authorize more than your balance");
        require(allowed[_msgSender()][spender] + addedValue <= balances[_msgSender()], "It's not allowed to authorize more than own balance");
        allowed[_msgSender()][spender] += addedValue;
        _approve(_msgSender(), spender, allowed[_msgSender()][spender]);
        return true;
    }

    // It decrease allowance of "subtractedValue"
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool){
        require(allowed[_msgSender()][spender] >= subtractedValue, "Decreased allowance below zero");
        allowed[_msgSender()][spender] -= subtractedValue;
        
        _approve(_msgSender(), spender, allowed[_msgSender()][spender]);
        return true;
    }


    // Private hidden function, to approve transfers and blocked token
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve from the zero address");
        _blocked_token[_msgSender()] = amount;

        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        
    }
}