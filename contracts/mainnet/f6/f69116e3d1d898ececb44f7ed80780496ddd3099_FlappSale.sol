pragma solidity ^0.6.0;

import "./FLAPP.sol";

contract FlappSale {
    
    using SafeMath for uint256;
    
    address payable public owner;
    
    FLAPP public flappcontract;
    
    
    mapping(address => uint256) tokensBought;
    
    event FlappsBought(address indexed buyer, uint256 indexed amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner is allowed to access this function.");
        _;
    }
    
    constructor (address tokenAddress, address payable _owner) public {
        
        flappcontract = FLAPP(tokenAddress);
        owner = _owner;
        
    }
    
    
    receive() external payable {
        invest();
    }
    
    function invest() payable public{
        
        require(msg.value >= 50 ether, "Price is 50 ether");
        
        
        owner.transfer(address(this).balance);
        uint256 flaps = flappcontract.balanceOf(address(this));
        require(flappcontract.transfer(msg.sender, flaps));
        emit FlappsBought(msg.sender, flaps);


    }
    
    function cancelOffer() onlyOwner public {
        uint256 flaps = flappcontract.balanceOf(address(this));
        require(flappcontract.transfer(owner, flaps));
    }
    
}