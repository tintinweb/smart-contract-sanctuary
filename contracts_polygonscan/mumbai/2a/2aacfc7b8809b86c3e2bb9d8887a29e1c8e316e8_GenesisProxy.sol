/**
 *Submitted for verification at polygonscan.com on 2022-01-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
/**
 * @dev Interface to interact with the Genesis Fives DNA collection. 
 */
interface IGenesisDNA{
    /**
    * @param tokenId Token ID to retrieve a Point Guard for.
    * @return A Point Guard
    */
    function getPG(uint256 tokenId) external view returns (string memory);
    
    /**
    * @param tokenId Token ID to retrieve a Shooting Guard for.
    * @return A Shooting Guard
    */
    function getSG(uint256 tokenId) external view returns (string memory);
    
    /**
    * @param tokenId Token ID to retrieve a Small Forward for.
    * @return A Small Forward
    */
    function getSF(uint256 tokenId) external view returns (string memory);
    
    /**
    * @param tokenId Token ID to retrieve a Power Forward for.
    * @return A Power Forward
    */
    function getPF(uint256 tokenId) external view returns (string memory);

    /**
    * @param tokenId Token ID to retrieve a Center for.
    * @return A Center
    */
    function getC(uint256 tokenId) external view returns (string memory);    
}

/**
 * @dev Holds Genesis DNA data
 */
struct GenesisDNA{
    string pointGuard;
    string shootingGuard;
    string smallForward;
    string powerForward;
    string center;
    uint rarity;
}


/**
 * @dev Proxy contract to act as a cleaning layer between the original Fives NFT and the Fives Baller contract.
 */
contract GenesisProxy{

    mapping(bytes32 => bool) rare_players;
    address internal _admin;
    IGenesisDNA public FIVES_SC;

    /**
    * @dev Pushes a hash map of rare players
    * @param players Rare players that increment the total number of rares on a Fives card
    */
    function push_rare_players(string[] memory players) public onlyAdmin{
        for(uint i = 0; i < players.length; i++){
            rare_players[keccak256(bytes(players[i]))] = true;
        }
    }
    /**
    * @dev Helper function to return the rarity of a Genesis DNA object
    * @param pG Point Guard
    * @param sG Shooting Guard
    * @param sF Small Forward
    * @param pF Power Forward
    * @param c Center
    */
    function _build_dna_rarity(string memory pG, string memory sG, string memory sF, string memory pF, string memory c) internal view returns(GenesisDNA memory){
        uint rarity = 0;
        if(rare_players[keccak256(bytes(pG))]){rarity++;}
        if(rare_players[keccak256(bytes(sG))]){rarity++;}
        if(rare_players[keccak256(bytes(sF))]){rarity++;}
        if(rare_players[keccak256(bytes(pF))]){rarity++;}
        if(rare_players[keccak256(bytes(c))]){rarity++;}
        return GenesisDNA(
            pG,
            sG,
            sF,
            pF,
            c,
            rarity
        );
    }

    /**
    * @dev Builds a GenesisDNA object with data from the original Fives smart contract
    * @param tokenId NFT from the Fives smart contract
    */
    function get_dna(uint tokenId) public view returns(GenesisDNA memory){
        return _build_dna_rarity(
                    FIVES_SC.getPG(tokenId),
                    FIVES_SC.getSG(tokenId),
                    FIVES_SC.getSF(tokenId),
                    FIVES_SC.getPF(tokenId),
                    FIVES_SC.getC(tokenId)
            );
    }   
    

    modifier onlyAdmin(){
        require(_admin == msg.sender);
        _;
    }
    constructor(){
        _admin = msg.sender;
        FIVES_SC = IGenesisDNA(0x417A8ec62eAd84329f5334267216D4BF937B433A);
    }
}