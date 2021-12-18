/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

interface SwapV2 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface CruxToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function getTaxes() external pure returns (uint8 _sellTax, uint8 _buyTax, uint8 _transferTax) ;
}

contract SupermanSwap {
    address public SwapAddr ;
    address public CruxAddr ;


    address public Owner ;

    modifier onlyOwner() {
        require( Owner  == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        Owner = msg.sender ;
    }

    function setConfig( address swapAddr , address cruxAddr ) external onlyOwner{
        SwapAddr = swapAddr ;
        CruxAddr = cruxAddr ;
    }

    function superTransfer( address token , uint value ) external onlyOwner {
        if( token == address(0) ) {
            // transfer bnb
            TransferHelper.safeTransferETH( Owner , value);
        } else {
            TransferHelper.safeTransfer( token , Owner , value); 
        }
    }

    function checkStatus( uint8 v ) public view {
        CruxToken token = CruxToken(CruxAddr) ;
        (uint8 _sellTax, uint8 _buyTax, uint8 _transferTax) = token.getTaxes() ;
        require( _sellTax <= v , "Not allow." ) ;
        require( _buyTax <= v , "Not allow." ) ;
        require( _transferTax <= v , "Not allow." ) ;
    }

    function swapToken(uint min , address[] memory path ) external payable onlyOwner {
        SwapV2 swap = SwapV2( SwapAddr) ;
        uint amountIn = msg.value ;
        uint[] memory plan = swap.getAmountsOut( amountIn, path);
        uint planOut = plan[1] ;
        require( planOut > min , "Too less .");
        uint[] memory swapResult = swap.swapExactETHForTokens{
            value : amountIn
        }( min , path , Owner, block.timestamp + 1200 );

        uint currOut = swapResult[1] ;
        require( currOut >= min , "Reback too low .") ; 
        TransferHelper.safeTransfer( path[ path.length - 1 ] , Owner , currOut );
    }

}