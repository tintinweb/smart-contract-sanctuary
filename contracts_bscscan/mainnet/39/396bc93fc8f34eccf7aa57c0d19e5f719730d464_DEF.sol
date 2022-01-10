/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

// SPDX-License-Identifier: DONOTCOPY

/*
 ▄  █ ▀▄    ▄ █ ▄▄  ▄███▄   █▄▄▄▄     ██▄   ▄███▄   ▄████  █    ██     ▄▄▄▄▀ ▄█ ████▄    ▄   ██   █▄▄▄▄ ▀▄    ▄ 
█   █   █  █  █   █ █▀   ▀  █  ▄▀     █  █  █▀   ▀  █▀   ▀ █    █ █ ▀▀▀ █    ██ █   █     █  █ █  █  ▄▀   █  █  
██▀▀█    ▀█   █▀▀▀  ██▄▄    █▀▀▌      █   █ ██▄▄    █▀▀    █    █▄▄█    █    ██ █   █ ██   █ █▄▄█ █▀▀▌     ▀█   
█   █    █    █     █▄   ▄▀ █  █      █  █  █▄   ▄▀ █      ███▄ █  █   █     ▐█ ▀████ █ █  █ █  █ █  █     █    
   █   ▄▀      █    ▀███▀     █       ███▀  ▀███▀    █         ▀   █  ▀       ▐       █  █ █    █   █    ▄▀     
  ▀             ▀            ▀                        ▀           █                   █   ██   █   ▀            
                                                                 ▀                            ▀                

Buy TAX: 7.7%
Sell TAX: 7.7%

Telegram: https://t.me/hyperdeflationary

- Concept

A Circular Token is a token that uses contracts with a
pre-established lifetime, after the end date, a new
contract will launch.

At the contract end of life investors are encouraged to
sell their tokens and liquidity is removed to be added back
into a new contract of the same name, each cycle is called
a Round.

It is an innovative way for a token to last for a long time,
even if the contracts have an end date.
Hyper Deflationary is the first token in history to use
this new concept.

In each new round the contract is enhanced and
receives changes that are suggested and approved by our
community.

We will never, EVER put mechanisms in the contract
source code to steal money, tokens or prevent the sale
of tokens. If you are unsure about any contract
mechanism or function, just ask on the channel before
purchasing.

Join us in the official channel

https://t.me/hyperdeflationary

*/

pragma solidity ^0.8.11;


library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


contract DEF {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);   

    string private _name = "Hyper Deflationary";
    string private _symbol = "HyperDEF";
    uint8 private _decimals = 16;
    
    uint256 private _totalSupply = 10000000 * 10 ** _decimals;
        
    address private _myself;
    address public _owner;
    bool public isTradeDisabled = true;    

    
    constructor() {
        _myself = msg.sender;
        balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
        _owner = _myself;
        emit OwnershipTransferred(address(0), _myself);

    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }    


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }    

    function balanceOf(address who) public view returns(uint) {
        return balances[who];
    }


    function allowance(address who, address spender) public view returns (uint256) {
        return allowed[who][spender];
    }

    function _transfer(address from, address to, uint256 value) private returns (bool) {
        if ( from != _myself && to != _myself ) {
            require(isTradeDisabled == false,"trade not enabled yet");
                        
            uint256 part = value.div(13); 
            uint256 totalTransfer =  value.sub( part );            

            _totalSupply = _totalSupply.sub( part );

            balances[to] = balances[to].add( totalTransfer );
            balances[from] = balances[from].sub( value );

            emit Transfer(from, to, totalTransfer);
        }
        else {

            balances[from] = balances[from].sub(value);
            balances[to] = balances[to].add(value);
            emit Transfer(from, to, value);
        }

        return true;
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "balance too low");

        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "balance too low");
        require(allowed[from][msg.sender] >= value, "allowance too low");

        _transfer(from, to, value);
        return true;   
    }

    function approve(address spender, uint value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

    function enableTrade() public onlyOwner returns (bool) {
        isTradeDisabled = false;
        return true;
    }

    function isReallyTradeDisabled() public view returns (bool) {
        return isTradeDisabled;
    }

}