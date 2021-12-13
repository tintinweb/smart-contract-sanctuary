/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

pragma solidity ^0.4.26;

/*  @合约
    游戏方
*/
contract Game {
    // function chakanquanxian(address _address,uint256 _tokenid) public returns(bool); 
    function transfer(address _to,uint256 _tokenid) public returns(bool);
    function transferFrom(address _from,address _to,uint256 _tokenid) payable public returns(bool);
    
}

/*  @合约
    代币
*/
contract Glod {
    //授权的函数
    function transfer(address _to, uint256 _amount) public returns(bool);
    function transferFrom(address _from,address _to, uint256 _amount) public returns(bool);
    
}


/*  @合约
    交易所
*/
contract Exchange {

    /*  @引入合约
        引入游戏合约
    */
    Game private game;

    /*  @引入合约
        引入代币合约
    */
    Glod private glod;

    /*  @属性 公共
        当前订单号
    */
    uint256 public orderId;

    /*  @属性 公共
        合约创立人
    */
    address public founder = address(0x00);
    
    /*  @属性 公共
        服务费千分比
    */
    uint256 public serviceCharge;

    /*  @属性 公共
        服务费地址
    */
    address public waiter = address(0x00);

    /*  @结构体 公共
        订单详情
    */
    struct order{
        address account;            //用户地址

        address gameContract;       //游戏合约

        address glodContract;       //币种合约

        uint256 price;              //出售价格(小数位6位)
        
        uint256 equipTokenId;       //装备tokenId

        uint256[]  types;           //类型(类型id)
        
        uint256  state;             //交易状态  1挂单中  2交易完成  3交易取消
        
        uint256  nowtime;           //挂单时间

        uint256  validity;          //有效期

        uint256  orderId;           // 订单id

        address to;                 //买家地址
    }

    /*  @映射 公共
        订单集合
    */
    mapping(uint256=>order) orders; 


    /*  @事件
        发布订单
    */
    event _addTheOrder(uint256 _orderId);

    /*  @事件
        取消订单
    */
    event _cancellationOfOrder(uint256 _orderId); 
    
    /*  @事件
        购买订单
    */
    event _buyOrder(uint256 _orderId);
    

    /*  @构造函数 公共
        @_orderId  uint256  初始订单号
        @_serviceCharge  uint256  服务费千分比
        @_waiter  address  服务费地址
    */
    constructor (uint256  _orderId,uint256 _serviceCharge,address _waiter) public  payable{
        require (_serviceCharge > 0 && _serviceCharge < 1000);
        founder = msg.sender;               //设定合约创立者
        orderId = _orderId;                 //设定初始订单id
        serviceCharge = _serviceCharge;     //设定服务费千分比
        waiter = _waiter;                   //设定服务费收取地址

    }

    function () payable public {
    
    }
    
    /*  @公共方法 修改创立人
        @_waiter  address  新服务费地址
        @returns
        @bool 
    */
    function modifyOwnerFounder(address _founder) public returns(bool){
        require (msg.sender == founder,'Do not have permission');
        founder = _founder;
        return true;
    }

    /*  @公共方法 修改服务费千分比
        @_serviceCharge  uint256  新服务费千分比
        @returns
        @bool 
    */
    function modifyingServiceCharges(uint256 _serviceCharge) public returns(bool){
        require (msg.sender == founder,'Do not have permission');
        require (_serviceCharge > 0 && _serviceCharge < 1000,'parameter error');
        serviceCharge = _serviceCharge;
        return true;
    }
     
    /*  @公共方法 修改服务费地址
        @_waiter  address  新服务费地址
        @returns
        @bool 
    */
    function modifyTheServer(address _waiter) public returns(bool){
        require (msg.sender == founder,'Do not have permission');
        waiter = _waiter;
        return true;
    }
     
    /*  @公共方法 玩家添加订单
        @_gameContract  address     游戏合约地址
        @_price         uint256     出售价格
        @_equipToken    string      装备token
        @_types         uint256[]   类型（类型的id集合）
        @_validity      uint256     有效期
        @teturns
        @uint256        订单号 
    */ 
    function accountAddTheOrder(address _gameContract,address _glodContract,uint256 _price,uint256 _equipTokenId,uint256[] memory _types,uint256 _validity) public returns(bool,uint256){
        //初始化游戏合约地址
        game = Game(_gameContract);
        //这里调用游戏合约 判断有没有授权
        // if(game.chakanquanxian(msg.sender,_equipTokenId) != true){
        //     require(false,'Unauthorized');
        // }
        //这里调用游戏合约 转移装备
        require (game.transferFrom(msg.sender,address(this),_equipTokenId),'Failed to call the game'); //将装备从卖家处转移到本合约
        orderId = orderId + 1;  //订单号累加1
        orders[orderId] = order(msg.sender,_gameContract,_glodContract,_price,_equipTokenId,_types,1,block.timestamp,_validity,orderId,address(0x00));
        emit _addTheOrder(orderId);  
        return (true,orderId);
    }

    /*  @公共方法 查询订单详情
        @_orderId       uint256     订单号
        @teturns
        @_address       address     跟地址有关的数据 
        @_uint          address     跟数字有关的数据
        @_types         uint256     订单类型
    */ 
    function theOrderDetails(uint256 _orderId) public view returns(address[] _address,uint256[] _uint,uint256[] _types){
        address[] memory temporaryAddress;
        temporaryAddress[0] = orders[_orderId].account;             //用户地址
        temporaryAddress[1] = orders[_orderId].gameContract;        //游戏合约
        temporaryAddress[2] = orders[_orderId].glodContract;        //币种合约
        temporaryAddress[3] = orders[_orderId].to;                  //买家地址
        uint256[] memory temporaryUint;
        temporaryUint[0] = orders[_orderId].price;                  //出售价格
        temporaryUint[1] = orders[_orderId].equipTokenId;           //道具id
        temporaryUint[2] = orders[_orderId].state;                  //状态
        return (temporaryAddress,temporaryUint,orders[_orderId].types);
    }
    
    /*  @公共方法 取消订单
        @_orderId       uint256     订单号
        @teturns
        @bool
    */ 
    function cancellationOfOrder(uint256 _orderId) public returns(bool,uint256){
        require (msg.sender == orders[_orderId].account,'Do not have permission');       //判断是不是订单发起人
        require (orders[_orderId].state == 1,'Abnormal order status');                  //判断订单状态是不是未交易
        orders[_orderId].state == 3;            //修改订单状态为取消
        //初始化游戏合约地址
        game = Game(orders[_orderId].gameContract);
        //这里调用游戏合约 转移装备
        require (game.transfer(msg.sender,orders[_orderId].equipTokenId),'Failed to call the game'); //将装备退给卖家
        emit _cancellationOfOrder(_orderId);    //发布取消订单事件
        return (true,200);
    }
    
    /*  @公共方法 购买订单
        @_orderId       uint256     订单号
        @teturns
        @bool
    */
    function buyOrder(uint256 _orderId) payable public returns(bool){
        //判断订单状态是否是未交易
        require (orders[_orderId].state == 1,'Abnormal order status');
        orders[_orderId].state = 2;     //将订单状态改为已交易
        uint256  transactionFee = orders[_orderId].price * (1000 - serviceCharge) / 1000;   //计算卖家应收的金额
        uint256  transactionServiceCharge = orders[_orderId].price * serviceCharge / 1000;  //计算手续费
        //判断订单币种
        if(address(orders[_orderId].glodContract) != address(0x00)){
            //代币交易
            //初始化币种合约地址
            glod = Glod(orders[_orderId].glodContract);
            glod.transferFrom(msg.sender,address(orders[_orderId].account),transactionFee);
            glod.transferFrom(msg.sender,address(waiter),transactionServiceCharge);
        }else{
            //链币交易
            require (msg.value >= orders[_orderId].price,'Insufficient transaction amount');
            address(orders[_orderId].account).transfer(transactionFee);    
            address(waiter).transfer(transactionServiceCharge);   
        }
        //初始化游戏合约地址
        game = Game(orders[_orderId].gameContract);
        require (game.transfer(msg.sender,orders[_orderId].equipTokenId),'Failed to call the game');  //将道具转移给买家
        orders[_orderId].to = address(msg.sender);      //修改订单中的买家地址
        emit _buyOrder(_orderId);      //发布购买事件   
        return true;
    }


    
}