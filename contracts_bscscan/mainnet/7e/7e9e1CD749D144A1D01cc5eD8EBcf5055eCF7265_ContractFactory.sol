pragma solidity 0.6.12;

import "./ContractFrame.sol";


contract ContractFactory{
    
    mapping(address => mapping(uint256 => ContractFrame)) public contracts;
    
    event coinCreated(uint256 id, address owner, ContractFrame token);
    event id_is(uint256 id);
    address _owner;
    uint256 public price;
    
    constructor() public{
        _owner = msg.sender;
    }
    
    function createCoin(string memory name, string memory symbol, uint256 totalSupply, uint8 decimals) external payable returns (uint256){
        if(msg.value < price){
            revert("you did not send enough bnb to create a token");
        }
        uint256 id = uint256(sha256(abi.encode(name, now)));
        contracts[msg.sender][id] = new ContractFrame(name, symbol, decimals, totalSupply, msg.sender);
        emit coinCreated(id, msg.sender, contracts[msg.sender][id]);
        return id;
    }
    
    function setPrice(uint256 bnb) public { 
        if(msg.sender == _owner){
            price = bnb;
        }
    }
    
    function withdrawlBNB() public {
        if(msg.sender == _owner){
            msg.sender.transfer(address(this).balance);
        }
    }
    
}