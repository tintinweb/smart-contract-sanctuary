//SourceUnit: NFTMining.sol

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


// Math operations with safety checks that throw on error
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add Math error");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "sub Math error");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "mul Math error");
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


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
    // Optional
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);
}


// Ownable Contract
contract Ownable {
    address public Owner;

    constructor() public {
        Owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner, "You not owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            Owner = _newOwner;
        }
    }

}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}


// NFT Mining Contract
contract NFTMining is Ownable {
    using SafeMath for uint256;
    using TransferHelper for address;
    // 池子信息
    struct tokenStruct {
        // 是否已经有了
        bool isFlag;
        // 是否关闭; false=关闭
        bool isClosed;
        // 名字
        string name;
        // 总质押
        uint256 totalDeposit;
        // 总提取
        uint256 totalWithdraw;
        // 总被提走的收益
        uint256 totalRed;
        // 单币挖矿和Lp挖矿的全局accShu
        uint256 accSushi;
        // 玩家人数
        uint256 playerNumber;
        // 上一次领取的区块高度
        uint256 block;
    }
    // 单币地址=>单币质押池子信息
    mapping(address => tokenStruct) public tokenMapping;
    // Lp币地址 => 池子信息
    mapping(address => tokenStruct) public lpMapping;
    // 全部的单币地址
    address[] public tokens;
    // 全部lp币地址
    address[] public lps;

    // 用户的信息
    struct userStruct {
        // 总投资
        uint256 amount;
        // 已领取的收益
        uint256 alreadyRed;
        // 用户的accSushi
        uint256 accSushi;
    }
    // token地址=>地址=>用户信息
    mapping(address => mapping(address => userStruct)) public userTokenMapping;
    mapping(address => mapping(address => userStruct)) public userLpMapping;
    // 是否是有效用户
    mapping(address => bool) public userMapping;

    // 记录地址是否质押过; token地址=>用户地址=>是否玩过
    mapping(address => mapping(address => bool)) public tokenUserPlayer;
    // 记录地址是否质押过; lp地址=>用户地址=>是否玩过
    mapping(address => mapping(address => bool)) public lpUserPlayer;

    // HNFT合约地址
    address public hnftAddress;
    // 每个区块的产出HNFT数量, Token=40% LP=60%; 如果有多个池子进行平分(000000000000000000)
    uint256[3] public everyNumber = [5000000000000000000, 40, 60];

    // 构造函数
    // 参数1: hnft合约地址
    constructor(address _hnftAddress) public {
        hnftAddress = _hnftAddress;
    }

    // 质押事件
    event Deposit(address _address, uint256 _value);

    // 设置分配的数量
    // 参数1: 每个区块产生的总量
    // 参数3: 单币的占比
    // 参数4: Lp的占比
    function setEveryNumber(uint256 _total, uint256 _token, uint256 _lp) external onlyOwner {
        require(_token + _lp == 100, "Ratio error");
        everyNumber[0] = _total;
        everyNumber[1] = _token;
        everyNumber[2] = _lp;
    }

    // 管理员添加一个单币质押池子
    // 参数1: token合约地址
    // 参数2: 名字
    function addToken(address _tokenAddress, string calldata _name) external onlyOwner {
        require(_tokenAddress != address(0), "Zero address");
        // 这个地址是不存在的
        require(tokenMapping[_tokenAddress].isFlag == false, "Token exist");
        // 添加
        tokenStruct memory _t = tokenStruct(true, false, _name, 0, 0, 0, 0, 0, block.number);
        tokenMapping[_tokenAddress] = _t;
        tokens.push(_tokenAddress);
    }

    // 管理员添加一个LP质押池子
    // 参数1: lp合约地址
    // 参数2: 名字
    function addLp(address _lpAddress, string calldata _name) external onlyOwner {
        require(_lpAddress != address(0), "Zero address");
        // 这个地址是不存在的
        require(lpMapping[_lpAddress].isFlag == false, "Token exist");
        // 添加
        tokenStruct memory _t = tokenStruct(true, false, _name, 0, 0, 0, 0, 0, block.number);
        lpMapping[_lpAddress] = _t;
        lps.push(_lpAddress);
    }

    // 关闭或开启token池子
    function closeOrOpenTokenPool(address _tokenAddress) external onlyOwner {
        // 这个地址是存在的
        require(tokenMapping[_tokenAddress].isFlag == true, "Token not exist");
        tokenMapping[_tokenAddress].isClosed = !tokenMapping[_tokenAddress].isClosed;
    }

    // 关闭或开启lp池子
    function closeOrOpenLpPool(address _lpAddress) external onlyOwner {
        // 这个地址是存在的
        require(lpMapping[_lpAddress].isFlag == true, "Token not exist");
        lpMapping[_lpAddress].isClosed = !lpMapping[_lpAddress].isClosed;
    }

    // 查询tokens
    function getTokens() external view returns (address[] memory _r) {
        uint256 _length = tokens.length;
        // 创建定长结构体数组对象
        _r = new address[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _r[i] = tokens[i];
        }
    }

    // 查询lps
    function getLps() external view returns (address[] memory _r) {
        uint256 _length = lps.length;
        // 创建定长结构体数组对象
        _r = new address[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _r[i] = lps[i];
        }
    }

    //////////////////////////////////////////// 封装 //////////////////////////////////////
    // 存入的封装; Token, Lp
    // 参数1: token or Lp地址
    // 参数2: 存入的代币金额
    // 参数3: 1=token, 2=lp;
    // 参数4: 池子信息的引用
    // 参数5: 用户信息的引用
    function _depositStorage(address _tokenAddress, uint256 _value, uint256 _tokenType, tokenStruct storage t_, userStruct storage u_) private {
        // 先把存入的代币金额转给合约
        _tokenAddress.safeTransferFrom(msg.sender, address(this), _value);

        if(u_.amount == 0) {
            // 用户的是第一次存入, 或者之前全部取出来了
            // 增加用户的总投资
            u_.amount = u_.amount.add(_value);
            // 修改用户accSushi为最新的accSushi
            u_.accSushi = t_.accSushi;

            // 增加池子的总质押
            t_.totalDeposit = t_.totalDeposit.add(_value);
            return;
        }

        // 不是第一次存入, 先把用户的收益给领取了, 然后把两笔订单合成一笔
        // 计算本次区块之间产出的分红总数量
        uint256 _length;
        if(_tokenType == 1) {
            // tokens数组长度
            _length = tokens.length;
        }else {
            // lps数组长度
            _length = lps.length;
        }
        // 计算本次区块之间产出的分红总数量
        // uint256 _totalRed = (block.number - t_.block) * everyNumber[0] * everyNumber[_tokenType] / 100 / _length;
        uint256 _totalRed = (block.number.sub(t_.block)).mul(everyNumber[0]).mul(everyNumber[_tokenType]).div(100).div(_length);
        // 最新的accSushi
        // uint256 _nowSushi = t_.accSushi + _totalRed / t_.totalDeposit;
        uint256 _nowSushi = t_.accSushi.add(_totalRed.div(t_.totalDeposit));
        // 计算用户收益
        // uint256 _userRed = u_.amount * (_nowSushi - u_.accSushi);
        uint256 _userRed = u_.amount.mul(_nowSushi.sub(u_.accSushi));
        // 如果收益大于0就执行交易; 考虑某些erc20不能交易0金额, 会报错
        if(_userRed > 0) {
            // 收益HNFT币给到用户
            hnftAddress.safeTransfer(msg.sender, _userRed);
        }

        // 增加用户的总投资
        u_.amount = u_.amount.add(_value);
        // 修改用户accSushi为最新的accSushi
        u_.accSushi = _nowSushi;
        // 增加用户已领取收益
        u_.alreadyRed = u_.alreadyRed.add(_userRed);

        // 修改区块高度为当前
        t_.block = block.number;
        // 增加池子的总质押
        t_.totalDeposit = t_.totalDeposit.add(_value);
        // 增加池子的被提取的总收益
        t_.totalRed = t_.totalRed.add(_userRed);
        // 修改池子的accSushi为最新的accSushi
        t_.accSushi = _nowSushi;
    }

    // 用户的上级; 用户地址=>上级地址
    mapping(address => address) public superAddress;
    // 邀请记录
    struct inviteStruct {
        // 时间
        uint256 time;
        // 地址
        address subor;
    }
    mapping(address => inviteStruct[]) public inviteMapping;

    // 查询所有的下级; 不能返回结构体, 要分成两个基础类型;
    function getSubor(address _address) public view returns(uint256[] memory _t, address[] memory _s) {
        uint256 _length = inviteMapping[_address].length;
        // 创建定长结构体数组对象
        _t = new uint256[](_length);
        _s = new address[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _t[i] = inviteMapping[_address][i].time;
            _s[i] = inviteMapping[_address][i].subor;
        }
    }

    uint256 public superRatio = 5;
    uint256 public superSuperRatio = 2;

    // 设置上级和上上级比例
    // 参数1: 上级获取的比%;
    // 参数2: 上上级获取的比%;
    function setSuperRatio(uint256 _superRatio, uint256 _superSuperRatio) onlyOwner public {
        superRatio = _superRatio;
        superSuperRatio = _superSuperRatio;
    }

    // 提取的封装; Token, LP
    // 参数1: token or Lp地址
    // 参数2: 提取的代币金额
    // 参数3: 1=token, 2=lp;
    // 参数4: 池子信息的引用
    // 参数5: 用户信息的引用
    function _withdrawStorage(address _tokenAddress, uint256 _value, uint256 _tokenType, tokenStruct storage t_, userStruct storage u_) private {
        // 计算本次区块之间产出的分红总数量
        uint256 _length;
        if(_tokenType == 1) {
            // tokens数组长度
            _length = tokens.length;
        }else {
            // lps数组长度
            _length = lps.length;
        }
        // uint256 _totalRed = (block.number - t_.block) * everyNumber[0] * everyNumber[_tokenType] / 100 / _length;
        uint256 _totalRed = (block.number.sub(t_.block)).mul(everyNumber[0]).mul(everyNumber[_tokenType]).div(100).div(_length);
        // 最新的accSushi
        // uint256 _nowSushi = t_.accSushi + _totalRed / t_.totalDeposit;
        uint256 _nowSushi = t_.accSushi.add(_totalRed.div(t_.totalDeposit));
        // 计算用户收益
        // uint256 _userRed = u_.amount * (_nowSushi - u_.accSushi);
        uint256 _userRed = u_.amount.mul(_nowSushi.sub(u_.accSushi));

        // 提取的币给用户
        require(u_.amount >= _value, "Money error");
        if(_value > 0) {
            // 把用户提取的币转到用户
            _tokenAddress.safeTransfer(msg.sender, _value);
        }
        // 如果收益大于0就执行交易; 考虑某些erc20不能交易0金额, 会报错
        if(_userRed > 100) {

            // 收益给上级或销毁
            address _zeroAddress = address(0x0000000000000000000000000000000000000099);
            address _super1 = superAddress[msg.sender];
            address _super2 = superAddress[_super1];
            uint256 _value3 = _userRed.mul(superRatio).div(100);
            uint256 _value2 = _userRed.mul(superSuperRatio).div(100);
            uint256 v95 = uint256(100).sub(superRatio).sub(superSuperRatio);
            uint256 _value95 = _userRed.mul(v95).div(100);

            if(_super1 == address(0)) {
                _super1 = _zeroAddress;
            }
            if(_super2 == address(0)) {
                _super2 = _zeroAddress;
            }
            // 都有
            hnftAddress.safeTransfer(_super1, _value3);
            hnftAddress.safeTransfer(_super2, _value2);
            hnftAddress.safeTransfer(msg.sender, _value95);

        }

        // 减少用户的总投资
        u_.amount = u_.amount.sub(_value);
        // 修改用户accSushi为最新的accSushi
        u_.accSushi = _nowSushi;
        // 增加用户已领取收益
        u_.alreadyRed = u_.alreadyRed.add(_userRed);

        // 修改用户上一次的区块高度为当前
        t_.block = block.number;
        // 减少池子的总质押
        t_.totalDeposit = t_.totalDeposit.sub(_value);
        // 增加池子的总提取
        t_.totalWithdraw = t_.totalWithdraw.add(_value);
        // 增加池子的被提取的总收益
        t_.totalRed = t_.totalRed.add(_userRed);
        // 修改池子的accSushi为最新的accSushi
        t_.accSushi = _nowSushi;
    }

    // 查询收益的封装
    // 参数1: 1=token, 2=lp;
    // 参数2: 池子信息的引用
    // 参数3: 用户信息的引用
    function _getRed(uint256 _tokenType, tokenStruct memory _t, userStruct memory _u) private view returns (uint256 _userRed) {
        // 计算本次区块之间产出的分红总数量
        uint256 _length;
        if(_tokenType == 1) {
            // tokens数组长度
            _length = tokens.length;
        }else {
            // lps数组长度
            _length = lps.length;
        }
        // 计算本次区块之间产出的分红总数量
        // uint256 _totalRed = (block.number - _t.block) * everyNumber[0] * everyNumber[_tokenType] / 100 / _length;
        uint256 _totalRed = (block.number.sub(_t.block)).mul(everyNumber[0]).mul(everyNumber[_tokenType]).div(100).div(_length);
        // 最新的accSushi
        // uint256 _nowSushi = _t.accSushi + _totalRed / _t.totalDeposit;
        uint256 _nowSushi = _t.accSushi.add(_totalRed.div(_t.totalDeposit));
        // 计算用户收益
        // _userRed = _u.amount * (_nowSushi - _u.accSushi);
        _userRed = _u.amount.mul(_nowSushi.sub(_u.accSushi));
    }

    ////////////////////////////////////////// Token ///////////////////////////////////////////
    // 单币的存入
    // 参数1: token的地址
    // 参数2: 存入的数量
    // 参数3: 上级地址
    function depositToken(address _tokenAddress, uint256 _value, address _superAddress) external {
        require(msg.sender != _superAddress, "NFTMining: not my self");
        if(userMapping[msg.sender] == false) {
            userMapping[msg.sender] = true;
        }
        if(superAddress[msg.sender] == address(0) && _superAddress != address(0)) {
            if(userMapping[msg.sender]) {
                superAddress[msg.sender] = _superAddress;
                inviteStruct memory _i = inviteStruct(block.timestamp, msg.sender);
                inviteMapping[_superAddress].push(_i);
            }
        }
        // token信息的指针引用
        tokenStruct storage t_ = tokenMapping[_tokenAddress];
        // 用户信息的指针引用
        userStruct storage u_ = userTokenMapping[_tokenAddress][msg.sender];
        // 判断token是否存在, 必须存在
        require(t_.isFlag == true, "Mining: Token not exist");
        // 必须是没有关闭的
        require(t_.isClosed == false, "Mining: Token is closed");

        // 存入代币
        _depositStorage(_tokenAddress, _value, 1, t_, u_);
        // 增加一个新用户地址
        if(tokenUserPlayer[_tokenAddress][msg.sender] == false) {
            // 第一次存入
            tokenUserPlayer[_tokenAddress][msg.sender] = true;
            t_.playerNumber++;
        }

        emit Deposit(msg.sender, _value);
    }

    // 用户提现Token赚取; 提现任意金额都会把全部的HNFT收益给到用户, 如果提现0的话就是仅仅提取收益
    // 参数1: token的合约地址
    // 参数2: 提现的金额
    function withdrawToken(address _tokenAddress, uint256 _value) external {
        // token信息的指针引用
        tokenStruct storage t_ = tokenMapping[_tokenAddress];
        // 用户信息的指针引用
        userStruct storage u_ = userTokenMapping[_tokenAddress][msg.sender];
        // 判断token是否存在, 必须存在
        require(t_.isFlag == true, "Mining: Token not exist");
        // 必须是没有关闭的
        require(t_.isClosed == false, "Mining: Token is closed");

        // 调用提现的封装
        _withdrawStorage(_tokenAddress, _value, 1, t_, u_);
    }

    // 查询用户的总收益; Token池子
    // 参数1: 代币的地址
    // 参数2: 用户的地址
    function getRedToken(address _tokenAddress, address _userAddress) public view returns (uint256 _userRed) {
        // token信息的指针引用
        tokenStruct memory _t = tokenMapping[_tokenAddress];
        // 用户信息的指针引用
        userStruct memory _u = userTokenMapping[_tokenAddress][_userAddress];
        // 判断token是否存在
        require(_t.isFlag == true, "Mining: Token not exist");

        _userRed = _getRed(1, _t, _u);
    }

    ////////////////////////////////////////// LP ///////////////////////////////////////////
    // LP的存入
    // 参数1: lp的地址
    // 参数2: 存入的数量
    // 参数3: 上级地址
    function depositLp(address _tokenAddress, uint256 _value, address _superAddress) external {
        require(msg.sender != _superAddress, "NFTMining: not my self");
        if(userMapping[msg.sender] == false) {
            userMapping[msg.sender] = true;
        }
        if(superAddress[msg.sender] == address(0) && _superAddress != address(0)) {
            if(userMapping[msg.sender]) {
                superAddress[msg.sender] = _superAddress;
                inviteStruct memory _i = inviteStruct(block.timestamp, msg.sender);
                inviteMapping[_superAddress].push(_i);
            }
        }
        // token信息的指针引用
        tokenStruct storage t_ = lpMapping[_tokenAddress];
        // 用户信息的指针引用
        userStruct storage u_ = userLpMapping[_tokenAddress][msg.sender];
        // 判断token是否存在, 必须存在
        require(t_.isFlag == true, "Mining: Token not exist");
        // 必须是没有关闭的
        require(t_.isClosed == false, "Mining: Token is closed");

        // 存入代币
        _depositStorage(_tokenAddress, _value, 2, t_, u_);
        // 增加一个新用户地址
        if(lpUserPlayer[_tokenAddress][msg.sender] == false) {
            // 第一次存入
            lpUserPlayer[_tokenAddress][msg.sender] = true;
            t_.playerNumber++;
        }

        emit Deposit(msg.sender, _value);
    }

    // 用户提现LP赚取; 提现任意金额都会把全部的HNFT收益给到用户, 如果提现0的话就是仅仅提取收益
    // 参数1: lp的合约地址
    // 参数2: 提现的金额
    function withdrawLp(address _tokenAddress, uint256 _value) external {
        // token信息的指针引用
        tokenStruct storage t_ = lpMapping[_tokenAddress];
        // 用户信息的指针引用
        userStruct storage u_ = userLpMapping[_tokenAddress][msg.sender];
        // 判断token是否存在, 必须存在
        require(t_.isFlag == true, "Mining: Token not exist");
        // 必须是没有关闭的
        require(t_.isClosed == false, "Mining: Token is closed");

        // 调用提现的封装
        _withdrawStorage(_tokenAddress, _value, 2, t_, u_);
    }

    // 查询用户的总收益; Lp池子
    // 参数1: 代币的地址
    // 参数2: 用户的地址
    function getRedLp(address _tokenAddress, address _userAddress) public view returns (uint256 _userRed) {
        // token信息的指针引用
        tokenStruct memory _t = lpMapping[_tokenAddress];
        // 用户信息的指针引用
        userStruct memory _u = userLpMapping[_tokenAddress][_userAddress];
        // 判断token是否存在
        require(_t.isFlag == true, "Token not exist");

        _userRed = _getRed(2, _t, _u);
    }






}