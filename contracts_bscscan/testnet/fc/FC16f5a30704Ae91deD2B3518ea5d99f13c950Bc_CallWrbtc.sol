// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;
interface IWrapped {
    function balanceOf(address) external returns(uint);

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "../interface/IWrapped.sol";

contract CallWrbtc {

	IWrapped public wrbtc;

	constructor(address _wrbtcAddr) {
		setWrbtc(_wrbtcAddr);
	}

	receive() external payable {
		// The fallback function is needed to use WRBTC
		assert(msg.sender == address(wrbtc));
	}

	function setWrbtc(address _wrbtcAddr) public {
		wrbtc = IWrapped(_wrbtcAddr);
	}

	function deposit() public payable {
		wrbtc.deposit{ value: msg.value }();
	}

	function withdraw(uint256 wad) public {
		wrbtc.withdraw(wad);
		address payable senderPayable = payable(msg.sender);
		(bool success, ) = senderPayable.call{value: wad, gas:23000}("");
		require(success, "CallWrbtc: transfer fail");
	}

}