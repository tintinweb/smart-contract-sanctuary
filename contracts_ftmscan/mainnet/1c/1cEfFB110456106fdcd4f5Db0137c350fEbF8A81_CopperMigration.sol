/**
 *Submitted for verification at FtmScan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface ICopperBox{
    function balanceOfSummoner(uint) external returns (uint);
    function balanceOfMonster(uint) external returns (uint); 
}

interface IAssetBox {
    function getbalance(uint8 roleIndex, uint tokenID) external view returns (uint);
    function mint(uint8 roleIndex, uint tokenID, uint amount) external;
    function transfer(uint8 roleIndex, uint from, uint to, uint amount) external;
    function burn(uint8 roleIndex, uint tokenID, uint amount) external;
    function getRole(uint8 index) external view returns (address);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
    Migration from old to new copper
    Give double
 */
contract CopperMigration {

    address public immutable oldCopperBox;
    address public immutable newCopperBox;

    mapping(uint8 => mapping (uint => bool)) withdrawaled;

    constructor (address oldCopperBox_, address newCopperBox_) {
        oldCopperBox = oldCopperBox_;
        newCopperBox = newCopperBox_;
    }

    function withdrawal(uint8 roleIndex, uint tokenID) external {
        require(!withdrawaled[roleIndex][tokenID], "Has already been withdrawn");
        address role = IAssetBox(newCopperBox).getRole(roleIndex);
        require(_isApprovedOrOwner(role, msg.sender, tokenID), 'Not approved');
        
        uint amount;
        if (roleIndex == 1) {
            amount = ICopperBox(oldCopperBox).balanceOfSummoner(tokenID);
        }else if(roleIndex == 2) {
            amount = ICopperBox(oldCopperBox).balanceOfMonster(tokenID);
        }else {
            return;
        }
        
        require(amount > 0, "Dont have Copper");
        withdrawaled[roleIndex][tokenID] = true;
        amount = amount / 1e18 * 2;
        IAssetBox(newCopperBox).mint(roleIndex, tokenID, amount);
    }

    function isWithdrawable(uint8 roleIndex, uint tokenID) external view returns(bool){
        return !withdrawaled[roleIndex][tokenID];
    }

    function _isApprovedOrOwner(address role, address operator, uint256 tokenId) private view returns (bool) {
        require(role != address(0), "Query for the zero address");
        address TokenOwner = IERC721(role).ownerOf(tokenId);
        return (operator == TokenOwner || IERC721(role).getApproved(tokenId) == operator || IERC721(role).isApprovedForAll(TokenOwner, operator));
    }
   
}