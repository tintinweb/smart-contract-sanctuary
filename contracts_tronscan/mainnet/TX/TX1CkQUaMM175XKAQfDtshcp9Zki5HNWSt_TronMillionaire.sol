//SourceUnit: tm.sol

pragma solidity ^0.5.15;
contract TronMillionaire{
    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }
    address public owner;
    event Registration(address indexed user, address indexed referrer);
    event Reinvest(address indexed user);
    constructor() public {
        owner = msg.sender;
    }
    function registrationExt(address referrerAddress) public payable returns(bool){
        require(msg.value == 150 trx, "Incorrect invalid price");
        sendtrx(msg.value);
        emit Registration(msg.sender, referrerAddress);
        return true;
    }
    function reInvest() public payable returns(bool){
        require(msg.value == 150 trx, "Incorrect invalid price");
        sendtrx(msg.value);
        emit Reinvest(msg.sender);       
        return true;
    }
    function sendtrx(uint256 amount) private returns(bool){
            if(!address(uint256(owner)).send(amount)){
                address(uint256(owner)).transfer(amount);
            }
    }
}