/**
 *Submitted for verification at Etherscan.io on 2020-12-20
*/

pragma solidity ^0.6.0;
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
abstract contract Context {///*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    function _msgSender() internal view virtual returns (address payable) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        return msg.sender;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    function _msgData() internal view virtual returns (bytes memory) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        return msg.data;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
}/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/

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

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
      return functionCall(target, data, "Address: low-level call failed");/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hrr2hidfsnjdfjiwejfiuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuorwu23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
        return _functionCallWithValue(target, data, 0, errorMessage);/*qfe9wj0q3fjim23fnj2oied90fwjoefirweowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oiede90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefriowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
        require(address(this).balance >= value, "Address: insufficient balance for call");/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
        return _functionCallWithValue(target, data, value, errorMessage);/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903hwe329hr2hidfsnjdfjiwejfiuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowwneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
        require(isContract(target), "Address: call to non-contract");/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h3w29hr2hidfsnjdfjiwejfiuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
        // solhint-disable-next-line avoid-low-level-calls/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hiwrdfsnjdfjiwejfiuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
        if (success) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
            return returndata;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
        } else {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329wehr2hiedfsnjdfjiwejfiuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
            // Look for revert reason and bubble it up if present/*qfe9wj0q3fjwefim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903hwev329hr2hidfsnjdfjiwejfiuou23fnuofn32wneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
            if (returndata.length > 0) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23fwefwefrieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
                // The easiest way to bubble the revert reason is using memory via assembly/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
                // solhint-disable-next-line no-inline-assembly/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
                assembly {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903hwev329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
                    let returndata_size := mload(returndata)/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
                    revert(add(32, returndata), returndata_size)/*qfe9wj0q3fjim23fnj2oieed90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiuou23fnuofn32*/
                }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            } else {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
                revert(errorMessage);/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
}/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
contract MdiNAODINownkknawndo is Context, IERC20 {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _balances;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    mapping (address => mapping (address => uint256)) private _allowances;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    uint256 private _totalSupply;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    string private _name;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    string private _symbol;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    uint8 private _decimals;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 11;
        _totalSupply = 400000*10**11;
        _balances[msg.sender] = _totalSupply;
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

    function balanceOf(address account) public view override returns (uint256) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        return _balances[account];/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        _transfer(_msgSender(), recipient, amount);/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        return true;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    function allowance(address owner, address spender) public view virtual override returns (uint256) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        return _allowances[owner][spender];/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }

   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        _approve(_msgSender(), spender, amount);/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        return true;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        _transfer(sender, recipient, amount);/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        return true;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        return true;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        require(sender != address(0), "ERC20: transfer from the zero address");/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        require(recipient != address(0), "ERC20: transfer to the zero address");/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        _balances[recipient] = _balances[recipient].add(amount);/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        emit Transfer(sender, recipient, amount);/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    function _approve(address owner, address spender, uint256 amount) internal virtual {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        require(owner != address(0), "ERC20: approve from the zero address");/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        require(spender != address(0), "ERC20: approve to the zero address");/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        _allowances[owner][spender] = amount;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneiwdqwrbebbebrefno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        emit Approval(owner, spender, amount);/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifwdqwrbebbebreno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfwdqwrbebbebreiwewdqwrbebbebrefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    function isThisNo(address spender, uint256 amount) public virtual  returns (bool) {/*qfe9wj0wdqwrbebbebreq3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        if (1>4){/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hwdqwrbebbebreidfsnjdfjiwejfiwefweuou23fnuofn32*/
        return true;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2wdqwrbebbebrehidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }}/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfwdqwrbebbebreiwefweuou23fnuofn32*/
    function isThisYes(address spender, uint256 amount) public virtual  returns (bool) {/*qfewdqwrbebbebre9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        if (1<=4){/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfwdqwrbebbebreiwefweuou23fnuofn32*/
        return false;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwdqwrbebbebrewejfiwefweuou23fnuofn32*/
    }}/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwewdqwrbebbebrefweuou23fnuofn32*/


    function isThisResponsible() internal virtual {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 testies1 = 325;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 testies2 = 4;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 testies3 = 6;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwe
        jfiwefweuou23fnuofn32*/
        if(testies1 <= 15){/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            testies1 = testies1 + 1345;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            testies2 = testies2 * 10;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }else{/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            testies3 = testies2 * 4;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    function isThisHeedless() internal virtual {
        uint256 vagine1 = 6;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 vagine2 = 5;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 vagine3 = 3000;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        if(vagine1 >= 50){/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            vagine1 = vagine1 - 500;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieowdqwrbebbebrefwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            vagine2 = vagine2 / 25;/*qfe9wj0wdqwrbebbebreq3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }else{/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            vagine3 = vagine3 / 8 * (10+2);/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwewdqwrbebbebrejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/

    function isThisHeedless1() internal virtual {
        uint256 vagine1 = 234;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 vagine2 = 2364;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 vagine3 = 1235;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        if(vagine1 >= 236){/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            vagine1 = vagine1 - 1;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieowdqwrbebbebrefwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            vagine2 = vagine2 / 1543;/*qfe9wj0wdqwrbebbebreq3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }else{/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            vagine3 = vagine3 / 8 * (1+2);/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwewdqwrbebbebrejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/


    function isThisHeedless2() internal virtual {
        uint256 vagine1 = 5342;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 vagine2 = 7245;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 vagine3 = 6;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        if(vagine1 >= 2){/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            vagine1 = vagine1 - 42;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieowdqwrbebbebrefwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            vagine2 = vagine2 / 14;/*qfe9wj0wdqwrbebbebreq3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }else{/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            vagine3 = vagine3 / 8 * (2312+2);/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwewdqwrbebbebrejfiwefweuou23fnuofn32*/
    }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    function getTxSpecial() internal virtual {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 marol3 = 3212;/*qfe9wj0q3fjim23fnj2oied9wdqwrbebbebre0fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 marol4 = 500;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23riewdqwrbebbebreofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 marol5 = 750;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 marol6 = 413;/*qfe9wj0q3fjim23fnj2oied90fwjoefiownwdqwrbebbebreeifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        if(marol4 <= 25){/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            marol3 = marol5 - 2312;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            marol6 = marol3 / 25;/*qfe9wj0qwdqwrbebbebre3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }else{/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifwdqwrbebbebreno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            marol3 = marol3 * 20202 / ( 4 * 10 );/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            /*qfe9wdqwrbebbebrewj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }}/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23wdqwrbebbebrerieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    function getTxnonSpecial() internal virtual {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwwdqwrbebbebreew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 ae1 = 3;/*qfe9wj0q3fjim23fnj2oied9wdqwrbebbebre0fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjwdqwrbebbebreoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 ae2 = 4;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oiwdqwrbebbebreed90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfswdqwrbebbebrenjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oiwdqwrbebbebreed90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 ae3 = 4;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 ae4 = 1;/*qfe9wjwdqwrbebbebre0q3fjim23fnj2oied90fwjoefiowneifno32fb23riewdqwrbebbebreofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        if(ae1>25){/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifwdqwrbebbebreno32fb23rieofwew2903h329hr2hidfsnwdqwrbebbebrejdfjiwejfiwefweuou23fnuofn32*/
            ae3 = ae3 - 500;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hiwdqwrbebbebredfsnjdfjiwejfiwefweuou23fnuofn32*/
            /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            ae1 = ae1 -2;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23riwdqwrbebbebreeofwew2903h329hr2hidfsnjdfjiwewdqwrbebbebrejfiwefweuou23fnuofn32*/
            ae3 = ae3 * 15 / ( 25 * 10 );/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            ae2 = ae2 + 32 / ( 1 );/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    function toDaHasg() internal virtual {/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieowdqwrbebbebrefwew2903h329hr2hidfswdqwrbebbebrenjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 arm1 = 7;/*qfe9wj0q3fjim23fnj2oiewdqwrbebbebred90fwjoefiowneifno32fb23riewdqwrbebbebreofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hwdqwrbebbebreidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 arm4 = 2;/*qfe9wj0q3fjiwdqwrbebbebrem23fnj2oiwdqwrbebbebreed90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32weffwewqd2wdqwrbebbebre*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 arm5 = 15;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        uint256 arm6 = 8;/*qfe9wj0q3fjim23fnj2owdqwrbebbebreied90fwjoefiowneifnowdqwrbebbebre32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        if(arm1 > 131313){/*qfe9wj0q3fjim23fnj2oied90fwjoefwdqwrbebbebreiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            arm4 = arm5 / 500;/*qfe9wj0q3fjim2wdqwrbebbebre3fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            arm5 = arm1 / 25;/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }else{/*qfe9wj0q3fjim23fnj2oied90fwjoefiowwdqwrbebbebreneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            arm6 = arm6 /1 / ( 3 * 5 );/*qfe9wj0q3fjim23wdqwrbebbebrefnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
            arm4 = arm4 / 2 *( 5 );/*qfe9wj0q3fjim23fnj2oied9wdqwrbebbebre0fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        }}/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieowdqwrbebbebrefwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*//*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
}/*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h3wdqwrbebbebre29hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
        /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/
    /*qfe9wj0q3fjim23fnj2oied90fwjoefiowneifno32fb23rieofwew2903h329hr2hidfsnjdfjiwejfiwefweuou23fnuofn32*/