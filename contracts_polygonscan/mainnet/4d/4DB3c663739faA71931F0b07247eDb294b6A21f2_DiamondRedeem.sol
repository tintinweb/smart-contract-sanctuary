// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";

import "./FeatherToken.sol";

// Forked from Hermes Defi (objects changed, vars same for diff check)
contract DiamondRedeem is Ownable, ReentrancyGuard {

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    FeatherToken public fenix;
    address public irisAddress;

    uint256 public startBlock;

    bool public hasBurnedUnsoldPresale = false;

    event irisAddressChanged(address irisAddress);
    event irisSwap(address sender, uint256 amount);
    event burnUnclaimedIris(uint256 amount);
    event startBlockChanged(uint256 newStartBlock);

    constructor(uint256 _startBlock, address _fenixAddress, address _irisAddress) {
        require(_fenixAddress != _irisAddress, "fenix cannot be equal to iris");
        startBlock   = _startBlock;
        fenix = FeatherToken(_fenixAddress);
        irisAddress  = _irisAddress;
    }

    function swapFeatherForDiamond(uint256 swapAmount) external nonReentrant {
        require(block.number >= startBlock, "iris redemption hasn't started yet, good things come to those that wait ;)");
        require(IERC20(irisAddress).balanceOf(address(this)) >= swapAmount, "Not Enough tokens in contract for swap");
        fenix.transferFrom(msg.sender, BURN_ADDRESS, swapAmount);
        IERC20(irisAddress).transfer(msg.sender, swapAmount);

        emit irisSwap(msg.sender, swapAmount);
    }

    function sendUnclaimedIrisToDeadAddress() external onlyOwner {
        require(block.number > fenix.endBlock(), "can only send excess iris to dead address after presale has ended");
        require(!hasBurnedUnsoldPresale, "can only burn unsold presale once!");

        require(fenix.fenixRemaining() <= IERC20(irisAddress).balanceOf(address(this)),
            "burning too much iris, founders may need to top up");

        if (fenix.fenixRemaining() > 0)
            IERC20(irisAddress).transfer(BURN_ADDRESS, fenix.fenixRemaining());
        hasBurnedUnsoldPresale = true;

        emit burnUnclaimedIris(fenix.fenixRemaining());
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;

        emit startBlockChanged(_newStartBlock);
    }

    function setDiamondAddress(address _irisAddress) external onlyOwner {
    	require(block.number < startBlock, "cannot change start block if sale has already commenced");
	irisAddress = _irisAddress;

	emit irisAddressChanged(_irisAddress);
    }
}