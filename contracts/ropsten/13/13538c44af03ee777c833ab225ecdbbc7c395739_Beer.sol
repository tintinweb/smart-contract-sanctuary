/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC20Interface {
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Beer is ERC20Interface, SafeMath {
    string public symbol = "BEER";
    string public name = "beer";
    uint8 public decimals = 18;
    uint public _totalSupply = 0;
    address public owner = msg.sender;
    IERC20 public hlmc = IERC20(0x7040B15f1Ed817C3055E8bd1033ae7c3aEB68A1E);

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) custodians;
    
    
    //private minting function
    function mint(address _to, uint256 _amount) private{
        // need to update the _totalSupply, and the balance, then use Transfer
        _totalSupply += _amount;
        balances[msg.sender] += _amount;
        emit Transfer(address(0), _to, _amount);
    }
    
    function mintFromHlmc(uint256 _hlmcAmount) public{
        // note anyoe calling this will also have to approve this address yourself in order to use this function
        hlmc.transferFrom(msg.sender, address(this), _hlmcAmount);
        mint(address(msg.sender), _hlmcAmount*1000);
    }
    
    function burnBeer(uint256 _beerToBurn) public{
        require(hlmc.balanceOf(address(this))>= _beerToBurn/1000);
        _totalSupply -= _beerToBurn;
        balances[msg.sender] -= _beerToBurn;
        emit Transfer(address(msg.sender), address(0), _beerToBurn);
        hlmc.transfer(address(msg.sender), _beerToBurn/1000);
    }
    
    function mintInterestFromBank(address _to, uint256 _earnedInterest) public{
        require(custodians[address(msg.sender)] == true);
        mint(_to, _earnedInterest);
    }
    
    function addCustodianByCustodian(address _custodian) public{
        require(custodians[msg.sender] == true);
        custodians[_custodian] = true;
    }
    
    function emergencyHlmcWithdrawal(uint256 _amount) public{
        require(custodians[msg.sender] == true);
        hlmc.transfer(address(msg.sender), _amount);
    }
    
    error Unauthorized();
    
     modifier onlyBy(address _account){
        if (msg.sender != _account)
            revert Unauthorized();
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }
    
    function addCustodianByOwner(address _custodian) public onlyBy(owner){
        custodians[_custodian] = true;
    }
    
    function drinkBeer(uint256 _beerToDrink) public{
        balances[msg.sender] -= _beerToDrink;
        emit Transfer(address(msg.sender), address(0), _beerToDrink);
    }
    

// Sandard ERC20 implementation below:

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() override public returns (uint) {
        return _totalSupply;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) override public returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) override public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
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
    function approve(address spender, uint tokens) override public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
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
    function transferFrom(address from, address to, uint tokens) override public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) override public returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }



    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    receive() external payable {
        revert();
    }
}