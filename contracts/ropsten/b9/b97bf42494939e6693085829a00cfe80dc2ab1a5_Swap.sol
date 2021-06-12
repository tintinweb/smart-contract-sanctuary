/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

pragma solidity 0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Swap
{
    
    address owner;
    
    IERC20 tokenA;
    IERC20 tokenB;
    
    modifier onlyOwner
    {
        require(msg.sender == owner, "Msg.sender is not the owner");
        _;
    }
    
    constructor(address _tokenA, address _tokenB)
    {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        
        owner = msg.sender;
    }
    
    ////////////////
    // SWAP FUNCTION
    function swap(uint256 _amount) external
    {
        require(tokenA.balanceOf(address(this)) >= _amount, "Contract doesn't have enough funds");
        
        tokenB.transferFrom(msg.sender, address(this), _amount);
        tokenA.transfer(msg.sender, _amount);
    }
    
    //////////////////
    // Owner functions
    
    function setOwner(address _owner) external onlyOwner
    {
        owner = _owner;
    }
    
    function withdrawTokenA(uint256 _amount) external onlyOwner
    {
        require(tokenA.balanceOf(address(this)) >= _amount, "Contract doesn't have enough funds");
        
        tokenA.transfer(owner, _amount);
    }
    
    function withdrawTokenB(uint256 _amount) external onlyOwner
    {
        require(tokenB.balanceOf(address(this)) >= _amount);
        
        tokenB.transfer(owner, _amount);
    }
}