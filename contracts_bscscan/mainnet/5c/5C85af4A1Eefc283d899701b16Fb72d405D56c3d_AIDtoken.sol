/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// (c) coded solely for and inside New Live Aid system
// www.newliveaid.com
// we AID as we grow

// Our system connects conscious thinking, green projects and charity events in the crypto universe.
// Our goal is to work together for a better, more sustainable future!

pragma solidity ^0.8.10;
// SPDX-License-Identifier: UNLICENSED

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract AIDtoken is IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    address private _owner;

    address public _teamVestingWallet; //27%
    address public _devWallet; //10%
    address public _charityWallet; //3%
    address public _foundationWallet1; //10%
    address public _foundationWallet2; //10%
    address public _liquidityWallet; //40%

    uint public deployTime;

    uint _teamVestingWalletLimitedTime;
    uint _devWalletLimitedTime;
    uint _charityWalletLimitedTime;
    uint _foundationWallet1LimitedTime;
    uint _foundationWallet2LimitedTime;

    uint256 _teamVestingWalletLimitedAmount;
    uint256 _devWalletLimitedAmount;
    uint256 _charityWalletLimitedAmount;
    uint256 _foundationWallet1LimitedAmount;
    uint256 _foundationWallet2LimitedAmount;

    // @dev Sets the values for token construction.
    
    constructor(uint256 totalSupply_) {
        _owner = msg.sender;

        deployTime = block.timestamp;

        _name = "New Live Aid";
        _symbol = "AID";
        _totalSupply = totalSupply_;
        _teamVestingWallet = 0xCEA0D7B01d43A7226D204e9A5BBd2efC1F066DDB;
        _devWallet = 0x83d3cDf4D17F0bBc175474090d2cF2419bBe8464;
        _charityWallet = 0x446fbeaB98028e2f67622685Cc64cE3D711242cF;
        _foundationWallet1 = 0xB3000C84d36d2790e183D85F389b8B088CD5e98F;
        _foundationWallet2 = 0x3d3ccE9BB5759FFAE0701e5a06ac21ba74b49350;
        _liquidityWallet = 0x3e0d89740B603584F58d6c799f9480b5994fb625;
        _balances[_teamVestingWallet] = _totalSupply*10**18*27/100;
        _balances[_devWallet] = _totalSupply*10**18*10/100;
        _balances[_charityWallet] = _totalSupply*10**18*3/100;
        _balances[_foundationWallet1] = _totalSupply*10**18*10/100;
        _balances[_foundationWallet2] = _totalSupply*10**18*10/100;
        _balances[_liquidityWallet] = _totalSupply*10**18*40/100;

		emit Transfer(address(0), _teamVestingWallet, _totalSupply*10**18*27/100);
        emit Transfer(address(0), _devWallet, _totalSupply*10**18*10/100);
        emit Transfer(address(0), _charityWallet, _totalSupply*10**18*3/100);
        emit Transfer(address(0), _foundationWallet1, _totalSupply*10**18*10/100);
        emit Transfer(address(0), _foundationWallet2, _totalSupply*10**18*10/100);
        emit Transfer(address(0), _liquidityWallet, _totalSupply*10**18*40/100);
    }
    
    // In order to maintain trust we decided to always show publicly our addresses.
    // After resetting them you will still be able to see them correctly.
    function setTeamVestingWallet (address newWallet) external virtual returns (bool) {
        require(msg.sender == _owner, "Caller is not the NLA owner");
        _teamVestingWallet = newWallet;
        return true;
    }
        function setDevWallet (address newWallet) external virtual returns (bool) {
        require(msg.sender == _owner, "Caller is not the NLA owner");
        _devWallet = newWallet;
        return true;
    }
        function setCharityWallet (address newWallet) external virtual returns (bool) {
        require(msg.sender == _owner, "Caller is not the NLA owner");
        _charityWallet = newWallet;
        return true;
    }
        function setFoundation1Wallet (address newWallet) external virtual returns (bool) {
        require(msg.sender == _owner, "Caller is not the NLA owner");
        _foundationWallet1 = newWallet;
        return true;
    }
        function setFoundation2Wallet (address newWallet) external virtual returns (bool) {
        require(msg.sender == _owner, "Caller is not the NLA owner");
        _foundationWallet2 = newWallet;
        return true;
    }
        function setLiquidityWallet (address newWallet) external virtual returns (bool) {
        require(msg.sender == _owner, "Caller is not the NLA owner");
        _liquidityWallet = newWallet;
        return true;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer( address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}