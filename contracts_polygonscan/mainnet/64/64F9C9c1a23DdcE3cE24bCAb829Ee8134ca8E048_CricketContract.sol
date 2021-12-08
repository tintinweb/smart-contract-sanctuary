pragma solidity >=0.4.21 <0.9.0;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
contract CricketContract is Ownable,ERC721 { 
    using SafeMath for uint256;


    // dna settings
    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    uint public levelUpFee = 0.001 ether;
    uint public cricketPrice = 0.001 ether;
    uint public cricketCount = 0;
    uint public winningBettorCount;
    uint public roundBettorCount_temp = 0;
    uint public roundBettorCount = 0;


    // Nonce
    uint randNonce = 0;

    uint bettingWinnerCount;

    // VictoryProbability
    uint attackVictoryProbability = 70;


    // Betting Stake
    uint public bettingStake = 1 ether;


    // Cricket Structure
    struct Cricket {
        string name;
        uint dna;
        uint16 winCount;
        uint16 lossCount;
        uint level;
    } 

    // Bettor list
    address[] public bettors;


    // Cricket Set
    Cricket[] public crickets;


    // ID => Address Mapping
    mapping (uint => address) public cricketToOwner;


    // Address => Cricket Count Mapping
    mapping (address => uint) ownerCricketCount;


    // ID => Approved Addresses
    mapping (uint => address) cricketApprovals;

    // Address => Cricket ID it's betting on
    mapping (address => uint) bettingPool;

    // Cricket ID => Battle Result
    mapping (uint => bool) lastBattle;



    // Check if sender is cricket owner
    modifier onlyOwnerOf(uint cricketId) {
        require(msg.sender == cricketToOwner[cricketId], "This cricket doesn't belong to you.");
        _;
    }


     // New Cricket Created Event
     event NewCricket(uint cricketId, string name, uint dna);

     function createRandomCricket(string memory name) public {
        // Check if the address already have cricket, if have, prompt 'you already have a cricket'
        require(ownerCricketCount[msg.sender] == 0, "You already have a cricket.");
        uint randomDna = _generateRandomDna(name);
        randomDna = randomDna - randomDna % 10; // Mark last dna digit to 0, marked as free cricket
        _createCricket(name, randomDna);
    }


        // Purchase random cricket
    function buyRandomCricket(string memory name) public payable {
        // Check if the address already have cricket, if no, prompt 'you can create a cricket for free'
        require(ownerCricketCount[msg.sender] > 0, "You can create a cricket for free.");
        // Check if user sent enough money for the cricket, if not, prompt 'Your balance is not enough'
        require(msg.value >= cricketPrice, "Your balance is not enough.");
        uint randomDna = _generateRandomDna(name);
        randomDna = randomDna - randomDna % 10 + 1; // Mark last dna digit to 1, marked as paid cricket
        _createCricket(name, randomDna);
    }


       // Pseudo Random dna generation
    function _generateRandomDna(string memory name) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(name, block.timestamp))) % dnaModulus;
    }


        // Cricket Creation function
    function _createCricket(string memory name, uint dna) internal  {
        // Generate a cricket
        crickets.push(Cricket(name, dna, 0, 0, 1));
        uint cricketId = crickets.length - 1;
        // Set the owner
        cricketToOwner[cricketId] = msg.sender;
        ownerCricketCount[msg.sender] = ownerCricketCount[msg.sender].add(1);
        cricketCount = cricketCount.add(1);
        // Emit the event
        emit NewCricket(cricketId, name, dna);
    }



    // Helper functions


    // Paid level up
        function levelUp(uint cricketId) external payable onlyOwnerOf(cricketId){
        require(msg.value >= levelUpFee, "Your balance is not enough.");
        crickets[cricketId].level++;
    }
    // Name changing function (Only owner can change)
        function changeName(uint cricketId, string calldata name) external onlyOwnerOf(cricketId) {
        crickets[cricketId].name = name;
    }
    // DNA changing function (Only owner can change)
    function changeDna(uint cricketId, uint dna) external onlyOwnerOf(cricketId) {
        crickets[cricketId].dna = dna;
    }


       // Acquire a list of cricket ids owned by a specific address
    function getCricketsByOwner(address owner) external view returns (uint[] memory) {
        uint[] memory result = new uint[](ownerCricketCount[owner]);
        uint counter = 0;
        for (uint i = 0; i < crickets.length; i++) {
            if (cricketToOwner[i] == owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }



    // Acquire specific address's cricket count
        function getCricketsOwnerNum(address owner) external view returns (uint) {
            return ownerCricketCount[owner];
    }



    // Acquire cricket name and dna by id
        function getCricketsInfoById(uint _mid) view public returns(string memory,uint,uint,address) {  
        return (crickets[_mid].name,crickets[_mid].dna,crickets[_mid].level,cricketToOwner[_mid]);
    }
            function getCricketsNum() public view returns (uint) {
            return cricketCount;
    }

    
    // For new cricket created in battle
    function _multiply(uint cricketId, uint targetDna) internal onlyOwnerOf(cricketId) {
        Cricket storage cricket = crickets[cricketId];
        // newDna = (cricket dna + targetDna)/2
        targetDna = targetDna % dnaModulus; // Make sure targetDna fits the same format
        uint newDna = (cricket.dna + targetDna) / 2;
        newDna = newDna - newDna % 10 + 9; // Mark last dna digit to 9, marked as battle generated cricket
        _createCricket("New_Cricket", newDna);
    }


    
    // Ownership functions


    // With address returns cricket count
    function balanceOf(address owner) external view override returns (uint256 balance) {
        return ownerCricketCount[owner];
    }
    
   // With cricket id returns owning address
    function ownerOf(uint256 tokenId) external view override returns (address owner) {
        return cricketToOwner[tokenId];
    }

    // Cricket transfer
    function transfer(address to, uint256 tokenId) external override {
        // Check if sender is cricket owner or approved address, if not, prompt 'You are neither the owner nor an approved address'
        require(msg.sender == cricketToOwner[tokenId] || msg.sender == cricketApprovals[tokenId] , "You are neither the owner nor an approved address.");
        _transfer(msg.sender, to, tokenId);
    }

    // Approve address 
    function approve(address to, uint256 tokenId) external override {
        // Check if sender is cricket owner first, if not, prompt 'You are not the owner'
        require(msg.sender == cricketToOwner[tokenId], "You are not the owner.");
        cricketApprovals[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    // Ownership taking
    function takeOwnership(uint256 tokenId) external override {
        // Check if sender is an approved address, if not, prompt 'You are not approved'
        require(msg.sender == cricketApprovals[tokenId], "You are not approved.");
        address owner = cricketToOwner[tokenId];
        _transfer(owner, msg.sender, tokenId);
    }


    // Cricket transfer internal function
     function _transfer(address from, address to, uint tokenId) internal {
        ownerCricketCount[to] = ownerCricketCount[to].add(1);
        ownerCricketCount[from] = ownerCricketCount[from].sub(1);
        cricketToOwner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }


    // Battle funcitons

    // Pseudo random number generator
    function randMod(uint modulus) internal returns (uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % modulus;
    }

    // Set attack victory probability
    function setAttackVictoryProbability(uint probability) external onlyOwner {
        attackVictoryProbability = probability;
    }

    // Attack
    function attack(uint cricketId, uint targetId) external onlyOwnerOf(cricketId) {
        Cricket storage myCricket = crickets[cricketId];
        Cricket storage enemyCricket = crickets[targetId];
        // Flush lastBattle
        lastBattle[cricketId] = false;
        lastBattle[targetId] = false;

        // Flush betting round
        roundBettorCount_temp = 0;

        // Flush bettingPool
        for (uint256 i = 0; i < bettors.length; i++) {
            // If the bettor is betting on non of the battling cricket, he's betting on cricket number 1000000000000000000000000
            if(bettingPool[bettors[i]] != cricketId && bettingPool[bettors[i]] != targetId) {
                // I don't think we'll have 1000000000000000000000000 crickets within 100 year's time
                bettingPool[bettors[i]] = 1000000000000000000000000;
            }
        }


        // Generate random number as determinant for this specific battle
        uint rand = randMod(100)-myCricket.level; // Higher the level, smaller the rand, more likely to win
        if (rand < attackVictoryProbability) {
            // Win
            myCricket.winCount++;
            myCricket.level++;
            enemyCricket.lossCount++;
            _multiply(cricketId, enemyCricket.dna);
            lastBattle[cricketId] = true; // Record battle result in lastBattle
            lastBattle[targetId] = false;
        } else {
            // Loss
            myCricket.lossCount++;
            enemyCricket.winCount++;
            lastBattle[cricketId] = false; // Record battle result in lastBattle
            lastBattle[targetId] = true;

        }

        winningBettorCount = 0;
        // Track how many bettors won
        for (uint256 i = 0; i < bettors.length; i++){
            if(lastBattle[bettingPool[bettors[i]]] == true) {
                winningBettorCount += 1;
            }
        }
        // Reset betting round
        roundBettorCount_temp = roundBettorCount;
        roundBettorCount = 0;

    }


    // Betting

    function checkBettorExist(address bettor) public view returns (bool) {
        for (uint256 i = 0; i < bettors.length; i++) {
            if(bettors[i] == bettor) return true;
        }
        return false;
    }


    function placeBet(uint bettingCricketId) external payable {
        require(msg.value >= bettingStake, 'Your account balance is smaller than 1 ETH');
        bettingPool[msg.sender] = bettingCricketId;
        bettors.push(msg.sender);
        roundBettorCount += 1;
    }

    function claimBet() payable public {
        require(checkBettorExist(msg.sender), 'You have not placed a bet.');
        require(lastBattle[bettingPool[msg.sender]] == true, 'The cricket you bet on lost :(, or you have already claimed your reward!');
        // Distribute
        payable(msg.sender).transfer(roundBettorCount_temp * 1 ether / winningBettorCount);

        // Make sure you can only claim once
        bettingPool[msg.sender] = 1000000000000000000000000;
    }




        // Return sender
    function returnSender() public view returns (address) {
        return msg.sender;
    }

}