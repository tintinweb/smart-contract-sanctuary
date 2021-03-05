/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

pragma solidity 0.5.4;


contract ExchangeToken {
    
    // using SafeMath for uint256;
    
    uint256 input = 0 ;
    uint256 discount = 0 ;
    uint256 price = 0 ;
    
    uint256 p1 = 0;
    uint256 p2 = 0;
    uint256 p3 = 0;
    address owner;

    modifier onlyOwner(){
    require(msg.sender==owner);
    _;
    }
   
    function purchase(uint256 pric) public returns(uint256){
        uint256 disc = 10 * pric / 100;
        p1 = 40 * disc /100;
        p2 = 40 * disc /100 ;
        p3 = 10* disc /100 ;
    }
    
    function setPriceDiscount(uint256 pric, uint256 disc) public onlyOwner returns(uint256){
      setPrice(pric);
      setDiscount(disc);
    }
    
      function setPrice(uint256 pric) private returns(uint256){
        price = pric;
    }
     function setDiscount(uint256 disc) private returns(uint256){
        discount = disc;
    }
    
    function showData() public view returns(uint256,uint256,uint256, uint256 pri, uint256 dis, address ownr){
        return (p1, p2, p3, price ,discount, owner);
    }
    
}