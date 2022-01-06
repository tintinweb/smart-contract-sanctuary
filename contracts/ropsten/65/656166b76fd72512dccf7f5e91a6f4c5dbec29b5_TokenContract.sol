/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

pragma solidity >0.5.0 <0.9.0;


interface ITRC20
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address ower, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address repipient, uint256 amount) external returns (bool);
}

contract TokenContract{

    address private _mCreateAccount;

    mapping(string => ITRC20) private _mTokenSupportMaps;
    mapping(address => uint8) private _mRightAccountMaps;

    constructor() public
    {
        _mCreateAccount = msg.sender;
    }

    function addRightAccount(address account) public returns(bool)
    {
        require(account != address(0), "invalid account!");
        require(msg.sender == _mCreateAccount, "Invalid invoker!");
        _mRightAccountMaps[account] = 1;
        return true;
    }

    function removeRightAccount(address account) public returns(bool)
    {
        require(account != address(0), "invalid account!");
        require(msg.sender == _mCreateAccount, "Invalid invoker!");
        delete _mRightAccountMaps[account];
        return true;
    }

    function addTokenSupport(string memory symbol, ITRC20 token) public returns(bool)
    {
        require(bytes(symbol).length > 0, "invalid symbol!");
        require(msg.sender == _mCreateAccount, "Invalid invoker!");

        _mTokenSupportMaps[symbol] = token;
        return true;
    }

    function removeTokenSupport(string memory symbol) public returns(bool)
    {
        require(bytes(symbol).length > 0, "invalid symbol!");
        require(msg.sender == _mCreateAccount, "Invalid invoker!");

        delete _mTokenSupportMaps[symbol];
        return true;
    }

    function transferFrom(string memory symbol, address fromAddress, address toAddress, uint256 amount) public returns(bool)
    {
        require(fromAddress != toAddress, "Invalid account addr!");
        require(amount > 0, "Invalid amount");

        require(msg.sender == _mCreateAccount || _mRightAccountMaps[msg.sender] == 1, "Invalid invoker!");


        ITRC20 tokenImpl = _mTokenSupportMaps[symbol];
        tokenImpl.transferFrom(fromAddress, toAddress, amount);
        return true;
    }

    function balanceOf(string memory symbol, address account) public view returns(uint256)
    {
        require(account != address(0), "Invalid account addr!");

        ITRC20 tokenImpl = _mTokenSupportMaps[symbol];
        return tokenImpl.balanceOf(account);
    }

    function allowance(string memory symbol, address account) public view returns(uint256)
    {
        require(account != address(0), "Invalid account addr!");

        ITRC20 tokenImpl = _mTokenSupportMaps[symbol];

        address selfContractAddress = address(this);
        return tokenImpl.allowance(account, selfContractAddress);
    }

}