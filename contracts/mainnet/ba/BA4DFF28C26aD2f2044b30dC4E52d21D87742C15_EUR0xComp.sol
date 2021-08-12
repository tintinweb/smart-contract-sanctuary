/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor()  {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract BlackList is Ownable {

    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract EUR0xComp is IERC20, BlackList {
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private timeOf;


    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply= 0;

    string private _name="EUR0x GREEN";
    string private _symbol="EUR0x";
    
    uint interest_updated=0;
    uint public time=0;
    uint blockNumber=0;
    uint public interest_rate=4500000000000000000;
    uint public _updateReceiver =  1 minutes;
    

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        time = block.timestamp;
        blockNumber = block.number;
        uint initalSupply=1000000*10**18;
        _mint(msg.sender,initalSupply);
        timeOf[msg.sender]=time;
    }
    
    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        _balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
    
    function setReceiverTime(uint secs ) external onlyOwner{
        _updateReceiver = secs;
        
    }
    function setInt(uint ints ) external onlyOwner{
        interest_rate = ints;
        
    }
    function mkcalc(address src, address dst) internal {
        uint tempTime = time;
        if(block.number > blockNumber){
            blockNumber = block.number;
            tempTime = block.timestamp;
        }
        time=tempTime;
        interest_updated = timeOf[src];
        if(interest_updated <= 0){
            interest_updated = time;
            timeOf[src] = time;
        }
        uint diff = tempTime - interest_updated;
        uint how_many_mins = uint(diff/60);
        uint256 no_ox = _balances[src];
        if(no_ox > 0 && how_many_mins > 0 ){
           uint minseconds = how_many_mins * 60;
       	   uint256 interestSoFar =  uint((((no_ox * interest_rate ) / 31536000) * minseconds)  /  100000000000000000000 )    ;

           if(interestSoFar  > 0){
               
               interest_updated +=  minseconds;
               timeOf[src] = interest_updated;
               _balances[src] += interestSoFar ;
               _totalSupply += interestSoFar;
               emit Transfer(address(0),src, interestSoFar);
           }
           
       }
       
       //checking receiver side the receiver end
       no_ox=0;
       no_ox = _balances[dst];
       if( no_ox > 0){
            interest_updated = timeOf[dst];
            diff = tempTime - interest_updated;
            if(diff > _updateReceiver ){
                //do the calc
                how_many_mins = uint(diff / 60);
                uint minseconds = how_many_mins * 60;
                uint256 interestSoFar =  uint((((no_ox * interest_rate ) / 31536000) * minseconds)  /  100000000000000000000 )    ;

                if(interestSoFar  > 0){
                    interest_updated +=  minseconds;
                    timeOf[dst] = interest_updated;
                    _balances[dst] +=  interestSoFar ;
                    _totalSupply +=  interestSoFar ;
                    emit Transfer(address(0), dst, interestSoFar);
                }
            }

       }else{
            timeOf[dst] =tempTime;
       }
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual  returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual  returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function timeOfs(address account) public view virtual returns (uint256) {
        return timeOf[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address dst, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, dst, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

  
    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(!isBlackListed[msg.sender]);
        mkcalc(sender, recipient);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }
    
    function issue(uint256 amount) external onlyOwner{
        _mint(msg.sender,amount);
    }
   
    function redeem( uint256 amount) external onlyOwner {
        address account = msg.sender;
        require(account != address(0), "ERC20: burn from the zero address");


        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

 
    
}