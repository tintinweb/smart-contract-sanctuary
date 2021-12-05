pragma solidity ^0.8.3;

import "./ERC721.sol";

contract Titan is ERC721 {

    uint256 public constant maxTotalSupply = 100;
    address public owner;

    bool ownerMintOnly;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        owner = msg.sender;
        ownerMintOnly = true;
    }

    function unlockMintForAll(bool unlock) external {
        require(msg.sender == owner, "You are not the owner of this contract");
        ownerMintOnly = !unlock;
    }

    function mint(address _to, string calldata _uri) external {
        require(totalSupply < maxTotalSupply, "Total Supply Reached");
        if(ownerMintOnly)
             require(msg.sender == owner, "Only Contract Owner Can Mint");

        uint256 claimed = totalSupply;
        tokenURIs[claimed] = _uri;
        addOwnership(_to, claimed);
        emit Transfer(address(0), _to, claimed);
        totalSupply = claimed + 1;
    }
}