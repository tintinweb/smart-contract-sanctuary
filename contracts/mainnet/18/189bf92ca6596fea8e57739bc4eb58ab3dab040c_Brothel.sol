pragma solidity ^0.4.17;

contract Brothel {
    address public manager;
    address public coOwner;
    mapping(address => bool) public hasAids;
    Ho[8] public hoes;
    
    struct Ho {
        address pimp;
        uint buyPrice;
        uint rentPrice;
        uint aidsChance;
    }
    
    function Brothel(address coown) public {
        manager = msg.sender;
        coOwner = coown;
        
        uint basePrice = 0.002 ether;
        uint size = hoes.length;
        uint baseAidsChance = 7;
        
        for (uint i = 0; i<size; i++) {
            Ho hoe = hoes[i];
            hoe.pimp = manager;
            hoe.buyPrice = basePrice*(i+1);
            hoe.rentPrice = hoe.buyPrice/10;
            hoe.aidsChance = baseAidsChance + (i*4);
        }
    }
    
    function withdraw() public restricted {
        uint leBron = address(this).balance*23/100;
        coOwner.transfer(leBron);
        manager.transfer(address(this).balance);
    }
    
    function buyHo(uint index) public payable{
        Ho hoe = hoes[index];
        address currentPimp = hoe.pimp;
        uint currentPrice = hoe.buyPrice;
        require(msg.value >= currentPrice);
        
        currentPimp.transfer(msg.value*93/100);
        hoe.pimp = msg.sender;
        hoe.buyPrice = msg.value*160/100;
    }
    
    function rentHo(uint index) public payable {
        Ho hoe = hoes[index];
        address currentPimp = hoe.pimp;
        uint currentRent = hoe.rentPrice;
        require(msg.value >= currentRent);
        
        currentPimp.transfer(msg.value*93/100);
        if (block.timestamp%hoe.aidsChance == 0) {
            hasAids[msg.sender] = true;
        }
    }
    
    function setRentPrice(uint index, uint newPrice) public {
        require(msg.sender == hoes[index].pimp);
        hoes[index].rentPrice = newPrice;
    }

    function sendMoney() public payable restricted {
    }
    
    function balance() public view returns(uint) {
        return address(this).balance;
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}