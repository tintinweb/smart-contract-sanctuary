// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.4.22 <0.9.0;

import './IERC20.sol';

contract Exchange{
    // Define Struct
    struct Order{
        uint256 id;
        address from;
        uint256 amount;
    }
    // Define properties
    uint256 public length = 0;
    IERC20 token;
    Order[] public _orders;
    // mapping(address=>uint256) public _uncleared_balances;

    address public owner;

    // Define Modifiers
    modifier onlyAdmin(){
        require(msg.sender == owner,"Exchange: Action not Alowed!");
        _;
    }

    // Define Events
    event TransferIn(address indexed from,address indexed to, uint256 value, uint256 id);
    // event TransferOut(address indexed from,address indexed to, uint256 value);

    constructor(address _token){
        token = IERC20(_token);
        owner = msg.sender;
    }

    function setAdmin(address _new_admin) public virtual onlyAdmin{
        owner = _new_admin;
    }

    // A function is called to start Swaping Process 
    function transferIn(uint256 _value) public virtual{
        // Transfer Amount
        token.transferFrom(msg.sender, owner, _value);

        // Add to order
        Order memory _order;
        _order.id = length;
        _order.amount = _value;
        _order.from = msg.sender;
        _orders.push(_order);


        // Emit Event
        emit TransferIn(msg.sender, owner, _value, length);

        length +=1;
    }

    function checkStatus(uint256 _order_id) public virtual view returns(uint256 id,address from,uint256 amount){
        for(uint256 i = 0; i>=length;i++){
            if(_order_id ==_orders[i].id){
                return (_orders[i].id,_orders[i].from,_orders[i].amount);
            }
        }
    }

    function getOrders() public virtual view returns(Order[] memory){
        return _orders;
    }
}