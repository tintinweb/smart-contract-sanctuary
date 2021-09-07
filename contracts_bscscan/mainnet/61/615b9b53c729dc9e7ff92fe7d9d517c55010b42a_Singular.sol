// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Singular is ERC20, Ownable {
    mapping (address => bool) public claimed;
    mapping (address => uint256) public referrals;

    constructor() ERC20("Singular", "SNG") {}
	
    function claim() public {
        require((totalSupply() + (2000 * (10 ** 18))) < (10000000 * (10 ** 18)), "The airdrop is ended!");
        require(claimed[_msgSender()] != true, "The airdrop is already claimed!");
		
		_mint(_msgSender(), 2000 * (10 ** 18));
        claimed[_msgSender()] = true;
	}
	
    function claimReferrer(address referrer) public {
        require((totalSupply() + (2000 * (10 ** 18))) < (10000000 * (10 ** 18)), "The airdrop is ended!");
        require(claimed[_msgSender()] != true, "The airdrop is already claimed!");
		
		if (_msgSender() != referrer) {
			_mint(referrer, 1000 * (10 ** 18));
			referrals[referrer] += 1;
		}
		
		_mint(_msgSender(), 2000 * (10 ** 18));
        claimed[_msgSender()] = true;
	}
}