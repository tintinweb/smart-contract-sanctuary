/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity ^0.5.16;


// Math operations with safety checks that throw on error
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "Math error");
        return a - b;
    }
}


// Abstract contract for the full ERC 20 Token standard
interface ERC20 {
    function balanceOf(address _address) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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


// Manage contract
contract BhxManage {
    // 管理员
    address public owner;
    // 管理员2; 用于双重签名验证
    address public owner2;
    // 签名的messageHash
    mapping (bytes32 => bool) public signHash;
    // bhx合约地址
    address public bhx;
    // usdt合约地址
    address public usdt;
    // 接受10%手续费的地址
    address public feeAddress;

    // 参数1: 二次签名的地址
    // 参数2: bhx代币合约地址
    // 参数3: usdt代币合约地址
    // 参数4: 接受手续费的地址
    constructor(address _owner2, address _bhx, address _usdt, address _feeAddress) public {
        owner = msg.sender;
        owner2 = _owner2;
        bhx = _bhx;
        usdt = _usdt;
        feeAddress = _feeAddress;
    }

    // 领取BHX触发事件
    event BhxRed(address indexed owner, uint256 value);
    // 领取USDT触发事件
    event UsdtRed(address indexed owner, uint256 value);

    // 管理员修饰符
    modifier onlyOwner() {
        require(owner == msg.sender, "BHXManage: You are not owner");
        _;
    }

    // 设置新的管理员
    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "BHXManage: Zero address error");
        owner = _owner;
    }

    // 设置新的管理员2
    function setOwner2(address _owner2) external onlyOwner {
        require(_owner2 != address(0), "BHXManage: Zero address error");
        owner2 = _owner2;
    }

    // 设置新的收币地址
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "BHXManage: Zero address error");
        feeAddress = _feeAddress;
    }

    // 管理员取出合约里的erc20代币
    function takeErc20(address _erc20Address) external onlyOwner {
        require(_erc20Address != address(0), "BHXManage: Zero address error");
        // 创建usdt的合约对象
        ERC20 erc20 = ERC20(_erc20Address);
        // 获取合约地址的余额
        uint256 _value = erc20.balanceOf(address(this));
        // 从合约地址转出usdt到to地址
        TransferHelper.safeTransfer(_erc20Address, msg.sender, _value);
    }

    // 管理员取出合约里的ETH
    function takeETH() external onlyOwner {
        uint256 _value = address(this).balance;
        TransferHelper.safeTransferETH(msg.sender, _value);
    }

    // 后台交易bhx; 使用二次签名进行验证, 从合约地址扣除bhx
    // 参数1: 交易的数量
    // 参数2: 用户需要支付gas费用的10%给到feeAddress;
    // 参数3: 唯一的值(使用随机的唯一数就可以)
    // 参数4: owner签名的signature值
    function backendTransferBhx(uint256 _value, uint256 _feeValue, uint256 _nonce, bytes memory _signature) public payable {
        address _to = msg.sender;
        require(_to != address(0), "BHXManage: Zero address error");
        // 创建bhx合约对象
        ERC20 bhxErc20 = ERC20(bhx);
        // 获取合约地址的bhx余额
        uint256 bhxBalance = bhxErc20.balanceOf(address(this));
        require(bhxBalance >= _value && _value > 0, "BHXManage: Insufficient balance or zero amount");
        // 验证得到的地址是不是owner2, 并且数据没有被修改;
        // 所使用的数据有: 接受币地址, 交易的数量, 10%的手续费, nonce值
        bytes32 hash = keccak256(abi.encodePacked(_to, _value, _feeValue, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == owner2, "BHXManage: Signer is not owner2");
        // 签名的messageHash必须是没有使用过的
        require(signHash[messageHash] == false, "BHXManage: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // 用户给的ETH必须等于签名时候使用的feeValue
        require(msg.value == _feeValue, "BHXManage: Value unequal fee value");

        // 从合约地址转出bhx到to地址
        TransferHelper.safeTransfer(bhx, _to, _value);
        // 把ETH给到fee地址
        TransferHelper.safeTransferETH(feeAddress, _feeValue);
        emit BhxRed(_to, _value);
    }

    // 抵押bhx借贷usdt; 使用二次签名进行验证, 从合约地址扣除usdt
    // 参数1: 交易的数量
    // 参数2: 用户需要支付gas费用的10%给到feeAddress;
    // 参数3: 唯一的值(使用随机的唯一数就可以)
    // 参数4: owner签名的signature值
    function backendTransferUsdt(uint256 _value, uint256 _feeValue, uint256 _nonce, bytes memory _signature) public payable {
        address _to = msg.sender;
        require(_to != address(0), "BHXManage: Zero address error");
        // 创建usdt的合约对象
        ERC20 usdtErc20 = ERC20(usdt);
        // 获取合约地址的usdt余额
        uint256 usdtBalance = usdtErc20.balanceOf(address(this));
        require(usdtBalance >= _value && _value > 0, "BHXManage: Insufficient balance or zero amount");
        // 验证得到的地址是不是owner2, 并且数据没有被修改;
        // 所使用的数据有: 接受币地址, 交易的数量, 10%的手续费, nonce值
        bytes32 hash = keccak256(abi.encodePacked(_to, _value, _feeValue, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == owner2, "BHXManage: Signer is not owner2");
        // 签名的messageHash必须是没有使用过的
        require(signHash[messageHash] == false, "BHXManage: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // 用户给的ETH必须等于签名时候使用的feeValue
        require(msg.value == _feeValue, "BHXManage: Value unequal fee value");

        // 从合约地址转出usdt到to地址
        TransferHelper.safeTransfer(usdt, _to, _value);
        // 把ETH给到fee地址
        TransferHelper.safeTransferETH(feeAddress, _feeValue);
        emit UsdtRed(_to, _value);
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

    function() payable external {}

}