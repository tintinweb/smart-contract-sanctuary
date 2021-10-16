/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

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

interface IOldTreasury {
    function withdraw( uint _amount, address _token ) external;

    function mint( address _recipient, uint _amount ) external;
    
    function manage( address _token, uint _amount ) external;

    function excessReserves() external view returns ( uint );
}

interface INewTreasury {
    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint send_ );
    
    function valueOfToken( address _token, uint _amount ) external view returns ( uint value_ );
}

interface IRouter {
    function addLiquidity(
        address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline
        ) external returns (uint amountA, uint amountB, uint liquidity);
        
    function removeLiquidity(
        address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline
        ) external returns (uint amountA, uint amountB);
}


contract OlympusTokenMigration {

    struct Token {
        address token;
        bool reserveToken;
    }

    address immutable public DAO;
    address immutable public DAI;
    address immutable public oldOHM;
    address immutable public newOHM;
    address immutable public sushiRouter;
    address immutable public oldOHMDAISLP;
    address immutable public oldTreasury;
    address immutable public newTreasury;

    Token[] public tokens;

    constructor(address _DAO, address _DAI, address _oldOHM, address _newOHM, address _sushiRouter, address _oldOHMDAISLP, address _oldTreasury, address _newTreasury) {
        require( _DAO != address(0) );
        DAO = _DAO;
        
        require( _DAI != address(0) );
        DAI = _DAI;

        require( _oldOHM != address(0) );
        oldOHM = _oldOHM;

        require( _newOHM != address(0) );
        newOHM = _newOHM;

        require( _sushiRouter != address(0) );
        sushiRouter = _sushiRouter;

        require( _oldOHMDAISLP != address(0) );
        oldOHMDAISLP = _oldOHMDAISLP;

        require( _oldTreasury != address(0) );
        oldTreasury = _oldTreasury;

        require( _newTreasury != address(0) );
        newTreasury = _newTreasury;
    }

    /**
    *   @notice Migrate OHM/DAI SLP and tokens to new treasury
    */
    // function migrate() external {
    //     require(msg.sender == DAO);

    //     _migrateLP();
    //     _migrateTokens();
    // }

    /**
    *   @notice adds tokens to tokens array
    *   @param _tokens address[]
    *   @param _reserveToken bool[]
    */
    function addTokens( address[] memory _tokens, bool[] memory _reserveToken  ) external {
        require(msg.sender == DAO);
        require(_tokens.length == _reserveToken.length);

        for( uint i = 0; i < _tokens.length; i++ ) {
            tokens.push( Token({
                token: _tokens[i],
                reserveToken: _reserveToken[i]
            }));
        }

    }

    /**
    *   @notice Migrates tokens from old treasury to new treasury
    */
    function migrateTokens() external {
        require(msg.sender == DAO);

        for( uint i = 0; i < tokens.length; i++ ) {
            Token memory _token = tokens[i];

            uint balance = IERC20(_token.token).balanceOf( oldTreasury );
            IOldTreasury(oldTreasury).manage( _token.token, balance );

            if(_token.reserveToken) {
                uint excessReserves = IOldTreasury(oldTreasury).excessReserves();
                uint tokenValue = INewTreasury(newTreasury).valueOfToken(_token.token, balance);

                if ( tokenValue > excessReserves ) {
                    tokenValue = excessReserves;
                    balance = excessReserves * 10 ** 9;
                }

                IERC20(_token.token).approve(newTreasury, balance);
                INewTreasury(newTreasury).deposit(balance, _token.token, tokenValue);
            } else {
                IERC20(_token.token).transfer( newTreasury, balance );
            }
        }
    }
    
    /**
    *   @notice Migrates OHM/DAI SLP to new OHM contract
    */
    function migrateLP() external {
        require(msg.sender == DAO);

        uint oldLPAmount = IERC20(oldOHMDAISLP).balanceOf(oldTreasury);
        IOldTreasury(oldTreasury).manage(oldOHMDAISLP, oldLPAmount);
        
        IERC20(oldOHMDAISLP).approve(sushiRouter, oldLPAmount);
        (uint amountA, uint amountB) = IRouter(sushiRouter).removeLiquidity(DAI, oldOHM, oldLPAmount, 0, 0, address(this), 1000000000000);
        
        IERC20(oldOHM).approve(oldTreasury, amountB);
        IOldTreasury(oldTreasury).withdraw(amountB, DAI);
        
        IERC20(DAI).approve(newTreasury, amountB * 10 ** 9);
        INewTreasury(newTreasury).deposit(amountB * 10 ** 9, DAI, 0);
        
        IERC20(DAI).approve(sushiRouter, amountA);
        IERC20(newOHM).approve(sushiRouter, amountB);

        IRouter(sushiRouter).addLiquidity(newOHM, DAI, amountB - 1, amountA - 1, 0, 0, newTreasury, 100000000000);
    }
}