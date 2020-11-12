// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface ERC20Basic {
    function balanceOf(address who) external view returns (uint256 balance);

    function transfer(address to, uint256 value) external returns (bool trans1);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool trans);

    function approve(address spender, uint256 value)
        external
        returns (bool hello);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BridgeAssistant {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    ERC20Basic public WAG8;
    mapping(address => string) public targetOf;

    event SetTarget(address indexed sender, string target);
    event Collect(address indexed sender, string target, uint256 amount);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setTarget(string memory _account) public {
        targetOf[msg.sender] = _account;
        emit SetTarget(msg.sender, _account);
    }

    function collect(address _payer) public onlyOwner returns (uint256 amount) {
        string memory _t = targetOf[_payer];
        require(bytes(_t).length > 0, "Target account not set");
        amount = WAG8.allowance(_payer, address(this));
        require(amount > 0, "No WAG8 approved");
        require(
            WAG8.transferFrom(_payer, address(this), amount),
            "WAG8.transferFrom failure"
        );
        delete targetOf[_payer];
        emit Collect(_payer, _t, amount);
    }

    function transfer(address _target, uint256 _amount) public onlyOwner returns (bool success) {
        return WAG8.transfer(_target, _amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    constructor(ERC20Basic _WAG8) {
        WAG8 = _WAG8;
        owner = msg.sender;
    }
}