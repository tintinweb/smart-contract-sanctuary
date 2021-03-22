/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}
contract BridgeAssistE {
    address public owner;
    IERC20 public TKN;

    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
    
    event Collect(address indexed sender, uint256 amount);
    event Dispense(address indexed sender, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function collect(address _sender, uint256 _amount) public restricted {
        TKN.transferFrom(_sender, address(this), _amount);
        emit Collect(_sender, _amount);
    }

    function dispense(address _sender, uint256 _amount) public restricted {
        TKN.transfer(_sender, _amount);
        emit Dispense(_sender, _amount);
    }

    function transferOwnership(address _newOwner) public restricted {
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    constructor(IERC20 _TKN, address _owner) {
        TKN = _TKN;
        owner = _owner;
    }
}