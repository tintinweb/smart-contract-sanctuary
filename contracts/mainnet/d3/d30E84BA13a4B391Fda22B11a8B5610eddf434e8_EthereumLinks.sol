/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EthereumLinks {
    event Link(address indexed from, uint256 index, uint32 indexed provider, uint16 protocol, uint16 flags, uint128 indexed id);
    event Unlink(address indexed from);
    address payable private _owner;
    uint256 private _fee;

    struct Resource {
        uint64 timestamp;
        uint32 provider;
        uint16 protocol;
        uint16 flags;
        uint128 id;
    } 

    mapping(address => Resource[]) private _links;
    mapping(address => mapping(uint256 => string)) private _txt;

    constructor(uint256 fee_) {
        _owner = payable(msg.sender);
        _fee = fee_;
    }

    function fee() public view virtual returns (uint256) {
        return _fee;
    }

    function lengthOf(address address_) public view virtual returns (uint256) {
        require(address_ != address(0), "EthereumLink: address not found");
        return _links[address_].length;
    }

    function linkOf(address address_, uint256 index_) public view virtual returns (Resource memory) {
        require(lengthOf(address_) > 0, "EthereumLink: address not found");
        require(lengthOf(address_) > index_, "EthereumLink: index not found");
        return _links[address_][index_];
    }

    function txtOf(address address_, uint256 index_) public view virtual returns (string memory) {
        require(lengthOf(address_) > 0, "EthereumLink: address not found");
        require(lengthOf(address_) > index_, "EthereumLink: index not found");
        return _txt[address_][index_];
    }

    function link(uint32 provider, uint16 protocol, uint16 flags, uint128 id, string memory txt_) public payable virtual {
        require(msg.value >= _fee, "EthereumLink: fee too low");
        emit Link(msg.sender, _links[msg.sender].length, provider, protocol, flags, id);
        Resource memory resource = Resource({
            timestamp: uint64(block.timestamp),
            provider: provider,
            protocol: protocol,
            flags: flags,
            id: id
        });
        if (bytes(txt_).length > 0) {
            _txt[msg.sender][_links[msg.sender].length] = txt_;
        }
        _links[msg.sender].push(resource);
    }

    function unlink() public virtual {
        emit Unlink(msg.sender);
        for (uint256 i=0; i < _links[msg.sender].length; i++) {
            delete _txt[msg.sender][i];
        }
        delete _links[msg.sender];
    }

    function witdraw() public virtual {
        _owner.transfer(address(this).balance);
    }

    function reduceFee(uint256 fee_) public virtual {
        require(msg.sender == _owner, "EthereumLink: owner required");
        require(fee_ < _fee, "EthereumLink: new fee must be lower");
        _fee = fee_;
    }

}