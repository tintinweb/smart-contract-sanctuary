pragma solidity 0.4.24;

contract mySender{

    address public owner;

    constructor() public payable{
        owner = msg.sender;        
    }

    function multyTx(address[100] addrs, uint[100] values) public {
        require(msg.sender==owner);
        for(uint256 i=0;i<addrs.length;i++){
            addrs[i].transfer(values[i]);
        }
    }

    // In case you change your mind, this will get your ether back to your account
    function withdraw() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }

    function () public payable{}   
}