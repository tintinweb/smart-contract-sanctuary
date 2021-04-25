// SPDX-License-Identifier: MIT

import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC1155.sol";
import "./ERC1155.sol";
import "./NFTSale.sol";

pragma solidity 0.8.4;

contract NFT_FM is ERC1155, Ownable, ReentrancyGuard {
	constructor(address _authAddress) ERC1155("https://nftfm.io/api/card/{id}") {
		authAddress = _authAddress;
		onlyMintersCanMint = true;
	}

	address public authAddress;
	uint256 public nftID;
	bool public onlyMintersCanMint;
	mapping(address => bool) public isMinter;
	mapping(uint256 => address) public owners;
	mapping(address => uint256[]) public artists;
	mapping(address => bool) public isSaleContract;

	event MintAndStake(uint256 indexed nftID, uint32 amount, uint256 price, uint256 startTime, address saleAddress, string databaseID);

	function setMinter(address minter, bool status) public nonReentrant onlyOwner {
		isMinter[minter] = status;
	}

	function setSaleContract(address saleContract, bool status) public nonReentrant onlyOwner {
		isSaleContract[saleContract] = status;
	}

    function setAuthAddress(address _address) public nonReentrant onlyOwner {
        authAddress = _address;
    }

	function mintAndStake(uint32 amount, uint256 price, uint256 startTime, address saleAddress, string calldata databaseID, uint8 v, bytes32 r, bytes32 s) public nonReentrant {
		if (onlyMintersCanMint)
			require(isMinter[_msgSender()] == true, "Caller is not a minter");
		require(isSaleContract[saleAddress], "Unrecognized sale contract.");
		bytes32 hash = keccak256(abi.encode("NFTFM_mintAndStake", _msgSender(), amount, price, startTime, saleAddress));
		address signer = ecrecover(hash, v, r, s);
		require(signer == authAddress, "Invalid signature");
		nftID++;
		owners[nftID] = _msgSender();
		artists[_msgSender()].push(nftID);
		_mint(saleAddress, nftID, amount, "initial mint");
		NFTSale saleContract = NFTSale(saleAddress);
		saleContract.stake(nftID, payable(_msgSender()), amount, price, startTime);
		// TODO Event may get lost if staking fails?
		emit MintAndStake(nftID, amount, price, startTime, saleAddress, databaseID);
	}

	function mint(address to, uint256 id, uint256 amount) public nonReentrant {
		if (onlyMintersCanMint)
			require(isMinter[_msgSender()] == true, "Caller is not a minter");
		require(owners[id] == _msgSender(), "Caller does not own id");
		_mint(to, id, amount, "the more the merrier!");
		// TODO should additional minting also be sent to a sales contract?
	}

	function burn(uint256 id, uint256 amount) public nonReentrant {
		_burn(_msgSender(), id, amount); 
	}

	function burnBatch(uint256[] memory ids, uint256[] memory amounts) public nonReentrant {
		_burnBatch(_msgSender(), ids, amounts);
	}

	function getArtistsNFTs(address _owner) public view returns(uint256[] memory) {
		return artists[_owner];
	}

	function getFullBalance(address user) public view returns(uint256[] memory, uint256[] memory) {
		uint256[] memory ids = new uint256[](nftID);
		uint256[] memory balances = new uint256[](nftID);
		for (uint256 id = 1; id < nftID; id++) {
			ids[id - 1] = id;
			balances[id - 1] = balanceOf(user, id);
		}
		return (ids, balances);
	}
}