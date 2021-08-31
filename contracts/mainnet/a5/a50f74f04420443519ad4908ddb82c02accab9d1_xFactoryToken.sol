// contracts/0xFactoryToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC20.sol";

contract xFactoryToken is ERC20, Ownable {
    
    mapping(address => bool) private _minters;
    
    constructor() ERC20("0xFactoryToken", "xFCT") {

    }
    
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
    
    function mint(address _to, uint256 _count) public {
        require(isMinter(msg.sender), "Sender cannot mint tokens");
        _mint(_to, _count);
    }
    
    function burn(uint256 _count) public {
        require(isMinter(msg.sender), "Sender cannot burn tokens");
        _burn(msg.sender, _count);
    }
    
    function isMinter(address _address) public view returns (bool) {
        require(_address != address(0), "Query for the zero address");
        return _minters[_address];
    }
    
    function setMinterStatus(address _address, bool _status) public onlyOwner{
        require(_address != address(0), "Query for the zero address");
        _minters[_address] = _status;
    }
}