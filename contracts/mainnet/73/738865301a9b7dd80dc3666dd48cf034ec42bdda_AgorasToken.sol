/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;

interface IERC20 {
        function totalSupply() external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        event Approval(address indexed owner, address indexed spender, uint256 value);
        event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Pausable {
        event Paused();
        event Unpaused();
        bool private _paused;
        constructor ()                                  { _paused = false; }
        function paused() public view returns (bool)    { return _paused; }
        modifier whenNotPaused()                        { require(!_paused, "Pausable: paused"); _; }
        modifier whenPaused()                           { require(_paused, "Pausable: not paused"); _; }
        function _pause() internal virtual whenNotPaused{ _paused = true; emit Paused(); }
        function _unpause() internal virtual whenPaused { _paused = false; emit Unpaused(); }
}

contract AgorasToken is IERC20, Pausable {
        mapping (address => uint256) private _balances;
        mapping (address => mapping (address => uint256)) private _allowances;
        mapping (address => bool) private _locked;
        uint256 private _totalSupply;
        string private _name;
        string private _symbol;
        uint8 private _decimals;
        address private _owner;

        constructor() {
                _name = 'Agoras Token';
                _symbol = 'AGRS';
                _decimals = 8;
                _totalSupply = 42000000 * (10**_decimals);
                _balances[msg.sender] = _totalSupply;
                _owner = msg.sender;
        }

        function name() public view returns (string memory)     { return _name; }
        function symbol() public view returns (string memory) { return _symbol; }
        function decimals() public view returns (uint8) { return _decimals; }
        function totalSupply() public view override returns (uint256) { return _totalSupply; }
        function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
        function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
                require(!_locked[msg.sender], "AgorasToken locked sender");
                _transfer(msg.sender, recipient, amount);
                return true;
        }
        function allowance(address owner, address spender) public view virtual override returns (uint256) {
                return _allowances[owner][spender];
        }
        function approve(address spender, uint256 amount) public virtual override returns (bool) {
                _approve(msg.sender, spender, amount);
                return true;
        }

        function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
                require(!_locked[sender], "AgorasToken locked from sender");
                require(_allowances[sender][msg.sender] >= amount, "AgorasToken transfer amount exceeds allowance");
                _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
                _transfer(sender, recipient, amount);
                return true;
        }

        function _approve(address owner, address spender, uint256 amount) internal virtual {
                require(owner != address(0), "AgorasToken approve from the zero address");
                require(spender != address(0), "AgorasToken approve to the zero address");
                _allowances[owner][spender] = amount;
                emit Approval(owner, spender, amount);
        }

        function _transfer(address sender, address recipient, uint256 amount) internal virtual {
                //_beforeTokenTransfer();
                require(paused() == false, "AgorasToken is Paused");
                require(sender != address(0), "AgorasToken transfer from the zero address");
                require(recipient != address(0), "AgorasToken transfer to the zero address");
                require(_balances[sender] >= amount, "AgorasToken transfer amount exceeds balance");
                require(_balances[recipient] + amount >= _balances[recipient], "AgorasToken addition overflow");

                _balances[sender] -= amount;
                _balances[recipient] += amount;
                emit Transfer(sender, recipient, amount);
        }

        function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
                uint256 c = _allowances[msg.sender][spender] + addedValue;
                require(c >= _allowances[msg.sender][spender], "AgorasToken addition overflow");
                _approve(msg.sender, spender, c);
                return true;
        }

        function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
                require(_allowances[msg.sender][spender] >= subtractedValue, "AgorasToken decreased allowance below zero");
                _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
                return true;
        }

        function _beforeTokenTransfer() internal virtual { }

        function pause()  public virtual returns (bool) {
                require(msg.sender == _owner, "AgorasToken: pause request from non owner");
                _pause();
                return true;
        }

        function unpause() public virtual returns (bool) {
                require(msg.sender == _owner, "AgorasToken: unpause request from non owner");
                _unpause();
                return true;
        }

        event Mint(uint256 amount);

        function mint(uint256 amount) public virtual returns (bool) {
                require(paused()==false, "AgorasToken is Paused");
                require(msg.sender == _owner, "AgorasToken: mint from non owner ");
                require(_totalSupply + amount >= _totalSupply, "AgorasToken addition overflow");
                require(_balances[_owner] + amount >= amount, "AgorasToken addition overflow");
                _totalSupply += amount;
                _balances[_owner] += amount;
                emit Mint(amount);
                return true;
        }

        function updateNameSymbol(string calldata newname, string calldata newsymbol) public virtual returns (bool) {
                require(paused()==false, "AgorasToken is Paused");
                require(msg.sender == _owner, "AgorasToken: update from non owner");
                require(bytes(newname).length <= 32, "AgorasToken: name too long");
                require(bytes(newname).length > 0, "AgorasToken: empty name");
                require(bytes(newsymbol).length <= 8, "AgorasToken: symbol too long");
                require(bytes(newsymbol).length > 0, "AgorasToken: empty symbol");
                _name = newname;
                _symbol = newsymbol;
                return true;
        }

        function isLocked(address addr) public virtual returns (bool) {
                return _locked[addr];
        }

        function addLock(address addr) public virtual returns (bool) {
                require(paused()==false, "AgorasToken is Paused");
                require(msg.sender == _owner, "AgorasToken: update from non owner");
                _locked[addr] = true;
                emit Locked(addr);
                return true;
        }

        function removeLock(address addr) public virtual returns (bool) {
                require(paused()==false, "AgorasToken is Paused");
                require(msg.sender == _owner, "AgorasToken: update from non owner");
                _locked[addr] = false;
                emit Unlocked(addr);
                return true;
        }

        event Locked(address addr);
        event Unlocked(address addr);
}