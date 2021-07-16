//SourceUnit: moka_verify.sol

pragma solidity ^0.5.12;

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

library MokaLibrary {
    using SafeMath for uint;
    
    uint private constant USDT_RATE = 1e6;
    
    // min to USDT
    function toUsdt(uint _value) internal pure returns (uint) {
        return _value / USDT_RATE;
    }
    
    // USDT to min
    function usdtTo(uint _value) internal pure returns (uint) {
        return _value.mul(USDT_RATE);
    }
    
    // 计算用户的teamLevel
    function computeTeamLevel(uint _teamMenberNum) internal pure returns (uint _teamLevel) {
        if (_teamMenberNum >= 10 && _teamMenberNum < 20) {
            _teamLevel = 1;
        } else if (_teamMenberNum >= 20 && _teamMenberNum < 30) {
            _teamLevel = 2;
        } else if (_teamMenberNum >= 30 && _teamMenberNum < 50) {
            _teamLevel = 3;
        } else if (_teamMenberNum >= 50 && _teamMenberNum < 100) {
            _teamLevel = 4;
        } else if (_teamMenberNum >= 100 && _teamMenberNum < 200) {
            _teamLevel = 5;
        } else if (_teamMenberNum >= 200 && _teamMenberNum < 300) {
            _teamLevel = 6;
        } else if (_teamMenberNum >= 300 && _teamMenberNum < 500) {
            _teamLevel = 7;
        } else if (_teamMenberNum >= 500 && _teamMenberNum < 1000) {
            _teamLevel = 8;
        } else if (_teamMenberNum >= 1000 && _teamMenberNum < 2000) {
            _teamLevel = 9;
        } else if (_teamMenberNum >= 2000 && _teamMenberNum < 4000) {
            _teamLevel = 10;
        } else if (_teamMenberNum >= 4000 && _teamMenberNum < 6000) {
            _teamLevel = 11;
        } else if (_teamMenberNum >= 6000 && _teamMenberNum < 8000) {
            _teamLevel = 12;
        } else if (_teamMenberNum >= 8000 && _teamMenberNum < 10000) {
            _teamLevel = 13;
        } else if (_teamMenberNum >= 10000 && _teamMenberNum < 30000) {
            _teamLevel = 14;
        } else if (_teamMenberNum >= 30000 && _teamMenberNum < 50000) {
            _teamLevel = 15;
        } else if (_teamMenberNum >= 50000 && _teamMenberNum < 100000) {
            _teamLevel = 16;
        } else if (_teamMenberNum >= 100000 && _teamMenberNum < 200000) {
            _teamLevel = 17;
        } else if (_teamMenberNum >= 200000 && _teamMenberNum < 300000) {
            _teamLevel = 18;
        } else if (_teamMenberNum >= 300000 && _teamMenberNum < 500000) {
            _teamLevel = 19;
        } else if (_teamMenberNum >= 500000) {
            _teamLevel = 20;
        }
    }
    
}

interface ITRC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    
    function transfer(address _to, uint _value) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint);
    
    function burn(uint _value) external returns (bool);
    function burnFrom(address _from, uint _value) external returns (bool);
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Moka {
    using SafeMath for uint;
    // TODO
    address public constant USDT_ADDR = address(0x41A614F803B6FD780986A42C78EC9C7F77E6DED13C);
    address public owner;
    // TODO
    uint private constant WHEEL_TIME = 10*24*60*60;
    // uint private constant WHEEL_TIME = 1*60;
    
    constructor(address _owner) public {
        owner = _owner;
    }
    
    // 用户信息
    struct Player {
        uint id;                            // 用户id
        address addr;                       // 用户地址
        uint referrerId;                    // 推荐人(上一级)id：0表示没有推荐人(上一级)
        uint[] oneFriends;                  // 1代好友列表，存放的是id
        uint[] orderIds;                    // 所有订单id
        uint wheelNum;                      // 用户的轮数(第几轮)，每一轮只能投资一次，所以轮数也等于用户的总订单数
        uint totalAmt;                      // 用户的总投资额
        uint uBalance;                      // 用户的可提现余额
        uint teamMemberNum;                 // 用户的团队的有效成员数
        uint teamLevel;                     // 团队等级
        uint teamProfit;                    // 团队总收益
        uint teamAmt;                       // 团队业绩
        uint dyAmt;                       // 动态总收益dy
        uint[] profitAmts;            
    }
    uint public playerCount;                // 用户id，自增长
    mapping(address => uint) public playerAddrMap;    // 用户地址 => 用户id
    mapping(uint => Player) public playerMap;         // 用户id => 用户信息
    
    struct Order {
        uint id;                // 订单id
        uint playerId;          // 用户id
        uint orderAmt;          // 订单金额
        uint status;            // 订单状态(0进行中，2已返回(订单已结束))
        uint time;
    }
    uint public orderCount;                 // 订单id，自增长
    mapping(uint => Order) public orderMap; // 订单id => 订单信息
    
    uint public total;     // 所有用户的总投资额
    event Withdraw(address indexed _msgSender, uint _value);
    event Buy(address indexed _msgSender, uint _value, address _referrerAddr);
    
    function getOneFriends() external view returns (uint[] memory) {
        return getOneFriendsById(playerAddrMap[msg.sender]);
    }
    
    function getOneFriendsById(uint _id) public view returns (uint[] memory) {
        return playerMap[_id].oneFriends;
    }
    
    function getOrderIds() external view returns (uint[] memory) {
        return getOrderIdsById(playerAddrMap[msg.sender]);
    }
    
    function getOrderIdsById(uint _id) public view returns (uint[] memory) {
        return playerMap[_id].orderIds;
    }
    
    function getProfitAmtsById(uint _id) public view returns (uint[] memory) {
        return playerMap[_id].profitAmts;
    }
    
    function buy(uint _amount, address _referrerAddr) lock external {
        // 减去2%的手续费即是投资额
        uint _value = _amount.mul(100)/102;
        require(_value >= MokaLibrary.usdtTo(200));
        require(_value % MokaLibrary.usdtTo(100) == 0);
        require(ITRC20(USDT_ADDR).transferFrom(msg.sender, address(this), _amount));
        ITRC20(USDT_ADDR).transfer(owner, _amount.sub(_value));
        
        uint _id = _register(msg.sender);
        // 如果不是第一轮，则本次的投资额要大于等于上一次的投资额
        _wheelNumJudge(_id, _value, playerMap[_id].wheelNum);
        
        if (msg.sender != _referrerAddr) {
            _saveReferrerInfo(_id, _referrerAddr);  // 保存推荐人信息
        }
        
        uint _orderId = _saveOrder(_id, _value);
        playerMap[_id].orderIds.push(_orderId);
        playerMap[_id].totalAmt = playerMap[_id].totalAmt.add(_value);
        
        // 计算上级用户的动态奖
        _computeSuperiorUserDynamicAwartAmt(_id, _value);
        // 计算上级用户的团队奖
        _computeSuperiorUserTeamAwartAmt(_id, playerMap[_id].teamLevel, 
            _amount.sub(_value), playerMap[_id].wheelNum, 0, _id, _value);
        
        playerMap[_id].wheelNum++;
        total = total.add(_value);
        emit Buy(msg.sender, _value, _referrerAddr);
    }
    
    // 计算上级用户的团队奖
    function _computeSuperiorUserTeamAwartAmt(
        uint _id, 
        uint _biggestTeamLevel, 
        uint _fee, 
        uint _wheelNum,
        uint _count,
        uint _playerId,
        uint _playerValue
    ) private {
        uint _referrerId = playerMap[_id].referrerId;
        if (_referrerId == 0) {
            return;
        }
        if (_count >= 2000) {
            return;
        }
        uint _teamLevel = playerMap[_referrerId].teamLevel;
        if (_wheelNum == 0) { // 表示是个新用户
            playerMap[_referrerId].teamMemberNum++;
            // 计算用户的teamLevel
            uint _teamLevel2 = MokaLibrary.computeTeamLevel(playerMap[_referrerId].teamMemberNum);
            if (_teamLevel2 > _teamLevel) {
                // _teamLevel = _teamLevel2;
                playerMap[_referrerId].teamLevel = _teamLevel2;
            }
        }
        if (_teamLevel > _biggestTeamLevel) {
            uint _amount = _fee.mul(_teamLevel.sub(_biggestTeamLevel)).mul(5)/100;
            _addBalance(_referrerId, _amount);
            playerMap[_referrerId].teamProfit = playerMap[_referrerId].teamProfit.add(_amount);
            _biggestTeamLevel = _teamLevel;
        }
        playerMap[_referrerId].teamAmt = playerMap[_referrerId].teamAmt.add(_playerValue);
        _count++;
        _computeSuperiorUserTeamAwartAmt(_referrerId, _biggestTeamLevel, _fee, _wheelNum, _count, _playerId, _playerValue);
    }
    
    
    
    // 计算上级用户的动态奖
    function _computeSuperiorUserDynamicAwartAmt(uint _id, uint _value) private {
        // 用户的一级直推人
        uint _referrerId = playerMap[_id].referrerId;
        if (_referrerId > 0) {
            if (playerMap[_id].profitAmts.length == 0) {
                playerMap[_id].profitAmts = new uint[](2);
            }
            
            uint _baseAmt1 = _value;
            // uint _totalAmt1 = playerMap[_referrerId].totalAmt;
            uint[] memory _orderIds = playerMap[_referrerId].orderIds;
            uint _totalAmt1 = orderMap[_orderIds[_orderIds.length - 1]].orderAmt;
            if (_baseAmt1 > _totalAmt1) {
                _baseAmt1 = _totalAmt1;
            }
            uint _amount1 = _baseAmt1.mul(5)/100;
            playerMap[_id].profitAmts[0] = _amount1;
            _addBalance(_referrerId, _amount1);
            playerMap[_referrerId].dyAmt = playerMap[_referrerId].dyAmt.add(_amount1);
            
            // 用户的二级直推人
            uint _referrerId2 = playerMap[_referrerId].referrerId;
            if (_referrerId2 > 0) {
                uint _baseAmt2 = _value;
                // uint _totalAmt2 = playerMap[_referrerId2].totalAmt;
                uint[] memory _orderIds2 = playerMap[_referrerId2].orderIds;
                uint _totalAmt2 = orderMap[_orderIds2[_orderIds2.length - 1]].orderAmt;
                if (_baseAmt2 > _totalAmt2) {
                    _baseAmt2 = _totalAmt2;
                }
                uint _amount2 = _baseAmt2.mul(2)/100;
                playerMap[_id].profitAmts[1] = _amount2;
                _addBalance(_referrerId2, _amount2);
                playerMap[_referrerId2].dyAmt = playerMap[_referrerId2].dyAmt.add(_amount2);
            }
        }
    }
    
    // 如果不是第一轮，则本次的投资额要大于等于上一次的投资额
    function _wheelNumJudge(uint _id, uint _value, uint _wheelNum) private {
        if (_wheelNum == 0) {
            require(_value <= MokaLibrary.usdtTo(5000));
        } else {
            if (_wheelNum == 1) {
                require(_value <= MokaLibrary.usdtTo(20000));
            } else {
                require(_value <= MokaLibrary.usdtTo(50000));
            }
            uint[] memory _orders = playerMap[_id].orderIds;
            require(_orders.length == _wheelNum);
            uint _lastOrderId = _orders[_orders.length - 1]; // 需要结算的订单
            require(_value >= orderMap[_lastOrderId].orderAmt);
            require(block.timestamp >= orderMap[_lastOrderId].time.add(WHEEL_TIME));
            
            // 结算用户的上一笔订单
            orderMap[_lastOrderId].status = 2;
            uint _amount = orderMap[_lastOrderId].orderAmt.mul(115)/100;
            if (_wheelNum > 8) {
                _amount = orderMap[_lastOrderId].orderAmt.mul(113)/100;
            }
            ITRC20(USDT_ADDR).transfer(playerMap[_id].addr, _amount);
        }
    }
    
    
    // 保存订单信息
    function _saveOrder(uint _playerId, uint _value) internal returns(uint) {
        orderCount ++;
        uint _orderId = orderCount;
        orderMap[_orderId] = Order(_orderId, _playerId, _value, 0, block.timestamp);
        return _orderId;
    }
    
    // 保存推荐人信息
    function _saveReferrerInfo(uint _id, address _referrerAddr) internal {
        uint _referrerId = playerAddrMap[_referrerAddr];
        // playerMap[_id].allCirculationAmt == 0 这个条件是为了防止形成邀请关系的闭环
        if (_referrerId > 0 && playerMap[_id].referrerId == 0 && playerMap[_id].totalAmt == 0) {
            playerMap[_id].referrerId = _referrerId;
            playerMap[_referrerId].oneFriends.push(_id);
        }
    }
    
    // 注册
    function _register(address _sender) internal returns (uint _id) {
        _id = playerAddrMap[_sender];
        if (_id == 0) {   // 未注册
            playerCount++;
            _id = playerCount;
            playerAddrMap[_sender] = _id;
            playerMap[_id].id = _id;
            playerMap[_id].addr = _sender;
        }
    }
    
    function _addBalance(uint _id, uint _value) private {
        playerMap[_id].uBalance = playerMap[_id].uBalance.add(_value);
    }
    
    function withdraw() external returns (bool flag) {
        uint _id = playerAddrMap[msg.sender];
        require(_id > 0, "user is not exist");
        uint _uBalance = playerMap[_id].uBalance;
        require(_uBalance > 0, "Insufficient balance");
        playerMap[_id].uBalance = 0;
        playerMap[_id].teamProfit = 0;
        playerMap[_id].dyAmt = 0;
        ITRC20(USDT_ADDR).transfer(msg.sender, _uBalance);
        flag = true;
        emit Withdraw(msg.sender, _uBalance);
    }
    
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "is not owner");
        _;
    }
    
    function setOwner(address _addr) external isOwner {
        owner = _addr;
    }
}