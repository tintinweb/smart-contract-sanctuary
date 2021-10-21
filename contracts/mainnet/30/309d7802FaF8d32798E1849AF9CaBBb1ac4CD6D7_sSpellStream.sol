/**
 *Submitted for verification at Etherscan.io on 2021-10-21
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

// File: contracts/ystream/sSpellStream.sol

pragma solidity >=0.4.21 <0.6.0;





contract sSpellInterface is IERC20{
  IERC20 public token;
}

contract sSpellStream is IYieldStream{
  using SafeMath for uint256;
  sSpellInterface public sSpell;

  constructor() public{
    name = "sSpell yield stream";
    sSpell = sSpellInterface(address(0x26FA3fFFB6EfE8c1E69103aCb4044C26B9A106a9));
  }


  function target_token() public view returns(address){
    return address(sSpell);
  }

  function getVirtualPrice() public view returns(uint256){
    if(sSpell.totalSupply() == 0){
      return 0;
    }

    return sSpell.token().balanceOf(address(sSpell)).safeMul(1e18).safeDiv(sSpell.totalSupply());
  }

  function getDecimal() public pure returns(uint256){
    return 1e18;
  }

  function getPriceDecimal() public pure returns(uint256){
    return 1e18;
  }
}