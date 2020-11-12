// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.5.1;
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
contract BSpare {
    address public BMining;
    address public owner;
    address public finance;
    
    event Extract(address to, uint256 value);
    
    constructor(address _BMining) public {
        BMining = _BMining;
        owner = msg.sender;
    }
    
    receive() external payable { }
    
    function setupFinance(address _finance) public {
        require(msg.sender == owner, "REQUIRE OWNER");
        finance = _finance;
    }
    
    function upgradeMining(address _newBMining) public {
        require(msg.sender == owner, "REQUIRE OWNER");
        BMining = _newBMining;
    }
    
    function requestSpare(uint amount) public {
        require(msg.sender == BMining, "REQUIRE BMINING");
        TransferHelper.safeTransferETH(BMining, amount);
    }
    
    function extract() public {
        require(msg.sender == finance, "REQUIRE FINANCE");
        emit Extract(finance, address(this).balance);
        TransferHelper.safeTransferETH(finance, address(this).balance);
    }
}