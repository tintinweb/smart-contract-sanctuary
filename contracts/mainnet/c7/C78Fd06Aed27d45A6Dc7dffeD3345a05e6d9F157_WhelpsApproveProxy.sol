// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Ownable.sol";

contract WhelpsApproveProxy is Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    
    // Whelps NFT contract
    
    address public _whelpsNFTContract = address(0);

    function setWhelpsNFTContract(address _contract) external onlyOwner {
        require(_whelpsNFTContract == address(0));
        _whelpsNFTContract = _contract;
    }
    
    // Approved contracts
    
    uint256 public noContractsApproved;
    address[] public contractsApprovedByOwner;
    
    function addApprovedContract(address _contract) external onlyOwner {
      contractsApprovedByOwner.push(_contract);
      noContractsApproved++;
    }
    
    function removeApprovedContract(uint256 index) external onlyOwner {
      uint256 len = contractsApprovedByOwner.length;
      require(index < len);
      
      contractsApprovedByOwner[index] = contractsApprovedByOwner[len-1];
      delete contractsApprovedByOwner[len-1];
      noContractsApproved--;
    }
    
    // Transfer whelps
    
    function proxyTransferFrom(address from, address to, uint256 tokenId, uint256 approvedIndex) external {
      require(msg.sender == contractsApprovedByOwner[approvedIndex], "Unauthorized");
      ERC721 whelpsNFT = ERC721(_whelpsNFTContract);
      whelpsNFT.transferFrom(from, to, tokenId);
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}