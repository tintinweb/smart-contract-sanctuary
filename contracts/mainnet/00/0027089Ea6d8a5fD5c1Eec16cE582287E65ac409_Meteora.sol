/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/** 
 * METEORA - Rosetta Stone
 *
 * Lunaris Incorporation - 2021
 * https://meteora.lunaris.inc
 *
 * This is the TGE contract of the METEORA Project, following the
 * ERC20 standard on Ethereum.
 * 
 * TOTAL FIXED SUPPLY: 100,000,000 MRA
 * 
**/

contract Meteora {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    address private Lunaris;
    uint8 private _decimals;
    bool private _paused;
    
    mapping (address => bool) private _admins;
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    
    constructor() {
        _name = "Meteora";
        _symbol = "MRA";
        _decimals = 18;
        _totalSupply = 100000000 * (10 ** 18);
        
        // Owner - Lunaris Incorporation
        Lunaris = address(0xf0fA5BC481aDB0ed35c180B52aDCBBEad455e808);
        
        // All of the tokens are sent to the Lunaris Wallet
        // then sent to external distribution contracts following
        // the Tokenomics documents.
        //
        // Please check out the Lunaris blog for more information.
        _balances[Lunaris] = _totalSupply;
        _admins[Lunaris] = true;
    }
    
    /*******************/
    /* ERC20 FUNCTIONS */
    /*******************/
    
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
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        
        require(currentAllowance >= amount, "METEORA: You do not have enough allowance to perform this action!");
        
        _transfer(sender, recipient, amount);
        
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    
    /*************************/
    /* ADDITIONNAL FUNCTIONS */
    /*************************/
    
    /** 
     * MRA is burnable. Any MRA owner can burn his tokens if need be.
     * The total supply is updated accordingly.
    **/
    
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    
    /*******************/
    /* ADMIN FUNCTIONS */
    /*******************/
    
    /** 
     * The named admin is granted the power to pause and
     * resume the contract for emergencies.
    **/
    
    function getAdmin(address input) public view returns (bool) {
        return _admins[input];
    }
    
    function setAdmin(address user, bool status) public returns (bool) {
        require(_admins[_msgSender()] == true, "METEORA: You are not an admin for this operation!");
        require(user != Lunaris, "METEORA: Lunaris is the big boss, mkay?");
        _admins[user] = status;
        emit AdminSet(_msgSender(), user, status);
        return _admins[user];
    }
    
    function getPause() public view returns (bool) {
        return _paused;
    }
    
    function setPause(bool state) public returns (bool) {
        require(_admins[_msgSender()] == true, "METEORA: You are not an admin for this operation!");
        _paused = state;
        emit PauseSet(_msgSender(), state);
        return _paused;
    }

    
    /**********************/
    /* INTERNAL FUNCTIONS */
    /**********************/
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "METEORA: The sender cannot be the Zero Address!");
        require(recipient != address(0), "METEORA: The recipient cannot be the Zero Address!");
        require(_paused == false, "METEORA: Cannot continue, the contract has been paused by an admin!");
        
        uint256 senderBalance = _balances[sender];
        
        require(senderBalance >= amount, "METEORA: Sender does not have enough MRA for this operation!");
        
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "METEORA: The owner cannot be the Zero Address!");
        require(spender != address(0), "METEORA: The spender cannot be the Zero Address!");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _burn(address owner, uint256 amount) private {
        uint256 accountBalance = _balances[owner];
        
        require(owner != address(0), "METEORA: Owner cannot be the Zero Address!");
        require(accountBalance >= amount, "METEORA: You do not have enough tokens to burn!");
        
        unchecked {
            _balances[owner] = accountBalance - amount;
        }
        
        _totalSupply -= amount;
        
        emit Burned(owner, amount);
    }
    
    /**********/
    /* EVENTS */
    /**********/
    
    event Transfer(address sender, address recipient, uint256 amount);
    event Approval(address owner, address spender, uint256 amount);
    event AdminSet(address setter, address getter, bool status);
    event PauseSet(address setter, bool status);
    event Burned(address burner, uint256 amount);
    
    /***********/
    /* CONTEXT */
    /***********/
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}