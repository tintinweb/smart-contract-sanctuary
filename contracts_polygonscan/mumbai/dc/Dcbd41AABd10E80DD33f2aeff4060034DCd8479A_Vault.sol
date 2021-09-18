/**
 *Submitted for verification at polygonscan.com on 2021-09-17
*/

pragma solidity ^0.8.3;

interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Vault {
  address public admin;
  IERC20 public token;
  event BuyPoint(uint pointt, address account);
  



  constructor(address _token, address _admin) {
    admin = _admin; 
    token = IERC20(_token);
  }

  function updateAdmin(address newAdmin) external {
    require(msg.sender == admin, 'only admin');
    admin = newAdmin;
  }
  
  function buy(uint _amount) public {
        address from = msg.sender;
        address to = address(this);
        uint256 amountTobuy = _amount;
        require(amountTobuy > 0, "You need to send some Token");
        uint points = amountTobuy;
        token.transferFrom(from, to, _amount);
        emit BuyPoint(points, msg.sender);
    }

  function sellTokens(
    address recipient,
    uint _point
    
  ) public {
    
    uint amount = _point;
    token.transfer(recipient, amount);
    
  }


}