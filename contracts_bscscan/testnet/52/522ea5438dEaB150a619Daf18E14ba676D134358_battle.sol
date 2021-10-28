/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

pragma solidity ^0.8.0;

interface hero{
  function getHeroData(uint256 tokenId) external view returns (uint256[] memory);
  function ownerOf(uint256 tokenId) external view returns (address owner);
}
interface equipment{
  function getEquipmentData(uint256 tokenId) external returns (uint256[] memory);
  function battleClaim(address userAddress) external;
  
}
interface token{
  function mint(address account, uint256 amount) external;
}

contract battle{

    mapping(address => uint256[]) public teamData;
    hero heroContract;
    equipment equipmentContract;
    token tokenContract;

    address public heroAddress;
    address public equipmentAddress;
    address public tokenAddress;

    constructor(address hero_address,address equipment_address,address tokena_ddress) public {
        heroAddress = hero_address;
        equipmentAddress = equipment_address;
        tokenAddress = tokena_ddress;
        heroContract = hero(heroAddress);
        equipmentContract = equipment(equipmentAddress);
        tokenContract = token(tokenAddress);
    }


    function scene(uint256[] memory token) public returns(bool){
        require(token.length == 3, "Token Insufficient");
        equipmentContract.battleClaim(msg.sender);
        tokenContract.mint(msg.sender,1000*1e18);
        return true;
    }

    function score(uint256 tokenId) public view returns(uint256){
        uint256[] memory heroInfo = heroContract.getHeroData(tokenId);
        return heroInfo[1];
        // uint256[] memory equipmentInfo = equipmentContract.getEquipmentData(tokenId);
    }

    function team(uint256[] memory token) public returns(bool){
        require(token.length == 3, "Token Insufficient");
        for (uint256 i = 0; i < token.length; i++) {
            require(heroContract.ownerOf(token[i]) == msg.sender, "Token Invalid");
        }
        teamData[msg.sender] = token;
        return true;
    }
}