/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IWETHelper {
    function withdraw(uint) external;
}

contract WETHelper {
    receive() external payable {
    }
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, '!WETHelper: ETH_TRANSFER_FAILED');
    }
    function withdraw(address _eth, address _to, uint256 _amount) public {
        IWETHelper(_eth).withdraw(_amount);
        safeTransferETH(_to, _amount);
    }
}