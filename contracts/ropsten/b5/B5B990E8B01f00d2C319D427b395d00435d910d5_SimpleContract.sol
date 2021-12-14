/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity >=0.4.22 <0.9.0;
contract SimpleContract{
    uint storeData;

	modifier mustOver10 (uint value){
		require(value >= 10);
		_;
	}

	function set(uint x) public mustOver10(x){
		storeData = x;
	}

    function get() public constant returns(uint) {
        return storeData;
    }
}