pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

import "./NftPlotPojo.sol";
import "./CoinFactoryAdminRole.sol";

contract NftPlotInf is NftPlotPojo, CoinFactoryAdminRole {
    using SafeMath for uint256;

    //windows有参数构造，验证失败
    function triggerInitNft(uint256 key, address impl_add) public {
        require(key == 1, "init fail");

        _owner = msg.sender;
        addCoinFactoryAdmin(msg.sender);

        setGlobalMeth(0, "increaseBlindBox(string,uint256,uint256,uint256,uint256[])");
        setGlobalMeth(1, "openTheBlindBoxToGetThePlot(string)");
        setGlobalMeth(2, "mint(address,string,uint256,uint256,uint256,uint256[])");
        setGlobalMeth(3, "updateBlindBox(uint256,string,uint256,uint256,uint256,uint256[])");
        setGlobalAdd(10, impl_add);
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
    function updateBlindBox(bytes memory call_p) public onlyCoinFactoryAdmin returns (bool){
        (bool success, bytes memory data) = address(privateGlobalAdd[10]).delegatecall(abi.encodePacked(getEWithS(methodFacadeConfig[3]), call_p));
        require(success, string(abi.encodePacked("fail code 4 ", data)));
        return true;
    }

    //获取用户已发行nft数量
    function getUserTokenLen(address user) public view returns (uint256) {return userHoldList[user].length;}

    //获取所有展示nft剩余数量
    function getPlotList(bytes memory call_p) public view returns (uint256 singleLength, string[] memory elementName, uint256[] memory elementNum) {
        uint256 singleLength = 1;
        uint256 j = 0;
        uint256[] memory elementNum = new uint256[](plotList.length * singleLength);
        string[] memory elementName = new string[](elementNum.length);
        for (uint256 i = 0; i < plotList.length; i++) {
            elementNum[j] = plotList[i].lave_num;
            elementName[j] = plotList[i].introduce;
            j = j + singleLength;
        }
        return (singleLength, elementName, elementNum);
    }

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

    //建筑详情
    struct PlotPoJo {
        //建筑介绍
        string introduce;
        //剩余数量
        uint256 lave_num;
        //建筑类型 [ 1地块 2房子...... ]
        uint256 plot_type;
        //特征类型 [ 1灰色地块 2黄色地块 ]
        uint256 feature_type;
        //建筑属性：长，宽，面积
        uint256[] plot_attribute;
    }

    //token的详情
    struct UserNftPlot {
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
        //建筑类型 [ 1地块 2房子...... ]
        uint256 plot_type;
        //特征类型 [ 1灰色地块 2黄色地块 ]
        uint256 feature_type;
        //是否销毁
        bool is_burn;
        //挂单的价格
        uint256 last_price;
    }

    //本期安排地块 [地块1,地块2,地块3]
    PlotPoJo[] public plotList;

    //用户持有建筑列表。用户对建筑
    mapping(address => UserNftPlot[]) public userHoldList;
    //NFT建筑列表。ID对建筑
    mapping(uint256 => UserNftPlot) public nftList;
    //所有的TokenId。ID数组
    uint256[] public allTokenId;

    //方法门面配置
    mapping(uint256 => string) public methodFacadeConfig;
    //全局属性寄存表
    mapping(uint256 => uint256) public privateGlobalUint;
    mapping(uint256 => address) public privateGlobalAdd;

    //随机数种子
    uint256 randomSeed;
    //事件广播
    event BodyBroadcast(uint256 k, bytes v, string desc);
    //事件广播
    event RandomPlot(uint256 t, uint256 r, uint256 l);
}

/*@Param KV 整形配置：
@Param 1: 是否启用扩展方法
@Param 10: 盲盒NFT自增ID*/

/*@Param 10 KV 地址配置：
@Param 10 业务实现合约*/

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