// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenB.sol";  

contract BridgeAssistB {
    address public owner;
    Token public TKN;

    modifier restricted() {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }

    event BridgeAssistUpload(address indexed sender, uint256 amount, string target);
    event Dispense(address indexed sender, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function upload(uint256 amount, string memory target) public returns (bool success) {
        TKN.burnFrom(msg.sender, amount);
        emit BridgeAssistUpload(msg.sender, amount, target);
        return true;
    }


    function dispense(address _sender, uint256 _amount) public restricted returns (bool success) {
        TKN.mint(_sender, _amount);
        emit Dispense(_sender, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    function infoBundle(address user)
        external
        view
        returns (
            Token token,
            uint256 all,
            uint256 bal
        )
    {
        return (TKN, TKN.allowance(user, address(this)), TKN.balanceOf(user));
    }

    constructor(Token _TKN) {
        TKN = _TKN;
        owner = msg.sender;
    }
}