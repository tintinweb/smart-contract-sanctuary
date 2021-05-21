/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
interface IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
    function burnFrom(address from, uint256 amount) external returns (bool);
}
contract BridgeAssistB {
    address public owner;
    IERC20 public TKN;

    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
    
    event Collect(address indexed sender, uint256 amount);
    event Dispense(address indexed sender, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function collect(address _sender, uint256 _amount) public restricted returns (bool success) {
        TKN.burnFrom(_sender,  _amount);
        emit Collect(_sender, _amount);
        return true;
    }

    function dispense(address _sender, uint256 _amount) public restricted returns (bool success) {
        TKN.mint(_sender, _amount);
        emit Dispense(_sender, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public restricted {
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    constructor(IERC20 _TKN) {
        TKN = _TKN;
        owner = msg.sender;
    }
}