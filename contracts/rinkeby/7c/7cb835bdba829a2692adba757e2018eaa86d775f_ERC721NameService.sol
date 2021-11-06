pragma solidity 0.8.3;

import "./ERC721Map.sol";

contract ERC721NameService is ERC721Map {

    // Fee in wei 
    uint256 public fee;

    constructor() public {
        fee = 0;
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    /**
    * Sends all the contract's balance to specified address. 
    */
    function withdrawFunds(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

    function setTokenName(address _address, uint256 _tokenId, string memory _nftName) public payable {
        require(msg.value >= fee);
        _setTokenName(_address, _tokenId, _nftName);
    }

}