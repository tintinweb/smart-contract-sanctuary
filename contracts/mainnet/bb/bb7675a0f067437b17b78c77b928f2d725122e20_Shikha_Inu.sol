/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
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

contract Shikha_Inu is IERC20 {

    string private _name = "Shikha Inu";
    string private _symbol = "SHIKHA";
    uint8 private _decimals = 18;
    
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;
    
    uint256 internal _tokenTotal = 10000000000 *10**18;
    
    mapping(address => bool) isExcludedFromFee;

    constructor() {
        
        isExcludedFromFee[msg.sender] = true;
        
        _tokenBalance[msg.sender] = _tokenTotal;
        emit Transfer(address(0), msg.sender, _tokenTotal);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _tokenBalance[account];
    }

    function transfer(address recipient, uint256 amount) public override virtual returns (bool) {
       _transfer(msg.sender,recipient,amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(sender,recipient,amount);
               
        _approve(sender,msg.sender,_allowances[sender][msg.sender] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 transferAmount = amount;
        uint256 charityFee = amount * 9999 / 10000;
        
        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]) {
            //@dev charity fee
            if(charityFee > 0) {
                transferAmount = transferAmount - charityFee;
                _tokenBalance[address(this)] = _tokenBalance[address(this)] + charityFee;
                emit Transfer(recipient, address(this), charityFee);
            }
        }
        
        _tokenBalance[sender] = _tokenBalance[sender] - amount;
        _tokenBalance[recipient] = _tokenBalance[recipient] + transferAmount;

        emit Transfer(sender, recipient, transferAmount);
    }
}