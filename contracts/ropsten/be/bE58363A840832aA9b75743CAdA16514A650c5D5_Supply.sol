/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

pragma solidity 0.8.7;
contract Supply {
     struct  Product {
         string  productname;
         uint     price;
     }
     struct Distributor{
         string vessel_name;
         string productname;
     }
     struct Retailer{
         string shopname;
         string productname;
     }
struct History {
    Product[] one;
    Distributor[] two;
    Retailer[] three;
}
      address public producer;
      address public  dist;
      address public retail;

      constructor(){
        producer = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        dist  = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        retail = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;

      }
    //History[] public  history;
    mapping(string => Product) private product;
    mapping(string => Product[]) private arrayone;
    mapping(string => Distributor)private distributor;
    mapping(string => Retailer) private retai;
    mapping(string => History) private histo;
      function  addproduct(string memory _productname,uint _price) public {
        require(msg.sender == producer,"you are not the producer");
        Product  storage produces = product[_productname];
        produces.productname = _productname;
        produces.price = _price;
         
         arrayone[_productname].push(produces);
      histo[_productname].one.push(produces);


      }

      function getProduct(string memory _product) public  view returns(Product[] memory){
        return arrayone[_product];
      }
      
      function  adddist(string memory _productname,string memory _vessel) public {
        //require(msg.sender ==  dist,"you are not the distributor");

        Distributor  storage dists  =  distributor[_productname];
        dists.productname = _productname;
        dists.vessel_name = _vessel;

       
         histo[_productname].two.push(dists);

      }

function  addretail(string memory _productname,string memory  _shop) public { 
    
       // require(msg.sender == retail,"you are not the retailer");
        Retailer storage rett = retai[_productname];
        rett.productname = _productname;
        rett.shopname  = _shop;
        histo[_productname].three.push(rett);
         
      }

function getHistory(string memory _productname) public view  returns(Product[] memory,Distributor[] memory,Retailer[] memory){
    
return (histo[_productname].one,histo[_productname].two,histo[_productname].three);

}
}