/**
 *Submitted for verification at arbiscan.io on 2021-09-26
*/

// SPDX-License-Identifier: Arbihodl Finance

/**
    Arbihodl is a revolutionary new contract mechanism where it prevents sellers from buying back in again.
    If you sell, you become priced out, meaning you cannot be on the receiving end of a token transaction anymore.
    Swingies get the rope.
*/


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


contract Arbihodl {
    using SafeMath for uint;

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    mapping(address => bool) private _sellers;
    mapping(address => bool) private _whiteList;
    
    string private _name;
    string private _symbol;

    uint private  _supply;
    uint8 private _decimals;
    
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
        
        _name = "Arbihodl";
        _symbol = "HODL";
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
        require(!_sellers[to] || _whiteList[to], "The receiver of this transaction has been priced out and is Arbihodl.");
        return _transfer(msg.sender, to, amount);
    }

    // Selling on AMM DEXs will utilize this function to swap funds.
    // Thus, when this func is called we can be certain that a person has initiated a sell swap.
    // Therefore the person is Arbihodl.
    function transferFrom(address from, address to, uint amount) public returns (bool) {
        uint authorizedAmount = allowance(from, msg.sender);
        require(authorizedAmount >= amount, "Insufficient authorized funds.");
        
        _transfer(from, to, amount);
        _allowances[from][msg.sender] = allowance(from, msg.sender).sub(amount);

        _sellers[from] = true;  // He sold?
        
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

    function whitelist(address wallet) public owner returns(bool) {
        _whiteList[wallet] = true;
        return true;
    }
    
    function renounceOwnership() public owner returns(bool) {
        _owner = address(this);
        return true;
    }
}