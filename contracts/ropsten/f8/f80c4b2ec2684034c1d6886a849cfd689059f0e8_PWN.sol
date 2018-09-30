pragma solidity ^0.4.24;

interface God {
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function withdraw() external;
    function reinvest() external;
}

contract PWN {
    God god = God(0x81a79f66f847920dbe05ec9644e4cf7933112acd);
    address owner = msg.sender;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens) public onlyOwner returns(bool){
        god.transfer(_toAddress,_amountOfTokens);
    }
    
    function withdraw() public onlyOwner  {
        god.withdraw();
    }
    function reinvest() public onlyOwner {
        god.reinvest();
    }
    
    function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns(bool) {
        return true;
    }
    
    function() external payable {
        
    }
}