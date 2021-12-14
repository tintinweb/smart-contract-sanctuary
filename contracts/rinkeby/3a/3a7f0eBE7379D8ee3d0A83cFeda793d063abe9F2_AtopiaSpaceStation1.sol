// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Center.sol";

contract AtopiaSpaceStation1 is AtopiaCenter {
	function initialize(address space) public virtual override {
		AtopiaCenter.init(space, "Burrow Colony", "Atopia Center - Space Station");
		emission = 500;
		minAge = (5 * 365 days) / 10;
		enjoyFee = 100;
		image = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 1000 1000" style="enable-background:new 0 0 1000 1000;" xml:space="preserve"><style type="text/css">.s{stroke:#000000;stroke-width:10;stroke-miterlimit:10;}.d{stroke-linecap:round;stroke-linejoin:round}.e{fill:none}.c2{fill:#4BBD80}.c3{fill:#FFC08D}.c4{fill:#EBD15B}.c5{fill:#4F4F4F}.c6{fill:#303030}.c7{fill:url(#lg1)}</style><g class="s e d"><polygon class="c3" points="274.61,689.52 274.61,732.52 722.61,733.52 719.61,688.52"/><polygon class="c4" points="259.61,604.52 265.61,683.52 739.61,686.52 741.61,595.52"/><g class="c5"><polygon points="233.61,616.52 250.61,681.52 274.61,677.52 252.61,603.52"/><polygon points="281.61,599.52 300.61,671.52 325.61,672.52 307.61,594.52"/><polygon points="345.61,586.52 355.61,670.52 386.61,669.52 379.61,584.52"/><polygon points="410.61,583.52 419.61,666.52 446.61,666.52 444.61,579.52"/><polygon points="479.61,587.52 481.61,665.52 511.61,665.52 514.61,583.52"/><polygon points="545.61,589.52 547.61,669.52 575.61,669.52 580.61,585.52"/><polygon points="613.61,587.52 610.61,666.52 638.61,668.52 652.61,590.52"/><polygon points="680.61,592.52 668.61,668.52 696.61,673.52 713.61,593.52"/><path d="M742.61,602.52c-1,4-19,71-19,71l24,7l20-69L742.61,602.52z"/><path class="c3" d="M252.61,712.52c20-5,291-38,491-2l26-36c0,0-262-47-543,0L252.61,712.52z"/><linearGradient id="lg1" gradientUnits="userSpaceOnUse" x1="225.3507" y1="628.2901" x2="835.4998" y2="410.9372"><stop offset="0.3273" style="stop-color:#9B9BEB"/><stop offset="0.5788" style="stop-color:#BCBCFF"/><stop offset="0.7243" style="stop-color:#FFFFFF"/><stop offset="0.9138" style="stop-color:#9B9BEB"/></linearGradient><path class="c7" d="M780.61,637.52c0,0,4-282-270-292s-298,259-290,292C220.61,637.52,461.61,565.52,780.61,637.52z"/><path d="M416.08,355.76c0,0,77.61,31.4,151.57-1.92C567.65,353.84,475.55,334.99,416.08,355.76z"/></g><line x1="491.57" y1="371.2" x2="495.18" y2="604.32"/><path d="M534.61,366.52c0,0,120.79,66.83,120.39,247.42"/><path d="M444.61,365.52c0,0-118,73-116,247"/><g class="c6"><path d="M468.66,281.08c-3.84,6.35-19.81,48.9,13.55,67.14c33.37,18.24,58.5-18.49,58.5-18.49L468.66,281.08z"/><path d="M423.39,131.99c-3.92,8.6-24.9,70.06,54.08,161.23c44.64,51.53,170.55,75.06,214.31,45.87C698.34,334.7,423.39,131.99,423.39,131.99z"/><ellipse transform="matrix(0.6006 -0.7996 0.7996 0.6006 36.1397 541.3266)" style="fill:#FFD1AD" cx="559.86" cy="234.49" rx="47.88" ry="170.68"/><path d="M464.11,205.16c11.1-3.84,154.4-35.5,154.4-35.5"/><line x1="563.15" y1="259.21" x2="621.06" y2="166.77"/><path style="fill:#FFFFFF" d="M459.32,205.59c0,0,120.19-7.33,155.46,117.49C614.78,323.08,537.9,289.68,459.32,205.59z"/><line x1="617.7" y1="176.19" x2="575.07" y2="301.08"/><line x1="624.53" y1="161.76" x2="648.04" y2="136.69"/><circle cx="618.51" cy="169.65" r="17.15"/><circle cx="647.67" cy="136.91" r="9.65"/></g><path class="c3" d="M51.72,731.45l896.56,4.61l-99.79,47.59l-402.73,86.59c-51.5,11.07-105.27,2.5-150.77-24.04l-85.27-49.74l-73,5L51.72,731.45z"/><path class="c2" d="M582.05,735l-130.33,74.81l-181-48l-92.34,7.16c-14.78,1.15-29.17-5.15-38.35-16.8l-15.79-20.03L582.05,733.64z"/><polygon class="c2" points="690.72,735 721.72,784.45 885.53,736"/></g></svg>';
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
		address center,
		uint256 grown,
		uint256 enjoyFee
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

interface ISpace {
	function atopia() external view returns (IAtopia);

	function ownerOf(uint256 tokenId) external view returns (address);

	function lives(uint256 tokenId) external view returns (uint256);
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
	address proxyImpl_;
	address proxyAdmin_;

	bool public initialized;
	using Base64 for *;

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
	mapping(uint256 => uint256) public workRewards;

	uint256 public totalStaking;
	mapping(uint256 => uint256) public claims;
	uint256 public currentReflection;
	uint256 public lastUpdateAt;

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

	function totalPackages() external view returns (uint256) {
		return packages.length;
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

	function work(
		uint256 tokenId,
		uint16 packageId,
		uint256 working
	) external onlySpace returns (uint256) {
		if (packageId > 0) {
			uint16 package = packageId - 1;
			require(package < packages.length);
			require(space.atopia().getAge(tokenId) >= packages[package].minAge);
			require(packages[package].rewards <= workAvailable);

			if (working > 0) {
				uint16 currentPackage = uint16(working >> 128);
				uint256 end = working & (1 << (129 - 1));
				require(block.timestamp > end);
				workRewards[tokenId] += packages[currentPackage].rewards;
			}

			workAvailable -= packages[package].rewards;
			return (id << 192) & (uint256(packageId) << 128) & (block.timestamp + packages[package].duration);
		} else {
			require(working > 0);

			uint16 currentPackage = uint16(working >> 128);
			uint256 end = working & (1 << (129 - 1));
			uint256 totalRewards = 0;
			if (block.timestamp > end) {
				totalRewards += packages[currentPackage].rewards;
			} else {
				workAvailable += packages[currentPackage].rewards;
			}

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
							'"}'
						)
					)
				)
			);
	}
}