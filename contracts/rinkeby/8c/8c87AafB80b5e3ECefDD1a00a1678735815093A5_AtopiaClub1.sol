// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Center.sol";

contract AtopiaClub1 is AtopiaCenter {
	function initialize(address space) public virtual override {
		AtopiaCenter.init(space, "Crazy Nights", "Atopia Center - Club");
		emission = 300;
		minAge = (5 * 365 days) / 10;
		enjoyFee = 100;
		image = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 1000 1000" style="enable-background:new 0 0 1000 1000;" xml:space="preserve"><style type="text/css">.s{stroke:#000000;stroke-width:10;stroke-miterlimit:10;}.d{stroke-linecap:round;stroke-linejoin:round}.e{fill:none}.c1{fill:#FFA6D8}.c2{fill:#A4A4F4}.c3{fill:#C5C5FF}.c4{fill:#F4DA5B}.c5{stop-color:#FFA6D8}.c6{stop-color:#A4A4F4}.c7{fill:#FFC08D}.c8{fill:#4BBD80}</style><g class="s d"><polygon class="c1" points="198.65,736.91 708.89,736.91 712.31,593.09 196.94,629.04"/><polygon class="c2" points="710.6,736.91 799.63,738.62 803.06,613.63 712.31,593.09"/><polygon class="c3" points="664.37,240.37 660.43,595.56 556.5,602.65 563.35,165.04"/><polygon class="c2" points="462,611 498,608 489,737 455,736"/><polygon class="c2" points="340,619 311,621 313,736 340,736"/><line x1="528.79" y1="607.68" x2="519" y2="735"/><polygon class="c4" points="340,619 461,611 455,736 340,736"/><line x1="286.26" y1="735.2" x2="283.35" y2="624.54"/></g><linearGradient id="lg1" gradientUnits="userSpaceOnUse" x1="267.5063" y1="628.1265" x2="283.586" y2="318.4593"><stop offset="0.3" class="c5"/><stop offset="1" class="c6"/></linearGradient><path style="fill:url(#lg1)" d="M219.2,625.62c0,0-3.96-251.83,74.8-306.62l24,301L219.2,625.62z"/><g style="opacity:0.8;fill:#FFFFFF"><polygon points="324.11,524.6 216.25,444.13 211.11,488.64 323.64,570.25"/><polygon points="209.4,495.49 207.53,517.55 324.62,603.11 325.74,579.47"/></g><path class="s e d" d="M219.2,625.62c0,0-9.2-252.62,74.8-306.62l31.03,300.32L219.2,625.62z"/><linearGradient id="lg2" gradientUnits="userSpaceOnUse" x1="286.5359" y1="593.678" x2="597.051" y2="227.607"><stop  offset="0" class="c5"/><stop  offset="1" class="c6"/></linearGradient><polygon style="fill:url(#lg2)" class="s" points="556.41,603.34 561.64,197.57 289.4,262.48 316.8,619.35"/><path class="s c2" d="M699.61,591.09l69.2,14.7c0,0,37.67-252.4-150.67-327.74L699.61,591.09z"/><linearGradient id="lg3" gradientUnits="userSpaceOnUse" x1="642.7665" y1="597.0062" x2="636.0984" y2="265.043"><stop offset="0.3" class="c5"/><stop offset="1" class="c6"/></linearGradient><path style="fill:url(#lg3);" d="M585.61,266.06l-3.42,332.17l116.43-5.14C698.61,593.09,731.15,286.6,585.61,266.06z"/><g style="opacity:0.8;fill:#FFFFFF"><polygon points="583.9,500.63 691.77,420.15 696.9,464.67 584.37,546.28"/><polygon points="698.61,471.52 700.48,493.58 583.39,579.14 582.27,555.5"/></g><path class="s e d" d="M585.61,266.06l-3.42,334.17l116.43-7.14C698.61,593.09,731.15,286.6,585.61,266.06z"/><linearGradient id="lg4" gradientUnits="userSpaceOnUse" x1="373.4626" y1="20.2399" x2="445.1289" y2="319.795"><stop offset="0.3" class="c5"/><stop offset="1" class="c6"/></linearGradient><polygon style="fill:url(#lg4)" class="s d" points="263.72,272.19 565.06,200.28 567.77,121.75 263.72,206.13"/><polygon class="s d c2" points="565.06,200.99 681.2,250.65 684.92,187.3 568.49,122.23"/><g style="opacity:0.8;fill:url(#lg5)"><linearGradient id="lg5" gradientUnits="userSpaceOnUse" x1="504.4951" y1="572.329" x2="521.496" y2="244.9237"><stop  offset="0" style="stop-color:#F4DA5B"/><stop  offset="0.4375" style="stop-color:#FFE98A"/><stop  offset="0.5527" style="stop-color:#FFF2BB"/><stop  offset="0.6575" style="stop-color:#FFF9E0"/><stop  offset="0.7418" style="stop-color:#FFFDF7"/><stop  offset="0.7951" style="stop-color:#FFFFFF"/></linearGradient><path d="M529.11,572.54c0,0,5.84-326.87,3.42-327.03c-25.68-1.71-35.96,5.14-35.96,5.14l11.99,321.89H529.11z"/><path d="M471.45,575.88c0,0,4.78-321.87,2.37-321.86c-23.48,0.06-35.46,8.62-35.46,8.62l12.54,313.31L471.45,575.88z"/><path d="M417.71,579.03c0,0-8.6-310.26-10.96-310.19c-21.47,0.65-35.69,6.54-35.69,6.54l26.13,304.61L417.71,579.03z"/><path d="M363.73,583.92c0,0-10.8-301.55-13.13-301.47c-21.83,0.73-35.64,6.7-35.64,6.7l28.26,295.9L363.73,583.92z"/></g><path class="s d c2" d="M500,548.57l32.53-1.71c0,0,5.14,30.82-13.7,32.53C500,581.1,500,548.57,500,548.57z"/><path class="s d c2" d="M443.5,554.3l31.9-1.68c0,0,5.04,30.23-13.43,31.9C443.5,586.21,443.5,554.3,443.5,554.3z"/><path class="s d c2" d="M392.13,560.8l26.87-1.41c0,0,4.24,25.45-11.31,26.87C392.13,587.66,392.13,560.8,392.13,560.8z"/><path class="s d c2" d="M337.34,565.93l26.87-1.41c0,0,4.24,25.45-11.31,26.87C337.34,592.8,337.34,565.93,337.34,565.93z"/><path class="s d c7" d="M51.22,734.62l896.56,4.61l-95.21,45.41c-3.04,1.45-6.25,2.54-9.55,3.25l-393.89,84.69c-53.99,11.61-110.37,2.62-158.07-25.21l-74.24-43.31c-4.96-2.89-10.67-4.23-16.4-3.84l-51.88,3.55c-7.92,0.54-15.75-1.97-21.88-7.01L51.22,734.62z"/><path class="s d c8" d="M337,736c-27.36,16.65-51,33-56,34c-45.82,9.16-106.95,4.03-137-11c-4-2-12.32-17.48-17-24L337,736z"/><path class="s d c8" d="M459,737c0.13-0.04,5.11,16.15,6,19.62c3.12,12.1,8.54,27.57,19.94,40.12c3.91,6.05,11.32,8.83,18.24,6.85C634.92,781.18,758.86,759.94,882,739C740.94,738.22,459,737,459,737z"/></svg>';
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
	address public proxyAdmin_;

	bool public initialized;
	using Base64 for *;

	struct Package {
		uint256 duration;
		uint256 rewards;
		uint256 minAge;
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
		space.atopia().bucks().burn(bucks - fee - newWork);
		space.atopia().bucks().transfer(msg.sender, fee);
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
							'","attributes":[{"trait_type":"Emission","value":"',
							emission,
							'"},{"trait_type":"Min Age","value":"',
							(minAge * 10) / 365 days,
							'"},{"trait_type":"Fee","value":"',
							enjoyFee / 100,
							'"}]}'
						)
					)
				)
			);
	}
}