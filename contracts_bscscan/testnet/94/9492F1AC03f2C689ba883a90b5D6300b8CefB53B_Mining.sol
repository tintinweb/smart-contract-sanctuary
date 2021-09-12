/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// Mining 质押挖矿合约;
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

    function safeMint(address token, address to, uint tokenId) internal {
        // bytes4(keccak256(bytes('mint(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x40c10f19, to, tokenId));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: MINT_FAILED');
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
    // NFT ERC721合约地址
    address public nftAddress;
    // USDT代币合约地址
    address public usdtAddress;
    // NFTS代币合约地址
    address public nftsAddress;
    // 接受代币的地址
    address public feeAddress;

    // 双重签名的messageHash是否已经使用, 全局唯一;
    mapping (bytes32 => bool) public signHash;
    // 全局的nonce值是否已经使用, 全局唯一;
    mapping (uint256 => bool) public nonceMapping;
    // orderId;
    mapping (uint256 => bool) public orderIdMapping;


    // 参数1: NFT ERC721合约地址
    // 参数1: USDT代币合约地址
    // 参数2: NFTS代币合约地址
    // 参数3: 接受代币的地址
    // 参数4: 二级管理员地址;
    constructor(address _nftAddress,address _usdtAddress, address _nftsAddress, address _feeAddress, address _secondOwner) public {
        nftAddress = _nftAddress;
        usdtAddress = _usdtAddress;
        nftsAddress = _nftsAddress;
        feeAddress = _feeAddress;
        secondOwner = _secondOwner;
    }

    // 申请矿池主;
    event ApplyMiner(address owner, uint256 value, uint256 nonce);
    // 质押;
    event Deposit(address owner, uint256 value, uint256 nonce);
    // 提取;
    event Withdraw(address owner, uint256 value, uint256 nonce);
    // 用户领取代币事件
    event UserRed(address owner, uint256 value, uint256 nonce);
    // 铸造事件;
    event Mint(address owner, uint256 tokenId, uint256 nftsValue, uint256 nonce);
    // 交易事件
    event Buy(address buyAddress, address sellerAddress, address tokenAddress, uint256 tokenValue, uint256 tokenId, uint256 nonce, uint256 orderId);

    // 成为矿池主; 用户转入usdt
    // 参数1: 转入的usdt数量
    // 参数2: nonce值
    function applyMiner(uint256 _value, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 函数名, 用户地址, token数量, 随机数;
        bytes32 hash = keccak256(abi.encodePacked("applyMiner", _owner, _value, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "Mining: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "Mining: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // nonce必须是没有使用的
        require(!nonceMapping[_nonce], "Mining: Nonce is used");
        // 设置为已使用
        nonceMapping[_nonce] = true;

        // 转USDT
        TransferHelper.safeTransferFrom(usdtAddress, _owner, feeAddress, _value);
        // 触发事件
        emit ApplyMiner(_owner, _value, _nonce);
    }

    // 用户质押代币;
    // 参数1: 存入USDT的数量
    // 参数2: nonce值
    // 参数3: 二次签名的signature
    function deposit(uint256 _value, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 函数名, 用户地址, usdt数量, 随机数;
        bytes32 hash = keccak256(abi.encodePacked("deposit", _owner, _value, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "Mining: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "Mining: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // nonce必须是没有使用的
        require(!nonceMapping[_nonce], "Mining: Nonce is used");
        // 设置为已使用
        nonceMapping[_nonce] = true;

        // 把币转给合约
        TransferHelper.safeTransferFrom(usdtAddress, _owner, address(this), _value);
        // 触发事件
        emit Deposit(_owner, _value, _nonce);
    }

    // 用户提取代币;
    // 参数1: 提取USDT的数量
    // 参数2: nonce值
    // 参数3: 二次签名的signature
    function withdraw(uint256 _value, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 函数名, 用户地址, usdt数量, 随机数;
        bytes32 hash = keccak256(abi.encodePacked("withdraw", _owner, _value, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "Mining: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "Mining: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // nonce必须是没有使用的
        require(!nonceMapping[_nonce], "Mining: Nonce is used");
        // 设置为已使用
        nonceMapping[_nonce] = true;

        // 把币转给用户
        TransferHelper.safeTransfer(usdtAddress, _owner, _value);
        // 触发事件
        emit Withdraw(_owner, _value, _nonce);
    }

    // 用户领取质押产生的的收益
    // 参数1: 领取NFTS的数量
    // 参数2: nonce值
    // 参数3: 二次签名的signature
    function userRed(uint256 _value, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 函数名, 用户地址, 领取的NFTS数量, 随机数;
        bytes32 hash = keccak256(abi.encodePacked("userRed", _owner, _value, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "Mining: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "Mining: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // nonce必须是没有使用的
        require(!nonceMapping[_nonce], "Mining: Nonce is used");
        // 设置为已使用
        nonceMapping[_nonce] = true;

        // 转给用户
        TransferHelper.safeTransfer(nftsAddress, _owner, _value);
        // 触发事件
        emit UserRed(_owner, _value, _nonce);
    }

    // 铸造tokenId; 消耗NFTS和USDT;
    // 参数1: token id; 确保唯一不重复;
    // 参数2: 消耗的NFTS数量;
    // 参数3: 消耗的USDT数量;
    // 参数4: nonce值;
    // 参数5: 二次签名的signature;
    function mint(uint256 _tokenId, uint256 _nftsValue, uint256 _usdtValue, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 函数名, 拥有者地址, tokenId, 消耗的NFTS数量, 消耗的USDT数量, 随机数;
        bytes32 hash = keccak256(abi.encodePacked("mint", _owner, _tokenId, _nftsValue, _usdtValue, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "Mining: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "Mining: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // nonce必须是没有使用的
        require(!nonceMapping[_nonce], "Mining: Nonce is used");
        // 设置为已使用
        nonceMapping[_nonce] = true;

        // 开始转账ERC20, nfts和usdt;
        TransferHelper.safeTransferFrom(nftsAddress, _owner, feeAddress, _nftsValue);
        TransferHelper.safeTransferFrom(usdtAddress, _owner, feeAddress, _usdtValue);
        // 开始铸造TokenId;
        TransferHelper.safeMint(nftAddress, _owner, _tokenId);
        // 触发铸造事件
        emit Mint(_owner, _tokenId, _nftsValue, _nonce);
    }

    // 市场购买tokenId
    // 参数1: 卖方地址;
    // 参数2: 购买消耗的代币地址;
    // 参数3: 购买消耗的代币数量;
    // 参数4: 交易的TokenId;
    // 参数5: nonce值;
    // 参数6: orderId; 防止一个tokenId被多次交易
    // 参数6: 二次签名的signature;
    function buy( address _sellerAddress, address _tokenAddress, uint256 _tokenValue, uint256 _tokenId, uint256 _nonce, uint256 _orderId, bytes calldata _signature) external {
        address _owner = msg.sender; // 买方地址
        // 验证的数据有: 函数名, 买方地址, 卖方地址, 消耗的代币地址, 消耗的代币数量, 交易的TokenId, 随机数, 订单号;
        bytes32 hash = keccak256(abi.encodePacked("buy", _owner, _sellerAddress, _tokenAddress, _tokenValue, _tokenId, _nonce, _orderId));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "Mining: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "Mining: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // nonce必须是没有使用的
        require(!nonceMapping[_nonce], "Mining: Nonce is used");
        // 设置为已使用
        nonceMapping[_nonce] = true;
        // orderid必须是没有使用的
        require(!orderIdMapping[_orderId], "Mining: Order id is used");
        // 设置为已使用
        orderIdMapping[_orderId] = true;

        // 买方和卖方不能是同一人;
        require(_owner != _sellerAddress, "Mining: Buy must and seller unlike");

        // 开始转账ERC20;
        TransferHelper.safeTransferFrom(_tokenAddress, _owner, feeAddress, _tokenValue);
        // 交易tokenId
        TransferHelper.safeTransferFrom(nftAddress, _sellerAddress, _owner, _tokenId);
        // 触发购买事件
        emit Buy(_owner, _sellerAddress, _tokenAddress, _tokenValue, _tokenId, _nonce, _orderId);
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

    // 设置收币的地址
    function updateFeeAddress(address _feeAddress) external onlySecondOwner {
        if (_feeAddress != address(0)) {
            feeAddress = _feeAddress;
        }
    }


}