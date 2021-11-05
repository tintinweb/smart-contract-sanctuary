/**
 *Submitted for verification at arbiscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface IPopsicleV3Optimizer {
    function token0() external view returns (address);
    function token1() external view returns (address);
 
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        address to
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external ;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IChi is IERC20 {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256 freed);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

interface IGasDiscountExtension {
    function calculateGas(uint256 gasUsed, uint256 flags, uint256 calldataLength) external view returns (IChi, uint256);
}

interface IAggregationExecutor is IGasDiscountExtension {
    function callBytes(bytes calldata data) external payable;  // 0xd9c45357
}

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;
}

interface IRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function swap(IAggregationExecutor caller, SwapDescription calldata desc, bytes calldata data) external payable returns (uint256 returnAmount, uint256 gasLeft);
    function unoswap(IERC20 srcToken, uint256 amount, uint256 minReturn, bytes32[] calldata ) external payable returns(uint256 returnAmount);
}

contract OptimizerZap {
    IRouter constant router = IRouter(0x11111112542D85B3EF69AE05771c2dCCff4fAa26);
    address constant eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable DAO;
    
    struct Cache {
        uint256 amount0;
        uint256 amount1;
        uint256 return0Amount;
        uint256 return1Amount;
    }

    struct TokenData {
        bool IsUno;
        IAggregationExecutor caller;
        IRouter.SwapDescription desc;
        bytes data;
        bytes32[] pools;
    }

    constructor(address _DAO) {
        DAO = _DAO;
    }

    function DepositInEth(address optimizer, address to, TokenData calldata tokenData) external payable {
        uint value = msg.value;
       
        address token0 = IPopsicleV3Optimizer(optimizer).token0();
        address token1 = IPopsicleV3Optimizer(optimizer).token1();
        IWETH9(weth).deposit{value: value}();
        _approveToken(weth, optimizer, value);
        require(token0 == weth || token1 == weth, "BO");
        if (token0 == weth) {
            require(token1 == address(tokenData.desc.srcToken), "TNA");
            
            TransferHelper.safeTransferFrom(token1, msg.sender, address(this), tokenData.desc.amount);
            _approveToken(token1, optimizer, tokenData.desc.amount);
            (, uint256 amount0,uint256 amount1) = IPopsicleV3Optimizer(optimizer).deposit(value, tokenData.desc.amount, to);
            require(value >= amount0, "UA0");
            require(tokenData.desc.amount >= amount1, "UA1");
        } else {
            require(token0 == address(tokenData.desc.srcToken), "TNA");
            TransferHelper.safeTransferFrom(token0, msg.sender, address(this), tokenData.desc.amount);
            _approveToken(token0, optimizer, tokenData.desc.amount);
            (, uint256 amount0,uint256 amount1) =IPopsicleV3Optimizer(optimizer).deposit(tokenData.desc.amount, value,  to);
            require(tokenData.desc.amount >= amount0, "UA0");
            require(value >= amount1, "UA1");
        }
    }

    function ZapIn(address tokenIn, uint amount, address optimizer, address to, TokenData calldata token0Data, TokenData calldata token1Data) external payable {
        require(optimizer != address(0));
        require(to != address(0));
        address token0 = IPopsicleV3Optimizer(optimizer).token0();
        address token1 = IPopsicleV3Optimizer(optimizer).token1();
        require(tokenIn == address(token0Data.desc.srcToken), "NAT0");
        require(tokenIn == address(token1Data.desc.srcToken), "NAT1");
        require(token0 == address(token0Data.desc.dstToken), "IT0");
        require(token1 == address(token1Data.desc.dstToken), "IT1");

        require(token0Data.desc.amount + token1Data.desc.amount <= amount, "IA");
        Cache memory cache;
        if (tokenIn == eth || tokenIn == address(0)) {
            require(amount <= msg.value, "BA");

            if (token0 == weth) {
                IWETH9(weth).deposit{value: token0Data.desc.amount}();
                _approveToken(weth, optimizer, token0Data.desc.amount);
                if (token1Data.IsUno)
                {
                    cache.return1Amount = router.unoswap{value: token1Data.desc.amount}(IERC20(tokenIn), token1Data.desc.amount, token1Data.desc.minReturnAmount, token1Data.pools);
                } else {
                    (cache.return1Amount, ) = router.swap{value: token1Data.desc.amount}(token1Data.caller, token1Data.desc, token1Data.data);
                }
                _approveToken(token1, optimizer, cache.return1Amount);
                (, cache.amount0, cache.amount1) = IPopsicleV3Optimizer(optimizer).deposit(token0Data.desc.amount, cache.return1Amount, to);
                cache.return0Amount = token0Data.desc.amount-cache.amount0;
                cache.return1Amount = cache.return1Amount-cache.amount1;
                if (cache.return0Amount > 0 ) TransferHelper.safeTransfer(token0, to, cache.return0Amount);
                if (cache.return1Amount > 0 ) TransferHelper.safeTransfer(token1, to, cache.return1Amount);
            } else if (token1 == weth) {
                IWETH9(weth).deposit{value: token1Data.desc.amount}();
                _approveToken(weth, optimizer, token1Data.desc.amount);
                if (token0Data.IsUno)
                {
                    cache.return0Amount = router.unoswap{value: token0Data.desc.amount}(IERC20(tokenIn), token0Data.desc.amount, token0Data.desc.minReturnAmount, token0Data.pools);
                } else {
                    (cache.return0Amount, ) = router.swap{value: token0Data.desc.amount}(token0Data.caller, token0Data.desc, token0Data.data);
                }
                _approveToken(token0, optimizer, cache.return0Amount);
                (, cache.amount0, cache.amount1) = IPopsicleV3Optimizer(optimizer).deposit(cache.return0Amount, token1Data.desc.amount, to);
                cache.return0Amount = cache.return0Amount-cache.amount0;
                cache.return1Amount = token1Data.desc.amount-cache.amount1;
                if (cache.return0Amount > 0 ) TransferHelper.safeTransfer(token0, to, cache.return0Amount);
                if (cache.return1Amount > 0 ) TransferHelper.safeTransfer(token1, to, cache.return1Amount);
            } else {
                if (token0Data.IsUno)
                {
                    cache.return0Amount = router.unoswap{value: token0Data.desc.amount}(IERC20(tokenIn), token0Data.desc.amount, token0Data.desc.minReturnAmount, token0Data.pools);
                } else {
                    (cache.return0Amount, ) = router.swap{value: token0Data.desc.amount}(token0Data.caller, token0Data.desc, token0Data.data);
                }
                if (token1Data.IsUno)
                {
                    cache.return1Amount = router.unoswap{value: token1Data.desc.amount}(IERC20(tokenIn), token1Data.desc.amount, token1Data.desc.minReturnAmount, token1Data.pools);
                } else {
                    (cache.return1Amount, ) = router.swap{value: token1Data.desc.amount}(token1Data.caller, token1Data.desc, token1Data.data);
                }
                _approveToken(token0, optimizer, cache.return0Amount);
                _approveToken(token1, optimizer, cache.return1Amount);
                (, cache.amount0, cache.amount1) = IPopsicleV3Optimizer(optimizer).deposit(cache.return0Amount, cache.return1Amount, to);
                cache.return0Amount = cache.return0Amount-cache.amount0;
                cache.return1Amount = cache.return1Amount-cache.amount1;
                if (cache.return0Amount > 0 ) TransferHelper.safeTransfer(token0, to, cache.return0Amount);
                if (cache.return1Amount > 0 ) TransferHelper.safeTransfer(token1, to, cache.return1Amount);
            }
            return;
        } else {
            
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amount);
            _approveToken(tokenIn, address(router), amount);
            if (tokenIn == token0) {
                cache.return0Amount = token0Data.desc.amount;
            } else {

                if (token0Data.IsUno)
                {
                    cache.return0Amount = router.unoswap(IERC20(tokenIn), token0Data.desc.amount, token0Data.desc.minReturnAmount, token0Data.pools);
                } else {
                    (cache.return0Amount, ) = router.swap(token0Data.caller, token0Data.desc, token0Data.data);
                }
            }
            if (tokenIn == token1) {
                cache.return1Amount = token1Data.desc.amount;
            } else {
                
                if (token1Data.IsUno)
                {
                    cache.return1Amount = router.unoswap(IERC20(tokenIn), token1Data.desc.amount, token1Data.desc.minReturnAmount, token1Data.pools);
                } else {
                    (cache.return1Amount, ) = router.swap(token1Data.caller, token1Data.desc, token1Data.data);
                }
            }
            _approveToken(token0, optimizer, cache.return0Amount);
            _approveToken(token1, optimizer, cache.return1Amount);
            (, cache.amount0, cache.amount1) = IPopsicleV3Optimizer(optimizer).deposit(cache.return0Amount, cache.return1Amount, to);
            cache.return0Amount = cache.return0Amount-cache.amount0;
            cache.return1Amount = cache.return1Amount-cache.amount1;
            if (cache.return0Amount > 0 ) TransferHelper.safeTransfer(token0, to, cache.return0Amount);
            if (cache.return1Amount > 0 ) TransferHelper.safeTransfer(token1, to, cache.return1Amount);
            return;
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), spender) > 0) IERC20(token).approve(spender, 0);
        IERC20(token).approve(spender, amount);
    }
    
    

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens to the DAO
     *  @return bool
     */
    function recoverLostToken( address _token ) external returns ( bool ) {
        TransferHelper.safeTransfer(_token, DAO, IERC20( _token ).balanceOf( address(this)));
        return true;
    }

    function refundETH() external returns ( bool ) {
        if (address(this).balance > 0) TransferHelper.safeTransferETH(DAO, address(this).balance);
        return true;
    }
}