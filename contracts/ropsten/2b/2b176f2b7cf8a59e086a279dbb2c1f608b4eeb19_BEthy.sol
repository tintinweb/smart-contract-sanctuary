pragma solidity ^0.4.24;

contract ExchangeAdmin {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyAdmin {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyAdmin {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
library StringYokes {
        function zint_bytes32ToString(bytes32 x) public pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    function zint_convert(string key) public pure returns (bytes32 ret) {
        if (bytes(key).length > 32) revert();
        assembly {
          ret := mload(add(key, 32))
        }
    }
}    
contract Game is ExchangeAdmin {
    
    bool expired;
    
    struct Better {
        bool used;
        address betterAddress;
        uint contribAmount;
    }
    
    struct Side {
        uint totalPledged;
        bytes32 sideName;
        address[] usedAddresses;
        mapping (address => Better) contribDb;
    }
    string gName;
    bytes32[] sides;
    uint allSidesPledged;
    uint expiry;
    mapping (bytes32 => Side) public sideData;
    mapping (bytes32 => uint) public idToNameRef;
    
    constructor (string gameName, uint gameExpiry, bytes32[] gameSides) public {
        gName = gameName;
        expiry = gameExpiry;
        for (uint i = 0; i<gameSides.length; i++) {
            sideData[gameSides[i]].sideName=gameSides[i];
            idToNameRef[gameSides[i]]=i;
            sides.push(gameSides[i]);
        }
        expired = false;
        allSidesPledged = 0;
    }
    
    function getGameName() view public returns (string) {
        return gName;
    }
    function getGameSides() view public returns (bytes32[]) {
        return sides;
    }
    function isNotExpired() view public returns (bool) {
        return ((now < expiry) && !expired);
    }
    function getNumSides() view public returns (uint) {
        return sides.length;
    }
    function getStrFromId(uint toConv) view public returns (string) {
        return StringYokes.zint_bytes32ToString(sides[toConv]);
    }
    function getIdFromStr(string toConv) view public returns (uint) {
        return idToNameRef[StringYokes.zint_convert(toConv)];
    }
    
    function placeBet(address a, uint value, string betSide) public payable {
        require(isNotExpired());
        bytes32 index = StringYokes.zint_convert(betSide);
        sideData[index].totalPledged+=value;
        allSidesPledged+=value;
        if (sideData[index].contribDb[a].used) {
            value+=sideData[index].contribDb[a].contribAmount;
        }
        else {
            sideData[index].usedAddresses.push(a);
            sideData[index].contribDb[a].used=true;
        }
        sideData[index].contribDb[a].contribAmount+=value;
    }
    
    function allSidesPledgedAmount() public view returns (uint) {
        return allSidesPledged;
    }
    
    function checkSidePledge(uint i) public view returns (uint) {
        return sideData[sides[i]].totalPledged;
    }
    function dish(string winner, address profit) public onlyAdmin payable {
        require(!expired);
        expired = true;
        bytes32 winByte = StringYokes.zint_convert(winner);
        uint totalGameContrib = allSidesPledged;
        uint totalSideContrib = (sideData[winByte].totalPledged);
        for (uint i = 0; i<sideData[winByte].usedAddresses.length; i++) {
            address recip = sideData[winByte].usedAddresses[i];
            uint contribAmount = sideData[winByte].contribDb[recip].contribAmount;
            uint winAddition = (925*1000*contribAmount*(totalGameContrib-totalSideContrib))/(1000000*totalSideContrib);
            recip.transfer(contribAmount+winAddition);
        }
        profit.transfer(address(this).balance);
    }
    function refund() public onlyAdmin payable {
        for (uint i = 0; i<sides.length; i++) {
            for (uint j = 0; j<sideData[sides[i]].usedAddresses.length; j++) {
            address recip = sideData[sides[i]].usedAddresses[j];
            uint contribAmount = sideData[sides[i]].contribDb[recip].contribAmount;
            recip.transfer(contribAmount);
            }
        }
    }
    
}

contract BEthy is ExchangeAdmin {
    Game[] current;
    uint etherBalance;
    
    mapping (bytes32 => uint) public references;
    
    constructor () public {
    }
    
    function addGame(string gameName, uint gameExpiry, bytes32[] gameSides) onlyAdmin public {
        current.push(new Game(gameName, gameExpiry, gameSides));
        references[StringYokes.zint_convert(gameName)]=current.length-1;
    }
    
    function numGames() view public returns (uint) {
        return current.length;
    }
    
    function getName(uint i) view public returns (string, bool, uint) {
       return (current[i].getGameName(), current[i].isNotExpired(), current[i].allSidesPledgedAmount());
    }
    
    function getSidesById(uint i, uint j) view public returns (string, uint) {
        return (StringYokes.zint_bytes32ToString(current[i].getGameSides()[j]), current[i].checkSidePledge(j));
    }
    
    function getSides(string str, uint j) view public returns (string, uint) {
        return getSidesById(references[StringYokes.zint_convert(str)], j);
    }
    
    function getGameNumSides(uint i) view public returns (uint) {
        return current[i].getNumSides();
    }
    function _byteToString(bytes32 x) public pure returns (string) {
        return StringYokes.zint_bytes32ToString(x);
    }
    function _stringToByte(string x) public pure returns (bytes32) {
        return StringYokes.zint_convert(x);
    }
    
    function () public payable {
        etherBalance+=msg.value;
    }
    
    function getBalance() public view returns (uint) {
        return etherBalance;
    }
    function getAddBal() public view returns (uint) {
        return address(this).balance;
    }
    
    function placeBet(uint gameId, string betSide) payable public {
        require(msg.value!=0);
        etherBalance+=msg.value;
        current[gameId].placeBet.value(msg.value)(msg.sender, msg.value, betSide);
    }
    
    function placeBet(string gameId, string betSide) payable public {
        placeBet(references[StringYokes.zint_convert(gameId)], betSide);
    }
    
    function checkGameAmount(uint gameId) public view returns (uint) {
        return current[gameId].allSidesPledgedAmount();
    }
    function checkGameSideAmount(uint gameId, uint sideNum) public view returns (uint) {
        return current[gameId].checkSidePledge(sideNum);
    }
    
    function endGame(uint gameId, string winningSide, address beneficiary) public onlyAdmin {//returns (address[10], uint[10]) {
        current[gameId].dish(winningSide, beneficiary);
    }
    function endGame(uint gameId, uint winningId, address profit) public onlyAdmin {
        endGame(gameId, current[gameId].getStrFromId(winningId), profit);
    }
}