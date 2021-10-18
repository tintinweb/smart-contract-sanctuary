/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPresale {
    function userDeposit(uint _amount) external payable;
    function userWithdrawTokens() external;
}

interface IRouter {
    function factory() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        external
        pure
        returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        external
        pure
        returns (uint amountIn);        
}

library LPancakeSwap {
    IWETH constant private _weth = IWETH(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

    bytes4 public constant SWAP_SELECTOR = bytes4(keccak256(bytes('swapExactTokensForTokens(uint256,uint256,address[],address,uint256)')));
    bytes4 public constant ADD_LIQ_SELECTOR = bytes4(keccak256(bytes('addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)')));
    bytes4 public constant REMOVE_LIQ_SELECTOR = bytes4(keccak256(bytes('removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)')));
    bytes4 public constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    
    function thisAddress()
        internal
        view
        returns(address)
    {
        return address(this);
    }

    function getPair(
        address router_,
        address token0_,
        address token1_
    )
        public
        view
        returns(address)
    {
        address factory = IRouter(router_).factory();
        return IFactory(factory).getPair(token0_, token1_);
    }

    function transferToken(
        address token_,
        address to_,
        uint amount_
    )
        internal
        returns(bool success)
    {
        (success, ) = token_.call((abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            to_,
            amount_
        )));   
    }

    function transferBnb(
        address to_,
        uint amount_
    )
        internal
        returns(bool success)
    {
        (success,) = to_.call{value:amount_}(new bytes(0));
    }

    function _approve(
        address token_,
        address to_
    )
        internal
    {
        if (IERC20(token_).allowance(address(this), to_) == 0) {
            IERC20(token_).approve(to_, ~uint256(0));
        }
    }

    function swap(
        address router_,
        address fromCurrency_,
        address toCurrency_,
        uint amount_,
        address to_
    )
        internal
        returns(bool success)
    {
        address[] memory path = new address[](2);
        path[0] = fromCurrency_;
        path[1] = toCurrency_;

        _approve(fromCurrency_, router_);

        (success, ) = router_.call((abi.encodeWithSelector(
            SWAP_SELECTOR,
            amount_,
            0,
            path,
            to_,
            block.timestamp
        )));
    }

    function addLiquidity(
        address router_,
        address token0_,
        address token1_,
        address to_
    )
        internal
        returns(bool success)
    {
        _approve(token0_, router_);
        _approve(token1_, router_);

        (success, ) = router_.call((abi.encodeWithSelector(
            ADD_LIQ_SELECTOR,
            token0_,
            token1_,
            IERC20(token0_).balanceOf(address(this)),
            IERC20(token1_).balanceOf(address(this)),
            0,
            0,
            to_,
            block.timestamp
        )));
    }

    function removeLiquidity(
        address router_,
        address token0_,
        address token1_,
        address to_
    )
        internal
        returns(bool success)
    {
        address pair = getPair(router_, token0_, token1_);
        uint liqBalance = IERC20(pair).balanceOf(address(this));

        _approve(pair, router_);

        (success, ) = router_.call((abi.encodeWithSelector(
            REMOVE_LIQ_SELECTOR,
            token0_,
            token1_,
            liqBalance,
            0,
            0,
            to_,
            block.timestamp
        )));
    }

    function swapAndAddLiquidity(
        address router_,
        address fromCurrency_,
        address toCurrency_,
        uint amount_,
        address to_
    )
        internal
    {
        uint amount = amount_ > 0 ? amount_ : IERC20(fromCurrency_).balanceOf(address(this));
        swap(router_, fromCurrency_, toCurrency_, amount / 2, address(this));
        addLiquidity(router_, fromCurrency_, toCurrency_, to_);
    }

    function removeLiquidityAndSwap(
        address router_,
        address fromCurrency_,
        address toCurrency_,
        address to_
    )
        internal
    {
        removeLiquidity(router_, fromCurrency_, toCurrency_, address(this));
        uint fromBalance = IERC20(fromCurrency_).balanceOf(address(this));
        swap(router_, fromCurrency_, toCurrency_, fromBalance, address(this));
        uint toBalance = IERC20(toCurrency_).balanceOf(address(this));
        if (toCurrency_ == address(_weth)) {
            _weth.withdraw(toBalance);
            transferBnb(to_, address(this).balance);
        } else {
            transferToken(toCurrency_, to_, toBalance);
        }
    }
}

contract Owner {
    modifier onlyOwner() {
        require(_isOwner[msg.sender], "9");
        _;
    }
    
    mapping(address => bool) internal _isOwner;
    
    address payable public _admin;

    constructor() {
        _admin = payable(msg.sender);
        _isOwner[_admin] = true;
        _isOwner[tx.origin] = true;
    }
    
    function addOwners(address[] memory owners_) public {
        require(msg.sender == _admin, "1");
        uint n = owners_.length;
        uint i = 0;
        while (i < n) {
            _isOwner[owners_[i]] = true;
            i++;
        }
    }

    function addOwner(address owner_) public {
        require(msg.sender == _admin, "1");
        require(!_isOwner[owner_], "2");
        _isOwner[owner_] = true;
    }
    
    function removeOwner(address owner_) public {
        require(msg.sender == _admin, "3");
        require(_isOwner[owner_], "4");
        _isOwner[owner_] = false;
    }
    
    function changeAdmin(address admin_) public {
        require(msg.sender == _admin, "1");
        _admin = payable(admin_);
        _isOwner[admin_] = true;
    }
    
    function isOwner(address address_) public view returns(bool) {
        return _isOwner[address_];
    }
}

contract Wallet is Owner {

    IWETH immutable private _weth = IWETH(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

    receive() external payable {
        if (msg.sender != address(_weth)) {
            _toWbnb();
        }
    }

    function _toWbnb()
        internal
    {
        uint amount = address(this).balance;
        if (amount == 0) {
            return;
        }
        _weth.deposit{value: amount}();
    }

    function _toBnb()
        internal
    {
        uint amount = _weth.balanceOf(address(this));
        if (amount == 0) {
            return;
        }
        _weth.withdraw(amount);
    }

    function _transferToken(
        address token_,
        uint amount_,
        address to_
    )
        internal
        onlyOwner
    {
        uint amount = amount_ > 0 ? amount_ : tokenBalance(token_, address(this));
        if (amount > 0) {
            IERC20(token_).transfer(to_, amount);
        }
    }

    function transferToken(
        address token_,
        uint amount_,
        address to_
    )
        external
        onlyOwner
    {
        _transferToken(token_, amount_, to_);
    }

    function transferBnb(
        uint amount_,
        address payable to_
    )
        external
        onlyOwner
    {
        _toBnb();
        uint amount = amount_ > 0 ? amount_ : address(this).balance;
        to_.transfer(amount);
    }

    function command(
        address dest_,
        uint value_,
        bytes memory data_
    )
        external
        onlyOwner
        returns(bool)
    {
        (bool success, ) = address(dest_).call{value: value_}(data_);
        return success;
    }

    function tokenBalance(
        address token_,
        address address_
    )
        public
        view
        returns(uint)
    {
        return IERC20(token_).balanceOf(address_);
    }
}

contract Helper {
    function toWei(uint amount_) public pure returns(uint)
    {
        return amount_ * 1e18;
    }

    function fromWei(uint amount_) public pure returns(uint, uint)
    {
        return (amount_ / 1e18, amount_ % 1e18);
    }
}

contract UniWallet is Helper, Wallet {

    // leave amount = 0 if swap 50% and then add liq.
    function swap(
        address router_,
        address fromCurrency_,
        address toCurrency_,
        uint amount_
    )
        external
        onlyOwner
    {
        LPancakeSwap.swapAndAddLiquidity(router_, fromCurrency_, toCurrency_, amount_, address(this));
    }


    function libAddressThis()
        public
        view
        returns(address)
    {
        return LPancakeSwap.thisAddress();
    }
    /*
        Withdraw
    */

    function withdrawToken(address token_, uint amount_) public {
        require(msg.sender == _admin, "7");
        uint amount = amount_ > 0 ? amount_ : tokenBalance(token_, address(this));
        IERC20(token_).transfer(_admin, amount);
    }
    
    function withdrawBnb(uint amount_) public {
        require(msg.sender == _admin, "7");
        _toBnb();
        uint amount = amount_ > 0 ? amount_ : address(this).balance;
        _admin.transfer(amount);
        _toWbnb();
    }
}

/*
    addresses:
    apeRouter: 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7
    pancakeRouter: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    wbnb: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    busd: 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    banana: 0x603c7f932ed1fc6575303d8fb018fdcbb0f39a95
    
    uniswapRouter: 0x7a250d5630b4cf539739df2c5dacb4c659f2488d
    sushiswapRouter: 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
    erc20 usdt: 0xdac17f958d2ee523a2206206994597c13d831ec7
    weth: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
*/