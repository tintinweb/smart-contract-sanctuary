// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVRC20.sol";
import "./Privilege.sol";
import "./SafeERC20.sol";

contract BridgeGateway is Privilege {
    using SafeERC20 for IVRC20;

    mapping(string => SendStruct) public sendMap;

    struct SendStruct {
        address fromAddr;
        address toAddr;
        address token20Addr;
        uint256 fromAmount;
    }

    event ReceiveEvent(address indexed fromAddr, uint256 amount,address indexed toAddr,address indexed tokenAddress,string chainName);
    event ExtractEvent(address indexed ownerAddr, address indexed token20Addr, uint256 amount);
    event SendEvent(string indexed txId,address indexed fromAddr,
                    address indexed toAddr,address token20Addr,uint256 fromAmount);

    function receiveNativeToken(address toAddr,string memory chainName) external payable returns(bool){
        emit ReceiveEvent(msg.sender,msg.value,toAddr,address(0),chainName);
        return true;
    }

    function receiveToken20(address toAddr,uint256 amount,address token20Address,string memory chainName) external returns(bool){
        IVRC20(token20Address).safeTransferFrom(msg.sender, address(this), amount);
        emit ReceiveEvent(msg.sender, amount,toAddr,token20Address,chainName);
        return true;
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
            IVRC20(token20Addr).balanceOf(address(this)) >= amount,
            "Insufficient BridgeGateway Balance"
        );
        require(
            IVRC20(token20Addr).transfer(owner(), amount),
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
            IVRC20(token20Addr).balanceOf(address(this)) >= fromAmount,
            "Insufficient BridgeGateway Balance"
        );

        sendMap[txId] = SendStruct({
            fromAddr: fromAddr,
            toAddr: toAddr,
            token20Addr: address(0),
            fromAmount: fromAmount
        });

        limitMoneyPrivilegeAccount(fromAmount);

        IVRC20(token20Addr).safeTransfer(toAddr, fromAmount);

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