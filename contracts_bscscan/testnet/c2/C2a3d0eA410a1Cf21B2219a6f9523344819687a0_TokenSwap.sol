/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

pragma solidity ^0.8.7;

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

contract TokenSwap {
    IERC20 public token1;
    address public owner1;
    IERC20 public token2;
    address public owner2;
    
    constructor (address _token1, address _owner1, address _token2, address _owner2) {
        token1 = IERC20(_token1);
        owner1 = _owner1;
        token2 = IERC20(_token2);
        owner2 = _owner2;
    }
    
    function swap(uint _amount1, uint _amount2) public {
        require(msg.sender == owner1 || msg.sender == owner2, "Not authorized!");
        require(token1.allowance(owner1, address(this)) >= _amount1, "Token 1 allowance too low");
        require(token2.allowance(owner2, address(this)) >= _amount1, "Token 2 allowance too low");
    }
    
    event Approval(address indexed src, address indexed guy, uint wad);
        mapping(address => mapping (address => uint))  public allowance;
        function Approve(address guy, uint wad) public returns (bool) {
            IERC20(token1).approve(guy, wad);
            allowance[msg.sender][guy] = wad;
            emit Approval(msg.sender, guy, wad);
            return true;
        }
}