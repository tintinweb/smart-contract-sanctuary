/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// File: MockSafe_flat.sol


// File: gist-105ae8f09c34406997d217ee4dc0f63a/MockSafe.sol


pragma solidity >=0.8.0;

contract MockSafe {

    address public module;

    error NotAuthorized(address unacceptedAddress);

    receive() external payable {}

    function enableModule(address _module) external {
        module = _module;
    }

    function exec(
        address payable to,
        uint256 value,
        bytes calldata data
    ) external {
        bool success;
        bytes memory response;
        (success, response) = to.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(response, 0x20), mload(response))
            }
       }
    }
    //asd

// jq was here
    function execTransactionFromModule(
        address payable to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external returns (bool success) {
        if (msg.sender != module) revert NotAuthorized(msg.sender);
        if (operation == 1) (success, ) = to.delegatecall(data);
        else (success, ) = to.call{value: value}(data);
    }
}