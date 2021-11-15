/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract BridgeAssist {
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
        require(TKN.transferFrom(_sender, address(this), _amount), "transferFrom() failure. Make sure that your balance is not lower than the allowance you set");
        emit Collect(_sender, _amount);
        return true;
    }

    function dispense(address _sender, uint256 _amount) public restricted returns (bool success) {
        require(TKN.transfer(_sender, _amount), "transfer() failure. Contact contract owner");
        emit Dispense(_sender, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    function infoBundle(address user) public view returns (IERC20 token, uint256 all, uint256 bal, uint256 cBal) {
        token = TKN;
        all = TKN.allowance(user, address(this));
        bal = TKN.balanceOf(user);
        cBal = TKN.balanceOf(address(this));
    }

    constructor(IERC20 _TKN) {
        TKN = _TKN;
        owner = msg.sender;
    }
}