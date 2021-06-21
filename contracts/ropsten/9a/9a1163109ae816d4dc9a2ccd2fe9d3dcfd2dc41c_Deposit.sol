/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Deposit {

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    using SafeMath for uint256;


    function lock(address token, uint256 amount) public {
        require(
            amount <= IERC20(token).balanceOf(msg.sender), 
            "Token balance is too low"
        );
        require(
            IERC20(token).allowance(msg.sender, address(this)) >= amount,
            "Token allowance too low"
        );
        balances[msg.sender] = balances[msg.sender].add(amount);
        bool sent = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(sent, "Token transfer failed");
    }
    
    function unlock(address token, uint256 amount) public {
        require(
             IERC20(token).balanceOf(msg.sender) >= amount, 
            "The balance on the deposit is too low"
        );
        balances[msg.sender] = balances[msg.sender].sub(amount);
        bool sent = IERC20(token).transfer(msg.sender, amount);
        require(sent, "Token transfer failed");
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}