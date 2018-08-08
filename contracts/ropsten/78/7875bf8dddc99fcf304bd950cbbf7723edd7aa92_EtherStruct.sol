pragma solidity ^0.4.16;

contract owned {
	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner, "Only the owner can call this function.");
		_;
	}

	function transferOwnership(address newOwner) external onlyOwner {
		if (newOwner != address(0)) {
			owner = newOwner;
		}
	}
}

contract EtherStruct is owned {
	struct Cube {
		address owner;
		uint lockedFunds;
		uint style;
		uint metadata;
	}

	Cube[][][] worldspace;
	uint public worldLimitX;
	uint public worldLimitY;
	uint public worldLimitZ;

	constructor(uint startingWorldLimitX, uint startingWorldLimitY, uint startingWorldLimitZ) public {
		worldLimitX = startingWorldLimitX;
		worldLimitY = startingWorldLimitY;
		worldLimitZ = startingWorldLimitZ;
	}

	function increaseWorldLimit(uint newWorldLimitX, uint newWorldLimitY, uint newWorldLimitZ) external onlyOwner {
		// Ensure we can&#39;t shrink the world to make cubes inaccessible
		require(newWorldLimitX >= worldLimitX && newWorldLimitY >= worldLimitY && newWorldLimitZ >= worldLimitZ);

		// Set the new world limit
		worldLimitX = newWorldLimitX;
		worldLimitY = newWorldLimitY;
		worldLimitZ = newWorldLimitZ;
	}

	function placeCube(uint x, uint y, uint z, uint style, uint metadata) external payable onlyOwner {
		// Ensure the new cube is within bounds
		require(x < worldLimitX && y < worldLimitY && z < worldLimitZ);

		// Ensure the request is exceeding the previously locked value
		require(msg.value > worldspace[x][y][z].lockedFunds);

		returnLockedFunds(worldspace[x][y][z]);

		worldspace[x][y][z] = Cube({
			owner: msg.sender,
			lockedFunds: msg.value,
			style: style,
			metadata: metadata
		});
	}

	function returnLockedFunds(Cube cube) internal {
		cube.owner.transfer(cube.lockedFunds);
	}
}