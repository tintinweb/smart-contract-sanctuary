pragma solidity ^0.8.7;

import "./AllowanceCrowdsale.sol";

contract TRST0Crowdsale is Crowdsale, AllowanceCrowdsale {
	constructor(uint256 rate,    // rate in base units
        address payable wallet,
        ERC20 token)

        Crowdsale(rate, wallet) AllowanceCrowdsale(wallet, token) public {
	}

}