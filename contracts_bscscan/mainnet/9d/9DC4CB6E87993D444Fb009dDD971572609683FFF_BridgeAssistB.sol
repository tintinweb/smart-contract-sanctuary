/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
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
        require(TKN.allowance(_sender, address(this)) >= _amount, "Amount check failed");
        require(TKN.burnFrom(_sender,  _amount), "burnFrom() failure. Make sure that your balance is not lower than the allowance you set");
        emit Collect(_sender, _amount);
        return true;
    }

    function dispense(address _sender, uint256 _amount) public restricted returns (bool success) {
        require(TKN.mint(_sender, _amount), "mint() failure. Contact contract owner");
        emit Dispense(_sender, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    constructor(IERC20 _TKN) {
        TKN = _TKN;
        owner = msg.sender;
    }
}