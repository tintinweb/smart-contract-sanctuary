/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.5.8;

/*
    IdeaFeX Token token contract

    Deployed to     : 0x2CF588136b15E47b555331d2f5258063AE6D01ed
    Symbol          : IFX
    Name            : IdeaFeX Token
    Total supply    : 1,000,000,000.000000000000000000
    Decimals        : 18
    Distribution    : 40% to tokenSale      0x6924E015c192C0f1839a432B49e1e96e06571227 (to be managed)
                    : 30% to escrow         0xf9BF5e274323c5b9E23D3489f551F7525D8af1fa (cold storage)
                    : 15% to communityFund  0x2f70F492d3734d8b747141b4b961301d68C12F62 (to be managed)
                    : 15% to teamReserve    0xd0ceaB60dfbAc16afF8ebefbfDc1cD2AF53cE47e (cold storage)
*/


/* Safe maths */

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "Subtraction overflow");
        uint c = a - b;
        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a==0){
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0,"Division by 0");
        uint c = a / b;
        return c;
    }
    function mod(uint a, uint b) internal pure returns (uint) {
        require(b != 0, "Modulo by 0");
        return a % b;
    }
}


/* ERC20 standard interface */

contract ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed sender, address indexed recipient, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


/* IdeaFeX Token */

contract IdeaFeXToken is ERC20Interface {
    using SafeMath for uint;

    string private _symbol;
    string private _name;
    uint8 private _decimals;
    uint private _totalSupply;

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    address payable private tokenSale;
    address payable private escrow;
    address payable private communityFund;
    address payable private teamReserve;


    // Constructor

    constructor() public {
        _symbol = "IFX";
        _name = "IdeaFeX Token";
        _decimals = 18;
        _totalSupply = 1000000000 * 10**uint(_decimals);

        //IdeaFeX Token addresses (initial)
        tokenSale = 0x6924E015c192C0f1839a432B49e1e96e06571227;
        escrow = 0xf9BF5e274323c5b9E23D3489f551F7525D8af1fa;
        communityFund = 0x2f70F492d3734d8b747141b4b961301d68C12F62;
        teamReserve = 0xd0ceaB60dfbAc16afF8ebefbfDc1cD2AF53cE47e;

        //Token sale = 40%
        _balances[tokenSale] = _totalSupply*4/10;
        emit Transfer(address(0), tokenSale, _totalSupply*4/10);

        //Escrow = 30%
        _balances[escrow] = _totalSupply*3/10;
        emit Transfer(address(0), escrow, _totalSupply*3/10);

        //Community = 15%
        _balances[communityFund] = _totalSupply*15/100;
        emit Transfer(address(0), communityFund, _totalSupply*15/100);

        //Team = 15%
        _balances[teamReserve] = _totalSupply*15/100;
        emit Transfer(address(0), teamReserve, _totalSupply*15/100);
    }


    // Basics

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }


    // Basics II

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }


    // Burn Function

    function burn(uint amount) public {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }

    function _burn(address account, uint value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }


    // Fallback

    function () external payable {
        communityFund.transfer(msg.value);
    }
}