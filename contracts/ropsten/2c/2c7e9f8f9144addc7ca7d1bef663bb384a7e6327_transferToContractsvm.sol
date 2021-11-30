/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

pragma solidity =0.7.6;
pragma abicoder v2;

interface IERC20svm{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract transferToContractsvm{
    address public _WETH = 0x3Ac63D5f78b90CfDbd7135A9b4b1b5Fd4ce9e8ab;
    IERC20svm public WETH = IERC20svm(_WETH);

    function transferToC (uint amount) public
    {
        WETH.approve(msg.sender,amount);
        WETH.transferFrom(msg.sender,address(this),amount);
    }
    
    function transferFromC(uint amount) public{
        WETH.approve(address(this),amount);
        WETH.transferFrom(address(this),msg.sender,amount);
    }
    
    function getbal() public view returns(uint){
        return WETH.balanceOf(msg.sender);
    }
    
    
}