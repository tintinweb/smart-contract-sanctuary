//SPDX-Licence-Identifier: 2guys

pragma solidity ^0.6.0;

import "./ERC20.sol";

contract Steam is ERC20 {

    using SafeMath for uint256;

    modifier onlyUPS() {
        require(_UPS == _msgSender(), "onlyUPS: Only the UPStkn contract may call this function");
        _;
    }

    string private _name;
    address public _UPS;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _maxSupply;
    uint256 private _steamMinted = 0;

    event SteamGenerated(address account, uint amount);

    constructor(uint256 STEAM_maxTokens) public {
        _name = "STEAM";
        _symbol = "STEAM";
        _decimals = 18;
        _maxSupply = STEAM_maxTokens.mul(1e18);
        ERC20._mint(_msgSender(), 1e18);
        _UPS =  _msgSender();
    }
    
    function generateSteam(address account, uint256 amount) external onlyUPS {
        require((_totalSupply + amount) < _maxSupply, "STEAM token: cannot generate more steam than the max supply");
        ERC20._mint(account, amount);
        _steamMinted = _steamMinted.add(amount);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return ERC20._totalSupply;
    }
    
    function mySteam(address _address) public view returns(uint256){
        return balanceOf(_address);
    }
    
    function getSteamTotalSupply() public view returns(uint256){
        return _totalSupply;
    }
    
    function getSteamMaxSupply() public view returns(uint256){
        return _maxSupply;
    }
    
    function getSteamMinted() public view returns(uint256){
        return _steamMinted;
    }

}