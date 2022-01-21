// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721.sol";
import "./persalePausable.sol";
contract FirstNFT is Ownable, Pausable, ERC721, persalePausable {
    string private baseURI;
    uint256 public totalSupply = 10000;
    uint256 private basePrice = 150000000000000000;
    uint256 private persalePrice = 150000000000000000;
    uint256 private maxSupply = 10000;
    uint256 private mintedSupply = 0;
    uint256 private airDropTotal = 0;
    uint256 private reservedTotal = 0;
    uint256 private whiteListTotal = 0;
    bytes32 private whiteListHex;
    mapping(address => bool) private reservedAccounts;
    
    constructor(
        uint256  _totalSupply,
        uint256  _maxSupply,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        totalSupply = _totalSupply;
        maxSupply = _maxSupply;
        pause();
        persalepause();
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function persalepause() public onlyOwner {
        _persalepause();
    }

    function persaleunpause() public onlyOwner {
        _persaleunpause();
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

    function mint(uint256 amount) public payable whenNotPaused {
        require(mintedSupply < maxSupply, "Max supply reached");
        require(mintedSupply + amount <= maxSupply, "Exceeds max supply");
        if (!reservedAccounts[msg.sender]) {
            require(msg.value >= basePrice * amount, "Not enough ETH sent");
        }
        mintInner(amount);
    }

    function mintInner(uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
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
        airDropTotal++;
    }

    function setBasePrice(uint256 price) external onlyOwner {
        basePrice = price;
    }

    function setPersalePrice(uint256 price) external onlyOwner {
        persalePrice = price;
    }

    function setWhiteListHex(address[] memory addr) external onlyOwner {
        whiteListHex = keccak256(abi.encodePacked(addr));
    }

    function persaleMintInner() internal {
        _safeMint(msg.sender, mintedSupply);
        mintedSupply++;
        whiteListTotal++;
    }

    function persaleMint(address[] memory addr) public payable whenNotPersalePaused {
        require(whiteListHex == keccak256(abi.encodePacked(addr)), "Whitelist error");
        bool isInside = false;
        for(uint i = 0; i < addr.length; i ++){
            if(addr[i] == msg.sender){
                isInside = true;
                break;
            }
        }
        require(isInside, "Not on the white list");
        uint count = balanceOf(msg.sender);
        require(count < 1, "Repeat Click");
        require(mintedSupply < maxSupply, "Max supply reached");
        require(mintedSupply + 1 <= maxSupply, "Exceeds max supply");
        require(msg.value >= persalePrice, "Not enough ETH sent");
        persaleMintInner();
    }

    function airDrop(address[] memory addr) external onlyOwner {
        require(mintedSupply < maxSupply, "Max supply reached");
        require(mintedSupply + addr.length <= maxSupply, "Exceeds max supply");
        for (uint256 i = 0; i < addr.length; i++) {
            dropMintInner(addr[i]);
        }
    }

    function addReservedAccounts(address[] memory addr) external onlyOwner {
        for (uint256 i = 0; i < addr.length; i++) {
            reservedAccounts[addr[i]] = true;
        }
    }

    function getTokenList() public view returns(address[] memory, uint[] memory){
        address[] memory addrs;
        uint[] memory tokenList;
        uint count = 0;
        for(uint i = 0 ; i < totalSupply; i ++){
            address owner = getOwnnerOf(i);
            if(owner != address(0)){
                addrs[count] = owner;
                tokenList[count] = i;
                count ++;
            }
        }
        return (addrs, tokenList);
    }

    function getStatus() public view returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](9);
        arr[0] = paused() ? 0 : 1;
        arr[1] = persalepaused() ? 0 : 1;
        arr[2] = basePrice;
        arr[3] = persalePrice;
        arr[4] = maxSupply;
        arr[5] = mintedSupply;
        arr[6] = reservedTotal;
        arr[7] = airDropTotal;
        arr[8] = whiteListTotal;
        return arr;
    }

    function getAccount(address addr) public view returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](2);
        arr[0] = reservedAccounts[addr] ? 1 : 0;
        arr[1] = balanceOf(addr);
        return arr;
    }
}