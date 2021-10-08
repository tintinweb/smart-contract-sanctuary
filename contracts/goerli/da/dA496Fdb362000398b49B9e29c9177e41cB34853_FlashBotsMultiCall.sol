/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface IUniswapV3Pool {
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}
// This contract simply calls multiple targets sequentially, ensuring WETH balance before and after

contract FlashBotsMultiCall {
    address private immutable owner;
    address private immutable executor;
    //IWETH private constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IWETH private constant WETH =
        IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    address private constant ETH_address =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    modifier onlyExecutor() {
        require(msg.sender == executor);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _executor) public payable {
        owner = msg.sender;
        executor = _executor;
        if (msg.value > 0) {
            WETH.deposit{value: msg.value}();
        }
    }

    receive() external payable {}

    function uniswapWeth(
        uint256 _wethAmountToFirstMarket,
        uint256 _ethAmountToCoinbase,
        address[] memory _targets,
        bytes[] memory _payloads
    ) external payable onlyExecutor {
        require(
            _targets.length == _payloads.length,
            "target length not equal to payload length"
        );
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        WETH.transfer(_targets[0], _wethAmountToFirstMarket);
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(
                _payloads[i]
            );
            require(_success, "call swap function not successful");
            _response;
        }

        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(
            _wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase,
            "profit is negative or profit less then miner fee"
        );
        if (_ethAmountToCoinbase == 0) return;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < _ethAmountToCoinbase) {
            WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
        }
        block.coinbase.transfer(_ethAmountToCoinbase);
    }
    
    function uniswapWeth2(
        uint256 _ethAmountToCoinbase,
        address[] memory _targets,
        bytes[] memory _payloads,
        uint256[] memory _outAmounts,
        address[] memory _outTokens,
        uint256[] memory _types
    ) external payable onlyExecutor {
        require(
            _targets.length == _payloads.length && _targets.length == _outAmounts.length && _targets.length == _outTokens.length && _targets.length == _types.length,
            "target length not equal to payload length"
        );
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        for (uint256 i =0 ; i < _targets.length; i++) {
            if(_types[i] == 2) {
                IERC20(_outTokens[i]).transfer(_targets[i], _outAmounts[i]);
            }
            (bool _success, bytes memory _response) = _targets[i].call(
                _payloads[i]
            );
            require(_success, "call swap function not successful");
            _response;
            
        }
        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(
            _wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase,
            "profit is negative or profit less then miner fee"
        );
        if (_ethAmountToCoinbase == 0) return;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < _ethAmountToCoinbase) {
            WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
        }
        block.coinbase.transfer(_ethAmountToCoinbase);
    }
    
    struct FlashCallbackData {
        uint256 _ethAmountToCoinbase;
        address[] _targets;
        bytes[] _payloads;
        uint256[] _outAmounts;
        address[] _outTokens;
        uint256[] _types;
    }
    
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256,
        bytes calldata data
        ) external {
        FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        for (uint256 i =0 ; i < decoded._targets.length; i++) {
            if(decoded._types[i] == 2) {
                IERC20(decoded._outTokens[i]).transfer(decoded._targets[i], decoded._outAmounts[i]);
            }
            (bool _success, bytes memory _response) = decoded._targets[i].call(
                decoded._payloads[i]
            );
            require(_success, "call swap function not successful");
            _response;
            
        }
        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        uint256 _amountOwed = decoded._outAmounts[0]+fee0;
        require(
            _wethBalanceAfter > _wethBalanceBefore + decoded._ethAmountToCoinbase+fee0,
            "profit is negative or profit less then miner fee"
        );
        if (decoded._ethAmountToCoinbase == 0) return;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < decoded._ethAmountToCoinbase) {
            WETH.withdraw(decoded._ethAmountToCoinbase - _ethBalance);
        }
        block.coinbase.transfer(decoded._ethAmountToCoinbase);
        WETH.transfer(address(msg.sender), _amountOwed);
        }
    
    function uniswapFlash(
        IUniswapV3Pool _flashPool,
        uint256 _ethAmountToCoinbase,
        address[] memory _targets,
        bytes[] memory _payloads,
        uint256[] memory _outAmounts,
        address[] memory _outTokens,
        uint256[] memory _types
        ) external {
            _flashPool.flash(
                address(this),
                _outAmounts[0],
                0,
                abi.encode(
                    FlashCallbackData({
                      _ethAmountToCoinbase: _ethAmountToCoinbase,
                      _targets: _targets,
                      _payloads: _payloads,
                      _outAmounts: _outAmounts,
                      _outTokens: _outTokens,
                      _types: _types
                    })
                    )
                );
        }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory data
    ) external {
        require(amount0Delta > 0 || amount1Delta > 0);
        (address tokenIn, address tokenOut) = abi.decode(data, (address, address));
        (bool isExactInput, uint256 amountToPay) =
            amount0Delta > 0
                ? (tokenIn < tokenOut, uint256(amount0Delta))
                : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) {
             IERC20(tokenIn).transfer(address(msg.sender), amountToPay);
        }
    }

    function call(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable onlyOwner returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }

    function withdraw(address token) external onlyOwner {
        if (token == ETH_address) {
            uint256 bal = address(this).balance;
            msg.sender.transfer(bal);
        } else if (token != ETH_address) {
            uint256 bal = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(address(msg.sender), bal);
        }
    }
}