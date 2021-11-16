/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

pragma solidity >=0.6.0;

contract INonERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public {
        _transfer(msg.sender, recipient, amount);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");

      _balances[sender] = _balances[sender] - amount;
      _balances[recipient] = _balances[recipient] + amount;
      emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal {
      require(account != address(0), "ERC20: mint to the zero address");
      if (amount == 0) {
        return ;
      }

      _totalSupply = _totalSupply + amount;
      _balances[account] = _balances[account] + amount ;
      emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account] - value;
        _totalSupply = _totalSupply - value;
        emit Transfer(account, address(0), value);
    }


    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender]- amount);
    }
}

contract USDC is INonERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    constructor (string memory _n, string memory _s) {
      _name = _n;
      _symbol = _s;
      _mint(msg.sender, 70000000000 * 10 ** 18);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}