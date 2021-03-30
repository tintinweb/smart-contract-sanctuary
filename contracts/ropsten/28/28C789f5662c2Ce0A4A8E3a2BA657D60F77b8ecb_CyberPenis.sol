/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

contract ERC20 {
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

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
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
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract CyberPenis is ERC20 {
    address public immutable owner;

    address payable internal immutable registry;
    
    constructor(address user, string memory cyberNickname) ERC20(string(abi.encodePacked(cyberNickname, "'s CyberPenis")), "CP") {
        registry = payable(msg.sender);
        owner = user;
    }

    function grow() external payable {
        registry.transfer(msg.value / 100);
        _mint(owner, msg.value);
    }

    function size() public view returns (uint256) {
        return address(this).balance;
    }

    function getScaledSize() public view returns (uint256) {
		uint256[2] memory rates = CyberPenisRegistry(registry).getRates();
    	uint256 scaledSize = size() * rates[0] / 1e18;

    	if (scaledSize == 0) {
    		return 0;
    	}

    	return logarithm(scaledSize) * rates[1];
    }

    function logarithm(uint256 x) internal pure returns (uint256 y) {
	   assembly {
	        let arg := x
	        x := sub(x,1)
	        x := or(x, div(x, 0x02))
	        x := or(x, div(x, 0x04))
	        x := or(x, div(x, 0x10))
	        x := or(x, div(x, 0x100))
	        x := or(x, div(x, 0x10000))
	        x := or(x, div(x, 0x100000000))
	        x := or(x, div(x, 0x10000000000000000))
	        x := or(x, div(x, 0x100000000000000000000000000000000))
	        x := add(x, 1)
	        let m := mload(0x40)
	        mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
	        mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
	        mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
	        mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
	        mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
	        mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
	        mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
	        mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
	        mstore(0x40, add(m, 0x100))
	        let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
	        let shift := 0x100000000000000000000000000000000000000000000000000000000000000
	        let a := div(mul(x, magic), shift)
	        y := div(mload(add(m,sub(255,a))), shift)
	        y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
	    }  
	}

    function balanceOf(address user) public view override returns (uint256) {
    	if (user != owner) {
    		return 0;
    	}

    	return getScaledSize() * (10**decimals());
    }

    function transfer(address, uint256) public pure override returns (bool) {
    	revert('CyberPenises are not transferrable!');
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
    	revert('CyberPenises are not transferrable!');
    }

    function approve(address, uint256) public pure override returns (bool) {
    	revert('CyberPenises are not approvable!');
    }

    function increaseAllowance(address, uint256) public pure override returns (bool) {
    	revert('CyberPenises are not approvable!');
    }

    function decreaseAllowance(address, uint256) public pure override returns (bool) {
    	revert('CyberPenises are not approvable!');
    }
}

abstract contract FeeCollector {
    address public feeCollector;

    event FeeCollectorSet(address indexed previousFeeCollector, address indexed newFeeCollector);

    modifier onlyFeeCollector {
        require(msg.sender == feeCollector, "onlyFeeCollector");
        _;
    }

    constructor() {
        feeCollector = msg.sender;
        emit FeeCollectorSet(address(0), msg.sender);
    }

    receive() external payable {}

    function setFeeCollector(address newFeeCollector) external onlyFeeCollector {
    	address previousFeeCollector = feeCollector;
        require(newFeeCollector != address(0), "zero");
        require(newFeeCollector != previousFeeCollector, "same");

        emit FeeCollectorSet(previousFeeCollector, newFeeCollector);

        feeCollector = newFeeCollector;
    }

    function collectFee(address payable beneficiary) external onlyFeeCollector {
    	beneficiary.transfer(address(this).balance);
    }
}

abstract contract RateSetter {
    address public rateSetter;
    uint256[2] public rates;

    event RateSetterSet(address indexed previousRateSetter, address indexed newRateSetter);
    event RateSet(uint256 indexed index, uint256 indexed previousRate, uint256 indexed newRate);

    modifier onlyRateSetter {
        require(msg.sender == rateSetter, "onlyRateSetter");
        _;
    }

    constructor(uint256 initialRate0, uint256 initialRate1) {
    	require(initialRate0 > uint256(0), "zero");
    	require(initialRate1 > uint256(0), "zero");

        rateSetter = msg.sender;
        rates[0] = initialRate0;
        rates[1] = initialRate1;

        emit RateSetterSet(address(0), msg.sender);
    }

    function setRate(uint256 index, uint256 newRate) external onlyRateSetter {
    	uint256 previousRate = rates[index];
    	require(newRate > uint256(0), "zero");

    	rates[index] = newRate;

    	emit RateSet(index, previousRate, newRate);
    }

    function setRateSetter(address newRateSetter) external onlyRateSetter {
    	address previousRateSetter = rateSetter;
        require(newRateSetter != address(0), "zero");
        require(newRateSetter != previousRateSetter, "same");

        rateSetter = newRateSetter;

        emit RateSetterSet(previousRateSetter, newRateSetter);
    }
    
    function getRates() external view returns (uint256[2] memory) {
        return [rates[0], rates[1]];
    }
}

contract CyberPenisRegistry is FeeCollector, RateSetter {
	mapping (address => address) public cyberPenis;
	mapping (address => string) public cyberNickname;
	address public largestCyberPenisOwner;

	event NewCyberPenis(address indexed newCyberPenis);
	event NewLargestCyberPenisOwner(address indexed newLargestCyberPenisOwner);

	constructor(uint256 initialRate0, uint256 initialRate1) FeeCollector() RateSetter(initialRate0, initialRate1) {}

	function makeMeLargestCyberPenisOwner() external {
		checkUser(msg.sender);

        if (largestCyberPenisOwner != address(0)) {
    		address largerCyberPenisOwner = getLargerCyberPenisOwner(msg.sender, largestCyberPenisOwner);
    		require(
    			msg.sender == largerCyberPenisOwner,
    			"You've tried but you're still not the largest"
    		);
        }

		largestCyberPenisOwner = msg.sender;

		emit NewLargestCyberPenisOwner(msg.sender);
	}

	function createCyberPenis(string calldata cyberNickname_) external payable {
		require(msg.value >= 0.01 ether, "Creating a cyber penis requires a fee((");
		require(cyberPenis[msg.sender] == address(0), "Only one cyberPenis may be created");

		address newCyberPenis = address(new CyberPenis(msg.sender, cyberNickname_));
		cyberPenis[msg.sender] = newCyberPenis;
		cyberNickname[msg.sender] = cyberNickname_;

		emit NewCyberPenis(newCyberPenis);
	}

	function getCyberPenisOwnersComparison(address user) external view returns (string memory) {
		return getCyberPenisOwnersComparison(user, largestCyberPenisOwner);
	}

	function getUserCyberPenis(address user) external view returns (string memory) {
		checkUser(user);

		uint256 scaledSize = CyberPenis(cyberPenis[user]).getScaledSize();

		if (scaledSize == 0) {
			return
				string(
				    abi.encodePacked(
    					cyberNickname[user],
    					unicode" has no cyber balls ¯\\_(ツ)_/¯"
    				)
				);
		}

		string memory userCyberPenis = string(
		    abi.encodePacked(
    			cyberNickname[user],
    			"'s cyber penis is ",
    			toString(scaledSize),
    			" mm long."
    		)
		);

		if (largestCyberPenisOwner != user) {
			userCyberPenis = string(
			    abi.encodePacked(
    				userCyberPenis,
    				unicode" Still not the longest ¯\\_(ツ)_/¯"
    			)
			);
		}

		return userCyberPenis;
	}

	function getCyberPenisOwnersComparison(address user1, address user2) public view returns (string memory) {
		checkUser(user1);
		checkUser(user2);

		address largerCyberPenisOwner = getLargerCyberPenisOwner(user1, user2);

		if (largerCyberPenisOwner == address(0)) {
			return
				string(
				    abi.encodePacked(
    					cyberNickname[user1],
    					"'s cyber penis is equal to ",
    					cyberNickname[user2],
    					unicode"'s one ¯\\_(ツ)_/¯"
    				)
				);
		}

		return
			string(
			    abi.encodePacked(
    				cyberNickname[largerCyberPenisOwner == user1 ? user2 : user1],
    				"'s cyber penis is smaller than ",
    				cyberNickname[largerCyberPenisOwner == user1 ? user1 : user2],
    				unicode"'s one ¯\\_(ツ)_/¯"
    			)
			);
	}

    function checkUser(address user) internal view {
        require(cyberPenis[user] != address(0), "No penis yet :(");
    }

	function getLargerCyberPenisOwner(address user1, address user2) internal view returns (address) {
		uint256 size1 = CyberPenis(cyberPenis[user1]).size();
		uint256 size2 = CyberPenis(cyberPenis[user2]).size();

		return size1 > size2 ? user1 : user2;
	}

    function toString(uint256 data) internal pure returns (string memory) {
        if (data == uint256(0)) {
            return "0";
        }

        uint256 length = 0;

        uint256 dataCopy = data;
        while (dataCopy != 0) {
            length++;
            dataCopy /= 10;
        }

        bytes memory result = new bytes(length);
        dataCopy = data;

        for (uint256 i = length; i > 0; i--) {
            result[i - 1] = bytes1(uint8(48 + (dataCopy % 10)));
            dataCopy /= 10;
        }

        return string(result);
    }
}