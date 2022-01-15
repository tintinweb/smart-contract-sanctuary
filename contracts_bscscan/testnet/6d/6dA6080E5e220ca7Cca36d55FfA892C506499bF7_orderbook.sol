/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public{
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
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


interface IBEP20 {

   function totalSupply() external view returns (uint);

   function balanceOf(address account) external view returns (uint);

   function transfer(address recipient, uint amount) external returns (bool);

   function allowance(address owner, address spender) external view returns (uint);

   function approve(address spender, uint amount) external returns (bool);

   function transferFrom(address sender, address recipient, uint amount) external returns (bool);

   event Transfer(address indexed from, address indexed to, uint value);

   event Approval(address indexed owner, address indexed spender, uint value);
}


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


interface IOrderBook { 

    enum Side { Buy, Sell}

    struct Order {
        address sender;
        address tokenA;
        address tokenB;
        uint256 amount;
        Side side;
        uint256 price;
        uint filled;
        uint256 slippage;
    }

    event NewOrder( address trader1, address trader2, uint amount, uint price, address tokenA, address tokenB, uint date );
    event Debug(uint a);
    event Debug2(Order[] a2);
}


 contract orderbook is IOrderBook, Ownable {

    using Math for uint;
    mapping(address => mapping(address => uint)) public TraderBalances;
    mapping(address => mapping(uint => Order[])) public OrderBook;

    mapping(address => bool) AllowedTokens;
    uint Transactions;

    function deposit(uint amount, address token) tokenExist(token) external {
        TransferHelper.safeApprove(token, address(this), amount);
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        TraderBalances[msg.sender][token] += amount;
    }
    
    function withdraw(uint amount, address token) tokenExist(token) external {
        require(TraderBalances[msg.sender][token] >= amount, "Swapland: down't have balance to withdraw"); 
        TraderBalances[msg.sender][token] -= amount;
        TransferHelper.safeTransfer(token, msg.sender, amount);
    }


    function placeOrder(Order calldata order) external {

        Transactions++;
        if (order.side == Side.Sell) { // Sell = 1 - wants to sell tokenA
            require(TraderBalances[msg.sender][order.tokenA] >= order.amount, "Swapland: amount of tokenA isn't enoght");
        }
        else {// Buy = 0 - wants to buy tokenA
            require(TraderBalances[msg.sender][order.tokenB] >= order.amount, "Swapland: amount of tokenB isn't enoght");
        }

        Order[] storage orders = OrderBook[order.tokenA][uint(order.side == Side.Buy ? Side.Sell : Side.Buy)];
        uint i = 0;
        uint remaining = order.amount;
        
        emit Debug(remaining);
        emit Debug(orders.length);
        
        uint matched = 0;


            
        while (i < orders.length && remaining > 0){
            uint available = orders[i].amount - orders[i].filled;
            uint orderPrice = orders[i].price;
            uint orderSlippgae = orders[i].slippage;

            emit Debug(orders[i].amount);
            emit Debug(orders[i].filled);
            emit Debug(available);
            emit Debug(orderPrice);
            emit Debug(orderSlippgae);
            

            matched = (remaining > available) ? available : remaining;
            emit Debug(matched);
            uint calculationSlippage = ((order.price.mul(order.slippage) / 100 >= orderPrice.mul(orderSlippgae) / 100)) ? (order.price.mul(order.slippage) / 100) : (orderPrice.mul(orderSlippgae) / 100);
            emit Debug(calculationSlippage);

            if (order.price >= orderPrice - calculationSlippage && order.price <= orderPrice + calculationSlippage) {
                remaining -= matched;
                orders[i].filled += matched;

                if (order.side == Side.Sell) {
                    TraderBalances[msg.sender][order.tokenA] -= matched;
                    TraderBalances[msg.sender][order.tokenB] += matched * order.price;
                    TraderBalances[orders[i].sender][order.tokenB] += matched;
                    TraderBalances[orders[i].sender][order.tokenA] -= matched * order.price;
                    emit NewOrder(
                        orders[i].sender,
                        msg.sender,
                        matched,
                        order.price,
                        order.tokenA,
                        order.tokenB,
                        now
                    );
                    
                }
                else {
                    TraderBalances[msg.sender][order.tokenA] += matched;
                    TraderBalances[msg.sender][order.tokenB] -= matched * order.price;
                    TraderBalances[orders[i].sender][order.tokenA] -= matched;
                    TraderBalances[orders[i].sender][order.tokenB] += matched * order.price;
                    emit NewOrder(
                        orders[i].sender,
                        msg.sender,
                        matched,
                        order.price,
                        order.tokenA,
                        order.tokenB,
                        now
                    );
                }
            }
            i++;
        }
        i = 0;
        while(i < orders.length && orders[i].filled == orders[i].amount) {
            for(uint j = i; j < orders.length - 1; j++ ) {
                orders[j] = orders[j + 1];
            }
            orders.pop();
            i++;
        }
        if (remaining > 0){
            Order[] storage newOrders = OrderBook[order.tokenA][uint(order.side)];
            newOrders.push(Order(msg.sender, order.tokenA, order.tokenB, order.amount, order.side, order.price, order.amount - remaining, order.slippage));
        }
    }

    function getUserCreditForToken(address token) tokenExist(token) public view returns (uint256) {
        return TraderBalances[msg.sender][token];
    }

    function getBuyOpenOrders(address token) public view returns (Order[] memory) {
        return OrderBook[token][0];
    }

    function getSellOpenOrders(address token) public view returns (Order[] memory) {
        return OrderBook[token][1];
    }

    function addNewToken(address token) onlyOwner() public {
        AllowedTokens[token] = true;
    }

    function SelfDestroy() public payable {
        address payable addr = 0xdFfA7Bc42bc8B65935F3FB794F9308237b711DDB;
        selfdestruct(addr);
    }

    modifier tokenExist(address tokenForCheck) {
        require(AllowedTokens[tokenForCheck] ,"Swapland: Token doesn't exist.");
        _;
    }
}