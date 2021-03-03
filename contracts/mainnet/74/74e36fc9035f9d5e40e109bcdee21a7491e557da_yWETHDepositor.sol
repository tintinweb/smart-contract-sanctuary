/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity 0.8.0;


interface WETHInterace {
    function deposit() external payable;
    function approve(address usr, uint wad) external returns (bool);
}

interface yWETHInterface {
    function deposit(uint256 wad) external;
    function balanceOf(address usr) external view returns (uint256 wad);
    function transfer(address dst, uint256 wad) external returns (bool);
}


contract yWETHDepositor {
    WETHInterace private _WETH = WETHInterace(
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    );

    yWETHInterface private _yWETH = yWETHInterface(
        0xe1237aA7f535b0CC33Fd973D66cBf830354D16c7
    );

    constructor() {
        require(_WETH.approve(address(_yWETH), type(uint256).max));
    }

    function deposit(address account) external payable returns (uint256 received) {
        _WETH.deposit{value: msg.value}();
        _yWETH.deposit(msg.value);
        received = _yWETH.balanceOf(address(this));
        require(
            _yWETH.transfer(account, received), "yWETH transfer out failed."
        );
    }
}