/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Math error");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a / b;
        return c;
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


// Mining contract
contract Mining {
    using SafeMath for uint256;

    // 100%的分配
    struct detail {
        // 可领取的总量
        uint256 all;
        // 已领取的数量
        uint256 take;
    }
    // 0=全部的总量(1,2,3加一起), 1=存款, 2=矿税, 3=矿池主分红, 4=分给用户的200万, 5=矿池主锁仓的分红共9万9千, 后续可能会增加
    mapping(uint256 => detail) public totals;
    // N个参与用户分红的地址和对应的数量
    struct detail2 {
        // 可领取的总量
        uint256 all;
        // 已领取的数量
        uint256 take;
        // 默认的区块高度
        uint256 block;
    }
    mapping(address => detail2) public userDetail;
    // 保存所有参与分红的用户
    address[] public userList;
    // 用户领取的记录
    struct user {
        // 领取的区块高度
        uint256 block;
        // 领取的时间
        uint256 time;
        // 领取的数量
        uint256 value;
    }
    mapping(address => user[]) public userRecord;

    // 成为矿池主的白名单地址
    mapping(address => bool) public whiteListFlag;
    address[] public whiteList;
    struct detail3 {
        // 是不是矿池主
        bool flag;
        // 可领取的总量
        uint256 all;
        // 已领取的数量
        uint256 take;
        // 默认的区块高度
        uint256 block;
    }
    mapping(address => detail3) public minerDetail;
    address[] public minerList;
    // 矿池主锁仓分红领取的记录
    mapping(address => user[]) public minerRecord;
    // 双重签名的messageHash
    mapping (bytes32 => bool) public signHash;
    // 管理员地址
    address public owner;
    // 接收币的地址; 项目方地址
    address public leaderAddress;
    // 开始的区块高度
    uint256 public startBlock;
    // usdt代币合约地址
    address public usdtAddress;
    // NtfI代币合约地址
    address public ntfiAddress;
    // 后台操作地址
    address public operationAddress;
    // 矿税提取的地址
    address public taxMineAddress;
    // 每个区块领取0.2枚
    uint256 public blockTow = 2 * 10**17;
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    bytes4 private constant TRANSFERFROM = bytes4(
        keccak256(bytes("transferFrom(address,address,uint256)"))
    );

    // 提取1,2,3,4,5的触发事件;
    event Fetch(uint256 indexed _type, address indexed _to, uint256 _value);
    // 成为矿池主的触发事件
    event BeMiner(address indexed _address, address indexed _tokenAddress, uint256 _value);

    // 参数1: 分配的总量; 1,2,3;
    // 参数2: usdt代币的合约地址
    // 参数3: ntfi代币的合约地址
    // 参数4: 后台操作者的地址
    // 参数5: 矿税提取者地址
    // 参数6: 收币的地址
    constructor(uint256 _allTotalNumber, address _usdtAddress, address _ntfiAddress, address _operationAddress, address _taxMineAddress, address _leaderAddress) public {
        owner = msg.sender;
        startBlock = block.number;
        usdtAddress = _usdtAddress;
        ntfiAddress = _ntfiAddress;
        operationAddress = _operationAddress;
        taxMineAddress = _taxMineAddress;
        leaderAddress = _leaderAddress;

        totals[0] = detail(_allTotalNumber, 0);
        totals[1] = detail(_allTotalNumber.mul(88).div(100), 0);
        totals[2] = detail(_allTotalNumber.mul(7).div(100), 0);
        totals[3] = detail(_allTotalNumber.mul(5).div(100), 0);
        totals[4] = detail(2000000 * 10**18, 0);
        totals[5] = detail(99000 * 10**18, 0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    modifier onlyOperation {
        require(msg.sender == operationAddress, "You are not operation");
        _;
    }

    // 修改新的管理员
    function setOwner(address _owner) public onlyOwner returns (bool success) {
        require(_owner != address(0), "Zero address");
        owner = _owner;
        success = true;
    }

    // 修改新的后台操作地址
    function setOperationAddress(address _operationAddress) public onlyOwner returns (bool success) {
        require(_operationAddress != address(0), "Zero address");
        operationAddress = _operationAddress;
        success = true;
    }

    // 修改新的矿税提取地址
    function setTaxMineAddress(address _taxMineAddress) public onlyOwner returns (bool success) {
        require(_taxMineAddress != address(0), "Zero address");
        taxMineAddress = _taxMineAddress;
        success = true;
    }

    // 修改新的收币地址
    function setLeaderAddress(address _leaderAddress) public onlyOwner returns (bool success) {
        require(_leaderAddress != address(0), "Zero address");
        leaderAddress = _leaderAddress;
        success = true;
    }

    // 增加分红的用户地址; 每个地址对应的数量不一样
    // 参数1: 地址数组
    // 参数2: 金额数组
    function addUserDetail(address[] memory _address, uint256[] memory _value) public onlyOperation returns (bool success) {
        require(_address.length == _value.length, "The quantity is different");
        for(uint256 i = 0; i < _address.length; i++) {
            userList.push(_address[i]);
            // 地址必须是不存在的
            require(userDetail[_address[i]].all == 0, "The address already exists");
            userDetail[_address[i]] = detail2(_value[i], 0, block.number);
        }
        success = true;
    }

    // 查询用户分红的全部可领金额和已领取金额
    function getUserDetail(address _address) public view returns (detail2 memory r) {
        r = userDetail[_address];
    }

    // 查询全部的分红用户地址
    function getUserList() public view returns (address[] memory r) {
        uint256 a = userList.length;
        r = new address[](a);
        for(uint256 i = 0; i < a; i++) {
            r[i] = userList[i];
        }
    }

    // 查询分红用户地址的长度
    function getUserListLength() public view returns (uint256 r) {
        r = userList.length;
    }

    // 根据索引区间查询分红用户地址; 预防地址过多,可分多次查询, 包括_start,不包括_end
    function getUserListIndex(uint256 _start, uint256 _end) public view returns (address[] memory r) {
        uint256 a = _end.sub(_start);
        r = new address[](a);
        for(uint256 i = 0; i < a; i++) {
            r[i] = userList[_start.add(i)];
        }
    }

    // 添加白名单地址
    function addWhiteList(address[] memory _whiteList) public onlyOperation returns (bool success) {
        for(uint256 i = 0; i < _whiteList.length; i++) {
            // 增加到全部的白名单数组里
            whiteList.push(_whiteList[i]);
            // 白名单地址不能是已经存在的
            require(whiteListFlag[_whiteList[i]] == false, "Address is exists");
            // 设置为白名单
            whiteListFlag[_whiteList[i]] = true;
        }
        success = true;
    }

    // 查询全部的白名单地址
    function getWhiteList() public view returns (address[] memory r) {
        uint256 a = whiteList.length;
        r = new address[](a);
        for(uint256 i = 0; i < a; i++) {
            r[i] = whiteList[i];
        }
    }

    // 查询白名单的长度
    function getWhiteListLength() public view returns (uint256 r) {
        r = whiteList.length;
    }

    // 根据索引区间查询白名单地址; 预防地址过多,可分多次查询, 包括_start,不包括_end
    function getWhiteListIndex(uint256 _start, uint256 _end) public view returns (address[] memory r) {
        uint256 a = _end.sub(_start);
        r = new address[](a);
        for(uint256 i = 0; i < a; i++) {
            r[i] = whiteList[_start.add(i)];
        }
    }

    // 增加矿池主锁仓分红; 也就是考虑后续会增加矿池主
    function addMinerRed(uint256 _value) public onlyOperation returns (bool success) {
        totals[5].all = totals[5].all.add(_value);
        success = true;
    }

    // 成为矿池主
    // 参数1: 需要支付的币种;
    // 参数2: 需要支付的数量(数量由后台计算决定);
    // 参数3: nonce值(唯一性);
    // 参数4: 二次签名的数据;
    function makeMiner(address _tokenAddress, uint256 _value, uint256 _nonce, bytes memory _signature) public returns (bool success) {
        // 判断是不是矿池主;
        require(minerDetail[msg.sender].flag == false, "You are already miner");
        // token只能是usdt或ntfi
        require(_tokenAddress == usdtAddress || _tokenAddress == ntfiAddress, "The token address not exists");
        // 如果是白名单的话可以支付任意币种, 否则只能支付usdt;
        if(whiteListFlag[msg.sender]) {
            // 是白名单
            (bool success1, ) = _tokenAddress.call(
                abi.encodeWithSelector(TRANSFERFROM, msg.sender, leaderAddress, _value)
            );
            if(!success1) {
                revert("transfer fail");
            }
        }else {
            // 不是白名单
            require(_tokenAddress == usdtAddress, "The token address error");
            (bool success2, ) = _tokenAddress.call(
                abi.encodeWithSelector(TRANSFERFROM, msg.sender, leaderAddress, _value)
            );
            if(!success2) {
                revert("transfer fail");
            }
        }

        // 二次签名的验证; 预防用户直接调用合约转入过少的金额, 在合约里面变成了矿池主, 而在后台他并没有成为矿池主
        // 验证得到的地址是不是owner2, 并且数据没有被修改;
        // 验证的数据有: 发送方地址, 币种地址, 金额, 随机数
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _tokenAddress, _value, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == operationAddress, "Signer is not operation");
        // 签名的messageHash必须是没有使用过的
        require(signHash[messageHash] == false, "MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;

        // 添加矿池主数组
        minerList.push(msg.sender);
        minerDetail[msg.sender] = detail3(true, 1000 * 10**18, 0, block.number);
        emit BeMiner(msg.sender, _tokenAddress, _value);
        success = true;
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

    // 矿池主查询自己的可领取和未领取信息
    function getMinerDetail(address _address) public view returns (detail3 memory r) {
        r = minerDetail[_address];
    }

    // 查询全部的矿池主地址
    function getMinerList() public view returns (address[] memory r) {
        uint256 a = minerList.length;
        r = new address[](a);
        for(uint256 i = 0; i < a; i++) {
            r[i] = minerList[i];
        }
    }

    // 查询矿池主地址的长度
    function getMinerListLength() public view returns (uint256 r) {
        r = minerList.length;
    }

    // 根据索引区间查询矿池主地址; 预防地址过多,可分多次查询, 包括_start,不包括_end
    function getMinerListIndex(uint256 _start, uint256 _end) public view returns (address[] memory r) {
        uint256 a = _end.sub(_start);
        r = new address[](a);
        for(uint256 i = 0; i < a; i++) {
            r[i] = minerList[_start.add(i)];
        }
    }

    // 后台提取; 1, 3;
    // 参数1: 提取的类型; 1=存款, 3=矿池主分红
    // 参数2: 接收方地址
    // 参数3: 提取的NTFI数量
    function bgFetch(uint256 _type, address _to, uint256 _value, uint256 _nonce, bytes memory _signature) public returns (bool success) {
        require(_type == 1 || _type == 3, "Type error");
        // 二次签名的验证;
        // 验证得到的地址是不是owner2, 并且数据没有被修改;
        // 验证的数据有: 发送方地址, 币种地址, 金额, 随机数
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _type, _to, _value, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == operationAddress, "Signer is not operation");
        // 签名的messageHash必须是没有使用过的
        require(signHash[messageHash] == false, "MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;

        // 判断余额是否足够
        uint256 enough0 = totals[0].all - totals[0].take;
        uint256 enough1To5 = totals[_type].all - totals[_type].take;
        require(enough0 >= _value && enough1To5 >= _value, "Balance insufficient");
        // 1, 2, 3需要考虑区块高度和区块数递减;
        // 最多可以领取的数量
        uint256 canNumber = countFetch(_type);
        // 判断是否可以领取这么多
        require(canNumber - totals[_type].take >= _value, "Balance insufficient in 1 2 3");

        // 增加已领取数量
        totals[_type].take = totals[_type].take.add(_value);
        totals[0].take = totals[0].take.add(_value);
        // 开始转账
        (bool success1, ) = ntfiAddress.call(
            abi.encodeWithSelector(TRANSFER, _to, _value)
        );
        if(!success1) {
            revert("transfer fail");
        }
        // 触发提取事件
        emit Fetch(_type, _to, _value);
        success = true;
    }

    // 矿税提取; 2;
    // 参数1: 提取的NTFI数量
    function bgFetch2(uint256 _value) public returns (bool success) {
        require(msg.sender == taxMineAddress, "You not can fetch");
        // 判断余额是否足够
        uint256 enough0 = totals[0].all.sub(totals[0].take);
        uint256 enough1To5 = totals[2].all.sub(totals[2].take);
        require(enough0 >= _value && enough1To5 >= _value, "Balance insufficient");
        // 1, 2, 3需要考虑区块高度和区块数递减;
        // 最多可以领取的数量
        uint256 canNumber = countFetch(2);
        // 判断是否可以领取这么多
        require(canNumber.sub(totals[2].take) >= _value, "Balance insufficient in 1 2 3");

        // 增加已领取数量
        totals[0].take = totals[0].take.add(_value);
        totals[2].take = totals[2].take.add(_value);
        // 开始转账
        (bool success1, ) = ntfiAddress.call(
            abi.encodeWithSelector(TRANSFER, msg.sender, _value)
        );
        if(!success1) {
            revert("transfer fail");
        }
        // 触发提取事件
        emit Fetch(2, msg.sender, _value);
        success = true;
    }

    // 计算可领取的数量; 封装;
    // 说明: 只负责参数为1,2,3的;
    // 返回值: 最多可以领取的数量
    function countFetch(uint256 _type) public view returns (uint256 canNumber) {
        // 1, 2, 3 分别对应的比例为 88%, 7%, 5%
        uint256 propor;
        if(_type == 1) {
            propor = 88;
        }else if(_type == 2) {
            propor = 7;
        }else if(_type == 3) {
            propor = 5;
        }else {

        }

        // 2,3需要判断是否可领取这么多, 根据区块高度以及每年产生的区块数量递减10%的条件
        // 计算当下时间, 最多可以领取多少
        uint256 nowBlock = block.number;
        // 一年产生的区块数量; 一年=10512000个区块;
        uint256 yearBlock = 10512000;
        // 挖矿的所有区块
        uint256 allBlock = nowBlock - startBlock;

        // 除法, 要么整除, 除不尽会向下取整;
        // 幂, 0次是1, 1次是相当于*1, 其它次数就是正常计算
        // 20: 每个区块挖矿0.2枚
        // 9: 每年减产10%
        if(allBlock <= yearBlock) {
            canNumber = allBlock.mul(blockTow).mul(propor).div(100);
        }else if(allBlock % yearBlock == 0) {
            for(uint256 i = 0; i < allBlock.div(yearBlock); i++) {
                canNumber = canNumber.add(yearBlock.mul(blockTow).mul(propor).div(100).mul(9**i).div(10**i));
            }
        }else {
            for(uint256 i = 0; i < allBlock.div(yearBlock).add(1); i++) {
                if(i == allBlock.div(yearBlock)) {
                    // 计算剩余的区块可以领取多少
                    canNumber = canNumber.add((allBlock % yearBlock).mul(blockTow).mul(propor).div(100).mul(9**i).div(10**i));
                }else {
                    canNumber = canNumber.add(yearBlock.mul(blockTow).mul(propor).div(100).mul(9**i).div(10**i));
                }
            }
        }

    }

    // 查询目前可以提取的数量
    // 参数1: 查询的类型; 1-5;
    function getCanFetchNumber(uint256 _type) public view returns (uint256 canNumber) {
        require(_type < 6, "Type error");
        if(_type < 1) {
            // 查询的是总量0
            canNumber = totals[_type].all - totals[_type].take;
        }else if(_type < 4) {
            // 1,2,3; 需要计算区块
            uint256 count = countFetch(_type);
            canNumber = count - totals[_type].take;
        }else  {
            // 4,5;不需要计算区块数量
            canNumber = totals[_type].all - totals[_type].take;
        }
    }

    // 分红用户领取分红; 4;  第一次可以直接领取10%, 剩余90%一年释放完
    // 参数1: 领取的金额
    function userFetchRed(uint256 _value) public returns (bool success) {
        // 判断是不是用户
        require(userDetail[msg.sender].all > 0, "You are not entitled");
        // 计算出用户目前最多可以领取的数量
        uint256 fetchNumber = userGetFetchRed(msg.sender);
        require(fetchNumber >= _value, "The quantity claimed is excessive");
        userDetail[msg.sender].take = userDetail[msg.sender].take.add(_value);
        // 验证已领取数量不能大于总量
        assert(userDetail[msg.sender].all >= userDetail[msg.sender].take);
        // 增加用户领取记录
        userRecord[msg.sender].push(user(block.number, block.timestamp, _value));

        // 开始转账
        (bool success1, ) = ntfiAddress.call(
            abi.encodeWithSelector(TRANSFER, msg.sender, _value)
        );
        if(!success1) {
            revert("transfer fail");
        }
        // 触发提取事件
        emit Fetch(4, msg.sender, _value);
        success = true;
    }

    // 用户查询自己本次最多可以领取的数量
    function userGetFetchRed(address _address) public view returns (uint256 r) {
        detail2 storage d = userDetail[_address];
        uint256 nowBlock = block.number;
        // 计算最多可以领取的数量; 一个月=864000个区块; 1年=10512000个区块;
        uint256 n10 = d.all.mul(10).div(100);
        uint256 n90 = d.all.mul(90).div(100);
        uint256 fetchBlock = nowBlock - d.block;
        uint256 everyBlock = n90.div(10512000);
        // 最多可以领取的数量
        uint256 fetchNumber = everyBlock.mul(fetchBlock).add(n10);
        r = fetchNumber.sub(d.take);
    }

    // 查询用户自己的提取分红记录
    function getUserFetchRecord(address _address) public view returns (user[] memory r) {
        uint256 a = userRecord[_address].length;
        r = new user[](a);
        for(uint256 i = 0; i < a; i++) {
            r[i] = userRecord[_address][i];
        }
    }

    // 矿池主领取锁仓分红
    function minerFetchRed(uint256 _value) public returns (bool success) {
        // 先判断是不是矿池主
        require(minerDetail[msg.sender].flag, "You not miner");
        uint256 fetchNumber = minerGetFetchRed(msg.sender);
        require(fetchNumber >= _value, "The quantity claimed is excessive");
        minerDetail[msg.sender].take = minerDetail[msg.sender].take.add(_value);
        // 验证已领取数量不能大于总量
        assert(minerDetail[msg.sender].all >= minerDetail[msg.sender].take);
        minerRecord[msg.sender].push(user(block.number, block.timestamp, _value));

        // 开始转账
        (bool success1, ) = ntfiAddress.call(
            abi.encodeWithSelector(TRANSFER, msg.sender, _value)
        );
        if(!success1) {
            revert("transfer fail");
        }
        // 触发提取事件
        emit Fetch(5, msg.sender, _value);
        success = true;
    }

    // 矿池主查询自己本次最多可以领取的数量; 第一次可以直接领取10%, 剩余90%三个月后开始释放, 9个月后释放完
    function minerGetFetchRed(address _address) public view returns (uint256 r) {
        // 先判断是不是矿池主
        require(minerDetail[_address].flag, "You not miner");
        detail3 storage d = minerDetail[_address];
        uint256 nowBlock = block.number;
        // 计算最多可以领取的数量; 一个月=864000个区块; 3个月=2592000, 9个月=7776000
        uint256 n10 = d.all.mul(10).div(100);
        uint256 n90 = d.all.mul(90).div(100);
        uint256 fetchBlock = nowBlock - d.block;

        uint256 everyBlock = 0;
        if(fetchBlock > 2592000) {
            // 最多可以领取的数量
            fetchBlock = fetchBlock.sub(2592000);
            everyBlock = n90.div(7776000);
        }
        // 最多可以领取的数量
        uint256 fetchNumber = everyBlock.mul(fetchBlock).add(n10);
        r = fetchNumber.sub(d.take);
    }

    // 查询矿池主的提取分红记录
    function getMinerRecord(address _address) public view returns (user[] memory r) {
        uint256 a = minerRecord[_address].length;
        r = new user[](a);
        for(uint256 i = 0; i < a; i++) {
            r[i] = minerRecord[_address][i];
        }
    }

    ///////////////////////////// 用户存币领取收益, 迁移到挖矿合约 /////////////////////////////////
    event Earn(address indexed _userAddress, uint256 _ntfiValue);
    // 用户领取收益收益; 需要后台进行二次签名才可以通过
    // 参数1: ntfi金额
    // 参数2: nonce值
    // 参数3: 二次签名的v,r,su
    function userTakeEarn(uint256 _ntfiValue, uint256 _nonce, bytes memory _signature) public returns (bool success) {
        // 验证得到的地址是不是后台操作者, 并且数据没有被修改;
        // 所使用的数据有: 发送方地址, 接受方地址, 交易的数量, 唯一的值
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, msg.sender, _ntfiValue, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == operationAddress, "Signer is not operation");
        // 签名的messageHash必须是没有使用过的
        require(signHash[messageHash] == false, "MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;

        // 开始转账
        (bool success1, ) = address(ntfiAddress).call(
            abi.encodeWithSelector(TRANSFER, msg.sender, _ntfiValue)
        );
        if(!success1) {
            revert("transfer fail");
        }
        // 触发领取收益
        emit Earn(msg.sender, _ntfiValue);
        success = true;
    }

}