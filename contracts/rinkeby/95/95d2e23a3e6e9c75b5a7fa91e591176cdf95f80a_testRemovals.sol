/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.7.3;

interface IRNG {
    function isRequestComplete(bytes32 req) external view returns (bool);

    function requestRandomNumber() external returns (bytes32);

    function randomNumber(bytes32 id) external view returns (uint256);
}


contract testRemovals {
    
    IRNG        public rng;
    bool        public drawingStarted;
    bool        public allWinners;
    uint    []  public entrantArray;
    uint    []  public winners;
    bytes32 []         randos;
    bool        public randomsProcessed;
    bool        public auctionWinnersRemoved;
    address     public owner = msg.sender;

    uint256   constant random_mask   = 0xffffffff; // 4 bytes (32 bits) to reduce low order bias

    
    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorised");
        _;
    }

    constructor(IRNG _rng) {
        rng = _rng;
    }
    
    function addEntrant(uint n) internal {
        require(n == entrantArray.length, "Numerical order issue");
        entrantArray.push(n);
    }
    
    function removeRecord(uint n) internal {
        uint len = entrantArray.length;
        require(n < len,"invalid entry");
        entrantArray[n] = entrantArray[len-1];
        entrantArray.pop();
    }
    
    function getAndRemove(uint n) internal returns (uint) {
        uint out = entrantArray[n];
        removeRecord(n);
        return out;
    }
    
    function getAndRemoveRandom(uint random) internal returns (uint) {
        uint newN = random % entrantArray.length;
        return getAndRemoveRandom(newN);
    }
    
    
    //
    // 
    function startDrawingRaffleWinners() external onlyOwner {
        require(!drawingStarted,"Drawing alredy started");
        drawingStarted = true;
        if (entrantArray.length <= 80) {
            allWinners = true;
            return;
        }
        for (uint j = 0; j < 10; j++) {
            request_ten_randoms();
        }
    }

    // auctionWinners must be in descending order....
    function removeWinningAuctionBids(uint[20] memory auctionWinners) external onlyOwner {
        require(!auctionWinnersRemoved,"Auction winners already removed");
        for (uint j = 0; j < 20; j++) {
            require(entrantArray[auctionWinners[j]]==auctionWinners[j],"You seem to be removing the wrong entries");
            removeRecord(auctionWinners[j]);
        }
        auctionWinnersRemoved = true;
    }
    
    function randomsAvailable() public view returns (bool) {
        require(randos.length > 0,"Random have not been requested");
        for (uint j = 0; j < 10; j++) {
            if (!rng.isRequestComplete(randos[j])) return false;
        }
        return true;
    }

    function request_ten_randoms() internal {
        require(randos.length == 0,"Random already requested");
        for (uint j = 0; j < 10; j++) {
            randos.push(rng.requestRandomNumber());
        }
    }

    
    function processRandom(uint _random) internal {
        uint random = _random;
        for (uint j = 0; j < 8; j++) {
            uint256 small_rand = random & random_mask;
            winners.push(getAndRemoveRandom(small_rand));
            random = random >> 32;
        }
    }

    function processTenRandoms() external onlyOwner {
        require(!randomsProcessed,"Randoms already processed");
        require(randomsAvailable(),"Randoms not ready yet");
        for (uint j = 0; j < 10; j++) {
            processRandom(rng.randomNumber(randos[j]));
        }
        randomsProcessed = true;
    }

}