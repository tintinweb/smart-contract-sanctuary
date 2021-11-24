// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract ThreePunks is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string public _baseTokenURI;
    uint256 private _reserved = 333;
    uint256 private _supply = 10001;
    uint256 private _price = 0.033 ether;
    bool public _paused = false;
    bool public _onlyWhitelist = true;

    address[] public whitelistAddresses;
    address[] public whitelistNineAddresses;

    // withdraw address
    address team = 0x802DA0f8c89786E0820962AE38F111BE79666387;

    // 11111 in total
    constructor(string memory baseURI) ERC721("3x3Punks", "THREE")  {
        setBaseURI(baseURI);
        _safeMint( team, 0);
    }

    function mint3x3(uint256 num) public payable {
        require( !_paused,                              "Sale paused" );
        uint256 supply = totalSupply();
        require( num < 10,                               "Maximum of 9 3x3Punks per mint" );
        require( supply + num < _supply - _reserved,    "Exceeds maximum 3x3Punks supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        if(_onlyWhitelist==true){
            require(iswhitelist(msg.sender),            "Not whitelist");
            uint256 ownerTokenCount = balanceOf(msg.sender);
            if(!iswhitelistnine(msg.sender)){
                require( num < 4,                               "Maximum of 3 3x3Punks per mint" );
                require(ownerTokenCount + num < 4,  "Maximum of 3 3x3Punks per address");
            }
            require(ownerTokenCount + num < 10,  "Maximum of 9 3x3Punks per address");
        }

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function iswhitelist(address _user) public view returns (bool){
        for(uint256 i=0; i < whitelistAddresses.length; i++){
            if(whitelistAddresses[i] == _user){
                return true;
            }
        }
        return false;
    }

    function iswhitelistnine(address _user) public view returns (bool){
        for(uint256 i=0; i < whitelistNineAddresses.length; i++){
            if(whitelistNineAddresses[i] == _user){
                return true;
            }
        }
        return false;
    }

    function totalMint() public view returns (uint256) {
        return totalSupply();
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

     function setOnlyWhitelist(bool val) public onlyOwner {
        _onlyWhitelist = val;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner{
        delete whitelistAddresses;
        whitelistAddresses = _users;
    }

    function whitelistNineUsers(address[] calldata _users) public onlyOwner{
        delete whitelistNineAddresses;
        whitelistNineAddresses = _users;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function gift(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "No more gift" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _income = address(this).balance;
        require(payable(team).send(_income));
    }
}