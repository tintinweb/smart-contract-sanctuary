pragma solidity ^0.4.24;

contract Bank{
    mapping(address=>uint256) public balances;
    address[] public addresses;
    
    function deposit() public payable{
        balances[msg.sender] += msg.value;
        addresses.push(msg.sender);
    }
    
    function withdraw() public {
        for(uint i=0;i<addresses.length;i++){
            addresses[i].transfer(balances[addresses[i]]);
            balances[addresses[i]] = 0;
        }
        delete addresses;
    }
}