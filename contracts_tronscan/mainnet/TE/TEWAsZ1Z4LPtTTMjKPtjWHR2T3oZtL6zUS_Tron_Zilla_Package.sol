//SourceUnit: TronZilla.sol

pragma solidity 0.5.10;

/**
*
* 
*Publish Date:30th Dec 2021
* 
*Final Publish Date:30th Dec 2021
* 
*Coding Level: High
* 
*Tron Zilla TRX COMMUNITY
*
* 
**/

contract Tron_Zilla_Package {
    
    uint8 public constant LAST_PACKAGE = 8;

    mapping(uint8 => uint) public TronZillaPackage;
    
    address public owner;

    constructor(address ownerAddress) public {
 
        TronZillaPackage[1] = 250;
        TronZillaPackage[2] = 500;
        TronZillaPackage[3] = 1000;
		TronZillaPackage[4] = 5000;
        TronZillaPackage[5] = 10000;
        TronZillaPackage[6] = 15000;
		TronZillaPackage[7] = 25000;
		TronZillaPackage[8] = 50000;
		 
        owner = ownerAddress;
        
    }
    
    function buyTronZillaPackage() external payable {
        address(uint160(owner)).transfer(address(this).balance);
    }
    
}