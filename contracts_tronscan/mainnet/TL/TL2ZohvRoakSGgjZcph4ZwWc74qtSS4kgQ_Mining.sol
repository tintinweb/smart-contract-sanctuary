//SourceUnit: Mining.sol

// 挖矿合约
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

    /*function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }*/
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


// 挖矿合约
contract Mining is Ownable {
    using SafeMath for uint256;

    // 所有的池子
    address[] public pools;
    // 池子信息
    struct poolStruct {
        // 池子类型; 0=池子不存在,1=token池子,2=lp池子;
        uint256 typeOf;
        // 是否开启
        bool isOpen;
        // 名字
        string name;
        // 总质押数量
        uint256 totalDeposit;
        // 总提取数量
        uint256 totalWithdraw;
        // 总被提走的收益
        uint256 totalRed;
        // 玩家人数
        uint256 playerNumber;
    }
    // 池子地址=>池子详情
    mapping(address => poolStruct) public poolMapping;
    // 用户信息
    struct poolUserStruct {
        // 总投资数量
        uint256 amount;
        // 已领取的收益
        uint256 red;
        // 是否是玩家; 质押过就是玩家, 否则就不是;
        bool player;
    }
    // 池子地址=>用户地址=>用户信息
    mapping(address => mapping(address => poolUserStruct)) public poolUserMapping;
    // 是否是有效用户; 如果在合约里是有效用户的话, 后台就可以进行绑定上下级, 不是的话就不能;
    mapping(address => bool) public isUserMapping;
    // hnft(GDCV)合约地址
    address public hnftAddress;

    // 构造函数
    // 参数1: hnft(ETM)合约地址
    // 参数2: 二级管理者地址
    constructor(address _hnftAddress, address _secondOwner) public {
        hnftAddress = _hnftAddress;
        secondOwner = _secondOwner;
    }

    // 质押事件
    event Deposit(address pool, address owner, uint256 value);
    // 提取事件
    event Withdraw(address pool, address owner, uint256 value);
    // 用户提取收益事件
    event UserRed(address pool, address owner, uint256 value, address superAddress, uint256 superValue, address superSuperAddress, uint256 superSuperValue);

    // 添加token池子
    function addToken(address _tokenAddress, string calldata _name) external onlySecondOwner {
        require(_tokenAddress != address(0), "Mining: Zero address");
        // 这个地址是不存在的
        require(poolMapping[_tokenAddress].typeOf == 0, "Mining: Token pool exist");
        // 添加
        poolStruct memory _t = poolStruct(1, true, _name, 0, 0, 0, 0);
        poolMapping[_tokenAddress] = _t;
        pools.push(_tokenAddress);
    }

    // 添加lp池子
    function addLp(address _lpAddress, string calldata _name) external onlySecondOwner {
        require(_lpAddress != address(0), "Mining: Zero address");
        // 这个地址是不存在的
        require(poolMapping[_lpAddress].typeOf == 0, "Mining: Lp pool exist");
        // 添加
        poolStruct memory _t = poolStruct(2, true, _name, 0, 0, 0, 0);
        poolMapping[_lpAddress] = _t;
        pools.push(_lpAddress);
    }

    // 关闭或开启某个池子
    function openOrClosePool(address _poolAddress) external onlySecondOwner {
        // 这个地址必须是存在的
        require(poolMapping[_poolAddress].typeOf != 0, "Mining: pool not exist");
        poolMapping[_poolAddress].isOpen = !poolMapping[_poolAddress].isOpen;
    }

    // 修改池子的类型和名字; 预防管理员填写错了;
    function updatePoolTypeAndName(address _poolAddress, uint256 _type, string calldata _name) external onlySecondOwner {
        // 这个地址必须是存在的
        require(poolMapping[_poolAddress].typeOf != 0, "Mining: pool not exist");
        // pool类型只能是1或2
        require(_type == 1 || _type == 2, "Mining: type err");
        poolMapping[_poolAddress].typeOf = _type;
        poolMapping[_poolAddress].name = _name;
    }

    // 查询所有的池子
    function getPools() external view returns (address[] memory _r) {
        uint256 _length = pools.length;
        // 创建定长结构体数组对象
        _r = new address[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _r[i] = pools[i];
        }
    }

    // 用户质押
    // 参数1: 池子地址
    // 参数2: 质押的数量
    function deposit(address _poolAddress, uint256 _value) external {
        poolStruct storage p_ = poolMapping[_poolAddress];
        poolUserStruct storage u_ = poolUserMapping[_poolAddress][msg.sender];
        // 池子必须是存在的
        require(p_.typeOf != 0, "Mining: pool not exist");
        // 池子必须是开启
        require(p_.isOpen, "Mining: pool not open");
        // 开始转账; 需要用户先授权代币给本合约地址;
        TransferHelper.safeTransferFrom(_poolAddress, msg.sender, address(this), _value);

        // 质押过就是有效用户了
        if(!isUserMapping[msg.sender]) {
            isUserMapping[msg.sender] = true;
        }
        if(!u_.player) {
            // 如果是false的话, 就修改用户为是该池子的玩家, 并且该池子增加一个玩家;
            u_.player = true;
            p_.playerNumber++;
        }
        // 修改池子的信息
        p_.totalDeposit = p_.totalDeposit.add(_value);
        // 修改用户的信息
        u_.amount = u_.amount.add(_value);

        emit Deposit(_poolAddress, msg.sender, _value);
    }

    // 用户提现
    // 参数1: 池子地址
    // 参数2: 质押的数量
    function withdraw(address _poolAddress, uint256 _value) external {
        poolStruct storage p_ = poolMapping[_poolAddress];
        poolUserStruct storage u_ = poolUserMapping[_poolAddress][msg.sender];
        // 池子必须是存在的
        require(p_.typeOf != 0, "Mining: pool not exist");
        // 池子必须是开启
        require(p_.isOpen, "Mining: pool not open");
        // 用户必须是该池子的玩家
        require(u_.player, "Mining: pool not player");
        // 用户的充值金额必须大于等于提现金额
        require(u_.amount >= _value, "Mining: user amount insufficient");

        // 修改池子的信息
        p_.totalWithdraw = p_.totalWithdraw.add(_value);
        // 修改用户的信息
        u_.amount = u_.amount.sub(_value);

        // 开始转账;
        TransferHelper.safeTransfer(_poolAddress, msg.sender, _value);
        emit Withdraw(_poolAddress, msg.sender, _value);
    }

    // 双重签名的messageHash
    mapping (bytes32 => bool) public signHash;

    // 用户提取收益; 需要后台二次签名, 使用的是二级管理员私钥进行签名;
    // 参数1: 池子地址;
    // 参数2: 上级地址, 上上级地址;
    // 参数3: 用户数量, 上级数量, 上上级数量;
    // 参数4: nonce随机数(目前使用的是时间戳);
    // 参数5: 二次管理者签名的数据;
    function userRed(
        address _poolAddress,
        address _superAddress,
        address _superSuperAddress,
        uint256 _value,
        uint256 _superValue,
        uint256 _superSuperValue,
        uint256 _nonce,
        bytes calldata _signature) external {
        // 二次签名的验证; 验证得到的地址是不是secondOwner, 并且数据没有被修改;
        // 验证的数据有: 函数名, 池子地址, 用户地址, 上级地址, 上上级地址, 用户数量, 上级数量, 上上级数量, 随机数;
        // bytes32 hash = keccak256(abi.encodePacked(_poolAddress, msg.sender, _superAddress, _superSuperAddress, _value, _superValue, _superSuperValue, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked("userRed", _poolAddress, msg.sender, _superAddress, _superSuperAddress, _value, _superValue, _superSuperValue, _nonce))
            ));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "Mining: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "Mining: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;

        // 二次签名验证通过;
        poolStruct storage p_ = poolMapping[_poolAddress];
        // poolUserStruct storage u_ = poolUserMapping[_poolAddress][msg.sender];
        // 池子必须是存在的
        require(p_.typeOf != 0, "Mining: pool not exist");
        // 池子必须是开启
        require(p_.isOpen, "Mining: pool not open");
        // 用户必须是该池子的玩家
        require(poolUserMapping[_poolAddress][msg.sender].player, "Mining: pool not player");
        // 开始转账收益; 收益是hnft(GDCV)
        TransferHelper.safeTransfer(hnftAddress, msg.sender, _value);
        TransferHelper.safeTransfer(hnftAddress, _superAddress, _superValue);
        TransferHelper.safeTransfer(hnftAddress, _superSuperAddress, _superSuperValue);
        // 增加该池子被提取走的收益
        p_.totalRed = p_.totalRed.add(_value).add(_superValue).add(_superSuperValue);
        // 增加该池子用户的收益
        poolUserMapping[_poolAddress][msg.sender].red = poolUserMapping[_poolAddress][msg.sender].red.add(_value);

        // 触发事件
        emit UserRed(_poolAddress, msg.sender, _value, _superAddress, _superValue, _superSuperAddress, _superSuperValue);
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