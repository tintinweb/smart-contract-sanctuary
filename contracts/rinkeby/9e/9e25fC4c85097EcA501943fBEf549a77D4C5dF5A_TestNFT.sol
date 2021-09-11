// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Ownable.sol";

contract TestNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    
    bool public mintingEnabled = true;
    uint256 public constant MAX_BUY_COUNT = 15;
    uint256 public constant NFT_PRICE = 0.001 ether;
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor()
        ERC721("TESTNFT", "TESTNFT")
    {}
    
    function enableMinting() external onlyOwner {
      mintingEnabled = true;
    }
    
    function disableMinting() external onlyOwner {
      mintingEnabled = false;
    }

    function mintInternal(address minter, uint256 count) private {
      require(minter != address(0), "Minter address error");
      require(count > 0, "Count can't be 0");
      
      for (uint256 i = 0; i < count; i++) {
        _mint(minter, totalSupply());
      }
    }
    
    function buyCount(uint256 count) external payable {
      require(mintingEnabled, "Not enabled yet");
      require(count <= MAX_BUY_COUNT, "Count too big");
      require(msg.value == count.mul(NFT_PRICE), "Ether value sent is not correct");
      
      mintInternal(msg.sender, count);
    }
    
    function buy1() external payable {
      require(mintingEnabled, "Not enabled yet");
      require(msg.value == uint256(1).mul(NFT_PRICE), "Ether value sent is not correct");
      
      mintInternal(msg.sender, 1);
    }
    
    function buy5() external payable {
      require(mintingEnabled, "Not enabled yet");
      require(msg.value == uint256(5).mul(NFT_PRICE), "Ether value sent is not correct");
      
      mintInternal(msg.sender, 1);
    }
    
    function claimFree() external {
      require(mintingEnabled, "Not enabled yet");
      
      mintInternal(msg.sender, 1);
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}