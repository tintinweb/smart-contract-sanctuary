/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


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


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <[email protected]> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    // function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    // event Approval(address owner, address approved, uint256 tokenId);
    event ApprovalAll(address owner, address approved);
    // Optional
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);
}

interface IMdexRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface ERC20 {
    function balanceOf(address _address) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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


// NFT Contract
contract NFT is ERC721, Ownable {
    using SafeMath for uint256;

    string public constant name = "NFT Token";
    string public constant symbol = "NFT";
    // 所有的TokenId; 每个id都是唯一的;
    uint256[] public allTokenId;
    // 所有的系列; 每个系列的id都是唯一, 一个系列有21个token, 1个橙色, 4个蓝色, 16个白色, 每种颜色对应同样的名字;
    uint256[] public allSeriesId;
    // 全部的总魅力值;
    uint256 public allCharm;
    // 总手续费, USDT, 分给持有NFT的用户;
    uint256 public allFee;
    // 总的销毁NFT数量
    uint256 public allBurn;

    // 系列详情;
    struct seriesStruct {
        // 系列是否存在;
        bool isExist;
        // 系列每个颜色所剩余的数量; 橙色=1个, 蓝色=4个, 白色=16个;
        uint256 orangeSurplus;
        uint256 blueSurplus;
        uint256 whiteSurplus;
    }
    // 系列id=>系列详情; 系列id不能为0
    mapping (uint256 => seriesStruct) public seriesMapping;
    // 一个Token的详情;
    struct tokenStruct {
        // token是否存在
        bool isExist;
        // 是否销毁; 销毁了tokenId还是不能与这个重复
        bool isBurn;
        // 所属系列(系列id)
        uint256 seriesId;
        // 颜色; 1=白色, 2=蓝色, 3=橙色, 4=合成之后的蓝色, 5=合成之后的橙色;
        uint256 color;
        // 魅力值
        uint256 charm;
    }
    // TokenId=>Token详情
    mapping (uint256 => tokenStruct) public tokenMapping;
    // TokenId=>拥有者
    mapping (uint256 => address) public tokenToUser;
    // 用户把所有token授权给某个地址
    mapping (address => address) public approvedToUser;
    // 用户拥有的所有TokenId;
    mapping (address => uint256[]) public userAllToken;

    // 用户开盲盒的记录
    struct boxStruct {
        // 区块高度
        uint256 block;
        // tokenId
        uint256 tokenId;
    }
    // 地址=>所有的盲盒记录
    mapping (address => boxStruct[]) public userAllBoxStruct;
    // 地址拥有的碎片数量
    mapping (address => uint256) public userDebris;
    // 开盲盒消耗碎片的数量
    uint256 public debrisNumber = 5;
    // 开盲盒消耗HNFT的数量
    uint256 public hnftNumber = 10 * 10**18;

    // USDT 代币合约地址
    address public usdtAddress;
    // HNFT代币的合约地址
    address public hnftAddress;
    // bsc swap mdex路由合约地址
    address public constant bscRouterAddress = 0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8;
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    bytes4 private constant TRANSFERFROM = bytes4(
        keccak256(bytes("transferFrom(address,address,uint256)"))
    );
    // 用户有NFT就会参与分红
    struct userNft {
        // 总魅力值
        uint256 total;
        // 已经领取的奖励
        uint256 take;
        // 用户的AccSushi
        uint256 accSushi;
    }
    mapping(address => userNft) public userNftMapping;
    // 总的AccSushi
    uint256 allAccSushi;
    // 全部已经领取的奖励
    uint256 allRed;

    // 构造函数
    // 参数1: usdt地址
    // 参数2: hnft地址
    constructor(address _usdtAddress, address _hnftAddress) public {
        usdtAddress = _usdtAddress;
        hnftAddress = _hnftAddress;
    }

    ////////////////////////////////////// 事件 //////////////////////////////////////////////////////
    // 新增系列事件; 系列id, 目前系列的总长度
    event NewSeries(uint256 _seriesId, uint256 _seriesLength);
    // 铸造事件; 只有开盲盒和合成会触发;
    event Mint(address _address, uint256 _seriesId, uint256 _tokenId, uint256 color);
    // 销毁事件;
    event Burn(address _address, uint256 _tokenId);
    // 挂单事件
    event Push(address _address, uint256 _orderId, uint256 _tokenId, uint256 _block);
    // 取消挂单事件
    event Pull(address _address, uint256 _orderId, uint256 _tokenId);
    // 购买事件
    event Buy(address _seller, address _buyer, uint256 _orderId, uint256 _tokenId);


    ////////////////////////////////////// Modifier //////////////////////////////////////////////////////
    // Token必须是存在的
    modifier isToken(uint256 _tokenId) {
        // 必须是存在的;
        require(tokenMapping[_tokenId].isExist == true, "Token not exist");
        _;
    }

    // 必须是Token的拥有者
    modifier onlyTokenOwner(uint256 _tokenId) {
        // 这个卡牌必须是你的
        require(tokenToUser[_tokenId] == msg.sender, "NFT: It has to be yours");
        _;
    }

    ////////////////////////////////////// 管理员-操作 //////////////////////////////////////////////////////
    // 添加新的卡牌系列
    function addSeries() public onlyOwner {
        uint256 _seriesId = allSeriesId.length;
        // 系列id必须不存在
        require(seriesMapping[_seriesId].isExist == false, "NFT: Series existing");
        // 新增一个系列
        seriesMapping[_seriesId] = seriesStruct(true, 1, 4, 16);
        // 系列数组增加一个id
        allSeriesId.push(_seriesId);
        // 添加系列事件
        emit NewSeries(_seriesId, allSeriesId.length);
    }

    // 配置开盲盒消耗的碎片数量
    function setDebrisNumber(uint256 _debrisNumber) external onlyOwner {
        debrisNumber = _debrisNumber;
    }

    // 配置开盲盒消耗HNFT的数量
    function setHnftNumber(uint256 _hnftNumber) external onlyOwner {
        hnftNumber = _hnftNumber;
    }

    // 给地址发放碎片; 后台通过概率随机发放
    // 参数1: 地址数组
    // 参数2: 碎片数组
    function giveDebris(address[] calldata _address, uint256[] calldata _debris) external onlyOwner {
        // 长度必须一致
        require(_address.length == _debris.length, "Length error");
        for(uint256 i = 0; i < _address.length; i++) {
            userDebris[_address[i]] = userDebris[_address[i]].add(_debris[i]);
        }
    }

    ////////////////////////////////////// 工具包 //////////////////////////////////////////////////////
    // 随机生成一个ID; 用于生成token id, 很小的概率会重复, 如果重复就报错;
    // 长度大概长这样: 4471477976155408406;5789302068627388939;6167569892050301362;
    function _randomID64() private view returns (uint256 _tokenId) {
        uint64 _id = uint64(uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, now, allTokenId.length))));
        // uint256接受uint64, 很稳;
        _tokenId = uint256(_id);
        // 这个tokenId必须是不存在的
        require(tokenMapping[_tokenId].isExist == false, "NFT: Token id exist");
    }
    // 随机生成一个orderId; 大概这么长 320450732179946594744076108717109049587
    function _randomID128() private view returns (uint256 _orderId) {
        uint128 _id = uint128(uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, now))));
        // uint256接受uint128, 很稳;
        _orderId = uint256(_id);
        // 这个orderId必须是不存在的
        require(orderMapping[_orderId].block == 0, "NFT: Order id exist");
    }

    // 开盲盒的随机概率; 根据三种颜色剩余的数量然后随机一波, 最后随机开出颜色
    // 参数1: 橙色所剩数量;
    // 参数2: 蓝色所剩数量;
    // 参数3: 白色所剩数量;
    // 返回值: 1=白色, 2=蓝色, 3=橙色;
    function _randomProb(uint256 _o, uint256 _b, uint256 _w) private view returns (uint256 _r) {
        // 计算总数量
        uint256 _total = _o + _b + _w;
        // 总量必须大于0
        require(_total > 0, "Cannot be zero");

        // 随机创建一个很大的数
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, now)));
        // 使用这个很大的数去取余总数量; 得到一个0到_total减1的值, 然后加1, 就得到一个1到_total的数值, 包含1也包含_total
        uint256 luckyNumber = randomNumber % _total + 1;
        // 然后判断这个数字在那个区间里, 就随机生了那个颜色
        if(luckyNumber >= 1 && luckyNumber <= _o) {
            // 随机颜色为橙色
            _r = 3;
        }else if(luckyNumber >= _o + 1 && luckyNumber <= _o + _b) {
            // 随机颜色为蓝色
            _r = 2;
        }else {
            // (luckyNumber >= _o + _b + 1 && luckyNumber <= _o + _b + _w)
            // 随机颜色为白色
            _r = 1;
        }
    }

    // 铸造; 开盲盒, 合成; 这个id必须是不存在过的;
    // 参数1: 用户地址
    // 参数2: 所属的系列id
    // 参数3: tokenId
    // 参数4: 颜色
    // 参数5: 魅力值
    function _mint(address _address, uint256 _seriesId, uint256 _tokenId,  uint256 _color, uint256 _charm) private {
        // 总的tokenId数组
        allTokenId.push(_tokenId);
        // 总的魅力值
        allCharm = allCharm.add(_charm);
        // token
        tokenStruct memory _t = tokenStruct(true, false, _seriesId, _color, _charm);
        tokenMapping[_tokenId] = _t;
        // token所属者
        tokenToUser[_tokenId] = _address;
        // 用户的tokenId数组
        userAllToken[_address].push(_tokenId);
        // 用户的魅力值
        userNftMapping[_address].total = userNftMapping[_address].total.add(_charm);

        // 全局的accSushi不变; 把用户的奖励先领取, 再把总存入金额进行累加, 修改用户的accSuShi
        userTakeRed2(msg.sender);
        // userNftMapping[msg.sender].accSuShi = allAccSushi;
        userNftMapping[msg.sender].total = userNftMapping[msg.sender].total.add(_charm);
        // 触发一个铸造事件; color=1,2,3是开盲盒的; 4,5是合成的;
        emit Mint(_address, _seriesId, _tokenId, _color);
    }

    // 销毁; 合成
    // 参数1: 用户地址
    // 参数2: tokenId
    // 参数3: 魅力值
    function _burn(address _address, uint256 _tokenId, uint256 _charm) private {
        // 总的tokenId数组就不删除了; 查询的时候判断这个tokenId的详情是否是已经销毁进行过滤就好了, 在前端进行过滤
        // 总销毁数量加1
        allBurn = allBurn.add(1);
        // 总魅力值减去
        allCharm = allCharm.sub(_charm);
        // token
        tokenMapping[_tokenId].isBurn = true;
        // token所属者
        delete tokenToUser[_tokenId];
        // 用户的tokenId数组, 也不删除; 查询的时候判断这个tokenId的详情是否是已经销毁进行过滤就好了, 在前端进行过滤
        // 用户的魅力值
        userNftMapping[_address].total = userNftMapping[_address].total.sub(_charm);

        // 全局的accSushi不变; 把用户的奖励先领取, 再把总存入金额进行减少, 修改用户的accSuShi
        userTakeRed2(msg.sender);
        // userNftMapping[msg.sender].accSuShi = allAccSushi;
        userNftMapping[msg.sender].total = userNftMapping[msg.sender].total.sub(_charm);
        // 触发一个销毁事件
        emit Burn(_address, _tokenId);
    }

    // 交易Token
    // 参数1: 发送方地址
    // 参数2: 接收方地址
    // 参数3: tokenId
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        // token所属者
        tokenToUser[_tokenId] = _to;
        // 发送方的tokenId数组; 删除吧;
        uint256[] storage u_ = userAllToken[_from];
        for(uint256 i = 0; i < u_.length; i++) {
            if(u_[i] == _tokenId) {
                // 删除完之后用户的长度没有变化, 等于清空了那个tokenId;
                if(u_.length == i + 1) {
                    // 如果用户只有一个的话, 或者减少的是最后一个的话; 直接弹出最后一个;
                    u_.pop();
                }else {
                    // 如果不是第一个, 就删除那个, 然后把最后一个填补那个删除的位置, 再弹出最后一个;
                    delete u_[i];
                    u_[i] = u_[u_.length - 1];
                    u_.pop();
                }
                break;
            }
        }
        // 接收方的所有tokenId
        userAllToken[_to].push(_tokenId);
        // 发送方的魅力值
        userNftMapping[_from].total = userNftMapping[_from].total.sub(tokenMapping[_tokenId].charm);
        // 接收方的魅力值
        userNftMapping[_to].total = userNftMapping[_to].total.add(tokenMapping[_tokenId].charm);
        // 触发交易事件
        emit Transfer(_from, _to, _tokenId);
    }

    ////////////////////////////////////// 查询 //////////////////////////////////////////////////////
    // 查询所有的系列id
    function getAllSeriesId() external view returns (uint256[] memory _r) {
        uint256 _length = allSeriesId.length;
        // 创建定长结构体数组对象
        _r = new uint256[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _r[i] = allSeriesId[i];
        }
    }

    // 查询用户所有的token以及详情以及订单的挂起状态; 已销毁的前端不显示
    // 参数1: 用户地址
    function getUserAllToken(address _userAddress) external view returns (tokenStruct[] memory _r, uint256[] memory _o, bool[] memory _s) {
        uint256 _length = userAllToken[_userAddress].length;
        // 创建定长结构体数组对象
        _r = new tokenStruct[](_length);
        _o = new uint256[](_length);
        _s = new bool[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _r[i] = tokenMapping[userAllToken[_userAddress][i]];
            _o[i] = userAllToken[_userAddress][i];
            _s[i] = tokenIdStatusMapping[userAllToken[_userAddress][i]];
        }
    }

    // 查询地址开盲盒的所有记录
    function getUserAllBoxStruct(address _userAddress) external view returns (boxStruct[] memory _r) {
        uint256 _length = userAllBoxStruct[_userAddress].length;
        // 创建定长结构体数组对象
        _r = new boxStruct[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _r[i] = userAllBoxStruct[_userAddress][i];
        }
    }

    ////////////////////////////////////// 盲盒 //////////////////////////////////////////////////////
    // 开盲盒;
    // 参数1: 系列id
    function openBlindBox(uint256 _seriesId) external {
        seriesStruct storage s_ = seriesMapping[_seriesId];
        // 这个系列必须是存在的
        require(s_.isExist == true, "Series not existing");
        // 消耗碎片
        require(userDebris[msg.sender] >= debrisNumber, "Not have debris");
        userDebris[msg.sender] = userDebris[msg.sender].sub(debrisNumber);
        // 消耗hnft; 转给0地址销毁;
        (bool success, ) = hnftAddress.call(
            abi.encodeWithSelector(TRANSFERFROM, msg.sender, address(0), hnftNumber)
        );
        if(!success) {
            revert("NFT: transfer fail");
        }
        // 获取这个系列所各种颜色的剩余数量
        uint256 _o = s_.orangeSurplus;
        uint256 _b = s_.blueSurplus;
        uint256 _w = s_.whiteSurplus;
        // 随机开出一个幸运颜色; 返回值: 1=白色, 2=蓝色, 3=橙色;
        uint256 _color = _randomProb(_o, _b, _w);
        // 随机生成一个token id;
        uint256 _tokenId = _randomID64();
        uint256 _charm;
        if(_color == 3) {
            // 随机生成了橙色
            _charm = 2500;
            // 减少一个橙色
            s_.orangeSurplus = s_.orangeSurplus.sub(1);
        }else if(_color == 2) {
            // 随机生成了蓝色
            _charm = 500;
            // 减少一个蓝色
            s_.blueSurplus = s_.blueSurplus.sub(1);
        }else {
            // 随机生成了白色
            _charm = 100;
            // 减少一个白色
            s_.whiteSurplus = s_.whiteSurplus.sub(1);
        }

        // 铸造一个token给用户;
        _mint(msg.sender, _seriesId, _tokenId, _color, _charm);
        // 新增一个用户开盲盒记录
        boxStruct memory _box = boxStruct(block.number, _tokenId);
        userAllBoxStruct[msg.sender].push(_box);
    }

    // 合成; 四个一样的颜色的Token合成一个高一级别的Token, 同一个系列
    // 参数: 卡牌id1,2,3,4
    function jointToken(uint256[] calldata _tokenIds)
    onlyTokenOwner(_tokenIds[0]) onlyTokenOwner(_tokenIds[1]) onlyTokenOwner(_tokenIds[2]) onlyTokenOwner(_tokenIds[3])
    isToken(_tokenIds[0]) isToken(_tokenIds[1]) isToken(_tokenIds[2]) isToken(_tokenIds[3])
    external {
        // 必须是四个, 必须是同一个系列, 不能是同一个id, 必须同一个颜色, 且只能是白色和蓝色，合成之后的蓝色
        require(_tokenIds.length == 4, "NFT: Token id length error");
        require(
            tokenMapping[_tokenIds[0]].seriesId == tokenMapping[_tokenIds[1]].seriesId &&
            tokenMapping[_tokenIds[1]].seriesId == tokenMapping[_tokenIds[2]].seriesId &&
            tokenMapping[_tokenIds[2]].seriesId == tokenMapping[_tokenIds[3]].seriesId
        , "NFT: Series different");
        require(
            _tokenIds[0] != _tokenIds[1] &&
            _tokenIds[1] != _tokenIds[2] &&
            _tokenIds[2] != _tokenIds[3]
        , "NFT: Token id like");
        require(
            tokenMapping[_tokenIds[0]].charm == tokenMapping[_tokenIds[1]].charm &&
            tokenMapping[_tokenIds[1]].charm == tokenMapping[_tokenIds[2]].charm &&
            tokenMapping[_tokenIds[2]].charm == tokenMapping[_tokenIds[3]].charm
        , "NFT: Charm different");
        require(tokenMapping[_tokenIds[0]].color == 1
        || tokenMapping[_tokenIds[0]].color == 2
        || tokenMapping[_tokenIds[0]].color == 4
        , "NFT: Only blue and white");
        require(
            tokenMapping[_tokenIds[0]].isBurn == false &&
            tokenMapping[_tokenIds[1]].isBurn == false &&
            tokenMapping[_tokenIds[2]].isBurn == false &&
            tokenMapping[_tokenIds[3]].isBurn == false
        , "NFT: Token is burn");

        // 随机生成一个token id;
        uint256 _tokenId = _randomID64();
        uint256 _color;
        uint256 _charm;
        tokenStruct memory _t = tokenMapping[_tokenIds[0]];
        if(_t.color == 1) {
            // 升级成蓝色
            _color = 4;
            _charm = 500;
        }else {
            // 升级成橙色
            _color = 5;
            _charm = 2500;
        }

        // 铸造一个token给用户;
        _mint(msg.sender, _t.seriesId, _tokenId, _color, _charm);
        // 销毁这四张卡牌
        _burn(msg.sender, _tokenIds[0], _t.charm);
        _burn(msg.sender, _tokenIds[1], _t.charm);
        _burn(msg.sender, _tokenIds[2], _t.charm);
        _burn(msg.sender, _tokenIds[3], _t.charm);
    }

    ////////////////////////////////////// ERC721 //////////////////////////////////////////////////////
    // 获取Token的总量
    function totalSupply() public view returns (uint256 total) {
        total = allTokenId.length - allBurn;
    }

    // 查询用户的Token总数量
    function balanceOf(address _userAddress) public view returns (uint256 balance) {
        balance = userAllToken[_userAddress].length;
    }

    // 查询TokenId的拥有者; 如果不存在将会返回0地址
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = tokenToUser[_tokenId];
    }

    // 交易Token
    function transfer(address _to, uint256 _tokenId) external isToken(_tokenId) onlyTokenOwner(_tokenId) {
        // 挂起的不能交易
        require(tokenIdStatusMapping[_tokenId] == false, "NFT: Token is push");
        // token必须是没被销毁的
        require(tokenMapping[_tokenId].isBurn == false, "NFT: Token is burn");
        // 不能转给0地址
        require(_to != address(0), "NFT: Zero address");
        // 交易token
        _transfer(msg.sender, _to, _tokenId);
    }

    // 把用户的全部Token授权给某个地址; 如果之前授权了, 将会覆盖之前的授权
    function approveAll(address _to) external {
        // 不能授权给0地址
        require(_to != address(0), "NFT: Zero address");
        // 授权给地址
        approvedToUser[msg.sender] = _to;
        // 触发授权事件
        emit ApprovalAll(msg.sender, _to);
    }

    // 交易授权的Token
    function transferFrom(address _from, address _to, uint256 _tokenId) external isToken(_tokenId) {
        // 挂起的不能交易
        require(tokenIdStatusMapping[_tokenId] == false, "NFT: Token is push");
        // token必须是没被销毁的
        require(tokenMapping[_tokenId].isBurn == false, "NFT: Token is burn");
        // 不能转给0地址
        require(_to != address(0), "NFT: Zero address");
        // 检查是否批准了
        require(approvedToUser[_from] == msg.sender, "NFT: Not approve");
        // 检查这个tokenId是否是发送方的
        require(tokenToUser[_tokenId] == _from, "NFT: It has to be yours");
        // 转让
        _transfer(_from, _to, _tokenId);
    }


    //////////////////////////////////////////// 市场 /////////////////////////////////////////////
    // 挂单的状态
    struct orderStruct {
        // 挂起的区块高度
        uint256 block;
        // 挂起者的地址
        address seller;
        // 购买方地址
        address buyer;
        // usdt价格
        uint256 price;
        // 状态; 1=已挂起,2=取消挂起,3=已卖出
        uint256 status;
        // tokenId
        uint256 tokenId;
    }
    // orderId=>挂单详情
    mapping(uint256 => orderStruct) public orderMapping;
    // tokenId=>挂单状态; false=没有挂起, true=已经挂起;
    mapping(uint256 => bool) public tokenIdStatusMapping;
    // 用户所有的订单;
    mapping(address => uint256[]) public userOrders;
    // 市场全部的挂起订单;
    uint256[] public allOrders;
    // 首发市场全部挂单
    uint256[] public allNipoOrders;
    // 一个tokenId的交易记录; token=>orderId
    mapping(uint256 => uint256[]) public tokenIdToOrdersMapping;

    // 用户挂单到市场
    // 参数1: tokenId
    // 参数2: 价格; usdt
    function userPushOrder(uint256 _tokenId, uint256 _price) external isToken(_tokenId) onlyTokenOwner(_tokenId) {
        // token必须是没被销毁的
        require(tokenMapping[_tokenId].isBurn == false, "NFT: Token is burn");
        // token id必须是没有挂起的
        require(tokenIdStatusMapping[_tokenId] == false, "NFT: Token id is put up");

        // 随机生成一个orderId
        uint256 _orderId = _randomID128();
        // order
        orderStruct memory _o = orderStruct(block.number, msg.sender, address(0), _price, 1, _tokenId);
        orderMapping[_orderId] = _o;
        // tokenId设置为已经挂起
        tokenIdStatusMapping[_tokenId] = true;
        // 用户添加一个orderId
        userOrders[msg.sender].push(_orderId);
        if(msg.sender == Owner) {
            // 首发市场全部挂单orderId
            allNipoOrders.push(_orderId);
        }else {
            // 市场全部订单orderId
            allOrders.push(_orderId);
        }
        // 触发一个挂单事件
        emit Push(msg.sender, _orderId, _tokenId, block.number);
    }

    // 用户取消挂单
    function userPullOrder(uint256 _orderId) external {
        orderStruct storage o_ = orderMapping[_orderId];
        // order id必须是存在的
        require(o_.block > 0, "NFT: Order id is not exist");
        // 只能是挂起者才可以取消
        require(o_.seller == msg.sender, "NFT: Order id is not yours");
        // 订单状态必须是已挂起
        require(o_.status == 1, "NFT: Order id is not push");

        // orderId设置为取消挂起
        o_.status = 2;
        // tokenId设置为未挂起状态
        tokenIdStatusMapping[o_.tokenId] = false;
        // 触发取消挂单事件
        emit Pull(msg.sender, _orderId, o_.tokenId);
    }

    // 用户购买挂单
    function userBuyOrder(uint256 _orderId) external {
        orderStruct storage o_ = orderMapping[_orderId];
        // 不能购买自己的挂单
        require(o_.seller != msg.sender, "NFT: Not buy self");
        // 订单状态必须是已挂起
        require(o_.status == 1, "NFT: Order id is not push");

        // 70%=99%, 10%=1%;
        uint256 _value1;
        uint256 _value2;
        if(o_.seller == Owner) {
            // 首发的
            // 转usdt, 70%给买方, 20%用于兑换成hnft销毁, 10%给合约用于分成
            _value1 = o_.price.mul(70).div(100);
            _value2 = o_.price.mul(10).div(100);
            uint256 _value20 = o_.price.mul(20).div(100);

            // 用户把币先转给合约
            (bool success0, ) = usdtAddress.call(
                abi.encodeWithSelector(TRANSFERFROM, msg.sender, address(this), _value20)
            );
            if(!success0) {
                revert("NFT: transfer fail 00");
            }
            // 合约调用路由合约的兑换USDT=>HNFT
            // 需要先授权usdt给路由合约
            if(ERC20(usdtAddress).allowance(address(this), bscRouterAddress) == 0) {
                ERC20(usdtAddress).approve(bscRouterAddress, 999999999999999999 * 10**18);
            }
            address[] memory _path = new address[](2);
            _path[0] = usdtAddress;
            _path[1] = hnftAddress;
            // bsc swap 路由合约; 兑换直接给到0地址进行销毁
            // IMdexRouter(bscRouterAddress).swapExactTokensForTokens(_value20, 0 , _path, address(0), block.timestamp + 300);
        }else {
            // 不是首发的
            _value1 = o_.price.mul(99).div(100);
            _value2 = o_.price.mul(1).div(100);
        }
        // 99%||70%, 1%||10%;
        (bool success1, ) = usdtAddress.call(
            abi.encodeWithSelector(TRANSFERFROM, msg.sender, o_.seller, _value1)
        );
        if(!success1) {
            revert("NFT: transfer fail 11");
        }
        (bool success2, ) = usdtAddress.call(
            abi.encodeWithSelector(TRANSFERFROM, msg.sender, address(this), _value2)
        );
        if(!success2) {
            revert("NFT: transfer fail 22");
        }

        // 全部的手续费增加
        allFee = allFee.add(_value2);

        // 订单改成已卖出
        o_.buyer = msg.sender;
        o_.status = 3;
        // tokenId设置为未挂起状态
        tokenIdStatusMapping[o_.tokenId] = false;
        // 买方增加一个订单id
        userOrders[msg.sender].push(_orderId);
        // 交易token
        _transfer(o_.seller, msg.sender, o_.tokenId);

        // 修改全局的accSushi
        // 把卖方的奖励先领取, 再把总存入金额进行减少, 修改接收方的accSuShi
        // 把买方的奖励先领取, 再把总存入金额进行增加, 修改发送方的的accSuShi
        allAccSushi = allAccSushi + (_value2 / allCharm);
        userTakeRed2(o_.seller);
        userNftMapping[o_.seller].total = userNftMapping[o_.seller].total.sub(tokenMapping[o_.tokenId].charm);
        userTakeRed2(msg.sender);
        userNftMapping[msg.sender].total = userNftMapping[msg.sender].total.add(tokenMapping[o_.tokenId].charm);
        // 触发购买事件
        emit Buy(o_.seller, msg.sender, _orderId, o_.tokenId);
    }

    // 查询用户的全部挂单, 取消挂单, 购买挂单
    function getUserAllOrder(address _userAddress) external view returns (uint256[] memory _o) {
        uint256 _length = userOrders[_userAddress].length;
        // 创建定长数组对象
        _o = new uint256[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _o[i] = userOrders[_userAddress][i];
        }
    }

    // 查询市场全部挂单; 前端只显示状态为1的
    function getMarketAllOrder() external view returns (uint256[] memory _o) {
        uint256 _length = allOrders.length;
        // 创建定长数组对象
        _o = new uint256[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _o[i] = allOrders[i];
        }
    }

    // 查询某个id的全部交易记录
    function getTokenIdOrder(uint256 _tokenId) external view returns (uint256[] memory _o) {
        uint256 _length = tokenIdToOrdersMapping[_tokenId].length;
        // 创建定长数组对象
        _o = new uint256[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _o[i] = tokenIdToOrdersMapping[_tokenId][i];
        }
    }

    ///////////////////////////////////// 首发 //////////////////////////////////
    // 添加Nipo首发token, 用于首次销售
    function nipoPublish() external onlyOwner {
        // 新增一个系列id
        addSeries();
        uint256 _seriesId = allSeriesId.length - 1;

        // 所有的tokenId必须是不存在的, 每个tokenId不能一样, 一个一个添加进去, 如果一样会报错
        uint256 _color;
        uint256 _charm;
        uint256 _tokenId;
        for(uint256 i = 0; i < 21; i++) {
            _tokenId = _randomID64();
            require(tokenMapping[_tokenId].isExist == false, "NFT: Token id exist");
            if(i == 0) {
                _color = 3;
                _charm = 2500;
            }else if(i < 5) {
                _color = 2;
                _charm = 500;
            }else {
                _color = 1;
                _charm = 100;
            }
            // 铸造token
            _mint(msg.sender, _seriesId, _tokenId, _color, _charm);
            // 现在管理员是有了21个token
        }
    }

    // 查询全部的首发
    // 查询市场全部挂单; 前端只显示状态为1的
    function getNipoMarketAllOrder() external view returns (uint256[] memory _o) {
        uint256 _length = allNipoOrders.length;
        // 创建定长数组对象
        _o = new uint256[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _o[i] = allNipoOrders[i];
        }
    }

    ///////////////////////////////////// 持有nft领取交易手续费 //////////////////////////////////
    // 获取用户可以领取的奖励
    // 参数1: 用户地址
    function getUserRed(address _address) public view returns (uint256 _amount) {
        userNft memory _u = userNftMapping[_address];
        _amount = _u.total * (allAccSushi - _u.accSushi);
    }
    // 用户领取奖励; 默认领取全部
    function userTakeRed() public {
        userTakeRed2(msg.sender);
    }
    function userTakeRed2(address _address) private {
        uint256 _amount = getUserRed(_address);
        if(_amount > 0) {
            (bool success1, ) = usdtAddress.call(
                abi.encodeWithSelector(TRANSFER, _address, _amount)
            );
            if(!success1) {
                revert("NFT: transfer fail red");
            }
        }
        // 从新赋值用户的accSushi
        userNftMapping[_address].accSushi = allAccSushi;
        // 增加用户已经领取奖励
        userNftMapping[_address].take = userNftMapping[_address].take.add(_amount);
        // 增加全部奖励
        allRed = allRed.add(_amount);
    }




}