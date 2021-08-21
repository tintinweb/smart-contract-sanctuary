/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

pragma solidity ^0.8.4;


contract CAR {
     
     // PARAMETROS NFT
    string public name = "CAR"; 
    string public symbol = "CAR"; 
    uint public decimals = 0;
    uint public totalSupply = 0; 
    address creator;
    address owner;

    
    
    struct Car {
        uint id;
        uint idCategory;
        uint idModel;
        address owner;
    }
    Car[] cars;
    
    
   
    event Transfer(address indexed from, address indexed to, uint value);
    event CarTransfer(address indexed from, address indexed to, uint256 carIndex);
    event Approval(address indexed owner, address indexed spender, uint value);

    event BuyedRecord(
        address indexed buyer,
        uint256 idModel,
        uint256 idCategory,
        uint    amount
    );
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    
  
    bool isPublicCategorySale = true;
    bool isPublicModelSale = false;
    address[] public scamers;
    
    constructor(){
        creator = msg.sender;
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == creator);
        _;
    }
    
    
    
    function balanceOf() external view returns(uint){
        return address(this).balance;
    }

    function whoisCreator() public view returns(address){
      return creator;
    }
    
    function changeCreator(address newOwner) public onlyOwner {
        creator = newOwner;
    }
    
    
    
    
    
    function transferCar(address _newOwner, uint _idCar) public {
        require(msg.sender == cars[_idCar - 1].owner);
        cars[_idCar - 1].owner = _newOwner;
        balances[msg.sender] -= 1;
        balances[_newOwner] += 1;
        
        emit Transfer(msg.sender, _newOwner, 1);
        emit CarTransfer(msg.sender, _newOwner, _idCar - 1);

        
    }
    
    
    function buyCar(uint _idCategory, uint _idModel) external payable {
        require(isPublicCategorySale == true);
        require(msg.value > 0);
        balances[msg.sender] += 1;
        cars.push(Car(cars.length + 1 ,_idCategory, _idModel, msg.sender));
        totalSupply += 1;
    
        emit BuyedRecord(msg.sender, _idModel, _idCategory, msg.value); 
    }
    
    
    
    function withdraw() public {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success,) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
    
    
    
    // CERRAR/ACTIVAR VENTAS
    function publicCategorySale(bool _state) public onlyOwner {
        isPublicCategorySale = _state; 
    }
    function publicModelSale(bool _state) public onlyOwner {
        isPublicModelSale = _state; 
    }
    
    
    
    

    
    function carsCount() public view returns(uint){
        return cars.length;
    }
    function getCars() external view returns(Car[] memory){ 
        return cars;
    }
   
    
    function getCarsCountByOwner(address _owner) public view returns(uint){
         uint ownerCars;
        
        for(uint i = 0 ; i < cars.length ; i++){
            if(cars[i].owner == _owner){
               ownerCars += 1;
            }
        }
        return  ownerCars;
    }
    
    
    
    
    function addScammer(address scamer) external onlyOwner {
        scamers.push(scamer);
    }
    
    function showScammers() public view returns(address[] memory) {
        return scamers;
        
    }
    
    
    
    
}