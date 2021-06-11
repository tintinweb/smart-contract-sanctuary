/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

/*
SPDX-License-Identifier: CC-BY-4.0
(c) Desenvolvido por Jeff Prestes
This work is licensed under a Creative Commons Attribution 4.0 International License.
*/

pragma solidity 0.8.4;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/// @title Manages the contract owner
contract Owned {
    address payable contractOwner;

    constructor() { 
        contractOwner = payable(msg.sender); 
    }
    
    function whoIsTheOwner() public view returns(address) {
        return contractOwner;
    }
}

/// @title Mortal allows the owner to kill the contract
contract Mortal is Owned  {
    function kill() public {
        require(msg.sender==contractOwner, "Only owner can destroy the contract");
        selfdestruct(contractOwner);
    }
}

/// @title ERC-20 Token template
contract TicketERC20 is IERC20, Mortal {
    string private myName;
    string private mySymbol;
    uint256 private myTotalSupply;
    uint256 public decimals;

    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) ownerAllowances;

    constructor() {
        myName = "Ficha de Chocolate";
        mySymbol = "CHOCO1";
        decimals = 2;
        _mint(msg.sender, (46 * (10 ** decimals)));
    }

    function name() public view returns(string memory) {
        return myName;
    }

    function symbol() public view returns(string memory) {
        return mySymbol;
    }

    function totalSupply() public override view returns(uint256) {
        return myTotalSupply;
    }

    function balanceOf(address tokenOwner) public override view returns(uint256) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns(uint256) {
        return ownerAllowances[tokenOwner][spender];
    }

    function transfer(address to, uint256 amount) public override  hasEnoughBalance(msg.sender, amount) tokenAmountValid(amount) returns(bool) {
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    } 

    function approve(address spender, uint limit) public override returns(bool) {
        ownerAllowances[msg.sender][spender] = limit;
        emit Approval(msg.sender, spender, limit);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override 
    hasEnoughBalance(from, amount) isAllowed(msg.sender, from, amount) tokenAmountValid(amount)
    returns(bool) {
        balances[from] = balances[from] - amount;
        balances[to] += amount;
        ownerAllowances[from][msg.sender] = amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        myTotalSupply = myTotalSupply + amount;
        balances[account] = balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }
    
    function purchase() public payable {
        require(msg.value >= 10 gwei);
        transfer(msg.sender, 100);
        //                   1,00
        contractOwner.transfer(msg.value);
    }

    modifier hasEnoughBalance(address owner, uint amount) {
        uint balance;
        balance = balances[owner];
        require (balance >= amount); 
        _;
    }

    modifier isAllowed(address spender, address tokenOwner, uint amount) {
        require (amount <= ownerAllowances[tokenOwner][spender]);
        _;
    }

    modifier tokenAmountValid(uint256 amount) {
        require(amount > 0);
        require(amount <= myTotalSupply);
        _;
    }

}