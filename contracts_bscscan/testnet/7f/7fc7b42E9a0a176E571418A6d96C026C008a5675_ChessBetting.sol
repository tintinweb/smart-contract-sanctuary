/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// SPDX-License-Identifier: MIT

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.7;

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

// File: contracts/ChessBetting.sol



// pragma solidity 0.8.7;


contract ChessBetting {
    mapping(string => Game) public games;
    address public owner;
    IERC20 private _token;
    
    struct Game {
        uint256 betAmount;
        uint256 level;
        address player1;
        address player2;
        address winner;
    }

    modifier isOwner() {
        require(msg.sender == owner, "only owner can do it");
        _;
    }

    function setWinner(string memory _gameId, address addr) public isOwner {
        checkPermissions(_gameId, addr);
        require(games[_gameId].winner == address(0), "Winner already selected");
        uint betAmount = games[_gameId].betAmount;
        uint burn = betAmount / 100 * 20;
        uint prize = betAmount - burn;
            
            games[_gameId].winner = addr;
            require(_token.transfer( addr, prize));
            require(_token.transfer( owner, burn / 2));
        
    }


    function setOwner(address addr) public isOwner {
        owner = addr;
}

    constructor(IERC20 token)  {
        _token = token;
        owner = msg.sender;
    }

    function bet(string memory _gameId, uint _level, uint _betamount) public {
        require(_betamount >= 0, "fees not good"); 
        address from = msg.sender;
           require( _token.transferFrom(from, address(this), _betamount));
        uint betAmount = games[_gameId].betAmount;
        if (betAmount > 1) {
            games[_gameId].player2 = from;
            games[_gameId].betAmount = betAmount + _betamount;
        }else {
            games[_gameId] = Game(_betamount, _level, from, address(0), address(0));
        
        }    
    }
    
    function checkPermissions(string memory _gameId, address sender) private view {
     //only the originator or taker can call this function
        require(sender == games[_gameId].player1 || sender == games[_gameId].player2, "address not good");  
    }

          
}