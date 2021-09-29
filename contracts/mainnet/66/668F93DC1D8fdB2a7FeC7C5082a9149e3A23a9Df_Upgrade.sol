/**
 *Submitted for verification at Etherscan.io on 2021-09-29
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


// Upgrade contract
contract Upgrade {
    // 管理员
    address public owner;
    // 管理员2; 用于双重签名验证
    address public owner2;
    // 签名的messageHash
    mapping (bytes32 => bool) public signHash;
    // bhc合约地址
    address public bhc;
    // 接受10%手续费的地址
    address public feeAddress;

    // 参数1: 二次签名的地址
    // 参数2: bhc代币合约地址
    // 参数4: 接受手续费的地址
    constructor(address _owner2, address _bhc, address _feeAddress) public {
        owner = msg.sender;
        owner2 = _owner2;
        bhc = _bhc;
        feeAddress = _feeAddress;
    }

    // 燃烧BHC升级事件
    event BurnBhc(address indexed owner, uint256 bhcvalue, uint256 ethValue);

    // 管理员修饰符
    modifier onlyOwner() {
        require(owner == msg.sender, "Upgrade: You are not owner");
        _;
    }

    // 设置新的管理员
    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "Upgrade: Zero address error");
        owner = _owner;
    }

    // 设置新的管理员2
    function setOwner2(address _owner2) external onlyOwner {
        require(_owner2 != address(0), "Upgrade: Zero address error");
        owner2 = _owner2;
    }

    // 设置新的收币地址
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "Upgrade: Zero address error");
        feeAddress = _feeAddress;
    }

    // 管理员取出合约里的erc20代币
    function takeErc20(address _erc20Address) external onlyOwner {
        require(_erc20Address != address(0), "Upgrade: Zero address error");
        // 创建usdt的合约对象
        ERC20 erc20 = ERC20(_erc20Address);
        // 获取合约地址的余额
        uint256 _value = erc20.balanceOf(address(this));
        // 从合约地址转出token到to地址
        TransferHelper.safeTransfer(_erc20Address, msg.sender, _value);
    }

    // 管理员取出合约里的ETH
    function takeETH() external onlyOwner {
        uint256 _value = address(this).balance;
        TransferHelper.safeTransferETH(msg.sender, _value);
    }

    // 燃烧BHC升级事件; 使用二次签名进行验证;
    // 参数1: 消耗的BHC数量
    // 参数2: 用户需要支付gas费用的10%给到feeAddress;
    // 参数3: 唯一的值(使用随机的唯一数就可以)
    // 参数4: owner签名的signature值
    function burnBhc(uint256 _bhcValue, uint256 _feeValue, uint256 _nonce, bytes memory _signature) public payable {
        address _owner = msg.sender;

        // 所使用的数据有: 函数名, 用户的地址, 消耗bhc数量, 10%的手续费, nonce值;
        bytes32 hash = keccak256(abi.encodePacked("burnBhc", _owner, _bhcValue, _feeValue, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == owner2, "Upgrade: Signer is not owner2");
        // 签名的messageHash必须是没有使用过的
        require(signHash[messageHash] == false, "Upgrade: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // 用户给的ETH必须等于签名时候使用的feeValue
        require(msg.value == _feeValue, "Upgrade: Value unequal fee value");

        // 消耗用户的BHC的给收币地址
        TransferHelper.safeTransferFrom(bhc, _owner, feeAddress, _bhcValue);
        // 把ETH给到fee地址
        TransferHelper.safeTransferETH(feeAddress, _feeValue);
        // 触发事件
        emit BurnBhc(_owner, _bhcValue, _feeValue);
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