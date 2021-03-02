/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity 0.8.0;


interface WETHInterace {
    function balanceOf(address usr) external view returns (uint256 wad);
    function withdraw(uint256 wad) external;
}

interface yWETHInterface {
    function withdraw(uint256 wad) external;
    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}


contract yWETHWithdrawer {
    WETHInterace private _WETH = WETHInterace(
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    );

    yWETHInterface private _yWETH = yWETHInterface(
        0xe1237aA7f535b0CC33Fd973D66cBf830354D16c7
    );

    receive() external payable {}

    function withdraw(address account, uint256 amount) external returns (uint256 received) {
        require(
            _yWETH.transferFrom(account, address(this), amount),
            "yWETH transfer in failed... has the allowance been set?"
        );

        _yWETH.withdraw(amount);
        _WETH.withdraw(_WETH.balanceOf(address(this)));

        received = address(this).balance;
        (bool ok, ) = account.call{value: received}("");
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}