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
contract Game {
    
    struct Better {
        address betterAddress;
        uint contribAmount;
    }
    
    struct Side {
        uint totalPledged;
        bytes32 sideName;
        Better[] betters;
    }
    string gName;
    bytes32[] sides;
    uint expiry;
    mapping (bytes32 => Side) public games;
    
    constructor (string gameName, uint gameExpiry, bytes32[] gameSides) public {
        gName = gameName;
        expiry = gameExpiry;
        for (uint i = 0; i<gameSides.length; i++) {
            games[gameSides[i]].sideName=gameSides[i];
            sides.push(gameSides[i]);
        }
    }
    
    function getGameName() view public returns (string) {
        return gName;
    }
    function getGameSides() view public returns (bytes32[]) {
        return sides;
    }
    function isNotExpired() view public returns (bool) {
        return (now < expiry);
    }
    function getNumSides() view public returns (uint) {
        return sides.length;
    }
    
}


contract BEthy is ExchangeAdmin {
    string public name;
    Game[] current;
    
    // Test:        &quot;BEthy&quot;
    // Game Test:   &quot;Uruguay vs France&quot;, 1530626815, [&quot;0x55727567756179&quot;, &quot;0x4672616e6365&quot;]
    //constructor (string contractName) public {
    //    name = contractName;
    //}
    constructor () public {
        name = &quot;BEthy&quot;;
    }
    
    function addGame(string gameName, uint gameExpiry, bytes32[] gameSides) public {
        current.push(new Game(gameName, gameExpiry, gameSides));
    }
    
    function numGames() view public returns (uint) {
        return current.length;
    }
    
    function getName(uint i) view public returns (string) {
       return current[i].getGameName();
    }
    
    function getSides(uint i, uint j) view public returns (string) {
        return StringYokes.zint_bytes32ToString(current[i].getGameSides()[j]);
    }
    
    function getGameNumSides(uint i) view public returns (uint) {
        return current[i].getNumSides();
    }
    function zint_now() view public returns (uint) {
        return now;
    }
    function gameActive(uint i) view public returns (bool) {
        return current[i].isNotExpired();
    }
    function _byteToString(bytes32 x) public pure returns (string) {
        return StringYokes.zint_bytes32ToString(x);
    }
    function _stringToByte(string x) public pure returns (bytes32) {
        return StringYokes.zint_convert(x);
    }
    
}