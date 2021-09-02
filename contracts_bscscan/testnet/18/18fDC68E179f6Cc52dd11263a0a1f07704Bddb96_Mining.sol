/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// 质押挖矿合约, 代币和领取代币收益; BSC链;
pragma solidity ^0.5.16;


// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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
        // (bool success,) = to.call{value:value}(new bytes(0));
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Owner
contract Ownable {
    // 一级管理者
    address public owner;
    // 二级管理者
    address public secondOwner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Mining: You are not owner");
        _;
    }

    function updateOwner(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    modifier onlySecondOwner() {
        require(msg.sender == secondOwner, "Mining: You are not second owner");
        _;
    }

    function updateSecondOwner(address newSecondOwner) onlyOwner public {
        if (newSecondOwner != address(0)) {
            secondOwner = newSecondOwner;
        }
    }

}


// Mining
contract Mining is Ownable {
    using SafeMath for uint256;
    // 双重签名的messageHash是否已经使用, 全局唯一;
    mapping (bytes32 => bool) public signHash;
    // 全局的nonce值是否已经使用, 全局唯一;
    mapping (uint256 => bool) public nonceMapping;

    
    // 参数1: 二级管理员地址;
    constructor(address _secondOwner) public {
        secondOwner = _secondOwner;
    }

    // 质押;
    event Deposit(address owner, address token, uint256 value, uint256 nonce);
    // 提取;
    event Withdraw(address owner, address token, uint256 value, uint256 nonce);
    // 用户领取代币事件
    event UserRed(address owner, address token, uint256 value, uint256 nonce);


    // 用户质押代币;
    // 参数1: 代币的地址
    // 参数2: 存入代币的数量
    // 参数3: nonce值
    // 参数4: 二次签名的signature
    function deposit(address _tokenAddress, uint256 _tokenValue, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 用户地址, token地址, token数量, 随机数;
        bytes32 hash = keccak256(abi.encodePacked(_owner, _tokenAddress, _tokenValue, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "NFTToken: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "NFTToken: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // nonce必须是没有使用的
        require(!nonceMapping[_nonce], "NFTToken: Nonce is used");
        // 设置为已使用
        nonceMapping[_nonce] = true;

        // 把币转给合约
        TransferHelper.safeTransferFrom(_tokenAddress, _owner, address(this), _tokenValue);
        // 触发事件
        emit Deposit(_owner, _tokenAddress, _tokenValue, _nonce);
    }

    // 用户提取代币;
    // 参数1: 代币的地址
    // 参数2: 提取代币的数量
    // 参数3: nonce值
    // 参数4: 二次签名的signature
    function withdraw(address _tokenAddress, uint256 _tokenValue, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 用户地址, token地址, token数量, 随机数;
        bytes32 hash = keccak256(abi.encodePacked(_owner, _tokenAddress, _tokenValue, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "NFTToken: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "NFTToken: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // nonce必须是没有使用的
        require(!nonceMapping[_nonce], "NFTToken: Nonce is used");
        // 设置为已使用
        nonceMapping[_nonce] = true;

        // 把币转给用户
        TransferHelper.safeTransfer(_tokenAddress, _owner, _tokenValue);
        // 触发事件
        emit Withdraw(_owner, _tokenAddress, _tokenValue, _nonce);
    }

    // 用户领取质押产生的的收益
    // 参数1: 领取的币种地址
    // 参数2: 领取的数量
    // 参数3: nonce值
    // 参数4: 二次签名的signature
    function userRed(address _tokenAddress, uint256 _tokenValue, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 用户地址, 币种地址, 领取的数量, 随机数;
        bytes32 hash = keccak256(abi.encodePacked(_owner, _tokenAddress, _tokenValue, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "NFTToken: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "NFTToken: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // nonce必须是没有使用的
        require(!nonceMapping[_nonce], "NFTToken: Nonce is used");
        // 设置为已使用
        nonceMapping[_nonce] = true;

        // 转给用户
        TransferHelper.safeTransfer(_tokenAddress, _owner, _tokenValue);
        // 触发事件
        emit UserRed(_owner, _tokenAddress, _tokenValue, _nonce);
    }

    // 提取签名中的发起方地址
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    // 分离签名信息的 v r s
    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    // 二级管理员设置某个messageHash为已经使用, 备用;
    function setMessageHash(bytes32 _messageHash) external onlySecondOwner {
        if(!signHash[_messageHash]) {
            // 该messageHash设置为已使用
            signHash[_messageHash] = true;
        }
    }

    // 二级管理员设置某个nonce为已经使用, 备用;
    function setNonceMapping(uint256 _nonce) external onlySecondOwner {
        if(!nonceMapping[_nonce]) {
            // 该messageHash设置为已使用
            nonceMapping[_nonce] = true;
        }
    }


}