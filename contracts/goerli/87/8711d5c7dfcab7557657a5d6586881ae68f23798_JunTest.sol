/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract testERC721 {
    //소유권 변경
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    string public name;
    string public symbol;

    address public minter;
    uint256 public totalSupply = 0;

    //소유권 매핑
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    constructor(string memory name_, string memory symbol_) {
        minter = msg.sender;
        name = name_;
        symbol = symbol_;
    }

    //NFT 보유량 조회
    function balanceOf(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    //NFT 소유자 조회
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    //소유권 이전
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    //
    function mint(address to) public returns (uint256) {
        require(msg.sender == minter);
        uint256 tokenIdToMint = ++totalSupply;
        _mint(to, tokenIdToMint);
        return tokenIdToMint;
    }

    //존재 여부 확인
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    //주소 및 NFT 존재여부 확인
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        //수량 및 소유주 설정
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    //소유권 변경
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner);
    }
}

contract JunTest {
    event CheckCreate(address sender, uint256 tokenId);
    uint256 constant JUN_price = 0.01 ether;

    address payable public owner;
    testERC721 public JUN;

    constructor() {
        owner = payable(msg.sender);
        JUN = new testERC721("jun", "JUN");
    }

    function mint() external payable {
        require(msg.value == JUN_price);
        uint256 tokenId = JUN.mint(msg.sender);
        emit CheckCreate(msg.sender, tokenId);
        owner.transfer(msg.value);
    }
}