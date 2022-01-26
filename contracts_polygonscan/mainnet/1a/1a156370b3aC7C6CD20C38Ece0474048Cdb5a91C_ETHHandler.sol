// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import "../interfaces/IWETH.sol";
import "../interfaces/IEthHandler.sol";

contract ETHHandler is IEthHandler {
    receive() external payable {}

    //Send WETH and then call withdraw
    function withdraw(address weth, uint256 amount) external override {
        IWETH(weth).withdraw(amount);
        (bool success, ) = msg.sender.call{ value: amount }(new bytes(0));
        require(success, "safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IEthHandler {

    function withdraw(address WETH,uint256) external;
}