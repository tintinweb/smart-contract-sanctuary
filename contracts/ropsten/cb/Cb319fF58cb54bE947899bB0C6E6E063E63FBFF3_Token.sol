/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

library SafeMath {

	function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

contract Ownable {
	address internal _owner;

	event TransferOwnerShip(address currentOwner, address newOwner);

	modifier onlyOwner {
		require(msg.sender == _owner);
		_;
	}

	constructor() {
		_owner = msg.sender;
	}

	function owner() public view returns(address) {
		return _owner;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		address currentOwner;

		require(newOwner != address(0));

		currentOwner = _owner;
		_owner = newOwner;

		emit TransferOwnerShip(currentOwner, newOwner);
	}
}

contract Token is Ownable {
	using SafeMath for uint;

	string public name;
	string public symbol;
	uint256 private _totalSupply;

	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;

	event Transfer(address indexed sender, address indexed receiver, uint256 tokenAmount);
	event Approval(
		address indexed owner, 
		address indexed spender, 
		uint256 tokenAmount
	);

	constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
		name = _name;
		symbol = _symbol;

		_mint(_initialSupply);
	}

	/**
	 * @dev Returns token decimals 
	 */
	function decimals() public pure returns(uint8) {
		return 18;
	}

	/**
	 * @dev Returns `_totalSupply` of tokens 
	 */
	function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

	/**
	 * @dev Returns token balance of `_account`
	 */
	function balanceOf(address account) public view returns(uint256) {
		return _balances[account];
	}

	/**
	 * @dev Returns withdrawable amount of `spender`
	 */
	function allowance(address owner, address spender) public view returns(uint256) {
        return _allowances[owner][spender];
    }

	/**
	 * @dev Allow `_spender` to withdraw tokens from sender's account
	 */
	function approve(address spender, uint256 tokenAmount) public returns(bool) {
		_approve(msg.sender, spender, tokenAmount);
		return true;
	}

	/**
	 * @dev Transfer `tokenAmount` from sender's account to `receiver`
	 */
	function transfer(address receiver, uint256 tokenAmount) public returns(bool) {
        _transfer(msg.sender, receiver, tokenAmount);
        return true;
    }

    /**
     * @dev Transfer `tokenAmount` from sender's account to `receiver`
     */
    function transferFrom(address sender, address receiver, uint256 tokenAmount) public returns (bool) {
        _transfer(sender, receiver, tokenAmount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= tokenAmount, "Transfer amount exceeds allowance");

        unchecked {
            _approve(sender, msg.sender, currentAllowance - tokenAmount);
        }

        return true;
    }

	function _mint(uint256 tokenAmount) public onlyOwner {
		if (tokenAmount > 0) {
			_issue(_owner, tokenAmount);
		}
	}

	function _issue(address account, uint256 tokenAmount) internal {
		require(tokenAmount > 0);

		uint256 accountBalance = _balances[account];

		_totalSupply = _totalSupply.add(tokenAmount);
		_balances[account] = accountBalance.add(tokenAmount);

		emit Transfer(address(0), account, tokenAmount);
	}

	function _approve(address owner, address spender, uint256 tokenAmount) internal {
       	require(owner != address(0) && spender != address(0));

        _allowances[owner][spender] = tokenAmount;
        emit Approval(owner, spender, tokenAmount);
    }

    function _transfer(address sender, address receiver, uint256 tokenAmount) internal {
    	require(sender != address(0) && receiver != address(0));

    	uint256 senderBalance = _balances[sender];
    	uint256 receiverBalance = _balances[receiver];

    	require(senderBalance >= tokenAmount, "Transfer amount exceeds balance");

    	unchecked {
    		_balances[sender] = senderBalance.sub(tokenAmount);
    	}
    	_balances[receiver] = receiverBalance.add(tokenAmount);

    	emit Transfer(sender, receiver, tokenAmount);
    }
}