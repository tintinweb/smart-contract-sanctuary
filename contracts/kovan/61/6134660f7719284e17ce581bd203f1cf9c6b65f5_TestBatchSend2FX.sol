/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

pragma solidity ^0.6.6;

interface IFxBridge {
    function sendToFx(address _tokenContract, bytes32 _destination, bytes32 _targetIBC, uint256 _amount) external;
}

interface IERC20 {
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

contract TestBatchSend2FX {
    bytes32 destination = 0x000000000000000000000000d4e44d5e89b1271475fe4d43fbf84a3d24b9e390;
    bytes32 targetIBC = 0x0000000000000000000000000000000000000000000000000000000000000000;

    function batch(address token, address bridge, uint number) public {
        IERC20(token).transferFrom(msg.sender, address(this), number);
        IERC20(token).approve(bridge,number);
        for (uint i = 0; i < number; i++) {
            IFxBridge(bridge).sendToFx(token, destination, targetIBC, 1);
        }
    }
}