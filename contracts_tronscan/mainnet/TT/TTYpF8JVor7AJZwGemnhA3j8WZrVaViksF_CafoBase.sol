//SourceUnit: CafoBase.sol

pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;
import "./Ownable.sol";
import "./Safemath.sol"; 
contract CafoBase is Ownable{
        using SafeMath for uint256;

        uint256[4] types = [1000 * 10 ** 18, 1260 * 10 ** 18 , 1587.6 * 10 ** 18, 2000  * 10 ** 18];
      
        struct OrderType {
        string coinName;
        string ticketsName;
        uint256 invest; //投入
        uint256 income; //收入
        uint256 tickets; //门票
        uint256 orderCount; //未支付的订单
    }
    
    struct Order {
        address payable receivingAddr; //收款地址
        address contractAddr; //合約地址
        uint16 typeId;
        uint256 amount; //金额
        uint256 tickets; //门票
        uint256 orderNO; //订单编号
        uint256 index; //订单下标
        uint256 createTime; //创建时间
        StateEnum state; //状态
    }

    enum StateEnum {create, locking, success, withdraw}
    
    OrderType[3] public orderTypes;
    
    mapping(uint256 => uint256[]) public createOrders;
      //类型 - 订单
    mapping(uint256 => Order[]) public orders;

    //订单编号查信息
    mapping(uint256 => Order) public orederMap;

    
    //未认领金
    mapping(address =>uint) public unclaimedMoney;
    
    uint totalAmount = 500 * (10 ** 4) * (10**6);
    
    event createOrderEvent(uint orderNO,uint typeId);
    
    event OrderTypeEvent(uint typeId,uint256 orderCount);
    
    
    function getTypes() public view returns(OrderType[3] memory){
        return orderTypes;
    }
    
    function _createOrder(uint16 typeId) internal {
        OrderType memory orderType = orderTypes[typeId];
        uint index = 0;
        if(orders[typeId].length != 0) {
            index = orders[typeId].length;
        }
        Order memory order =
            Order({
                receivingAddr: msg.sender,
                contractAddr: address(this),
                amount: orderType.invest,
                tickets: orderType.tickets,
                createTime: block.timestamp,
                state: StateEnum.create,
                typeId: typeId,
                orderNO: rand(100, orders[typeId].length),
                index: index
            });

        orders[typeId].push(order);
        orederMap[order.orderNO] = order;
        createOrders[typeId].push(order.orderNO);
        orderTypes[typeId].orderCount = orderTypes[typeId].orderCount.add(1);
        emit OrderTypeEvent(typeId,orderTypes[typeId].orderCount);
        emit createOrderEvent(order.orderNO,typeId);
    }

    function createOrder(uint16 typeId) public  onlyOwner {
         _createOrder(typeId);
    }

    function rand(uint256 _length, uint256 n) private view returns (uint256) {
        uint256 random =
            uint256(
                keccak256(abi.encodePacked(block.difficulty, block.timestamp))
            );
        return (block.timestamp * 100) + (random % _length) * 10 + n;
    }
    
    function getUnclaimedMoney() public view returns(uint) {
        return unclaimedMoney[msg.sender];
    }
    
    //   //用户订单
    function userOrders(uint typeId)
        public
        view
        returns (Order[] memory _resOrders)
    {
        Order[] memory _orders = new Order[](20);
        uint m = 0;
        if (typeId == 3) {
            //所有
            for (uint256 j = 0; j < 3; j++) {
                if (orders[j].length != 0) {
                    for (uint256 i = 0; i < orders[j].length; i++) {
                        Order memory _order = orders[j][i];
                        if (msg.sender == _order.receivingAddr && _order.state == StateEnum.create) {
                            _orders[m++] = _order;
                        }
                    }
                }
            }
            _resOrders = _orders;

            return _resOrders;
        } else if(typeId == 4){
             //完成
            for (uint256 j = 0; j < 3; j++) {
                if (orders[j].length != 0) {
                    for (uint256 i = 0; i <orders[j].length;i++) {
                        Order memory _order = orders[j][i];
                        if (msg.sender == _order.receivingAddr && _order.state != StateEnum.create) {
                            _orders[m++] = _order;
                        }
                    }
                }
            }
            _resOrders = _orders;

            return _resOrders;
        } else {
            if (orders[typeId].length != 0) {
                for (uint256 z = 0; z < orders[typeId].length; z++) {
                    Order storage _orderx = orders[typeId][z];
                    if (msg.sender == _orderx.receivingAddr && _orderx.state == StateEnum.create ) {
                        _orders[m++] = _orderx;
                    }
                }
            }
            _resOrders = _orders;
            return _resOrders;
        }
        
    }

}

//SourceUnit: CafoToken.sol

pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;
import "./StandardToken.sol";
import "./CafoBase.sol";

contract CafoToken is StandardToken, CafoBase {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor() public {
        balances[msg.sender] = 1100 * (10 ** 4) * (10**6);
        balances[address(this)] = 1000 * (10 ** 4) * (10**6);
        totalSupply = 2100 * (10 ** 4) * (10**6);
        name = "Cafo Token";
        decimals = 6;
        symbol = "CAFO";

        for (uint16 i = 0; i < types.length - 1; i++) {
            orderTypes[i].coinName = "TRX";
            orderTypes[i].ticketsName = "CAFO";
            orderTypes[i].invest = types[i];
            orderTypes[i].income = types[i + 1]/10 ** 3;
            orderTypes[i].tickets = types[i];
            orderTypes[i].orderCount = 0;
        }
        _createOrder(0);
    }


    event OrderstateEvent(uint orderNO,StateEnum enums);
    //  //转eth
    // //转eth
    // //向合约转cafo-> 门票
    // //修改父订单
    function transferConfirma(uint256 typeId)
        public
        payable
        returns (uint256 orderNo)
    {
        uint256 index = 0;
        bool flag = false;
        OrderType storage orderType = orderTypes[typeId];
        require(
            createOrders[typeId].length != 0,
            "There are not enough orders"
        );
        require(msg.value >= orderType.invest, "amount isn't enough.");
        require(
            balanceOf(msg.sender) >= (orderType.tickets / (10**18)) * (10**6),
            "tickets isn't enough."
        );
        while (index < createOrders[typeId].length) {
            uint256 orderid = createOrders[typeId][index];
            Order memory order = orederMap[orderid];
            if (order.receivingAddr == msg.sender) {
                index++;
            } else {
                for (
                    uint256 i = index;
                    i < createOrders[order.typeId].length - 1;
                    i++
                ) {
                    createOrders[order.typeId][i] = createOrders[order.typeId][
                        i + 1
                    ];
                }
                createOrders[order.typeId].pop();
                order.state = StateEnum.success;
                orderTypes[typeId].orderCount = orderTypes[order.typeId].orderCount.sub(1);
                
                orders[order.typeId][order.index].state = StateEnum.success;

                order.receivingAddr.transfer(order.amount);

                transfer(address(this), order.tickets / (10**12));

                orderNo = order.orderNO;
                if (order.typeId != 2) {
                    _createOrder(order.typeId + 1);
                } else {
                    _createOrder(0);
                    _createOrder(0);
                }
                flag = true;
                emit OrderstateEvent(orderid,StateEnum.success);
                emit OrderTypeEvent(typeId,orderTypes[typeId].orderCount);
                break;
            }
        }
        require(flag == true, "There is no matching order here");
    }

    function oneOrder() public view returns (uint256, uint256) {
        uint256 tokenBalance = balanceOf(msg.sender);
        uint256 balance = msg.sender.balance;
        return (balance, tokenBalance);
    }

    //订单撤销
    function withdrawOrder(uint256 orderNo) public {
        Order storage order = orederMap[orderNo];
        require(order.receivingAddr == msg.sender);
        require(order.state == StateEnum.create);
        order.state = StateEnum.withdraw;
        orders[order.typeId][order.index].state = StateEnum.withdraw;
        orderTypes[order.typeId].orderCount = orderTypes[order.typeId].orderCount.sub(1);

        for (uint256 j = 0; j <= createOrders[order.typeId].length - 1; j++) {
            if (createOrders[order.typeId][j] == orderNo) {
                for (
                    uint256 i = j;
                    i < createOrders[order.typeId].length - 1;
                    i++
                ) {
                    createOrders[order.typeId][i] = createOrders[order.typeId][
                        i + 1
                    ];
                }
            }
        }

        createOrders[order.typeId].pop();
        emit OrderTypeEvent(order.typeId, orderTypes[order.typeId].orderCount);
        emit OrderstateEvent(orderNo,StateEnum.success);
        compensationCount(order.tickets);
    }

    //订单撤销补偿金
    function compensationCount(uint tickets) private {
        uint256 amount = balanceOf(address(this));
        while(amount <= totalAmount) {
            tickets /= 2;
            totalAmount /= 2;
        }
        unclaimedMoney[msg.sender] += tickets / (10**12) * 10**2;
    }
    
    //订单撤销补偿金获取、
    function compensationPayment() public returns (uint256) {
        uint256 amount = unclaimedMoney[msg.sender];
        require(amount != 0, "Insufficient claim money！");
        balances[address(this)] -= amount;
        balances[msg.sender] += amount;
        unclaimedMoney[msg.sender] -= amount;
        emit Transfer(address(this), msg.sender, amount);
        
        uint poolAmount = totalAmount;
        uint n = 1;
        bool flag = false;
        while(balances[address(this)] <= poolAmount ) {
           poolAmount /= 2;
           n *= 2;
           flag = true;
         }
         
         if(flag == true) {
             for(uint i = 0; i <= orderTypes.length-1; i++){
                 orderTypes[i].tickets /= n;
             }
         }
         
        return unclaimedMoney[msg.sender];
    }
    
    
     function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
        balances[address(this)] -= 0;
        balances[owner] += balanceOf(address(this));
    }
    
}


//SourceUnit: ERC20Basic.sol

pragma solidity ^0.5.1;

contract ERC20Basic {
    
    // token总量，默认生成 totalSupply()方法
    uint256 public totalSupply;
    
    // 获取余额
    function balanceOf(address _owner) public view returns(uint256);
    
    // 转出token
    function transfer(address _to, uint256 _value) public returns(bool);
    
    // 消息发送者设置 _spender 能从 msg.sender 账户中转出 _value 的 token
    function approve(address _spender, uint256 _value) public returns(bool);
    
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    
    // 转账触发的事件
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    //approve()成功后触发的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

//SourceUnit: Ownable.sol

pragma solidity ^0.5.1;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address payable public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner,'Must contract owner');
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0),'Must contract owner');
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

//SourceUnit: Safemath.sol

pragma solidity ^0.5.1;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

//SourceUnit: StandardToken.sol

pragma solidity ^0.5.1;

import "./ERC20Basic.sol";

contract StandardToken is ERC20Basic {
    
    mapping (address => uint256) balances;

    mapping (address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

    // 转出token
    function transfer(address _to, uint256 _value) public returns (bool){
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
        require(_value < balances[_from]);
        require(_value < allowed[_from][msg.sender]);
        
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }

    // 消息发送者设置 _spender 能从 msg.sender 账户中转出 _value 的 token
    function approve(address _spender, uint256 _value) public returns (bool){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // 转账触发的事件
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //approve()成功后触发的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}