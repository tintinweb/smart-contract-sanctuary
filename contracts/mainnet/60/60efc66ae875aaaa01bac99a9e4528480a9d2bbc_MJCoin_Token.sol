/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
interface Art_IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    
    function increaseAllowance(address spender, uint256 addedValue) external  returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external  view  returns(string memory);
    function symbol() external view   returns (string memory);
    function decimals() external view  returns (uint8);
    
    function getTokenPrice() external view  returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/*
fixed supply MJC 
*/

contract MJC_ERC20 is Context, Art_IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;

    string private _name;
    string private _symbol;

    address payable owner;
    uint  priceEthToken;

    constructor ( string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        owner =payable(msg.sender);
        priceEthToken = 0.01 ether;
    }
   
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function setTokenPrice(uint priceWeiTokens) public  returns (bool esito) {
        require(msg.sender == owner,"Solo il propritario puo settare il prezzo");
        priceEthToken = priceWeiTokens;
        return true;
    }
    
    /* buy MJC for using to buy Artworks */
    function buyToken( uint tokens) payable public  returns (bool success) {//
        uint amount = msg.value;
        uint256 sellerBalance = balanceOf(owner);
        require(tokens <= sellerBalance, "Not enough tokens in the Seller reserve");
        require(amount >= priceEthToken * (tokens / (10 ** uint256(_decimals))), "Wrong price Token");
        _balances[owner] -=  tokens;
        _balances[msg.sender] += tokens;
        emit Transfer(owner, msg.sender, tokens);
        owner.transfer(amount);

        return true;
    }
    
    function getTokenPrice() external view override returns (uint256){
        return priceEthToken;
    }
    
    /* DEFAULT FUNCTIONS*/
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address Owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
  
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(((currentAllowance >= amount)), "MJC: transfer amount exceeds allowance ");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
    
        return true;
    }

  
    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

   
    function _approve(address Owner, address spender, uint256 amount) internal virtual {
        require(Owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[Owner][spender] = amount;
        emit Approval(Owner, spender, amount);
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
}
contract MJCoin_Token is MJC_ERC20 {
    
  //Nome symbol decimal  
    constructor() MJC_ERC20("MaryJaneCoin", "MJC",10)  {
        uint256 totalSupply = 1000000 * (10 ** uint256(10));
        _mint(msg.sender,totalSupply);
    }
}