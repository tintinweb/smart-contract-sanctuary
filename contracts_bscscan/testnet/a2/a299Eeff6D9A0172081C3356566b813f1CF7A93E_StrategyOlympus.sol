// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC721 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function transferFrom(address from, address to, uint tokenId) external;
    function approve(address to, uint tokenId) external;
    function getApproved(uint tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;
}

interface IEpicHeroNFT is IERC721{
    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);
    function getHero(uint tokenId) external view returns (uint8 level, uint8 rarity);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Auth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

contract StrategyOlympus is Auth {
    using SafeMath for uint256;

    IEpicHeroNFT nftContract;
    IEpicHeroNFT nftContract2;

    mapping(uint256 => uint256) public tierWeight;
    mapping(uint256 => uint256) public levelWeight;

    constructor(address _nftAddress) Auth(msg.sender) {
        nftContract = IEpicHeroNFT(_nftAddress);

        setTierWeight(0, 0);
        setTierWeight(1, 1);
        setTierWeight(2, 2);
        setTierWeight(3, 3);
        setTierWeight(4, 4);
        setTierWeight(5, 6);
        setTierWeight(6, 12);
        setTierWeight(7, 24);

        setLevelWeight(0, 0);
        setLevelWeight(1, 1000);
        setLevelWeight(2, 1500);
        setLevelWeight(3, 2500);
        setLevelWeight(4, 5500);
        setLevelWeight(5, 15000);
        setLevelWeight(6, 26500);
        setLevelWeight(7, 39000);
        setLevelWeight(8, 52000);
        setLevelWeight(9, 65000);
        setLevelWeight(10, 78000);
        setLevelWeight(11, 91000);
        setLevelWeight(12, 104000);
        setLevelWeight(13, 117000);
    }

    function calculateShares(address, uint256[] memory _tokenIds) external view returns (uint256){
        uint256 shares = 0;
        for(uint i = 0; i < _tokenIds.length; i++) {
            (uint256 level, uint256 tier) = nftContract.getHero(_tokenIds[i]);
            uint256 total = levelWeight[level].mul(tierWeight[tier]);
            shares = shares.add(total);
        }

        return shares;
    }

    function setTierWeight(uint256 tier, uint256 weight) public onlyOwner{
        tierWeight[ tier ] = weight;
    }

    function setLevelWeight(uint256 level, uint256 weight) public onlyOwner{
        levelWeight[ level ] = weight;
    }
}