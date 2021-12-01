/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//        ___           ___           ___           ___           ___           ___     
//       /\  \         /\  \         /\  \         /\  \         /\  \         /\__\    
//      /::\  \       /::\  \       /::\  \        \:\  \       /::\  \       /::|  |   
//     /:/\:\  \     /:/\:\  \     /:/\:\  \        \:\  \     /:/\:\  \     /:|:|  |   
//    /::\~\:\  \   /::\~\:\  \   /:/  \:\  \       /::\  \   /:/  \:\  \   /:/|:|  |__ 
//   /:/\:\ \:\__\ /:/\:\ \:\__\ /:/__/ \:\__\     /:/\:\__\ /:/__/ \:\__\ /:/ |:| /\__\
//   \/__\:\/:/  / \/_|::\/:/  / \:\  \ /:/  /    /:/  \/__/ \:\  \ /:/  / \/__|:|/:/  /
//        \::/  /     |:|::/  /   \:\  /:/  /    /:/  /       \:\  /:/  /      |:/:/  / 
//         \/__/      |:|\/__/     \:\/:/  /     \/__/         \:\/:/  /       |::/  /  
//                    |:|  |        \::/  /                     \::/  /        /:/  /   
//                     \|__|         \/__/                       \/__/         \/__/    
//        ___           ___           ___           ___           ___           ___     
//       /\  \         /\  \         /\__\         /\__\         /\  \         /\__\    
//      /::\  \       /::\  \       /::|  |       /::|  |       /::\  \       /::|  |   
//     /:/\:\  \     /:/\:\  \     /:|:|  |      /:|:|  |      /:/\:\  \     /:|:|  |   
//    /:/  \:\  \   /::\~\:\  \   /:/|:|  |__   /:/|:|  |__   /:/  \:\  \   /:/|:|  |__ 
//   /:/__/ \:\__\ /:/\:\ \:\__\ /:/ |:| /\__\ /:/ |:| /\__\ /:/__/ \:\__\ /:/ |:| /\__\
//   \:\  \  \/__/ \/__\:\/:/  / \/__|:|/:/  / \/__|:|/:/  / \:\  \ /:/  / \/__|:|/:/  /
//    \:\  \            \::/  /      |:/:/  /      |:/:/  /   \:\  /:/  /      |:/:/  / 
//     \:\  \           /:/  /       |::/  /       |::/  /     \:\/:/  /       |::/  /  
//      \:\__\         /:/  /        /:/  /        /:/  /       \::/  /        /:/  /   
//       \/__/         \/__/         \/__/         \/__/         \/__/         \/__/    

///////////////////////////////////////////////////////////////////////////////////////////

// Proton Cannon is a simple NFT game where you can 'fire' the cannon at other people's tokens, burning them to receive 90%
// of the mint price as a reward. Unless they fire back, that is!

// mint price: .1 eth
// reward per shot: .09 eth
// max number of shots: as many as you can hit!
// max supply: unlimited. the game never ends!
// anti-bot rate limiting to keep the game fun for everyone

// steps have been taken to gas-optimize the contract. it should be significantly cheaper to mint and 'fire' compared to other
// NFT contracts. tip: minting multiple tokens at once uses a lot less gas per token than minting one at a time.

// Enjoy!

contract ProtonCannon {

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    uint256 public constant tokenPrice = .1 ether;
    string public constant name = 'Proton Cannon';
    string public constant symbol = 'PROC';
    address public constant owner = 0x6192D6074e0D7B4B37739eF1B2CeFB58fb4591D3;
    string private _baseUri;
    uint256 private _tokenCounter;
    mapping(address => uint256) private lastFiredTimestamp;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() {}

    function setBaseURI(string memory newBaseURI) external {
        require(msg.sender == owner);
        _baseUri = newBaseURI;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri, toString(tokenId))) : "";
    }

    function totalSupply() external view returns (uint256) {
        return _tokenCounter - balanceOf(address(0));
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _owners[tokenId];
    }

    function balanceOf(address user) public view returns (uint256) {
        return _balances[user];
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address ownerOfToken, address operator) public view returns (bool) {
        return _operatorApprovals[ownerOfToken][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address ownerOfToken = ownerOf(tokenId);
        return (spender == ownerOfToken || getApproved(tokenId) == spender || isApprovedForAll(ownerOfToken, spender));
    }

    function approve(address to, uint256 tokenId) external {
        address ownerOfToken = ownerOf(tokenId);
        require(msg.sender == ownerOfToken || isApprovedForAll(ownerOfToken, msg.sender));
        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(from == ownerOf(tokenId), 'wrong owner');
        require(block.timestamp - lastFiredTimestamp[from] > 300, '5 minute transfer cooldown after firing');
        require(_isApprovedOrOwner(msg.sender, tokenId), 'not approved nor owner');
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        _approve(address(0), tokenId);
        _owners[tokenId] = to;
        _balances[from] -= 1;
        _balances[to] += 1;
        emit Transfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return true;
    }

    function mint(uint256 count) external payable {
        require(msg.value >= tokenPrice*count);
        address to = msg.sender;

        uint256 startingCount = _tokenCounter;
        uint256 addedCount;

        for (uint256 i = 0; i < count; i++) {

            uint256 tokenId = startingCount + addedCount;
            _owners[tokenId] = to;
            addedCount += 1;
            emit Transfer(address(0), to, tokenId);

        }

        _balances[to] += addedCount;
        _tokenCounter += addedCount;

    }

    // fire the proton cannon
    //
    // input a token id owned by another account as the target
    // burn the target token and receive .09 ether
    //
    // requires 3 charges to fire (you must own 3 tokens)
    // charges are not consumed
    // limit 1 shot per minute per user
    // after firing: 5 minute cooldown before you can transfer tokens
    function fire(uint256 targetToken) external {

        address sender = msg.sender;
        require(balanceOf(sender) >= 3, 'requires 3 charges to fire');

        uint256 timestamp = block.timestamp;
        require(timestamp - lastFiredTimestamp[sender] > 60, 'max 1 shot per minute per user');
        lastFiredTimestamp[sender] = timestamp;

        address target = ownerOf(targetToken);
        require(sender != target, 'cannot fire on oneself');
        require(ownerOf(targetToken) != address(0), 'token does not exist');
        _transfer(target, address(0), targetToken);
        payable(sender).transfer(.09 ether);
    }

    // allows owner withdrawal of excess ether (beyond what can be received from gameplay)
    function withdrawExcess() external {
        uint256 activeTokens = _tokenCounter-balanceOf(address(0));
        uint256 valueInPlay = activeTokens*.09 ether;
        uint256 excessValue = address(this).balance - valueInPlay;
        payable(owner).transfer(excessValue);
    }

    // allows owner to 'fire' on oneself (for easier cleanup after testing)
    // subject to 1 hour cooldown if owner called 'fire'
    // provides no advantage in gameplay
    function ownerSelfBurn(uint256 targetToken) external {
        address sender = msg.sender;
        require(sender == owner);
        require(sender == ownerOf(targetToken));
        require(block.timestamp - lastFiredTimestamp[sender] > 3600, '1 hour transfer cooldown');
        _transfer(sender, address(0), targetToken);
        payable(sender).transfer(.09 ether);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}