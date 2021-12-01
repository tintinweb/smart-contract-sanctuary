// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract BDBattle2 is Context, Ownable
{
	address public authAddress;
	address public holdingAddress;
	IERC20 public dcToken;
	IERC20 public bdtToken;

	uint256 public entryFee = 2e18;
	uint256 public winAmountDC = 4e18;
	uint256 public lossAmountDC = 0;
	uint256 public winAmountBDT = 4e18;
	uint256 public lossAmountBDT = 0;

	mapping(address => uint256) public nextClaimableID;
	uint256 private fightID;

	event Fight(uint256 indexed id, address challenger, uint256 enemy);

	constructor(uint256 startID, address dc, address bdt, address _authAddress, address _holdingAddress)
	{
		fightID = startID;
		dcToken = IERC20(dc);
		bdtToken = IERC20(bdt);
		authAddress = _authAddress;
		holdingAddress = _holdingAddress;
	}

	function setAuthAddress(address _authAddress) public onlyOwner
	{
		authAddress = _authAddress;
	}

	function setHoldingAddress(address _holdingAddress) public onlyOwner
	{
		holdingAddress = _holdingAddress;
	}

	function setDC(address dc) public onlyOwner
	{
		dcToken = IERC20(dc);
	}

	function setBDT(address bdt) public onlyOwner
	{
		bdtToken = IERC20(bdt);
	}

	function setValues(uint256 _entryFee, uint256 _winAmountDC, uint256 _lossAmountDC, uint256 _winAmountBDT, uint256 _lossAmountBDT) public onlyOwner
	{
		entryFee = _entryFee;
		winAmountDC = _winAmountDC;
		lossAmountDC = _lossAmountDC;
		winAmountBDT = _winAmountBDT;
		lossAmountBDT = _lossAmountBDT;
	}

	function setEntryFee(uint256 _entryFee) public onlyOwner
	{
		entryFee = _entryFee;
	}

	function setWinDC(uint256 winDC) public onlyOwner
	{
		winAmountDC = winDC;
	}

	function setLossDC(uint256 lossDC) public onlyOwner
	{
		lossAmountDC = lossDC;
	}

	function setWinBDT(uint256 winBDT) public onlyOwner
	{
		winAmountBDT = winBDT;
	}

	function setlossBDT(uint256 lossBDT) public onlyOwner
	{
		lossAmountBDT = lossBDT;
	}

	function challenge(uint256 enemyID) public
	{
		dcToken.transferFrom(_msgSender(), holdingAddress, entryFee);
		emit Fight(fightID, _msgSender(), enemyID);
		fightID++;
	}

	function totalRedeemable(uint256 won, uint256 lost) public view returns (uint256[2] memory)
	{
		return [
			won * winAmountDC + lost * lossAmountDC,
			won * winAmountBDT + lost * lossAmountBDT
		];
	}

	function batchRedeem(uint256 startID, uint256 endID, uint256 won, uint256 lost, uint8 v, bytes32 r, bytes32 s) public
	{
		bytes32 hash = keccak256(abi.encode("BDBattle2_batchRedeem", startID, endID, won, lost, _msgSender()));
		address signer = ecrecover(hash, v, r, s);
		require(signer == authAddress, "Invalid signature");
		require(startID >= nextClaimableID[_msgSender()], "Some or all winnings already claimed.");
		nextClaimableID[_msgSender()] = endID;
		dcToken.transferFrom(holdingAddress, _msgSender(), won * winAmountDC + lost * lossAmountDC);
		bdtToken.transferFrom(holdingAddress, _msgSender(), won * winAmountBDT + lost * lossAmountBDT);
	}
}