/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

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

// File: contracts/Sample.sol


pragma solidity ^0.8.7;


contract Sample {
     
    mapping(string => mapping(string => Liquidity)) private machines;
    
    struct Liquidity {
        IERC20 token;
        uint256 amountInWei;
    }
    
    Liquidity game;
    
    event MachineGameLiquidityReceived(string machineId, string gameId, address from, uint amount);
    
    /**
     * @dev Adds liquidity to a machine game.
     */ 
    function addLiquidityToMachineGame(string memory machineId, string memory gameId, IERC20 _token) public payable {
       require(_token.allowance(msg.sender, address(this)) >= msg.value, "You must execute approve on the token for the desired amount before adding liquidity!");
       require(_token.balanceOf(msg.sender) >= msg.value, "You do not have enough funds!");
       _token.transferFrom(msg.sender, address(this), msg.value);
       machines[machineId][gameId] = Liquidity(_token, msg.value);
       emit MachineGameLiquidityReceived(machineId, gameId, msg.sender, msg.value);
    }
    
    /**
     * @dev Gets the Liquidity Remaining for specific game and machine
     */
    function getMachineGameRemainingLiquidity(string memory machineId, string memory gameId) public view returns (uint256) {
        return machines[machineId][gameId].amountInWei;
    }
    
    /**
     * @dev Gets the active token being used for the specific machine and game 
     */ 
    function getMachineGameActiveToken(string memory machineId, string memory gameId) public view returns (IERC20) {
        return machines[machineId][gameId].token;
    }
}