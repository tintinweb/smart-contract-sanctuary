// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.4.22 <0.9.0;

import './IERC20.sol';

contract Exchange{
    // Define Struct
    struct Order{
        uint256 id;
        string order_id;
        bool status;
        address to;
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
    event TransferIn(address indexed from,address indexed to, uint256 value);
    event TransferOut(address indexed from,address indexed to, uint256 value);

    constructor(address _token){
        token = IERC20(_token);
        owner = msg.sender;
    }

    function setAdmin(address _new_admin) public virtual onlyAdmin{
        owner = _new_admin;
    }

    // A function is called after Transfer  ZENITH -> ETH
    function transferOut(address _to, uint256 _value,string memory order_id) public virtual onlyAdmin{
        // Check Allowance
        require(token.allowance(msg.sender, address(this)) >= _value,"Exchange: Not Enough allowance!");

        // Check Balance
        require(token.balanceOf(msg.sender)>=_value,"Exchange: Not enough Token!");

        // Transfer amount
        token.transferFrom(msg.sender, _to, _value);


        length +=1;
        
        // Add to order
        Order memory _order;
        _order.id = length;
        _order.order_id = order_id;
        _order.status = true;
        _order.to = _to;
        _orders.push(_order);
        
        // Emit Event
        emit TransferOut(msg.sender,_to,_value);
    }

    // A function is called to start Swaping Process 
    function transferIn(uint256 _value) public virtual{
        // Check Allowance
        require(token.allowance(msg.sender, address(this)) >= _value,"Exchange: Not Enough allowance!");

        // Check Balance
        require(token.balanceOf(msg.sender)>=_value,"Exchange: Not enough Token!");

        // Transfer Amount
        token.transferFrom(msg.sender, owner, _value);

        // Emit Event
        emit TransferIn(msg.sender, owner, _value);
    }


    function checkStatus(uint256 _order_id) public virtual view returns(uint256 id,string memory order_id,bool status,address to){
        for(uint256 i = 0; i>=length;i++){
            if(_order_id ==_orders[i].id){
                return (_orders[i].id,_orders[i].order_id,_orders[i].status,_orders[i].to);
            }
        }
    }

    function getOrders() public virtual view returns(Order[] memory){
        return _orders;
    }
}