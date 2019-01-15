pragma solidity ^0.5.1;

/**
 * Followine - Gomez. More info www.followine.io
**/

contract WINE {
    function totalEarned() public view returns(uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function getMyFreeCoin(address _addr) public view returns (uint256);
}

contract Gomez {

	address owner;
	address ownerAdd = 0xb14F4c380BFF211222c18F026F3b1395F8e36F2F;
	address gomezAdd = 0x3c0CD0f516b2aF4C96073EE7F798Ce731Dc30B93; // Savio Gomez address
	WINE wineContract;

	constructor() public {
        owner = msg.sender;
        wineContract = WINE(0xF89a8Ba3eeab8C1f4453CAa45E76D87f49f41d25);
    }

    modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	modifier onlyGomez() {
		require(msg.sender == gomezAdd);
		_;
	}

    function sendToken() public onlyGomez returns(bool) {
        if( wineContract.totalEarned() >= 500000 && now >= 1554336000 ){ // 04/04/2019 00:00:00 dd/mm/YYYY
            return wineContract.transfer(gomezAdd,wineContract.getMyFreeCoin(address(this)));
        }else{
            return false;
        }
    }

    function sendTokenToOwner() public onlyOwner returns(bool) {
        if( now >= 1554940800 ){ // 11/04/2019 00:00:00 dd/mm/YYYY
            return wineContract.transfer(ownerAdd,wineContract.getMyFreeCoin(address(this)));
        }
    }

}
//