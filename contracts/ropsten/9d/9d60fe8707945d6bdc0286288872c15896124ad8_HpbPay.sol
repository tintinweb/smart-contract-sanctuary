pragma solidity ^0.4.25;
/**
 * HPB 支付合约
 */
contract HpbPay{
    event OwnershipRenounced(
        address indexed previousOwner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event ReceivedHpb(
        address indexed sender, 
        uint amount
    );
    event GenerateOrder(
        address indexed from,
        address indexed to,
        string indexed orderId,
        uint value,
        string backUrl,
        string desc
    );
    event PayOrder(
        address indexed from,
        address indexed to,
        string indexed orderId,
        uint value,
        string backUrl,
        string desc
    );
    event CancelOrder(
        address indexed from,
        address indexed to,
        string indexed orderId,
        uint value,
        string backUrl,
        string desc
    );
    /**
     * 接受HPB转账，比如赞助合约开发
     * Accept HPB transfer
     */
    function () payable  external{
        emit ReceivedHpb(msg.sender, msg.value);
    }
    /**
     * 商户详细信息结构体
     */
    struct Merchant{
        address merchantAddr;//商户账户地址
        string publicKey;//商户公钥(如果需要对传递的数据签名认证)
        string desc;//商户描述
        uint[] orderIndexs;//该商户的订单序号列表
        mapping (string => uint) indexMap;//订单号=》订单序号列表下标
    }
    /**
     * 付款者详细信息结构体
     */
    struct Payer{
        address payerAddr;//付款者账户地址
        uint[] orderIndexs;//付款者的订单序号列表
        mapping (string => uint) indexMap;//订单号=》订单序号列表下标
    }
    /**
     * 订单详细信息结构体
     */
    struct Order{
        address from;//付款者
        address to;//收款者
        uint value;//金额
        PayStatus status;//0,已创建；1,已支付；2,已取消
        string orderId;//商家订单Id，对商家而言保证唯一性
        string backUrl;//HPB支付APP返回到商户APP的返回URL
        string desc;//订单的详细描述
    }
    /**
     * 订单状态枚举
     */
    enum PayStatus {
        Created,//创建待支付状态
        Paid,//已支付状态
        Cancelled//已取消状态
    }
    
    address public owner;
    
    mapping (address => address) public adminMap;//支付合约管理员
    
    Merchant[] merchants;//商户列表
    Payer[] payers;//付款者列表
    Order[] orders;//订单列表
    mapping (address => uint) public merchantsIndexMap;//商户账户地址=》商户数组下标
    mapping (address => uint) public payersIndexMap;//付款者账户地址=》付款者数组下标
    
    constructor() public {
        owner = msg.sender;
        adminMap[owner]=owner;// 设置默认普通管理员（合约创建者）
        merchants.push(Merchant(msg.sender,"","",new uint[](0)));//设置第一个位置（为了定位不出错，第一个位置不占用）
        payers.push(Payer(msg.sender,new uint[](0)));//设置第一个位置（为了定位不出错，第一个位置不占用）
        orders.push(Order(0,0,0,PayStatus.Created,"","",""));//设置第一个位置（为了定位不出错，第一个位置不占用）
    }
    
    /**
     * 如果非合约拥有者就抛出异常
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * 允许当前合约拥有者放弃合约的控制权
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * 允许当前合约拥有者转交合约的控制权
     */
    function transferOwnership(
        address _newOwner
    ) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
    
    modifier onlyAdmin{
        require(adminMap[msg.sender] != 0);
        _;
    }
    /**
     *  增加普通管理员
     */
    function addAdmin(address addr) onlyOwner public{
        require(adminMap[addr]== 0);
        adminMap[addr] = addr;
    }
    /**
     * 删除普通管理员
     */
    function deleteAdmin(address addr) onlyOwner public{
        require(adminMap[addr] != 0);
        adminMap[addr]=0;
    }
    /**
     * 通过合约管理员添加商户
     */
    function addMerchant(
        address _merchantAddr,
        string _publicKey,
        string _desc
    ) onlyAdmin public{
        uint merchantIndex = merchantsIndexMap[_merchantAddr];
        require(merchantIndex == 0);//必须商户地址还未添加
        merchants.push(Merchant(_merchantAddr,_publicKey,_desc,new uint[](0)));
        merchantIndex =merchants.length;
        merchantsIndexMap[_merchantAddr]=merchantIndex;
        merchants[merchantIndex].orderIndexs.push(0);//设置第一个位置（为了定位不出错，第一个位置不占用）
    }
    /**
     * 商户更新自己的公钥和描述信息
     */
    function updateMerchant(
        string _publicKey,
        string _desc
    )  public{
        uint merchantIndex = merchantsIndexMap[msg.sender];
        require(merchantIndex!= 0);//必须商户地址存在
        merchants[merchantIndex].publicKey=_publicKey;
        merchants[merchantIndex].desc=_desc;
    }
    /**
     * 商户本人查看自己提供的公钥
     */
    function getMerchantPublicKey(
    ) public constant returns(
        string _publicKey
    ){
        uint merchantIndex = merchantsIndexMap[msg.sender];
        require(merchantIndex!= 0);//必须商户地址存在
        return merchants[merchantIndex].publicKey;
    }
    /**
     * 管理员获取商户的公钥
     */
    function getMerchantPublicKeyByAdmin(
        address _merchantAddr
    )onlyAdmin public constant returns(
        string _publicKey
    ){
        uint merchantIndex = merchantsIndexMap[_merchantAddr];
        require(merchantIndex!= 0);//必须商户地址存在
        return merchants[merchantIndex].publicKey;
    }
    /**
     * 管理员更新商户的公钥和描述
     */
    function updateMerchantByAdmin(
        address _merchantAddr,
        string _publicKey,
        string _desc
    )onlyAdmin public{
        uint merchantIndex = merchantsIndexMap[_merchantAddr];
        require(merchantIndex!= 0);//必须商户地址存在
        merchants[merchantIndex].publicKey=_publicKey;
        merchants[merchantIndex].desc=_desc;
    }
    /**
     *生成订单详情,供内部调用
     */
    function _generateOrder(
        address _merchantAddr,
        address _from,
        address _to,
        uint _value,
        string _orderId,
        string _backUrl,
        string _desc
    ) internal{
        uint merchantIndex = merchantsIndexMap[_merchantAddr];
        require(merchantIndex!= 0);//必须商户地址存在(合法的商户才可以生成订单)
        require(merchants[merchantIndex].indexMap[_orderId]==0);//订单Id不能重复
        uint orderIndexFromMerchant=merchants[merchantIndex].orderIndexs.length;
        merchants[merchantIndex].indexMap[_orderId]=orderIndexFromMerchant;
        merchants[merchantIndex].orderIndexs.push(orders.length);
        uint payerIndex = payersIndexMap[_from];
        if(payerIndex==0){//如果付款者不存在，那么添加一个付款者
            payerIndex=payers.length;
            payers.push(Payer(_from,new uint[](0)));
            payersIndexMap[_from]=payerIndex;
            payers[payerIndex].orderIndexs.push(0);//设置第一个位置（为了定位不出错，第一个位置不占用）
        }
        require(payers[payerIndex].indexMap[_orderId]==0);//订单Id不能重复
        uint orderIndexFromPayer=payers[payerIndex].orderIndexs.length;
        payers[payerIndex].indexMap[_orderId]=orderIndexFromPayer;
        payers[payerIndex].orderIndexs.push(orders.length);
        orders.push(Order(_from,_to,_value,PayStatus.Created,_orderId,_backUrl,_desc));
        emit GenerateOrder(
	        _from,
	        _to,
	        _orderId,
	        _value,
	        _backUrl,
	        _desc
    	);
    }
    /**
     * 为付款者取消对应的订单,供内部调用
     */
    function _cancelOrderWithPayer(
        string _orderId,
        address _payerAddr
    ) internal{
        uint payerIndex = payersIndexMap[_payerAddr];
        require(payerIndex!= 0);//必须是已存在订单关联的支付账户
        uint orderIndexFromPayer=payers[payerIndex].indexMap[_orderId];
        require(orderIndexFromPayer!= 0);//订单必须存在
        uint orderIndex=payers[payerIndex].orderIndexs[orderIndexFromPayer];
        require(orderIndex!=0);
        require(msg.sender==orders[orderIndex].from);//支付者必须是本人
        require(PayStatus.Created==orders[orderIndex].status);//必须是已创建状态
        orders[orderIndex].status=PayStatus.Cancelled;
        emit CancelOrder(
	        orders[orderIndex].from,
	        orders[orderIndex].to,
	        _orderId,
	        orders[orderIndex].value,
	        orders[orderIndex].backUrl,
	        orders[orderIndex].desc
    	);
    }
     /**
     *查看付款者的订单,供内部调用
     */
    function _fetchOrderByIdWithPayer(
        string orderId,
        address payerAddr
    )  internal constant returns (
        address _from,
        address _to,
        uint _value,
        PayStatus _status,
        string _orderId,
        string _backUrl,
        string _desc
    ){
        uint payerIndex = payersIndexMap[payerAddr];
        require(payerIndex!= 0);//必须是已存在订单关联的支付账户
        uint orderIndexFromPayer=payers[payerIndex].indexMap[orderId];
        require(orderIndexFromPayer!= 0);//订单必须存在
        uint orderIndex=payers[payerIndex].orderIndexs[orderIndexFromPayer];
        require(orderIndex!=0);
        return fetchOrderByOrderIndex(orderIndex);
    }
    /**
     * 为商户取消对应的订单,供内部调用
     */
    function _cancelOrderWithMerchant(
        string _orderId,
        address _merchantAddr
    ) internal{
        uint merchantIndex = merchantsIndexMap[_merchantAddr];
        require(merchantIndex!= 0);//必须是已存在订单关联的商户账户
        uint orderIndexFromMerchant=merchants[merchantIndex].indexMap[_orderId];
        require(orderIndexFromMerchant!= 0);//订单必须存在
        uint orderIndex=merchants[merchantIndex].orderIndexs[orderIndexFromMerchant];
        require(orderIndex!=0);//必须是商户本人的订单
        require(PayStatus.Created==orders[orderIndex].status);//必须是已创建状态
        orders[orderIndex].status=PayStatus.Cancelled;
        emit CancelOrder(
	        orders[orderIndex].from,
	        orders[orderIndex].to,
	        _orderId,
	        orders[orderIndex].value,
	        orders[orderIndex].backUrl,
	        orders[orderIndex].desc
    	);
    }
    /**
     *查看商户的订单,供内部调用
     */
    function _fetchOrderByIdWithMerchant(
        string orderId,
        address merchantAddr
    )  internal constant returns (
        address _from,
        address _to,
        uint _value,
        PayStatus _status,
        string _orderId,
        string _backUrl,
        string _desc
    ){
        uint merchantIndex = merchantsIndexMap[merchantAddr];
        require(merchantIndex!= 0);//必须是已存在订单关联的商户账户
        uint orderIndexFromMerchant=merchants[merchantIndex].indexMap[orderId];
        require(orderIndexFromMerchant!= 0);//订单必须存在
        uint orderIndex=merchants[merchantIndex].orderIndexs[orderIndexFromMerchant];
        require(orderIndex!=0);//必须是商户本人的订单
        return fetchOrderByOrderIndex(orderIndex);
    }
    /**
     *查看商户所有的订单,供内部调用
     */
    function _fetchOrdersForMerchant(
        address merchantAddr
    )  internal constant returns (
        uint[] _orderIndexs
    ){
        uint merchantIndex = merchantsIndexMap[merchantAddr];
        require(merchantIndex!= 0);//必须是已存在订单关联的商户账户
        return merchants[merchantIndex].orderIndexs;
    }
    /**
     *查看付款者所有的订单,供内部调用
     */
    function _fetchOrdersForPayer(
        address payerAddr
    )  internal constant returns (
        uint[] _orderIndexs
    ){
        uint payerIndex = payersIndexMap[payerAddr];
        require(payerIndex!= 0);//必须是已存在订单关联的付款者账户
        return payers[payerIndex].orderIndexs;
    }
    /**
     *查看商户所有的已取消状态订单,供内部调用
     */
    function _fetchCancelledOrdersForMerchant(
        address merchantAddr
    )  internal constant returns (
        uint[] _orderIndexs
    ){
        uint merchantIndex = merchantsIndexMap[merchantAddr];
        require(merchantIndex!= 0);//必须是已存在订单关联的商户账户
        uint ol=merchants[merchantIndex].orderIndexs.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Cancelled==orders[merchants[merchantIndex].orderIndexs[i]].status){
                orderIndexs[i-1]=(merchants[merchantIndex].orderIndexs[i]);
            }
        }
        return orderIndexs;
    }
    /**
     *查看商户所有的已支付状态订单,供内部调用
     */
    function _fetchPaidOrdersForMerchant(
        address merchantAddr
    )  internal constant returns (
        uint[] _orderIndexs
    ){
        uint merchantIndex = merchantsIndexMap[merchantAddr];
        require(merchantIndex!= 0);//必须是已存在订单关联的商户账户
        uint ol=merchants[merchantIndex].orderIndexs.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Paid==orders[merchants[merchantIndex].orderIndexs[i]].status){
                orderIndexs[i-1]=(merchants[merchantIndex].orderIndexs[i]);
            }
        }
        return orderIndexs;
    }
    /**
     *查看商户所有的已创建状态订单,供内部调用
     */
    function _fetchCreatedOrdersForMerchant(
        address merchantAddr
    )  internal constant returns (
        uint[] _orderIndexs
    ){
        uint merchantIndex = merchantsIndexMap[merchantAddr];
        require(merchantIndex!= 0);//必须是已存在订单关联的商户账户
        uint ol=merchants[merchantIndex].orderIndexs.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Created==orders[merchants[merchantIndex].orderIndexs[i]].status){
                orderIndexs[i-1]=(merchants[merchantIndex].orderIndexs[i]);
            }
        }
        return orderIndexs;
    }
    /**
     *查看付款者所有的已取消状态订单,供内部调用
     */
    function _fetchCancelledOrdersForPayer(
        address payerAddr
    )  internal constant returns (
        uint[] _orderIndexs
    ){
        uint payerIndex = payersIndexMap[payerAddr];
        require(payerIndex!= 0);//必须是已存在订单关联的付款者账户
        uint ol=payers[payerIndex].orderIndexs.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Cancelled==orders[payers[payerIndex].orderIndexs[i]].status){
                orderIndexs[i-1]=(payers[payerIndex].orderIndexs[i]);
            }
        }
        return orderIndexs;
    }
    /**
     *查看付款者所有的已支付状态订单,供内部调用
     */
    function _fetchPaidOrdersForPayer(
        address payerAddr
    )  internal constant returns (
        uint[] _orderIndexs
    ){
        uint payerIndex = payersIndexMap[payerAddr];
        require(payerIndex!= 0);//必须是已存在订单关联的付款者账户
        uint ol=payers[payerIndex].orderIndexs.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Paid==orders[payers[payerIndex].orderIndexs[i]].status){
                orderIndexs[i-1]=(payers[payerIndex].orderIndexs[i]);
            }
        }
        return orderIndexs;
    }
     /**
     *查看付款者所有的已创建状态订单,供内部调用
     */
    function _fetchCreatedOrdersForPayer(
        address payerAddr
    )  internal constant returns (
        uint[] _orderIndexs
    ){
        uint payerIndex = payersIndexMap[payerAddr];
        require(payerIndex!= 0);//必须是已存在订单关联的付款者账户
        uint ol=payers[payerIndex].orderIndexs.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Created==orders[payers[payerIndex].orderIndexs[i]].status){
                orderIndexs[i-1]=(payers[payerIndex].orderIndexs[i]);
            }
        }
        return orderIndexs;
    }
    /**
     * 由商户生成订单(并指定特定收款地址)
     */
    function generateOrderByMerchantWithPayee(
        address _from,
        address _to,
        uint _value,
        string _orderId,
        string _backUrl,
        string _desc
    ) public{
        uint merchantIndex = merchantsIndexMap[msg.sender];
        require(merchantIndex!= 0);//必须商户地址存在(合法的商户才可以生成订单)
        _generateOrder(msg.sender,_from,_to,_value,_orderId,_backUrl,_desc);
    }
    
    /**
     * 由商户生成订单(默认指定商户账户地址为收款地址)
     */
    function generateOrderByMerchant(
        address _from,
        uint _value,
        string _orderId,
        string _backUrl,
        string _desc
    ) public{
       generateOrderByMerchantWithPayee(_from,msg.sender,_value,_orderId,_backUrl,_desc);
    }
    /**
     * 由管理员生成订单(并指定特定的商户收款地址)
     */
    function generateOrderWithPayeeByAdmin(
        address _merchantAddr,
        address _from,
        address _to,
        uint _value,
        string _orderId,
        string _backUrl,
        string _desc
    ) onlyAdmin public{
        _generateOrder(_merchantAddr,_from,_to,_value,_orderId,_backUrl,_desc);
    }
    
    /**
     * 商户让管理员生成订单(默认指定商户账户地址为收款地址)
     */
    function generateOrderByAdmin(
        address _merchantAddr,
        address _from,
        uint _value,
        string _orderId,
        string _backUrl,
        string _desc
    ) onlyAdmin public{
        _generateOrder(_merchantAddr,_from,_merchantAddr,_value,_orderId,_backUrl,_desc);
    }
    
    /**
     *付款者确认并订单
     */
    function payOrder(
        string _orderId
    )public{
        uint payerIndex = payersIndexMap[msg.sender];
        uint orderIndexFromPayer=payers[payerIndex].indexMap[_orderId];
        require(orderIndexFromPayer!= 0);//必须是已存在订单关联的支付账户
        uint orderIndex=payers[payerIndex].orderIndexs[orderIndexFromPayer];
        require(msg.sender==orders[orderIndex].from);
        require(PayStatus.Created==orders[orderIndex].status);//必须是已创建状态
        uint v=orders[orderIndex].value;
        orders[orderIndex].to.transfer(v);
        orders[orderIndex].status=PayStatus.Paid;
        emit PayOrder(
	        orders[orderIndex].from,
	        orders[orderIndex].to,
	        _orderId,
	        orders[orderIndex].value,
	        orders[orderIndex].backUrl,
	        orders[orderIndex].desc
    	);
    }
    /**
     *付款者取消订单
     */
    function cancelOrderByPayer(
        string _orderId
    )public{
        _cancelOrderWithPayer(_orderId,msg.sender);
    }
     /**
     *管理员取消付款者的某个订单
     */
    function cancelOrderWithPayerByAdmin(
        string _orderId,
        address _payerAddr
    )onlyAdmin public{
        _cancelOrderWithPayer(_orderId,_payerAddr);
    }
    /**
     *商户取消订单
     */
    function cancelOrderByMerchant(
        string _orderId
    )public{
        _cancelOrderWithMerchant(_orderId,msg.sender);
    }
    /**
     *管理员取消商户的某个订单
     */
    function cancelOrderWithMerchantByAdmin(
        string _orderId,
        address _merchantAddr
    )onlyAdmin public{
        _cancelOrderWithMerchant(_orderId,_merchantAddr);
    }
    
    /**
     *付款者查询自己的某个付款订单
     */
    function fetchOrderByIdWithPayer(
        string orderId
    )  public constant returns (
        address _from,
        address _to,
        uint _value,
        PayStatus _status,
        string _orderId,
        string _backUrl,
        string _desc
    ){
        return _fetchOrderByIdWithPayer(orderId,msg.sender);
    }
    /**
     *管理员查询付款者的某个付款订单
     */
    function fetchOrderByIdWithPayerByAdmin(
        string orderId,
        address payerAddr
    )onlyAdmin public constant returns (
        address _from,
        address _to,
        uint _value,
        PayStatus _status,
        string _orderId,
        string _backUrl,
        string _desc
    ){
        return _fetchOrderByIdWithPayer(orderId,payerAddr);
    }
    
   
    /**
     *商户查看自己的某个订单
     */
    function fetchOrderByIdWithMerchant(
        string orderId
    )  public constant returns (
        address _from,
        address _to,
        uint _value,
        PayStatus _status,
        string _orderId,
        string _backUrl,
        string _desc
    ){
        return _fetchOrderByIdWithMerchant(orderId,msg.sender);
    }
    /**
     *管理员查看商户的某个订单
     */
    function fetchOrderByIdWithMerchantByAdmin(
        string orderId,
        address merchantAddr
    )  onlyAdmin public constant returns (
        address _from,
        address _to,
        uint _value,
        PayStatus _status,
        string _orderId,
        string _backUrl,
        string _desc
    ){
        return _fetchOrderByIdWithMerchant(orderId,merchantAddr);
    }
    
    /**
     *根据订单序号查询订单详细信息
     */
    function fetchOrderByOrderIndex(
        uint _orderIndex
    )  public constant returns (
        address _from,
        address _to,
        uint _value,
        PayStatus _status,
        string _orderId,
        string _backUrl,
        string _desc
    ){
        require(_orderIndex!= 0);
        return (
            orders[_orderIndex].from,
            orders[_orderIndex].to,
            orders[_orderIndex].value,
            orders[_orderIndex].status,
            orders[_orderIndex].orderId,
            orders[_orderIndex].backUrl,
            orders[_orderIndex].desc
        );
    }
    /**
     *商户查询自己所有的订单信息
     */
    function fetchOrdersForMerchant(
    )  public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchOrdersForMerchant(msg.sender);
    }
    /**
     *管理员查询商户所有的订单信息
     */
    function fetchOrdersForMerchantByAdmin(
        address merchantAddr
    )onlyAdmin public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchOrdersForMerchant(merchantAddr);
    }
    /**
     *付款者查询自己所有的订单信息
     */
    function fetchOrdersForPayer(
    )  public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchOrdersForPayer(msg.sender);
    }
    /**
     *管理员查询付款者所有的订单信息
     */
    function fetchOrdersForPayerByAdmin(
        address payerAddr
    ) onlyAdmin public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchOrdersForPayer(payerAddr);
    }
    /**
     *商户查询自己所有已取消状态的订单信息
     */
    function fetchCancelledOrdersForMerchant(
    )  public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchCancelledOrdersForMerchant(msg.sender);
    }
    /**
     *管理员查询商户所有已取消状态的订单信息
     */
    function fetchCancelledOrdersForMerchantByAdmin(
        address merchantAddr
    ) onlyAdmin public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchCancelledOrdersForMerchant(merchantAddr);
    }
    /**
     *商户查询自己所有已支付状态的订单信息
     */
    function fetchPaidOrdersForMerchant(
    )  public constant returns (
        uint[] _orderIndexs
    ){
      return _fetchPaidOrdersForMerchant(msg.sender); 
    }
    /**
     *管理员查询商户所有已支付状态的订单信息
     */
    function fetchPaidOrdersForMerchantByAdmin(
        address merchantAddr
    ) onlyAdmin public constant returns (
        uint[] _orderIndexs
    ){
      return _fetchPaidOrdersForMerchant(merchantAddr); 
    }
    /**
     *商户查询自己的所有已创建状态的订单信息
     */
    function fetchCreatedOrdersForMerchant(
    )  public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchCreatedOrdersForMerchant(msg.sender);
    }
    /**
     *管理员查询商户所有已创建状态的订单信息
     */
    function fetchCreatedOrdersForMerchantByAdmin(
        address merchantAddr
    ) onlyAdmin public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchCreatedOrdersForMerchant(merchantAddr);
    }
    /**
     *付款者查询自己所有已取消状态的订单信息
     */
    function fetchCancelledOrdersForPayer(
    )  public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchCancelledOrdersForPayer(msg.sender);
    }
    /**
     *管理员查询付款者所有已取消状态的订单信息
     */
    function fetchCancelledOrdersForPayerByAdmin(
        address payerAddr
    ) onlyAdmin public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchCancelledOrdersForPayer(payerAddr);
    }
    /**
     *付款者查询自己所有已支付状态的订单信息
     */
    function fetchPaidOrdersForPayer(
    )  public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchPaidOrdersForPayer(msg.sender);
    }
    /**
     *管理员查询付款者所有已支付状态的订单信息
     */
    function fetchPaidOrdersForPayerByAdmin(
        address payerAddr
    ) onlyAdmin public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchPaidOrdersForPayer(payerAddr);
    }
    /**
     *付款者查询住酒店所有已创建状态的订单信息
     */
    function fetchCreatedOrdersForPayer(
    )  public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchCreatedOrdersForPayer(msg.sender);
    }
    /**
     *管理员查询付款者所有已创建状态的订单信息
     */
    function fetchCreatedOrdersForPayerByAdmin(
        address payerAddr
    ) onlyAdmin public constant returns (
        uint[] _orderIndexs
    ){
        return _fetchCreatedOrdersForPayer(payerAddr);
    }
    /**
     *管理员查询所有已创建状态的订单信息
     */
    function fetchAllCreatedOrders(
    ) onlyAdmin public constant returns (
        uint[] _orderIndexs
    ){
        uint ol=orders.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Created==orders[i].status){
                orderIndexs[i-1]=i;
            }
        }
        return orderIndexs;
    }
}