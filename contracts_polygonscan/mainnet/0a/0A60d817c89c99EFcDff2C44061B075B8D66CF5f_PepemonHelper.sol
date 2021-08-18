/**
 *Submitted for verification at polygonscan.com on 2021-08-18
*/

pragma experimental ABIEncoderV2;
interface Pepe{
 struct BattleCardStats {
        uint16 element;
        uint16 hp;
        uint16 speed;
        uint16 intelligence;
        uint16 defense;
        uint16 attack;
        uint16 specialAttack;
        uint16 specialDefense;
        uint16 level;
        string name;
        string description;
        string ipfsAddr;
        string rarity;
    }

    struct SupportCardStats {
        bytes32 currentRoundChanges;
        bytes32 nextRoundChanges;
        uint256 specialCode;
        uint16 modifierNumberOfNextTurns;
        bool isOffense;
        bool isNormal;
        bool isStackable;
        string name;
        string description;
        string ipfsAddr;
        string rarity;
    }
    
    function setSupportCardStats(uint id, SupportCardStats calldata x) external;
    function setBattleCardStats(uint id, BattleCardStats calldata x) external;
    function isWhitelistAdmin(address account) external view returns (bool);
    function battleCardStats(uint i) external view returns(BattleCardStats memory);
    function supportCardStats(uint i) external view returns(SupportCardStats memory);
}
contract PepemonHelper{
    Pepe constant pepemon = Pepe(0xA02e589D5a8E3C0F540ebb931FDA0b91D742A79E);

    modifier onlyAdmin{
        require (pepemon.isWhitelistAdmin(msg.sender));
        _;
    }
    function kill() onlyAdmin public{
        selfdestruct(payable(msg.sender));
    }
    function setIPFSSupport(uint id, string memory ipfs )onlyAdmin public{
        Pepe.SupportCardStats memory s= pepemon.supportCardStats(id);
        s.ipfsAddr = ipfs;
        pepemon.setSupportCardStats(id, s);
    }
    function setIPFSBattle(uint id, string memory ipfs )onlyAdmin public{
        Pepe.BattleCardStats memory s= pepemon.battleCardStats(id);
        s.ipfsAddr = ipfs;
        pepemon.setBattleCardStats(id, s);
    }
}