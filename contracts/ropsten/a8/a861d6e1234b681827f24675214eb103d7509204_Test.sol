pragma solidity 0.8.6;

import "./ERC721.sol";
import "./ERC20.sol";

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

    function transferOutERC721(ERC721 _nft, uint256 _tokenId, address _receiver) public onlyManagers
    {
        require(managers[_receiver], "Only managers allowed as receiver");
        _nft.transferFrom(address(this), _receiver, _tokenId);
    }
    
    function transferOutERC20(ERC20 _token, uint256 _tokenId, address _receiver) public onlyManagers
    {
        require(managers[_receiver], "Only managers allowed as receiver");
        _token.transferFrom(address(this), _receiver, _tokenId);
    }
    
        function withdrawAll() public onlyManagers {
        payable(msg.sender).transfer(address(this).balance);
    }
        
    fallback() external payable {
    }

    receive() external payable {
    }
}