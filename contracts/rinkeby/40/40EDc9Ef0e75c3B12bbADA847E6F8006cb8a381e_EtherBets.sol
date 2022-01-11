// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// New version of the lottery. Trying out a bit map to avoid the need for sorted arrays.

interface RandomNumberConsumer{
    function getRandomNumber() external returns (bytes32 requestId);
}

contract EtherBetsFactory{
    event NewLottery(address lottery);
    address[] public contracts;

    function newEtherBets(string memory _name, uint _betCost, uint8 _maximumNumber, uint8 _picks, uint256 _timeBetweenDraws, address _VRF) public returns (address){
        EtherBets e = new EtherBets(_name,_betCost, _maximumNumber, _picks, _timeBetweenDraws, _VRF);
        contracts.push(address(e));
        emit NewLottery(address(e));
        return address(e);
    }
}

contract EtherBets{ // how do I name this..
    event NumbersDrawn(uint8[] winningNumbers, uint256 draw);
    event BetPlaced(address indexed sender, uint8[] numbers, uint256 draw);
    event RandomnessRequested(uint256 draw);
    event RandomnessFulfilled(uint256 randomness, uint256 draw);

    /**
     * The name of this lottery instance.
     */
    string public name;
    
    /**
     * The cost in ETH or MATIC to place a bet.
     */
    uint256 public betCost;
    
    /**
     * The largest number that can be picked/drawn (up to 256).
     */
    uint8 public maximumNumber;

    /**
     * How many numbers must be picked in a bet. 
     */
    uint8 public picks;

    uint8[] public winningNumbers;
    
    /**
     * A number representing the draw, it is incremented after each draw.
     */
    uint256 public draw;

    /**
     * Maps a bet to the addresses that made them.
     * The bet is the keccak256(abi.encode(arrayToUint(arr), n)), where arr
     * is an ascending uint8 array with the numbers chosen by the user,
     * and n is the number of the draw.
     */
    mapping(uint => address[]) public betToAddresses;

    /**
     * Stores the time in seconds of the last draw.
     */
    uint256 public lastDrawTime;

    /**
     * Stores the minimum wait time in seconds between draws.
     */
    uint256 public timeBetweenDraws;

    address public VRF;

    bool public paused;

    uint256 public randomNumber;

    bool public randomNumberFetched;

    constructor(string memory _name, uint _betCost, uint8 _maximumNumber, uint8 _picks, uint256 _timeBetweenDraws, address _VRF) {
        name = _name;
        betCost = _betCost;
        maximumNumber = _maximumNumber;
        picks = _picks;
        timeBetweenDraws = _timeBetweenDraws;
        VRF = _VRF;
    }

    function setRandomNumber(uint256 _randomNumber) public{
        require(msg.sender == VRF, "Only the VRF can set the random number.");
        randomNumber = _randomNumber;
        randomNumberFetched = true;
        emit RandomnessFulfilled(randomNumber, draw);
    }
 
    /**
     * Checks if an array input matches the requirements of this contract.
     */
    function checkRequirements(uint8[] memory arr) public view{
        require(inAcceptableRange(arr), "Numbers must be larger than 0 and less than or equal to maximumNumber.");
        require(arr.length == picks, "Numbers must match expected length.");
    }
    /**
     * Checks if the numbers in the array are in the acceptable range.
     */
    function inAcceptableRange(uint8[] memory arr) public view returns (bool){
        for(uint8 i = 0; i < arr.length; i++){
            if(arr[i] == 0 || arr[i] > maximumNumber){
                return false;
            }
        }
        return true;
    }

    /**
     * Checks if arr contains n.
     */

    function contains(uint8 n, uint8[] memory arr) public pure returns (bool){
        for(uint8 i = 0; i < arr.length; i++){
            if(arr[i] == n){
                return true;
            }
        }
        return false;
    }

    /**
     * Expands randomValue into n random, unique numbers.
     */
    function expand(uint256 randomValue) public view returns (uint8[] memory expandedValues){
        expandedValues = new uint8[](picks);
        
        uint8 inserted = 0;
        uint256 j = 0;

        while(inserted < picks){
            uint8 value = uint8(uint256(keccak256(abi.encode(randomValue, j))) % maximumNumber + 1);
            if(contains(value, expandedValues)){
                j++;
                continue;
            }

            else{
                expandedValues[inserted] = value;
                inserted++;
                j++;
            }
        }
        
        return expandedValues;
    }

    /**
     * Receives a uint8 array, returns a uint256 unique to the number of that array.
     * Example: arr = [1, 2, 3] -> number = 0b000...111
     *          arr = [256, 1, 2] -> number = 0b100...011
     * Input numbers must be between 1 and 256.
     */
    function arrayToUint(uint8[] memory arr) public pure returns (uint){
        uint number = 0;
        for(uint8 i = 0; i < arr.length; i++){
            number |= (1 << (arr[i] - 1));
        }
        return number;
    }

    function beginDraw() public{
        require(block.timestamp - lastDrawTime > timeBetweenDraws, "You must wait longer before another draw is available.");
        require(paused == false, "A draw is already happening");
        paused = true; // pause bets to wait for the result.
        lastDrawTime = block.timestamp;
        RandomNumberConsumer r = RandomNumberConsumer(VRF);
        r.getRandomNumber();
        emit RandomnessRequested(draw);
    }

    function drawNumbers() public{
        require(paused, "The game has to be paused for numbers to be drawn.");
        require(randomNumberFetched, "The random number has not been fetched.");
        winningNumbers = expand(randomNumber);
        emit NumbersDrawn(winningNumbers, draw);
        distributePrize();
        draw++;

        paused = false;
        randomNumberFetched = false;
    }

    /**
    * To test wins. Will be removed.
     */
    function drawNumbersRigged(uint8[] memory numbers) public{
        require(paused, "The game has to be paused for numbers to be drawn.");
        require(randomNumberFetched, "The random number has not been fetched.");

        checkRequirements(numbers);
        winningNumbers = numbers;
        emit NumbersDrawn(winningNumbers, draw);
        distributePrize();
        draw++;

        paused = false;
        randomNumberFetched = false;
    }

    function placeBet(uint8[] memory numbers) public payable{
        require(msg.value == betCost, "msg.value does not match betCost");
        require(paused == false, "Bets are paused to draw the numbers.");
        checkRequirements(numbers);
        betToAddresses[uint(keccak256(abi.encode(arrayToUint(numbers), draw)))].push(msg.sender);
        emit BetPlaced(msg.sender, numbers, draw);
    }

    function distributePrize() internal{
        uint winners = betToAddresses[uint(keccak256(abi.encode(arrayToUint(winningNumbers), draw)))].length;        
        if(winners == 0){
            return;
        }
        uint splitPrize = address(this).balance / winners; // have to learn how to calculate this correctly.
        for(uint i = 0; i < winners; i++){
            address payable a = payable(betToAddresses[uint(keccak256(abi.encode(winningNumbers, draw)))][i]);
            (bool sent, bytes memory data) = a.call{value: splitPrize}("");
            require(sent, "Failed to send Ether");
        }
    }
}