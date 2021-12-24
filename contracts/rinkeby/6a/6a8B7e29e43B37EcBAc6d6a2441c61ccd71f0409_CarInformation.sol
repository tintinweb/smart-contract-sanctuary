/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

pragma solidity >=0.8.0 <=0.8.11;

contract CarInformation{

struct Car{
    string name;
    string color;
    uint yearofmanufacturing;
    bool registered;
}
mapping (uint =>address)public ownerOfCar;
mapping (address=>uint)public ownersNumberOfCars;
address private _owner=msg.sender;


modifier onlyOwner() {
    require(isOwner());
    _;
}
function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

Car [] public cars;
function createCar(uint _id,string memory _color,string memory _name,uint _yearofmanufacturing) public {
    ownerOfCar[_id]=msg.sender;
    ownersNumberOfCars[msg.sender]++;
  cars.push(Car(_color,_name,_yearofmanufacturing,false));
  (cars[_id].color, cars[_id].name, cars[_id].yearofmanufacturing)=(_color,_name,_yearofmanufacturing);
  
}
// funkcija vraca stanje sa adrese ovog contracta
 function contractBalance() external view returns (uint) {
        return address(this).balance;
    }
//funkcija vraca stanje sa adrese contracta koji koristi ovu aplikaciju
    function contractUserBalance() external view returns (uint) {
        return address(msg.sender).balance;
    }
function changeColor(string memory _color,uint _id) external payable onlyOwner  {
    
    require(msg.value==10000 wei);
    cars[_id].color=_color;
    
}

function registerCar(uint _id)external payable  onlyOwner{
    if(cars[_id].registered==false){
    require(msg.value== 20000 wei);
    cars[_id].registered=true;
    }
   
}
}