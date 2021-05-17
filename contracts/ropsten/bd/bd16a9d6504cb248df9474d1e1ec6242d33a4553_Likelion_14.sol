/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

//Sungrae Park

pragma solidity 0.8.0;

contract Likelion_14 {
    struct product {
        uint width;
        uint depth;
        uint height;
        uint weight;
        string element;
        bool luxury;
        uint price;
    }
    
    product[] products;
    
    function getPrice(uint w, uint d, uint h, uint weight,string memory material) public returns(uint,bool) {
        
        uint price = (w+d)*2*h*weight/125/100;
        bool _luxury;
        
        if(keccak256(abi.encodePacked(material)) == keccak256(abi.encodePacked("A"))){
            price = price * 125/100;
        }else if(keccak256(abi.encodePacked(material)) == keccak256(abi.encodePacked("B"))){
            price = price * 15/10;
        }else if(keccak256(abi.encodePacked(material)) == keccak256(abi.encodePacked("C"))){
            price = price * 3;
        }
        
       
        
        if(price>5000) {
            _luxury = true;
        }else {
            _luxury = false;
        }
        
        products.push(product(w,d,h,weight,material,_luxury,price));
        
        return(price,_luxury);
    }
}