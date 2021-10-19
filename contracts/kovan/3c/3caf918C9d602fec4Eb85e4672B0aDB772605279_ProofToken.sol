/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ProofToken is Ownable {
    using SafeMath for uint256;

    address public immutable tokenContract;
    address public immutable usdtContract;
    address public receiver;
    uint256 public pricePerUSDT;
    uint256 public totalFOF;
    uint256 public soldFOF;

    constructor(address _tokenContract, address _usdtContract, address _receiver, uint256 _pricePerUSDT) {
        tokenContract = _tokenContract;
        usdtContract = _usdtContract;
        receiver = _receiver;
        pricePerUSDT = _pricePerUSDT;
    }

    function getProofToken(uint256 usdtAmount, address referrer) public {
        uint256 tokenAmount = usdtAmount.mul(pricePerUSDT).div(10**6);
        soldFOF = tokenAmount.add(tokenAmount);
        TransferHelper.safeTransfer(tokenContract, msg.sender, tokenAmount);
        if (receiver == referrer) {
            TransferHelper.safeTransferFrom(usdtContract, msg.sender, receiver, usdtAmount);
        } else {
            uint256 reward = usdtAmount.div(10);
            TransferHelper.safeTransferFrom(usdtContract, msg.sender, receiver, usdtAmount.sub(reward));
            TransferHelper.safeTransferFrom(usdtContract, msg.sender, referrer, reward);
        }
    }

    function addFOF(uint256 value) public {
        TransferHelper.safeTransferFrom(tokenContract, msg.sender, address(this), value);
    }

    function changeReceiver(address _receiver) public onlyOwner() {
        receiver = _receiver;
    }

    function changePrice(uint256 _pricePerUSDT) public onlyOwner() {
        pricePerUSDT = _pricePerUSDT;
    }

    function transferETH(uint256 value) public onlyOwner() {
        TransferHelper.safeTransferETH(receiver, value);
    }

    function transferAsset(address token, uint256 value) public onlyOwner() {
        TransferHelper.safeTransfer(token, receiver, value);
    }
}