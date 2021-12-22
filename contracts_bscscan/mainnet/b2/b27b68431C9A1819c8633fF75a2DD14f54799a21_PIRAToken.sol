// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20.sol";
import "./BotPrevent.sol";

// Piratera Token
contract PIRAToken is BEP20 {
	BPContract public BP;
	bool public bpEnabled;

	event BPAdded(address indexed bp);
    event BPEnabled(bool indexed _enabled);
    event BPTransfer(address from, address to, uint256 amount);

	constructor() BEP20("Piratera Token", "PIRA", 18) {
		uint256 totalTokens = 1000000000 * 10**uint256(decimals());
		_mint(msg.sender, totalTokens);
	}

	function setBpAddress(address _bp) external onlyOwner {
        require(address(BP) == address(0), "Can only be initialized once");
        BP = BPContract(_bp);

        emit BPAdded(_bp);
    }

	function setBpEnabled(bool _enabled) external onlyOwner {
        require(address(BP) != address(0), "You have to set BP address first");
        bpEnabled = _enabled;
        emit BPEnabled(_enabled);
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

	/**
     * @dev Add the BP handler to prevents the bots.
     *
     **/
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (bpEnabled) {
            BP.protect(sender, recipient, amount);
            emit BPTransfer(sender, recipient, amount);
        }
        super._transfer(sender, recipient, amount);
    }

	function burn(uint256 amount) external {
		_burn(msg.sender, amount);
	}
}