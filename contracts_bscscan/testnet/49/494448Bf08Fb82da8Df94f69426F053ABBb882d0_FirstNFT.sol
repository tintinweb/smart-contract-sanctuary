// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721.sol";

contract FirstNFT is Ownable, Pausable, ERC721 {
    string private baseURI;
    uint256 public totalSupply = 10000;
    uint256 private basePrice = 150000000000000000;
    uint256 private maxSupply = 10000;
    uint256 private mintedSupply = 0;
    uint256 private airDropTotal = 0;
    uint256 private reservedTotal = 0;
    mapping(address => bool) private reservedAccounts;
    constructor( uint256 _totalSupply, uint256 _maxSupply, string memory name, string memory symbol) ERC721(name, symbol) {
        totalSupply = _totalSupply;
        maxSupply = _maxSupply;
        pause();
    }
     function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }
    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }

    function mint(uint amount) public payable whenNotPaused {
        require(mintedSupply < maxSupply, "Max supply reached");
        require(mintedSupply + amount <= maxSupply, "Exceeds max supply");
        if(!reservedAccounts[msg.sender]){
            require(msg.value >= basePrice * amount, "Not enough ETH sent");
        }
        mintInner(amount);
    }

    function mintInner(uint amount) internal {
        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintedSupply);
            mintedSupply++;
            if (reservedAccounts[msg.sender]) {
                reservedTotal++;
            }
        }
    }
    function dropMintInner(address addr) internal {
        _safeMint(addr, mintedSupply);
        mintedSupply++;
    }
    function setBasePrice(uint price) external onlyOwner {
        basePrice = price;
    }

    function setReserved(uint256 n) external onlyOwner {
        reservedTotal = n;
    }

    function airDrop(address[] memory addr) external onlyOwner{
        require(mintedSupply < maxSupply, "Max supply reached");
        require(mintedSupply + addr.length <= maxSupply, "Exceeds max supply");
        for (uint i = 0; i < addr.length; i++) {
            dropMintInner(addr[i]);
        }
    }

    function addReservedAccounts(address[] memory addr) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            reservedAccounts[addr[i]] = true;
        }
    }

    function getStatus() public view returns (uint[] memory) {
        uint[] memory arr = new uint[](6);
        arr[0] = paused() ? 0 : 1;
        arr[1] = basePrice;
        arr[2] = maxSupply;
        arr[3] = mintedSupply;
        arr[4] = reservedTotal;
        arr[5] = airDropTotal;
        return arr;
    }

    function getAccount(address addr) public view returns (uint[] memory) {
        uint[] memory arr = new uint[](2);
        arr[0] = reservedAccounts[addr] ? 1 : 0;
        arr[1] = balanceOf(addr);
        return arr;
    }
}