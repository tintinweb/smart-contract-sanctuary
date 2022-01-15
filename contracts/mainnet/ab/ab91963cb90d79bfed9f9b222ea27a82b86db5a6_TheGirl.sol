// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";

contract TheGirl is ERC721Enumerable, Ownable {

    using Strings for uint256;

    using SafeMath for uint256;

    uint256 public constant _MAX_SUPPLY = 10000;

    string public _base_uri = "";

    uint256 public _base_price = 80000000000000000;

    uint256 public _fomo_index = 0;

    uint256 public _fomo_date = 28800;

    uint256 public _fomo_lastdate = 0;

    address public _fomo_lastaddr;

    uint256 public _fomo_reward;

    uint256 public _fomo_rate = 70;

    uint256 public _startTime = 0;//1642600800;

    constructor() ERC721("The Girl Game", "THEGIRL") {
      
    }

    function currentPrice() public view returns (uint256) {
        return _base_price * ((_fomo_index*1000000/500) + 1000000)/1000000;
    }

    function fomoCheck() public {
        if(_fomo_lastdate!=0){
            if(block.timestamp - _fomo_lastdate > _fomo_date){
                if(_fomo_reward>0){
                    uint256 amount = _fomo_reward;
                    if(totalSupply()!=_MAX_SUPPLY){
                        amount = _fomo_reward.mul(80).div(100);
                    }
                    _fomo_reward -= amount;
                    payable(_fomo_lastaddr).transfer(amount);
                }
                _fomo_index = 0;
                _fomo_lastdate = 0;
                _fomo_lastaddr = address(0x0);
            }
        }
    }
    
    function mint() public payable returns (uint256) {
        require(block.timestamp >= _startTime,"not start");
        require(msg.value >= currentPrice(), "Eth value sent is not sufficient");
        require(totalSupply() + 1 <= _MAX_SUPPLY, "Purchase would exceed max supply of tokens");
        fomoCheck();
        uint tokenId = totalSupply() + 1;
        _safeMint(msg.sender, tokenId);
        _fomo_index += 1;
        _fomo_lastdate = block.timestamp;
        _fomo_lastaddr = msg.sender;
        _fomo_reward += msg.value.mul(_fomo_rate).div(100);
        return tokenId;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount<=address(this).balance-_fomo_reward);
        payable(msg.sender).transfer(amount);
    }

    function setFomoRate(uint256 rate) external onlyOwner {
        _fomo_rate=rate;
    }

    function setFomoDate(uint256 date) external onlyOwner {
        _fomo_date = date;
    }

    function setStartDate(uint256 date) external onlyOwner {
        _startTime = date;
    }
    
    function getInfo() public view  returns (uint256,uint256,uint256,uint256,uint256,address,uint256) {
        uint256 time = _startTime>block.timestamp?_startTime-block.timestamp:0;
        uint256 last = block.timestamp-_fomo_lastdate>_fomo_date?0:_fomo_date-(block.timestamp-_fomo_lastdate);
        return (time,_MAX_SUPPLY,totalSupply(),currentPrice(),_fomo_reward,_fomo_lastaddr,last);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _base_uri;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _base_uri = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory base = _baseURI();
        if(bytes(base).length==0){
            return string("https://thegirl.games/nft/0.json");
        }
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory url  = string(abi.encodePacked(base, tokenId.toString()));
        return string(abi.encodePacked(url,".json"));
    }
}