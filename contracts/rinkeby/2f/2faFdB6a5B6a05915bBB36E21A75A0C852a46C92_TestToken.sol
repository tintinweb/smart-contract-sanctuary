// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;
pragma solidity <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";

/// @custom:security-contact [email protected]
contract TestToken is ERC721, Ownable {

    uint256 constant private _PRICE = .04 ether;
    uint256 constant private _BULK_PRICE = .035 ether;
    uint256 constant private _BULK_THRESHOLD = 4;
    uint256 constant private _MAX_SINGLE_ACTION = 10;
    uint256 constant private _MAX_MINT = 10000;
    uint256 private _issued = 1;
    bool private ACTIVE = true;
    address private _cashout;
    string private baseTokenURI = "";

    constructor() payable ERC721("TestOFLToken", "TST-TKT-OFL") {}

    function safeMint(uint256 numToIssue) external payable {
        require(ACTIVE, "The sale is not currently active.");
        
        require(numToIssue < _MAX_SINGLE_ACTION && numToIssue > 0, "At least 1 mint must be performed per transaction, and at most 10.");

        require(msg.value == _PRICE*numToIssue || (numToIssue > _BULK_THRESHOLD && msg.value == _BULK_PRICE*numToIssue), "Insufficient funds.");

        uint256 toIssue = _issued;
        require(_issued + numToIssue <= _MAX_MINT, "Insufficient tokens remaining.");

        for (uint256 i = 0; i < numToIssue; i+=1) {
            _safeMint(msg.sender, toIssue);
            toIssue = toIssue + 1;
        }
        _issued = toIssue;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    receive () external payable {}
    fallback() external payable {}

    function pause() external onlyOwner {
        ACTIVE = false;
    }

    function unpause() external onlyOwner {
        ACTIVE = true;
    }

    function _baseURI() internal view override virtual returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function getBalance() external view onlyOwner returns(uint256) {
        return address(this).balance;
    }

    function setCashout(address addr) external onlyOwner returns(address) {
        _cashout = addr;
        return addr;
    }

    function cashout() external onlyOwner {
        payable(_cashout).transfer(address(this).balance);
    }

}