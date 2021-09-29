//SourceUnit: Recycle.sol

// 回收合约
pragma solidity ^0.5.16;



// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
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
        require(msg.sender == owner, "Recycle: You are not owner");
        _;
    }

    function updateOwner(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    modifier onlySecondOwner() {
        require(msg.sender == secondOwner, "Recycle: You are not second owner");
        _;
    }

    function updateSecondOwner(address newSecondOwner) onlyOwner public {
        if (newSecondOwner != address(0)) {
            secondOwner = newSecondOwner;
        }
    }

}


// 回收合约
contract Recycle is Ownable {
    // 双重签名的messageHash
    mapping (bytes32 => bool) public signHash;
    // 充值订单的唯一值
    mapping (uint256 => bool) public orderIdMapping;
    // hnft(ETM)合约地址
    address public hnftAddress;
    // nft卡牌合约地址
    address public nftAddress;
    // 销毁的0地址
    address public zeroAddress = 0x0000000000000000000000000000000000000001;

    // 构造函数
    // 参数1: hnft(ETM)合约地址
    // 参数2: nft卡牌合约地址
    // 参数2: 二级管理者地址
    constructor(address _hnftAddress, address _nftAddress, address _secondOwner) public {
        hnftAddress = _hnftAddress;
        nftAddress = _nftAddress;
        secondOwner = _secondOwner;
    }

    // 质押事件
    event Deposit(uint256 orderId, uint256 time, uint256 typology, address owner, uint256 etmValue);
    // 提取事件
    event Withdraw(uint256 orderId, address owner, uint256 etmValue, uint256 nonce);
    // 用户领取挖矿收益事件
    event UserRed(address owner, uint256 etmValue, uint256 nonce);
    // 回收NFT事件
    event RecycleNft(address owner, uint256 nftId, uint256 etmValue, uint256 nonce);

    // 用户质押
    // 参数1: 订单号, 要求唯一;
    // 参数2: 类型; 只能是30或60或90;
    // 参数3: 存入的ETM数量;
    function deposit(uint256 _orderId, uint256 _type, uint256 _etmValue) external {
        // orderId必须是没有使用过的
        require(orderIdMapping[_orderId] == false, "Recycle: Order id is exist");
        require(_type == 30 || _type == 60 || _type == 90, "Recycle: Type not");
        require(_etmValue > 0, "Recycle: ETM value not zero");

        orderIdMapping[_orderId] = true;
        // 开始转账销毁
        TransferHelper.safeTransferFrom(hnftAddress, msg.sender, zeroAddress, _etmValue);
        // 触发事件
        emit Deposit(_orderId, block.timestamp, _type, msg.sender, _etmValue);
    }

    // 用户提取和收益一起; 需要后台二次签名, 使用的是二级管理员私钥进行签名;
    // 参数1: 提取的订单号;
    // 参数2: 提取的ETM数量;
    // 参数3: nonce值;
    // 参数4: 二次签名的数据;
    function withdraw(uint256 _orderId, uint256 _etmValue, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 函数名, 订单号, 用户地址, 提取的ETM数量, 随机数;
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked("withdraw", _orderId, _owner, _etmValue, _nonce))
            ));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "Recycle: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "Recycle: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;

        // 开始转账
        TransferHelper.safeTransfer(hnftAddress, _owner, _etmValue);
        // 触发事件
        emit Withdraw(_orderId, _owner, _etmValue, _nonce);
    }

    // 用户领取ETM挖矿收益
    // 参数1: 领取的ETM数量
    // 参数2: nonce值;
    // 参数3: 二次签名的数据;
    function userRed(uint256 _etmValue, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 函数名, 用户地址, 挖矿的ETM数量, 随机数;
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked("userRed", _owner, _etmValue, _nonce))
            ));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "Recycle: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "Recycle: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;

        // 开始转账
        TransferHelper.safeTransfer(hnftAddress, _owner, _etmValue);
        // 触发事件
        emit UserRed(_owner, _etmValue, _nonce);
    }

    // 回收NFT卡牌, 然后付给用户一定数量的ETM代币
    // 参数1: NFT卡牌的id
    // 参数2: 获得的ETM代币数量
    // 参数3: nonce值;
    // 参数4: 二次签名的数据;
    function recycleNft(uint256 _nftId, uint256 _etmValue, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 函数名, nft卡牌id, 用户地址, 提取的ETM数量, 随机数;
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked("recycle", _nftId, _owner, _etmValue, _nonce))
            ));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "Recycle: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "Recycle: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;

        // 开始销毁NFT卡牌; 需要用户授权这个nft卡牌给到本合约;
        TransferHelper.safeTransferFrom(nftAddress, _owner, zeroAddress, _nftId);
        // 转给用户ETM
        TransferHelper.safeTransfer(hnftAddress, _owner, _etmValue);
        // 触发回收事件
        emit RecycleNft(owner, _nftId, _etmValue, _nonce);
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


}