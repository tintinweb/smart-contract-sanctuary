/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Ahorro {
    address public owner;
    uint256 public lastUpdateTime;

    constructor() {
        owner = msg.sender;
    }

    event Retiro(uint256 _monto, uint256 _lastTime);

    modifier onlyOwner() {
        require(owner == msg.sender);
        lastUpdateTime = block.timestamp;
        _;
    }

    function transferir(address _token, uint256 _monto) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(owner, _monto);

        emit Retiro(_monto, lastUpdateTime);
    }

    function transferirBNB(uint256 _monto) external onlyOwner {
        require(_monto > address(this).balance, "Saldo BNB insuficiente");
        payable(msg.sender).transfer(_monto);

        emit Retiro(_monto, lastUpdateTime);
    }

    function depositar(uint256 amount) public payable {
        require(msg.value == amount);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}