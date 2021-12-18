// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
                                                                             
///////////////////////////////////////////////////////////////////////////                                                                            
///////////////////////////////////////////////////////////////////////////                                                                            
//                                                                      ///   
//                        &&&&&&&&&&&&&&&&&&                            ///    
//                   ,&&&&&&&&&&&&&&&&&&&&&&&&&#                        ///    
//                 &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                      ///    
//               &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(                    ///    
//             &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                   ///    
//            &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&/                  ///    
//           %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                  ///    
//           &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                  ///    
//           &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                  ///    
//           *&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                   ///    
//            &&&&&&&&&&&&&&&,,,&&&&&&&&&&&&&&&&&&&&&#&                 ///    
//              &&& &&&&&&&&&,,,,,&&&&&&&&&,,&&&&&&,,&                  ///    
//                &&&&&&//&&&#&&@,,&&&&&&&,,,,,,,,,&                    ///    
//                  &&&&&&&&&&,,,&,,,,,,,,,,,,,,,,,,,&&&&&              ///    
//                     &&&&&&&&&,,,&,,,,,,,,,,,,&,,,,,,,/&&/&           ///    
//                          &&&&&&&,,,&&,,,,,,,,,,&&,,&&&&&%            ///    
//                            && #&&&&&&,,,,,,,,@&                      ///    
//                             &&&&&&/                                  ///    
//                             &&&&&&&                                  ///    
//                         *&&&&&&&&&&&&                                ///    
//                       &&&&&&&&&&&&&&&&&                              ///    
//                    &&&&&&&&&&&&&&&&&&&&&&                            ///    
//                 &&&&&&&&&&&,&&&&&&&&&&&&&&&                          ///    
//                &&&&&&&&#   /&&&&&&&&&&&&&&&&                         ///    
//               &&&&&&,/      &&&&&&&&&&&&&&&&&                        ///    
//                &&&&&&&*      &&&&&&&&&&&&&&&&&                       ///    
//                 *&&&&&&&&   %&&&&&&&&&&&&&&&&&*                      ///    
//                    &&&&&&&&#&&&&&&&&&&&&&&&&&&&                      ///    
//                                                                      ///
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

contract DuckBoyz is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string public baseURI;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 5;
    uint256 private _presaleAt;
    uint256 private _launchAt;
    bool public paused = false;

    uint256 public PRESALE_PRICE = 50000000000000000; // 0.05 ether
    uint256 public LAUNCH_PRICE = 60000000000000000; // 0.06 ether

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        uint256 presaleAt_,
        uint256 launchAt_
    ) ERC721(_name, _symbol) {
        _presaleAt = presaleAt_;
        _launchAt = launchAt_;

        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function launchAt() external view returns (uint256) {
        return _launchAt;
    }

    function presaleAt() external view returns (uint256) {
        return _presaleAt;
    }

    function isPresale() public view returns (bool) {
        return block.timestamp >= _presaleAt && block.timestamp < _launchAt;
    }

    function isLaunched() public view returns (bool) {
        return block.timestamp >= _launchAt;
    }

    function calculatePrice() public view returns (uint256) {
        uint256 tokenPrice = LAUNCH_PRICE;

        if (isPresale()) {
            tokenPrice = PRESALE_PRICE;
        }

        return tokenPrice;
    }

    function presaleMint(address _to, uint256 _mintAmount) public payable {
        require(!paused, "Sale hasn't started");
        require(block.timestamp >= _presaleAt, "presale has not begun");
        require(block.timestamp < _launchAt, "presale has ended");
        mint(_to, _mintAmount);
    }

    function launchMint(address _to, uint256 _mintAmount) public payable {
        require(!paused, "Sale hasn't started");
        require(block.timestamp >= _launchAt, "Launch has not begun");
        mint(_to, _mintAmount);
    }

    function mint(address _to, uint256 _mintAmount) internal {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "You can get no fewer than 1");
        require(supply + _mintAmount <= maxSupply, "Sold out");

        if (msg.sender != owner()) {
            require(_mintAmount <= maxMintAmount, "You cannot get more than 5 at a time");
            require(msg.value >= SafeMath.mul(calculatePrice(), _mintAmount), "Amount of Ether sent is not correct");
        }
        
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setLaunchAt(uint256 value) public onlyOwner {
        _launchAt = value;
    }

    function setPresaleAt(uint256 value) public onlyOwner {
        _presaleAt = value;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}