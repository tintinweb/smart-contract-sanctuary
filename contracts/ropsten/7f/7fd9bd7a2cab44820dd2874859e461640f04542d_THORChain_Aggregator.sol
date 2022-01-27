/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: MIT
// -------------------
// Aggregator Version: 1.0
// -------------------
pragma solidity 0.8.10;

// ERC20 Interface
interface iERC20 {
    function balanceOf(address) external view returns (uint256);
}
// ROUTER Interface
interface iROUTER {
    function depositWithExpiry(address payable vault, address asset, uint amount, string memory memo, uint expiration) external payable;
}
// Sushi Interface
interface iSWAPROUTER {
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
}

// THORChain_Aggregator is permissionless
contract THORChain_Aggregator {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    address private ETH = address(0);
    address public WETH;
    iSWAPROUTER public swapRouter;

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(address _weth, address _swapRouter) {
        _status = _NOT_ENTERED;
        WETH = _weth;
        swapRouter = iSWAPROUTER(_swapRouter);
    }

    receive() external payable {}

     //############################## IN ##############################

    function swapIn(
        address tcVault, 
        address tcRouter, 
        string calldata tcMemo, 
        address token,
        uint amount, 
        uint amountOutMin, 
        uint256 deadline
        ) public nonReentrant {
        uint256 _safeAmount = safeTransferFrom(token, amount); // Transfer asset
        safeApprove(token, address(swapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = token; path[1] = WETH;
        swapRouter.swapExactTokensForETH(_safeAmount, amountOutMin, path, address(this), deadline);
        _safeAmount = address(this).balance;
        iROUTER(tcRouter).depositWithExpiry{value:_safeAmount}(payable(tcVault), ETH, _safeAmount, tcMemo, deadline);
    }

    //############################## OUT ##############################

    function swapOut(address token, address to, uint256 amountOutMin) public payable nonReentrant {
        address[] memory path = new address[](2);
        path[0] = WETH; path[1] = token;
        swapRouter.swapExactETHForTokens{value: msg.value}(amountOutMin, path, to, type(uint).max);
    }

    //############################## HELPERS ##############################

    // Safe transferFrom in case asset charges transfer fees
    function safeTransferFrom(address _asset, uint _amount) internal returns(uint amount) {
        uint _startBal = iERC20(_asset).balanceOf(address(this));
        (bool success, bytes memory data) = _asset.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
        return (iERC20(_asset).balanceOf(address(this)) - _startBal);
    }

    function safeApprove(address _asset, address _address, uint _amount) internal {
        (bool success,) = _asset.call(abi.encodeWithSignature("approve(address,uint256)", _address, _amount)); // Approve to transfer
        require(success);
    }
}