pragma solidity 0.8.6;

import "./erc721.sol";

contract Test 
{
    mapping(address => bool) public managers;

    constructor(){
        managers[msg.sender] = true;
    }

    modifier onlyManagers(){
        require(managers[msg.sender], "Only managers allowed");
        _;
    }

    function addManager(address _manager) public onlyManagers{
        managers[_manager] = true;
    }

    function removeManager(address _manager) public onlyManagers{
        managers[_manager] = false;
    }

    function transferOut(ERC721 nft, uint256 _tokenId, address _receiver) public onlyManagers
    {
        require(managers[_receiver], "Only managers allowed as receiver");
        nft.transferFrom(address(this), _receiver, _tokenId);
    }
}