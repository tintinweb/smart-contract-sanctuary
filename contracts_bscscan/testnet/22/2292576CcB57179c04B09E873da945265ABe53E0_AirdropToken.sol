/**
 *Submitted for verification at BscScan.com on 2021-11-12
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

contract AirdropToken is Ownable {
    address public immutable tokenAddress;
    mapping(address => bool) public operators;
    uint256 public deadline = 1640995200;
    address public constant burnAddress = address(0x0000000000000000000000000000000000000001);

    mapping(address => bool) public firstLevel;
    mapping(address => bool) public secondLevel;
    mapping(address => bool) public thirdLevel;
    mapping(address => bool) public fourthLevel;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        operators[msg.sender] = true;
    }

    modifier onlyOperator(){
        require(operators[msg.sender], "AirdropToken: caller is not operator");
        _;
    }

    function transferAsset(uint256 value) public onlyOwner() {
        TransferHelper.safeTransferETH(owner(), value);
    }

    function tokenTransfer(address token, uint256 value) public onlyOwner() {
        TransferHelper.safeTransfer(token, owner(), value);
    }

    function burnToken(uint256 value) public onlyOwner() {
        TransferHelper.safeTransfer(tokenAddress, burnAddress, value);
    }

    function firstLevelAirdrop(address[] memory to) public onlyOperator() {
        require(block.timestamp < deadline, "AirdropToken: deadline is up");
        uint256 value = 10**15;
        for (uint256 i = 0; i < to.length; i++) {
            require(!firstLevel[to[i]], "AirdropToken: user has been firstLevel airdropped");
            TransferHelper.safeTransfer(tokenAddress, to[i], value);
            firstLevel[to[i]] = true;
        }
    }

    function secondLevelAirdrop(address[] memory to) public onlyOperator() {
        require(block.timestamp < deadline, "AirdropToken: deadline is up");
        uint256 value = 10**16;
        for (uint256 i = 0; i < to.length; i++) {
            require(!secondLevel[to[i]], "AirdropToken: user has been secondLevel airdropped");
            TransferHelper.safeTransfer(tokenAddress, to[i], value);
            secondLevel[to[i]] = true;
        }
    }

    function thirdLevelAirdrop(address[] memory to) public onlyOperator() {
        require(block.timestamp < deadline, "AirdropToken: deadline is up");
        uint256 value = 10**17;
        for (uint256 i = 0; i < to.length; i++) {
            require(!thirdLevel[to[i]], "AirdropToken: user has been thirdLevel airdropped");
            TransferHelper.safeTransfer(tokenAddress, to[i], value);
            thirdLevel[to[i]] = true;
        }
    }

    function fourthLevelAirdrop(address[] memory to) public onlyOperator() {
        require(block.timestamp < deadline, "AirdropToken: deadline is up");
        uint256 value = 10**18;
        for (uint256 i = 0; i < to.length; i++) {
            require(!fourthLevel[to[i]], "AirdropToken: user has been fourthLevel airdropped");
            TransferHelper.safeTransfer(tokenAddress, to[i], value);
            fourthLevel[to[i]] = true;
        }
    }

    function setOperator(address _operator) public onlyOwner {
        operators[_operator] = true;
    }

    function setDeadline(uint256 _deadline) public onlyOwner {
        require(_deadline < deadline, "AirdropToken: deadline set error");
        deadline = _deadline;
    }
}