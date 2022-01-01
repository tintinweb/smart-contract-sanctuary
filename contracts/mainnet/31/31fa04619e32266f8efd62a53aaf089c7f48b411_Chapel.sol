// SPDX-License-Identifier: MIT

// @title The Underground Sistine Chapel by Pascal Boyart
// @author jolan.eth
pragma solidity ^0.8;

import "./IChapel.sol";
import "./Ownable.sol";

contract Chapel is Ownable {
    string public CID;
    string public ContractCID;
    string public symbol = "CHAPEL";
    string public name = "The Underground Sistine Chapel";
    address public ADDRESS_SIGN = 0x1Af70e564847bE46e4bA286c0b0066Da8372F902;

    uint256 public maxSupply = 404;
    uint256 public totalSupply = 1;

    mapping (uint256 => address) owners;
    mapping(address => uint256) balances;
    
    mapping(uint256 => address) approvals;
    mapping(address => mapping(address => bool)) operatorApprovals;

    mapping(uint256 => address) public snapshot;

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {}

    function setSnapshot(address[] memory batch)
    public onlyOwner {
        uint256 i = 0;
        uint256 len = batch.length;
        while (i < len)
            snapshot[i] = batch[i++];
    }

    function batchMintChapel()
    public onlyOwner {
        while (totalSupply <= maxSupply)
            _mint(snapshot[totalSupply], totalSupply++);
    }

    function setCID(string memory _CID) 
    public onlyOwner {
        CID = _CID;
    }

    function setContractCID(string memory _CID) 
    public onlyOwner {
        ContractCID = _CID;
    }

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return
            interfaceId == 0x80ac58cd ||
            interfaceId == 0x5b5e139f;
    }

    function balanceOf(address owner)
    public view returns (uint256) {
        require(address(0) != owner, "error address(0)");
        return balances[owner];
    }

    function ownerOf(uint256 id)
    public view returns (address) {
        require(owners[id] != address(0), "error !exist");
        return owners[id];
    }

    function tokenURI(uint256 id)
    public view returns (string memory) {
        require(owners[id] != address(0), "error !exist");
        return string(
            abi.encodePacked(
                "ipfs://", CID, '/', _toString(id)
            )
        );
    }

    function contractURI()
    public view returns (string memory) {
        return string(
            abi.encodePacked(
                "ipfs://", ContractCID
            )
        );
    }

    function approve(address to, uint256 id)
    public {
        address owner = owners[id];
        require(to != owner, "error to");
        require(
            owner == msg.sender ||
            operatorApprovals[owner][msg.sender],
            "error owner"
        );
        approvals[id] = to;
        emit Approval(owner, to, id);
    }

    function getApproved(uint256 id)
    public view returns (address) {
        require(owners[id] != address(0), "error !exist");
        return approvals[id];
    }

    function setApprovalForAll(address operator, bool approved)
    public {
        require(operator != msg.sender, "error operator");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
    public view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 id)
    public {
        require(owners[id] != address(0), "error !exist");
        address owner = owners[id];
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender], 
            "error msg.sender"
        );

        _transfer(owner, from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes memory data)
    public {
        address owner = owners[id];
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender], 
            "error msg.sender"
        );
        _transfer(owner, from, to, id);
        require(_checkOnERC721Received(from, to, id, data), "error ERC721Receiver");
    }

    function _mint(address to, uint256 id)
    private {
        require(to != address(0), "error to");
        require(owners[id] == address(0), "error owners[id]");
        emit Transfer(address(0), ADDRESS_SIGN, id);

        balances[to]++;
        owners[id] = to;
        
        emit Transfer(ADDRESS_SIGN, to, id);
        require(_checkOnERC721Received(address(0), to, id, ""), "error ERC721Receiver");
    }

    function _transfer(address owner, address from, address to, uint256 id)
    private {
        require(owner == from, "errors owners[id]");
        require(address(0) != to, "errors address(0)");

        approve(address(0), id);
        balances[from]--;
        balances[to]++;
        owners[id] = to;
        
        emit Transfer(from, to, id);
    }

    function _checkOnERC721Received(address from, address to, uint256 id, bytes memory _data)
    internal returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(to)
        }

        if (size > 0)
            try IChapel(to).onERC721Received(msg.sender, from, id, _data) returns (bytes4 retval) {
                return retval == IChapel(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) revert("error ERC721Receiver");
                else assembly {
                        revert(add(32, reason), mload(reason))
                    }
            }
        else return true;
    }

    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) return "0";

        uint256 digits;
        uint256 tmp = value;

        while (tmp != 0) {
            digits++;
            tmp /= 10;
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