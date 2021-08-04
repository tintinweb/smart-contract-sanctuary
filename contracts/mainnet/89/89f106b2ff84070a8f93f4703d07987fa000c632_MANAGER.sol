/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

pragma solidity ^0.8.0;

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()  {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    
    function burn(uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}



contract MANAGER is Owned {

     address public tokenAddress = address(0);

      function setToken(address _addr) external onlyOwner {
        tokenAddress =  _addr;
      }
    
      function run() external {
         
        uint256 devFund = IERC20(tokenAddress).balanceOf(address(this))/4; 
        
        IERC20(tokenAddress).transfer(owner, devFund);
        IERC20(tokenAddress).burn(IERC20(tokenAddress).balanceOf(address(this)));

    }


}