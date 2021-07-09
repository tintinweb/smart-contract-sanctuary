pragma solidity 0.8.6;

import "./library/TransferHelper.sol";
import "./interface/IGYM.sol";
import "./interface/IPancakeRouter.sol";

contract BuyAndBurn {
    address public constant pancakeRouter = 0x67C2DFa68BFc104B51C63521df3B1734dc3ec309;
    address public constant wbnb = 0x97C19036E16BEFCc6f433FaCc7C9738Fc9793a98;
    address public gymToken;

    constructor(address _gymToken) public {
        gymToken = _gymToken;
    }

    receive() external payable {}

    function buyAndBurnBNB() external payable {
        address[] memory _path = new address[](2);
        _path[0] = wbnb;
        _path[1] = gymToken;
        uint256 _amount = IPancakeRouter(pancakeRouter).getAmountsOut(msg.value, _path)[1];
        IPancakeRouter(pancakeRouter).swapETHForExactTokens{value: msg.value}(
            _amount,
            _path,
            address(this),
            block.timestamp
        );
        IGYM(gymToken).burn(_amount);
    }

    function buyAndBurnBEP20(address _token, uint256 _amount) external {
        address[] memory _path = new address[](3);
        _path[0] = _token;
        _path[1] = wbnb;
        _path[2] = gymToken;
        uint256 _amountOut = IPancakeRouter(pancakeRouter).getAmountsOut(_amount, _path)[2];
        
        TransferHelper.safeApprove(_token, pancakeRouter, _amount);
        IPancakeRouter(pancakeRouter).swapExactTokensForTokens(
            _amount,
            _amountOut,
            _path,
            address(this),
            block.timestamp
        );
        IGYM(gymToken).burn(_amountOut);
    }
}

pragma solidity 0.8.6;

interface IGYM {
    function burn(uint256 _amount) external;
}

pragma solidity 0.8.6;

interface IPancakeRouter {
    function swapETHForExactTokens(
        uint256 _amountOut,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256[] memory _amounts);

    function swapExactTokensForTokens(
        uint _amountIn,
        uint _amountOutMin,
        address[] calldata _path,
        address _to,
        uint _deadline
    ) external returns (uint[] memory _amounts);

    function getAmountsOut(uint256 _amountsIn, address[] calldata _path) external view returns(uint256[] memory);
}

pragma solidity 0.8.6;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}