/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.5.0;

contract NFTVault {
    mapping(address => mapping(uint256 => bool)) public deposits;
    mapping(address => mapping(uint256 => uint256)) public usedInStrat;
    function useNFT(address user, uint256 id) public {}
    function finishUseNFT(address user, uint256 id) public {}
}

contract Strat {
    NFTVault vault;

    function setNFTVault(address _vault) public {
        vault = NFTVault(_vault);
    }

    function deposit() external {
        require(vault.deposits(msg.sender, 1) == true, "User has not locked NFT");
        vault.useNFT(msg.sender, 1);
    }

    function withdraw() external {
        vault.finishUseNFT(msg.sender, 1);
    }
}