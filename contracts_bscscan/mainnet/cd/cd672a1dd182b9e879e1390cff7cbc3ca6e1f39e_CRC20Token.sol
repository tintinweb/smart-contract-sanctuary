// SPDX-License-Identifier: GPL
pragma solidity 0.6.12;

import "./SafeMath256.sol";
import "./ICRC20.sol";
import "./IToken.sol";
import "./CRC20BlackList.sol";

contract CRC20Token is IToken, CRC20BlackList {

    using SafeMath256 for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    constructor (string memory name, string memory symbol, uint256 supply, uint8 decimals) public CRC20BlackList() {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = supply;
        _balances[msg.sender] = supply;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override whenNotPaused returns (bool)  {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender,
                _allowances[sender][msg.sender].sub(amount, "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "DECREASED_ALLOWANCE_BELOW_ZERO"));
        return true;
    }

    function burn(uint256 amount) public virtual override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual override {
        uint256 decreasedAllowance = allowance(account, msg.sender).sub(amount, "BURN_AMOUNT_EXCEEDS_ALLOWANCE");

        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }

    function multiTransfer(uint256[] calldata mixedAddrVal) public override returns (bool) {
        for (uint i = 0; i < mixedAddrVal.length; i++) {
            address to = address(mixedAddrVal[i]>>96);
            uint256 value = mixedAddrVal[i]&(2**96-1);
            _transfer(msg.sender, to, value);
        }
        return true;
    }

    function mint(uint256 amount) public virtual override onlyOwner {
        _mint(msg.sender, amount);
    }

    function mintTo(address account, uint256 amount) public virtual override onlyOwner {
        _mint(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "TRANSFER_FROM_THE_ZERO_ADDRESS");
        require(recipient != address(0), "TRANSFER_TO_THE_ZERO_ADDRESS");
        _beforeTokenTransfer(sender, recipient);

        _balances[sender] = _balances[sender].sub(amount, "TRANSFER_AMOUNT_EXCEEDS_BALANCE");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BURN_FROM_THE_ZERO_ADDRESS");
        //if called from burnFrom, either blackListed msg.sender or blackListed account causes failure
        _beforeTokenTransfer(account, address(0));
        _balances[account] = _balances[account].sub(amount, "BURN_AMOUNT_EXCEEDS_BALANCE");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(_totalSupply + amount > _totalSupply);
        require(_balances[account] + amount > _balances[account]);

        _balances[account] += amount;
        _totalSupply += amount;
        emit Mint(account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "APPROVE_FROM_THE_ZERO_ADDRESS");
        require(spender != address(0), "APPROVE_TO_THE_ZERO_ADDRESS");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to) internal virtual view {
        require(!isBlackListed(msg.sender), "MSG_SENDER_IS_BLACKLISTED_BY_TOKEN_OWNER");
        require(!isBlackListed(from), "FROM_IS_BLACKLISTED_BY_TOKEN_OWNER");
        require(!isBlackListed(to), "TO_IS_BLACKLISTED_BY_TOKEN_OWNER");
    }
}