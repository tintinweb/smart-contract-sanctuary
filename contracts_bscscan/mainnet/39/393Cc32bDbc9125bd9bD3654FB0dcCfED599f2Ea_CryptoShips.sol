/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CryptoShips {
    // Owner 
    address private _owner;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Decimals
    uint8 _decimals;

    // Total Supply
    uint256 _totalSupply;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    
    // Mapping allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _name = "CryptoShips Token";
        _symbol = "CSHIP";
        _owner = msg.sender;
        _decimals = 18;
        _mint(_owner, 100000000*10**18);
    } 

    // ERC-20 Events.
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
    * @dev Returns the function caller.
    */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev Returns the name of the token.
    */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
    * @dev Returns the symbol of the token, usually a shorter version of the name.
    */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the number of decimals used to get its user representation.
    */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
    * @dev See {IERC20-totalSupply}.
    */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
    * @dev See {IERC20-allowance}.
    */
    function allowance(address ownerAdd, address spender) public view virtual returns (uint256) {
        return _allowances[ownerAdd][spender];
    }

    /**
    * @dev Moves `amount` of tokens from `sender` to `recipient`.
    */
    function transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }

    /**
    * @dev Deposits msg.value to the contract balance.
    */
    function deposit() public payable returns (bool success) {
        if (_balances[msg.sender] + msg.value < msg.value) return false;
        if (_totalSupply + msg.value < msg.value) return false;
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
        return true;
    }

    /**
    * @dev Withdraws _value from the contract.
    */
    function withdraw(uint256 _value) public payable onlyOwner returns (bool success)  {
        if (_balances[msg.sender] < _value) return false;
        transfer(_owner, msg.sender, _value);
        _balances[msg.sender] -= _value;
        _totalSupply -= _value;
        return true;
    }
    
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /** @dev Sets allowance of spender in behalve the owner of amount.
    */
     function _approve(
        address ownerAdd,
        address spender,
        uint256 amount
    ) public virtual returns(bool){
        require(ownerAdd != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[ownerAdd][spender] = amount;
        emit Approval(ownerAdd, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

}