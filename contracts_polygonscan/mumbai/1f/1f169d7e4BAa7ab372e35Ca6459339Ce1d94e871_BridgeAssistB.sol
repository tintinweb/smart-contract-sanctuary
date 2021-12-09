// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
interface IXFUN {
    function mint(address recipient, uint256 amount) external;
    function burn(address sender, uint256 amount, uint256 fee) external;
}
contract BridgeAssistB {
    address public owner;
    IXFUN public TKN;

    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
    
    event Collect(address indexed sender, uint256 amount);
    event Dispense(address indexed sender, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function collect(address _sender, uint256 _amount, uint256 _fee) public restricted returns (bool success) {
        TKN.burn(_sender, _amount, _fee);
        emit Collect(_sender, _amount);
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

    constructor(IXFUN _TKN) {
        TKN = _TKN;
        owner = msg.sender;
    }
}