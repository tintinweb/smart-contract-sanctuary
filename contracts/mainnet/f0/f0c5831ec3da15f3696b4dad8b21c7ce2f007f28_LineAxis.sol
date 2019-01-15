pragma solidity ^0.4.24;



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Owned {
    address private _owner;
    address private _newOwner;

    event TransferredOwner(
        address indexed previousOwner,
        address indexed newOwner
    );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() internal {
        _owner = msg.sender;
        emit TransferredOwner(address(0), _owner);
    }

  /**
   * @return the address of the owner.
   */

    function owner() public view returns(address) {
        return _owner;
    }

  /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(isOwner(), "Access is denied");
        _;
    }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
    function renounceOwner() public onlyOwner {
        emit TransferredOwner(_owner, address(0));
        _owner = address(0);
    }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
    function transferOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Empty address");
        _newOwner = newOwner;
    }


    function cancelOwner() public onlyOwner {
        _newOwner = address(0);
    }

    function confirmOwner() public {
        require(msg.sender == _newOwner, "Access is denied");
        emit TransferredOwner(_owner, _newOwner);
        _owner = _newOwner;
    }
}




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */

contract ERC20CoreBase {

    // string public name;
    // string public symbol;
    // uint8 public decimals;


    mapping (address => uint) internal _balanceOf;
    uint internal _totalSupply; 

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );


    /**
    * @dev Total number of tokens in existence
    */

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */

    function balanceOf(address owner) public view returns(uint) {
        return _balanceOf[owner];
    }



    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */

    function _transfer(address from, address to, uint256 value) internal {
        _checkRequireERC20(to, value, true, _balanceOf[from]);

        _balanceOf[from] -= value;
        _balanceOf[to] += value;
        emit Transfer(from, to, value);
    }


    /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param account The account that will receive the created tokens.
    * @param value The amount that will be created.
    */

    function _mint(address account, uint256 value) internal {
        _checkRequireERC20(account, value, false, 0);
        _totalSupply += value;
        _balanceOf[account] += value;
        emit Transfer(address(0), account, value);
    }

    /**
    * @dev Internal function that burns an amount of the token of a given
    * account.
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */

    function _burn(address account, uint256 value) internal {
        _checkRequireERC20(account, value, true, _balanceOf[account]);

        _totalSupply -= value;
        _balanceOf[account] -= value;
        emit Transfer(account, address(0), value);
    }


    function _checkRequireERC20(address addr, uint value, bool checkMax, uint max) internal pure {
        require(addr != address(0), "Empty address");
        require(value > 0, "Empty value");
        if (checkMax) {
            require(value <= max, "Out of value");
        }
    }

}


contract ERC20 is ERC20CoreBase {
    mapping (address => mapping (address => uint256)) private _allowed;


    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    ); 


	constructor(address to, uint value) public {
		_mint(to, value);
	}

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    
    function allowance(address owner, address spender) public view returns(uint) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */

    function approve(address spender, uint256 value) public {
        _checkRequireERC20(spender, value, true, _balanceOf[msg.sender]);

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */

    function transferFrom(address from, address to, uint256 value) public {
        _checkRequireERC20(to, value, true, _allowed[from][msg.sender]);

        _allowed[from][msg.sender] -= value;
        _transfer(from, to, value);
    }






 
    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */

    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }
}


contract LineAxis is Owned, ERC20 {
	string public name;
	string public symbol;
	uint public decimals;
	bool public frozen;


	/**
	* Logged when token transfers were frozen/unfrozen.
	*/
	event Freeze ();
	event Unfreeze ();
	
    modifier onlyUnfreeze() {
        require(!frozen, "Action temporarily paused");
        _;
    }

	constructor(string _name, string _symbol, uint _decimals, uint _total, bool _frozen) public ERC20(msg.sender, _total) {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		frozen = _frozen;
	}

	function mint(address to, uint value) public onlyOwner {
		_mint(to, value);
	}





	function freezeTransfers () public onlyOwner {
		if (!frozen) {
			frozen = true;
			emit Freeze();
		}
	}

	/**
	* Unfreeze token transfers.
	* May only be called by smart contract owner.
	*/
	function unfreezeTransfers () public onlyOwner {
		if (frozen) {
			frozen = false;
			emit Unfreeze();
		}
	}

	function transfer(address to, uint value) public onlyUnfreeze {
		super.transfer(to, value);
	}


	function transferFrom(address from, address to, uint value) public onlyUnfreeze {
		super.transferFrom(from, to, value);
	}
}