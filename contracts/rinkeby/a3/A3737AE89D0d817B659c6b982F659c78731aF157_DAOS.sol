// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract DAOS is ERC20, Ownable, ReentrancyGuard {
    address public farmingContract;
    using SafeMath for uint256;

    uint256 private constant initialMint = 25694276 * 10**18; //25.69m tokens minted when deployed
    uint256 private constant numTokensToMigrateV1 = 1074592 * 10**18; //1.07m tokens to be migrated from v1
    uint256 private constant numTokensToMigrateV2 = 59631132 * 10**18; //59.63m tokens to be migrated from v2

    uint256 private migratedV1;
    uint256 private migratedV2;

    //uint256 private deployedAt;

    IERC20 public oldNFTLV1 = IERC20(0x2f7b4C618Dc8E0bBA648E54cDADce3D8361f9816);
    IERC20 public oldNFTLV2 = IERC20(0xE5904E9816b309d3eD4d061c922f5aa8f3B24C92);

    event SetFarmingContract(address indexed farmingContractAddress, address indexed _owner);

    constructor() ERC20("DAOS", "DAOS") {
        _mint(_msgSender(), initialMint);
      //  deployedAt = block.timestamp;
    }

    function mint(address _to, uint256 _amt) external {
        require(farmingContract == msg.sender, "You are not authorised to mint");
        require(totalSupply().add(_amt) <= 86400000 * (10**18) , "Unable to mint more"); // total supply = 86.4m
        _mint(_to, _amt);
    }

    function setFarmingContract(address _farmingContractAddress) external onlyOwner {
        require(_farmingContractAddress != address(0), "New Farming Contract can't be the zero address");
        require(farmingContract == address(0), "Farming Contract Already Added");
        farmingContract = _farmingContractAddress;
        emit SetFarmingContract(_farmingContractAddress, _msgSender());
    }

    // migrate from v1 to v3
    function migrateV1() external nonReentrant {
        uint256 oldBalanceV1 = oldNFTLV1.balanceOf(_msgSender());
        require(oldBalanceV1 > 0 , "Not eligible to migrate from V1");

        require(migratedV1.add(oldBalanceV1) <= numTokensToMigrateV1, "V1: Cant migrate more than allocated");
        require(oldNFTLV1.transferFrom(_msgSender(), 0x000000000000000000000000000000000000dEaD, oldBalanceV1), "ERC20: transfer failed");
        
        _mint(_msgSender(), oldBalanceV1);
        migratedV1 = migratedV1.add(oldBalanceV1);
    }

    // migrate from v2 to v3
    function migrateV2() external nonReentrant {
        uint256 oldBalanceV2 = oldNFTLV2.balanceOf(_msgSender());
        require(oldBalanceV2 > 0 , "Not eligible to migrate from V2");

        require(migratedV2.add(oldBalanceV2) <= numTokensToMigrateV2, "V2: Cant migrate more than allocated");
        require(oldNFTLV2.transferFrom(_msgSender(), 0x000000000000000000000000000000000000dEaD, oldBalanceV2), "ERC20 Transfer failer");
        
        _mint(_msgSender(), oldBalanceV2);
        migratedV2 = migratedV2.add(oldBalanceV2);

    }

    // in case of wrong address by mistake
    function changeV1Address(address _address) external onlyOwner {
        require(oldNFTLV1 != IERC20(_address), "Address is the same");
        oldNFTLV1 = IERC20(_address);
    }

    function changeV2Address(address _address) external onlyOwner {
        require(oldNFTLV2 != IERC20(_address), "Address is the same");
        oldNFTLV2 = IERC20(_address);
    }
}