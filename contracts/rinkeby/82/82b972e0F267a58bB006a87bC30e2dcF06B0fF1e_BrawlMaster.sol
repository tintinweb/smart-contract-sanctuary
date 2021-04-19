pragma solidity ^0.8.0;
import "./Signature.sol";
import "./CryptoBrawlRegistry.sol";

contract BrawlMaster is SignatureVerification {

    CryptoBrawlRegistry public Registry;

    event FightCreated(bytes32 fightId);

    struct Fight {
        bytes32 player1CharID;
        bytes32 player2CharID;
        address player1Address;
        address player2Address;
        address player1TempAddress;
        address player2TempAddress;
        bytes32 winner; // победитель боя, либо 0x00 если бой в процессе
    }

    mapping (bytes32 => Fight) public fights;
    bool public initialised;
    mapping (address => uint) public lastNonce;


    function init(address registry) public {
        require(!initialised);
        Registry = CryptoBrawlRegistry(registry);
    }

    function createFight
    (
        uint nonce,
        uint blockNumber,
        address tokenAddressPlayer1,
        uint tokenIdPlayer1,
        address tokenAddressPlayer2,
        uint tokenIdPlayer2,
        address player2Address,
        address player1TempAddress,
        address player2TempAddress,
        bytes memory signature
    )
    public returns(bytes32)
    {
        require(lastNonce[player2Address] < nonce);
        lastNonce[player2Address] = nonce;
        require(blockNumber+100 >= block.number);
        //TODO check if both players own this chars
        bytes32 hash = keccak256(
            abi.encodePacked
            (
                    nonce,
                    blockNumber,
                    tokenAddressPlayer2,
                    tokenIdPlayer2,
                    tokenAddressPlayer1,
                    tokenIdPlayer1
            )
        );
        require(player2Address == recover(hash, signature));
        bytes32 charId1 = genCharId(tokenAddressPlayer1, tokenIdPlayer1);
        if (Registry.getLevel(charId1) == 0) {
            Registry.initChar(charId1, tokenAddressPlayer1, tokenIdPlayer1, msg.sender);
        }
        bytes32 charId2 = genCharId(tokenAddressPlayer2, tokenIdPlayer2);
        if (Registry.getLevel(charId2) == 0) {
            Registry.initChar(charId2, tokenAddressPlayer2, tokenIdPlayer2, player2Address);
        }
        bytes32 fightId = genFightId(nonce, charId1, charId2);
        fights[fightId] = Fight(charId1, charId2, msg.sender, player2Address ,player1TempAddress, player2TempAddress, bytes32(0));
        Registry.setFightId(charId1, charId2, fightId);
        emit FightCreated(fightId);
        return fightId;
    }

    function finishFight(bytes32 fightId, bytes32 winnerCharId, bytes32 looserCharID) public {
        require(msg.sender == fights[fightId].player1Address || msg.sender == fights[fightId].player2Address);
        fights[fightId].winner = winnerCharId;
        Registry.finishFight(winnerCharId, looserCharID);
    }

    function genCharId(address tokenAddress, uint256 tokenID) internal pure returns(bytes32){
        bytes32 charID = keccak256(abi.encodePacked(tokenAddress, tokenID));
        return charID;
    }

    function genFightId(uint nonce, bytes32 charId1, bytes32 charId2) internal pure returns(bytes32) {
        bytes32 fightID = keccak256(abi.encodePacked(nonce, charId1, charId2));
        return fightID;
    }
}

pragma solidity ^0.8.0;

contract SignatureVerification {

    function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
      * toEthSignedMessageHash
      * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
      * and hash the result
      */
    function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
    }
}

pragma solidity ^0.8.0;


contract CryptoBrawlRegistry  {

    struct Character {
        uint8 level;
        uint256 fightsCount;
        uint256 winsCount;
        uint8 fullHp;
        uint8 damage;
        bytes32 fightId;
        uint8 currentXP;
        uint256 tokenId;
        address tokenAddress;
        address owner;
    }

    mapping (bytes32 => Character) public chars;
    address public brawlMaster;

    Character private defaultChar = Character(
        1, // defaultLevel
        0, // fightsCount
        0, // winsCount
        45, // default fullHP
        15, // default damage
        bytes32(0), // fightId
        100, // XP
        0, // tokenID
        address (0), // tokenAddress
        address (0) // owner
    );

    constructor (address _brawlMaster) public {
        brawlMaster = _brawlMaster;
    }


    function initChar(bytes32 charID, address tokenAddress,  uint256 tokenId, address owner) onlyBrawlMaster public {
        chars[charID] = defaultChar;
        chars[charID].tokenAddress = tokenAddress;
        chars[charID].tokenId = tokenId;
        chars[charID].owner = owner;
    }


    function getFightId(bytes32 charID) public view returns (bytes32) {
        return chars[charID].fightId;
    }

    function getLevel(bytes32 charID) public view returns (uint){
        return chars[charID].level;
    }

    function getCharsOwner(bytes32 charID) public view returns (address){
        return chars[charID].owner;
    }

    function levelUp(bytes32 charID) internal {
        chars[charID].level += 1;
        chars[charID].fullHp += 10;
        chars[charID].damage += 1;
    }

    function finishFight(bytes32 winnerCharID, bytes32 looserCharID) onlyBrawlMaster public {
        chars[winnerCharID].fightsCount +=1;
        chars[looserCharID].fightsCount +=1;
        chars[winnerCharID].fightId = bytes32(0);
        chars[looserCharID].fightId = bytes32(0);
        chars[winnerCharID].winsCount += 1;
        levelUp(winnerCharID);
    }

    function setFightId(bytes32 charId1, bytes32 charId2, bytes32 fightId) onlyBrawlMaster public {
        chars[charId1].fightId = fightId;
        chars[charId2].fightId = fightId;
    }


    modifier onlyBrawlMaster() {
        require(msg.sender == brawlMaster);
        _;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}