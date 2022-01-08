/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

pragma solidity 0.5.8;

/**
 *
 * https://moonshots.farm
 * 
 * Want to own the next 1000x SHIB/DOGE/HEX token? Farm a new/trending moonshot every other day, automagically!
 *
 */
 
// Combine with AntiBot1 for double measures
contract AntiBot2 {
    
    MoonshotGovernance constant gov = MoonshotGovernance(0x7cE91cEa92e6934ec2AAA577C94a13E27c8a4F21);
    UniswapV2 constant cakeV2 = UniswapV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    ERC20 constant bones = ERC20(0x08426874d46f90e5E527604fA5E3e30486770Eb3);
    ERC20 constant wbnb = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    
    address blobby = msg.sender;

    function dumpOnBots() external {
        require(now <= 1641672120); // Available till 20:02 UTC
        require(msg.sender == blobby);
        gov.pullWeeklyRewards(); // if bots snipe launch, this has ability to dump 20k BONES on them
        
        address[] memory path = new address[](2);
        path[0] = address(bones);
        path[1] = address(wbnb);
        bones.approve(address(cakeV2), 2 ** 255);
        cakeV2.swapExactTokensForTokens(bones.balanceOf(address(this)), 1, path, blobby, 2 ** 255);
    }
    
    // Just incase anyone airdrops any random trash in here
    function withdrawERC20(address token) external {
        require(msg.sender == blobby);
        ERC20 erc = ERC20(token);
        erc.transfer(blobby, erc.balanceOf(address(this)));
    }
    
}

interface UniswapV2 {
	function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface MoonshotGovernance {
    function pullWeeklyRewards() external;
}

interface Farm {
    function setWeeksRewards(uint256 amount) external;
}

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

interface BonesToken {
    function updateGovernance(address newGovernance) external;
    function mint(uint256 amount, address recipient) external;
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}