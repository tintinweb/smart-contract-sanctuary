pragma solidity ^0.5.0;

/*

This is a token that remains in your account forever, until
you pay ether to send it somewhere else.

*/

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "safeAdd integer overflow");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "safeSub integer underflow");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "safeMul integer overflow");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "safeDiv divide by zero");
        c = a / b;
    }
}

contract Owned {
    
    address payable public owner;
    address payable public newOwner;
    
    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    constructor() public {
        owner = msg.sender;
        newOwner = address(0);
    }
    
    // only the owner can run a function
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can access this function");
        _;
    }
    
    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner, "Only the new owner can access this function");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0); // set the next new owner to burn address
    }
    
}

contract Sendable {
    
    mapping (address => bool) canSend;
    
}

contract ERC20Interface {
    
    // token supply
    function totalSupply() public view returns (uint256);
    
    // transfering tokens from sender
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    // allowing others to transfer tokens
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
    // events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract CantGetRidOfMe is ERC20Interface, Owned, SafeMath {
    
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public _totalSupply;
    
    uint256 public priceToSend;
    bool private _mintLocked;
    
    mapping(address => uint256) _balances;
    mapping(address => uint256) _allowedToSend;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        
        // token parameters
        symbol = "CANTSEND";
        name = "Can&#39;t Get Rid of Me";
        decimals = 0;
        uint256 wholeTokens = 100;
        
        // set up supply
        _totalSupply = 0;
        _mintLocked = false;
        uint256 initialSupply = wholeTokens * (uint256(10) ** decimals);
        
        priceToSend = 0.001 ether;
        
        // initial creation
        mintTo(msg.sender, initialSupply);
        
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint256) {
        
        // current total supply is the supply - amount sent to burned address
        return safeSub(_totalSupply, _balances[address(0)]);
        
    }
    
    function balance() public view returns (uint256 balance) {
        return balanceOf(msg.sender);
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }
    
    function allowedToTransfer() public view returns (uint256 allowed) {
        return allowedToTransferOf(msg.sender);
    }
    
    function allowedToTransferOf(address _owner) public view returns (uint256 allowed) {
        return _allowedToSend[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        _allowedToSend[msg.sender] = safeSub(_allowedToSend[msg.sender], _value);
        
        _balances[msg.sender] = safeSub(_balances[msg.sender], _value);
        _balances[_to] = safeAdd(_balances[_to], _value);
        
        // send transfer event
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }
    
    // approve - not allowed
    function approve(address _spender, uint256 _value) public returns (bool success) {
        revert("transferFrom not supported in this contract");
    }
    
    // transfer from - not allowed
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        revert("transferFrom not supported in this contract");
    }
    
    // allowance - not allowed
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        revert("allowance not supported in this contract");
    }
    
    // if they send ether, they can move some tokens
    function () external payable {
        
        // if they sent too little, send it back
        require(msg.value >= priceToSend);
        
        // how much movement have they bought?
        uint256 movementBought = safeDiv(msg.value, priceToSend);
        // allow them to send it
        _allowedToSend[msg.sender] = safeAdd(_allowedToSend[msg.sender], movementBought);
        
        // if they are approved to send more than they have, mint some new ones
        if (_allowedToSend[msg.sender] > _balances[msg.sender]) {
            // how much to mint is difference between the two values
            uint256 newTokens = safeSub(_allowedToSend[msg.sender], _balances[msg.sender]);
            // give it to them
            mintTo(msg.sender, newTokens);
        }
        
    }
    
    // can mint to new addresses
    function mintTo(address _to, uint256 _value) private returns (bool success) {
        
        // add the new tokens to the total supply
        _totalSupply = safeAdd(_totalSupply, _value);
        // add brand new coins to the address
        _balances[_to] = safeAdd(_balances[_to], _value);
        
        // send out mint event
        emit Transfer(address(0), _to, _value);
        
        return true;
        
    }
    
    // allows price to be lowered as ether&#39;s value goes up
    function setSendCost(uint256 newPriceToSend) external onlyOwner returns (bool success) {
        priceToSend = newPriceToSend;
        return true;
    }
    
    // owner can send out accidentally transferred erc20 tokens
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    // owner can send out ether sent to this contract
    function sendOutEther() public onlyOwner returns (bool success) {
        owner.transfer(address(this).balance);
        return true;
    }
    
    // owner can send out ether sent to this contract, might need this if the gas price gets too high
    function sendOutEtherWithGasAmount(uint256 gasAmount) public onlyOwner returns (bool success) {
        uint256 thisBalance = address(this).balance;
        owner.call.value(thisBalance).gas(gasAmount)("");
        return true;
    }
    
}