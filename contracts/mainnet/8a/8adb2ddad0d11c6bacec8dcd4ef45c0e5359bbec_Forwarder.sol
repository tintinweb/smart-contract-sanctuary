/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <0.9.0;

contract Forwarder {

    address payable immutable public destinationAddress;
    event Created(bytes32 salt, address indexed forwarder);
    event Forwarded(address addr, uint256 quantity);

    constructor(address payable destination) {
        destinationAddress = destination;
        destination.transfer(address(this).balance);
        emit Forwarded(address(this), address(this).balance);
    }

    // EIP-1167
    function derivate(bytes32 salt) external returns (address result) {
        bytes20 targetBytes = bytes20(address(this));
        assembly {
            let bs := mload(0x40)
            mstore(bs, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(bs, 0x14), targetBytes)
            mstore(add(bs, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let encoded_data := add(0x20, bs) // load initialization code.
            let encoded_size := mload(bs)     // load the init code's length.

            result := create2(0, bs, 0x37, salt)
        }

        emit Created(salt, result);
    }

    // Auto forward all incoming ethers
    receive() external payable {
        flush();
    }

    // Manually require to forward ethers when the forwarder has been derivated after assets have been received on the contract address
    function flush() public {
        // destinationAddress.transfer(address(this).balance);
        destinationAddress.call{value: address(this).balance}("");
        emit Forwarded(address(this), address(this).balance);
    }

    // Forward ERC20 tokens from a given contract address
    function flushTokens(address tokenContractAddress) public {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        uint256 forwarderBalance = instance.balanceOf(address(this));
        if (forwarderBalance == 0) {
            return;
        }

        instance.transfer(destinationAddress, forwarderBalance);
        emit Forwarded(tokenContractAddress, forwarderBalance);
    }

    // Forward only a given quantity of ERC20 tokens from a the provided contract address 
    function flushTokensQuantity(address tokenContractAddress, uint256 quantity) public {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        instance.transfer(destinationAddress, quantity);
        emit Forwarded(tokenContractAddress, quantity);
    }

    // Forward all ethers present on this contract and all ERC20 tokens from a given contract address
    function flushTokensAndBalance(address tokenContractAddress) public {
        flush();
        flushTokens(tokenContractAddress);
    }

    function requireCall(address dest, bytes memory data) public returns (bool, bytes memory) {
        require(msg.sender == destinationAddress);
        return dest.call(data);
    }
}

interface ERC20Interface {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}