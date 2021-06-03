/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: SimPL-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

interface IERC20 {
    // 代币名称
    function name() external view returns (string memory);

    // 代币缩写--符号
    function symbol() external view returns (string memory);

    // 代币小数位数
    function decimals() external view returns (uint8);

    // 代币总数
    function totalSupply() external view returns (uint);

    // 账户余额
    function balanceOf(address _addr) external view returns (uint);

    // 交易的发起方(谁调用这个方法，谁就是交易的发起方)把_value数量的代币发送到_to账户
    function transfer(address _to, uint _value) external returns (bool);

    // 从_from账户里转出_value数量的代币到_to账户
    function transferFrom(address _from, address _to, uint _value) external returns (bool);

    // 交易的发起方把_value数量的代币的使用权交给_spender
    // 然后_spender才能调用transferFrom方法把我账户里的钱转给另外一个人
    function approve(address _spender, uint _value) external returns (bool);

    // 查询_spender目前还有多少_owner账户代币的使用权
    function allowance(address _owner, address _spender) external view returns (uint);
}

interface IUniswapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
}

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapRouterV2{
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function WETH() external pure returns (address);

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external view returns (uint[] memory amounts);
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

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, msg.sender), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, msg.sender), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual {
        require(account == msg.sender, "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    modifier roleCheck(bytes32 role) {
        require(hasRole(role, msg.sender), "ROSMANAGE:DON'T_HAVE_PERMISSION");
        _;
    }
}

contract CommunityLiquidityData is AccessControl {
    using SafeMath for uint;
    bytes32 public constant ADMIN_ROLE = 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42; // keccak256("ADMIN")
    bytes32 public constant REWARD_ROLE = 0x0b9821ae606ebc7c79bf3390bdd3dc93e1b4a7cda27aad60646e7b88ff55b001; // keccak256("REWARD")
    bytes32 public constant VOTE_ROLE = 0x03ad3ebd1a64c869d637fb0a425b368606ea3968a5cc7cb533a3955395955fd2; //keccak256("VOTE")
    // 用户白名单
    EnumerableSet.AddressSet userList;

    // 用户流动性凭证数量
    mapping(address => uint) public userLiquidity;
    // 授权记录
    mapping(address => mapping(address => bool)) approveRecord;

    // 全部参与流动性数量
    uint public liquidityNum;

    address public rosAddress;
    address public WETH;
    address public USDC;
    address public uniswapAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public uniswapPairAddress;
    address public uniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    uint rewardNum;
    uint public rewardId;
    mapping(uint => mapping(address => uint)) public receiveReward;

    uint public addLiquidityBeginTime; // 添加流动性最后时间
    uint public addLiquidityLastTime; // 添加流动性最后时间
    uint public removeLiquidityBeginTime; // 赎回流动性开始时间
    uint public removeLiquidityLastTime; // 赎回流动性最后时间
    uint public removeLiquidityRate; // 赎回流动性比例  百分之
    uint public LiquiditySlippage = 10; // 赎回流动性滑移  千分之
    mapping(uint => mapping(address => bool)) public removeLiquidityRecord;

    uint public charge = 0.1 ether;
    uint public chargeTotal;
    uint public initEther;
    uint public initRosRate = 3000;
    mapping(address => uint) public initUserEther;

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(VOTE_ROLE, msg.sender);
        _setupRole(VOTE_ROLE, address(this));
    }

    function setUSDC(address _usdc) public roleCheck(ADMIN_ROLE) {
        USDC = _usdc;
    }

    function setWETH(address _weth) public roleCheck(ADMIN_ROLE) {
        WETH = _weth;
    }

    function setRemoveLiquidityData(uint _beginTime, uint _lastTime, uint _rate) public roleCheck(VOTE_ROLE) {
        require(_rate > 0 && _rate <= 100, "OUT_RANGE");
        removeLiquidityLastTime = _lastTime;
        removeLiquidityBeginTime = _beginTime;
        removeLiquidityRate = _rate;
    }

    function setAddLiquidityLastTime(uint _beginTime, uint _lastTime) public roleCheck(VOTE_ROLE) {
        addLiquidityLastTime = _lastTime;
        addLiquidityBeginTime = _beginTime;
    }

    function setCharge(uint _charge) external roleCheck(ADMIN_ROLE) {
        charge = _charge;
    }

    function setInitRosRate(uint _rate) external roleCheck(ADMIN_ROLE) {
        initRosRate = _rate;
    }

    function setUniswapAddress(address _addr) external roleCheck(ADMIN_ROLE) {
        uniswapAddress = _addr;
    }

    function setRosAddress(address _addr) external roleCheck(ADMIN_ROLE) {
        rosAddress = _addr;
    }

    function setPairAddress() public roleCheck(ADMIN_ROLE) {
        uniswapPairAddress = IUniswapFactory(uniswapFactoryAddress).getPair(rosAddress, WETH);
    }

    function setUserListEnable(address _addr, bool _enable) public roleCheck(VOTE_ROLE) {
        if (_enable) {
            userList.add(_addr);
        } else {
            userList.remove(_addr);
        }
    }
}

contract CommunityVote is CommunityLiquidityData {
    struct Vote {
        address _addr;
        address _sender;
        uint _lastTime;
        uint forVotes;
        uint againstVotes;
        bool isCarry;
        bool isSucc;
        bytes _callData;
        string _title;
    }
    uint voteRete = 90; // 投票成功比例
    uint public voteId = 1;
    mapping(uint => Vote) public voteData;
    struct voteRecordData {
        bool isVote;
        bool voteRes;
    }
    mapping(uint => mapping(address => voteRecordData)) public takeVoteRecord;

    event VoteLog(uint _id, uint _voteEndTime, uint _beginTime, uint _lastTime, string _title, string _describe);

    function setVoteRete(uint _rate) external roleCheck(ADMIN_ROLE) {
        voteRete = _rate;
    }

    function sponsorVote(
        string memory _signature,
        uint _endTime,
        uint _beginTime,
        uint _lastTime,
        address _callAddr,
        string memory _title,
        string memory _describe,
        bytes memory _callData
    ) external {
        require(userList.contains(msg.sender), "NOT_ON_THE_WHITELIST");
        bytes memory _cd = abi.encodePacked(bytes4(keccak256(bytes(_signature))), _callData);
        Vote memory _data = Vote(_callAddr, msg.sender, _endTime, 0, 0, false, false, _cd, _title);
        uint _id = voteId;
        voteId = voteId.add(1);
        voteData[_id] = _data;
        emit VoteLog(_id, _endTime, _beginTime, _lastTime, _title, _describe);
    }

    function takeVote(uint _id, bool _support) external {
        voteRecordData memory _voteData = takeVoteRecord[_id][msg.sender];
        require(!_voteData.isVote, "REPEAT_TAKE");
        require(voteData[_id]._addr != address(0), "NONENTITY_VOTE");
        require(userList.contains(msg.sender), "NOT_ON_THE_WHITELIST");
        if (_support) {
            voteData[_id].forVotes = voteData[_id].forVotes.add(1);
        } else {
            voteData[_id].againstVotes = voteData[_id].againstVotes.add(1);
        }
        _voteData.isVote = true;
        _voteData.voteRes = _support;
        takeVoteRecord[_id][msg.sender] = _voteData;
    }

    function carryVote(uint _id) external {
        Vote memory _vote = voteData[_id];
        require(block.timestamp >= _vote._lastTime, "VOTE_DO_NOT_END");
        require(!_vote.isCarry, "REPETITION_CARRY");
        uint _totalVote = _vote.forVotes.add(_vote.againstVotes);
        _vote.isCarry = true;
        if (_totalVote > 0 && _totalVote.mul(voteRete).div(100) <= _vote.forVotes) {
            (bool success,) = _vote._addr.call(_vote._callData);
            _vote.isSucc = success;
        }
        voteData[_id] = _vote;
    }
}

contract CommunityLiquidityView is CommunityVote {
    function isWhitelist(address _addr) external view returns (bool) {
        return userList.contains(_addr);
    }

    function getAmountsOutRos2Usdc(
        uint _tokenNum
    ) external view returns (uint) {
        address[] memory addr = new address[](2);
        addr[0] = WETH;
        addr[1] = USDC;
        uint[] memory amounts = IUniswapRouterV2(uniswapAddress).getAmountsOut(_tokenNum, addr);
        return amounts[1];
    }

    function getLiquidityDetail(address _addr) external view returns (uint _total, uint _contractTotal, uint _myNum) {
        _total = IERC20(uniswapPairAddress).totalSupply();
        _contractTotal = liquidityNum;
        _myNum = userLiquidity[_addr];
    }

    function getAllUser() public view returns (address[] memory) {
        uint _len = userList.length();
        address[] memory res = new address[](_len);
        for (uint i = 0; i < _len; i++) {
            res[i] = userList.at(i);
        }
        return res;
    }

    function existPair() public view returns (bool) {
        return uniswapPairAddress == address(0);
    }

    function getUniswapReserves() public view returns (uint112 rosReserve, uint112 ethReserve, uint32 blockTimestampLast) {
        if (getUniswapToken0Address() == rosAddress) {
            (rosReserve, ethReserve, blockTimestampLast) = IUniswapPair(uniswapPairAddress).getReserves();
        } else {
            (ethReserve, rosReserve, blockTimestampLast) = IUniswapPair(uniswapPairAddress).getReserves();
        }
    }

    function getUniswapToken0Address() public view returns (address) {
        return IUniswapPair(uniswapPairAddress).token0();
    }

    function getUniswapToken1Address() public view returns (address) {
        return IUniswapPair(uniswapPairAddress).token1();
    }


    function getLiquidityProofAmount(address _sender) public view returns (uint _balance, uint _totalSupply) {
        _balance = userLiquidity[_sender];
        _totalSupply = IERC20(uniswapPairAddress).totalSupply();
    }

    function getRemoveLiquidityETHData(
        address _account,
        uint _slippage
    ) public view returns (uint amountTokenMin, uint amountETHMin) {
        (uint112 rosReserve, uint112 ethReserve,) = getUniswapReserves();

        (uint _balance, uint _totalSupply) = getLiquidityProofAmount(_account);

        uint _liquidity = _balance.mul(removeLiquidityRate).div(100);
        uint amountToken = uint(rosReserve).mul(_liquidity).div(_totalSupply);
        uint amountETH = uint(ethReserve).mul(_liquidity).div(_totalSupply);
        amountTokenMin = getSlippage(amountToken, _slippage);
        amountETHMin = getSlippage(amountETH, _slippage);
    }

    function getSlippage(uint _tokenNum, uint _slippage) internal pure returns (uint) {
        return _tokenNum.sub(_tokenNum.mul(_slippage).div(1000));
    }

    function getAddUniLiquidityDataETH2Ros(
        uint _eth,
        uint _slippage
    ) public view returns (uint _ethNum, uint _rosNum, uint _ethNumMin, uint _rosNumMin) {
        (uint112 _rosReserve, uint112 _ethReserve,) = getUniswapReserves();
        uint rosReserve  = uint(_rosReserve);
        uint ethReserve  = uint(_ethReserve);
        _ethNum = _eth;
        _rosNum = _ethNum.mul(rosReserve).div(ethReserve);
        _ethNumMin = getSlippage(_ethNum, _slippage);
        _rosNumMin = getSlippage(_rosNum, _slippage);
    }

    function getAddUniLiquidityDataRos2ETH(
        uint _ros,
        uint _slippage
    ) public view returns (uint _ethNum, uint _rosNum, uint _ethNumMin, uint _rosNumMin) {
        (uint112 _rosReserve, uint112 _ethReserve,) = getUniswapReserves();
        uint rosReserve  = uint(_rosReserve);
        uint ethReserve  = uint(_ethReserve);
        _rosNum = _ros;
        _ethNum = _rosNum.mul(ethReserve).div(rosReserve);
        _ethNumMin = getSlippage(_ethNum, _slippage);
        _rosNumMin = getSlippage(_rosNum, _slippage);
    }
}

contract CommunityLiquidity is CommunityLiquidityView {
    event AddLiquidityLog(address addr, uint rosNum, uint EthNum, uint _time);
    event RemoveLiquidityLog(address addr, uint rosNum, uint EthNum, uint _time);

    constructor(address _ros, address _usdc, uint _endTime, address[] memory _userList) public {
        addLiquidityLastTime = _endTime;
        rosAddress = _ros;
        setPairAddress();
        USDC = _usdc;
        WETH = IUniswapRouterV2(uniswapAddress).WETH();
        uint _len = _userList.length;
        for (uint i = 0; i < _len; i++) {
            setUserListEnable(_userList[i], true);
        }
    }

    function approve(address _addr, uint _amount) external roleCheck(VOTE_ROLE) {
        IERC20(uniswapPairAddress).approve(_addr, _amount);
    }

    function initLiquidity() external payable {
        require(uniswapPairAddress == address(0), "LIQUIDITY_EXIST");
        require(block.timestamp <= addLiquidityLastTime, "ADD_LIQUIDITY_END");

        uint _value = msg.value;
        uint _charge = charge;
        uint _initValue = _value.sub(_charge);
        require(_initValue > 0, "INJECT_SMALL");
        require(userList.contains(msg.sender), "NOT_ON_THE_WHITELIST");
        uint _rate = initRosRate;
        uint _intiRos = _initValue.mul(_rate);
        require(IERC20(rosAddress).transferFrom(msg.sender, address(this), _intiRos), "ROS_NOT_APPROVE");

        chargeTotal = chargeTotal.add(_charge);
        initUserEther[msg.sender] = initUserEther[msg.sender].add(_initValue);
        initEther = initEther.add(_initValue);
        emit AddLiquidityLog(msg.sender, _initValue.mul(_rate), _initValue, block.timestamp);
    }

    function createLiquidity() external roleCheck(ADMIN_ROLE) returns (uint amountToken, uint amountETH, uint liquidity) {
        require(block.timestamp >= addLiquidityLastTime, "ADD_LIQUIDITY_NO_END");
        payable(msg.sender).transfer(chargeTotal);
        chargeTotal = 0;
        uint _initEth = initEther;
        uint _rate = initRosRate;
        uint rosNum = _initEth.mul(_rate);

        uint _slippage = LiquiditySlippage;
        (amountToken, amountETH, liquidity) = _addUniLiquidityETH(
            rosNum,
            _initEth,
            getSlippage(_initEth, _slippage),
            getSlippage(rosNum, _slippage),
            address(this),
            block.timestamp.add(200)
        );

        liquidityNum = liquidity;
        initEther = 0;
        initRosRate = 0;

        address[] memory userList = getAllUser();
        uint _len = userList.length;
        for (uint i = 0; i < _len; i++) {
            uint userEthNum = initUserEther[userList[i]];
            userLiquidity[userList[i]] = liquidity.mul(userEthNum).div(_initEth);
            initUserEther[userList[i]] = 0;
        }

        uniswapPairAddress = IUniswapFactory(uniswapFactoryAddress).getPair(rosAddress, WETH);
    }

    function receiveRosReward(uint amount) external roleCheck(REWARD_ROLE) {
        rewardId = rewardId.add(1);
        rewardNum = amount;
    }

    // 领取奖励
    function carveUpReward() external {
        uint _rId = rewardId;

        require(receiveReward[_rId][msg.sender] == 0, "REPETITION_RECEIVE");
        uint _userLiquidity = userLiquidity[msg.sender];
        require(_userLiquidity > 0, "NO_LIQUIDITY");

        uint _rewardTotal = rewardNum;
        uint _reward = _rewardTotal.mul(_userLiquidity).div(liquidityNum);
        IERC20(rosAddress).transfer(msg.sender, _reward);

        receiveReward[_rId][msg.sender] = _reward;
    }

    function addUniLiquidityETH(
        uint _rosNum,
        uint _ethNumMin,
        uint _rosNumMin,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        address _account = msg.sender;
        require(block.timestamp >= addLiquidityBeginTime, "ADD_LIQUIDITY_TIME_LOCK");
        require(block.timestamp <= addLiquidityLastTime, "ADD_LIQUIDITY_TIME_LOCK");
        require(userList.contains(_account), "NOT_ON_THE_WHITELIST");
        require(IERC20(rosAddress).transferFrom(_account, address(this), _rosNum), "NOT_APPROVE_ROS");
        (amountToken, amountETH, liquidity) = _addUniLiquidityETH(_rosNum, msg.value, _ethNumMin, _rosNumMin, address(this), deadline);

        uint _diff = _rosNum.sub(amountToken);
        if (_diff > 0) {
            IERC20(rosAddress).transfer(_account, _diff);
        }

        liquidityNum = liquidityNum.add(liquidity);
        userLiquidity[msg.sender] = userLiquidity[msg.sender].add(liquidity);
        emit AddLiquidityLog(_account, amountToken, amountETH, block.timestamp);
    }

    function _addUniLiquidityETH(
        uint _rosNum,
        uint _ethNum,
        uint _ethNumMin,
        uint _rosNumMin,
        address _to,
        uint deadline
    ) internal returns (uint amountToken, uint amountETH, uint liquidity) {
        address _ros = rosAddress;
        address _uni = uniswapAddress;
        if (!approveRecord[_ros][_uni]) {
            if (IERC20(_ros).approve(_uni, 1e66)) {
                approveRecord[_ros][_uni] = true;
            } else {
                revert("APPROVE_FIELD");
            }
        }

        (amountToken, amountETH, liquidity) = IUniswapRouterV2(_uni).addLiquidityETH{value:_ethNum}(
            rosAddress,
            _rosNum,
            _rosNumMin,
            _ethNumMin,
            _to,
            deadline
        );
    }

    function removeUniswapLiquidityETH() external returns (uint amountToken, uint amountETH) {
        uint _removeTime = removeLiquidityLastTime;
        require(!removeLiquidityRecord[_removeTime][msg.sender], "REPETITION_REMOVE");
        uint _userLiquidity = userLiquidity[msg.sender];
        require(_userLiquidity > 0, "NO_LIQUIDITY");
        require(block.timestamp <= _removeTime, "REMOVE_LIQUIDITY_TIME_LOCK");
        require(block.timestamp >= removeLiquidityBeginTime, "REMOVE_LIQUIDITY_TIME_LOCK");
        uint removeLiauidity = _userLiquidity.mul(removeLiquidityRate).div(100);

        (uint amountTokenMin, uint amountETHMin) = getRemoveLiquidityETHData(msg.sender, LiquiditySlippage);
        (amountToken, amountETH) = removeUniswapLiquidityETH(msg.sender, removeLiauidity, amountTokenMin, amountETHMin, block.timestamp.add(200));

        liquidityNum = liquidityNum.sub(removeLiauidity);
        userLiquidity[msg.sender] = userLiquidity[msg.sender].sub(removeLiauidity);
        removeLiquidityRecord[_removeTime][msg.sender] = true;

        emit RemoveLiquidityLog(msg.sender, amountToken, amountETH, block.timestamp);
    }

    function removeUniswapLiquidityETH(
        address _account,
        uint _liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline
    ) internal returns (uint amountToken, uint amountETH) {
        address _pair = uniswapPairAddress;
        address _uni = uniswapAddress;
        if (!approveRecord[_pair][_uni]) {
            if (IERC20(_pair).approve(_uni, 1e66)) {
                approveRecord[_pair][_uni] = true;
            } else {
                revert("APPROVE_FIELD");
            }
        }

        IUniswapRouterV2 uniswapRouter = IUniswapRouterV2(_uni);
        (amountToken, amountETH) = uniswapRouter.removeLiquidityETH(
            rosAddress,
            _liquidity,
            amountTokenMin,
            amountETHMin,
            _account,
            deadline
        );
    }

    function destroy() external roleCheck(ADMIN_ROLE) {
        IERC20 _ros = IERC20(rosAddress);
        uint _balance = _ros.balanceOf(address(this));
        if (_balance > 0) {
            _ros.transfer(msg.sender, _balance);
        }

        IERC20 _pair = IERC20(uniswapPairAddress);
        uint _pairBalance = _pair.balanceOf(address(this));
        if (_pairBalance > 0) {
            _pair.transfer(msg.sender, _pairBalance);
        }

        selfdestruct(msg.sender);
    }

    receive() external payable {}
}