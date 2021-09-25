/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

pragma solidity 0.6.0;

contract brand{
    string Brands;
    function setBrand(string memory _brand)public {
        Brands = _brand;
    }
    function getBrand()public view returns(string memory){
        return Brands;
    }
}

contract name{
    string Name;
    function setName(string memory _name)public {
        Name = _name;
    }
     function getName()public view returns(string memory){
        return Name;
    }
}
contract model{
    uint256 Models;
    function setModel(uint256 _year)public returns(uint256){
        Models = _year;
    }
     function getModel()public view returns(uint256){
        return Models;
    }
}

contract Details is brand, name, model{
    brand a = new brand();
    name b = new name();
    model c = new model();
   event brandCaller(string); 
    function getDetails()public returns(string memory){
    emit brandCaller(Brands);
    return a.getBrand();
    
    }
}