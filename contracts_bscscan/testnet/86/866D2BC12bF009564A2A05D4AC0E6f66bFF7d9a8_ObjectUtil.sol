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


contract ObjectUtil {

    mapping(uint256 => uint256) public privateGlobalUint;
    mapping(uint256 => mapping(uint256 => uint256)) public xySizeUse;
    uint256[][] public xySize;
    using SafeMath for uint256;
    mapping(uint256 => UserNftPlot) public nftList;
    mapping(address => UserNftPlot[]) public userHoldList;

    event XySize(uint256 c_x, uint256 c_y, uint256 c_w, uint256 c_h);

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
    }

    //改变照片
    function updatePlotImage(uint256 _tokenId, string memory image_) public {
        nftList[_tokenId].image_suffix = image_;
        UserNftPlot[] memory u_ = userHoldList[nftList[_tokenId].user_address];
        for (uint256 i = 0; i < u_.length; i++) {
            if (u_[i].token_id == _tokenId) u_[i].image_suffix = image_;
        }
    }

    //改变坐标
    function updatePlotXYWH(uint256 _tokenId, uint256 _x, uint256 _y, uint256 _w, uint256 _h) public {
        UserNftPlot storage un = nftList[_tokenId];
        un.current_x = _x;
        un.current_y = _y;
        un.block_width = _w;
        un.block_height = _h;
        UserNftPlot[] memory u_ = userHoldList[nftList[_tokenId].user_address];
        for (uint256 i = 0; i < u_.length; i++) {
            if (u_[i].token_id == _tokenId) u_[i] = un;
        }
    }

    constructor() {
        xySize.push([0, 0, 0, 0]);
        privateGlobalUint[4] = 10;

        /*uint256[] memory a = new uint256[](4);
          a[0] = 1;
          a[1] = 3;
          a[2] = 1;
          a[3] = 1;
          uint256[] memory b = new uint256[](4);
          b[0] = 3;
          b[1] = 0;
          b[2] = 10;
          setLastXYParam(0, b);
          setLastXYParam(1, a);*/
    }

    // 检查xy
    function verifyXySize(uint256 c_x, uint256 c_y, uint256 c_w, uint256 c_h) public returns (bool) {
        require(xySizeUse[c_x][c_y] == 0, "dev : xy used");
        xySizeUse[c_x][c_y] = 1;
        xySize.push([c_x, c_y, c_w, c_h]);

        emit XySize(c_x, c_y, c_w, c_h);
        return true;
    }

    //得到坐标参数
    function getLastXYParam(uint256 param_) public view returns (uint256[] memory, uint256, uint256, uint256){
        return (xySize[xySize.length.sub(1)], xySize.length, privateGlobalUint[3], privateGlobalUint[4]);
    }

    function getXYSize(uint256 _index) public view returns (uint256[] memory) {
        return xySize[_index];
    }

    // 获取xy
    function getNextXy(address call_, uint256 block_height) public view returns (uint256[] memory) {
        (uint256[] memory last,,,uint256 end_) = getLastXYParam(1);
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

        uint256[] memory result = last = new uint256[](2);
        result[0] = c_x;
        result[1] = c_y;
        return result;
    }

}