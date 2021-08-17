/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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
        require(TKN.allowance(_sender, address(this)) >= _amount, "Amount check failed");
        require(TKN.transferFrom(_sender, address(this), _amount), "transferFrom() failure. Make sure that your balance is not lower than the allowance you set");
        TKN.burn(_amount);
        emit Collect(_sender, _amount);
        return true;
    }

    function dispense(address payable _sender, uint256 _amount) public restricted returns (bool success) {
        TKN.mint(_sender, _amount);
        emit Dispense(_sender, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    constructor(IERC20 _TKN, address _owner) {
        TKN = _TKN;
        owner = _owner;
    }
}