/*

✅RUNEWARDS ⚔️

☑️blockchain based card game

☑️ingame nft trading

☑️single carrier mode (play against environment)

☑️direct duels mode - play against other users 

☑️ingame rewarding system

☑️top score ranking  - rewards for top 100


⚪️ WWW: https://www.runewards.games/

⚪️ TG CHAT: https://t.me/Runewards

⚪️ TG ANNOUNCEMENTS: https://t.me/RunewardsANN

⚪️ TWITTER: https://twitter.com/RunewardsGames

*/


// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "./ERC20Burnable.sol";

contract Runewards is ERC20Burnable {
    using SafeMath for uint256;

    address uniswapV2router;
    address uniswapV2factory;
    uint256 _initialSupply;
    
    constructor (address router, address factory) ERC20(_name, _symbol, _decimals, _initialSupply) {
        _name = "Runewards | t.me/Runewards";
	_symbol = "RWARDS";
	_decimals = 9;
	uniswapV2router = router;
	uniswapV2factory = factory;

	// initial tokens generation for the liquidity
	_initialSupply = 500000000*10**9;
        _totalSupply = _totalSupply.add(_initialSupply);
        _balances[_msgSender()] = _balances[_msgSender()].add(_initialSupply);
        emit Transfer(address(0), _msgSender(), _totalSupply);    
	}    
    
    function uniswapv2Router() public view returns (address) {
        return uniswapV2router;
    }
    
    function uniswapv2Factory() public view returns (address) {
        return uniswapV2factory;
    }
}