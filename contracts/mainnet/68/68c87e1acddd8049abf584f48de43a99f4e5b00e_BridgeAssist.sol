/**
 *Submitted for verification at Etherscan.io on 2021-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
    function burnFrom(address from, uint256 amount) external returns (bool);
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

    function collect(address _sender) public restricted returns (uint256 amount) {
        amount = TKN.allowance(_sender, address(this));
        require(amount > 0, "No amount approved");
        require(
            TKN.burnFrom(_sender, amount),
            "Transfer failure. Make sure that your balance is not lower than the allowance you set"
        );
        emit Collect(_sender, amount);
    }

    function dispense(address _sender, uint256 _amount) public restricted returns (bool success) {
        require(TKN.mint(_sender, _amount), "Dispense failure. Contact contract owner");
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