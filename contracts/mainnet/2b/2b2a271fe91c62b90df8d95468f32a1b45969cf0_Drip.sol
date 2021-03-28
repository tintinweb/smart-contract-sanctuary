/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Drip is IERC20 {
    
    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    
    uint256 private _totalSupply;
    address private contractAddress;
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    address private owner1=0xaD0eb8de748F0bE8cE13c0c0d81bd7b9E03d13c8;
    address private owner2=0x12652A31C800810De411C578ebe035245b5F05e0;
    
    constructor ()  {
        _name = 'Drip';
        _symbol = 'DRIP';
        _decimals = 18;
        contractAddress = address(this);
        
        
        _totalSupply =  7470000000  * (10**_decimals);
        
        //transfer total supply to owner
        _balances[contractAddress] =5229000000e18;
        _balances[owner1]=1120500000e18;
        _balances[owner2]=1120500000e18;
        
        //fire an event on transfer of tokens
        emit Transfer(address(0),contractAddress, _balances[contractAddress]);
        
        emit Transfer(address(0),owner1, _balances[owner1]);
        
        emit Transfer(address(0),owner2, _balances[owner2]);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
     function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public  override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

   
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

 
    function approve(address spender, uint256 amount) public  virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][msg.sender]>=amount,"In Sufficient allowance");
        _transfer(sender, recipient, amount);
        _approve(sender,msg.sender, _allowances[sender][msg.sender]-=amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(sender != recipient,"cannot send money to your Self");
        require(_balances[sender]>=amount,"In Sufficiebt Funds");
        
        _balances[sender] -= amount;
        _balances[recipient] +=amount;
        emit Transfer(sender, recipient, amount);
    }
     
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(owner != spender,"cannot send allowances to yourself");
        require(_balances[owner]>=amount,"In Sufficiebt Funds");
    
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}