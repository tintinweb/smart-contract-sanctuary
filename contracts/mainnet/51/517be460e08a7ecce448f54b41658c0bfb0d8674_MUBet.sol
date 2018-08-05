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
        bool isValidSide;
        uint totalPledged;
        bytes32 sideName;
        address[] usedAddresses;
        mapping (address => Better) contribDb;
    }
    string gName;
    address gameMaker;
    address mainContract;
    bytes32[] sides;
    uint allSidesPledged;
    uint expiry;
    mapping (bytes32 => Side) public sideData;
    mapping (bytes32 => uint) public idToNameRef;
    constructor (string gameName, uint gameExpiry, bytes32[] gameSides,address maker, address mainContractAdd) public {
        require(now<gameExpiry);
        gName = gameName;
        gameMaker = maker;
        expiry = gameExpiry;
        mainContract = mainContractAdd;
        for (uint i = 0; i<gameSides.length; i++) {
            sideData[gameSides[i]].sideName=gameSides[i];
            sideData[gameSides[i]].isValidSide=true;
            idToNameRef[gameSides[i]]=i;
            sides.push(gameSides[i]);
        }
        expired = false;
        allSidesPledged = 0;
    }
    function getGameName() view public returns (string) {
        return gName;
    }
    function getGameMaker() view public returns(address){
      return gameMaker;
    }
    function getGameSides() view public returns (bytes32[]) {
        return sides;
    }
    function isNotExpired() view public returns (bool) {
        return ((now < expiry) && !expired);
    }
    function isExpired() view public returns(bool){
        return expired;
    }
    function getNumSides() view public returns (uint) {
        return sides.length;
    }
    function getExpiryTime() view public returns(uint){
      return expiry;
    }
    function getStrFromId(uint toConv) view public returns (string) {
        return StringYokes.zint_bytes32ToString(sides[toConv]);
    }
    function getIdFromStr(string toConv) view public returns (uint) {
        return idToNameRef[StringYokes.zint_convert(toConv)];
    }
    function placeBet(address a, uint value, string betSide) public payable {
        require(isNotExpired() && value!=0 && msg.sender==mainContract && sideData[StringYokes.zint_convert(betSide)].isValidSide);
        bytes32 index = StringYokes.zint_convert(betSide);
        sideData[index].totalPledged+=value;
        allSidesPledged+=value;
        if (!sideData[index].contribDb[a].used) {
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
    function dish(string winner, address profit) public payable {
        require((!expired) && (mainContract==msg.sender));
        expired = true;
        bytes32 winByte = StringYokes.zint_convert(winner);
        uint totalGameContrib = allSidesPledged;
        uint totalSideContrib = (sideData[winByte].totalPledged);
        for (uint i = 0; i<sideData[winByte].usedAddresses.length; i++) {
            address recip = sideData[winByte].usedAddresses[i];
            uint contribAmount = sideData[winByte].contribDb[recip].contribAmount;
            uint winAddition = (950*1000*contribAmount*(totalGameContrib-totalSideContrib))/(1000000*totalSideContrib);
            recip.transfer(contribAmount+winAddition);
        }
        profit.transfer(2*(address(this).balance/5));
        gameMaker.transfer(address(this).balance);
    }
    function refund(address sentBy) public payable {
        require(!expired && (mainContract==msg.sender) && ((sentBy==gameMaker) || now > getExpiryTime() + 259200));
        for (uint i = 0; i<sides.length; i++) {
            for (uint j = 0; j<sideData[sides[i]].usedAddresses.length; j++) {
                address recip = sideData[sides[i]].usedAddresses[j];
                uint contribAmount = sideData[sides[i]].contribDb[recip].contribAmount;
                recip.transfer(contribAmount);
            }
        }
    }
}

contract MUBet is ExchangeAdmin {
    Game[] current;
    constructor () public {    }

    function numGames() view public returns (uint nGames) {
        return current.length;
    }
    function getName(uint i) view public returns (string gameName, bool isNotExpired, uint totalPledgedETH, bool wasFinalised, uint gameEndTime, address gameMakerAddress, uint gameNumSides, uint gameId) {
       return (current[i].getGameName(), current[i].isNotExpired(), current[i].allSidesPledgedAmount(),current[i].isExpired(),current[i].getExpiryTime(), current[i].getGameMaker(), current[i].getNumSides(), i);
    }
    function getSidesArray(uint i) view public returns (bytes32[] sideNameBytes) {
        return current[i].getGameSides();
    }
    function getSidesById(uint i, uint j) view public returns (string sideName, uint sidePledgedETH) {
        return (StringYokes.zint_bytes32ToString(current[i].getGameSides()[j]), current[i].checkSidePledge(j));
    }
    function getGameNumSides(uint i) view public returns (uint gameNumSides) {
        return current[i].getNumSides();
    }
    function getContractBal() public view returns (uint invalidBalanceETH) {
        return address(this).balance;
    }

    function () public payable {    }
    function emergency(uint amount, address recipient) public onlyAdmin payable {
        recipient.transfer(amount);
    }
    function addGame(string gameName, uint gameExpiry, bytes32[] gameSides) public {
        require(gameSides.length > 1);
        current.push(new Game(gameName, gameExpiry, gameSides, msg.sender, address(this)));
    }
    function endGame(uint gameId, string winningSide) public  {
        require(current[gameId].getGameMaker() == msg.sender);
        current[gameId].dish(winningSide,owner);
    }
    function refund(uint gameId) public {
        current[gameId].refund(msg.sender);
    }
    function placeBet(uint gameId, string betSide) payable public {
        current[gameId].placeBet.value(msg.value)(msg.sender, msg.value, betSide);
    }
}