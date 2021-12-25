// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Center.sol";

contract AtopiaGym1 is AtopiaCenter {
	function initialize(address space) public virtual override {
		AtopiaCenter.init(space, "Gym Heros", "Atopia Center - Gym");
		emission = 200;
		minAge = (5 * 365 days) / 10;
		enjoyFee = 1000;
		image = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 1000 1000" style="enable-background:new 0 0 1000 1000;" xml:space="preserve"><style type="text/css">.s{stroke:#000000;stroke-width:10;stroke-miterlimit:10;}.d{stroke-linecap:round;stroke-linejoin:round}.e{fill:none}.c1{stop-color:#B2E6FF}.c2{stop-color:#9B9BEB}.c3{fill:#EBD15B}.c4{fill:#90503D}.c5{fill:#FFC08D}.c6{fill:#4BBD80}.c7{fill:url(#lg1)}.c8{fill:url(#lg2)}</style><linearGradient id="lg1" gradientUnits="userSpaceOnUse" x1="584.7225" y1="210.7773" x2="496.5416" y2="200.981"><stop offset="0" class="c1"/><stop offset="1" class="c2"/></linearGradient><polygon class="s d c7" points="500.57,232.57 497.86,189.14 523.64,172.85 580.64,189.14 583.36,223.07"/><line x1="523.64" y1="172.85" x2="526.36" y2="228.5" class="s"/><polygon class="s d c3" points="480.21,685.85 777.43,685.85 829,243.42 645.79,190.5 421.86,242.07"/><line class="s d" x1="644.58" y1="684.49" x2="645.79" y2="190.5"/><linearGradient id="lg2" gradientUnits="userSpaceOnUse" x1="661.9341" y1="516.061" x2="140.1486" y2="458.0943"><stop offset="0" class="c1"/><stop offset="1" class="c2"/></linearGradient><path class="c8" d="M184.36,685.85L145,414.42c0,0,192.71-188.64,496.71-119.43l1.36,390.86H184.36z"/><path class="c3" d="M146.36,414.42c0,0,186.69-185.22,500.49-116.36l-3.77,68.86c0,0-260.57-90.93-492.03,86.58L146.36,414.42z"/><g class="s e d"><line x1="179.37" y1="436.51" x2="219.64" y2="681.78"/><line x1="229.24" y1="404.77" x2="267.14" y2="681.78"/><line x1="285.91" y1="382.1" x2="321.43" y2="683.14"/><line x1="354" y1="361.5" x2="378.43" y2="681.78"/><line x1="427.59" y1="349.23" x2="443.57" y2="681.78"/><line x1="508.71" y1="347.92" x2="515.99" y2="684.72"/><line x1="605.07" y1="362.85" x2="595.57" y2="681.78"/><path d="M162.37,514.71c0,0,156.96-135.3,478.29-80.47"/><path d="M173.5,578.64c0,0,177.79-112.64,465.5-67.86"/><path class="c5" d="M51.72,683.64l896.56,4.61l-95.21,45.41c-3.04,1.45-6.25,2.54-9.55,3.25L449.64,821.6c-53.99,11.61-110.37,2.62-158.07-25.21l-74.24-43.31c-4.96-2.89-10.67-4.23-16.4-3.84l-51.88,3.55c-7.92,0.54-15.75-1.97-21.88-7.01L51.72,683.64z"/><path class="c4" d="M754.59,253.13c-6.43,4.61-10.62,17.32,16.05,26.94c0,0-18.25,33.78-11.21,46.47c0,0-17.21-24.79-38.17-9.78c0,0-16.51-26.42-38.63-10.94c-22.12,15.48-14.21,66.84,23.82,52.7c0,0,22.99,17.69,44.01,6.54c0,0,34.81,6.4,39.67-20.41c4.86-26.8,6.6-59.77-4.14-75.02C775.25,254.37,762.97,247.13,754.59,253.13z"/><path d="M151.04,453.51c0,0,202.68-172.1,491.89-87.27"/><path d="M184.36,685.85L145,414.42c0,0,192.71-188.64,496.71-119.43l1.36,390.86H184.36z"/><path class="c6" d="M601,691l-115.09,67.64c-9.09,5.22-19.88,6.64-30.02,3.95l-172.59-42.47c-8.33-2.21-16.98-3-25.58-2.33l-80.72,6.26c-13.86,1.08-27.28-5.11-35.48-16.33l-13.82-18.94"/><polygon class="c6" points="705.72,687 736.72,735.64 885.53,688"/></g></svg>';
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBucks.sol";

interface IAtopia {
	function owner() external view returns (address);

	function bucks() external view returns (IBucks);

	function getAge(uint256 tokenId) external view returns (uint256);

	function ownerOf(uint256 tokenId) external view returns (address);

	function update(uint256 tokenId) external;

	function exitCenter(
		uint256 tokenId,
		uint256 grown,
		uint256 enjoyFee
	) external returns (uint256);

	function addReward(uint256 tokenId, uint256 reward) external;

	function claimGrowth(
		uint256 tokenId,
		uint256 grown,
		uint256 enjoyFee
	) external returns (uint256);

	function claimBucks(address user, uint256 amount) external;

	function buyAndUseItem(
		uint256 tokenId,
		uint256 itemInfo
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBucks {
	function mint(address account, uint256 amount) external;

	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;

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

struct Task {
	uint256 id;
	uint256 info;
	uint256 rewards;
}

interface ISpace {
	function atopia() external view returns (IAtopia);

	function ownerOf(uint256 tokenId) external view returns (address);

	function lives(uint256 tokenId) external view returns (uint256);

	function tasks(uint256 id) external view returns (Task memory);

	function claimBucks(uint256 centerId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Base64 {
	string private constant base64stdchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	function encode(bytes memory data) internal pure returns (string memory) {
		if (data.length == 0) return "";

		// load the table into memory
		string memory table = base64stdchars;

		// multiply by 4/3 rounded up
		uint256 encodedLen = 4 * ((data.length + 2) / 3);

		// add some extra buffer at the end required for the writing
		string memory result = new string(encodedLen + 32);

		assembly {
			// set the actual output length
			mstore(result, encodedLen)

			// prepare the lookup table
			let tablePtr := add(table, 1)

			// input ptr
			let dataPtr := data
			let endPtr := add(dataPtr, mload(data))

			// result ptr, jump over length
			let resultPtr := add(result, 32)

			// run over the input, 3 bytes at a time
			for {

			} lt(dataPtr, endPtr) {

			} {
				dataPtr := add(dataPtr, 3)

				// read 3 bytes
				let input := mload(dataPtr)

				// write 4 characters
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
				resultPtr := add(resultPtr, 1)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
				resultPtr := add(resultPtr, 1)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
				resultPtr := add(resultPtr, 1)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
				resultPtr := add(resultPtr, 1)
			}

			// padding with '='
			switch mod(mload(data), 3)
			case 1 {
				mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
			}
			case 2 {
				mstore(sub(resultPtr, 1), shl(248, 0x3d))
			}
		}

		return result;
	}

	function toString(uint256 value) internal pure returns (string memory) {
		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISpace.sol";
import "../libs/Base64.sol";

abstract contract AtopiaCenter {
	address implementation_;
	address public admin;

	bool public initialized;
	using Base64 for *;

	struct Package {
		uint256 id;
		string name;
		uint256 info;
		uint256 rewards;
	}

	uint16 public constant FEE_PERCENT = 500;
	uint16 public constant WORK_PERCENT = 1000;

	uint256 public id;
	string public name;
	string public description;
	string public image;
	uint256 public emission;
	uint256 public minAge;
	uint16 public enjoyFee;

	uint256 public level;
	uint256 public progress;

	ISpace public space;

	uint256 public workAvailable;
	Package[] public packages;
	mapping(uint256 => uint256) public workRewards; // retire

	uint256 public totalStaking;
	mapping(uint256 => uint256) public claims;
	uint256 public currentReflection;
	uint256 public lastUpdateAt;

	uint256 public totalFeeAmount;

	event PackageAdded(Package newPackage);
	event PackageUpdated(Package newPackage);
	event LevelUpdated(uint256 level);

	function initialize(address _space) public virtual;

	function init(
		address _space,
		string memory _name,
		string memory _description
	) internal {
		require(!initialized);
		initialized = true;
		space = ISpace(_space);
		name = _name;
		description = _description;
	}

	modifier onlyOwner() {
		require(space.ownerOf(id) == msg.sender);
		_;
	}

	modifier onlySpace() {
		require(address(space) == msg.sender);
		_;
	}

	function totalPackages() external view returns (uint256) {
		return packages.length;
	}

	function newReflection() public view returns (uint256) {
		return currentReflection + (emission / totalStaking) * (block.timestamp - lastUpdateAt);
	}

	function grown(uint256 tokenId) public view returns (uint256) {
		return newReflection() - claims[tokenId];
	}

	function getProgress() public view returns (uint256) {
		uint256 percent = progress / emission;
		return percent > 100 ? 100 : percent;
	}

	function updateReflection() internal {
		if (totalStaking > 0) {
			currentReflection += (emission / totalStaking) * (block.timestamp - lastUpdateAt);
		}
		lastUpdateAt = block.timestamp;
	}

	function setId(uint256 _id) external onlySpace {
		require(address(space) == msg.sender);
		require(id == 0);
		id = _id;
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

	function grow(uint256 tokenId) external onlySpace returns (uint256 _growing) {
		_growing = grown(tokenId);
		claims[tokenId] = currentReflection;
	}

	function work(
		uint256 tokenId,
		uint16 packageId,
		uint256 working
	) external onlySpace returns (uint256 life, uint256 reward) {
		uint256 _workAvailable = workAvailable;
		if (packageId > 0) {
			uint16 package = packageId - 1;
			uint256 info = packages[package].info;
			require(package < packages.length);
			require(space.atopia().getAge(tokenId) >= uint128(info));
			//require(packages[package].rewards <= workAvailable);

			uint256 packageReward;
			if (working > 0) {
				uint16 currentPackage = uint16(working >> 128);
				uint256 end = uint128(working);
				//require(block.timestamp >= end);
				packageReward = packages[currentPackage - 1].rewards;
				if (block.timestamp >= end) {
					reward = packageReward;
				} else {
					_workAvailable += packageReward;
				}
			}

			packageReward = packages[package].rewards;
			require(packageReward <= _workAvailable);
			workAvailable = _workAvailable - packageReward;
			life = (id << 192) | (uint256(packageId) << 128) | (block.timestamp + (info >> 128));
		} else {
			// finish or quit work
			uint16 currentPackage = uint16(working >> 128);
			uint256 end = uint128(working);
			uint256 packageReward = packages[currentPackage - 1].rewards;
			require(currentPackage > 0 && end > 0);
			if (block.timestamp >= end) {
				reward = packageReward;
			} else {
				workAvailable = _workAvailable + packageReward;
			}
		}
	}

	function addPackage(string memory packageName, uint256 taskId) external onlyOwner {
		Task memory task = space.tasks(taskId);
		Package memory newPackage = Package(packages.length + 1, packageName, task.info, task.rewards);
		packages.push(newPackage);
		emit PackageAdded(newPackage);
	}

	function updatePackage(uint256 packageId, string memory packageName) external onlyOwner {
		require(packageId > 0 && packages.length <= packageId);
		packageId -= 1;
		packages[packageId].name = packageName;
		emit PackageUpdated(packages[packageId]);
	}

	function upgrade() external onlyOwner {
		require(getProgress() == 100);
		progress -= emission * 100;
		emission = (emission * 110) / 100;
		level += 1;
		updateReflection();
		emit LevelUpdated(level);
	}

	function addFeeAmount(uint256 feeAmount) external onlySpace {
		totalFeeAmount += feeAmount;
	}

	function withdraw() external onlyOwner {
		uint256 fee = (totalFeeAmount * FEE_PERCENT) / 10000;
		uint256 newWork = (totalFeeAmount * WORK_PERCENT) / 10000;
		workAvailable += newWork;
		totalFeeAmount = 0;
		//space.atopia().bucks().burn(bucks - fee - newWork);
		//space.atopia().bucks().transfer(msg.sender, fee);
		space.claimBucks(id, fee);
	}

	function metadata() external view returns (string memory) {
		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					Base64.encode(
						abi.encodePacked(
							'{"name":"',
							name,
							'","description":"',
							description,
							'","image":"data:image/svg+xml;base64,',
							Base64.encode(bytes(image)),
							'","attributes":[{"display_type":"number","trait_type":"Emission","value":"',
							emission.toString(),
							'"},{"display_type":"number","trait_type":"Min Age","value":"',
							((minAge * 10) / 365 days).toString(),
							'"},{"trait_type":"Level","value":"',
							level.toString(),
							'"},{"display_type":"boost_percentage","trait_type":"Progress","value":"',
							getProgress().toString(),
							'"},{"display_type":"boost_percentage","trait_type":"Fee","value":"',
							(enjoyFee / 100).toString(),
							'"}]}'
						)
					)
				)
			);
	}
}