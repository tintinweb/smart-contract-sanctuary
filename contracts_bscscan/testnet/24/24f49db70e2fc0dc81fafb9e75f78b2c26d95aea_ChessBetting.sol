/**
 *Submitted for verification at BscScan.com on 2021-09-13
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
        uint level;
        address[2] players;
        address winner;
    }

    /**
   * @dev Indicates that the contract has been initialized.
   */
    bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
    bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    modifier isOwner() {
        require(msg.sender == owner, "only owner can do it");
        _;
    }

    function setWinner(string memory _gameId, address addr) public isOwner {
        checkPermissions(_gameId, addr);
        require(games[_gameId].winner == 0x0000000000000000000000000000000000000000, "Winner already selected");
        games[_gameId].winner = addr;
        if (games[_gameId].betAmount > 0) {
            uint betX = games[_gameId].betAmount;
            uint burn = betX / 100 * 20;
            _token.transferFrom(address(this), 0x0000000000000000000000000000000000000000, burn);
            _token.transferFrom(address(this), addr, betX - burn);
        }
      
    }


    function setOwner(address addr) public isOwner {
        owner = addr;
}

    function initialize(IERC20 token) external initializer {
        _token = token;
        owner = msg.sender;
    }

    function bet(string memory _gameId, uint _level, uint _betamount) public {
        require(_betamount >= 0, "fees not good"); 
        address from = msg.sender;
        if (_betamount > 0) {
            _token.transferFrom(from, address(this), _betamount);
        }
        if (games[_gameId].level > 1) {
            games[_gameId].players[1] = from;
            games[_gameId].betAmount = games[_gameId].betAmount + _betamount;
        }else {
            games[_gameId] = Game(_betamount, _level, [from, 0x0000000000000000000000000000000000000000], 0x0000000000000000000000000000000000000000);
        
        }    
    }
    
    function checkPermissions(string memory _gameId, address sender) private view {
     //only the originator or taker can call this function
        require(sender == games[_gameId].players[0] || sender == games[_gameId].players[1], "address not good");  
    }

    
    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
    cs := extcodesize(self)
  }(self);
        return cs == 0;
    }     
}