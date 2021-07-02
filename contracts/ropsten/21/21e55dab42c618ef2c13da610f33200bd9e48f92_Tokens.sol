/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity  0.6.0;
library SafeMath {
       function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        return c;
    }
}
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
contract Tokens {
    using SafeMath for uint256;
    address public admin;
    IERC20 public Token;
  //  Oracle public callOracle;
    event Bought(uint256 tokens);
    event Sold(uint256 tokens);
    uint256  public oneTokenPrice=100;                                  //1ether=10^16 tokens
    constructor(IERC20 _token/*,Oracle _oracle8*/) public {
        admin=msg.sender;
        Token=_token;
        //callOracle=_oracle;
    }
    event Transfer(address indexed from, address indexed to, uint256 value);
    uint256 public tokens;
    modifier onlyAdmin {
        require(msg.sender==admin,"Only admin can access");
        _;
    }
    function buyTokens() payable public {
        //oneTokenPrice=callOracle.getPrice();
        require(oneTokenPrice!=0,"Token price cannot be zero");
        tokens = msg.value.div(oneTokenPrice);
        require(IERC20(Token).balanceOf(address(this))>=tokens,"Not Enough Tokens");
        IERC20(Token).transfer(msg.sender,tokens);
        emit Transfer(address(this),msg.sender,tokens);
    }
    function sellTokens(uint256 noOfTokens) public {
        require(IERC20(Token).balanceOf(msg.sender)>=noOfTokens,"You don't have enough tokens to sell");
        uint256 returnEther = noOfTokens.mul(oneTokenPrice);
        // Return tokens to the contract address
        IERC20(Token).transferFrom(msg.sender, address(this), noOfTokens);
        // Return Ether to buyer address
        msg.sender.transfer(returnEther);
        emit Transfer(msg.sender, address(this), noOfTokens);
    }
    function withdraw() public onlyAdmin {
        uint256 balance = Token.balanceOf(address(this));
        Token.transfer(admin,balance);
    }
}