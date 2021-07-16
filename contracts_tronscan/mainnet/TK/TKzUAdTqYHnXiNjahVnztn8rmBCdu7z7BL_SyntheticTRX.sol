//SourceUnit: Address.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


//SourceUnit: Distributable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

import "./Ownable.sol";
import "./Address.sol";
import "./ITRC20.sol";

interface IDistribute {
    function distribute(uint256 amount) external returns (bool);
    function distribute(address to, uint256 amount) external returns (bool);
    
    event Distribute(address indexed distributor, address indexed to, uint256 amount);
}

contract Distributable is IDistribute, Ownable {
    using Address for address;
    
    mapping (address => bool) distributors;
    
    modifier distributed() {
        require(distributors[msg.sender], "distributor");
        _;
    }
    
    function setDistributor(address distributor_, bool status) public owned {
        require(distributor_.isContract(), "contract");
        distributors[distributor_] = status;
    }
    
    function isDistributor(address sender_) public view returns (bool) {
        return distributors[sender_];
    }
    
    function distribute(uint256 amount) public returns (bool) {
        return distribute(msg.sender, amount);
    }
    
    function distribute(address to, uint256 amount) public returns (bool);
}


//SourceUnit: ISTRX.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

interface ISTRX {
    function burn(uint256 amount) external returns (bool);
    function burnTo(address payable to, uint256 amount) external returns (bool);
    
    function mint() external payable returns (bool);
    function mintTo(address to) external payable returns (bool);
    
    event Mint(address indexed from, address to, uint256 amount);
    event Burn(address indexed from, address to, uint256 amount);
}


//SourceUnit: ITRC20.sol

/// TRC20.sol -- API for the TRC20 token standard

// See <https://github.com/tronprotocol/tips/blob/master/tip-20.md>.

// This file likely does not meet the threshold of originality
// required for copyright to apply.  As a result, this is free and
// unencumbered software belonging to the public domain.

pragma solidity ^0.5.8;

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier owned() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public owned {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public owned {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SourceUnit: Rescuable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

import "./Ownable.sol";
import "./SafeTRC20.sol";
import "./ITRC20.sol";

contract Rescuable is Ownable {
    using SafeTRC20 for ITRC20;
    
    event Rescue(address indexed to, uint256 amount);
    event Rescue(address indexed to, address indexed token, uint256 amount);

    function rescue(address payable to, uint256 amount) external owned {
        require(to != address(0), "zeroaddr");
        require(amount > 0, "nonzero");

        to.transfer(amount);
        emit Rescue(to, amount);
    }
    
    function rescue(ITRC20 token, address to, uint256 amount) external owned {
        require(to != address(0), "zeroaddr");
        require(amount > 0, "nonzero");

        token.safeTransfer(to, amount);
        emit Rescue(to, address(token), amount);
    }
}


//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SourceUnit: SafeTRC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

import "./SafeMath.sol";
import "./Address.sol";
import "./ITRC20.sol";

library SafeTRC20 {
    address internal constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        if (address(token) == USDTAddr) {
            (bool success, ) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success, "SafeTRC20: low-level call failed");
        } else {
            callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        }
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ITRC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeTRC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeTRC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeTRC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }
}

//SourceUnit: SyntheticTRX.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

import "./ISTRX.sol";
import "./Distributable.sol";
import "./SafeTRC20.sol";
import "./TRC20Token.sol";

contract SyntheticTRX is ISTRX, Distributable, TRC20Token {
    using SafeTRC20 for ITRC20;
    
    uint256 internal constant _decimals = 6;

    constructor() TRC20Token(_decimals) public {}
    
    // Mint
    bool public mintable;
    
    function setMintable(bool value) public owned {
        mintable = value;
    }

    function mint() public payable returns (bool) {
        return mintTo(msg.sender);
    }

    function mintTo(address to) public payable returns (bool) {
        require(mintable, "disallowed");
        
        uint256 amount = msg.value;
        require(amount > 0, "nonzero");
        
        _balances[to] = _balances[to].add(amount);
        _supply = _supply.add(amount);

        emit Mint(msg.sender, to, amount);
        return true;
    }
    
    function distribute(address to, uint256 amount) distributed public returns (bool) {
        require(amount > 0, "nonzero");
        
        _balances[to] = _balances[to].add(amount);
        _supply = _supply.add(amount);
        
        emit Distribute(msg.sender, to, amount);
        return true;
    }
    
    // Burn
    bool public burnable;
    
    function setBurnable(bool value) public owned {
        burnable = value;
    }
    
    function burn(uint256 amount) public returns (bool) {
        return burnTo(msg.sender, amount);
    }

    function burnTo(address payable to, uint256 amount) public returns (bool) {
        require(burnable, "disallowed");
        require(amount > 0, "nonzero");
        
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _supply = _supply.sub(amount);
        
        to.transfer(amount);
        
        emit Burn(msg.sender, to, amount);
        return true;
    }
}


//SourceUnit: TRC20Token.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

import "./Rescuable.sol";
import "./ITRC20.sol";
import "./SafeMath.sol";

contract TRC20Token is ITRC20, Rescuable {
    using SafeMath for uint256;

    uint256 _supply;
    uint256 _decimals;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _approvals;
    
    constructor(uint256 decimals) public {
		_balances[address(this)] = _supply = 10 ** (_decimals = decimals);
    }
	
	function decimals() public view returns (uint256) {
        return _decimals;
	}

    function totalSupply() public view returns (uint256) {
        return _supply;
    }
	
    function balance() public view returns (uint256) {
        return balanceOf(msg.sender);
    }

    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }

    function allowance(address src, address guy) public view returns (uint256) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        require(src != dst, "self-transfer");
        
        if (src != msg.sender && _approvals[src][msg.sender] != uint256(-1)) {
            _approvals[src][msg.sender] = _approvals[src][msg.sender].sub(wad);
        }

        _balances[src] = _balances[src].sub(wad);
        _balances[dst] = _balances[dst].add(wad);

        emit Transfer(src, dst, wad);
        return true;
    }
    
    function approve(address guy) public returns (bool) {
        return approve(guy, uint256(-1));
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);
        return true;
    }
    
    string public name = "";
    function setName(string memory name_) public owned {
        name = name_;
    }

    string public symbol = "";
    function setSymbol(string memory symbol_) public owned {
        symbol = symbol_;
    }
}