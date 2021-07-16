//SourceUnit: bzAgreement_v2.sol

pragma solidity >=0.4.23 <0.6.0;

contract BzAgreement {
    
    address public owner;
	
	constructor() public {
        owner = address(0x41A5F5D93D645B8AA1C1C17753DEDF75D8335D9190);
	}
	
    event Registration(address indexed user, address indexed referrer, uint256 indexed amount);
	event UpgradeLevel(address indexed user, uint256 indexed amount);
    
    function registration(address referrerAddress) external payable {
		require(msg.value == 3000000);
        address(uint160(owner)).transfer(1000000);
		address(uint160(referrerAddress)).transfer(2000000);
        emit Registration(msg.sender, referrerAddress, msg.value);
    }
	
	function openNewLevel() external payable{
		require(msg.value == 2000000);
		address(uint160(owner)).transfer(msg.value);
		emit UpgradeLevel(msg.sender, msg.value);
	}
}