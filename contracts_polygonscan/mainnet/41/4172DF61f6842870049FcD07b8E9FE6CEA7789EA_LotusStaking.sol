/**
 *Submitted for verification at polygonscan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File contracts/V2-Lotus-Staking/ILotusStaking.sol


pragma solidity ^0.8.4;

interface ILotusStaking {
	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Approval(address indexed owner, address indexed spender, uint256 amount);
	event GoLotus(address indexed owner, uint256 indexed lotusId, uint256 power);
	event OutLotus(address indexed owner, uint256 indexed lotusId);
	event Mine(address indexed owner, uint256 indexed lotusId, uint256 subsidy);

	function name() external view returns (string memory);

	function lotusCount() external view returns (uint256);

	function subsidyAt(uint256 blockNumber) external view returns (uint256);

	function goLotus(uint256[] memory myTokensId) external returns (uint256);

	function outLotus(uint256 lotusId) external;

	function powerOf(uint256 lotusId) external view returns (uint256);

	function subsidyOf(uint256 lotusId) external view returns (uint256);

	function mine(uint256 lotusId) external returns (uint256);
}


// File contracts/CND-V2/IClonesNeverDieV2.sol



pragma solidity ^0.8.4;

interface IClonesNeverDieV2 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	function mint(address to) external;

	function totalSupply() external view returns (uint256);

	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

	function tokenByIndex(uint256 index) external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256 balance);

	function ownerOf(uint256 tokenId) external view returns (address owner);

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	function approve(address to, uint256 tokenId) external;

	function getApproved(uint256 tokenId) external view returns (address operator);

	function setApprovalForAll(address operator, bool _approved) external;

	function isApprovedForAll(address owner, address operator) external view returns (bool);

	function massTransferFrom(
		address from,
		address to,
		uint256[] memory _myTokensId
	) external;
}


// File contracts/Nectar/INectar.sol



pragma solidity ^0.8.0;

interface INectar {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	function mint(address to, uint256 amount) external;

	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/V2-Lotus-Staking/LotusStaking.sol



pragma solidity ^0.8.4;




contract LotusStaking is ILotusStaking {
	INectar public Nectar;
	IClonesNeverDieV2 public CNDV2;
	string public constant NAME = "Lotus";
	uint256 public constant COIN = 10**uint256(DECIMALS);
	uint8 public constant DECIMALS = 18;
	uint32 public constant SUBSIDY_HALVING_INTERVAL = 210000 * 20;
	uint256 public constant PRECISION = 1e4;

	uint256 public immutable genesisEthBlock;

	uint256 private _totalSupply;
	mapping(address => uint256[]) private ownerPools;

	struct Lotus {
		address owner;
		uint256 power;
		uint256 accSubsidy;
		uint256[] v2TokensId;
	}
	Lotus[] public lotuses;

	uint256 public accSubsidyBlock;
	uint256 public accSubsidy;
	uint256 public totalPower;

	constructor(address _cndv2, address _nectar, address _genesisLotusOwner) {
		CNDV2 = IClonesNeverDieV2(_cndv2);
		Nectar = INectar(_nectar);

		genesisEthBlock = block.number;
		accSubsidyBlock = block.number;
		accSubsidy = 0;
		uint256[] memory nullArr;

		lotuses.push(Lotus({ owner: _genesisLotusOwner, power: 1, accSubsidy: 0, v2TokensId: nullArr }));
		totalPower = 1;
	}

	function name() external pure override returns (string memory) {
		return NAME;
	}

	function lotusCount() external view override returns (uint256) {
		return lotuses.length;
	}

	function myLotusList(address myAddress) public view returns (uint256[] memory) {
		return ownerPools[myAddress];
	}

	function myLotusLength(address myAddress) public view returns (uint256) {
		return ownerPools[myAddress].length;
	}

	function subsidyAt(uint256 blockNumber) public view override returns (uint256 amount) {
		uint256 era = (blockNumber - genesisEthBlock) / SUBSIDY_HALVING_INTERVAL;
		amount = (10 * COIN) / (1**era);
	}

	function calculateAccSubsidy() internal view returns (uint256) {
		uint256 _accSubsidyBlock = accSubsidyBlock;
		uint256 subsidy = 0;
		uint256 era1 = (_accSubsidyBlock - genesisEthBlock) / SUBSIDY_HALVING_INTERVAL;
		uint256 era2 = (block.number - genesisEthBlock) / SUBSIDY_HALVING_INTERVAL;

		if (era1 == era2) {
			subsidy = (block.number - _accSubsidyBlock) * subsidyAt(block.number);
		} else {
			uint256 boundary = (era1 + 1) * SUBSIDY_HALVING_INTERVAL + genesisEthBlock;
			subsidy = (boundary - _accSubsidyBlock) * subsidyAt(_accSubsidyBlock);
			uint256 span = era2 - era1;
			for (uint256 i = 1; i < span; i += 1) {
				boundary = (era1 + 1 + i) * SUBSIDY_HALVING_INTERVAL + genesisEthBlock;
				subsidy += SUBSIDY_HALVING_INTERVAL * subsidyAt(_accSubsidyBlock + SUBSIDY_HALVING_INTERVAL * i);
			}
			subsidy += (block.number - boundary) * subsidyAt(block.number);
		}

		return accSubsidy + (subsidy * PRECISION) / totalPower;
	}

	function getLotusV2TokenId(uint256 lotusId) public view returns (uint256[] memory) {
		return lotuses[lotusId].v2TokensId;
	}

	function makeLotus(uint256 power, uint256[] memory myTokensId) internal returns (uint256) {
		require(power > 0);

		uint256 lotusId = lotuses.length;
		uint256 _accSubsidy = update();

		lotuses.push(Lotus({ owner: msg.sender, power: power, accSubsidy: (_accSubsidy * power) / PRECISION, v2TokensId: myTokensId }));
		ownerPools[msg.sender].push(lotusId);

		totalPower += power;
		return lotusId;
	}

	function goLotus(uint256[] memory myTokensId) external override returns (uint256) {
		require(CNDV2.totalSupply() >= 2000, "The total supply has not reached 20%.");
		CNDV2.massTransferFrom(msg.sender, address(this), myTokensId);
		uint256 power = myTokensId.length;
		uint256 lotusId = makeLotus(power, myTokensId);
		emit GoLotus(msg.sender, lotusId, power);
		return lotusId;
	}

	function outLotus(uint256 ownerPoolsNum) external override {
		uint256 lotusId = ownerPools[msg.sender][ownerPoolsNum];
		Lotus storage lotus = lotuses[lotusId];
		require(lotusId != 0);
		require(lotus.owner == msg.sender);

		uint256 power = lotus.power;
		uint256[] memory myTokensId = lotus.v2TokensId;
		mine(ownerPoolsNum);

		delete lotus.v2TokensId;
		lotus.owner = address(0);
		totalPower -= power;

		CNDV2.massTransferFrom(address(this), msg.sender, myTokensId);
		emit OutLotus(msg.sender, lotusId);
	}

	function outGenesisLotus(uint256 _genesisLotus) external {
		uint256 lotusId = _genesisLotus;
		Lotus storage lotus = lotuses[lotusId];
		require(lotus.owner == msg.sender);

		uint256 power = lotus.power;
		genesisLotusMine(_genesisLotus);

		delete lotus.v2TokensId;
		lotus.owner = address(0);
		totalPower -= power;
		emit OutLotus(msg.sender, lotusId);
	}

	function powerOf(uint256 lotusId) external view override returns (uint256) {
		return lotuses[lotusId].power;
	}

	function subsidyOf(uint256 lotusId) external view override returns (uint256) {
		Lotus memory lotus = lotuses[lotusId];
		if (lotus.owner == address(0)) {
			return 0;
		}
		return (calculateAccSubsidy() * lotus.power) / PRECISION - lotus.accSubsidy;
	}

	function mine(uint256 ownerPoolsNum) public override returns (uint256) {
		uint256 lotusId = ownerPools[msg.sender][ownerPoolsNum];
		Lotus storage lotus = lotuses[lotusId];
		require(lotus.owner == msg.sender);
		uint256 power = lotus.power;

		uint256 _accSubsidy = update();
		uint256 subsidy = (_accSubsidy * power) / PRECISION - lotus.accSubsidy;
		if (subsidy > 0) {
			Nectar.mint(msg.sender, subsidy);
		}

		lotus.accSubsidy = (_accSubsidy * power) / PRECISION;
		emit Mine(msg.sender, lotusId, subsidy);
		return subsidy;
	}

	function genesisLotusMine(uint256 _genesisLotus) public returns (uint256) {
		uint256 lotusId = _genesisLotus;
		Lotus storage lotus = lotuses[lotusId];
		require(lotus.owner == msg.sender);
		uint256 power = lotus.power;

		uint256 _accSubsidy = update();
		uint256 subsidy = (_accSubsidy * power) / PRECISION - lotus.accSubsidy;
		if (subsidy > 0) {
			Nectar.mint(msg.sender, subsidy);
		}

		lotus.accSubsidy = (_accSubsidy * power) / PRECISION;
		emit Mine(msg.sender, lotusId, subsidy);
		return subsidy;
	}

	function update() internal returns (uint256 _accSubsidy) {
		if (accSubsidyBlock != block.number) {
			_accSubsidy = calculateAccSubsidy();
			accSubsidy = _accSubsidy;
			accSubsidyBlock = block.number;
		} else {
			_accSubsidy = accSubsidy;
		}
	}
}