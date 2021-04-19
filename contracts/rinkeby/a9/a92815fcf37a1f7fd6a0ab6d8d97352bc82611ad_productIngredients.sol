/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// Recording products ingredients on blockchain

pragma solidity ^0.4.20;


contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract productIngredients is owned{
    
    string public dAppPurpose = "Recording products ingredients on Blockchain";
    uint256 public size;
    
    
    struct productIngredientsTraces {
        string productName;
        uint productID;
        uint milk;
        uint egg;
        uint wheat;
        uint soya;
        uint nuts;
        uint shellfish;
    }
    
    productIngredientsTraces[] productIngredientsTracesRecords;
   
    
    // add product Ingredients 
    
    function addProductIngredients(string _productName, uint _productID, uint _milk, uint _egg, uint _wheat, uint _soya, uint _nuts, uint _shellfish) public payable returns(uint) {
        require(msg.sender==owner);
        size = productIngredientsTracesRecords.length++;
        productIngredientsTracesRecords[productIngredientsTracesRecords.length-1].productName = _productName;
        productIngredientsTracesRecords[productIngredientsTracesRecords.length-1].productID = _productID;
        productIngredientsTracesRecords[productIngredientsTracesRecords.length-1].milk = _milk;
        productIngredientsTracesRecords[productIngredientsTracesRecords.length-1].egg = _egg;
        productIngredientsTracesRecords[productIngredientsTracesRecords.length-1].wheat = _wheat;
        productIngredientsTracesRecords[productIngredientsTracesRecords.length-1].soya = _soya;
        productIngredientsTracesRecords[productIngredientsTracesRecords.length-1].nuts = _nuts;
        productIngredientsTracesRecords[productIngredientsTracesRecords.length-1].shellfish = _shellfish;
        return productIngredientsTracesRecords.length;
        }

    
    
    // search for product Ingredients using product ID
    
    function searchProductIngredients(uint _searchProductbyID) public constant returns(string, uint, uint, uint, uint, uint, uint){
    uint index =0;
    for (uint i=0; i<=size; i++){
            if (productIngredientsTracesRecords[i].productID == _searchProductbyID){
                index=i;
            }
        }
   
    return (productIngredientsTracesRecords[index].productName, productIngredientsTracesRecords[index].milk, productIngredientsTracesRecords[index].egg, productIngredientsTracesRecords[index].wheat, productIngredientsTracesRecords[index].soya, productIngredientsTracesRecords[index].nuts, productIngredientsTracesRecords[index].shellfish);
    }
    
    
}