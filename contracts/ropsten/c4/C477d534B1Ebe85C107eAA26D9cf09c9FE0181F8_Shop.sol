/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity >= 0.8.0;

contract Product{
    address thisProdAddr = address(this);
    address owner;
    string name;
    uint16 cost;

    constructor(string memory _name, uint16 _cost) public
    {
        name = _name;
        cost = _cost;
        owner = msg.sender;
    }
    
    function get_name() public view returns(string memory){
        return name;
    }
    
    function get_cost() public view returns(uint16){
        return cost;
    }
    
    function get_address() public view returns(address){
        return thisProdAddr;
    }
    
    function set_cost(uint16 _cost) public payable{
        require(owner == msg.sender);
        cost = _cost;
    }
}


contract Shop{
    address[] products;
    address owner;
    
    constructor() public{
        owner = msg.sender;
    }
    
    function add_prod(string memory _name, uint16 _cost) public payable{
        require(owner == msg.sender);
        products.push(address(new Product(_name, _cost)));
    }
    
    function get_products() public view returns(string[] memory, uint16[] memory, address[] memory){
        string[] memory names = new string[](products.length);
        uint16[] memory costs = new uint16[](products.length);
        address[] memory adresses = new address[](products.length);
        
        for(uint32 i; i < products.length; i++){
            names[i] = Product(products[i]).get_name();
            costs[i] = Product(products[i]).get_cost();
            adresses[i] = Product(products[i]).get_address();
        }
        return (names, costs, adresses);
    }
}