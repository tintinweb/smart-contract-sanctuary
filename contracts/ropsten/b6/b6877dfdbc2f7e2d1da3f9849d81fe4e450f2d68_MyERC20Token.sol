/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: MIT

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

contract MyERC20Token is IERC20
{
    uint _totalSupply;
    uint _tokenCap;
    uint8 _decimal;
    string _tokenName;
    string _tokenSymbol;
    
    uint _perTokenWeiValue;
    uint _gapBetweenTransfers;
    uint _lastTransferTime;
    
    address _ownerAddress;
    
    mapping (address => uint) _wallets;
    mapping(address => mapping(address => uint256)) _allowances;

    constructor(uint initialTokenSupply, uint tokenCap, uint8 decimal, string memory tokenName, string memory tokenSymbol, uint8 percentAllowanceForContract)
    {
        require(initialTokenSupply >= 1e6, "Minimum initial allowed token supply is 1 million");
        require(tokenCap >= initialTokenSupply, "Token cap cannot be less than initial supply");
        require(decimal <= 100, "Cannot have a value of more than 100 for decimals");
        require(percentAllowanceForContract <= 100, "Cannot have a value of more than 100 for allowance");
        
        _totalSupply = initialTokenSupply * 10 ** decimal;
        _tokenCap = tokenCap * 10 ** decimal;
        _decimal = decimal;
        _tokenName = tokenName;
        _tokenSymbol = tokenSymbol;
        
        _ownerAddress = msg.sender;
        
        // Owner gets all tokens
        _wallets[_ownerAddress] = _totalSupply;
        
        // Approve requested allowance for the contract
        _allowances[msg.sender][address(this)] = _totalSupply * percentAllowanceForContract / 100;

        // Default to 100 tokens per ether at deployment
        _perTokenWeiValue = 1e18 / 100;
        
        // Default to 2 minutes
        _gapBetweenTransfers = 2 minutes;
    }
    
    modifier ownerOnly
    {
        require(msg.sender == _ownerAddress, "Address is not owner's address.");
        _;
    }
    
    modifier nonZeroAddress(address addressToCheck)
    {
        require(addressToCheck != address(0), "Cannot execute request for zero address.");
        _;
    }
    
    modifier transferGapElapsed
    {
        require(_lastTransferTime == 0 || block.timestamp >= _lastTransferTime + _gapBetweenTransfers, "Please request a transfer after some time");
        _;
    }
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() override external view returns (uint256)
    {
        return _totalSupply;
    }
    
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) override external view returns (uint256)
    {
        return _wallets[account];
    }
    
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) override external nonZeroAddress(msg.sender) nonZeroAddress(recipient) returns (bool)
    {
        return transferAmount(msg.sender, recipient, amount * 10 ** _decimal);
    }
    
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) override external view returns (uint256)
    {
        return _allowances[owner][spender];
    }
    
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
    function approve(address spender, uint256 amount) override external nonZeroAddress(msg.sender) nonZeroAddress(spender) returns (bool)
    {
        uint fullAmount = amount * 10 ** _decimal;

        _allowances[msg.sender][spender] = fullAmount;
        
        emit Approval(msg.sender, spender, fullAmount);
        
        return true;
    }
    
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) override external nonZeroAddress(msg.sender) nonZeroAddress(sender) nonZeroAddress(recipient) returns (bool)
    {
        uint fullAmount = amount * 10 ** _decimal;
        
        require(_allowances[sender][msg.sender] >= fullAmount, "Not enough allowance to make the transfer");
        
        transferAmount(sender, recipient, fullAmount);
        
        _allowances[sender][msg.sender] -= fullAmount;
        
        return true;
    }
    
    // only owner can mint
    function mint(uint newTokenAmount) external ownerOnly
    {
        uint newTotalSupply = (newTokenAmount * 10 ** _decimal) + _totalSupply;
        require(newTotalSupply <= _tokenCap, "Cannot exceed capped amount");
        
        _totalSupply = newTotalSupply;
        
        _wallets[msg.sender] += (newTokenAmount * 10 ** _decimal);
        
        emit Transfer(address(0), msg.sender, (newTokenAmount * 10 ** _decimal));
    }
    
    function buyToken() payable public nonZeroAddress(msg.sender)
    {
        require(msg.value >= 1 ether, "Amount must be minimum 1 ether");
        
        uint tokensToTransfer = msg.value / _perTokenWeiValue * 10 ** _decimal;
        
        require(this.allowance(_ownerAddress, address(this)) >= tokensToTransfer, "Not enough tokens to sell");
        
        transferAmount(_ownerAddress, msg.sender, tokensToTransfer);
        
        _allowances[_ownerAddress][address(this)] -= tokensToTransfer;
    }
    
    function setPerTokenWeiValue(uint tokenValueInWei) external ownerOnly
    {
        _perTokenWeiValue = tokenValueInWei;
    }
    
    function getPerTokenWeiValue() external view returns (uint)
    {
        return _perTokenWeiValue;
    }
    
    function getBalance() external view returns (uint)
    {
        return address(this).balance;
    }
    
    function increaseAllowance(address spender, uint addedValue) external
    {
        _allowances[msg.sender][spender] += addedValue;
    }
    
    function decreaseAllowance(address spender, uint reducedValue) external
    {
        uint currentAllowance = _allowances[msg.sender][spender];
        
        if (reducedValue > currentAllowance)
            _allowances[msg.sender][spender] = 0;
        else
            _allowances[msg.sender][spender] = currentAllowance - reducedValue;
    }
    
    function withdrawEtherFromContract() external payable ownerOnly
    {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    receive() payable external
    {
        buyToken();
    }
    
    function transferAmount(address sender, address recipient, uint amount) private transferGapElapsed returns (bool)
    {
        require(_wallets[sender] >= amount, "Sender does not have enough funds to transfer");
        
        _wallets[sender] -= amount;
        _wallets[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
        
        _lastTransferTime = block.timestamp;
        
        return true;
    }
}