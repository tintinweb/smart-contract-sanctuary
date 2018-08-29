pragma solidity ^0.4.21;

contract WannabeSmartInvestor {
    
    address private owner;
    mapping(address => uint) public incomeFrom;

    constructor() public {
        owner = msg.sender;
    }
    
    function invest(address _to, uint _gas) public payable {
        require(msg.sender == owner);
        require(_to.call.gas(_gas).value(msg.value)());
    }
    
    function withdraw() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }

    function () public payable {
        incomeFrom[msg.sender] = incomeFrom[msg.sender] + msg.value;
    }     

}