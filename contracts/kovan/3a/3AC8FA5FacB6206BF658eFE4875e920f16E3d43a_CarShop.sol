/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity 0.8.4;



contract CarShop{
    
    address public admin;
    
    mapping (address=>bool) public isEmployee;
    
    mapping (bytes=>bool) internal carExists;
    
    mapping (uint=>CarContext) public carInventory;
    
    struct CarContext {
        uint stock;
        CarSale[] soldCars;
    }
    
    struct Car {
        string brand;
        string make;
        string year;
    }
    
    struct CarSale {
        address buyer;
        uint price;
    }
    
    Car[] public carTypes;
    
        constructor () {
        admin = msg.sender;
        }
    
    
    //add new type of car
    function addCar ( string memory _brand, string memory _make, string memory _year) onlyAdminOrEmployee public returns (uint) {
        bytes memory tempName = abi.encodePacked(_brand, _make, _year);
        
        require(carExists[tempName]==false,'Car already exists');
        
        carExists[tempName]=true;
        
        carTypes.push(Car({
            brand:_brand,
            make:_make,
            year:_year
        }));
        
        
        return carTypes.length-1;
    }
    
    
    //incremnt stock of a car with carId
    function addCarStock ( uint _carId,uint amount) onlyAdminOrEmployee public {
        require(_carId<carTypes.length,'Car with the given id does not exist');
        
        carInventory[_carId].stock += amount;
        
    }
    
    
    //record car sales 
    function addCarSale (uint _carId, address _buyer, uint _price) onlyAdminOrEmployee public {
        require(carInventory[_carId].stock>0 , "Not enought cars in stock");
        
       carInventory[_carId].stock -= 1;
       
       carInventory[_carId].soldCars.push(CarSale({
           buyer:_buyer,
           price:_price
       }));
    }
    
    
    //Get number of sales for a car using carId
    function getTotalSalesForCar(uint _carId) onlyAdminOrEmployee public view returns (uint){
            return carInventory[_carId].soldCars.length;
    }
    
    
    //get buyer address and selling price for a car sale.
    function getCarSaleDetails(uint _carId,uint _saleId) onlyAdminOrEmployee public view returns (address,uint) {
            address buyer = carInventory[_carId].soldCars[_saleId].buyer;
            uint price = carInventory[_carId].soldCars[_saleId].price;
            return (buyer,price);
    }
    
    
    //add a new employee
    function addEmployee (address _emp) onlyAdmin public {
        
        require(isEmployee[_emp]==false,'Employee already exists');
        
        isEmployee[_emp] = true;
        
    }
    
    
    //remove existing employee
     function removeEmployee (address _emp) onlyAdmin public {
        
        require(isEmployee[_emp]==true,'Employee does not exists');
        
        isEmployee[_emp] = false;
        
    }
    
    modifier onlyAdmin {
        require(msg.sender==admin, 'Only admin allowed');
        _;
    }
    
    modifier onlyAdminOrEmployee {
        require(msg.sender == admin || isEmployee[msg.sender]==true,'Only admin or employee allowed');
        _;
    }
}