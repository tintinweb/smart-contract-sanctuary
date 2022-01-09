pragma solidity ^0.8.0;

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

import "./CoinFactoryAdminRole.sol";
import "./ObjectPoJo.sol";

contract ObjectUtil is CoinFactoryAdminRole, ObjectPoJo {

    mapping(uint256 => mapping(uint256 => uint256)) public xySizeUse;
    uint256[][] public xySize;
    using SafeMath for uint256;

    event XySize(uint256 c_x, uint256 c_y, uint256 c_w, uint256 c_h);
    event XySizeUpdate(address id, uint256 c_x, uint256 c_y, uint256 c_w, uint256 c_h);

    //改变照片
    function updatePlotImage(uint256 _tokenId, string memory image_) public returns (uint256){
        nftList[_tokenId].image_suffix = image_;
        UserNftPlot[] memory u_ = userHoldList[nftList[_tokenId].user_address];
        for (uint256 i = 0; i < u_.length; i++) {
            if (u_[i].token_id == _tokenId) u_[i].image_suffix = image_;
        }
        return 1;
    }

    //改变坐标
    function updatePlotXYWH(uint256 _tokenId, uint256 _x, uint256 _y, uint256 _w, uint256 _h) public returns (uint256){
        UserNftPlot storage un = nftList[_tokenId];
        un.current_x = _x;
        un.current_y = _y;
        un.block_width = _w;
        un.block_height = _h;

        UserNftPlot[] storage u_ = userHoldList[un.user_address];
        for (uint256 i = 0; i < u_.length; i++) {
            if (u_[i].token_id == _tokenId) u_[i] = un;
        }

        //emit XySizeUpdate(un.user_address, _tokenId, un.token_id, un.current_x, un.current_y);
        return 1;
    }

    constructor() {
        _owner = msg.sender;
        addCoinFactoryAdmin(msg.sender);

        xySize.push([0, 0, 0, 0]);
        privateGlobalUint[4] = 10;
        privateGlobalUint[3] = 100;
    }

    // 检查xy
    function verifyXySize(uint256 c_x, uint256 c_y, uint256 c_w, uint256 c_h) public onlyCoinFactoryAdmin returns (bool) {
        require(xySizeUse[c_x][c_y] == 0, "dev : xy used");
        xySizeUse[c_x][c_y] = 1;
        xySize.push([c_x, c_y, c_w, c_h]);

        emit XySize(c_x, c_y, c_w, c_h);
        return true;
    }

    // 获取xy
    function getNextXy(address call_, uint256 block_height) public view returns (uint256[] memory) {
        (uint256[] memory last,,uint256 start_,uint256 end_) = getLastXYParam(1);
        uint256 c_x;
        uint256 c_y;

        if (last[0] == 0) {
            //从开始的坐标开始累计
            c_x = 1;
            c_y = 1;
        } else {
            //x默认是当前这一排
            c_x = last[0];
            //纵列第几列 = 上一个纵坐标 + 方块大小
            c_y = last[1].add(last[2]);
        }

        //当纵列超过最大纵列，x换行到下一排去，y重新计算
        if (c_y.add(block_height) > end_) {
            c_x = c_x.add(1);
            c_y = 1;
        }

        //当横列超过最大横列
        require(c_x <= start_, "max nft width!");

        uint256[] memory result = last = new uint256[](2);
        result[0] = c_x;
        result[1] = c_y;
        return result;
    }

    //添加最后坐标，画地抽盒
    function pushLastXy(uint256 c_x, uint256 c_y) public onlyCoinFactoryAdmin {
        xySize.push([c_x, c_y, 1, 1]);
    }

    //得到坐标参数
    function getLastXYParam(uint256 param_) public view returns (uint256[] memory, uint256, uint256, uint256){
        return (xySize[xySize.length.sub(1)], xySize.length, privateGlobalUint[3], privateGlobalUint[4]);
    }

    //得到xy
    function getXYSizeAll(uint256 _index) public view returns (uint256[][] memory) {
        return xySize;
    }
    //得到xy
    function getXYSize(uint256 _index) public view returns (uint256[] memory) {
        return xySize[_index];
    }

    function setXYSize(uint256[][] memory xySize_) public onlyCoinFactoryAdmin {
        xySize = xySize_;
    }

    function setGlobalUint(uint256 k, uint256 v) public onlyCoinFactoryAdmin {privateGlobalUint[k] = v;}
}

pragma solidity ^0.8.0;

contract ObjectPoJo {

    //token的详情
    struct UserNftPlot {
        //nft id
        uint256 token_id;
        //建筑介绍
        string name;
        //持有用户
        address user_address;
        //获得时间
        uint256 create_time;
        //建筑照片
        string image_suffix;
        //建筑类型
        uint256 plot_type;
        //建筑坐标
        uint256 current_x;
        //建筑坐标
        uint256 current_y;
        //建筑宽
        uint256 block_width;
        //建筑高
        uint256 block_height;
        uint256 _param1;
        uint256 _param2;
    }

    //NFT建筑列表。ID对建筑
    mapping(uint256 => UserNftPlot) public nftList;
    //用户持有建筑列表。用户对建筑
    mapping(address => UserNftPlot[]) public userHoldList;
    mapping(uint256 => uint256) public privateGlobalUint;
}

library Roles {struct Role {mapping(address => bool) bearer;}

    function add(Role storage role, address account) internal {require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;}

    function remove(Role storage role, address account) internal {require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;}

    function has(Role storage role, address account) internal view returns (bool) {require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];}}

pragma solidity ^0.8.0;

contract CoinFactoryAdminRole {
    address internal _owner;

    function owner() public view returns (address) {return _owner;}
    modifier onlyOwner() {require(isOwner(), "Ownable: caller is not the owner");
        _;}

    function isOwner() public view returns (bool) {return msg.sender == _owner;}

    function transferOwnership(address newOwner) public onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;}

    using Roles for Roles.Role;
    Roles.Role private _coinFactoryAdmins;
    modifier onlyCoinFactoryAdmin() {require(isCoinFactoryAdmin(msg.sender), "CoinFactoryAdminRole: caller does not have the CoinFactoryAdminRole role");
        _;}

    function isCoinFactoryAdmin(address account) public view returns (bool) {return _coinFactoryAdmins.has(account);}

    function addCoinFactoryAdmin(address account) public onlyOwner {_coinFactoryAdmins.add(account);}

    function removeCoinFactoryAdmin(address account) public onlyOwner {_coinFactoryAdmins.remove(account);}
}