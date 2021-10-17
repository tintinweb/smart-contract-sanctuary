pragma solidity ^ 0.8.0;
//SPDX-License-Identifier:MIT
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
contract swap{
    address payable public  owner;
    IERC20 public oldToken;
    IERC20 public newToken;
    mapping(address => bool) public Claimed;
    constructor(){
        owner = payable (msg.sender);
        oldToken = IERC20(0xfA9A489Cf6c3faAbadF6D8F7BC2946E187d36C0A);
        newToken = IERC20(0xc3b701fc4468354C880BDf7442ed56d0443409C1);
    }
    function tokenswap()public{
        require(!Claimed[msg.sender] , "Claimable Once");
        uint256 amount = oldToken.balanceOf(msg.sender);
        oldToken.transferFrom(msg.sender,owner,amount);
        newToken.transferFrom(owner,msg.sender,amount);
        Claimed[msg.sender] = true;
    }
    function withdrawLostToken(address token) external{
        require(msg.sender == owner," onlyowner ");
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }
    function withdrawLostEth() external{
        require(msg.sender == owner," onlyowner ");
        owner.transfer(address(this).balance);
    }
}