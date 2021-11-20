/**
 *Submitted for verification at FtmScan.com on 2021-11-19
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-25
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-25
*/

pragma solidity ^0.8.7;

interface IRarity {
    function adventure(uint _summoner) external;
    function level_up(uint _summoner) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
}

/**
 * @title AdventureTime
 * @dev sends multiple summoners on an adventure
 */
contract AdventureTime {
    IRarity rarity = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

    // you'll be able to send summoners that you (the caller) don't own on an
    // adventure, as long as it's approved for this contract
    function adventureTime(uint256[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            rarity.adventure(_ids[i]);
        }
        // that's literally it
    }
    
    function level_up(uint256[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            rarity.level_up(_ids[i]);
        }
    }
    
    function trans_summor(uint256 _id,address _to) external {
        rarity.safeTransferFrom(msg.sender,_to,_id);
        address _owner = rarity.ownerOf(_id);
        require(msg.sender == _owner,'not owner');
    }
}