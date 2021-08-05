/**
 *Submitted for verification at Etherscan.io on 2021-01-14
*/

/**
 * SPDX-License-Identifier: UNLICENSED;
 *
 *
 *    db    88 88""Yb 8888b.  88""Yb  dP"Yb  88""Yb     888888 888888 .dP"Y8 888888 
 *   dPYb   88 88__dP  8I  Yb 88__dP dP   Yb 88__dP       88   88__   `Ybo."   88   
 *  dP__Yb  88 88"Yb   8I  dY 88"Yb  Yb   dP 88"""        88   88""   o.`Y8b   88   
 * dP""""Yb 88 88  Yb 8888Y"  88  Yb  YbodP  88           88   888888 8bodP'   88   
 * 888888  dP"Yb  88  dP 888888 88b 88                                              
 *   88   dP   Yb 88odP  88__   88Yb88                                              
 *   88   Yb   dP 88"Yb  88""   88 Y88                                              
 *   88    YbodP  88  Yb 888888 88  Y8    
 *
 * This is a test token. Usage on own risk. This is not an investment, security or anything like that.
 * 
 * Tutorial:
 * 1) Run requestAirdrop()
 * 2) Wait :)
 * PRO TIP: Donate 0.1 ETH for 1 or more entries!
 */


pragma solidity 0.8.0;

contract AirdropTestToken {
    
    /**
     * @dev Always use this to ensure that the msg.sender is always payable.
     */
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    
    /**
     * @dev A modifier to only allow function calls by the owner.
     */
    modifier onlyOwner {
        require(owner == msg.sender, "AirdropTestToken: You're not the owner.");
        _;
    }

    mapping (address => uint256) private _balances;
	mapping (address => uint256) private _lockedBalances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _maxSupply;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

	uint UNIT;
	uint public reward;
	bool public airdropActive;

	address public owner;

	uint nextReceiver;
	uint receiversCount;
	mapping(uint => address) receivers;
	mapping(address => uint) received;
	mapping(address => bool) isDonator;
	mapping(address => uint) lastClaimed;


    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /**
     * @dev Emitted when an Airdrop is rewarded.
     */
    event Airdrop(address indexed receiver, uint amount);
    
    /**
     * @dev Emitted when an tokens are burned.
     */
    event Burn(address indexed burner, uint amount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    /**
     * Emitted when the owner sends a message.
     */
    event OwnerMessage(string message);

    /**
     * @dev Initialize the project and define the project name, symbol, decimals,
     * totalSupply, owner and the price for the shovels.
     * Note: There are no pre-mined tokens.
     */
    constructor () {
        airdropActive = true;
        _name = "AirdropTestToken";
        _symbol = "ATT";
        _decimals = 18;
		UNIT = 10 ** _decimals;
		reward = 1000 * UNIT;
		owner = msg.sender;
		nextReceiver = 1;

		// Set the total supply to 100.000
        _totalSupply = 0;
		_maxSupply = 9600000 * UNIT;

		// Add this to owners balance
		_mint(msg.sender, 100000 * UNIT);
    }


    /**
     * @dev Basic ERC20 getters
     *  Get the decimals, totalSupply, name and symbol of the token and
     * get the balances and allowances of specific addresses.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
	// @dev Return the _totalSupply
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
	// @dev Return the token balance of account_
    function balanceOf(address account_) public view returns (uint256) {
        return _balances[account_];
    }

	// @dev Returns the locked token balance of account_
    function lockedBalanceOf(address account_) public view returns (uint256) {
        return _lockedBalances[account_];
    }
    
	// @dev Return the allowance of spender_ of owner_
    function allowance(address owner_, address spender_) public view virtual returns (uint256) {
        return _allowances[owner_][spender_];
    }
    
	// @dev Return the token name
    function name() public view returns (string memory name_) {
        return _name;
    }
    
	// @dev Return the token symbol
    function symbol() public view returns (string memory symbol_) {
        return _symbol;
    }

	// @dev Return who's next
	function getNextReceiver() public view returns (uint nextReceiver_) {
        return nextReceiver;
    }

	// @dev Return the address behind `receiverAddress[id_]`
	function getReceiver(uint id_) public view returns (address receiverAddress_) {
        return receivers[id_];
    }

	// @dev Return how much `address_` has been airdropped to
	function getTotalReceivers() public view returns (uint receiversCount_) {
        return receiversCount;
    }
    
    // @dev Return how much total airdrops are/will be
	function getReceived(address address_) public view returns (uint received_) {
        return received[address_];
    }

	// @dev Return how much `address_` has been airdropped to
	function checkIsDonator(address address_) public view returns (bool isDonator_) {
        return isDonator[address_];
    }
	

	// @dev Create a new Airdrop request
    receive() payable external {
        requestAirdrop();
    }
    
    // @dev Revert when no function is called and no eth are sent.
    fallback() external {
        revert();
    }


    /**
     * @dev Transfer `amount_` tokens from _msgSender() (msg.sender) to `recipient_`
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient_, uint256 amount_) public returns (bool) {
        _transfer(_msgSender(), recipient_, amount_);
        return true;
    }

    /**
     * @dev Allow `spender_` to spend `amount_` of tokens of _msgSender() (msg.sender)
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender_, uint256 amount_) public returns (bool) {
        _approve(_msgSender(), spender_, amount_);
        return true;
    }

    /**
     * @dev Transfer `amount_` tokens from `sender_` to `recipient_`
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender_` and `recipient_` cannot be the zero address.
     * - `sender_` must have a balance of at least `amount_`.
     * - the caller must have allowance for ``sender_``'s tokens of at least `amount_`.
     */
    function transferFrom(address sender_, address recipient_, uint256 amount_) public returns (bool) {
        _transfer(sender_, recipient_, amount_);
        _approve(sender_, _msgSender(), _allowances[sender_][_msgSender()] - amount_);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender_` by the caller.
     *
     * This is an alternative to {approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender_` cannot be the zero address.
     */
    function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool) {
        _approve(_msgSender(), spender_, _allowances[_msgSender()][spender_] + addedValue_);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender_` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender_` cannot be the zero address.
     * - `spender_` must have allowance for the caller of at least
     * `subtractedValue_`.
     */
    function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool) {
        _approve(_msgSender(), spender_, _allowances[_msgSender()][spender_] - subtractedValue_);
        return true;
    }

	/**
	 * @dev Lock `_amount` tokens and burn them.
	 * @notice Warning! Token locks have NO FUNCTIONALITY BESIDES UPGRADING! DO NOT LOCK IF NOT NEEDED!
	 */
	function lockTokens(uint _amount) public returns(bool) {
		_lockedBalances[_msgSender()] += _amount;
		_burn(_msgSender(), _amount);
		return true;
	}

	/**
	 * @dev Request an AirDrop
	 * If msg.sender sends eth, get more AirDrops per 0.1 ETH.
	 * Require to only pay in 0.001 incrementals.
	 * Note: The price is on purpose set to a high price - to prevent spamming and to only allow generous people to use this :)
	 */
	function requestAirdrop() payable public returns(bool) {
	    // Check if airdrop is enabled
	    require(airdropActive, "AirdropTestToken: Airdrop is over.");
	    
	    // Airdrop to the next 3 addresses
	    for(uint i = 1; i <= 3; i++) {
	        if(receivers[nextReceiver] != address(0)) {
	            // Reward the Airdrop
    			_mint(receivers[nextReceiver], reward);
    			
    			// Give 10 tokens (1%) to the owner
    			_mint(owner, 10 * UNIT);
    			received[receivers[nextReceiver]] += reward;
    			nextReceiver++;
    			emit Airdrop(receivers[nextReceiver], reward);
    		}
	    }
		
		// Add multiple requests when donating
		uint requestMultiplier_ = 1;
		uint donationSteps_ = 100000000000000000; // 0.1 ETH
		
		// Check if user is donating
		if(msg.value >= 1) {

			// Only send in 0.1 steps (0.1, 0.2, 0.5, etc.)
			uint remain_ = msg.value % donationSteps_;
			require(remain_ == 0, "AirdropTestToken: Please send ETH only in 0.1 steps.");
			
			isDonator[_msgSender()] = true;

			// Calculate how much additional entries msg.sender gets
			requestMultiplier_ = msg.value / donationSteps_;
			requestMultiplier_ = requestMultiplier_ * 2;
			for(uint i = 1; i <= requestMultiplier_; i++) {
				receiversCount++;
				receivers[receiversCount] = _msgSender();
			}
		}

		else {
		    // Reserve 5% of the Airdrop capacity for donating users
			require(_totalSupply <= _maxSupply - _totalSupply / 5, "AirdropTestToken: Last 5% supply reserved for donating users.");
			
			// Only allow one airdrop per hour and address
			require(block.timestamp - lastClaimed[msg.sender] >= 3600, "AirdropTestToken: You can only get an Airdrop once an hour. Donate to get more.");
		}
		receiversCount++;
		receivers[receiversCount] = _msgSender();
		lastClaimed[msg.sender] = block.timestamp;
		
		return true;
	}

	/**
     * @dev Withdraws the current balance
     */
    function withdraw() payable public onlyOwner {
        _msgSender().call{value: address(this).balance}("");
    }
    
    /**
     * @dev Disables the airdrop function.
     */
    function status() public onlyOwner {
        if(airdropActive == true) {
            airdropActive = false;
        }
        else {
            airdropActive = true;
        }
    }

	/**
     * @dev emits an {OwnerMessage} event with message `message_`
     * This is used for communication only.
     * No otherwise usage.
	 * May use twitter 'n stuff instead lol.
     */
    function ownerMessage(string memory message_) public onlyOwner {
        emit OwnerMessage(message_);
    }
    
    /**
     * @dev Send (accidentally) to the smart contract sent tokens to the owner.
     * Note: The owner CAN NOT send AirdropTest tokens as long as the CONTRACT does not hold them.
     */
    function transferERC20(address token_) public {
        uint amount_ = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(owner, amount_);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender_, address recipient_, uint256 amount_) internal {
        require(sender_ != address(0), "AirdropTestToken: transfer from the zero address");
        require(recipient_ != address(0), "AirdropTestToken: transfer to the zero address");

        _balances[sender_] = _balances[sender_] - amount_;
        _balances[recipient_] = _balances[recipient_] + amount_;
        emit Transfer(sender_, recipient_, amount_);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account_, uint256 amount_) internal {
        require(account_ != address(0), "AirdropTestToken: mint to the zero address");
        require(_totalSupply + amount_ <= _maxSupply, "AirdropTestToken: Amount to mint exceeds max supply.");

        _totalSupply = _totalSupply + amount_;
        _balances[account_] = _balances[account_] + amount_;
        emit Transfer(address(0), account_, amount_);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account_, uint256 amount_) internal {
        require(account_ != address(0), "AirdropTestToken: burn from the zero address");
        _balances[account_] = _balances[account_] - amount_;
        _totalSupply = _totalSupply - amount_;
        _maxSupply = _maxSupply - amount_;
        emit Transfer(account_, address(0), amount_);
        emit Burn(account_, amount_);
    }

    /**
     * @dev Sets `amount_` as the allowance of `spender_` over the `owner_` s tokens.
     *
     * This internal function is equivalent to {approve}, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner_` cannot be the zero address.
     * - `spender_` cannot be the zero address.
     */
    function _approve(address owner_, address spender_, uint256 amount_) internal {
        require(owner_ != address(0), "AirdropTestTokenRC20: approve from the zero address");
        require(spender_ != address(0), "AirdropTestToken: approve to the zero address");

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }
    
}

interface IERC20 {
    function transfer(address recipient_, uint256 amount_) external returns(bool);
    function balanceOf(address account_) external view returns (uint256);
}