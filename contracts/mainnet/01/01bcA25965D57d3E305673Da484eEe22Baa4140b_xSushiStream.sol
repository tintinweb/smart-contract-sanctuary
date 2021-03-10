/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// File: contracts/erc20/IERC20.sol

pragma solidity >=0.4.21 <0.6.0;

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

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

// File: contracts/ystream/IYieldStream.sol

pragma solidity >=0.4.21 <0.6.0;

contract IYieldStream{

  string public name;

  function target_token() public view returns(address);

  function getVirtualPrice() public view returns(uint256);

  function getDecimal() public pure returns(uint256);

  function getPriceDecimal() public pure returns(uint256);
}

// File: contracts/ystream/xSushiStream.sol

pragma solidity >=0.4.21 <0.6.0;





contract xSushiInterface is IERC20{
  IERC20 public sushi;
}

contract xSushiStream is IYieldStream{
  using SafeMath for uint256;
  xSushiInterface public xsushi;

  constructor() public{
    name = "xSushi yield stream";
    xsushi = xSushiInterface(address(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272));
  }


  function target_token() public view returns(address){
    return address(xsushi);
  }

  function getVirtualPrice() public view returns(uint256){
    if(xsushi.totalSupply() == 0){
      return 0;
    }

    return xsushi.sushi().balanceOf(address(xsushi)).safeMul(1e18).safeDiv(xsushi.totalSupply());
  }

  function getDecimal() public pure returns(uint256){
    return 1e18;
  }

  function getPriceDecimal() public pure returns(uint256){
    return 1e18;
  }
}