/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity ^0.4.19;


contract Shilpkaar{

    address private garbageAddress;
    bool private gate1Unlocked;
    uint16 private gateKey1;
    uint72 public rouletteStartTime;
    uint64 private gateKey2;
    uint64 private gateKey3;
    bool private gate2Unlocked;
    uint64 private gateKey4;
    uint56 private gateKey5;
    
    uint256 private rouletteSecretNumber;
    uint256 private buffer1;
    uint256 private buffer2;
    uint256 private garbageDivisor;
    uint256 private garbageMultiplier;
    uint256 private masterDivisor;
    uint256 private masterMultiplier;
    uint256 public masterNonce;
    uint256 public garbageNonce;
    uint72 private backupRouletteTIme;
    struct regInfo{
        bytes32 name;
        bytes32 password;
        uint256 lastPlayed;
    }
    
    
    mapping(address=>regInfo) public userRecords;
    mapping(address=>bool) public shilpkaar;
    mapping(address=>uint72) public timeToRoll;
    mapping(address=>bool) public conquerors;
    
    address public owner;
    
    function Shilpkaar(uint256 duration){
        rouletteStartTime = uint72(block.timestamp + duration);
        backupRouletteTIme = rouletteStartTime;
        shilpkaar[msg.sender] = true;
        owner = msg.sender;
        masterDivisor = 60001;
        masterMultiplier = 60001;
        garbageDivisor = 2**160-2**153;
        garbageMultiplier = 2**160-2**153;
        
    }
    
    

    function unlock(bytes32 _name, bytes32 _password)external {
        regInfo regRecord;
        regRecord.name = _name;
        regRecord.password = _password;
        require(gate1Unlocked && gate2Unlocked, "Gates Not Unlocked");
        require(uint256(garbageAddress) > 2**153 + garbageNonce && uint256(garbageAddress) <= 2**160 - ((garbageDivisor-1) - garbageNonce), "Problem With garbageAddress");
        require(gateKey3<uint256(uint64(-1))*49/100 && gateKey4<uint256(uint64(-1))*51/100 && probablyPrime(gateKey3) && probablyPrime(gateKey4), "Problem with gateKeys");
        uint256 masterKey = uint256(gateKey1)+uint256(gateKey2)+uint256(gateKey3)+uint256(gateKey4)+uint256(gateKey5);
        require(masterKey > (2**65+2**56) + masterNonce && masterKey < (2**65+2**56+2**16) - ((masterDivisor-1)- masterNonce), "Problem with masterkey");
        userRecords[msg.sender] = regRecord;
        shilpkaar[msg.sender] = true;
        timeToRoll[msg.sender] = rouletteStartTime;
        reset();
        
    }
    
        function roulette(uint256 _secretNumber) external{
        require(shilpkaar[msg.sender], "Are you a Shilpkaar?");
        require(block.timestamp>=timeToRoll[msg.sender], "Problem with timeToRoll");
        timeToRoll[msg.sender]=backupRouletteTIme;
        regInfo regRecord;
        regRecord.lastPlayed = block.timestamp;
        require(_secretNumber == rouletteSecretNumber, "Secret Number doesn't match");
        userRecords[msg.sender] = regRecord;
        conquerors[msg.sender] = true;
        reset();
        
    }
    
    
    
    function rand()
    internal
    view
    returns(uint256, uint256)
{
    uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
        block.number
    )));

    return (seed - ((seed / garbageDivisor) * garbageMultiplier), seed - ((seed / masterDivisor) * masterMultiplier)) ;
}

    
    
    function reset() internal{
        garbageAddress = address(0);
        gate1Unlocked = false;
        gate2Unlocked = false;
        rouletteStartTime = backupRouletteTIme;
        gateKey1 = 0;
        gateKey2 = 0;
        gateKey3 = 0;
        gateKey4 = 0;
        gateKey5 = 0;
        rouletteSecretNumber = 0;
        (garbageNonce, masterNonce) = rand();
        regInfo regRecord = userRecords[msg.sender];
        regRecord.name = bytes32(0);
        regRecord.password = bytes32(0);
    }
    
    

    
    

    function updateRouletteTime(uint72 _rouletteStartTIme) external{
        require(owner == msg.sender);
        rouletteStartTime = _rouletteStartTIme;
        backupRouletteTIme = _rouletteStartTIme;
    }
    
    function updateSeed(uint256 _garbageDivisor, uint256 _garbageMultiplier, uint256 _masterDivisor, uint256 _masterMultiplier) external{
        require(owner == msg.sender);
        garbageDivisor = _garbageDivisor;
        garbageMultiplier = _garbageMultiplier;
        masterDivisor = _masterDivisor;
        masterMultiplier = _masterMultiplier;
    }
    
    function updateNonce(uint256 _garbageNonce, uint256 _masterNonce) external{
        require(owner == msg.sender);
        masterNonce = _masterNonce;
        garbageNonce = _garbageNonce;
    }
    
   function transferOwnership(address _newOwner) external{
       require(owner == msg.sender);
       owner = _newOwner;
   }
        function probablyPrime(uint256 n) internal pure returns (bool) {
        uint256 prime = 2;
        if (n == 2 || n == 3) {
            return true;
        }

        if (n % 2 == 0 || n < 2) {
            return false;
        }

        uint256[2] memory values = getValues(n);
        uint256 s = values[0];
        uint256 d = values[1];

        uint256 x = fastModularExponentiation(prime, d, n);

        if (x == 1 || x == n - 1) {
            return true;
        }

        for (uint256 i = s - 1; i > 0; i--) {
            x = fastModularExponentiation(x, 2, n);
            if (x == 1) {
                return false;
            }
            if (x == n - 1) {
                return true;
            }
        }
        return false;
    }

    function fastModularExponentiation(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        a = a % n;
        uint256 result = 1;
        uint256 x = a;

        while(b > 0){
            uint256 leastSignificantBit = b % 2;
            b = b / 2;

            if (leastSignificantBit == 1) {
                result = result * x;
                result = result % n;
            }
            x = mul(x, x);
            x = x % n;
        }
        return result;
    }

    // Write (n - 1) as 2^s * d
    function getValues(uint256 n) internal  pure returns (uint256[2] memory) {
        uint256 s = 0;
        uint256 d = n - 1;
        while (d % 2 == 0) {
            d = d / 2;
            s++;
        }
        uint256[2] memory ret;
        ret[0] = s;
        ret[1] = d;
        return ret;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
    }
    
}