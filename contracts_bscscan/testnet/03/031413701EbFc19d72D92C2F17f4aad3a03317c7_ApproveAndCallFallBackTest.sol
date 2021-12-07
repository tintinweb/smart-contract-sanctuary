pragma solidity ^0.6.0;

import "../interface/ApproveAndCallFallBack.sol";

contract ApproveAndCallFallBackTest is ApproveAndCallFallBack {
    event LogTestReceiveApproval(address from, uint256 _amount, address _token);

    function receiveApproval(address _from, uint256 _amount, bytes calldata /* _data */) override external {
        emit LogTestReceiveApproval(_from, _amount, msg.sender);
    }
}

pragma solidity ^0.6.0;

interface ApproveAndCallFallBack {
    function receiveApproval(address _from, uint256 _amount, bytes calldata _data) external;
}