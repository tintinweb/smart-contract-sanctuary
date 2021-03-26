/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity 0.6.6;

interface IGasToken {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

interface ERC20 {
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Router02 {
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to,uint deadline) 
        external returns (uint[] memory amounts);
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}


library LibBytes {

    using LibBytes for bytes;

    function popLast20Bytes(bytes memory b)
        internal
        pure
        returns (address result)
    {
        require(
            b.length >= 20,
            "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED"
        );

        // Store last 20 bytes.
        result = readAddress(b, b.length - 20);

        assembly {
            // Subtract 20 from byte array length.
            let newLen := sub(mload(b), 20)
            mstore(b, newLen)
        }
        return result;
    }

    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        require(
            b.length >= index + 20,  // 20 is length of address
            "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED"
        );

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

}


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Dex, TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Dex, TransferHelper: TRANSFER_FAILED');
    }

}


// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


library UniswapV2Library {
    using SafeMath for uint;
    
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

}


contract PermissionGroups{
    
    address public admin;
    address public pendingAdmin;

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin,"onlyAdmin");
        _;
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        pendingAdmin = newAdmin;
    }

    function claimAdmin() external {
        require(pendingAdmin == msg.sender,"pendingAdmin != msg.sender");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

}


contract AssetManager is PermissionGroups{
    
    uint256 internal constant MAX_UINT = 2**256 - 1;
    address public wethAddress = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    receive() external payable{}
    fallback() external payable{}
    
    function setWethAddress(address _wethAdress) external onlyAdmin {
        wethAddress = _wethAdress;
    }
    
    function withdrawEth(address payable _to, uint _value) external onlyAdmin{
        require(_to != address(0),"_to == address(0)");
        _to.transfer(_value);
    }
    
    function withdrawToken(address _token, address _to, uint _value) external onlyAdmin{
        require(_to != address(0),"_to == address(0)");
        TransferHelper.safeTransfer(_token,_to,_value);
    }
    
    function approveTokensSpender(address[] calldata _tokens, address _spender) external onlyAdmin{
        require(_tokens.length>=1,"_tokens.length<1");
        for(uint i=0; i<_tokens.length; i++){
            TransferHelper.safeApprove(_tokens[i],_spender,MAX_UINT);
        }
    }
    
    function disapproveTokensSpender(address[] calldata _tokens, address _spender) external onlyAdmin{
        require(_tokens.length>=1,"_tokens.length<1");
        for(uint i=0; i<_tokens.length; i++){
            TransferHelper.safeApprove(_tokens[i],_spender,0);
        }
    }

}

contract DexToDexArb is AssetManager,IUniswapV2Callee{
    
    using LibBytes for bytes;
    
    address public gasToken = address(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    address public gasTokenPayer;
    
    // constructor(address _wethAddress) public {
    //     wethAddress = _wethAddress;
    // }

    modifier useGasToken(uint gasTokenAmount) {
        _;
        if(gasTokenAmount>0){
            IGasToken(gasToken).freeFromUpTo(gasTokenPayer,gasTokenAmount);
        }
    } 
    
    function setGasToken(address newGasToken) external onlyAdmin{
        gasToken = newGasToken;
    }
    
    function setGasTokenPayer(address newGasTokenPayer) external onlyAdmin{
        gasTokenPayer = newGasTokenPayer;
    }

    function uniswapSwap(address uniswapPairAddr,uint amount0Out, uint amount1Out, bytes calldata _data, uint gasTokenAmount) external useGasToken(gasTokenAmount){
        IUniswapV2Pair(uniswapPairAddr).swap(amount0Out,amount1Out,address(this),_data);
    }
    
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata _data) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
        address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch the address of token1
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(msg.sender).getReserves();
        
        uint returnAmount;
        uint borrowAmount;
        address returnToken;
        address[] memory arbPath = new address[](2); 
        if (amount0 >0) {
            borrowAmount = amount0;
            arbPath[0] = token0;
            arbPath[1] = token1;
            returnToken = token1;
            returnAmount = UniswapV2Library.getAmountIn(borrowAmount + 1, reserve1, reserve0);
        }
        else if(amount1 >0) {
            borrowAmount = amount1;    
            arbPath[0] = token1;
            arbPath[1] = token0;
            returnToken = token0;
            returnAmount = UniswapV2Library.getAmountIn(borrowAmount + 1, reserve0, reserve1);
        }
        else {
            revert("amount0 ==0 and amount1 ==0");
        }

        if(_data.length == 20) {
            address _to = _data.popLast20Bytes();
            if (borrowAmount > ERC20(arbPath[0]).allowance(address(this),_to) ) {
                TransferHelper.safeApprove(arbPath[0],_to,MAX_UINT);
            }
            uint deadline = block.timestamp + 1000;   
            if(arbPath[0] == wethAddress) {
                IUniswapV2Router02(_to).swapTokensForExactTokens(returnAmount,borrowAmount,arbPath,msg.sender,deadline);
            }
            else {
                IUniswapV2Router02(_to).swapExactTokensForTokens(borrowAmount,returnAmount,arbPath,address(this),deadline);
                TransferHelper.safeTransfer(returnToken,msg.sender,returnAmount);
            }
        }
        else {
            address _to = _data.popLast20Bytes();
            if (borrowAmount > ERC20(arbPath[0]).allowance(address(this),_to) ) {
                TransferHelper.safeApprove(arbPath[0],_to,MAX_UINT);
            }
            (bool _success,) = _to.call(_data);
            require(_success);
            TransferHelper.safeTransfer(returnToken,msg.sender,returnAmount);
        }
    
    }
    
    
}