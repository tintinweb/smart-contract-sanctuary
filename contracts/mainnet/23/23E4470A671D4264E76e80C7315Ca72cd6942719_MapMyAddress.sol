// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

contract MapMyAddress {
    mapping(address => bool) public mapped;
    
    event Mapped(address sender, string cardanoAddress);
    
    function mapAddress(string memory cardanoAddress) external {
        require(!mapped[msg.sender],"Already mapped");
        mapped[msg.sender] = true;
        emit Mapped(msg.sender,cardanoAddress);
    }
}