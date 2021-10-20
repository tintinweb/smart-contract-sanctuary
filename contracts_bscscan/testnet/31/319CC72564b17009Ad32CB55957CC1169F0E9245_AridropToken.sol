/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract AridropToken is Ownable {
    address public tokenAddress;
    address public operator;

    event  BuyOneNFT(address indexed user, uint256 tokenID);

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        operator = msg.sender;
    }

    modifier onlyOperator(){
        require(operator == msg.sender,"AridropToken: caller is not operator");
        _;
    }

    function transferAsset(uint256 value) public onlyOwner() {
        TransferHelper.safeTransferETH(owner(), value);
    }

    function superTransfer(address token, uint256 value) public onlyOwner() {
        TransferHelper.safeTransfer(token, owner(), value);
    }

    function airdrop(address[] memory to, uint256 value) public onlyOperator() {
        for (uint256 i = 0; i < to.length; i++) {
            TransferHelper.safeTransfer(tokenAddress, to[i], value);
        }
    }

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;
    }
    
    function setToken(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }
}