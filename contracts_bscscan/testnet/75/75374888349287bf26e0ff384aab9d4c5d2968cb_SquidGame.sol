/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


// File: @openzeppelin/contracts/utils/Context.sol
contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol
library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }


    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface ERC721Interface {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract SquidGame is Ownable {
    
    using SafeMath for uint256;

    // FIELDS 

    ERC721Interface sgPass;
    address nftAddress = 0xBca0305cBc7Ca6F72d54705c68CEBdC4bcC05FdB; // TODO: update this before deploy

    // STRUCT
    // struct Round {
    //     uint ID;
    //     uint startTime;
    //     uint endTime;
    // }
    
    uint currentRoundStartTime;
    uint currentRoundEndTime;
    

    bool public gameIsActive = false;
    bool public gameEND = false;
    uint public maxGameRound = 6;
    uint public totalPrize = 1 ether;
    uint public roundNumber = 0;

    // Round[] public allRounds;
    uint sgSurvivorCount;
    uint sgBriberCount;
    mapping (uint => uint) public sgPlayerRound; // records NFT-ID with the round they played
    mapping (uint => bool) public sgSurvivor;   // (id => bool)
    mapping (uint => bool) public sgBriber;     // (id => bool)
    mapping (uint => bool) public sgWinnerRewarded; // records NFT-ID with prize claimed (id => bool)
    

    // EVENETS
    event roundStarted(uint roundID);
    event playAndSurvive(uint nftID);
    event playAndDied(uint nftID);
    event officerBribed(uint nftID);
    event prizeClaimed(uint nftID);
    event logerror(string msg); // TODO: to be removed

    // - - - - -- - - - -- - - - -- - - - -- - - - -- - - - -- - - - -- - - - -- - - - -
    
    
    constructor() {
        sgPass = ERC721Interface(nftAddress);
    }

    // FUNCTIONS
    
    function deposit() payable public onlyOwner {
    }

    function getNftBalance(address player) internal view returns (uint) {
        return sgPass.balanceOf(player);
    }

    function getNftID(address player, uint nftIndex) internal view returns (uint) {
        return sgPass.tokenOfOwnerByIndex(player, nftIndex);
    }

    function flipGameState() public onlyOwner {
        gameIsActive = !gameIsActive;
    }


    function roundStart(uint _roundID) public onlyOwner
    {   
        // if (!gameIsActive) {
        //     logerror("gameIsActive wrong");
        // } 
        
        // if (address(this).balance > 0) {
        //     logerror("balance right");
        // } 
        
        // if (_roundID != roundNumber.add(1)) {
        //     logerror("round wrong");
        // }

        // require(gameIsActive, "The Squid Game has not been activated");
        // require(address(this).balance > 0, "The pot is not filled up yet"); // should be 456
        // require(_roundID == roundNumber.add(1), "Incorrect round order");

        roundNumber++;
        
        // Round memory newRound;
        // newRound.ID = _roundID;
        // newRound.startTime = block.timestamp; 
        // newRound.endTime = block.timestamp.add(600); // 10min later
        // allRounds[_roundID] = newRound;
        
        currentRoundStartTime = block.timestamp; 
        currentRoundEndTime = block.timestamp.add(600); // 10min later

        roundStarted(_roundID);
    }

    function playTheRound(uint nftIndex) public returns (bool)
    {
        require(gameIsActive && !gameEND, "The Squid Game is stopped");

        bool validPlayTime = (block.timestamp > currentRoundStartTime) && (block.timestamp < currentRoundEndTime);
        require(validPlayTime, "This round is ended.");
        
        uint nftCount = getNftBalance(msg.sender);
        require(nftCount > 0, "You do not have a SG Pass to play.");
        require(nftIndex < nftCount, "Your input NFT index is not valid");

        uint nftID = getNftID(msg.sender, nftIndex);
        uint playedRoundNum = sgPlayerRound[nftID];
        bool alreadyPlayed = playedRoundNum == roundNumber;
        require(alreadyPlayed, "You have already played this round.");

        bool alive = (roundNumber == 1) || (sgSurvivor[nftID]);
        require(alive, "Sorry, you are dead.");

        
        sgPlayerRound[nftID] = roundNumber; // to record the player who has played this round
        sgSurvivorCount++;

        // assign the players into surviver list if they played and won
        if (_winOrDie(nftID)) {
            sgSurvivor[nftID] = true;
            playAndSurvive(nftID);
        } else {
            sgSurvivor[nftID] = false;
            sgSurvivorCount--;
            playAndDied(nftID);
        }

        // check if need to endGame early
        _endingCheck();
    }

    function bribeOfficer(uint nftIndex) public payable {
        require(gameIsActive && !gameEND, "The Squid Game is stopped");
        require(msg.value >= 0.01 ether); // TODO: need update before deploy

        uint nftID = getNftID(msg.sender, nftIndex);
        sgBriber[nftID] = true;
        sgBriberCount++;
        officerBribed(nftID);
    }

    function _endingCheck() internal {
        bool noMoreSurvivors = sgSurvivorCount <= 1;
        bool lastRound = roundNumber == 6;

        if (noMoreSurvivors || lastRound) { 
            gameEND = true;
        } 
    }

    function _winOrDie(uint nftID) internal returns (bool) {
        uint rand = getRandomNum();
 
        if (sgBriber[nftID]) {
            sgBriber[nftID] = false;
            sgBriberCount--;
            return rand > 25; // 75% chance to win for bribed player
        } else {
            return rand > 50; // 50% chance to win for normal player
        }
    }

    function claimPrize(uint nftIndex) public
    {
        require(gameEND, "The game is still going on");
        
        uint nftID = getNftID(msg.sender, nftIndex);
        bool rewardClaimed = sgWinnerRewarded[nftID] == true;
        require(!rewardClaimed, "You have already claimed the winning prize");

        if (sgSurvivor[nftID]) {
            
            uint remainer = totalPrize.mod(sgSurvivorCount);
            uint prizePerWinner = (totalPrize.sub(remainer)).div(sgSurvivorCount);
            
            (msg.sender).transfer(prizePerWinner);  
            sgWinnerRewarded[nftID] == true;
            prizeClaimed(nftID);
            
        }
    }

    // in case there are no survivors or anything wrong in the middle of game
    function resetGame() public onlyOwner {
        require(!gameIsActive, "The game is going on.");

        gameEND = false;
        roundNumber = 0;
        sgSurvivorCount = 0;
        currentRoundStartTime = 0;
        currentRoundEndTime = 0;
    }


    // GETTER


    function getRandomNum() internal view returns (uint rand) {
        return ((uint(blockhash(block.number-1))).mod(100)).add(1); // return result from 1 to 100
    }

    function drain() public onlyOwner 
	{
		(msg.sender).transfer(address(this).balance);
	}


}