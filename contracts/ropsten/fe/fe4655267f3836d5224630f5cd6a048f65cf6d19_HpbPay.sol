pragma solidity ^0.4.25;
contract HpbPay{
    address public owner;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    /**
     * Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
    event ReceivedHpb(address indexed sender, uint amount);
    // 接受HPB转账，比如投票应用赞助(用于自动投票支出)
    // Accept HPB transfer
    function () payable  external{
        emit ReceivedHpb(msg.sender, msg.value);
    }
    
    // 管理员
    mapping (address => address) public adminMap;
    modifier onlyAdmin{
        require(adminMap[msg.sender] != 0);
        _;
    }
    // 增加普通管理员
    function addAdmin(address addr) onlyOwner public{
        require(adminMap[addr]== 0);
        adminMap[addr] = addr;
    }
    // 删除普通管理员
    function deleteAdmin(address addr) onlyOwner public{
        require(adminMap[addr] != 0);
        adminMap[addr]=0;
    }
    
    struct Merchant{
        address merchantAddr;
        string publicKey;
        string desc;
        uint[] orderIndexs;
        mapping (string => uint) indexMap;
    }
    struct Payer{
        address payerAddr;
        uint[] orderIndexs;
        mapping (string => uint) indexMap;
    }
    enum PayStatus {
        Created,
        Paid,
        Cancelled
    }
    struct Order{
        address from;
        address to;
        uint value;
        PayStatus status;//0,已创建；1,已支付；2,已取消
        string orderId;
        string backUrl;
        string desc;
    }
    
    Merchant[] public merchants;
    Payer[] public payers;
    Order[] orders;
    mapping (address => uint) public merchantsIndexMap;
    mapping (address => uint) public payersIndexMap;
    
    constructor() public {
        owner = msg.sender;
        // 设置默认普通管理员（合约创建者）
        adminMap[owner]=owner;
        //设置第一个位置（为了定位不出错，第一个位置不占用）
        merchants.push(Merchant(msg.sender,"","",new uint[](0)));
        payers.push(Payer(msg.sender,new uint[](0)));
        orders.push(Order(0,0,0,PayStatus.Created,"","",""));
    }
    //添加商户
    function addMerchant(
        address _merchantAddr,
        string _publicKey,
        string _desc
    ) onlyAdmin public{
        uint merchantIndex = merchantsIndexMap[_merchantAddr];
        //必须商户地址还未添加
        require(merchantIndex == 0);
        merchants.push(Merchant(_merchantAddr,_publicKey,_desc,new uint[](0)));
        merchantIndex =merchants.length;
        merchantsIndexMap[_merchantAddr]=merchantIndex;
        //设置第一个位置（为了定位不出错，第一个位置不占用）
        merchants[merchantIndex].orderIndexs.push(0);
    }
    //更新商户
    function updateMerchant(
        string _publicKey,
        string _desc
    )  public{
        uint merchantIndex = merchantsIndexMap[msg.sender];
        //必须商户地址存在
        require(merchantIndex!= 0);
        merchants[merchantIndex].publicKey=_publicKey;
        merchants[merchantIndex].desc=_desc;
    }
    //由管理员更新商户
    function updateMerchantByAdmin(
        address _merchantAddr,
        string _publicKey,
        string _desc
    )onlyAdmin public{
        uint merchantIndex = merchantsIndexMap[_merchantAddr];
        //必须商户地址存在
        require(merchantIndex!= 0);
        merchants[merchantIndex].publicKey=_publicKey;
        merchants[merchantIndex].desc=_desc;
    }
    //由商户生成订单(指定收款地址)
    function generateOrderByMerchantWithPayee(
        address _from,
        address _to,
        uint _value,
        string _orderId,
        string _backUrl,
        string _desc
    ) public{
        uint merchantIndex = merchantsIndexMap[msg.sender];
        //必须商户地址存在(合法的商户才可以生成订单)
        require(merchantIndex!= 0);
        generateOrder(msg.sender,_from,_to,_value,_orderId,_backUrl,_desc);
    }
    
    //由商户生成订单(不指定收款地址)
    function generateOrderByMerchant(
        address _from,
        uint _value,
        string _orderId,
        string _backUrl,
        string _desc
    ) public{
       generateOrderByMerchantWithPayee(_from,msg.sender,_value,_orderId,_backUrl,_desc);
    }
    
    //由管理员生成订单(指定收款地址)
    function generateOrderByAdminWithPayee(
        address _merchantAddr,
        address _from,
        address _to,
        uint _value,
        string _orderId,
        string _backUrl,
        string _desc
    ) onlyAdmin public{
        generateOrder(_merchantAddr,_from,_to,_value,_orderId,_backUrl,_desc);
    }
    
    //由管理员生成订单(不指定收款地址)
    function generateOrderByAdmin(
        address _merchantAddr,
        address _from,
        uint _value,
        string _orderId,
        string _backUrl,
        string _desc
    ) onlyAdmin public{
        generateOrder(_merchantAddr,_from,_merchantAddr,_value,_orderId,_backUrl,_desc);
    }
    //生成订单
    function generateOrder(
        address _merchantAddr,
        address _from,
        address _to,
        uint _value,
        string _orderId,
        string _backUrl,
        string _desc
    ) internal{
        
        uint merchantIndex = merchantsIndexMap[_merchantAddr];
        //必须商户地址存在(合法的商户才可以生成订单)
        require(merchantIndex!= 0);
        
        //订单Id不能重复
        require(merchants[merchantIndex].indexMap[_orderId]==0);
        uint orderIndexFromMerchant=merchants[merchantIndex].orderIndexs.length;
        merchants[merchantIndex].indexMap[_orderId]=orderIndexFromMerchant;
        merchants[merchantIndex].orderIndexs.push(orders.length);
        
        uint payerIndex = payersIndexMap[_from];
        //如果付款者不存在，那么添加一个付款者
        if(payerIndex==0){
            payerIndex=payers.length;
            payers.push(Payer(_from,new uint[](0)));
            payersIndexMap[_from]=payerIndex;
            //设置第一个位置（为了定位不出错，第一个位置不占用）
            payers[payerIndex].orderIndexs.push(0);
        }
        //订单Id不能重复
        require(payers[payerIndex].indexMap[_orderId]==0);
        uint orderIndexFromPayer=payers[payerIndex].orderIndexs.length;
        payers[payerIndex].indexMap[_orderId]=orderIndexFromPayer;
        payers[payerIndex].orderIndexs.push(orders.length);

        orders.push(Order(_from,_to,_value,PayStatus.Created,_orderId,_backUrl,_desc));
    }
    function commitOrder(
        string _orderId
    )public{
       
        uint payerIndex = payersIndexMap[msg.sender];
        //必须是已存在支付订单关联的支付账户
        uint orderIndexFromPayer=payers[payerIndex].indexMap[_orderId];
        //订单必须存在
        require(orderIndexFromPayer!= 0);
        uint orderIndex=payers[payerIndex].orderIndexs[orderIndexFromPayer];
        require(msg.sender==orders[orderIndex].from);
        // 必须是已创建状态
        require(PayStatus.Created==orders[orderIndex].status);
        uint v=orders[orderIndex].value;
        orders[orderIndex].to.transfer(v);
        orders[orderIndex].status=PayStatus.Paid;
    }
    function cancelOrderByPayer(
        string _orderId
    )public{
        cancelOrderWithPayer(_orderId,msg.sender);
    }
    function cancelOrderByAdminWithPayer(
        string _orderId,
        address _payerAddr
    )onlyAdmin public{
        cancelOrderWithPayer(_orderId,_payerAddr);
    }
    function cancelOrderWithPayer(
        string _orderId,
        address _payerAddr
    ) public{
        uint payerIndex = payersIndexMap[_payerAddr];
        //必须是已存在支付订单关联的支付账户
        require(payerIndex!= 0);
        uint orderIndexFromPayer=payers[payerIndex].indexMap[_orderId];
        //订单必须存在
        require(orderIndexFromPayer!= 0);
        uint orderIndex=payers[payerIndex].orderIndexs[orderIndexFromPayer];
        require(orderIndex!=0);
        //支付者必须是本人
        require(msg.sender==orders[orderIndex].from);
        // 必须是已创建状态
        require(PayStatus.Created==orders[orderIndex].status);
        orders[orderIndex].status=PayStatus.Cancelled;
    }
    function cancelOrderByMerchant(
        string _orderId
    )public{
        cancelOrderWithMerchant(_orderId,msg.sender);
    }
    function cancelOrderByAdminWithMerchant(
        string _orderId,
        address _merchantAddr
    )onlyAdmin public{
        cancelOrderWithMerchant(_orderId,_merchantAddr);
    }
    function cancelOrderWithMerchant(
        string _orderId,
        address _merchantAddr
    ) internal{
        uint merchantIndex = merchantsIndexMap[_merchantAddr];
        //必须是已存在支付订单关联的商户账户
        require(merchantIndex!= 0);
        uint orderIndexFromMerchant=merchants[merchantIndex].indexMap[_orderId];
        //订单必须存在
        require(orderIndexFromMerchant!= 0);
        uint orderIndex=merchants[merchantIndex].orderIndexs[orderIndexFromMerchant];
        //必须是商户本人的订单
        require(orderIndex!=0);
        // 必须是已创建状态
        require(PayStatus.Created==orders[orderIndex].status);
        orders[orderIndex].status=PayStatus.Cancelled;
    }
    function fetchOrderByIdWithWithPayer(
        string orderId,
        address payerAddr
    )  public constant returns (
        address _from,
        address _to,
        uint _value,
        PayStatus _status,
        string _orderId,
        string _backUrl,
        string _desc
    ){
        uint payerIndex = payersIndexMap[payerAddr];
        //必须是已存在支付订单关联的支付账户
        require(payerIndex!= 0);
        uint orderIndexFromPayer=payers[payerIndex].indexMap[orderId];
        //订单必须存在
        require(orderIndexFromPayer!= 0);
        uint orderIndex=payers[payerIndex].orderIndexs[orderIndexFromPayer];
        require(orderIndex!=0);
        return fetchOrderByOrderIndex(orderIndex);
    }
    function fetchOrderByIdWithMerchant(
        string orderId,
        address merchantAddr
    )  public constant returns (
        address _from,
        address _to,
        uint _value,
        PayStatus _status,
        string _orderId,
        string _backUrl,
        string _desc
    ){
        uint merchantIndex = merchantsIndexMap[merchantAddr];
        //必须是已存在支付订单关联的商户账户
        require(merchantIndex!= 0);
        uint orderIndexFromMerchant=merchants[merchantIndex].indexMap[orderId];
        //订单必须存在
        require(orderIndexFromMerchant!= 0);
        uint orderIndex=merchants[merchantIndex].orderIndexs[orderIndexFromMerchant];
        //必须是商户本人的订单
        require(orderIndex!=0);
        
        return fetchOrderByOrderIndex(orderIndex);
    }
    
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
    function fetchOrdersForMerchant(
        address merchantAddr
    )  public constant returns (
        uint[] _orderIndexs
    ){
        uint merchantIndex = merchantsIndexMap[merchantAddr];
        //必须是已存在支付订单关联的商户账户
        require(merchantIndex!= 0);
        return merchants[merchantIndex].orderIndexs;
    }
    
    function fetchOrdersForPayer(
        address payerAddr
    )  public constant returns (
        uint[] _orderIndexs
    ){
        uint payerIndex = payersIndexMap[payerAddr];
        //必须是已存在支付订单关联的商户账户
        require(payerIndex!= 0);
        return payers[payerIndex].orderIndexs;
    }
   
    function fetchCancelledOrdersForMerchant(
        address merchantAddr
    )  public constant returns (
        uint[] _orderIndexs
    ){
        uint merchantIndex = merchantsIndexMap[merchantAddr];
        //必须是已存在支付订单关联的商户账户
        require(merchantIndex!= 0);
        uint ol=merchants[merchantIndex].orderIndexs.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Cancelled==orders[merchants[merchantIndex].orderIndexs[i]].status){
                orderIndexs[i-1]=(merchants[merchantIndex].orderIndexs[i]);
            }
        }
        return orderIndexs;
    }
    function fetchPaidOrdersForMerchant(
        address merchantAddr
    )  public constant returns (
        uint[] _orderIndexs
    ){
        uint merchantIndex = merchantsIndexMap[merchantAddr];
        //必须是已存在支付订单关联的商户账户
        require(merchantIndex!= 0);
        uint ol=merchants[merchantIndex].orderIndexs.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Paid==orders[merchants[merchantIndex].orderIndexs[i]].status){
                orderIndexs[i-1]=(merchants[merchantIndex].orderIndexs[i]);
            }
        }
        return orderIndexs;
    }
    function fetchCreatedOrdersForMerchant(
        address merchantAddr
    )  public constant returns (
        uint[] _orderIndexs
    ){
        uint merchantIndex = merchantsIndexMap[merchantAddr];
        //必须是已存在支付订单关联的商户账户
        require(merchantIndex!= 0);
        uint ol=merchants[merchantIndex].orderIndexs.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Created==orders[merchants[merchantIndex].orderIndexs[i]].status){
                orderIndexs[i-1]=(merchants[merchantIndex].orderIndexs[i]);
            }
        }
        return orderIndexs;
    }
    function fetchCancelledOrdersForPayer(
        address payerAddr
    )  public constant returns (
        uint[] _orderIndexs
    ){
        uint payerIndex = payersIndexMap[payerAddr];
        //必须是已存在支付订单关联的商户账户
        require(payerIndex!= 0);
        uint ol=payers[payerIndex].orderIndexs.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Cancelled==orders[payers[payerIndex].orderIndexs[i]].status){
                orderIndexs[i-1]=(payers[payerIndex].orderIndexs[i]);
            }
        }
        return orderIndexs;
    }
    function fetchPaidOrdersForPayer(
        address payerAddr
    )  public constant returns (
        uint[] _orderIndexs
    ){
        uint payerIndex = payersIndexMap[payerAddr];
        //必须是已存在支付订单关联的商户账户
        require(payerIndex!= 0);
        uint ol=payers[payerIndex].orderIndexs.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Paid==orders[payers[payerIndex].orderIndexs[i]].status){
                orderIndexs[i-1]=(payers[payerIndex].orderIndexs[i]);
            }
        }
        return orderIndexs;
    }
    function fetchCreatedOrdersForPayer(
        address payerAddr
    )  public constant returns (
        uint[] _orderIndexs
    ){
        uint payerIndex = payersIndexMap[payerAddr];
        //必须是已存在支付订单关联的商户账户
        require(payerIndex!= 0);
        uint ol=payers[payerIndex].orderIndexs.length;
        uint[] memory orderIndexs=new uint[](ol-1);
        for(uint i=1;i<ol;i++){
            if(PayStatus.Created==orders[payers[payerIndex].orderIndexs[i]].status){
                orderIndexs[i-1]=(payers[payerIndex].orderIndexs[i]);
            }
        }
        return orderIndexs;
    }
    function fetchAllCreatedOrders(
    )  public constant returns (
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