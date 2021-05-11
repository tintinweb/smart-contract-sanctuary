// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ERC20 {
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function balanceOf(address account) external view returns (uint256);
}

contract UserAddress {
    address payable public coldAddress;

    constructor(address payable addr) {
        require(addr != address(0), "0x0 is an invalid address");
        coldAddress = addr;
    }

    event receiveNative(uint256 amount);

    function withdrawNative(uint256 _value) public {
        coldAddress.transfer(_value);
        emit receiveNative(_value);
    }

    function withdrawToken(address _token, uint256 _value)
        public
        returns (bool success)
    {
        return ERC20(_token).transfer(coldAddress, _value);
    }

    receive() external payable {
        coldAddress.transfer(msg.value);
        emit receiveNative(msg.value);
    }
}