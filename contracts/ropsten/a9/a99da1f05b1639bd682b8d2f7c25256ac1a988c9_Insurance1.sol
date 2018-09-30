pragma solidity ^0.4.24;

contract Insurance1{

        // create order
    event onCreateOrder
    (
        uint256 id,    //insurance order id
        uint256 logisticOrderId,//logistic order id
        uint256 customerIdCard,//customer id card
        address customerAddr,//customer address
        uint256 distance,
        string  goods,
        uint256 eth, //insurance money
        uint256 payIfFail // pay if the goods has accident
    );

   // compensate order
    event onCompensateOrder
    (
        uint256 id,    //insurance order id
        uint256 logisticOrderId,//logistic order id
        address customerAddr,//customer address
        uint256 payIfFail // pay if the goods has accident
    );

    /** contract total money must be greater than  100*(insurance money) */
    uint256 public pool = 10 ** 25;
    uint256 currentOrderId = 0;
    address private admin = 0x3df0d1c17c0cd932829c23acfcce22c779e51960;

    //****************
    // Insurance Order
    //****************
    mapping (uint256 => Order) public orders;          // (orderId => order)  orders

     /**
     * if pool is low than 100 * estimatePrice
     */
    modifier isLowThanDeposit(uint256 _eth) {
        require(100 * _eth < pool, "sorry pool is must be more than 100 * estimatePrice");
        _;
    }

     /**
     * if pool is low than 100 * (insurance money)
     */
    modifier onlyCustomerAddr(address customAddr,uint256 orderId) {
        require(orders[orderId].customerAddr == customAddr, "sorry only customer address");
        _;
    }

    function core(uint256 logisticOrderId,uint256 customerIdCard,address customerAddr,uint256 distance,string goods,uint256 estimatePrice)
    isLowThanDeposit(estimatePrice)
    public payable{

        currentOrderId = currentOrderId + 1;
        uint256 payIfFail = estimatePrice * 60 / 100; // 60%
        orders[currentOrderId]=Order(currentOrderId,logisticOrderId,customerIdCard,customerAddr,distance,goods,msg.value,payIfFail);
        emit onCreateOrder(currentOrderId,logisticOrderId,customerIdCard,customerAddr,distance,goods,msg.value,payIfFail);
        admin.transfer(msg.value);

    }

     /**
     *  compensate customer payIfFail.
     */
    function compensate(uint256 orderId)
    onlyCustomerAddr(msg.sender,orderId)
    public payable{

        address customAddr = orders[orderId].customerAddr;
        uint256 payIfFail = orders[orderId].payIfFail;
        customAddr.transfer(payIfFail);
        uint256 logisticOrderId = orders[orderId].logisticOrderId;
        address customerAddr = orders[orderId].customerAddr;

        emit onCompensateOrder(orderId,logisticOrderId,customerAddr,payIfFail);

    }


    struct Order{
        uint256 id;    //insurance order id
        uint256 logisticOrderId;//logistic order id
        uint256 customerIdCard;//customer id card
        address customerAddr;//customer address
        uint256 distance;
        string  goods;
        uint256 eth; //insurance money
        uint256 payIfFail; // pay if the goods has accident
    }

}