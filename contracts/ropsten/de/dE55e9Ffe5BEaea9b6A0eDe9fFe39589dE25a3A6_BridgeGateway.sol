// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Privilege.sol";

contract BridgeGateway is Privilege {
    mapping(string => SendStruct) public sendMap;

    struct SendStruct {
        address fromAddr;
        address toAddr;
        address token20Addr;
        uint256 fromAmount;
    }

    event ReceiveEvent(address indexed fromAddr, uint256 amount);
    event ExtractEvent(address indexed ownerAddr, address indexed token20Addr, uint256 amount);
    event SendEvent(string indexed txId,address indexed fromAddr,
                    address indexed toAddr,address token20Addr,uint256 fromAmount);

    receive() external payable {
        emit ReceiveEvent(msg.sender, msg.value);
    }

    function extractToken(uint256 amount) external onlyOwner() returns (bool){
        require(
            address(this).balance >= amount,
            "Insufficient BridgeGateway Balance"
        );
        payable(super.owner()).transfer(amount);
        emit ExtractEvent(owner(), address(0), amount);
        return true;
    }

    function extractToken20(address token20Addr, uint256 amount)
        external
        onlyOwner() returns (bool)
    {
        require(token20Addr != address(0), "token20Addr cannot be empty");
        require(
            IERC20(token20Addr).balanceOf(address(this)) >= amount,
            "Insufficient BridgeGateway Balance"
        );
        require(
            IERC20(token20Addr).transfer(owner(), amount),
            "extract failed"
        );
        emit ExtractEvent(owner(), token20Addr, amount);
        return true;
    }

    function sendToken(
        string memory txId,
        address fromAddr,
        address payable toAddr,
        uint256 fromAmount
    ) external onlyPrivilegeAccount() returns (bool){
        require(
            sendMap[txId].fromAddr == address(0),
            "The transaction has been transferred"
        );
        require(toAddr != address(0), "The toAddr cannot be empty");
        require(
            address(this).balance >= fromAmount,
            "Insufficient BridgeGateway Balance"
        );

        limitMoneyPrivilegeAccount(fromAmount);

        sendMap[txId] = SendStruct({
            fromAddr: fromAddr,
            toAddr: toAddr,
            token20Addr: address(0),
            fromAmount: fromAmount
        });

        toAddr.transfer(fromAmount);
        emit SendEvent(
            txId,
            fromAddr,
            toAddr,
            address(0),
            fromAmount
        );
        return true;
    }

    function sendToken20(
        string memory txId,
        address fromAddr,
        address toAddr,
        address token20Addr,
        uint256 fromAmount
    ) external onlyPrivilegeAccount() returns (bool){
        require(sendMap[txId].fromAddr == address(0), "txId is exis");
        require(toAddr != address(0), "The toAddr cannot be empty");
        require(token20Addr != address(0), "The token20Addr cannot be empty");

        require(
            IERC20(token20Addr).balanceOf(address(this)) >= fromAmount,
            "Insufficient BridgeGateway Balance"
        );

        sendMap[txId] = SendStruct({
            fromAddr: fromAddr,
            toAddr: toAddr,
            token20Addr: address(0),
            fromAmount: fromAmount
        });

        limitMoneyPrivilegeAccount(fromAmount);

        require(
            IERC20(token20Addr).transfer(toAddr, fromAmount),
            "Token20 transfer failed"
        );

        emit SendEvent(
            txId,
            fromAddr,
            toAddr,
            token20Addr,
            fromAmount
        );
        return true;
    }
}