// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.6.99 <0.8.0;
import "./Wallet.sol";
contract WalletFactory {

	mapping(address => address[]) wallets;

	event Created(address wallet, address from, address to, uint iterations, uint unlockStartDate, uint unlockEndDate);

	function getWallets(address _user)
  	public
  	view
  returns(address[] memory)
  {
  	return wallets[_user];
	}

	function newWallet(address _owner, address _relayer, uint _iterations, uint _unlockStartDate, uint _unlockEndDate)
		public
		payable
	{
		address wallet = address(new Wallet(msg.sender, _owner, _relayer, _iterations, _unlockStartDate, _unlockEndDate));
    wallets[msg.sender].push(wallet);

    if(msg.sender != _owner){
      wallets[_owner].push(wallet);
    }

		payable(wallet).transfer(msg.value);
		emit Created(wallet, msg.sender, _owner, _iterations, _unlockStartDate, _unlockEndDate);
	}
}
