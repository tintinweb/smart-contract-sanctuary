/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;


/* ----------------------------------------------------------------------------
 
 'GToken' contract 

 * Symbol      : GTO
 * Name        : GToken
 * Total supply: 1 trillion
 * Decimals    : 18

---------------------------------------------------------------------------- */ 
 

interface IGtoken {
    /**
     * @dev returns the name of the token
     */
    function name() external view returns (string memory);

    /**
     * @dev returns the symbol of the token
     */
    function symbol() external view returns (string memory);

    /**
     * @dev returns the decimal places of a token
     */
    function decimals() external view returns (uint8);

    /**
     * @dev returns the total tokens in existence
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev returns the tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev transfers the `amount` of tokens from caller's account
     * to the `recipient` account.
     *
     * returns boolean value indicating the operation status.
     *
     * Emits a {Transfer} event
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev returns the remaining number of tokens the `spender' can spend
     * on behalf of the owner.
     *
     * This value changes when {approve} or {transferFrom} is executed.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev sets `amount` as the `allowance` of the `spender`.
     *
     * returns a boolean value indicating the operation status.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev transfers the `amount` on behalf of `spender` to the `recipient` account.
     *
     * returns a boolean indicating the operation status.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted from tokens are moved from one account('from') to another account ('to)
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when allowance of a `spender` is set by the `owner`
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


abstract contract Context {

    function msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function msgData() internal view virtual returns(bytes calldata) {
        this;
        return msg.data;
    }

    function msgValue() internal view virtual returns(uint256) {
        return msg.value;
    }

}

contract GToken is IGtoken, Context {
    
    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint256)) private allowances;

    address private _governor;

    uint256 private _totalSupply;

    uint256 public feeFraction = 10;

    string private _name;

    string private _symbol;

    // allowedAddresses will be able to transfer even when locked
    mapping(address => bool) public allowedAddresses;

    // lockedAddresses will *not* be able to transfer even when *not locked*
    mapping(address => bool) public lockedAddresses;

    mapping (address => mapping (address => uint256)) allowed;

    bool public freezed = false;

    /**
     * @dev checks whether `caller` is governor;
    */
    modifier onlyGovernor() {
        require(msgSender() == _governor, "ERC20: caller not governor");
        _;
    }


    /**
     * @dev adds the address to the list of allowedAddresses
    */
    function allowAddress(address _addr, bool _allowed) public onlyGovernor {
        require(_addr != _governor);
        allowedAddresses[_addr] = _allowed;
    }

    /**
     * @dev adds the address to the list of lockedAddresses
    */
    function lockAddress(address _addr, bool _locked) public onlyGovernor {
        require(_addr != _governor);
        lockedAddresses[_addr] = _locked;
    }

    /**
     * @dev freezes the contract
    */
    function freeze() public onlyGovernor {
        freezed = true;
    }

    /**
     * @dev unfreezes the contract
    */
    function unfreeze() public onlyGovernor {
        freezed = false;
    }

    /**
     * @dev validates the transfer
    */
    function validateTransfer(address _addr) internal view returns (bool) {
       
        if(freezed){
           
            if(!allowedAddresses[_addr]&&_addr!=_governor) 
                return false;
        }
        
        else if(lockedAddresses[_addr]) 
            return false;

        return true;
    }

 

    /**
     * @dev sets the {name}, {symbol} and {governor wallet} of the token.
     *
     * All the two variables are immutable and cannot be changed
     * and set only in the constructor.
     */
    constructor(string memory name_, string memory symbol_, address _governorAddress) {
        _name = name_;
        _symbol = symbol_;
        _governor = _governorAddress;
     }

    /**
     * @dev returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev returns the symbol of the token.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev returns the decimals of the token
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev returns the total supply of the token
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev returns the number of tokens owned by `account`
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return balances[account];
    }

    /**
     * @dev returns the amount the `spender` can spend on behalf of the `owner`.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return allowances[owner][spender];
    }

    /**
     * @dev Approve a `spender` to spend tokens on behalf of the `owner`.
     */
    function approve(address spender, uint256 value)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msgSender(), spender, value);
        return true;
    }

    /**
     * @dev to increase the allowance of `spender` over the `owner` account.
     *
     * Requirements
     * `spender` cannot be zero address
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msgSender(),
            spender,
            allowances[msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev to decrease the allowance of `spender` over the `owner` account.
     *
     * Requirements
     * `spender` allowance shoule be greater than the `reducedValue`
     * `spender` cannot be a zero address
     */
    function decreaseAllowance(address spender, uint256 reducedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = allowances[msgSender()][spender];
        require(
            currentAllowance >= reducedValue,
            "ERC20: ReducedValue greater than allowance"
        );

        _approve(msgSender(), spender, currentAllowance - reducedValue);
        return true;
    }

    /**
     * @dev sets the amount as the allowance of `spender` over the `owner` address
     *
     * Requirements:
     * `owner` cannot be zero address
     * `spender` cannot be zero address
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev transfers the `amount` of tokens to `recipient`
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(validateTransfer(msgSender()),"ERC20: Transfer reverted");

        _transfer(msgSender(), recipient, amount);

        emit Transfer(msgSender(), recipient, amount);

        return true;
    }

    /**
     * @dev transfers the 'amount` from the `sender` to the `recipient`
     * on behalf of the `sender`.
     *
     * Requirements
     * `sender` and `recipient` should be non zero addresses
     * `sender` should have balance of more than `amount`
     * `caller` must have allowance greater than `amount`
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(validateTransfer(sender),"ERC20: Transfer reverted");
        
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowances[sender][msgSender()];
        require(currentAllowance >= amount, "ERC20: amount exceeds allowance");
        _approve(sender, msgSender(), currentAllowance - amount);
      
        emit Transfer(sender, recipient, amount);

        return true;
    }

    /**
     * @dev mints the amount of tokens to the `recipient` wallet.
     *
     * Requirements :
     *
     * The caller must be the `governor` of the contract.
     * Governor can be an DAO smart contract.
     */
    function mint(address recipient, uint256 amount)
        public
        virtual
        onlyGovernor
        returns (bool)
    {
        require(recipient != address(0), "ERC20: mint to a zero address");

 
        _totalSupply += amount;
        balances[recipient] += amount;

        emit Transfer(address(0), recipient, amount);
        return true;
    }

    /**
     * @dev burns the `amount` tokens from `supply`.
     *
     * Requirements
     * `caller` address balance should be greater than `amount`
     */
    function burn(uint256 amount) public virtual onlyGovernor returns (bool) {
        uint256 currentBalance = balances[msgSender()];
        require(
            currentBalance >= amount,
            "ERC20: burning amount exceeds balance"
        );

        balances[msgSender()] = currentBalance - amount;
        _totalSupply -= amount;

        return true;
    }

    /**
     * @dev transfers the `amount` of tokens from `sender` to `recipient`.
     *
     * Requirements:
     * `sender` is not a zero address
     * `recipient` is also not a zero address
     * `amount` is less than or equal to balance of the sender.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from zero address");
        require(recipient != address(0), "ERC20: transfer to zero address");

        uint256 senderBalance = balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

     
        balances[sender] = senderBalance - amount;
        
        // Transfer the spread to the admin
        uint256 fee = amount * feeFraction / 10**4;

        uint256 receiverAmount = amount - fee;

        balances[recipient] += receiverAmount;
        balances[_governor] +=fee;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev returns the current `governor` address.
     *
     * `governors` can mint / burn Gtokens
     */
    function governor() public view virtual returns (address) {
        return _governor;
    }

    /**
     * @dev transfers the governance of the contract.
     *
     * Requirements :
     * `caller` should be the current governor.
     * `newGovernor` cannot be a zero address.
     */
    function transferGovernance(address newGovernor)
        public
        virtual
        onlyGovernor
        returns (bool)
    {
        require(newGovernor != address(0), "ERC20: zero address cannot govern");
        _governor = newGovernor;
        return true;
    }
 
    /**
     * @dev changes the transaction fee.
     *
     * Requirements :
     * `caller` should be the current governor.
     * `transactionFee` cannot be less than zero.
     */
    function setTransactionFee(uint256 _newFeeFraction)
        public
        virtual
        onlyGovernor
        returns (bool)
    {
        require(_newFeeFraction >= 0, "ERC20: fee must not be negative");
        feeFraction = _newFeeFraction;
        return true;
    }

   
}