/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.5.0 <0.9.0;


interface IERC20
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address ower, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address repipient, uint256 amount) external returns (bool);
}

contract MyVeriable
{
    address public ownerAddress;

    mapping(address => bool) private mWhiteAccountMap;

    constructor() public
    {
        ownerAddress = msg.sender;
    }

    modifier onlyOwner()
    {
        require(msg.sender == ownerAddress);
        _;
    }

    modifier onlyOwnerOrWhiteAccount()
    {
        require(msg.sender == ownerAddress || mWhiteAccountMap[msg.sender] == true);
        _;
    }

    function addWhiteAccount(address account) onlyOwner public returns(bool)
    {
        require(account != address(0), "invalid address!");
        require(ownerAddress != account, "Forbidden add owner!");
        mWhiteAccountMap[account] = true;
        return true;
    }

    function removeWhiteAccount(address account) onlyOwner public returns(bool)
    {
        require(account != address(0), "invalid address!");
        delete mWhiteAccountMap[account];
        return true;
    }

}

contract BasicTokenProcessor is MyVeriable{

    mapping(string => IERC20) private _mToken20Maps;

    function addTokenSupport(string memory symbol, IERC20 token) onlyOwner public returns(bool)
    {
        require(bytes(symbol).length > 0, "invalid symbol!");
        _mToken20Maps[symbol] = token;
        return true;
    }

    function removeTokenSupport(string memory symbol) onlyOwner public returns(bool)
    {
        require(bytes(symbol).length > 0, "invalid symbol!");
        delete _mToken20Maps[symbol];
        return true;
    }

    function transferFrom(string memory symbol, address fromAddress, address toAddress, uint256 amount) onlyOwnerOrWhiteAccount public returns(bool)
    {
        // self not transfer self
        require(fromAddress != toAddress, "Invalid account addr!");
        require(fromAddress != address(0), "Invalid fromAddress!");
        require(toAddress != address(0), "Invalid toAddress!");
        require(amount > 0, "Invalid amount");

        IERC20 tokenImpl = _mToken20Maps[symbol];
        tokenImpl.transferFrom(fromAddress, toAddress, amount);
        return true;
    }

    function balanceOf(string memory symbol, address account) public view returns(uint256)
    {
        require(account != address(0), "Invalid account addr!");

        IERC20 tokenImpl = _mToken20Maps[symbol];
        return tokenImpl.balanceOf(account);
    }

    function allowance(string memory symbol, address account) public view returns(uint256)
    {
        require(account != address(0), "Invalid account addr!");

        IERC20 tokenImpl = _mToken20Maps[symbol];
        address selfContractAddress = address(this);
        return tokenImpl.allowance(account, selfContractAddress);
    }

}