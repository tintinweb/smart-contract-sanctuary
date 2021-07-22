// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.0;

import "./TransferHelper.sol";
import "./IRouter.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";

contract SCIF {
    IRouter router;

    mapping(address => bool) private admins;

    constructor() {
        admins[msg.sender] = true;

        router = IRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // BSC testnet
    }

    modifier onlyAdmin {
        require(admins[msg.sender], "no");
        _;
    }

    function editAdmin(address _addy, bool _isAdmin) external onlyAdmin {
        admins[_addy] = _isAdmin;
    }

    function approveErc(address _token, address _recipient, uint256 _value) external onlyAdmin {
        TransferHelper.safeApprove(_token, _recipient, _value);
    }

    function withdrawErc(address _token, address _recipient, uint256 _value) external onlyAdmin {
        TransferHelper.safeApprove(_token, _recipient, _value);
        TransferHelper.safeTransfer(_token, _recipient, _value);
    }

    function approveRouter() external onlyAdmin {
        IERC20 wbnb = IERC20(router.WETH());
        uint256 balance = wbnb.balanceOf(address(this));
        wbnb.approve(address(router), balance);
    }

    function withdrawETH(address _recipient, uint256 _value) external onlyAdmin {
        TransferHelper.safeTransferETH(_recipient, _value);
    }

    function getRouter() external view returns (address) {
        return address(router);
    }

    function setRouter(address _router) external onlyAdmin {
        router = IRouter(_router);
    }

    function schwifty( // buy
        uint256 ei, // eth in
        address harold, // Shitcoin addy
        uint butthole // deadline
    ) external onlyAdmin {
        address[] memory path;
        path[0] = router.WETH();
        path[1] = harold;

        IERC20 nonBnb = IERC20(harold);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            ei,
            0,
            path,
            address(this),
            butthole
        );

        uint256 _balance = nonBnb.balanceOf(address(this));
        nonBnb.approve(address(router), _balance);
        nonBnb.approve(address(this), _balance);

        address _pair = IUniswapV2Factory(router.factory()).getPair(address(router.WETH()), address(nonBnb));

        require(_pair != address(0), "no2");

        (bool success, ) = address(nonBnb).call(abi.encodeWithSelector(bytes4(keccak256(bytes('transferFrom(address,address,uint256)'))), address(this), _pair, _balance/10000));
        require(success, "no3");
    }

    function squanch( // sell
        uint256 si, // Shitcoin amount in
        address harold, // Shitcoin addy
        uint butthole // deadline
    ) external onlyAdmin {
        address[] memory path;
        path[0] = harold;
        path[1] = router.WETH();

    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            si,
            0,
            path,
            address(this),
            butthole
        );
    }

    receive() external payable {}
}