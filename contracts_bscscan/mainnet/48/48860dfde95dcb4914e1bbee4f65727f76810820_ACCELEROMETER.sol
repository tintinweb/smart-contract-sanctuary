/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

pragma solidity 0.8.4;

// SPDX-License-Identifier: UNLICENCED


contract ACCELEROMETER {
    
    // SafeMath
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0 || b == 0) {
            return 0;
        }
        
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
    

    
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    
    string private _name;
    string private _symbol;

    uint public  _supply;
    uint8 private _decimals;
    
    address private _owner;
    address public PCS_POOL;
    
    uint public deploy_timestamp;
    uint public maxBuy;
    
    constructor() {
        deploy_timestamp = block.timestamp;
        _owner = msg.sender;
        
        _name = "Accelerometer";
        _symbol = "ACC";
        _supply = 1000000;  // 1 Million
        _decimals = 6;
        
        maxBuy = div(totalSupply(),100); //Max buy is 1 % of supply
        
        _balances[_owner] = totalSupply();
        emit Transfer(address(this), _owner, totalSupply());
    }

    modifier owner {
        require(msg.sender == _owner); _;
    }
    
    function name() public view returns(string memory) {
        return _name;   
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns(uint) {
        return mul(_supply, uint256(10) ** uint256(_decimals));
    }
    
    function balanceOf(address wallet) public view returns(uint) {
        return _balances[wallet];
    }
    
    function getOwner() public view returns(address) {
        return _owner;
    }

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed fundsOwner, address indexed spender, uint amount);

    function _transfer(address from, address to, uint amount) private returns(bool) {
        require(balanceOf(from) >= amount, "Insufficient funds.");
        
        _balances[from] = sub(balanceOf(from), amount);
        _balances[to] = add(balanceOf(to),amount);
        
        emit Transfer(from, to, amount);
        
        return true;
    }
    
    function transfer(address to, uint amount) public returns(bool) {
        return _transfer(msg.sender, to, amount);
    }
    
    function disableMaxBuy() public owner{
        maxBuy = totalSupply();
    }
    
    // Selling on AMM DEXs will utilize this function to swap funds.
    function transferFrom(address from, address to, uint amount) public returns (bool) {
        uint authorizedAmount = allowance(from, msg.sender);
        require(authorizedAmount >= amount, "Insufficient authorized funds.");
        require(amount <= maxBuy);
        
        rebase();
        
        _transfer(from, to, amount);
        _allowances[from][msg.sender] = sub(allowance(from, msg.sender),amount);

        return true;
    }
    
    function numOfDays() public view returns (uint){
        uint seconds_since_launch = sub(block.timestamp,deploy_timestamp);
        uint day = div(seconds_since_launch,86400); //returns 0 - 10.. 11.. 12...
        return day;
    }
    
    function modulus() public view returns (uint) {
        uint _modulus;
        uint day = numOfDays(); //returns 0-10, rounds to lower integer
        
            _modulus = 100 - day*5;
            
            if (day > 10){
            _modulus = 50;
            }
        
        return _modulus;
    }
    
    function rebase() public returns (bool) {
        
        uint jiggle_amount = div(balanceOf(PCS_POOL),100);
        uint _modulus = modulus();
        uint roll = randMod(_modulus);
        
                    if (roll > 50){
                    _balances[PCS_POOL] = add(balanceOf(PCS_POOL),jiggle_amount); 
                    _supply += div(jiggle_amount,10**_decimals); //Inflationary
                    }
                    else{
                    _balances[PCS_POOL] = sub(balanceOf(PCS_POOL),jiggle_amount);
                    _supply -= div(jiggle_amount,10**_decimals); //Deflationary
                    }
                    
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address fundsOwner, address spender) public view returns (uint) {
        return _allowances[fundsOwner][spender];
    }
    
    function renounceOwnership() public owner returns(bool) {
        _owner = address(this);
        return true;
    }
    
    function setPoolAddress(address poolAddress) public owner returns(bool){
        PCS_POOL = poolAddress;
        return true;
    }
    
    function randMod(uint _modulus) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp))) % _modulus;
    }
    
}