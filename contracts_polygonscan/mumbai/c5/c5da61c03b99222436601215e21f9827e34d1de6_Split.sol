// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./Address.sol";

contract Split is Ownable{
	address private _canna;
	address private _despe;

	constructor(address cannaWallet, address despeWallet) {
		_canna = cannaWallet;
		_despe = despeWallet;
	}

	function setCannaAddress(address cannaWallet) external onlyOwner {
		_canna = cannaWallet;
	}

	function setDespeAddress(address despeWallet) external onlyOwner {
		_despe = despeWallet;
	}

	function splitETH() external payable{
		Address.sendValue(payable(_canna), (msg.value/2) + (msg.value%2));
		Address.sendValue(payable(_despe), msg.value/2);
	}

	function splitERC20(address token, uint256 amount) external {
		IERC20 erc20Contract = IERC20(token);
		erc20Contract.transferFrom(msg.sender, _canna, (amount/2) + (amount%2));
		erc20Contract.transferFrom(msg.sender, _despe, (amount/2));
	}
}