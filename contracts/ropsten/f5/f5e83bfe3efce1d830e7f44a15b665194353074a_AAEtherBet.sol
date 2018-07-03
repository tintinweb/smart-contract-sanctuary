pragma solidity ^0.4.24;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Admin {
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
    function convert(string key) public pure returns (bytes32 ret) {
        if (bytes(key).length > 32) revert();
        assembly {
          ret := mload(add(key, 32))
        }
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
    
}


contract AAEtherBet is Admin {
    string public name;
    Game[] current;
    
    // Test:    &quot;BEthy&quot;, &quot;Uruguay vs France&quot;, 0, [&quot;Uruguay&quot;, &quot;France&quot;]
    constructor (string contractName) public {
        name = contractName;
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
    
    function getSides(uint i) view public returns (bytes32[]) {
        return current[i].getGameSides();
    }
    
}