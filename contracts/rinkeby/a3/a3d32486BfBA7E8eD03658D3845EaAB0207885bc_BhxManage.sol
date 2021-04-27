/**
 *Submitted for verification at Etherscan.io on 2021-04-27
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
contract ERC20 {

    function balanceOf(address _address) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

// Manage contract
contract BhxManage is ERC20 {

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
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );

    // owner2: 0xEd90A957557941C61Ad8c730d7f958bB6f7C668c
    // bhx:
    // usdt: 0x70cCc035A942F58D5c532cFf22d7e3D2C1db17Df
    constructor(address _owner2, address _bhx, address _usdt) public {
        owner = msg.sender;
        owner2 = _owner2;
        bhx = _bhx;
        usdt = _usdt;
    }
    
    function balanceOf(address _address) public view returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) public returns (bool success) {}
    function approve(address _spender, uint256 _amount) public returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}
    

    // 管理员修饰符
    modifier onlyOwner() {
        require(owner == msg.sender, "You are not owner");
        _;
    }

    // 设置新的管理员
    function setOwner(address _owner) public onlyOwner returns (bool success) {
        require(_owner != address(0), "Zero address error");
        owner = _owner;
        success = true;
    }

    // 设置新的管理员2
    function setOwner2(address _owner2) public onlyOwner returns (bool success) {
        require(_owner2 != address(0), "Zero address error");
        owner2 = _owner2;
        success = true;
    }

    // 管理员取出合约里的erc20代币
    function takeErc20(address _erc20Address) public onlyOwner returns (bool success2) {
        require(_erc20Address != address(0), "Zero address error");
        // 创建usdt的合约对象
        ERC20 erc20 = ERC20(_erc20Address);
        // 获取合约地址的余额
        uint256 _value = erc20.balanceOf(address(this));
        // 从合约地址转出usdt到to地址
        (bool success, ) = address(_erc20Address).call(
            abi.encodeWithSelector(TRANSFER, msg.sender, _value)
        );
        if(!success) {
            revert("Transfer is fail");
        }
        success2 = true;
    }

    // 后台交易bhx; 使用二次签名进行验证, 从合约地址扣除bhx
    // 参数1: 接受方地址
    // 参数2: 交易的数量
    // 参数3: 唯一的值(使用随机的唯一数就可以)
    // 参数4: owner签名的signature值
    function backendTransferBhx(address _to, uint256 _value, uint256 _nonce, bytes memory _signature) public returns (bool success2) {
        require(_to != address(0), "Zero address error");
        // 创建bhx合约对象
        ERC20 bhxErc20 = ERC20(bhx);
        // 获取合约地址的bhx余额
        uint256 bhxBalance = bhxErc20.balanceOf(address(this));
        require(bhxBalance >= _value && _value > 0, "Insufficient balance or zero amount");
        // 验证得到的地址是不是owner2, 并且数据没有被修改;
        // 所使用的数据有: 发送方地址, 接受方地址, 交易的数量
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _to, _value, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == owner2, "Signer is not owner2");
        // 签名的messageHash必须是没有使用过的
        require(signHash[messageHash] == false, "MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;

        // 从合约地址转出bhx到to地址
        (bool success, ) = address(bhx).call(
            abi.encodeWithSelector(TRANSFER, _to, _value)
        );
        if(!success) {
            revert("Transfer is fail");
        }
        success2 = true;
    }

    // 抵押bhx借贷usdt; 使用二次签名进行验证, 从合约地址扣除usdt
    // 参数1: 接受方地址
    // 参数2: 交易的数量
    // 参数3: 唯一的值(使用随机的唯一数就可以)
    // 参数4: owner签名的signature值
    function backendTransferUsdt(address _to, uint256 _value, uint256 _nonce, bytes memory _signature) public returns (bool success2) {
        require(_to != address(0), "Zero address error");
        // 创建usdt的合约对象
        ERC20 usdtErc20 = ERC20(usdt);
        // 获取合约地址的usdt余额
        uint256 usdtBalance = usdtErc20.balanceOf(address(this));
        // 判断合约地址的usdt余额是否足够
        require(usdtBalance >= _value && _value > 0, "Insufficient balance or zero amount");
        // 验证得到的地址是不是owner2, 并且数据没有被修改;
        // 所使用的数据有: 发送方地址, 接受方地址, 交易的数量
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _to, _value, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == owner2, "Signer is not owner2");
        // 签名的messageHash必须是没有使用过的
        require(signHash[messageHash] == false, "MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;

        // 从合约地址转出usdt到to地址
        (bool success, ) = address(usdt).call(
            abi.encodeWithSelector(TRANSFER, _to, _value)
        );
        if(!success) {
            revert("Transfer is fail");
        }
        success2 = true;
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