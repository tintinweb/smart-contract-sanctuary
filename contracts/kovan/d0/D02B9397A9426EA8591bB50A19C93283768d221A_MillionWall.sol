/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

// SPDX-License-Identifier: Free-to-use

pragma solidity 0.8.5;
 
contract MillionWall{
    address payable owner;
  
    struct advSpace{
        uint price;
        string base64code;
        string caption;
        string url;
        bool occupied;
        address occupiedBy;
    }
   
    mapping (uint => advSpace) pic;
   
    constructor() payable{
        owner = payable(msg.sender);
    }
    
    function init(uint n, uint[] memory prices) public {
        require(msg.sender == owner);
        // building the advertising space
        for (uint i=n;i<n+prices.length;i++){
            if (pic[i].price == 0){ // initialization is allowed only once
                pic[i] = advSpace(uint(prices[i-n])*(10**14),"","","",false,address(0));    
            }
        }
    }
  
    function save(uint i, string memory code, string memory caption, string memory url) public payable{
        // check if space is free
        require (!pic[i].occupied || msg.sender == pic[i].occupiedBy);
        
        // check if payment is enough, caption/URL length meets the limits 
        require ( (msg.value >= pic[i].price || msg.sender == pic[i].occupiedBy) && bytes(caption).length <= 30 && bytes(url).length <= 50);
        
        // saving the picture in the blockchain memory
        pic[i].base64code = code;
        pic[i].occupied = true;
        pic[i].caption = caption;
        pic[i].url = url;
        pic[i].occupiedBy = msg.sender;
    }
    
    function get(uint i) public view returns (string memory, uint, string memory, address, string memory){
        return (pic[i].base64code, pic[i].price, pic[i].caption, pic[i].occupiedBy, pic[i].url);
    }
    
    function payoff(uint amount) public payable {
        require(msg.sender == owner);
        owner.transfer(amount);
    }
    
    
}