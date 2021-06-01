/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

pragma solidity ^0.6.6;

interface IFxBridge {
    function sendToFx(address _tokenContract, bytes32 _destination, bytes32 _targetIBC, uint256 _amount) external;
}

interface IERC20 {
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract TestBatchSend2FX {
    uint unit = 1e18;

    function batch(address token, address bridge, bytes32 destination, bytes32 targetIBC, uint number) public {
        IERC20(token).transferFrom(msg.sender, address(this), number * unit);
        for (uint i = 0; i < number; i++) {
            IFxBridge(bridge).sendToFx(token, destination, targetIBC, unit);
        }
    }
}