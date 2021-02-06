/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


interface cETHInterface {
	function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function redeem(uint256 amount) external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
}


interface cETHRedeemerInterface {
    function redeem(uint256 amount) external returns (uint256 receivedEther);
    function redeemUnderlying(uint256 amount) external returns (uint256 redeemedCEth);
    function redeemFor(address from, address to, uint256 amount) external returns (uint256 receivedEther);
    function redeemUnderlyingFor(address from, address to, uint256 amount) external returns (uint256 redeemedCEth);
}


/// Redeem cETH for ETH in cases where ETH payments cannot be accepted due to
/// the 2300 gas stipend used for ETH transfers on cETH. Approve this contract
/// to move cETH before calling.
/// @author 0age
contract cETHRedeemer is cETHRedeemerInterface {
	cETHInterface public constant cETH = cETHInterface(
		0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5
	);

    receive() external payable {
    	if (msg.sender != address(cETH)) {
    		revert("Only cETH can send Ether to this contract.");
    	}
    }

    function redeem(
    	uint256 amount
    ) external override returns (uint256 receivedEther) {
    	receivedEther = _redeemFor(msg.sender, msg.sender, amount);
    }

    function redeemUnderlying(
    	uint256 amount
    ) external override returns (uint256 redeemedCEth) {
     	redeemedCEth = _convertEthToCEth(amount);
    	_redeemFor(msg.sender, msg.sender, redeemedCEth);
    }

    function redeemFor(
    	address from, address to, uint256 amount
    ) external override returns (uint256 receivedEther) {
    	receivedEther = _redeemFor(from, to, amount);
    }

    function redeemUnderlyingFor(
    	address from, address to, uint256 amount
    ) external override returns (uint256 redeemedCEth) {
    	redeemedCEth = _convertEthToCEth(amount);
    	_redeemFor(from, to, redeemedCEth);
    }

    function _redeemFor(
    	address from, address to, uint256 amount
    ) internal returns (uint256 receivedEther) {
    	require(
    		cETH.transferFrom(from, address(this), amount),
    		"Transfer in failed... is allowance set on cETH for this contract?"
    	);
    	require(
    		cETH.redeem(amount) == 0,
    		"Redeeming cETH failed."
    	);

    	receivedEther = address(this).balance;
        (bool ok, ) = to.call{value: receivedEther}("");
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _convertEthToCEth(uint256 ethAmount) internal returns (uint256 cETHAmount) {
    	cETHAmount = (ethAmount * 1e18) / cETH.exchangeRateCurrent();
    }
}