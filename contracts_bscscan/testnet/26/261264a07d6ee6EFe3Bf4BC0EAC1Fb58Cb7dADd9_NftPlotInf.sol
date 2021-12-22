pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

import "./NftPlotPojo.sol";
import "./CoinFactoryAdminRole.sol";

contract NftPlotInf is NftPlotPojo, CoinFactoryAdminRole {
    using SafeMath for uint256;

    constructor () public {
        _owner = msg.sender;
        addCoinFactoryAdmin(msg.sender);
    }

    function triggerInitNft(uint256 key, address impl_add, address token_add) public onlyCoinFactoryAdmin {
        setGlobalUint(2, 1e18);
        setGlobalUint(10, 1000000);

        setGlobalMeth(0, "increaseBlindBox(string,uint256,uint256,uint256[])");
        setGlobalMeth(1, "openTheBlindBoxToGetThePlot(string)");
        setGlobalMeth(2, "mint(address,string,uint256,uint256,uint256[])");
        setGlobalMeth(3, "transfer(address,uint256)");
        setGlobalMeth(4, "transferFrom(address,address,uint256)");

        setGlobalAdd(10, impl_add);
        setGlobalAdd(11, token_add);
    }

    // ################################################################################ 业务

    //业务接口，增加新系列盲盒
    function increaseBlindBox(bytes memory call_p) public onlyCoinFactoryAdmin returns (uint256){
        (bool success, bytes memory data) = address(privateGlobalAdd[10]).delegatecall(abi.encodePacked(getEWithS(methodFacadeConfig[0]), call_p));
        require(success, string(abi.encodePacked("fail code 1 ", data)));
        return abi.decode(data, (uint256));
    }
    //业务接口，重置盲盒货架。新一期，发行新一轮盲盒
    function resetBlindBox() public onlyCoinFactoryAdmin returns (bool){
        plotList.length = 0;
        return true;
    }
    //业务接口，开盲盒
    function openTheBlindBoxToGetThePlot(bytes memory call_p) public returns (uint256){
        (bool success, bytes memory data) = address(privateGlobalAdd[10]).delegatecall(abi.encodePacked(getEWithS(methodFacadeConfig[1]), call_p));
        require(success, string(abi.encodePacked("fail code 2 ", data)));
        return abi.decode(data, (uint256));
    }
    //业务接口，铸造盲合，例如单独奖励不可抽
    function mintBlindBox(bytes memory call_p) public onlyCoinFactoryAdmin returns (uint256){
        (bool success, bytes memory data) = address(privateGlobalAdd[10]).delegatecall(abi.encodePacked(getEWithS(methodFacadeConfig[2]), call_p));
        require(success, string(abi.encodePacked("fail code 3 ", data)));
        return abi.decode(data, (uint256));
    }
    //业务接口，（如：临时补充）改变原有系列盲盒参数
    function updateBlindBoxNum(uint256 plot_id, uint256 number) public onlyCoinFactoryAdmin returns (bool){
        plotList[plot_id].lave_num = number;
        return true;
    }
    //业务接口，（如：临时补充）改变原有系列盲盒参数
    function delBlindBox(uint256 plot_id) public onlyCoinFactoryAdmin returns (bool){
        delete plotList[plot_id];
        return true;
    }

    // 转移Token
    function transfer(bytes memory call_p) public {
        (bool success, bytes memory data) = address(privateGlobalAdd[10]).delegatecall(abi.encodePacked(getEWithS(methodFacadeConfig[3]), call_p));
        require(success, string(abi.encodePacked("fail code 4 ", data)));
    }

    // 转移Token
    function transferFrom(bytes memory call_p) public {
        (bool success, bytes memory data) = address(privateGlobalAdd[10]).delegatecall(abi.encodePacked(getEWithS(methodFacadeConfig[4]), call_p));
        require(success, string(abi.encodePacked("fail code 5 ", data)));
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

    // ################################################################################ 读取

    //获取用户已持有nft数量
    function getUserTokenLen(address user) public view returns (uint256) {return userHoldList[user].length;}
    //获取用户获得的所有nft地块
    function getUserPlotList(address user) public view returns (UserNftPlot[] memory) {return userHoldList[user];}
    //获取所有展示nft列表
    function getPlotList(uint256 type_) public view returns (PlotPoJo[] memory) {return plotList;}
    //所有的TokenID
    function getAllTokenIdList(uint256 type_) public view returns (uint256[] memory) {return allTokenId;}
    //获取用户所有订单
    function getUserOrderList(address user) public view returns (OrderStruct[] memory) {return userOrders[user];}
    //获取所有订单
    function getOrderList(uint256 type_) public view returns (OrderStruct[] memory) {return allOrders;}

    // ################################################################################ 其他

    //扩展接口，多态
    function polymorphismIncrease(string memory name_m, bytes memory call_p) public returns (uint256){
        require(privateGlobalUint[1] == 1, "Not Enabled");
        (bool success, bytes memory data) = address(privateGlobalAdd[10]).delegatecall(abi.encodePacked(getEWithS(name_m), call_p));
        require(success, string(abi.encodePacked("fail code 99 ", data)));
        return abi.decode(data, (uint256));
    }
    //编码方法
    function getEWithS(string memory info) public view returns (bytes4) {return bytes4(keccak256(bytes(info)));}
    //设置全局属性
    function setGlobalUint(uint256 k, uint256 v) public onlyCoinFactoryAdmin returns (bool){
        privateGlobalUint[k] = v;
        return true;}
    //设置全局地址
    function setGlobalAdd(uint256 k, address add) public onlyCoinFactoryAdmin returns (bool){
        privateGlobalAdd[k] = add;
        return true;}
    //设置全局方法
    function setGlobalMeth(uint256 k, string memory met) public onlyCoinFactoryAdmin returns (bool){
        methodFacadeConfig[k] = met;
        return true;}
    //资金提现
    function withdrawTransfer(address token, address to, uint value) public onlyOwner returns (bool){return fundTransfer(token, to, value);}
}

pragma solidity ^0.5.8;

library SafeMath {function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;}
}

contract NftPlotPojo {

    // ################################################################################ 盲盒建筑

    //建筑详情
    struct PlotPoJo {
        //建筑介绍
        string name;
        //剩余数量
        uint256 lave_num;
        //参照数据库注释，该type_id对应资源照片
        uint256 feature_type;
        //建筑属性：长，宽，面积
        uint256[] plot_attribute;
    }
    //本期安排地块 [地块1,地块2,地块3]
    PlotPoJo[] public plotList;
    //NFT建筑列表。ID对建筑
    mapping(uint256 => UserNftPlot) public nftList;
    //所有的TokenId。ID数组
    uint256[] public allTokenId;

    // ################################################################################ 用户建筑

    //token的详情
    struct UserNftPlot {
        //建筑介绍
        string name;
        //持有用户
        address user_address;
        //获得时间
        uint256 create_time;
        //nft id
        uint256 nft_token_id;

        //建筑属性：长，宽，面积
        uint256[] plot_attribute;
        //来源 [ 1抽盲合 2手动合成 3nft转移 ]
        uint256 plot_source;
        //参照数据库注释，该type_id对应资源照片
        uint256 feature_type;
        //是否销毁
        bool is_burn;
        //挂单的价格
        uint256 last_price;
    }

    //用户持有建筑列表。用户对建筑
    mapping(address => UserNftPlot[]) public userHoldList;
    // 用户把所有token授权给某个地址
    mapping(address => address) public approvedToUser;

    // ################################################################################ 用户买卖

    // 挂单的状态
    struct OrderStruct {
        // 创建时间
        uint256 create_time;
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
    // tokenId=>挂单状态; false=没有挂起, true=已经挂起;
    mapping(uint256 => bool) public tokenIdStatus;
    // 用户所有的订单;
    mapping(address => OrderStruct[]) public userOrders;
    // 市场全部的挂起订单;
    OrderStruct[] public allOrders;

    // ################################################################################ 公用

    //方法门面配置
    mapping(uint256 => string) public methodFacadeConfig;
    //全局属性寄存表
    mapping(uint256 => uint256) public privateGlobalUint;
    mapping(uint256 => address) public privateGlobalAdd;

    // 随机数种子
    uint256 randomSeed;
    // 事件广播
    event BodyBroadcast(uint256 k, bytes v, string desc);
    // 铸造盲合
    event MintPlot(uint256 token_id, uint256 feature_type);
    // 触发交易事件
    event Transfer(address from, address to, uint256 tokenId);
    // 授权给用户
    event ApprovalAll(address owner, address approved);

    //资金转账 transferFrom(address,address,uint256)>0x23b872dd。需注意授权中间商。每个赛事玩法币种不一样，就直接来token
    function fundTransferFrom(address token, address from, address to, uint value) internal returns (bool){
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success, string(abi.encodePacked("fail code 10", data)));
        return success;}

    //资金提现
    function fundTransfer(address token, address to, uint value) internal returns (bool){
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success, string(abi.encodePacked("fail code 11", data)));
        return success;}

}

/*@Param KV 整形配置：
@Param 1: 是否启用扩展方法
@Param 2: 开盒消耗的leo
@Param 10: 盲盒NFT自增ID*/

/*@Param KV 地址配置：
@Param 10 业务实现合约
@Param 11 leo token合约*/

pragma solidity ^0.5.8;

library Roles {struct Role {mapping(address => bool) bearer;}
    function add(Role storage role, address account) internal {require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;}
    function remove(Role storage role, address account) internal {require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;}
    function has(Role storage role, address account) internal view returns (bool) {require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];}}

contract CoinFactoryAdminRole {
    address internal _owner;

    function owner() public view returns (address) {return _owner;}
    modifier onlyOwner() {require(isOwner(), "Ownable: caller is not the owner"); _;}

    function isOwner() public view returns (bool) {return msg.sender == _owner;}
    function transferOwnership(address newOwner) public onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address"); _owner = newOwner;}

    using Roles for Roles.Role;
    Roles.Role private _coinFactoryAdmins;
    modifier onlyCoinFactoryAdmin() {require(isCoinFactoryAdmin(msg.sender), "CoinFactoryAdminRole: caller does not have the CoinFactoryAdminRole role"); _;}

    function isCoinFactoryAdmin(address account) public view returns (bool) {return _coinFactoryAdmins.has(account);}
    function addCoinFactoryAdmin(address account) public onlyOwner {_coinFactoryAdmins.add(account);}
    function removeCoinFactoryAdmin(address account) public onlyOwner {_coinFactoryAdmins.remove(account);}
}