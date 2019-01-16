pragma solidity >= 0.5.1;
contract Agri{
    address payable admin = 0x57e4922bB31328E5e05694B308025C44ca3fB135;
    mapping(bytes32 => uint) public itemPrices;
    event ItemBought(string item, uint quantity, address customer);
    constructor () public{
        itemPrices[keccak256(abi.encodePacked("Coffee"))] = 10000000;
        itemPrices[keccak256(abi.encodePacked("Fish"))] = 100000000000000;
        itemPrices[keccak256(abi.encodePacked("Beef"))] = 100000000;
    }
    function purchaseItem(string memory item, uint quantity) public payable returns(bool success){
        require(msg.value >= itemPrices[keccak256(abi.encodePacked(item))] * quantity);
        require(itemPrices[keccak256(abi.encodePacked(item))] != 0);
        admin.transfer(itemPrices[keccak256(abi.encodePacked(item))] * quantity);
        if(msg.value >= itemPrices[keccak256(abi.encodePacked(item))] * quantity)
            msg.sender.transfer(msg.value - (itemPrices[keccak256(abi.encodePacked(item))] * quantity));
        emit ItemBought(item, quantity, msg.sender);
    }
}