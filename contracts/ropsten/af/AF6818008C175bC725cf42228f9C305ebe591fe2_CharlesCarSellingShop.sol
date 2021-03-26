/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity >=0.4.25 <0.7.0;

contract CharlesCarSellingShop {
    
    enum CarState {Shipped, Store, Owned, Sale}
    address owner;
    uint public productCount = 0;
    

    struct Car 
    {
            uint carid;
            bytes32 name;
            bytes32 serialNo;
            uint price;
            bytes10 car_state; //later change to CarState
    }

    mapping(address => Car[]) OwnerOfProducts;
   
   event CarAddToInventory
    (
        uint carid,
        bytes32 name,
        bytes32 serlialNo,
        uint price,
        address owner,
        bytes10 car_state //later change to CarState
    );

    constructor() public {
            owner = msg.sender;
    }

    function createProduct(address _OwnerAddress, bytes32 _name, bytes32 _serialNo, uint _price, bytes10 _car_state) public {
        // Require a valid name
        require(_name.length > 0);
        // Require a valid price
        require(_price >= 0);
        // Require a valid serialNo
        require(_serialNo.length > 0);
        //Create new product
        Car memory p;
        //assign value to products
        p.carid = productCount++;
        p.name = _name;
        p.serialNo = _serialNo;
        p.price = _price;
        p.car_state = _car_state;
        OwnerOfProducts[_OwnerAddress].push(p);

        // Trigger an event
        emit CarAddToInventory(productCount, _name, _serialNo, _price, msg.sender, _car_state );
    }
}