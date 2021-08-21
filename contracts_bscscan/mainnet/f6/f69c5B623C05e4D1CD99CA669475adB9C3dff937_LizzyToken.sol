/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

pragma solidity 0.8.7;

// SPDX-License-Identifier: NGMI Finance

//  /$$       /$$                                       /$$               /$$                          
// | $$      |__/                                      | $$              | $$                          
// | $$       /$$ /$$$$$$$$ /$$$$$$$$ /$$   /$$       /$$$$$$    /$$$$$$ | $$   /$$  /$$$$$$  /$$$$$$$ 
// | $$      | $$|____ /$$/|____ /$$/| $$  | $$      |_  $$_/   /$$__  $$| $$  /$$/ /$$__  $$| $$__  $$
// | $$      | $$   /$$$$/    /$$$$/ | $$  | $$        | $$    | $$  \ $$| $$$$$$/ | $$$$$$$$| $$  \ $$
// | $$      | $$  /$$__/    /$$__/  | $$  | $$        | $$ /$$| $$  | $$| $$_  $$ | $$_____/| $$  | $$
// | $$$$$$$$| $$ /$$$$$$$$ /$$$$$$$$|  $$$$$$$        |  $$$$/|  $$$$$$/| $$ \  $$|  $$$$$$$| $$  | $$
// |________/|__/|________/|________/ \____  $$         \___/   \______/ |__/  \__/ \_______/|__/  |__/
//                                   /$$  | $$                                                        
//                                   |  $$$$$$/                                                        
//                                   \______/                                                         

// Deployment date: August 21st 2021
// Deployed by LizardMan (tg @lizardev)

// Lizzy Token represents a way to reward all those who contribute, or have contributed, to the official NGMI Finance project.
// It serves as a sort of a badge of honor. Only Liz can mint them, but once a receiver gets it, they can do with it as they please.
// The token itself is indivisible, meaning, you can only have it as a whole.

// Author intends this token to be non-tradeable at the time of writing this. It should only serve as a way to reward NGMI bros for their effort.

// NGMI Finance is a DeFi project which started out as a meme in May of 2021, but over time evolved into a collective effort to create a one-in-all platform for blockchain users.
// Follow our roadmap and development through some of our social channels:
//
// Telegram: t.me/ngmifinance
// Twitter: twitter.com/ngmif
// Reddit: reddit.com/r/ngmi
//
// Official website: ngmi.cc
// Old meme website: ngmi.one


contract LizzyToken {
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    string private _name;
    string private _symbol;

    uint private  _supply;
    uint8 private _decimals;
    
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
        
        _name = "Lizzy Token";
        _symbol = "LIZZ";
        _supply = 269;  // 1 Million
        _decimals = 0;
        
        _balances[_owner] = totalSupply();
        emit Transfer(address(this), _owner, totalSupply());
    }
    
    modifier lizzy {
        require(msg.sender == _owner); _;
    }
    
    function _mint(address receiver, uint256 amount) private {
        _balances[receiver] += amount;
        _supply += amount;
        emit Transfer(address(0x0), receiver, amount);
    }
    
    function mint(uint256 amount) external lizzy {
        _mint(msg.sender, amount);
    }
    
    function mintTo(address[] memory receivers) external lizzy {
        uint8 i = 0;
        for (i; i < receivers.length; i++) {
            _mint(receivers[i], 1);
        }
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
        return _supply;
    }
    
    function balanceOf(address wallet) external view returns(uint) {
        return _balances[wallet];
    }
    
    function getOwner() public view returns(address) {
        return _owner;
    }

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed fundsOwner, address indexed spender, uint amount);

    function _transfer(address from, address to, uint amount) private returns(bool) {
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount;
        
        emit Transfer(from, to, amount);
        
        return true;
    }
    
    function transfer(address to, uint amount) external returns(bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        _allowances[from][msg.sender] = allowance(from, msg.sender) - amount;
        _transfer(from, to, amount);
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
}