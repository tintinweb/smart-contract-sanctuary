// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./HeadShotLib.sol";

contract HeadShotTracker is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using ConvertString for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 0;

    struct TrxInfo {
        uint256 trxMode;
        address trxAccount;
        uint256 trxDate;
        uint256 trxAmount;
    }

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping(address => TrxInfo) private _trxMap;
    TrxInfo[] private _trxList;

    mapping (string => string) private _fieldStringMap;
    mapping (string => uint256) private _fieldNumberMap;
    mapping (string => address) private _fieldAddressMap;

    address private _tokenAddress;

    constructor(string memory name_, string memory symbol_, address tokenAddress_) {
        _name = name_;
        _symbol = symbol_;
        _tokenAddress = tokenAddress_;
    }

    receive() external payable {}

    modifier authSender() {
        require((owner() == _msgSender() || _tokenAddress == _msgSender()), "Ownable: caller is not the owner");
        _;
    }

    function setTokenAddress(address address_) public authSender {
        _tokenAddress = address_;
    }

    /* Start of show properties */
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function _increaseBalance(address account_, uint256 balance_) private {
        uint256 currBalance = _balances[account_];
        uint256 newBalance = currBalance.add(balance_);
        _setBalance(account_, newBalance);
    }

    function _decreaseBalance(address account_, uint256 balance_) private {
        uint256 currBalance = _balances[account_];
        uint256 newBalance = currBalance.sub(balance_);
        require(newBalance >= 0, "ERR");
        _setBalance(account_, newBalance);
    }

    function increaseBalance(address account_, uint256 balance_) public onlyOwner returns (uint256) {
        _increaseBalance(account_, balance_);
        TrxInfo memory trxInfo = TrxInfo(1, account_, block.timestamp, balance_);
        _trxList.push(trxInfo);
        return _balances[account_];
    }

    function decreaseBalance(address account_, uint256 balance_) public onlyOwner returns (uint256) {
        _decreaseBalance(payable(account_), balance_);
        TrxInfo memory trxInfo = TrxInfo(2, account_, block.timestamp, balance_);
        _trxList.push(trxInfo);
        return _balances[account_];
    }

    function _setBalance(address account, uint256 newBalance) private {
        uint256 currentBalance = _balances[account];
        if(newBalance > currentBalance) {
            uint256 addAmount = newBalance.sub(currentBalance);
            _mint(address(this), addAmount);
            _transfer(address(this), account, addAmount);
        } else if(newBalance < currentBalance) {
            uint256 subAmount = currentBalance.sub(newBalance);
            _transfer(account, address(this), subAmount);
            _burn(address(this), subAmount);
        }
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "zero address");
        require(recipient != address(0), "zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function getAccountBalance(address account_) public view returns (uint256) {
        return _balances[account_];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("HeadShotTracker: method not implemented");
    }

    function allowance(address, address) public pure override returns (uint256) {
        revert("HeadShotTracker: method not implemented");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("HeadShotTracker: method not implemented");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("HeadShotTracker: method not implemented");
    }

    function setFieldString(string memory key_, string memory value_) public onlyOwner {
        _fieldStringMap[key_] = value_;
    }

    function getFieldString(string memory key_) public view returns (string memory) {
        return _fieldStringMap[key_];
    }

    function setFieldNumber(string memory key_, uint256 value_) public onlyOwner {
        _fieldNumberMap[key_] = value_;
    }

    function getFieldNumber(string memory key_) public view returns (uint256) {
        return _fieldNumberMap[key_];
    }

    function setFieldAddress(string memory key_, address value_) public onlyOwner {
        _fieldAddressMap[key_] = value_;
    }

    function getFieldAddress(string memory key_) public view returns (address) {
        return _fieldAddressMap[key_];
    }

    function listTrx(address account_) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        uint rowCount = _trxList.length;

        uint256[] memory _modes = new uint256[](rowCount);
        uint256[] memory _dates = new uint256[](rowCount);
        uint256[] memory _amounts = new uint256[](rowCount);

        uint id = 0;

        for (uint i = 0; i < rowCount; i++) {
            address _account = _trxList[i].trxAccount;
            if (account_ == _account){
                _modes[id] = _trxList[i].trxMode;
                _dates[id] = _trxList[i].trxDate;
                _amounts[id] = _trxList[i].trxAmount;
                id++;
            }
        }
        return (_modes, _dates, _amounts);
    }
}