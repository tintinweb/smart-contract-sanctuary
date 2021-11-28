// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBucks.sol";

interface IAtopia {
	function bucks() external view returns (IBucks);

	function getAge(uint256 tokenId) external view returns (uint256);

	function ownerOf(uint256 tokenId) external view returns (address);

	function setLife(uint256 tokenId, uint256 life) external;

	function exitCenter(
		uint256 tokenId,
		address center,
		uint256 grown
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBucks {
	function mint(address account, uint256 amount) external;

	function transfer(address recipient, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAtopia.sol";

interface ISpace {
	function atopia() external view returns (IAtopia);

	function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISpace.sol";

contract AtopiaCenter {
	struct Package {
		uint256 duration;
		uint256 rewards;
		uint256 minAge;
	}

	uint16 public constant FEE_PERCENT = 2000;
	uint16 public constant WORK_PERCENT = 4000;

	uint256 public id;
	string public name;
	string public description;
	string public image;
	uint256 public emission;
	uint256 public minAge;
	uint16 public enjoyFee;

	ISpace public space;

	uint256 public workAvailable;
	Package[] public packages;
	mapping(uint256 => uint256) public workings;
	mapping(uint256 => uint256) public workRewards;

	uint256 public totalStaking;
	mapping(uint256 => uint256) public claims;
	uint256 public currentReflection;
	uint256 public lastUpdateAt;

	constructor(
		address _space,
		string memory _name,
		string memory _description,
		string memory _image,
		uint256 _emission,
		uint256 _minAge,
		uint16 _enjoyFee
	) {
		space = ISpace(_space);
		name = _name;
		description = _description;
		image = _image;
		emission = _emission;
		minAge = _minAge;
		enjoyFee = _enjoyFee;
	}

	modifier onlyOwner() {
		require(space.ownerOf(id) == msg.sender);
		_;
	}

	function addPackage(
		uint256 duration,
		uint256 _rewards,
		uint256 _minAge
	) external onlyOwner {
		packages.push(Package(duration, _rewards, _minAge));
	}

	modifier onlySpace() {
		require(address(space) == msg.sender);
		_;
	}

	function setId(uint256 _id) external onlySpace {
		require(address(space) == msg.sender);
		require(id == 0);
		id = _id;
	}

	function newReflection() public view returns (uint256) {
		return currentReflection + (emission / totalStaking) * (block.timestamp - lastUpdateAt);
	}

	function updateReflection() internal {
		if (totalStaking > 0) {
			currentReflection += (emission / totalStaking) * (block.timestamp - lastUpdateAt);
		}
		lastUpdateAt = block.timestamp;
	}

	function enter(uint256 tokenId) external onlySpace returns (uint256) {
		require(space.atopia().getAge(tokenId) >= minAge);
		updateReflection();
		totalStaking += 1;
		claims[tokenId] = currentReflection;
		return id << 192;
	}

	function exit(uint256 tokenId) external onlySpace returns (uint256 _growing) {
		_growing = grown(tokenId);
		totalStaking -= 1;
		updateReflection();
	}

	function work(uint256 tokenId, uint16 package) external onlySpace returns (uint256) {
		uint256 working = workings[tokenId];
		if (package > 0) {
			require(package < packages.length);
			require(space.atopia().getAge(tokenId) >= packages[package].minAge);
			require(packages[package].rewards <= workAvailable);

			if (working > 0) {
				uint8 currentPackage = uint8(working >> 128);
				uint256 end = working & (1 << (129 - 1));
				require(block.timestamp > end);
				workRewards[tokenId] += packages[currentPackage].rewards;
			}

			workAvailable -= packages[package].rewards;
			uint256 life = (id << 192) & (package << 128) & (block.timestamp + packages[package].duration);
			workings[tokenId] = life;
			return life;
		} else {
			require(working > 0);

			uint8 currentPackage = uint8(working >> 128);
			uint256 end = working & (1 << (129 - 1));
			uint256 totalRewards = 0;
			if (block.timestamp > end) {
				totalRewards += packages[currentPackage].rewards;
			} else {
				workAvailable += packages[currentPackage].rewards;
			}

			workings[tokenId] = 0;

			if (workRewards[tokenId] > 0) {
				totalRewards += workRewards[tokenId];
				workRewards[tokenId] = 0;
			}

			space.atopia().bucks().transfer(space.atopia().ownerOf(tokenId), totalRewards);

			return totalRewards;
		}
	}

	function grown(uint256 tokenId) public view returns (uint256) {
		return newReflection() - claims[tokenId];
	}

	function rewards(uint256 tokenId) public view returns (uint256) {
		return workRewards[tokenId];
	}

	function withdraw() external onlyOwner {
		uint256 bucks = space.atopia().bucks().balanceOf(address(this)) - workAvailable;
		uint256 fee = (bucks * FEE_PERCENT) / 10000;
		uint256 newWork = (bucks * WORK_PERCENT) / 10000;
		workAvailable += newWork;
		space.atopia().bucks().transfer(msg.sender, bucks - fee - newWork);
	}

	function metadata() external view returns (string memory) {
		return
			string(
				abi.encodePacked("data:application/json;base64", name) // onchian-nft
			);
	}
}