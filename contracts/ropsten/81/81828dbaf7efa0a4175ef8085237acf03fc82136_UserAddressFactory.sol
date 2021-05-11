// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./UserAddress.sol";

contract UserAddressFactory {
    address payable public immutable coldAddress;
    event UserAddressCreated(address);

    // 只有冷钱包
    constructor(address payable addr) {
        require(addr != address(0), "0x0 is an invalid address");
        coldAddress = addr;
    }

    // 创建地址，相同的UserAddressFactory
    function createUserAddress(bytes32 salt)
        external
        returns (address userAddress)
    {
        UserAddress newAddress = new UserAddress{salt: salt}(coldAddress);
        userAddress = address(newAddress);
        emit UserAddressCreated(userAddress);
    }
}