/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// File: contracts/ERC20Int.sol


pragma solidity >=0.4.22 <0.9.0;

interface ERC20Int {
    /**
     * Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     *  Sets `amount` as the allowance of `spender` over the caller's tokens.
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
     *  Moves `amount` tokens from `sender` to `recipient` using the
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

// File: contracts/GenToken.sol

pragma solidity >=0.4.22 <0.9.0;



contract GenToken is ERC20Int{

    //mapping(spender=>allownace)
    mapping (address=>uint256) public _balances;

    //mapping(owner=>mapping(spender,allowance))
    mapping (address=>mapping(address=>uint256)) public _allowances;

    uint256 private _totalSupply;

    string private _symbol;
    string private _name;


    constructor(string memory name_, string memory symbol_, uint256 initialAmount_)
    {
        _name = name_;
        _symbol=symbol_;
        _totalSupply=initialAmount_;
        _balances[msg.sender]=initialAmount_;

    }

     function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8){
        return 18;
    }


    //returns the total supply of the tokens
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    //returns the balance of given account address
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    //return allowances of token that spender can spend on behalf of owner
    function allowance(address owner, address spender) public view  override returns (uint256) {
        return _allowances[owner][spender];
    }

    //sets the allownaces of spender as the given amount
    // emits approve event
    // ** spender cannot be zeo address
    function approve(address spender, uint256 amount) public  override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    //Transfer to a reciepient
    // emits transfer event
    // ** recipient cannot be zero address
    // ** sender must have balance >=amount
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    //Transfer from sender to receiver
    // emits transfer event
    // emits an approval event indicating the updated allowance
    // ** sender and recipient cannot be zero address
    // ** sender must have balance >=amount
    // ** the caller(msg.sender) of the function should have allowance for sender's token
    function transferFrom(address sender, address recipient, uint256 amount ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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


    function _approve(address owner,  address spender,  uint256 amount ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

}