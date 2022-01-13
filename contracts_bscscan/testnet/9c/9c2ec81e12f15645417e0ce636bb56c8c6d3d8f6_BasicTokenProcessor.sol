/**
 *Submitted for verification at BscScan.com on 2022-01-13
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

    constructor()
    {
        ownerAddress = msg.sender;
    }

    modifier onlyOwner()
    {
        require(msg.sender == ownerAddress, "Invalid invoker!");
        _;
    }

    modifier onlyOwnerOrWhiteAccount()
    {
        require(msg.sender == ownerAddress || mWhiteAccountMap[msg.sender] == true, "Invalid invoker!");
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

    mapping(string => IERC20) private mToken20Maps;

    function addTokenSupport(string memory _symbol, address _tokenAddress) onlyOwner public returns(bool)
    {
        require(bytes(_symbol).length > 0, "invalid symbol!");
        mToken20Maps[_symbol] = IERC20(_tokenAddress);
        return true;
    }

    function removeTokenSupport(string memory _symbol) onlyOwner public returns(bool)
    {
        require(bytes(_symbol).length > 0, "invalid symbol!");
        delete mToken20Maps[_symbol];
        return true;
    }

    function getTokenAddress(string memory _symbol) public view returns(address)
    {
        IERC20 erc20 = mToken20Maps[_symbol];
        return address(erc20);
    }

    function transferFrom(string memory _symbol, address _fromAddress, address _tokenAddress, uint256 _amount) onlyOwnerOrWhiteAccount public returns(bool)
    {
        // self not transfer self
        require(_fromAddress != _tokenAddress, "Invalid account addr!");
        require(_fromAddress != address(0), "Invalid fromAddress!");
        require(_tokenAddress != address(0), "Invalid toAddress!");
        require(_amount > 0, "Invalid amount");

        IERC20 tokenImpl = mToken20Maps[_symbol];
        tokenImpl.transferFrom(_fromAddress, _tokenAddress, _amount);
        return true;
    }

    function transferFrom(string memory _symbol, address _fromAddress,
        address _toAddress1, uint256 _amount1,
        address _toAddress2, uint256 _amount2) onlyOwnerOrWhiteAccount public returns(bool)
    {
        transferFrom(_symbol, _fromAddress, _toAddress1, _amount1);
        if(_amount2 > 0 && _toAddress2 != address(0) && _fromAddress != _toAddress2)
        {
            transferFrom(_symbol, _fromAddress, _toAddress2, _amount2);
        }
        return true;
    }

    function transferFrom(string memory _symbol, address _fromAddress,
        address _toAddress1, uint256 _amount1,
        address _toAddress2, uint256 _amount2,
        address _toAddress3, uint256 _amount3) onlyOwnerOrWhiteAccount public returns(bool)
    {
        transferFrom(_symbol, _fromAddress, _toAddress1, _amount1, _toAddress2, _amount2);
        if(_amount3 > 0 && _toAddress3 != address(0) && _fromAddress != _toAddress3)
        {
            transferFrom(_symbol, _fromAddress, _toAddress3, _amount3);
        }
        return true;
    }

    function transferFrom(string memory _symbol, address _fromAddress,
        address _toAddress1, uint256 _amount1,
        address _toAddress2, uint256 _amount2,
        address _toAddress3, uint256 _amount3,
        address _toAddress4, uint256 _amount4) onlyOwnerOrWhiteAccount public returns(bool)
    {
        transferFrom(_symbol, _fromAddress, _toAddress1, _amount1, _toAddress2, _amount2, _toAddress3, _amount3);
        if(_amount4 > 0 && _toAddress4 != address(0) && _fromAddress != _toAddress4)
        {
            transferFrom(_symbol, _fromAddress, _toAddress4, _amount4);
        }
        return true;
    }

    function balanceOf(string memory _symbol, address _account) public view returns(uint256)
    {
        require(_account != address(0), "Invalid account addr!");

        IERC20 tokenImpl = mToken20Maps[_symbol];
        return tokenImpl.balanceOf(_account);
    }

    function allowance(string memory _symbol, address _account) public view returns(uint256)
    {
        require(_account != address(0), "Invalid account addr!");

        IERC20 tokenImpl = mToken20Maps[_symbol];
        address selfContractAddress = address(this);
        return tokenImpl.allowance(_account, selfContractAddress);
    }
}