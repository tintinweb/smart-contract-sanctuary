/**
 *Submitted for verification at Etherscan.io on 2022-01-08
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
interface iMARKET {
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
    address public market;

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(address _weth, address _market) {
        _status = _NOT_ENTERED;
        WETH = _weth;
        market = _market;
    }

    receive() external payable {}

     //############################## IN ##############################

    function swapIn(address asset, uint amount, uint256 deadline, string calldata memo, address thorchainVault, address thorchainRouter) public nonReentrant {
        uint256 _safeAmount = safeTransferFrom(asset, amount); // Transfer asset
        (bool success,) = asset.call(abi.encodeWithSignature("approve(address,uint256)", market, _safeAmount)); // Approve to transfer
        require(success);
        address[] memory path = new address[](2);
        path[0] = asset; path[1] = WETH;
        iMARKET(market).swapExactTokensForETH(_safeAmount, 0, path, address(this), deadline);
        _safeAmount = address(this).balance;
        iROUTER(thorchainRouter).depositWithExpiry{value:_safeAmount}(payable(thorchainVault), ETH, _safeAmount, memo, deadline);
    }

    //############################## OUT ##############################

    function swapOut(address asset, address to) public payable nonReentrant {
        address[] memory path = new address[](2);
        path[0] = WETH; path[1] = asset;
        iMARKET(market).swapExactETHForTokens{value: msg.value}(0, path, to, type(uint).max);
    }

    //############################## HELPERS ##############################

    // Safe transferFrom in case asset charges transfer fees
    function safeTransferFrom(address _asset, uint _amount) internal returns(uint amount) {
        uint _startBal = iERC20(_asset).balanceOf(address(this));
        (bool success, bytes memory data) = _asset.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
        return (iERC20(_asset).balanceOf(address(this)) - _startBal);
    }
}