/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

// SPDX-License-Identifier: MIT
// File: contracts/ToshiGames/IterableFlips.sol


pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

//import {SafeMath} from "./SafeMath.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//import {DataAggregator} from "./DataAggregator.sol";
//import {Tokens} from "./Tokens.sol";
//import {Users} from "./Users.sol";

/*
 * @dev 
 * This library is required to manage flipss on ToshiFlip
 * dataAggregator is used to create random address and to create commitment
 *
 * The declaration of the variable is on "ToshiFlip.sol"
 * Only players of ToshiFlip can execute functions
 */
library IterableFlips {
    //using SafeMath for uint256;
    //using Tokens for Tokens.Token;
    //using Users for Users.User;

    struct Flip{
        address key;
        //Users.User player1;
        address player1;
        //Users.User player2;
        address player2;
        address commitment1;
        address commitment2;
        //Tokens.Token token;
        address token;
        uint256 amount;
        uint256 expiration;
        
        address winner;
        bool available;
        uint256 dateCreated;
        uint256 dateFinished;
    }
    
    struct Flips{
        //DataAggregator dataAggregator;
        uint nFlips;
        uint nNonces;
        //uint nbCommitment;
        address[] keys;
        mapping(address => Flip) flips;
        mapping(address => address) nonces;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Flips storage flips, address key) external view returns(Flip memory flip){
        if( !flips.inserted[key] ){
            return Flip(address(0), address(0), address(0), address(0), address(0), address(0), 0, 0, address(0), false, 0, 0);
        }
        return flips.flips[key];
    }
    function getAll(Flips storage flips) external view returns(Flip[] memory all){
        uint nFlips = flips.keys.length;
        Flip[] memory flipArray = new Flip[](nFlips);
        for(uint i=0; i < nFlips; i++ ){
            flipArray[i] = flips.flips[flips.keys[i]];
        }
        return flipArray;
    }
    function getAvailables(Flips storage flips) external view returns(Flip[] memory availables){
        uint nFlips = flips.keys.length;
        uint nFlipsReal = 0;
        address[] memory flipAddressArray = new address[](nFlips);
        for(uint i=0; i < nFlips; i++ ){
            if( flips.flips[flips.keys[i]].available ){
                flipAddressArray[i] = flips.keys[i];
                nFlipsReal++;
            }
        }

        Flip[] memory flipArray = new Flip[](nFlipsReal);
        for(uint i=0; i < nFlipsReal; i++ ){
            flipArray[i] = flips.flips[flipAddressArray[i]];
        }
        return flipArray;
    }
    
    function getPlayerFlips(Flips storage flips, address player) external view returns(Flip[] memory playerFlips){
        uint nFlips = flips.keys.length;
        uint nFlipsReal = 0;
        address[] memory flipAddressArray = new address[](nFlips);
        for(uint i=0; i < nFlips; i++ ){
            if( flips.flips[flips.keys[i]].player1 == player || flips.flips[flips.keys[i]].player2 == player ){
                flipAddressArray[i] = flips.keys[i];
                nFlipsReal++;
            }
        }
        if( nFlipsReal == 0 ){
            return new Flip[](nFlipsReal);
        }
        
        Flip[] memory flipArray = new Flip[](nFlipsReal);
        for(uint i=0; i < nFlipsReal; i++ ){
            flipArray[i] = flips.flips[flipAddressArray[i]];
        }
        return flipArray;
    }
    function isFlip(Flips storage flips, address key) external view returns(bool _isFlip){
        return flips.inserted[key];
    }

    function add(Flips storage flips, address player1, address token, uint256 amount, bool choice, uint256 expiration) external returns(address flipAddress){
        flips.nFlips++;
        address key = address(uint160(uint(keccak256(abi.encodePacked(flips.nFlips, player1, token, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))));
        //address key = flips.dataAggregator.createRandomAddress(token.key, amount);
        while( flips.inserted[key] ){
            flips.nFlips++;
            key = address(uint160(uint(keccak256(abi.encodePacked(flips.nFlips, player1, token, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))));
        }
        
        flips.nNonces++;
        address nonce = address(uint160(uint(keccak256(abi.encodePacked(flips.nNonces, player1, token, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))));
        flips.nonces[key] = nonce;
        
        address commitment1 = address(uint160(uint(keccak256(abi.encodePacked(nonce, choice, address(this))))));
        
        //uint lastIndex = flips.keys.length - 1;
        flips.keys.push(key);
        //flips.keys[lastIndex] = key;
        flips.flips[key] = Flip(key, player1, address(0), commitment1, address(0), token, amount, expiration, address(0), true, block.timestamp, 0);
        flips.indexOf[key] = flips.keys.length - 1;
        flips.inserted[key] = true;
        return key;
    }
    /*
    function _addFlip(Flips storage flips, Users.User memory player1, Tokens.Token memory token, uint256 amount, bool choice, uint256 expiration) public returns(address flipAddress){
        flips.nFlips++;
        address key = address(uint160(uint(keccak256(abi.encodePacked(flips.nFlips, player1.key, token.key, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))));
        //address key = flips.dataAggregator.createRandomAddress(token.key, amount);
        while( flips.inserted[key] ){
            flips.nFlips++;
            key = address(uint160(uint(keccak256(abi.encodePacked(flips.nFlips, player1.key, token.key, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))));
        }
        
        flips.nNonces++;
        address nonce = address(uint160(uint(keccak256(abi.encodePacked(flips.nNonces, player1.key, token.key, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))));
        flips.nonces[key] = nonce;
        
        address commitment1 = address(uint160(uint(keccak256(abi.encodePacked(nonce, choice, address(this))))));
        
        flips.keys.push(key);
        flips.flips[key] = Flip(key, player1, Users.User(address(0), 0, 0, true), commitment1, address(0), token, amount, expiration, address(0), true, block.timestamp, 0);
        flips.indexOf[key] = flips.keys.length;
        flips.inserted[key] = true;
        return key;
    }
    */
    function join(Flips storage flips, address key, address player2, bool choice) external returns(bool joined){
        if( !flips.inserted[key] ){
            return false;
        }
        
        address nonce = flips.nonces[key];
        flips.flips[key].player2 = player2;
        flips.flips[key].commitment2 = address(uint160(uint(keccak256(abi.encodePacked(nonce, choice, address(this))))));
        return true;
    }
    
    function pickWinner(Flips storage flips, address key) external returns(address winner){
        if( !flips.inserted[key] ){
            return address(0);
        }
        Flip memory flip = flips.flips[key];
        flip.winner = flip.commitment1 == flip.commitment2 ? flip.player2 : flip.player1;
        flip.available = false;
        flip.dateFinished = block.timestamp;
        flips.flips[key] = flip;
        
        delete flips.nonces[key];
        return flip.winner;
    }
    
    function remove(Flips storage flips, address key) external returns (bool removed){
        if (!flips.inserted[key]) {
            return false;
        }
        flips.nFlips--;
        flips.nNonces--;
        
        delete flips.nonces[key];
        delete flips.inserted[key];
        delete flips.flips[key];
        uint index = flips.indexOf[key];
        uint lastIndex = flips.keys.length - 1;
        address lastKey = flips.keys[lastIndex];
        flips.indexOf[lastKey] = index;
        flips.keys[index] = lastKey;
        delete flips.indexOf[key];
        flips.keys.pop();
        return true;
    }
    


    function getIndexOfKey(Flips storage flips, address key) external view returns (int index) {
        if(!flips.inserted[key]) {
            return -1;
        }
        return int(flips.indexOf[key]);
    }
    function getKeyAtIndex(Flips storage flips, uint index) external view returns (address flipAddress) {
        return flips.keys[index];
    }
    
    function size(Flips storage flips) external view returns (uint length) {
        return flips.keys.length;
    }
}
// File: contracts/ToshiGames/IterablePlayers.sol


pragma solidity >=0.8.0;

/*
 * @dev 
 * This library is required to manage available players on ToshiGames
 * dataAggregator is used to pick a random user
 *
 * The declaration of the variable is on "ContextGames.sol"
 * Only BabyToshi owner can exclude a player
 * Only players of ToshiFlip can execute some functions
 * Only new players can register to ToshiFlip
 */
library IterablePlayers {
    struct Players{
        uint nbRandom;
        address[] keys;
        mapping(address => uint256) win;
        mapping(address => uint256) loose;
        mapping(address => bool) excluded;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }
    function get(Players storage players, address key) external view returns(address player, uint256 win, uint256 loose, bool excluded){
        if( !players.inserted[key] ){
            return (address(0), 0, 0, false);
        }
        return (key, players.win[key], players.loose[key], players.excluded[key]);
    }
    
    function getRandom(Players storage players, address key) external returns (address randomPlayer) {
        if( players.keys.length == 0 ){
            return address(0);
        }
        players.nbRandom++;
        uint random = uint(keccak256(abi.encodePacked(players.nbRandom, key, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))%players.keys.length; //blockhash(block.number), block.difficulty
        return players.keys[random];
    }
    function getAll(Players storage players) external view returns(address[] memory player, uint256[] memory win, uint256[] memory loose, bool[] memory excluded){
        uint nPlayers = players.keys.length;
        (address[] memory _player, uint256[] memory _win, uint256[] memory _loose, bool[] memory _excluded) = (new address[](nPlayers), new uint256[](nPlayers), new uint256[](nPlayers), new bool[](nPlayers));
        for(uint i=0; i < nPlayers; i++ ){
            address key = players.keys[i];
            _player[i] = key;
            _win[i] = players.win[key];
            _loose[i] = players.loose[key];
            _excluded[i] = players.excluded[key];
        }
        return (_player, _win, _loose, _excluded);
    }
    function getAvailables(Players storage players) external view returns(address[] memory player, uint256[] memory win, uint256[] memory loose, bool[] memory excluded){
        uint nPlayers = players.keys.length;
        (address[] memory _player, uint256[] memory _win, uint256[] memory _loose, bool[] memory _excluded) = (new address[](nPlayers), new uint256[](nPlayers), new uint256[](nPlayers), new bool[](nPlayers));
        for(uint i=0; i < nPlayers; i++ ){
            address key = players.keys[i];
            if( !players.excluded[key] ){
                _player[i] = key;
                _win[i] = players.win[key];
                _loose[i] = players.loose[key];
                _excluded[i] = players.excluded[key];
            }
        }
        return (_player, _win, _loose, _excluded);
    }

    function isPlayer(Players storage players, address key) external view returns(bool _isPlayer){
        return players.inserted[key];
    }
    
    function add(Players storage players, address key) public returns(bool added){
        if( players.inserted[key] ){
            return false;
        }
        players.keys.push(key);
        players.win[key] = 0;
        players.loose[key] = 0;
        players.excluded[key] = false;
        players.indexOf[key] = players.keys.length - 1;
        players.inserted[key] = true;
        
        return true;
    }
    function remove(Players storage players, address key) external returns (bool removed){
        if (players.inserted[key]) {
            delete players.win[key];
            delete players.loose[key];
            delete players.excluded[key];
            delete players.inserted[key];
            uint index = players.indexOf[key];
            uint lastIndex = players.keys.length - 1;
            address lastKey = players.keys[lastIndex];
            players.indexOf[lastKey] = index;
            players.keys[index] = lastKey;
            delete players.indexOf[key];
            players.keys.pop();
            return true;
        }else{
            return false;
        }
    }
    
    function getIndexOfKey(Players storage players, address key) external view returns (int index) {
        if(!players.inserted[key]) {
            return -1;
        }
        return int(players.indexOf[key]);
    }
    function getKeyAtIndex(Players storage players, uint index) external view returns (address playerAddress) {
        return players.keys[index];
    }


    function incrementWin(Players storage players, address key) external returns(bool updated){
        if( !players.inserted[key] ){
            return false;
        }
        players.win[key] += 1;
        return true;
    }
    function incrementLoose(Players storage players, address key) external returns(bool updated){
        if( !players.inserted[key] ){
            return false;
        }
        players.loose[key] += 1;
        return true;
    }
    function updateExcluded(Players storage players, address key, bool excluded) external returns(bool updated){
        if( !players.inserted[key] || players.excluded[key] == excluded ){
            return false;
        }
        players.excluded[key] = excluded;
        return true;
    }
    function size(Players storage players) external view returns (uint length) {
        return players.keys.length;
    }
}
// File: contracts/ToshiGames/IterableCurrencies.sol


pragma solidity >=0.8.0;

/*
 * @dev 
 * This library is required to manage available currencies on ToshiGame
 *
 * The declaration of the variable is on "GameManager.sol"
 * Only BabyToshi owner can execute functions to create, update and delete
 * Everybody can execute readable functions.
 */
library IterableCurrencies {
    struct Currencies{
        address[] keys;
        mapping(address => bool) available;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }
    function get(Currencies storage currencies, address key) external view returns(address currency, bool available) {
        if( !currencies.inserted[key] ){
            return ( address(0), false );
        }
        return ( key, currencies.available[key] );
    }
    function getAll(Currencies storage currencies) external view returns(address[] memory currency, bool[] memory available) {
        uint _nTokens = currencies.keys.length;
        (address[] memory _currency, bool[] memory _available) = (new address[](_nTokens), new bool[](_nTokens));
        for(uint i=0; i < _nTokens; i++ ){
            address key = currencies.keys[i];
            _currency[i] = key;
            _available[i] = currencies.available[key];
        }
        return (_currency, _available);
    }
    
    function getAvailables(Currencies storage currencies) external view returns(address[] memory currency){
        uint _nTokens = currencies.keys.length;
        address[] memory _currency = new address[](_nTokens);
        for(uint i=0; i < _nTokens; i++ ){
            address key = currencies.keys[i];
            if( currencies.available[key] ){
                _currency[i] = key;
            }
        }
        return (_currency);
    }
    function isCurrency(Currencies storage currencies, address key) external view returns(bool _isCurrency){
        return currencies.inserted[key];
    }
    function add(Currencies storage currencies, address key) external returns(bool added){
        if( currencies.inserted[key] ){
            return false;
        }
        currencies.keys.push(key);
        currencies.available[key] = true;
        currencies.indexOf[key] = currencies.keys.length - 1;
        currencies.inserted[key] = true;
        
        return true;
    }

    function remove(Currencies storage currencies, address key) external returns (bool removed){
        if ( !currencies.inserted[key] ){
            return false;
        }
        delete currencies.available[key];
        delete currencies.inserted[key];
        uint index = currencies.indexOf[key];
        uint lastIndex = currencies.keys.length - 1;
        address lastKey = currencies.keys[lastIndex];
        currencies.indexOf[lastKey] = index;
        currencies.keys[index] = lastKey;
        delete currencies.indexOf[key];
        currencies.keys.pop();
        return true;
    }
    
    
    function getIndexOfKey(Currencies storage currencies, address key) external view returns (int index) {
        if(!currencies.inserted[key]) {
            return -1;
        }
        return int(currencies.indexOf[key]);
    }

    function getKeyAtIndex(Currencies storage currencies, uint index) external view returns (address key) {
        return currencies.keys[index];
    }
    
    function updateAddress(Currencies storage currencies, address key, address newKey) external returns(bool updated) {
        if( !currencies.inserted[key] ){
            return false;
        }
        uint index = currencies.indexOf[key];
        if( currencies.keys[index] == newKey ){
            return false;
        }
        currencies.keys[index] = newKey;
        return true;
    }
    
    function updateAvailable(Currencies storage currencies, address key, bool available) external returns(bool updated){
        if( !currencies.inserted[key]){
            return false;
        }
        if( currencies.available[key] == available ){
            return false;
        }
        currencies.available[key] = available;
        return true;
    }
    function size(Currencies storage currencies) external view returns (uint length) {
        return currencies.keys.length;
    }
}
// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol


pragma solidity >=0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol


pragma solidity >=0.8.0;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/ToshiGames/GameManager.sol


pragma solidity >=0.8.0;
//pragma experimental ABIEncoderV2;

//import {SafeMath} from "./SafeMath.sol";

//import {Tokens} from "./Tokens.sol";
//import {Users} from "./Users.sol";


//import {Users} from "./Users.sol";
//import {BetsFlip} from "./BetsFlip.sol";

contract GameManager {
    using SafeMath for uint256;
    //using Tokens for Tokens.Token;
    //using Tokens for Tokens.TokenMap;
    //using Users for Users.User;
    //using Users for Users.UserMap;
    using IterableCurrencies for IterableCurrencies.Currencies;
    using IterablePlayers for IterablePlayers.Players;
    
    IterableCurrencies.Currencies currencies;
    IterablePlayers.Players players;
    
    //Tokens.TokenMap tokens;
    //Users.UserMap users;

    address internal gameManager = address(this);
    address public owner;
    address public toshiGame;
    
    // list of initial tokens
    address internal babyToshi = address(0xE69d11c4f455E944cA95dB8a5B98399D2c7B466E); // TEST : 0xE69d11c4f455E944cA95dB8a5B98399D2c7B466E   --- REAL : 0xD2309BbD6Ec83D8B3341cE5b061ce378F45c2621
    address internal btcb = address(0x6ce8dA28E2f864420840cF74474eFf5fD80E65B8); // TEST : 0x6ce8dA28E2f864420840cF74474eFf5fD80E65B8   --- REAL : 0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c
    address internal bnb = address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd); // TEST : 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd   --- REAL : 0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c
    address internal eth = address(0xd66c6B4F0be8CE5b39D52E0Fd1344c389929B378); // TEST : 0xd66c6B4F0be8CE5b39D52E0Fd1344c389929B378   --- REAL : 0x2170Ed0880ac9A755fd29B2688956BD959F933F8
    address internal busd = address(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee); // TEST : 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee   --- REAL : 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    address internal usdt = address(0xA11c8D9DC9b66E209Ef60F0C8D969D3CD988782c); // TEST : 0xA11c8D9DC9b66E209Ef60F0C8D969D3CD988782c   --- REAL : 0x55d398326f99059fF775485246999027B3197955
    address internal usdc = address(0x64544969ed7EBf5f083679233325356EbE738930); // TEST :0x64544969ed7EBf5f083679233325356EbE738930    --- REAL : 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d
    address internal dai = address(0xEC5dCb5Dbf4B114C9d0F65BcCAb49EC54F6A0867); // TEST : 0xEC5dCb5Dbf4B114C9d0F65BcCAb49EC54F6A0867   --- REAL : 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3
    address internal xrp = address(0xa83575490D7df4E2F47b7D38ef351a2722cA45b9); // TEST : 0xa83575490D7df4E2F47b7D38ef351a2722cA45b9    --- REAL : 0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE
    address[] internal initialTokens = [babyToshi, btcb, bnb, eth, busd, usdt, usdc, dai, xrp];
    
    address[] internal eternalExcluded = [address(0), gameManager, babyToshi, btcb, bnb, eth, busd, usdt, usdc, dai, xrp];
    mapping(address => bool) internal excludedPlayers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddToken(address indexed gameManager, address indexed tokenAddress);
    event AddTokens(address indexed gameManager, address[] tokenAddresses);
    event UpdateToken(address indexed gameManager, address indexed tokenAddress, bool available);
    event RemoveToken(address indexed gameManager, address indexed tokenAddress);
    event RemoveTokens(address indexed gameManager, address[] tokenAddress);
    
    event AddUser(address indexed gameManager, address indexed player);
    event ExcludePlayer(address indexed gameManager, address indexed player);
    event IncludePlayer(address indexed gameManager, address indexed player);
    event ExcludePlayers(address indexed gameManager, address[] players);
    event IncludePlayers(address indexed gameManager, address[] players);
    event GetRandomIndex(address indexed gameManager, address indexed player, address random);
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender() || owner == _txOrigin(), "only callable by owner!");
        _;
    }
    
    /**
     * @dev Throws if called by the owner.
     */
    modifier notOwner() {
        require(owner != _msgSender() && owner != _txOrigin(), "not callable by owner!");
        _;
    }
    
     /**
     * @dev Throws if the token doesnt exist on the list
     */
    modifier onlyTokenExist(address tokenAddress) {
        require( currencies.isCurrency(tokenAddress), "Only existing token!");
        _;
    }
    
    /**
     * @dev Throws if the token already exists on the list
     */
    modifier notTokenExist(address tokenAddress) {
        require(!currencies.isCurrency(tokenAddress), "Not existing token!");
        _;
    }
    
    constructor(address _toshiGame) {
        owner = _txOrigin();
        toshiGame = _toshiGame;
        //this.addTokens(initialTokens);
        addCurrencies(initialTokens);
        excludePlayers(eternalExcluded);
        emit OwnershipTransferred(address(0), _txOrigin());
    }
    
    function isPlayer(address key) public view returns(bool) {
        return players.isPlayer(key);
    }
    
    function sizePlayers() public view returns(uint size) {
        return players.size();
    }

    function addPlayer(address key) public returns(bool added) {
        //bool transferredFrom = transferFromPlayer(babyToshiAddress, _msgSender(), enterPrice);
        //require(transferredFrom, "NOTa transfer register");
        bool _added = players.add(key);
        require(_added, "NOTa ADD");
        emit AddUser(gameManager, key);
        return _added;
    }
    function getPlayer(address key) public view returns(address player, uint256 win, uint256 loose, bool excluded) {
        return players.get(key);
    }
    function getRandomPlayer(address player) external virtual returns(address randomAddress) {
        address random = players.getRandom(player);
        emit GetRandomIndex(gameManager, player, random);
        return random;
    }

    function incrementWinPlayer(address key) public returns(bool incrementWin) {
        return players.incrementWin(key);
    }
    function incrementLoosePlayer(address key) public returns(bool incrementLoose) {
        return players.incrementLoose(key);
    }
    function isExcluded(address player) public view returns(bool) {
        return excludedPlayers[player];
    }
    /*
    function isUser(address player) public view returns(bool) {
        return users._isUser(player);
    }
    
    function sizeUsers() public view returns(uint size) {
        return users._size();
    }
    
    function isExcluded(address player) public view returns(bool) {
        return excludedPlayers[player];
    }
    
    function addUser(address player) public returns(bool added) {
        //bool transferredFrom = transferFromPlayer(babyToshiAddress, _msgSender(), enterPrice);
        //require(transferredFrom, "NOTa transfer register");
        bool _added = users._addUser(player);
        require(_added, "NOTa ADD");
        emit AddUser(gameManager, player);
        return _added;
    }
    */
    /*
    function getUser(address player) public view returns(Users.User memory user) {
        return users._getUser(player);
    }

    function incrementUserWin(address player) public returns(bool incrementWin) {
        return users._incrementWin(player);
    }
    function incrementUserLoose(address player) public returns(bool incrementLoose) {
        return users._incrementLoose(player);
    }
    */
    /**
     * @dev
     * Functions allow to create needed random data
     */
     /*
    function getRandomIndex(address player) external virtual returns(address randomAddress) {
        address random = users._getRandomPlayer(player);
        emit GetRandomIndex(gameManager, player, random);
        return random;
    }
    */
    
    /**
     * @dev
     * Useful functions to manage library ToshiTokens
     * Every users can execute this functions
     */
    function isCurrency(address tokenAddress) public virtual view returns(bool _isCurrency){
        return currencies.isCurrency(tokenAddress);
    }
    
    function getCurrency(address tokenAddress) external virtual view onlyTokenExist(tokenAddress) returns(address currency, bool available){
        return currencies.get(tokenAddress);
    }
    
    function getAvailableCurrencies() external virtual view returns(address[] memory currency){
        return currencies.getAvailables();
    }
    
    function getAllCurrencies() external virtual view onlyOwner returns(address[] memory currency, bool[] memory available){
        return currencies.getAll();
    }
    
    /*
    function getToken(address tokenAddress) external virtual view onlyTokenExist(tokenAddress) returns(Tokens.Token memory token){
        return tokens._getToken(tokenAddress);
    }

    function getAvailableTokens() external virtual view returns(Tokens.Token[] memory _tokens){
        return tokens._getAvailableTokens();
    }
    
    function getAllTokens() external virtual view onlyOwner returns(Tokens.Token[] memory _tokens){
        return tokens._getAllTokens();
    }
    */
    
    /**
     * @dev
     * Only the owner can execute this function
     * The price of token comes from aggregator or pancakeswap router.
     * This function add a token
     */
    function addCurrency(address tokenAddress) public onlyOwner notTokenExist(tokenAddress) returns(bool added) {
        bool _added = currencies.add(tokenAddress);
        require(_added, "GameManager: the token was already added!");
        //excludePlayer(tokenAddress);
        emit AddToken(gameManager, tokenAddress);
        return true;
    }
    
    function addCurrencies(address[] memory tokenAddresses) public onlyOwner returns(bool added) {
        for( uint i=0; i < tokenAddresses.length; i++ ){
            addCurrency(tokenAddresses[i]);
        }
        emit AddTokens(gameManager, tokenAddresses);
        return true;
    }
    /*
    function addToken(address tokenAddress) public onlyOwner notTokenExist(tokenAddress) returns(bool added) {
        bool _added = tokens._addToken(tokenAddress);
        require(_added, "DataAggregator: the token was already added!");
        emit AddToken(gameManager, tokenAddress);
        return true;
    }
    
    function addTokens(address[] memory tokenAddresses) public onlyOwner returns(bool added) {
        for( uint i=0; i < tokenAddresses.length; i++ ){
            this.addToken(tokenAddresses[i]);
        }
        emit AddTokens(gameManager, tokenAddresses);
        return true;
    }
    */
    /**
     * @dev
     * Only the owner can execute this function
     * The price of token comes from aggregator or pancakeswap router.
     * This function update a token
     */
     /*
    function updateToken(address tokenAddress, bool available) public virtual onlyOwner onlyTokenExist(tokenAddress) returns(bool updated) {
        bool _updated = tokens._setAvailable(tokenAddress, available);
        emit UpdateToken(gameManager, tokenAddress, available);
        return _updated;
    }
    */
    /**
     * @dev
     * Only the owner can execute this function
     * This function remove a token
     */
     /*
    function removeToken(address tokenAddress) public virtual onlyOwner onlyTokenExist(tokenAddress) returns(bool removed) {
        bool _removed = tokens._removeToken(tokenAddress);
        emit RemoveToken(gameManager, tokenAddress);
        return _removed;
    }
    
    function removeTokens(address[] memory tokenAddresses) public onlyOwner returns(bool added) {
        for( uint i=0; i < tokenAddresses.length; i++ ){
            removeToken(tokenAddresses[i]);
        }
        emit AddTokens(gameManager, tokenAddresses);
        return true;
    }
    */
    function excludePlayer(address player) public virtual onlyOwner returns(bool) {
        excludedPlayers[player] = true;
        emit ExcludePlayer(gameManager, player);
        return true;
    }
    function excludePlayers(address[] memory keys) public virtual onlyOwner returns(bool) {
        for( uint256 i=0; i < keys.length; i++ ){
            excludePlayer(keys[i]);
        }
        emit ExcludePlayers(gameManager, keys);
        return true;
    }

    function includePlayer(address player) public virtual onlyOwner returns(bool) {
        require(player != address(0), "WARNING CONTRACT BABYTOSHIOWNER (includePlayer): the zero address can't be included!");
        require(player != gameManager, "WARNING CONTRACT BABYTOSHIOWNER (includePlayer): the BabytoshiCoinFlip address can't be included!");
        require(!isCurrency(player), "WARNING CONTRACT BABYTOSHIOWNER (includePlayer): the babyToshiOwner address can't be included!");
        excludedPlayers[player] = false;
        emit IncludePlayer(gameManager, player);
        return true;
    }
    function includePlayers(address[] memory keys) public virtual onlyOwner returns(bool) {
        for( uint256 i=0; i < keys.length; i++ ){
            excludePlayer(keys[i]);
        }
        emit IncludePlayers(gameManager, keys);
        return true;
    }
    
    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        require(newOwner != address(0), "WARNING CONTRACT BABYTOSHIOWNER (transferOwnership): new owner is the zero address");
        require(newOwner != owner, "WARNING CONTRACT BABYTOSHIOWNER (transferOwnership): new owner is the same actual owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
// File: contracts/ToshiGames/Game.sol


pragma solidity >=0.8.0;
//pragma experimental ABIEncoderV2;

//import {SafeMath} from "./SafeMath.sol";

//import {ERC20} from "./ERC20.sol";


//import {IPancakeSwapV2Router02} from './IPancakeSwapV2Router.sol';
//import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

//import {IPancakeSwapV2Factory} from './IPancakeSwapV2Factory.sol';
//import {IPancakeSwapV2Pair} from './IPancakeSwapV2Pair.sol';
//import {Tokens} from "./Tokens.sol";
//import {Users} from "./Users.sol";

//import {IterableCurrencies} from "./IterableCurrencies.sol";
//import {DataAggregator} from "./DataAggregator.sol";
//import {ContextGame} from "./ContextGame.sol";


//import {IterableCurrencies} from "./IterableCurrencies.sol";

/*
 * @dev
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 
 * This contract is only required for intermediate, library-like contracts.
 *
 * This contract import contract DataAggregtor which import library Tokens
 * This contract import library Users
 */ 


contract Game {
    using SafeMath for uint256;
    //using IterableCurrencies for IterableCurrencies.Currencies;
    
    //IterableCurrencies.Currencies private currencies;
    
    receive() external payable {}
    fallback() external payable {}
    
    address public game = address(this);
    string public name;
    address public burnWallet = address(0x0122000000000122000000000012200000000bab); // excludeFromDividends and excludeFromFees must be true on contract BabyToshi !!!
    
    
    // variables from Babytoshi contract
    address public owner = address(0x200923193ed77BEAb040011580e89c66390CBBa2); //Test : 0x200923193ed77BEAb040011580e89c66390CBBa2   --- REAL : 0x91B5AF08EccC9c208738218b45726Bd6450C8025
    address internal babyToshiAddress = address(0xE69d11c4f455E944cA95dB8a5B98399D2c7B466E); //Test : 0x000823cD0C6f19369F5B78a13c14578F65DF881d   --- REAL : 0xD2309BbD6Ec83D8B3341cE5b061ce378F45c2621
    address internal marketingWallet = address(0x50F2E07131Cfbed5658aEc7AD52e83207DaC8DCD); //TEST: 0x50F2E07131Cfbed5658aEc7AD52e83207DaC8DCD   --- REAL : 0x61472ced7d1dea15d3ef3e30158006a4152e48b5
    address internal pancakeSwapRouterAddress = address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //Test : 0xD99D1c33F9fC3444f8101754aBC46c52416550D1   --- REAL : 0x10ed43c718714eb63d5aa57b78b54704e256024e
    uint256 internal gasForProcessing = 300_000;
    IUniswapV2Router02 internal pancakeswapV2Router = IUniswapV2Router02(pancakeSwapRouterAddress);
    ERC20 internal babyToshi = ERC20(babyToshiAddress); //Test : 0x000823cD0C6f19369F5B78a13c14578F65DF881d   --- REAL : 0xD2309BbD6Ec83D8B3341cE5b061ce378F45c2621
    ERC20 internal btcb = ERC20(0x6ce8dA28E2f864420840cF74474eFf5fD80E65B8); // TEST: 0x6ce8dA28E2f864420840cF74474eFf5fD80E65B8   --- REAL:0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c
    ERC20 public bnb = ERC20(pancakeswapV2Router.WETH()); // 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd   --- REAL : 0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c
    
    // variables can be update
    uint256 public registerAmount = uint256(1_000_000).mul(10**uint256(babyToshi.decimals())); // ~0.10cts
    uint256 internal marketingFeeRegister = 10; // 10% in percentage
    uint256 internal burnFeeRegister = 40; // 40% in percentage
    uint256 internal liquidityFeeRegister = 50; // 50% in percentage
    
    address[] internal eternalExcluded = [game, owner, burnWallet, marketingWallet, pancakeSwapRouterAddress];
    mapping(address => mapping(address => uint256)) internal marketingBalances; // bet / token = amount
    uint256 internal burnBalance; // bet / token = amount
    
    GameManager public gameManager;
    
    modifier onlyOwner() {
        require(owner == _msgSender(), "only callable by owner!");
        _;
    }
    
    modifier notOwner() {
        require(owner != _msgSender(), "not callable by owner!");
        _;
    }
    /**
     * @dev Throws if the token doesnt exist on the list
     */
    modifier onlyTokenExist(address tokenAddress) {
        require( gameManager.isCurrency(tokenAddress), "Only existing token!");
        _;
    }
    
    /**
     * @dev Throws if the token already exists on the list
     */
    modifier notTokenExist(address tokenAddress) {
        require(!gameManager.isCurrency(tokenAddress), "Not existing token!");
        _;
    }
    
    modifier onlyPlayers() {
        require(gameManager.isPlayer(_msgSender()), "only callable by players!");
        _;
    }
    
    modifier notPlayers() {
        require(!gameManager.isPlayer(_msgSender()), "only callable by new player!");
        _;
    }
    
    modifier notExcluded() {
        require(!gameManager.isExcluded(_msgSender()), "excluded player can't execute this function!");
        _;
    }
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event GiveAwayRandomPlayer(address indexed randomPlayer, address indexed tokenAddress, uint256 amount);
    event ManageRegisterFee(address indexed babyToshiAddress, address indexed game, address indexed player, uint256 registerAmount);
    event Register(address indexed game, address indexed player);
    event SwapTokensForBnb(address indexed tokenAddress, uint256 tokenAmount, address indexed receiver);
    event AddLiquidity(address indexed babyToshiAddress, uint256 tokenAmount, uint256 bnbAmount);
    event Burn(address indexed babyToshiAddress, address indexed game, address indexed burnWallet, uint256 amount);
    event ApprovePlayer(address indexed betCurrencyAddress, address indexed player, uint256 amount, bool approved);
    event Transfer(address indexed token, address indexed sender, address indexed receiver, uint256 amount, bool transferred);

    constructor(string memory _name) /*ContextGame(_name)*/ onlyOwner {
        require(bytes(_name).length > 0, "add a valid name!");
        name = _name;
        //gameManager = new GameManager(game);
        //transferOwnership(_txOrigin());
        //babyToshiOwner = _msgSender();
        //emit OwnershipTransferred(address(0), _msgSender());
        //dataAggregator.initDataAggregator();
        //--------------------------------------------- USERS PART ---------------------------------------------//
        //users.dataAggregator = dataAggregator;
        //excludePlayers(eternalExcluded);
        emit OwnershipTransferred(address(0), _msgSender());
    }
    
    function getCurrencies() public virtual view returns(address[] memory currencies){
        return gameManager.getAvailableCurrencies();
    }
    
    function sizePlayers() public view returns(uint size) {
        return gameManager.sizePlayers();
    }
    
    function excludePlayer(address player) public virtual onlyOwner returns(bool) {
        return gameManager.excludePlayer(player);
    }
    
    function excludePlayers(address[] memory players) public virtual onlyOwner returns(bool) {
        return gameManager.excludePlayers(players);
    }

    function includePlayer(address player) public virtual onlyOwner returns(bool) {
        require(player != game, "WARNING CONTRACT BABYTOSHIOWNER (includePlayer): the zero address can't be included!");
        require(player != owner, "WARNING CONTRACT BABYTOSHIOWNER (includePlayer): the BabytoshiCoinFlip address can't be included!");
        require(player != burnWallet, "WARNING CONTRACT BABYTOSHIOWNER (includePlayer): the BABYTOSHI address can't be included!");
        require(player != marketingWallet, "WARNING CONTRACT BABYTOSHIOWNER (includePlayer): the babyToshiOwner address can't be included!");
        require(!gameManager.isCurrency(player), "WARNING CONTRACT BABYTOSHIOWNER (includePlayer): the babyToshiOwner address can't be included!");
        return gameManager.includePlayer(player);
    }
    function includePlayers(address[] memory players) public virtual onlyOwner returns(bool) {
        return gameManager.includePlayers(players);
    }
    
    function manageRegisterFee() private {
        uint256 balanceMarketing = registerAmount.mul(marketingFeeRegister).div(100);
        uint256 balanceBurn = registerAmount.mul(burnFeeRegister).div(100);
        uint256 balanceLiquidity = registerAmount.mul(liquidityFeeRegister).div(100);
        
        uint256 attemptBalanceBurn = babyToshi.balanceOf(game).sub(registerAmount);
        
        bool marketingSwapped = swapTokensForBnb(babyToshiAddress, balanceMarketing, marketingWallet);
        require(marketingSwapped, "no transfer bnb marketing");
        
        bool liquidityAdded = addLiquidity(balanceLiquidity);
        require(liquidityAdded, "no liquidity added");
        
        bool burned = burn(balanceBurn);
        require(burned, "NON burn tokens");
        
        uint256 balanceGiveAway = babyToshi.balanceOf(game).sub(attemptBalanceBurn);

        if( sizePlayers() > 0 && balanceGiveAway > 0 ){
            bool gave = giveAwayRandomPlayer(babyToshiAddress, balanceGiveAway);
            require(gave, "not random");
        }
        
        emit ManageRegisterFee(babyToshiAddress, game, _msgSender(), registerAmount);
    }
    
    
    /*
    function distributeGifts() public onlyOwner returns(bool) {
        if( giveAwayKeys.length == 0 ){
            return false;
        }
        
        for( uint i=0; i < balancesGiveAway[babyToshiAddress].length; i++ ){
            //address tokenAddress = 
            //giveAwayRandomPlayer(babyToshiAddress, balanceGiveAway);
        }
        return true;
    }
    */
    
    function giveAwayRandomPlayer(address tokenAddress, uint256 amount) internal returns(bool) {
        address randomPlayer = gameManager.getRandomPlayer(_msgSender());
        bool transferredToRandom = transferToPlayer(tokenAddress, randomPlayer, amount);
        require(transferredToRandom, "NON transfer tokens random");
        emit GiveAwayRandomPlayer(randomPlayer, tokenAddress, amount);
        return true;
    }
    
    
    function burn(uint256 burnAmount) internal returns(bool) {
        bool burned = transferToPlayer(babyToshiAddress, burnWallet, burnAmount);
        require(burned, "not burn");
        emit Burn(babyToshiAddress, game, burnWallet, burnAmount);
        return burned;
    }
    
    function amountBurned() public view returns(uint256){
        return babyToshi.balanceOf(burnWallet);
    }
    
    function register() public notOwner notPlayers notExcluded {
        bool transferredFrom = transferFromPlayer(babyToshiAddress, _msgSender(), registerAmount);
        require(transferredFrom, "NOTa transfer register");
        bool _add = gameManager.addPlayer(_msgSender());
        require(_add, "NOTa ADD");
        manageRegisterFee();
        emit Register(game, _msgSender());
    }
    
    function approvePlayer(address tokenAddress, address player, uint256 amount) internal returns (bool){
        (bool approved,) = tokenAddress.call(abi.encodeWithSignature("approve(address,uint256)", player, amount));
        emit ApprovePlayer(tokenAddress, player, amount, approved);
        return approved;
    }
    
    function transferToPlayer(address tokenAddress, address player, uint256 amount) internal returns (bool){
        bool approved = approvePlayer(tokenAddress, player, amount);
        require(approved, "CONTEXT: this player was not approved!");
        uint256 allowance = ERC20(tokenAddress).allowance(game, player);
        require(allowance > 0 && allowance >= amount, "allowance game not enough!");
        uint256 balance = ERC20(tokenAddress).balanceOf(game);
        require(balance > 0 && balance >= amount, "balance game not enough!");
        (bool transferred,) = tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", player, amount));
        require(transferred, "CONTEXT: the amount to this player was not transfered!");
        emit Transfer(tokenAddress, game, player, amount, transferred);
        return true;
    }
    
    function transferFromPlayer(address tokenAddress, address player, uint256 amount) internal returns (bool){
        uint256 allowance = ERC20(tokenAddress).allowance(player, game);
        require(allowance > 0 && allowance >= amount, "allowance player not enough!");
        uint256 balance = ERC20(tokenAddress).balanceOf(player);
        require(balance > 0 && balance >= amount, "balance player not enough!");
        (bool transferred,) = tokenAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", player, game, amount));
        require(transferred, "CONTEXT: the amount from this player was not transfered!");
        emit Transfer(tokenAddress, player, game, amount, transferred);
        return true;
    }
    
    function swapTokensForBnb(address tokenAddress, uint256 tokenAmount, address receiver) internal returns (bool){
        // generate the uniswap pair path of token -> weth
        
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = pancakeswapV2Router.WETH();

        ERC20(babyToshiAddress).approve(pancakeSwapRouterAddress, tokenAmount);
        //babyToshiAddress.call{gas: gasForProcessing}(abi.encodeWithSignature("approve(address,uint256)", address(pancakeswapV2Router), tokenAmount));
        //approvePlayer(babyToshiAddress, pancakeSwapRouterAddress, tokenAmount);
        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            receiver,
            block.timestamp
        );
        emit SwapTokensForBnb(tokenAddress, tokenAmount, receiver);
        return true;
    }
    
    function addLiquidity(uint256 tokenAmount) internal returns (bool){
        // approve token transfer to cover all possible scenarios
        //ERC20(babyToshiAddress).approve(pancakeSwapRouterAddress, tokenAmount);
        //approvePlayer(babyToshiAddress, pancakeSwapRouterAddress, tokenAmount);
        
        uint256 half = tokenAmount.div(2);
        uint256 otherHalf = tokenAmount.sub(half);
        
        uint256 initialBalance = address(this).balance;
        bool swap = swapTokensForBnb(babyToshiAddress, half, address(this)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        require(swap, "non swap liquidity");
        uint256 newBalance = address(this).balance.sub(initialBalance);
        require(newBalance > 0, "no balance");
        
        bool added = _addLiquidity(half, newBalance);
        require(added, "liquidity not added!");
        emit AddLiquidity(babyToshiAddress, otherHalf, newBalance);
        return true;
    }
    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) internal returns (bool){
        // approve token transfer to cover all possible scenarios
        ERC20(babyToshiAddress).approve(pancakeSwapRouterAddress, tokenAmount);
        //approvePlayer(babyToshiAddress, pancakeSwapRouterAddress, tokenAmount);
        
        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value: bnbAmount}(
            babyToshiAddress,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
        return true;
    }
    
    function setRegisterAmount(uint256 amount) public onlyOwner {
        require(amount > 0 && amount != registerAmount, "enter valid amount!");
        registerAmount = amount;
    }
    function setMarketingFee(uint256 amount) public onlyOwner {
        require(amount > 0 && amount != marketingFeeRegister, "enter valid marketing fee!");
        uint256 totalFee = burnFeeRegister.add(liquidityFeeRegister).add(amount);
        require(totalFee <= 100, "enter valid marketing fee!");
        marketingFeeRegister = amount;
    }
    function setBurnFee(uint256 amount) public onlyOwner {
        require(amount > 0 && amount != burnFeeRegister, "enter valid burn fee!");
        uint256 totalFee = marketingFeeRegister.add(liquidityFeeRegister).add(amount);
        require(totalFee <= 100, "enter valid burn fee!");
        burnFeeRegister = amount;
    }
    function setLiquidityFee(uint256 amount) public onlyOwner {
        require(amount > 0 && amount != liquidityFeeRegister, "enter valid liquidity fee!");
        uint256 totalFee = marketingFeeRegister.add(burnFeeRegister).add(amount);
        require(totalFee <= 100, "enter valid liquidity fee!");
        liquidityFeeRegister = amount;
    }
    

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        require(newOwner != address(0), "WARNING CONTRACT BABYTOSHIOWNER (transferOwnership): new owner is the zero address");
        require(newOwner != owner, "WARNING CONTRACT BABYTOSHIOWNER (transferOwnership): new owner is the same actual owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
// File: contracts/ToshiGames/CoinFlip.sol


pragma solidity >=0.8.0;
//pragma experimental ABIEncoderV2;

//import {SafeMath} from "./SafeMath.sol";

//import {ERC20} from "./ERC20.sol";


//import {Tokens} from "./Tokens.sol";
//import {Users} from "./Users.sol";
//import {BetsFlip} from "./BetsFlip.sol";

//import {ContextGames} from "./ContextGames.sol";



//import {IterableCurrencies} from "./IterableCurrencies.sol";

/*
 * @dev
 * This contract is derived by contract ContextGames
 * This contract import library Users
 */ 
contract CoinFlip is Game {
    using SafeMath for uint256;
    using IterableFlips for IterableFlips.Flips;
    using IterableFlips for IterableFlips.Flip;
    //using Tokens for Tokens.Token;
    //using Tokens for Tokens.TokenMap;
    //using Users for Users.User;
    //using Users for Users.UserMap;
    //using BetsFlip for BetsFlip.Bet;
    //using BetsFlip for BetsFlip.BetMap;
    //using IterableCurrencies for IterableCurrencies.Currencies;
    
    //IterableCurrencies.Currencies internal currencies;

    //BetsFlip.BetMap internal bets;
    IterableFlips.Flips private flips;
    
    uint256 internal toshiFeeBet = 25; // 2.5% ---> 25 / 1000
    
    uint256 internal defaultExpirationBet = block.timestamp + 24 hours; // 1 day
    
    mapping(address => mapping(address => uint256)) internal balancesBets; // bet / token = amount
    
    
    modifier onlyPlayerOne(address betAddress) {
        require(flips.get(betAddress).player1 == _msgSender(), "TOSHIFLIP_OWNER: only player one!");
        _;
    }
    
    modifier notPlayerOne(address betAddress) {
        require(flips.get(betAddress).player1 != _msgSender(), "TOSHIFLIP_OWNER: not player one!");
        _;
    }
    
    modifier onlyBetExist(address betAddress) {
        require(flips.isFlip(betAddress), "TOSHIFLIP_OWNER: only exist bet!");
        _;
    }
    
    modifier notExpired(address betAddress) {
        require(block.timestamp < flips.get(betAddress).expiration, "TOSHIFLIP_OWNER: not expired!");
        _;
    }
    

    event CreateBet(address indexed toshiGame, address indexed betAddress, address indexed player, address currency, uint256 amount, bool choice);
    event CancelBet(address indexed toshiGame, address indexed betAddress, address indexed player, address currency, uint256 amount);
    event JoinBet(address indexed toshiGame, address indexed betAddress, address indexed player, address currency, uint256 amount, bool choice);
    event DoBet(address indexed toshiGame, address indexed betAddress, address indexed winner, address currency, uint256 amountWin);
    
    constructor() Game("CoinFlip") {
        gameManager = new GameManager(game);
        excludePlayers(eternalExcluded);
        //name = "CoinFlip";
        //dataAggregator = new DataAggregator(babyToshiAddress, owner);
        //--------------------------------------------- TOKENS PART ---------------------------------------------//
        //dataAggregator.initDataAggregator();
        //--------------------------------------------- BETS PART ---------------------------------------------//
        //bets.dataAggregator = dataAggregator;
        //--------------------------------------------- USERS PART ---------------------------------------------//
        //users.dataAggregator = dataAggregator;
        //excludePlayers(eternalExcluded);
    }
    
    //0xE69d11c4f455E944cA95dB8a5B98399D2c7B466E, 1000000000000000000000000, true
    //0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee, 1000000000000000000, true
    
    function createBet(address currency, uint256 amount, bool choice) public onlyPlayers notExcluded onlyTokenExist(currency) {
        //require( gameManager.isCurrency(currency), "only existing token!");
        bool transferredFrom = transferFromPlayer(currency, _msgSender(), amount);
        require(transferredFrom, "NOTa transfer create bet");
        //Users.User memory user = gameManager.getUser(_msgSender());
        address betAddress = flips.add(_msgSender(), currency, amount, choice, defaultExpirationBet);
        require(betAddress != address(0), "BET not add bets");
        //bool betAdded = gameManager.addUserBet(user.key, betAddress);
        //require(betAdded, "bet not added users");
        balancesBets[betAddress][currency] += amount;
        emit CreateBet(game, betAddress, _msgSender(), currency, amount, choice);
        //return true;
    }
    
    //0x1ec79864f3890331A221F1060Dfe5E22e5Ff56dF, 1000000000000000000000000, true
    function joinBet(address betAddress, address currency, uint256 amount, bool choice) public onlyBetExist(betAddress) onlyPlayers notPlayerOne(betAddress) notExcluded onlyTokenExist(currency) notExpired(betAddress) {
        IterableFlips.Flip memory bet = getBet(betAddress);
        require(currency == bet.token, "currency not the same join bet");
        require(amount == bet.amount, "amount not the same join bet");
        bool transferredFrom = transferFromPlayer(currency, _msgSender(), amount);
        require(transferredFrom, "NOTa transfer join bet");
        //Users.User memory user = gameManager.getUser(_msgSender());
        bool betJoined = flips.join(bet.key, _msgSender(), choice);
        require(betJoined, "BET not joined bets");
        //bool betAdded = gameManager.addUserBet(user.key, bet.key);
        //require(betAdded, "bet not added users");
        balancesBets[bet.key][bet.token] += amount;
        emit JoinBet(game, betAddress, _msgSender(), bet.token, bet.amount, choice);
        uint256 balanceWinner = doBet(betAddress);
        require(balanceWinner > 0, "the bet was not done");
        emit DoBet(game, betAddress, bet.winner, bet.token, balanceWinner);
    }
    
    function doBet(address betAddress) internal onlyBetExist(betAddress) onlyPlayers notPlayerOne(betAddress) notExcluded notExpired(betAddress) returns(uint256 balanceWinner) {
        IterableFlips.Flip memory bet = getBet(betAddress);
        address winner = flips.pickWinner(bet.key);
        require(winner != address(0), "no winner");
        gameManager.incrementWinPlayer(winner);
        if( winner == bet.player1 ){
            gameManager.incrementLoosePlayer(bet.player2);
        }else{
            gameManager.incrementLoosePlayer(bet.player1);
        }
        uint256 balanceBet = balancesBets[bet.key][bet.token];
        uint256 balanceMarketing = balanceBet.mul(toshiFeeBet).div(1_000);
        bool transferredTo = transferToPlayer(bet.token, marketingWallet, balanceMarketing);
        require(transferredTo, "NOTa transfer marketing dobet");
        uint256 _balanceWinner = balanceBet.sub(balanceMarketing);
        transferredTo = transferToPlayer(bet.token, winner, _balanceWinner);
        require(transferredTo, "NOTa transfer winner dobet");
        delete balancesBets[bet.key][bet.token];
        //emit DoBet(bet.key, bet.winner, bet.token.key, balanceWinner);
        return _balanceWinner;
    }
    
    function cancelBet(address betAddress) public onlyBetExist(betAddress) onlyPlayerOne(betAddress){
        IterableFlips.Flip memory bet = getBet(betAddress);
        uint256 balanceBet = balancesBets[bet.key][bet.token];
        require(balanceBet > 0 && balanceBet >= bet.amount, "balance not enough cancel");
        bool transferredTo = transferToPlayer(bet.token, _msgSender(), balanceBet);
        require(transferredTo, "NOTa transfer cancel bet");
        
        bool betRemoved = flips.remove(bet.key);
        require(betRemoved, "BET not removed bets");
        //Users.User memory user = gameManager.getUser(_msgSender());
        //bool betRemovedPlayer = gameManager.removeUserBet(user.key, bet.key);
        //require(betRemovedPlayer, "bet not emovedusers");
        delete balancesBets[bet.key][bet.token];
        emit CancelBet(game, betAddress, bet.player1, bet.token, bet.amount);
       // return true;
    }
    
    function getBet(address betAddress) internal virtual view returns(IterableFlips.Flip memory bet){
        return flips.get(betAddress);
    }
    
    function getBets() public virtual view returns(IterableFlips.Flip[] memory _bets){
        return flips.getAvailables();
    }
    
    function getMyBets() public view onlyPlayers returns(IterableFlips.Flip[] memory _bets) {
        return flips.getPlayerFlips(_msgSender());
    }
    
    function sizeBets() public view returns(uint size) {
        return flips.size();
    }
}