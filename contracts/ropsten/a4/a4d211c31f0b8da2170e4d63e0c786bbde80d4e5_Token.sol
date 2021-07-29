/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;



// abstract contract Context {
//     function _msgSender() internal view virtual returns (address) {
//         return msg.sender;
//     }

//     function _msgData() internal view virtual returns (bytes calldata) {
//         return msg.data;
//     }
// }

// interface IERC20 {

//     function totalSupply() external view returns (uint256);

//     function balanceOf(address account) external view returns (uint256);

//     function transfer(address recipient, uint256 amount) external returns (bool);

//     function allowance(address owner, address spender) external view returns (uint256);

//     function approve(address spender, uint256 amount) external returns (bool);

//     function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

//     event Transfer(address indexed from, address indexed to, uint256 value);

//     event Approval(address indexed owner, address indexed spender, uint256 value);
// }



contract ERC20{
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    
   
    uint256 public _totalSupply;
    string private _name;
    string private _symbol;
    
    uint256 CAP = 50000;
    
    constructor() {
        _name = "name_";
        _symbol = "symbol_";
        _totalSupply = 5000;
        _balances[msg.sender] = 5000;
    }
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
    
    
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 0;
    }

    function totalSupply() public view virtual  returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual  returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual  returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual  returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) public virtual  returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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

    function _transfer(address sender,address recipient,uint256 amount) internal virtual {
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

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    
    function mintform(address account, uint256 amount) public virtual {
        require(totalSupply() + amount  <= CAP);
        _mint(account, amount);
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

        _afterTokenTransfer(account, address(0), amount);
    }
    
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    
    function _approve(address owner,address spender,uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from,address to,uint256 amount) internal virtual {
        
    }

    function _afterTokenTransfer(address from,address to,uint256 amount) internal virtual {}
}

contract Token is ERC20{
    
    address private own;
    bool private _paused;
    
    constructor(){
        own = msg.sender;
        _paused = false;
    }
    
    modifier onlyown(){
        require(msg.sender == own,"only own call the function...");
        _;
    }
    event Burned(address user, uint amt);
    
    // function burn(address account, uint256 amount) public returns(bool) {
    //     if(amount > 0){
    //         _burn(account, amount);
    //         emit Burned(account, amount);
    //         return true;
    //     }
    //     return false;
    //     }
    
     function burn(address account, uint256 amount) public virtual onlyown returns(bool) {
        require(amount > 0, "no amount found");
        _burn(account, amount);
        emit Burned(account, amount);
        return true;
     }
    
    function mint(address account, uint256 amount) public onlyown {
        require(totalSupply() + amount  <= CAP);
        _mint(account, amount);
    }
    
    event Paused(address account);
    event Unpaused(address account);
    
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() public virtual whenNotPaused onlyown {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() public virtual whenPaused onlyown {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    
    function _beforeTokenTransfer(address from,address to,uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    
    event OwnershipTransferred(address newOwner);
    
    function _transferOwnership(address newOwner) public onlyown {
        require(newOwner != address(0));
        emit OwnershipTransferred(newOwner);
        own = newOwner;
    }
    
}