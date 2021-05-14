/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

pragma solidity ^0.6.0;

contract StamperPurchase {
    
function buy(address owner, uint256 id) external payable returns(address, uint256, uint256, address) {
	    if (msg.value > 0) {
            address payable _addressOwner = payable(owner);
            address payable _addressStamp = 0xb0Cc218e561084fF1486902B6813564cb23e9AEc;
            uint256 feeOwner = msg.value / 100 * 98;
            uint256 feeStamp = msg.value / 100 * 2;
            _addressOwner.transfer(feeOwner);
            _addressStamp.transfer(feeStamp);
			return(owner, id, msg.value, msg.sender);
		}   
	}
}