/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity ^0.8.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function transferFrom(address from, address to, uint value) external returns (bool);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


contract UniswapFlashloan is IUniswapV2Callee {
 
    address private uniswapFactory;
    uint constant deadline = 10 minutes;
    address private _permissionedPairAddress = address(0);
    address private owner;
 
    constructor(address _uniswapFactory) {
        owner = msg.sender;
        uniswapFactory = _uniswapFactory;
    }
    
    receive() external payable {}
    
    function startFlashloan(address token, uint256 amount, address tokenExtra) public {
        require(msg.sender == owner);
        address pairAddress = IUniswapV2Factory(uniswapFactory).getPair(token, tokenExtra);
        require(pairAddress != address(0), "Requested _token is not available.");
        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();
        uint256 amount0Out = token == token0 ? amount : 0;
        uint256 amount1Out = token == token1 ? amount : 0;
        bytes memory data = abi.encode(
            pairAddress,
            token,
            amount
        );
        IUniswapV2Pair(pairAddress).swap(amount0Out, amount1Out, address(this), data);
    }
    
    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external override {
        require(tx.origin == owner);
        require(sender == address(this), "only this contract may initiate");
        (address pairAddress, address token, uint256 amount) = abi.decode(data, (address, address, uint256));
        
        // do something, already receive token
        
        uint256 amountRequired = amount * 1000 / 997 + 1;
        TransferHelper.safeTransfer(token, address(pairAddress), amountRequired);        
    }
    
}