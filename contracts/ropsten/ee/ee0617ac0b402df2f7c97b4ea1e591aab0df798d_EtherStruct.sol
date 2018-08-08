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

	function packLocation (uint64 x, uint64 y, uint64 z) public pure returns(uint256){
		uint256 sum;
		sum += uint256(x) * (2**128);
		sum += uint256(y) * (2**64);
		sum += z;
		return sum;
	}

	mapping(uint256 => Cube) public worldspace;
	uint public worldCornerX;
	uint public worldCornerY;
	uint public worldCornerZ;

	constructor(uint64 startingWorldCornerX, uint64 startingWorldCornerY, uint64 startingWorldCornerZ) public {

		//Set the starting world corners
		worldCornerX = startingWorldCornerX;
		worldCornerY = startingWorldCornerY;
		worldCornerZ = startingWorldCornerZ;
	}

	function increaseWorldCorner(uint64 newWorldCornerX, uint64 newWorldCornerY, uint64 newWorldCornerZ) external onlyOwner {

		// Ensure we can&#39;t shrink the world to make cubes inaccessible
		require(newWorldCornerX >= worldCornerX && newWorldCornerY >= worldCornerY && newWorldCornerZ >= worldCornerZ);

		// Set the new world limit
		worldCornerX = newWorldCornerX;
		worldCornerY = newWorldCornerY;
		worldCornerZ = newWorldCornerZ;
	}

	function placeCube(uint64 x, uint64 y, uint64 z, uint style, uint metadata) external payable {

		// Ensure the new cube is within bounds
		require(x < worldCornerX && y < worldCornerY && z < worldCornerZ);

		// Convert the coordinates to the packed location key
		uint256 packedLocation = packLocation(x, y, z);

		// Ensure the request is exceeding the previously locked value
		require(msg.value > worldspace[packedLocation].lockedFunds);
		
		// Don&#39;t send nothing to nobody
		if(worldspace[packedLocation].owner != 0x0)
			returnLockedFunds(worldspace[packedLocation]);
			
		// Place a block
		worldspace[packedLocation] = Cube({
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