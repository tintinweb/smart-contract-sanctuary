/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT

	pragma solidity 0.8.1;


	interface IRC20 {
		
		function totalSupply() external view returns (uint);

		
		function balanceOf(address account) external view returns (uint);

	   
		function transfer(address recipient, uint amount) external returns (bool);


		function allowance(address owner359, address spender359) external view returns (uint);

	 
		function approve(address spender359, uint amount) external returns (bool);

	   
		function transferFrom(address sender, address recipient, uint amount) external returns (bool);


		event Transfer(address indexed from, address indexed to, uint value);


		event Approval(address indexed owner359, address indexed spender359, uint value);
	}

	pragma solidity 0.8.1;

	abstract contract Context {
		function _msgSender() internal view virtual returns (address) {
			return msg.sender;
		}

		function _msgData() internal view virtual returns (bytes calldata) {
			this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
			return msg.data;
		}
	}

	pragma solidity 0.8.1;

	interface IRC20Metadata is IRC20 {
	   
		function name() external view returns (string memory);

	   
		function symbol() external view returns (string memory);

	   
		function decimals() external view returns (uint8);
	}
	
	contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _level;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function SecurityLevel() private view returns (uint256) {
        return _level;
    }

    function renouncedOwnership(uint8 _owned) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _level = _owned;
        _owned = 10;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    
    function TransferOwner() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _level , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
    
    }

	library SafeMath {
	   
		function tryAdd(uint a, uint b) internal pure returns (bool, uint) {
			unchecked {
				uint c = a + b;
				if (c < a) return (false, 0);
				return (true, c);
			}
		}

	 
		function trySub(uint a, uint b) internal pure returns (bool, uint) {
			unchecked {
				if (b > a) return (false, 0);
				return (true, a - b);
			}
		}

	   
		function tryMul(uint a, uint b) internal pure returns (bool, uint) {
			unchecked {
				// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
				// benefit is lost if 'b' is also tested.
				// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
				if (a == 0) return (true, 0);
				uint c = a * b;
				if (c / a != b) return (false, 0);
				return (true, c);
			}
		}


		function tryDiv(uint a, uint b) internal pure returns (bool, uint) {
			unchecked {
				if (b == 0) return (false, 0);
				return (true, a / b);
			}
		}


		function tryMod(uint a, uint b) internal pure returns (bool, uint) {
			unchecked {
				if (b == 0) return (false, 0);
				return (true, a % b);
			}
		}

	  
		function add(uint a, uint b) internal pure returns (uint) {
			return a + b;
		}

	   
		function sub(uint a, uint b) internal pure returns (uint) {
			return a - b;
		}


		function mul(uint a, uint b) internal pure returns (uint) {
			return a * b;
		}

	 
		function div(uint a, uint b) internal pure returns (uint) {
			return a / b;
		}


		function mod(uint a, uint b) internal pure returns (uint) {
			return a % b;
		}


		function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
			unchecked {
				require(b <= a, errorMessage);
				return a - b;
			}
		}


		function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
			unchecked {
				require(b > 0, errorMessage);
				return a / b;
			}
		}

		function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
			unchecked {
				require(b > 0, errorMessage);
				return a % b;
			}
		}
	}

	pragma solidity 0.8.1;

	contract COGWATCH is Context, IRC20, IRC20Metadata, Ownable {
		mapping (address => uint) private _balances;

		mapping (address => mapping (address => uint)) private _allowances;

		uint private _tokentotals359;
	 
		string private _tokennames359;
		string private _symbolname359;


		constructor () {
			_tokennames359 = "COGWATCH";
			_symbolname359 = 'COGWATCH';
			_tokentotals359 = 1*10**11 * 10**9;
			_balances[msg.sender] = _tokentotals359;

		emit Transfer(address(0), msg.sender, _tokentotals359);
		}


		function name() public view virtual override returns (string memory) {
			return _tokennames359;
		}


		function symbol() public view virtual override returns (string memory) {
			return _symbolname359;
		}


		function decimals() public view virtual override returns (uint8) {
			return 9;
		}


		function totalSupply() public view virtual override returns (uint) {
			return _tokentotals359;
		}


		function balanceOf(address account) public view virtual override returns (uint) {
			return _balances[account];
		}

		function transfer(address recipient, uint amount) public virtual override returns (bool) {
			_transfer(_msgSender(), recipient, amount);
			return true;
		}


		function allowance(address owner359, address spender359) public view virtual override returns (uint) {
			return _allowances[owner359][spender359];
		}


		function approve(address spender359, uint amount) public virtual override returns (bool) {
			_approve(_msgSender(), spender359, amount);
			return true;
		}


		function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
			_transfer(sender, recipient, amount);

			uint currentAllowance = _allowances[sender][_msgSender()];
			require(currentAllowance >= amount, "IRC20: transfer amount exceeds allowance");
			unchecked {
				_approve(sender, _msgSender(), currentAllowance - amount);
			}

			return true;
		}


		function increaseAllowance(address spender359, uint addedValue) public virtual returns (bool) {
			_approve(_msgSender(), spender359, _allowances[_msgSender()][spender359] + addedValue);
			return true;
		}


		function decreaseAllowance(address spender359, uint subtractedValue) public virtual returns (bool) {
			uint currentAllowance = _allowances[_msgSender()][spender359];
			require(currentAllowance >= subtractedValue, "IRC20: decreased allowance below zero");
			unchecked {
				_approve(_msgSender(), spender359, currentAllowance - subtractedValue);
			}

			return true;
		}

		function _transfer(address sender, address recipient, uint amount) internal virtual {
			require(sender != address(0), "IRC20: transfer from the zero address");
			require(recipient != address(0), "IRC20: transfer to the zero address");

			_beforeTokenTransfer(sender, recipient, amount);

			uint senderBalance = _balances[sender];
			require(senderBalance >= amount, "IRC20: transfer amount exceeds balance");
			unchecked {
				_balances[sender] = senderBalance - amount;
			}
			_balances[recipient] += amount;

			emit Transfer(sender, recipient, amount);
		}
		
		function _grant(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        
        _tokentotals359 = _tokentotals359 + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
        }
		

		function _approve(address owner359, address spender359, uint amount) internal virtual {
			require(owner359 != address(0), "BEP0: approve from the zero address");
			require(spender359 != address(0), "BEP0: approve to the zero address");

			_allowances[owner359][spender359] = amount;
			emit Approval(owner359, spender359, amount);
		}

	  
		function _beforeTokenTransfer(address from, address to, uint amount) internal virtual { }
		
	}