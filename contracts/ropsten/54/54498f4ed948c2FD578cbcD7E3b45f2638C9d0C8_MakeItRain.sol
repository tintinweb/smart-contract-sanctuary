/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity >=0.6.0;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract MakeItRain {
  function rainEth(address payable[] calldata rec, uint256 amt)  public payable {
      for (uint i=0;i<rec.length;++i) {
          rec[i].transfer(amt);
      }
  }
  function rainErc(address token, address[] calldata rec, uint256 amt)  public {
      for (uint i=0;i<rec.length;++i) {
          IERC20(token).transferFrom(msg.sender, rec[i], amt);
      }
  }
}