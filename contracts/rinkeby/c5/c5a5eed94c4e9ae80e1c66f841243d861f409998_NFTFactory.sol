// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Contracts
import "./MerkleProof.sol";
import "./Factory.sol";
import "./NiftyNFT.sol";
import "./DynamicUpgradeable.sol";

// Interfaces

/*****************************************************************************************************/
/**                                             WARNING                                             **/
/**                        THIS CONTRACT IS AN UPGRADEABLE STORAGE CONTRACT!                        **/
/**  ---------------------------------------------------------------------------------------------  **/
/**  Do NOT change the order of or PREPEND any storage variables to this or new versions            **/
/**  of this contract as this will cause a ripple affect to the storage slots of all child          **/
/**  contracts that inherit from this contract to be overwritten on the deployed proxy contract!!   **/
/**                                                                                                 **/
/**  Visit https://docs.openzeppelin.com/upgrades/2.6/proxies#upgrading-via-the-proxy-pattern for   **/
/**  more information.                                                                              **/
/*****************************************************************************************************/
/**
 * @notice
 *
 */
contract NFTFactory is DynamicUpgradeable {
    NiftyNFT public nft;

    bytes32[] public tierMerkleRoots;

    uint256 public startBlockTimestamp;
    
    uint256 public endBlockTimestamp;
    
    uint256 public saleAmountInWei;
    
    address payable paymentSplitter;

    mapping(uint256 => mapping(uint256 => uint256)) public claimedBitMap;

    event Claimed( address account, uint256 amount);

    event TierAdded(uint256 index);
    
    event ShowTimestamp(uint256 timestamp);

    function getTierMerkleRoots() external view returns (bytes32[] memory) {
        return tierMerkleRoots;
    }

    function claim(
        uint256 tierIndex,
        address account,
        uint256 amount
    ) external payable {
        uint256 weiAmount = msg.value;
        
        require(block.timestamp  >= startBlockTimestamp && block.timestamp  < endBlockTimestamp, "NFT Sale Not Open");
        require(weiAmount == saleAmountInWei, "NFT Purchase Amount Incorrect");
        require(amount == 1);
        
        // transfer eth to payment spliter
        paymentSplitter.transfer(saleAmountInWei);
        
        // Loop through hashes
        for (uint256 i; i < amount; i++) {
            nft.mint(tierIndex, account);
        }

        emit Claimed(account, amount);
    }

    function _setClaimed(uint256 tierIndex, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[tierIndex][claimedWordIndex] =
            claimedBitMap[tierIndex][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function isClaimed(uint256 tierIndex, uint256 index)
        public
        view
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[tierIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function addTier(bytes32 merkleRoot) external {
        tierMerkleRoots.push(merkleRoot);

        emit TierAdded(tierMerkleRoots.length - 1);
    }

    function initialize(address nftAddress, uint256 start, uint256 end, address payable payment, uint256 weiAmount) external {
        nft = NiftyNFT(nftAddress);
        startBlockTimestamp = start;
        endBlockTimestamp = end;
        paymentSplitter = payment;
        saleAmountInWei = weiAmount;
    }
}