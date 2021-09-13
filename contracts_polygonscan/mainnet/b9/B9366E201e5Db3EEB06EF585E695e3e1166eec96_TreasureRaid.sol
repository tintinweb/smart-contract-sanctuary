pragma solidity =0.6.12;

import './TransferHelper.sol';
import './IERC20.sol';
import "./SafeMath.sol";
import "./Masterchef.sol";

contract TreasureRaid{
	using SafeMath for uint256;

    // The MasterChef contract.
	MasterChef public masterChef;
	// Last winner address.
	address public lastWinner;
	// How many Blocks between Treasure Raids.
    uint256 public treasureTime; 
    // Starting block for the first Treasure Raid.
    uint256 public startTreasureBlock;
    // Block for the next Treasure Raid.
    uint256 public nextTreasureBlock;

	constructor(MasterChef _masterChef, uint256 _startTreasureBlock, uint256 _treasureTime) public {
		masterChef = _masterChef;
        setStartTreasureBlock(_startTreasureBlock);
        setTreasureTime(_treasureTime);
        setNextTreasureBlock(startTreasureBlock + treasureTime);
    }

	receive() external payable {}

    // Generate random number between 0 and the total amount stored in the usersAmount array.
    function getRandomNumber(uint256 limitNumber) internal view returns (uint256){
    	uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now, limitNumber)));
    	random = random.mod(limitNumber);
		return random;
    }

    // Get the winner based on the random number generated.
    function getWinner() internal view returns (address) {
    	uint256 lastIndex = masterChef.userAmountLength();
    	uint256 lastAmount = masterChef.getUserAmount(lastIndex-1);
    	uint256 randomNumber = getRandomNumber(lastAmount);
    	uint256 foundIndex = uint256(-1);

    	for (uint256 i = 0; i < lastIndex; ++i) {
    		if(masterChef.getUserAmount(i) >= randomNumber && foundIndex == uint256(-1)){
    			foundIndex = i;
    		}
    	}
    	
    	address winner = masterChef.getUserAddress(foundIndex);
    	return winner;
    }

    // Set the starting block for the first Treasure Raid.
    function setStartTreasureBlock(uint256 _startTreasureBlock) internal {
        startTreasureBlock = _startTreasureBlock;
    }

    // Set amount of blocks between Treasure Raids.
    function setTreasureTime(uint256 _treasureTime) internal {
        treasureTime = _treasureTime;
    }

    // Set block for the next Treasure Raid.
    function setNextTreasureBlock(uint256 _nextTreasureBlock) internal {
        nextTreasureBlock = _nextTreasureBlock;
    }

    // Check if the current block is a valid block to do the prize draw.
    function checkRaffle() public view returns (bool) {
        return block.number >= nextTreasureBlock;
    }

    // Returns the last winner of the Treasure Raid prize draw.
    function getLastWinner() public view returns (address) {
        require(lastWinner != address(0), "No winner already");
        return lastWinner;
    }

    // Send the tokens assigned to the treasureFeeAddress to a random address with deposited assets (winner).
    function raffle() public {
        uint256 currentBlock = block.number;
        require(currentBlock >= nextTreasureBlock, "You have to wait for the next Treasure Raid");
        
        lastWinner = getWinner();
        for(uint256 i = 0; i < masterChef.poolLength(); ++i){
            address _lpToken = masterChef.getLpToken(i);
            sendTreasure(address(masterChef), _lpToken, lastWinner, masterChef.userPoolAmount(i, address(this)));
            masterChef.resetTreasure(i);
        }

        setNextTreasureBlock(currentBlock + treasureTime);
    }

    // Send the prize to the winner
    function sendTreasure(address _master, address _lpToken, address _to, uint256 _amount) internal {
        TransferHelper.safeTransferFrom(_lpToken, _master, _to, _amount);
    }  
}