pragma solidity ^0.8.0;


contract Token{
    uint256 public price = 2 ether;
    address public owner;
    address public shopAddress;

    constructor() {
        owner = msg.sender;// address from which this contract was start
        //0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
        shopAddress = address(this);//address our contract
        //0xd9145CCE52D386f254917e481eB44e9943F39138sss
    }

    function getBalance() public view returns(uint) {
        return shopAddress.balance;
    }

    receive() external payable {
        
        
    }

}