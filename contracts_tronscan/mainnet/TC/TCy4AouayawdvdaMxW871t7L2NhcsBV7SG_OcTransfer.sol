//SourceUnit: transfer.sol

/*This contract was made between OCGate and mahmoodpiri@gmail=>
    Your Vision , Our Creed
    https://ocgate.com
    support@ocgate.com
*/
pragma solidity >= 0.5.10;

contract OcTransfer{
    address payable _Owner;
    address payable OCUser;
    
    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    constructor(address payable _OCUSER ) public
    {
        _Owner = msg.sender;
        OCUser=_OCUSER;
        
    }
	
    function deposit(uint256 _val) public payable {
        require(msg.sender==_Owner,"Just Ocean Can deposit");
       _val = msg.value;
        emit Deposited(msg.sender, _val);
    }
    function withdraw() public {
        require(msg.sender==OCUser,"Just Ocuser Can withdraw balance");
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
        emit Withdrawn(msg.sender, balance);
    }
     function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
 
}