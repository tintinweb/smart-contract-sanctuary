/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.8.0;

contract Car_Sale{
    
    struct Car{
        
        
        uint256 ID;
        string car_name;
        address car_address;
        bool sold;
        uint256 price;
        address owner;
        }
    //structure to store car entity
    
    mapping(uint256=>Car) cars_collection;// stores car details
    address[] public carsAddresses;//stores car addresses
    mapping(address => Car) carowners;//stores car owners and track sales
    
    event CarAdded(address indexed car_address,uint indexed ID, string indexed car_name );
    event CarSold(address indexed car_address, uint indexed ID, address indexed Owner);
    
    //function to add cars
    function add_car(uint256 ID, string memory car_name, address car_address, bool sold, uint256 price, address owner) public
    
    {
        
        Car storage car = cars_collection[ID];
        car.ID=ID;
        car.car_name = car_name;
        car.car_address=car_address;
        car.sold=false;
        car.price=price;
        car.owner=address(0);
        
        carsAddresses.push(car_address);
        
        emit CarAdded(car_address,ID,car_name);
        
        
    }
    //function to get the car details
    function get_car(uint256 ID) public view returns(uint256,string memory,address,bool,uint256,address){
         
        require(cars_collection[ID].ID==ID,"Car ID doesnot match");
        return (cars_collection[ID].ID,cars_collection[ID].car_name,cars_collection[ID].car_address,cars_collection[ID].sold,cars_collection[ID].price,cars_collection[ID].owner);
        
        
    }
    //function to buy a car item
    function buy_car(address car_address, uint ID) public payable 
    {
        require(cars_collection[ID].ID==ID,"Car does not exist");
        require(cars_collection[ID].sold==false,"Car is already sold");
        require(msg.value>=cars_collection[ID].price, "Not enough Money Paid");
        cars_collection[ID].sold=true;
        cars_collection[ID].owner=msg.sender;
        Car storage car =cars_collection[ID];
        carowners[cars_collection[ID].owner]= car;
        emit CarSold(car_address,ID,msg.sender);
        
        
    }
    
    
}