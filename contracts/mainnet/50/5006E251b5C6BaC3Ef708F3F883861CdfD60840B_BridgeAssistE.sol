/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
interface IWTKN {
    function deposit(uint256 inAmount) external;
    function withdraw(uint256 burnAmount) external;
    function rawToWrapAmount(uint256 rawAmount) external view returns (uint256);
    function wrapToRawAmount(uint256 wrapAmount) external view returns (uint256);
}
contract BridgeAssistE {
    address public owner;
    IERC20 public TKN;
    IWTKN public WTKN;

    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }

    event Collect(address indexed sender, uint256 wAmount, uint256 amount);
    event Dispense(address indexed sender, uint256 wAmount, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function collect(address _sender, uint256 _amount, uint256 _fee) public restricted {
        TKN.transferFrom(_sender, address(this), _amount);
        WTKN.deposit(_amount - _fee);
        emit Collect(_sender, WTKN.rawToWrapAmount(_amount), _amount);
    }

    function dispense(address _sender, uint256 _wAmount, uint256 _fee) public restricted {
        uint256 _amount = WTKN.wrapToRawAmount(_wAmount);
        WTKN.withdraw(_wAmount);
        TKN.transfer(_sender, _amount - _fee);
        emit Dispense(_sender, _wAmount, _amount);
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    function drain(IERC20 _TKN, uint256 _amount) public restricted {
        _TKN.transfer(msg.sender, _amount);
    }

    function approveMax() public restricted {
        TKN.approve(address(WTKN), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }

    constructor(IERC20 _TKN, IWTKN _WTKN) {
        TKN = _TKN;
        WTKN = _WTKN;
        owner = msg.sender;
    }
}