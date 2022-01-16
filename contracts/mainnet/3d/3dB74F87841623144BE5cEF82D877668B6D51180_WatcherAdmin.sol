// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// Who brought you here?
contract WatcherAdmin {
	mapping(address => bool) public isAdmin;
	bool private killswitchActive;

	address public JDWUHRBCBW;

	address public owner;
	address public authorizer;

	AdminMinter public minter;

	// ZFF3NHc5V2dYY1E=
	constructor(
		address _owner,
		address _authorizer,
		address _minter
	) {
		owner = _owner;
		authorizer = _authorizer;
		minter = AdminMinter(_minter);
	}

	// 104 116 116 112 115 58 47 47 105 109 103 117 114 46 99 111 109 47 97 47 74 115 102 65 67 120 54
	modifier isAuthorized() {
		require(killswitchActive == false, "Killswitch has been activated");
		require(
			isAdmin[msg.sender] == true ||
				msg.sender == owner ||
				msg.sender == authorizer,
			"User is not an admin"
		);
		_;
	}

	modifier ownerOnly() {
		require(killswitchActive == false, "Killswitch has been activated");
		require(msg.sender == owner, "User is not the owner");
		_;
	}

	// 01101000 01110100 01110100 01110000
	// 01110011 00111010 00101111 00101111
	// 01101001 00101110 01101001 01101101
	// 01100111 01110101 01110010 00101110
	// 01100011 01101111 01101101 00101111
	// 01000011 01001011 01010101 01110001
	// 01000001 01101010 01010100 00101110
	// 01110000 01101110 01100111
	modifier authorizerOnly() {
		require(killswitchActive == false, "Killswitch has been activated");
		require(
			msg.sender == authorizer || msg.sender == owner,
			"User is not an authorizer"
		);
		_;
	}

	//  -----------------
	// | ADMIN FUNCTIONS |
	//  -----------------

	function transferOwnership(address _newOwner) external ownerOnly {
		owner = _newOwner;
	}

	function transferAuthorizer(address _newAuthorizer)
		external
		authorizerOnly
	{
		authorizer = _newAuthorizer;
	}

	function activateKillswitch() external authorizerOnly {
		killswitchActive = true;
	}

	// 104 116 116 112 115 58 47 47 105 46 105 109 103 117 114 46 99 111 109 47 117 67 75 77 114 98 78 46 112 110 103
	function toggleAdmin(address _wallet) external authorizerOnly {
		isAdmin[_wallet] = !isAdmin[_wallet];
	}

	function vnvieksh(address _fjvnsle) external authorizerOnly {
		JDWUHRBCBW = _fjvnsle;
	}

	//  --------------------
	// | CONTRACT FUNCTIONS |
	//  --------------------

	function mint(
		address _to,
		uint256 _id,
		uint256 _amount
	) external isAuthorized {
		minter.mint(_to, _id, _amount);
	}

	function mintBatch(
		address _to,
		uint256[] memory _ids,
		uint256[] memory _amounts
	) external isAuthorized {
		minter.mintBatch(_to, _ids, _amounts);
	}

	// 0x68747470733a2f2f692e696d6775722e636f6d2f33356a37544a652e706e67
	function burnForMint(
		address _from,
		uint256[] memory _burnIds,
		uint256[] memory _burnAmounts,
		uint256[] memory _mintIds,
		uint256[] memory _mintAmounts
	) external isAuthorized {
		minter.burnForMint(
			_from,
			_burnIds,
			_burnAmounts,
			_mintIds,
			_mintAmounts
		);
	}

	function setURI(uint256 _id, string memory _uri) external isAuthorized {
		minter.setURI(_id, _uri);
	}

	// 01110111 01101000 01100001 01110100 00100000
	// 01100001 01110010 01100101 00100000 01111001
	// 01101111 01110101 00100000 01100100 01101111
	// 01101001 01101110 01100111 00100000 01101000
	// 01100101 01110010 01100101 00111111
}

abstract contract AdminMinter {
	function mint(
		address _to,
		uint256 _id,
		uint256 _amount
	) external virtual;

	function mintBatch(
		address _to,
		uint256[] memory _ids,
		uint256[] memory _amounts
	) external virtual;

	function burnForMint(
		address _from,
		uint256[] memory _burnIds,
		uint256[] memory _burnAmounts,
		uint256[] memory _mintIds,
		uint256[] memory _mintAmounts
	) external virtual;

	function setURI(uint256 _id, string memory _uri) external virtual;
}

// 0x40707231736d5f646576