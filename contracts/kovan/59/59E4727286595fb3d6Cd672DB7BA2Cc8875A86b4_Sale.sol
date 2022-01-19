pragma solidity ^0.8.0;


import "./IBEP20.sol";
import "./Ownable.sol";

contract Sale is Ownable {

    address public USDT;
    address public SECURITIES;

    uint256 public basePrice;
    address public manager;
    bool public status;

    struct Order {
        uint256 securities;
        uint256 USDT;
        string orderId;
        address payer;
    }

    Order[] public orders;
    uint256 public ordersCount;

    event BuyTokensEvent(address buyer, uint256 amountSecurities);

    constructor(address _USDT, address _securities) {
        USDT = _USDT;
        SECURITIES = _securities;
        manager = _msgSender();
        ordersCount = 0;
        basePrice = 2;
        status = true;
    }

    modifier onlyManager() {
        require(_msgSender() == manager, "Wrong sender");
        _;
    }

    modifier onlyActive() {
        require(status == true, "Sale: not active");
        _;
    }

    function changeManager(address newManager) public onlyOwner {
        manager = newManager;
    }

    function changeStatus(bool _status) public onlyOwner {
        status = _status;
    }

    function setPrice(uint256 priceInUSDT) public onlyManager {
        basePrice = priceInUSDT;
    }

    function buyToken(uint256 amountUSDT, string memory orderId) public onlyActive returns(bool) {
        uint256 amountSecurities = (amountUSDT / basePrice) / (10**IBEP20(USDT).decimals());
        Order memory order;
        IBEP20(USDT).transferFrom(_msgSender(), address(this), amountUSDT);
        require(IBEP20(SECURITIES).transfer(_msgSender(), amountSecurities), "transfer: SEC error");

        order.USDT = amountUSDT;
        order.securities = amountSecurities;
        order.orderId = orderId;
        order.payer = _msgSender();
        orders.push(order);
        ordersCount += 1;

        emit BuyTokensEvent(_msgSender(), amountSecurities);
        return true;
    }

    function sendBack(uint256 amount, address token) public onlyOwner returns(bool) {
        require(IBEP20(token).transfer(_msgSender(), amount), "Transfer: error");
        return true;
    }

    function buyTokenView(uint256 amountUSDT) public view returns(uint256 token, uint256 securities) {
        uint256 amountSecurities = (amountUSDT / basePrice) / (10**IBEP20(USDT).decimals());
        return (
        amountUSDT, amountSecurities
         );
    }

}