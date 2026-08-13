/**
 *Submitted for verification at moonriver.moonscan.io on 2022-03-09
*/

/**
 *Submitted for verification at moonriver.moonscan.io on 2022-01-21
*/

// SPDX-License-Identifier: OSL-3.0

/** NETWORKS 
    *Web:      https://firulaixcoin.finance/
    *facebook: https://www.facebook.com/firulaixfinance/
    *youtube:  https://www.youtube.com/channel/UCrOJRzI105YKDHa9zwABAqQ
    *twitter:  https://twitter.com/firulaixcoin
    *discord:  https://discord.com/invite/TEDUHknZuE
    *telegram: https://t.me/firulaixcoin/
**/


pragma solidity = 0.8.11;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
interface Router {
  function WNativeCurrency() external pure returns (address);

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);  

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

        function swapExactNativeCurrencyForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);


    function swapExactTokensForNativeCurrency(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

}

contract Swap {
    address private constant ROUTER = 0xe6FE3Db4c5A2e4a9Ab3301201b38724E578B35cA;
    
    function swapExactTokensForTokens(address[] memory _path,  uint _amountIn, uint _amountOutMin, address _to) external {
        IERC20(_path[0]).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_path[0]).approve(ROUTER, _amountIn);
        Router(ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, _path, _to, block.timestamp);
    }

    function swapExactNativeCurrencyForTokens(address[] memory _token, uint _amountOut, address _to) external payable {
      address[] memory path;
        path = new address[](_token.length + 1);
        path[0] =  Router(ROUTER).WNativeCurrency();

         for(uint i =0; i < _token.length;i++){
            path[i+1] = _token[i];
        }
        Router(ROUTER).swapExactNativeCurrencyForTokens{ value: msg.value }(_amountOut, path, _to, block.timestamp);
    }

    function swapExactTokensForNativeCurrency(address[] memory _token, uint _amountIn, uint _amountOutMin, address _to) external  {

        IERC20(_token[0]).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_token[0]).approve(ROUTER, _amountIn);
        address[] memory path;
        path = new address[](_token.length + 1);
         for(uint i =0; i < _token.length;i++){
            path[i] = _token[i];
        }
        path[_token.length] =  Router(ROUTER).WNativeCurrency();
        Router(ROUTER).swapExactTokensForNativeCurrency(_amountIn,_amountOutMin, path, _to, block.timestamp);
    }

    function getAmountOutMin(address[] memory _path, uint _amountIn) external view returns (uint) {
        uint[] memory amountOutMins = Router(ROUTER).getAmountsOut(_amountIn, _path);
        return amountOutMins[_path.length -1];
    }   

}