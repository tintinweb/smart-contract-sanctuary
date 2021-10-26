pragma solidity ^0.8.7;

import "./ERC20.sol";

/**
 * @title TRST0
 * @dev 0-version of TRST, not providing any obligations from developers and publishers,
 * but allowing the community to support the Trood initiative.
 * Please contact founders and contributors for more information.
 * TRST0 is a fixed supply token, the supposed supply is 300.000 TRST
 * The Crowdsale coming along with the TRST0 contract presumes full sale of the whole amount from the Owner's account for 200 TRST per 1 BNB
 *
 */
contract TRST0 is ERC20 {

	constructor(string memory name_, string memory symbol_, address payable owner_, uint256 supply_) ERC20(name_, symbol_) public {
		_mint(owner_, supply_);
	}

}