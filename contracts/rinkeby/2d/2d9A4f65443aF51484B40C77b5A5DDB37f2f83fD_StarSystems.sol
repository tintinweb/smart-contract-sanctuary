// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

contract StarSystems {//is ERC721("Star System", "STARSYS"), Ownable {

    uint public numSystems;
    address public minter;

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter can mint");
        _;
    }

    function ownerOf(uint) external view returns (address) {}

    function setMinter(address _minter) external {}//onlyOwner { minter = _minter; }

    function mint(address _recipient) external onlyMinter returns (uint _sysId) {
        _sysId = ++numSystems;
        // _mint(_recipient, _sysId);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "berlin",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}