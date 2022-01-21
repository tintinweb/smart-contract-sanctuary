// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract BatchTransfer {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function batchTransferEthAvg(address[] memory _tos) payable public returns (bool) {
        require(_tos.length > 0, "_tos.length must be greater than 0");
        require(msg.value > 0, "msg.value must be greater than 0");
        uint256 value = msg.value / _tos.length;
        for (uint32 i = 0; i < _tos.length; i++) {
            TransferHelper.safeTransferETH(_tos[i], value);
        }
        return true;
    }

    function batchTransferEth(address[] memory _tos, uint256[] memory _values) payable public returns (bool) {
        require(_tos.length > 0, "_tos.length must be greater than 0");
        require(_values.length > 0, "_values.length must be greater than 0");
        require(_tos.length == _values.length, "_tos.length and _values.length must be are equal");
        for (uint32 i = 0; i < _tos.length; i++) {
            TransferHelper.safeTransferETH(_tos[i], _values[i]);
        }
        return true;
    }

    // need to approve this contract first
    function batchTransferTokenAvg(address _token, address _from, address[] memory _tos, uint _value) public returns (bool){
        require(_tos.length > 0, "_tos.length must be greater than 0");
        require(_value > 0, "_value must be greater than 0");
        for (uint i = 0; i < _tos.length; i++) {
            TransferHelper.safeTransferFrom(_token, _from, _tos[i], _value);
        }
        return true;
    }

    // need to approve this contract first
    function batchTransferToken(address _token, address _from, address[] memory _tos, uint[] memory _values) public returns (bool){
        require(_tos.length > 0, "_tos.length must be greater than 0");
        require(_values.length > 0, "_values.length must be greater than 0");
        require(_tos.length == _values.length, "_tos.length and _values.length must be are equal");
        for (uint i = 0; i < _tos.length; i++) {
            TransferHelper.safeTransferFrom(_token, _from, _tos[i], _values[i]);
        }
        return true;
    }

    function withdraw(uint256 amount) public {
        require(msg.sender == owner, "not owner");
        TransferHelper.safeTransferETH(owner, amount);
    }

}

library TransferHelper {
    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

}