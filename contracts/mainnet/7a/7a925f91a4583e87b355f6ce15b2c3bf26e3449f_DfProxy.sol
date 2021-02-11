/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

pragma solidity ^0.5.16;

contract DfProxy {
    function cast(address payable _to, bytes calldata _data) external payable {
        (bool success, bytes memory returndata) =
            address(_to).call.value(msg.value)(_data);
        require(success, "low-level call failed");
    }

    function withdrawEth(address payable _to) public {
        (bool result, ) = _to.call.value(address(this).balance)("");
        require(result, "Transfer of ETH failed");
    }

    function() external payable {}
}