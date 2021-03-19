/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity ^0.7.5;

interface minereum {
    function availableBalanceOf(address _owner) external view returns (uint balance);
}

contract erc20Validation
{	

minereum public _minereum;

constructor() {
    _minereum = minereum(0x426CA1eA2406c07d75Db9585F22781c096e3d0E0);
}

function balanceOf(address seller, address tokenAddress) public view returns(uint balance)
{
	return _minereum.availableBalanceOf(seller);
}
}