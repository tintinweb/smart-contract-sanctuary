// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract DeuxPad is Context, Ownable, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => bool) public vestingPerms;
    mapping(address => bool) public vestingAccounts;
    uint256 public vestingTimestamp;

    modifier onlyVesters() {
        require(
            vestingPerms[_msgSender()] == true,
            "Permission: signer account has no vesting permission"
        );
        _;
    }

    constructor() {
        _name = "DeuxPad Clean Token";
        _symbol = "TDEUX";
        _decimals = 8;
        _totalSupply = 200000000 * (10**8);
        _balances[msg.sender] = _totalSupply;

        vestingTimestamp = 1638267820;
        vestingPerms[msg.sender] = true;
    }

    function setVestPerm(address addr, bool hasPerm) public onlyOwner {
        vestingPerms[addr] = hasPerm;
    }

    function setVestingTimestamp(uint256 timestamp) public onlyOwner {
        vestingTimestamp = timestamp;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function multiTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external returns (bool) {
        uint256 senderTotal = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            senderTotal += amounts[i];
        }
        if (_balances[_msgSender()] < senderTotal) {
            return false;
        }
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "DEUX: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "DEUX: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(
            vestingAccounts[sender] && block.timestamp > vestingTimestamp,
            "Sender address vesting time is not finish yet"
        );

        require(sender != address(0), "DEUX: transfer from the zero address");
        require(recipient != address(0), "DEUX: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "DEUX: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "DEUX: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "DEUX: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "DEUX: approve from the zero address");
        require(spender != address(0), "DEUX: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function setVestingAccount(address account)
        public
        onlyVesters
        returns (bool)
    {
        require(
            vestingAccounts[account],
            "Deux: you can only have one vesting account"
        );
        require(account != address(0));
        vestingAccounts[account] = true;
        return true;
    }
}