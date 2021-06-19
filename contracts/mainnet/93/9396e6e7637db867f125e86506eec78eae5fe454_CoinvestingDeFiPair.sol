// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./ICoinvestingDeFiCallee.sol";
import "./ICoinvestingDeFiFactory.sol";
import "./ICoinvestingDeFiPair.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./UQ112x112.sol";
import "./CoinvestingDeFiERC20.sol";

contract CoinvestingDeFiPair is ICoinvestingDeFiPair, CoinvestingDeFiERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    // Public variables
    address public override factory;
    uint public override kLast;
    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
    address public override token0;
    address public override token1;

    uint public constant override MINIMUM_LIQUIDITY = 10**3;
        
    // Private variables
    uint32  private blockTimestampLast;
    uint112 private reserve0;
    uint112 private reserve1;    
    uint private unlocked = 1;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    // Modifiers
    modifier lock() {
        require(unlocked == 1, "PAIR: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() {
        factory = payable(msg.sender);
    }

    // External functions
    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (
        uint amount0,
        uint amount1
    ) 
    {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply;
        amount0 = liquidity.mul(balance0) / _totalSupply;
        amount1 = liquidity.mul(balance1) / _totalSupply;
        require(
            amount0 > 0 && amount1 > 0, 
            "PAIR: INSUF_LIQ_BURN"
        );

        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); 
        emit Burn(msg.sender, amount0, amount1, to);
    }
    
    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1
    )
    external
    override
    {
        require(msg.sender == factory, "PAIR: CALLER_MUST_BE_FAC");
        token0 = _token0;
        token1 = _token1;
    }
    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; 
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY);
        } else
            liquidity = Math.min(
                amount0.mul(_totalSupply) / _reserve0,
                amount1.mul(_totalSupply) / _reserve1
            );
        require(liquidity > 0, "PAIR: INSUF_LIQ_MINT");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = token0; 
        address _token1 = token1; 
        _safeTransfer(
            _token0,
            to,
            IERC20(_token0).balanceOf(address(this)).sub(reserve0)
        );
        _safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)).sub(reserve1)
        );
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    )
    external
    override
    lock
    {
        require(
            amount0Out > 0 || amount1Out > 0, 
            "PAIR: INSUF_OUT_AMT"
        );

        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1, 
            "PAIR: INSUF_LIQ"
        );
        
        uint balance0;
        uint balance1;
        {
            address _token0 = token0;
            address _token1 = token1;
            require(
                to != _token0 && to != _token1, 
                "PAIR: INV_TO"
            );

            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            if (data.length > 0) 
                ICoinvestingDeFiCallee(to).coinvestingDeFiCall(
                    payable(msg.sender),
                    amount0Out,
                    amount1Out,
                    data
                );
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        } 

        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "PAIR: INSUF_IN_AMT");
        {
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(
                balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2),
                "Pair: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(
            IERC20(token0).balanceOf(address(this)), 
            IERC20(token1).balanceOf(address(this)), 
            reserve0, 
            reserve1
        );
    }

    // External functions that are view
    function getReserves() 
        public
        override 
        view 
        returns (
            uint112 _reserve0, 
            uint112 _reserve1, 
            uint32 _blockTimestampLast
        ) 
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // Private functions
    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(
        uint112 _reserve0,
        uint112 _reserve1
    )
    private
    returns (bool feeOn)
    {
        address feeTo = ICoinvestingDeFiFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
           kLast = 0; 
        } 
    }

    function _safeTransfer(
        address token,
        address to,
        uint value
    ) 
    private 
    {
        (bool success, bytes memory data) = 
            token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "PAIR: TXFR_FL"
        );
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint balance0,
        uint balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) 
    private
    {
        require(balance0 <= type(uint112).max && balance1 <= type(uint).max, "PAIR: OVF");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }
}