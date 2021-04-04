/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

contract charlesCars {
    

    struct Car{
        bytes[] modelNo;
        CarData[] _data;
        mapping(bytes => uint) _index;
    }
    
    struct CarData {
        string name;
        uint date;
    }
    
    struct Sales {
        uint[] price;
        address[] soldTo;
        uint[] _carIndex;
    }
    
    Car car;
    Sales sales;

    address admin;
    
    modifier onlyOwner {
      //require(msg.sender == admin, "403: Forbidden");
        _;
    }

    
    /**
     @dev Emitted when a cal model is added
     @param model car model name
     */
    event CarAdded(bytes model);

    /**
     @dev Emitted when a cal is sold
     @notice This event is used by the frontend to populate data.
     @param model car model name
     @param buyer buyer's ethereum address
     @param price Price of the car
     */
    event Sold(bytes model, address buyer, uint price);

    constructor() {
      admin = msg.sender;
    }
    
    /**
      @dev Adds a new car model.
      @param _data tuple of carName and date //['Tesla',1617534279]
      @param _model model name in bytes
     */
    function addCar(CarData memory _data, bytes memory _model) public onlyOwner returns (bool){

      if(car._data.length != 0) {
        require(car._index[_model] == 0, 'Already added');
      }
        car.modelNo.push(_model);
        car._data.push(_data);
        car._index[_model] = car._data.length -1 ;
        
        emit CarAdded(_model);
        
        return true;
    }
    
    
    /**
      @dev Index starts from 1 
      @notice Retuns the car's detail based on the passed index
      @param _index Index of the car
      @return model Car's model name in bytes
      @return name Car's name 
      @return date 
     */
    function getCarByIndex(uint _index) public view returns (bytes memory model, string memory name, uint date) {
        return (car.modelNo[_index], car._data[_index].name, car._data[_index].date);
    }
    
    /**   
      @notice Retuns the car's detail using model.
      @param _model model of the car in bytes
      @return model Car's model name in bytes
      @return name Car's name 
      @return date  
      */
      
    function getCarByModel(bytes memory _model) public view returns (bytes memory model, string memory name, uint date) {
        uint index = car._index[_model];
        return (car.modelNo[index], car._data[index].name, car._data[index].date);
    }
    
    /**
      @dev Used to add a buy trnsaction.
      @param _model model of the car in bytes
      @param _buyer Ethereum address of the buyer
      @param _price Price of the car
      @param _carIndex Car Index. (from getCarByIndex)
      */
    function sold(bytes memory _model, address _buyer, uint _price, uint _carIndex) public onlyOwner returns (bool){
        sales.price.push(_price);
        sales.soldTo.push(_buyer);
        sales._carIndex.push(_carIndex);
        
        emit Sold(_model, _buyer, _price);
        return true;
    }
    
    /**
        @dev Use Events to get soldCar details
        @notice gets all the information about sold transactions
    */
    function getAllSoldCars() public view returns (Sales memory) {
        return sales;
    }
    
}