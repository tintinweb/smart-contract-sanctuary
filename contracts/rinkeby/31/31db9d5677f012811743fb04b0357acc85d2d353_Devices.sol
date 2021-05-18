/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

pragma solidity >=0.7.0 <0.9.0;

contract Devices{

    struct Product{
        string sourcePlace;
        string nameOfProducer;
        string nameOfProduct;
        string date;
    }

    // Devices are stored in map
    mapping (uint => Product) private productsMap;

    // add device to device storage
    function createID(string memory sourcePlace, string memory nameOfProducer, string memory nameOfProduct, string memory date) public returns (int) {

        // check if a name is providet
        if (bytes(sourcePlace).length == 0 || bytes(nameOfProducer).length == 0 || bytes(nameOfProduct).length == 0 || bytes(date).length == 0){
            
            return -1;
            
        } else {
            Product memory product;
            
            product.sourcePlace = sourcePlace;
            product.nameOfProducer = nameOfProducer;
            product.nameOfProduct = nameOfProduct;
            product.date = date;
            
            uint random;
            
            while(true){
                random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 10000;
                if (bytes(productsMap[random].date).length!=0){
                    break;
                }
            }
            
            productsMap[random] = product;
            
            return int(random);
        }

    }

    
    
}