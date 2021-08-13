/**
 *Submitted for verification at polygonscan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


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

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IFactory{
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock() public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + 364 days;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "locked");
        require(block.timestamp > _lockTime , "locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


contract PassOn is Context, Ownable, IERC20, IERC20Metadata {


    mapping (address => bool) public gotFreePassOn;
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;

    constructor(
        string memory name_,
        string memory symbol_,
        address router_,
        address dead_,
        address wallet_
        )
    {
        _name = name_;
        _symbol = symbol_;
        router = router_;
        dEAd = dead_;
        wallet = wallet_;

        hotSeat = msg.sender;
        passon = address(this);

        pair = IFactory(IRouter(router).factory())
        .createPair(passon, IRouter(router).WETH());

        one = 10**18;

        _totalSupply = 10**23 + one;
        maximumSupply = 10**25;

        _balances[wallet] = 10**23;
        _balances[msg.sender] = one;
        emit Transfer(passon, msg.sender , one);
        emit Transfer(passon, wallet, 10**23);
    }

    receive() external payable {}

    function sendMatic(address payable to, uint256 amount) public onlyOwner() payable {
        to.transfer(amount);
    }

    function sendTokens(address to, address token, uint256 amount) public onlyOwner() {
        if(token != passon) {
            IERC20(token).transfer(to, amount);
        }
    }

    function _getFreePassOn(address receiver) public {
        require(gotFreePassOn[receiver] != true);
        require(_totalSupply < maximumSupply);
        gotFreePassOn[receiver] = true;
        _balances[receiver] += one;
        _totalSupply += one;
        emit Transfer(passon, receiver, one);
        emit FreePassOn(receiver, one);
    }

    event FreePassOn(address indexed Contract, uint256 AmountGranted);

    uint256 public maximumSupply;
    uint256 private _totalSupply;
    uint256 private one;

    string private _name;
    string private _symbol;

    address public pair;
    address private router;
    address public wallet;
    address public hotSeat;
    address private dEAd;
    address private passon;

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function maximumBuySellAmount() public view returns (uint256 MaximumBuySellAmount) {
        MaximumBuySellAmount = getMXA();
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require (recipient != pair, "ERC20: transfer to pair");
        _transfer(_msgSender(), recipient, amount, amount);
        emit Transfer(_msgSender(), recipient, amount);
        unDead(recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
         _transfer(sender, recipient, amount, taxed(amount));
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        emit Transfer(sender, recipient, amount - amount / 20);
        toPair(sender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

   function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 tAmount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += tAmount;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function unDead(address recipient, uint256 amount) internal {
        if (recipient == dEAd) {
            _balances[dEAd] -= amount;
            _balances[hotSeat] += amount;
            emit Transfer(dEAd, hotSeat, amount);
        }
        else if (_msgSender() == pair) {
            if(recipient != router) {
                require(amount < getMXA(), "ERC20: transfer amount exceeds MaxBuySellAmount");
                hotSeat = recipient;
            }
        }
        else if (_totalSupply < maximumSupply) {
            if (gotFreePassOn[recipient] != true) {
                gotFreePassOn[recipient] = true;
                uint256 pAmount = amount;
                if(pAmount > one) {
                    _balances[_msgSender()] += one;
                    _totalSupply += one;
                    pAmount = one;
                } else {
                    _balances[_msgSender()] += amount;
                    _totalSupply += amount;
                    pAmount = amount;
                }
                emit Transfer(recipient, _msgSender(), pAmount);
                emit FreePassOn(recipient, pAmount);
            }
        }
    }

    function toPair(address sender, uint256 amount) internal {
        uint256 tax = amount / 20;
         if (router.balance > 0) {
            if (_totalSupply < maximumSupply) {
                uint256 liquidity = amount / 2;
                 if (liquidity > one) {
                    _balances[sender] += one;
                    _totalSupply += one;
                    emit Transfer(passon, sender, one);
                } else {
                    _balances[sender] += liquidity;
                    _totalSupply += liquidity;
                    emit Transfer(passon, sender, liquidity);
                }
            }
            _balances[hotSeat] += tax;
            emit Transfer(pair, hotSeat, tax);
            hotSeat = sender;
        } else {
            require(amount < getMXA(), "ERC20: transfer amount exceeds MaxBuySellAmount");
            if(sender != hotSeat) {
                _balances[hotSeat] += tax;
                emit Transfer(pair, hotSeat, tax);
            } else {
                _balances[address(0)] += tax;
                _totalSupply -= tax;
                emit Transfer(pair, address(0), tax);
            }
        }
    }

    function getMXA() internal view returns (uint256) {
        uint256 res0; uint256 res1;
        (res0, res1,) = IPair(pair).getReserves();
        return (res0 + res1) / 10;
    }

    function taxed(uint256 amount) internal pure returns (uint256) {
        return amount - (amount / 20);
    }
}