/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract BridgeAssistant {
    address public owner;

    modifier restricted() {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }

    IERC20 public TKN;
    mapping(address => string) public targetOf;

    event SetTarget(address indexed sender, string indexed target);
    event Collect(address indexed sender, string indexed target, uint256 amount);
    event Dispense(address indexed sender, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function setTarget(string memory _account) public {
        targetOf[msg.sender] = _account;
        emit SetTarget(msg.sender, _account);
    }

    function collect(address _payer) public restricted returns (uint256 amount) {
        string memory _t = targetOf[_payer];
        require(bytes(_t).length > 0, "Target account not set");
        amount = TKN.allowance(_payer, address(this));
        require(amount > 0, "No amount approved");
        require(TKN.transferFrom(_payer, address(this), amount), "Transfer failure. Make sure that your balance is not lower than the allowance you set");
        emit Collect(_payer, _t, amount);
    }

    function dispense(address _target, uint256 _amount) public restricted returns (bool success) {
        require(TKN.transfer(_target, _amount), "Dispense failure. Contact contract owner");
        emit Dispense(_target, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0));
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    constructor(IERC20 _TKN, address _owner) {
        TKN = _TKN;
        owner = _owner;
    }
}