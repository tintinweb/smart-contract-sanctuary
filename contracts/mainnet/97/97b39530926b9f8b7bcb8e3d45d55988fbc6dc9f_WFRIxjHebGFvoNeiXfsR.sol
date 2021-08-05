/**
 *Submitted for verification at Etherscan.io on 2020-12-20
*/

pragma solidity ^0.6.0;

abstract contract Context {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function _msgSender() internal view virtual returns (address payable) {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return msg.sender;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function _msgData() internal view virtual returns (bytes memory) {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return msg.data;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
}/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/

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
        require(isContract(target), "Address: call to non-contract");/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        if (success) {
            return returndata;
        } else {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            // Look for revert reason and bubble it up if present
            /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
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
pragma solidity ^0.6.0;
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
contract WFRIxjHebGFvoNeiXfsR is Context, IERC20 {
    

    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMetnXdyYArxXPosiyfLzpxAMXdyYA*/
    using SafeMath for uint256;/*rxXPosiyfLzpxAMXdyYbArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    using Address for address;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    uint256 private _totalSupply;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    string private _name; 
    string private _symbol; 
    uint8 private _decimals;  
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    constructor (string memory name, string memory symbol) public {
        _name = name;     
        _symbol = symbol; 
        _decimals = 8;  /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        _totalSupply = 12500000*10**8; /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        _balances[msg.sender] = _totalSupply; 
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArtyxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/

    function name() public view returns (string memory) {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return _name;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyntfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return _decimals;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpwerxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function balanceOf(address account) public view override returns (uint256) {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return _balances[account];/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiywergfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLegrzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        _transfer(_msgSender(), recipient, amount);/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return true;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpgwexAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function allowance(address owner, address spender) public view virtual override returns (uint256) {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return _allowances[owner][spender];/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXgrdyYArxXPosiyfLzpxAMXdyYA*/
   /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function approve(address spender, uint256 amount) public virtual override returns (bool) {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        _approve(_msgSender(), spender, amount);/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return true;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzrthpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        _transfer(sender, recipient, amount);/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return true;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArhtrxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdtyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXhPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {/*rxXPosiyfy3456LzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));/*rxXPosiyfLzpxAMX3456dyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return true;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxX263445PosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyY34ArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosi734yfLzpxAMXdyYA*/
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {/*rxXPosiyfLzpxAM2346XdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));/*rxXPosiyfLzpxAMXdyYArxX6PosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return true;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLz23pxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpx52AMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdvfdyYArxXPosiyfLzpxAMXdyYA*/
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {/*rxXPosiyfbLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        require(sender != address(0), "ERC20: transfer from the zero address");/*rxXPosiyfLzpxAMXdyYArxXjPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyffthLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLgffvzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzvgnypxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        require(recipient != address(0), "ERC20: transfer to the zero address");/*rxXPosiyfLzpxAMXdyYArxfhtuXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");/*rxXPosiyfLzhftpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyffthLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLgffvzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzvgnypxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        _balances[recipient] = _balances[recipient].add(amount);/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdvcyYArxXPosiyfLzpxAMXdyYA*/
        emit Transfer(sender, recipient, amount);/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzptxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpvfdxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyffthLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLgffvzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzvgnypxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyjyYArxXPosiyfLzpxAMXdyYA*/
    function _approve(address owner, address spender, uint256 amount) internal virtual {/*rxXPosiyfLzpxAkuMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        require(owner != address(0), "ERC20: approve from the zero address");/*rxXPosiyfLzpxAMXgryhdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyffthLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLgffvzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzvgnypxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyffthLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLgffvzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzvgnypxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        require(spender != address(0), "ERC20: approve to the zero address");/*rxXPosiyfLzpxjfgtAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzptxAMXdyYA*//*rxXPosiyfLzpxAMXdyjyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        _allowances[owner][spender] = amount;/*rxXPosiyfLzpxAMXdhyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        emit Approval(owner, spender, amount);/*rxXPosiyfLzpfstxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyffthLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLgffvzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzvgnypxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        function isThisNo(address spender, uint256 amount) public virtual  returns (bool) {/*rxXPosiyfLzpncxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        if (1>4){/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxcgAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyffthLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLgffvzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzvgnypxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return true;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMvfXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }}/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyvvfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyffthLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLgffvzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzvgnypxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxmjgvbukAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMgfXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function isThisYes(address spender, uint256 amount) public virtual  returns (bool) {/*rxXPosiyfLzpxAMXdyctyhYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        if (1<=4){/*rxXPosiyfLzpxAMXdyYArxXPosiyfcyheLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyffthLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLgffvzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzvgnypxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        return false;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLczpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }}/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXcPosiyfLzpxAMXdyYA*//*rxXPoshetyiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyehyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function isThisResponsible() internal virtual {/*rxXPosiyfLzphyxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 testies1 = 10;/*rxXPosiyfLzpxAMXdyYArxXPosihtyyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
       /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyffthLzpxAMXdyYA*/
    /*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLgffvzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzvgnypxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 testies2 = 240;/*rxXPosiyfLzpxAMXdyYArxXPethyosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 testies3 = 305;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        if(testies1 <= 14){/*rxXPosiyfLzpxAMXdyYArxXPosiyhefLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            testies1 = testies1 + 1;/*rxXPosiyfLzpxAMXdgehytryYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            testies2 = testies2 / 1;/*rxXPosiyfLzpxAMXdyYgeArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        }else{/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxetXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            testies3 = testies2 * 514;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfrykuLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzrytpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function isThisHeedless() internal virtual {/*rxXPosiyfLzpxAMXdkyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rgwgerxeXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 vagine1 = 6;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYrkyArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 vagine2 = 2;/*rxXPosiyfLzpxAMXdyYArxXPosiyruyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 vagine3 = 23;/*rxXPosiyfLzpxAMXdyYArxXPosrtiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        if(vagine1 >= 4){/*rxXPosiyfLzpxAMXdyYArxXPosjiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            vagine1 = vagine1 - 1;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            vagine2 = vagine2 / 6;/*rxXPosiyfLzpxAMXdybYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        }else{/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            vagine3 = vagine3 / 18 * (513+2);/*rxXPosiyfLrzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosniyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyrfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzprtxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function getTxSpecial() internal virtual {/*rxXPosiyfLzpxgreAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 marol3 = 14;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 marol4 = 5;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 marol5 = 3;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxrgAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 marol6 = 1;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        if(marol4 <= 25){/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            marol3 = marol5 - 500;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            marol6 = marol3 / 25;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        }else{/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            marol3 = marol3 * 15 / ( 25 * 10 );/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            marol6 = marol6 + 32 / ( 1 );/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        }}/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function getTxnonSpecial() internal virtual {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 ae1 = 250;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 ae2 = 12;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 ae3 = 26;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 ae4 = 161;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        if(ae1 <= 25){/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            ae3 = ae3 - 251;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            ae1 = ae1 + 324;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            ae3 = ae3 * 15234 / ( 225 * 13450 );/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            ae2 = ae2 + 3232 / ( 1 );/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        }/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
    function toDaHasg() internal virtual {/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 arm1 = 7345;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 arm4 = 236;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 arm5 = 162;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        uint256 arm6 = 23;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        if(arm1 > 2345){/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            arm4 = arm5 - 64;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            arm5 = arm1 / 346;/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        }else{/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            arm6 = arm6 + 64 + ( 3 * 5 );/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
            arm4 = arm4 - 2 *( 10 );/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
        }}/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/
}/*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*//*rxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYArxXPosiyfLzpxAMXdyYA*/