// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SaveThePandas is ERC721Enumerable, Ownable {
    uint public constant MAX_PANDAS = 1900;
    string _baseTokenURI;

    uint256 presaleDate = 1639448100; //9:15 P.M. EST 13 Dec
    uint256 saleDate = 1639534500; // 9:15 P.M. EST 14 Dec

    address walletFees1 = 0xD635f3292b03dEdCd909162A17E2919d69449CD8;
    address walletFees2 = 0x8Ace8db7A64CAfe915B1dCA304De8426AC16B0E4;

    IERC20 WETH = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    mapping(address=>bool) public whitelisted;

    constructor() ERC721("SaveThePandas", "PANDAS")  {
        _setBaseURI('https://savethepandas.io/api/metadata/');
        
        for(uint i = 0; i < 50; i++){
            _safeMint(_msgSender(), totalSupply());
        }
    }

    function mintMyPanda(address _to, uint _count) public payable {
        require(block.timestamp > presaleDate, "Sale not started");

        if (block.timestamp < saleDate) {
            require(whitelisted[msg.sender], "Not whitelisted");
        }

        require(totalSupply() + _count <= MAX_PANDAS, "Max limit");
        require(_count <= 20, "Exceeds 20");
        require(WETH.transferFrom(msg.sender, address(this), price(_count)), 'Could not transfer WETH');

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }

    function price(uint _count) public view returns (uint256) {
        if (block.timestamp > saleDate) {
            return 60000000000000000 * _count; // 0.06 ETH
        }
        return 45000000000000000 * _count; // 0.045 ETH
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function _setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function _setWhitelisted(address[] memory _addresses, bool _status) public onlyOwner {
        for(uint i = 0; i < _addresses.length; i++){
            whitelisted[_addresses[i]] = _status;
        }
    }
    
    function _withdrawFees() public {
        uint256 totalMatic = address(this).balance;
        uint256 partialMatic =  totalMatic / 4;
        require(payable(walletFees1).send(totalMatic - partialMatic));
        require(payable(walletFees2).send(partialMatic));

        uint256 totalWETH = WETH.balanceOf(address(this));
        uint256 partialWETH =  totalWETH / 4;
        require(WETH.transfer(walletFees1, totalWETH - partialWETH), 'Could not transfer tokens');
        require(WETH.transfer(walletFees2, partialWETH), 'Could not transfer tokens');
    }
}