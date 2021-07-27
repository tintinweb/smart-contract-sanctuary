/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// SPDX-License-Identifier: SimPL-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

interface IERC20 {
    // 代币总数
    function totalSupply() external view returns (uint);

    // 账户余额
    function balanceOf(address owner) external view returns (uint);

    // 交易的发起方(谁调用这个方法，谁就是交易的发起方)把_value数量的代币发送到_to账户
    function transfer(address _to, uint256 _value) external returns (bool);

    // 从_from账户里转出_value数量的代币到_to账户
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    // 交易的发起方把_value数量的代币的使用权交给_spender
    // 然后_spender才能调用transferFrom方法把我账户里的钱转给另外一个人
    function approve(address _spender, uint256 _value) external returns (bool);

    // 查询_spender目前还有多少_owner账户代币的使用权
    function allowance(address _owner, address _spender) external view returns (uint256);

    // 使用权委托成功的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:ADD_OVERFLOW");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:SUB_UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath:MUL_OVERFLOW");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:DIV_ZERO");
        uint256 c = a / b;

        return c;
    }
}

interface IUniswapRouterV2{
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function WETH() external pure returns (address);
}

interface IRosManager {
    function burnRosIn(address _builder, uint _ethValue) external returns(bytes32);
}

// 设置代币控制合约的管理员
contract Owned {

    // 权力所有者
    address public owner;

    mapping(address => bool) public admin;

    // 合约创建的时候执行，执行合约的人是第一个owner
    constructor() public {
        owner = msg.sender;
        setAdmin(msg.sender, true);
    }

    // 设置管理员  true 或 false
    function setAdmin(address _addr, bool _enable) public onlyOwner {
        admin[_addr] = _enable;
    }

    // 现任owner把所有权交给新的owner(需要新的owner调用acceptOwnership方法才会生效)
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    modifier isPermission() {
        require(admin[msg.sender], "STORAGE:permission denied!");
        _;
    }

    // modifier(条件)，表示必须是权力所有者才能操作，类似超管
    modifier onlyOwner() {
        require(msg.sender == owner,"STORAGE:only owner");
        _;
    }
}


//存储相关
contract FundAccessStorageMem is Owned{
    using SafeMath for uint;
    //dydx操作账户
    mapping(address=>bool) dydxAccount;

    //质押合约
    IRosManager public RosManager;

    //运维账户
    //    address payable public OPS;

    //dydx操作地址是否被授权
    mapping(address=>bool) dydxManageAddrList;


    // 自增随机数和建仓人数
    uint TotalOpenPositionNum = 0;

    // 用户建仓记录 是否建过仓|现有建仓额度 用户建仓地址=>建仓额度
    mapping(address => uint) isPositionMemberAndValue;

    // 单个用户最大可持仓的eth数量
    uint public PositionMemberMaxValue = 3 ether;

    // 单个用户最小持仓的eth数量
    uint public PositionMemberMinValue = 0.2 ether;

    // 全网用户最大可持仓的eth总数量和已建仓数量 全网最大|已建仓
    uint TotalMaxValueAndPositionValue;

    //设置dydx账户
    function setdydxAccount(address account)onlyOwner public{
        dydxManageAddrList[account]=true;
    }

    function setdydxAccount(address[] memory accounts)onlyOwner public{
        for (uint i;i<accounts.length;i++){
            dydxAccount[accounts[i]]=true;
        }
    }

    // 设置单个用户建仓最大eth数量
    function setPositionMemberMaxValue(uint _value) external onlyOwner {
        PositionMemberMaxValue = _value;
    }

    // 设置全网用户建仓最大eth数量
    function setTotalMax(uint _max) external onlyOwner {
        (, uint _total) = getTotalMaxValueAndPositionValue();
        TotalMaxValueAndPositionValue = unionUint128128(_max, _total);
    }

    // 设置单个用户建仓最小eth数量
    function setPositionMemberMinValue(uint _value) external onlyOwner {
        PositionMemberMinValue = _value;
    }

    // 获取全网最大建仓额度和已建仓额度
    function getTotalMaxValueAndPositionValue() public view returns (uint _max, uint _total) {
        (_max, _total) = getMergeUint128128(TotalMaxValueAndPositionValue);
    }

    // 用户建仓金额
    function getPositionValue(address _account) external view returns (uint _value) {
        (, _value) = getMergeUint128128(isPositionMemberAndValue[_account]);
    }

    // 用户是否已建仓
    function isPositionMember(address _account) external view returns (bool) {

        (uint _is,) = getMergeUint128128(isPositionMemberAndValue[_account]);
        return _is == 1;
    }


    // 128 128 二合一
    function unionUint128128(uint _value1, uint _value2) internal pure returns (uint){
        _value1 |= _value2 << 128;
        return _value1;
    }

    // 128 128 拆分
    function getMergeUint128128(uint _value) internal pure returns (uint _value1, uint _value2) {
        _value1 = uint(uint128(_value));
        _value2 = uint(uint128(_value >> 128));
    }


    function withdrawETH(address payable _to) external isPermission {
        _to.transfer(address(this).balance);
    }
}


contract FundAccessEvent{
    event OpenPositionLog(bytes32 id, address account,address fundManager,uint ETHValue,uint timestamp);

    event OutPositionLog(address account,uint USDValue,uint tokenChargeNum,uint timestamp);
}


contract FundAccess is FundAccessStorageMem,FundAccessEvent  {
    constructor(address _rosManger,address[] memory dydxAccounts) public {
        RosManager = IRosManager(_rosManger);
        TotalMaxValueAndPositionValue = unionUint128128(300 ether, 0);
        setdydxAccount(dydxAccounts);
    }

    function openPosition(
        address dydxManager
    )public payable{
        require(msg.sender != address(0), "Cannot be an empty address");
        uint balanceEth=msg.value;

        require(balanceEth != 0, "The amount of warehouse building cannot be equal to 0");

        (uint _is, uint _value) = getMergeUint128128(isPositionMemberAndValue[msg.sender]);
        _value = _value.add(balanceEth);
        //检查建仓的ETH数量是否超过没人限额
        require(_value <= PositionMemberMaxValue, "OVER_LIMIT");
        (uint _max, uint _total) = getTotalMaxValueAndPositionValue();
        _total = _total.add(balanceEth);
        //TODO:检查建仓的ETH数量是否超过总基金限额
        require(_total <= _max, "TOTAL_OVER_LIMIT");
        TotalMaxValueAndPositionValue = unionUint128128(_max, _total);
        if (_is == 0) {
            _is = 1;
            TotalOpenPositionNum++;
        }
        isPositionMemberAndValue[msg.sender] = unionUint128128(_is, _value);

        //调用销毁ros接口并发放奖励
        bytes32 _id = RosManager.burnRosIn(msg.sender, balanceEth);
        //验证dydxManager是否已注册
        require(dydxAccount[dydxManager]==true,"dydx account is not registered");

        //将建仓金额打入到dydx操作账户中
        payable(dydxManager).transfer(msg.value);

        //触发建仓事件
        emit OpenPositionLog(_id,msg.sender,dydxManager,balanceEth,block.timestamp);
    }


    //    function outPosition()isPermission public{
    //
    //    }


    receive() external payable {}
}