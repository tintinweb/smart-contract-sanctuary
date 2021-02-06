/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

pragma solidity 0.8.0;


interface WETHInterace {
    function withdraw(uint256 wad) external;
    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}


contract WETHUnwrapper {
    WETHInterace private _WETH = WETHInterace(
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    );

    receive() external payable {}

    function unwrapWETHFor(address account, uint256 amount) external {
        if (amount > 0) {
            require(
                _WETH.transferFrom(account, address(this), amount),
                "WETH transfer in failed... has the allowance been set?"
            );
            _WETH.withdraw(amount);

            (bool ok, ) = account.call{value: address(this).balance}("");
            if (!ok) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }
}