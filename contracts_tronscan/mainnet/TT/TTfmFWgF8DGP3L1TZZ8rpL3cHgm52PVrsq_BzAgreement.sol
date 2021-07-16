//SourceUnit: bzAgreement.sol

pragma solidity >=0.4.23 <0.6.0;

contract BzAgreement {
    
    address public owner;
	
	constructor() public {
        owner = address(0x41349D6145BECD87F9267FEA037D66ABD67C38E9EE);
	}
	
    event Registration(address indexed user, address indexed referrer, uint256 indexed amount);
	event UpgradeLevel(address indexed user, uint256 indexed amount);
    
    function registration(address referrerAddress) external payable {
		require(msg.value == 150000000);
        address(uint160(owner)).transfer(50000000);
		address(uint160(referrerAddress)).transfer(100000000);
        emit Registration(msg.sender, referrerAddress, msg.value);
    }
	
	function openNewLevel() external payable{
		require(msg.value == 100000000);
		address(uint160(owner)).transfer(msg.value);
		emit UpgradeLevel(msg.sender, msg.value);
	}
}