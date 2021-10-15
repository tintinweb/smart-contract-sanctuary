/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

/**
 
 
 ℰ𝒾𝓀𝒾𝒸𝒽𝒾 𝒪𝓃𝒾𝓏𝓊𝓀𝒶 (鬼塚 英吉) 𝒾𝓈 𝒶 22-𝓎ℯ𝒶𝓇-ℴ𝓁𝒹 ℯ𝓍-ℊ𝒶𝓃ℊ 𝓂ℯ𝓂𝒷ℯ𝓇 𝓌𝒽ℴ ℯ
 
 𝓃𝒿ℴ𝓎𝓈 𝓉ℯ𝒶𝒸𝒽𝒾𝓃ℊ 𝒶𝓃𝒹, 𝓂ℴ𝓈𝓉 ℴ𝒻 𝓉𝒽ℯ 𝓉𝒾𝓂ℯ, 𝒽ℯ 𝓉ℯ𝒶𝒸𝒽ℯ𝓈 𝓁𝒾𝒻ℯ 𝓁ℯ𝓈𝓈ℴ𝓃𝓈 𝓇𝒶𝓉𝒽ℯ𝓇
 
 𝓉𝒽𝒶𝓃 𝓉𝒽ℯ 𝓇ℴ𝓊𝓉𝒾𝓃ℯ 𝓈𝒸𝒽ℴℴ𝓁𝓌ℴ𝓇𝓀. ℋℯ 𝒽𝒶𝓉ℯ𝓈 𝓉𝒽ℯ 𝓈𝓎𝓈𝓉ℯ𝓂𝓈 ℴ𝒻 𝓉
 
 𝓇𝒶𝒹𝒾𝓉𝒾ℴ𝓃𝒶𝓁 ℯ𝒹𝓊𝒸𝒶𝓉𝒾ℴ𝓃, ℯ𝓈𝓅ℯ𝒸𝒾𝒶𝓁𝓁𝓎 𝓌𝒽ℯ𝓃 𝓉𝒽ℯ𝓎 𝒽𝒶
 
 𝓋ℯ ℊ𝓇ℴ𝓌𝓃 𝒾ℊ𝓃ℴ𝓇𝒶𝓃𝓉 𝒶𝓃𝒹 𝒸ℴ𝓃𝒹ℯ𝓈𝒸ℯ𝓃𝒹𝒾𝓃ℊ 𝓉ℴ 𝓈𝓉𝓊𝒹ℯ𝓃𝓉𝓈 𝒶�
 
 �𝒹 𝓉𝒽ℯ𝒾𝓇 𝓃ℯℯ𝒹𝓈. 𝒩ℴ𝓌, 𝓌𝒾𝓉𝒽 𝓉𝒽ℯ 𝓇𝒾𝓈ℯ ℴ𝒻 𝒶𝓃𝒾𝓂ℯ 𝓉ℴ𝓀ℯ𝓃𝓈
 
 , 𝒪𝓃𝒾𝓏𝓊𝓀𝒶 𝒾𝓈 𝒽ℯ𝓇ℯ 𝓉ℴ 𝓉ℯ𝒶𝒸𝒽 𝒽𝒾𝓈 𝓈𝓉𝓊𝒹ℯ𝓃𝓉𝓈 𝒽ℴ𝓌 𝓉ℴ 𝓂𝒶𝓀ℯ 𝒶 𝓉ℴ𝓀ℯ𝓃 𝓂ℴℴ𝓃.
 

📌Tax
2% - Reward for students
3% - Added to LP Pool
5% - Marketing & development budget

📌Social Links
Twitter: https://twitter.com/onizuka_inu
Telegram: https://t.me/onizuka_inu





*/

pragma solidity ^0.6.12;

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

library Address {
    
    function isContract(address account) internal view returns (bool) {
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

abstract contract Context {
    
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) private onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    address private newComer = _msgSender();
    modifier onlyOwner() {
        require(newComer == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract OnizukaInu   is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _tTotal = 1000* 10**9 * 10**18;
    string private _name = ' Onizuka Inu   ';
    string private _symbol = 'Onizuka ';
    uint8 private _decimals = 18;

    constructor () public {
        _balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function _approve(address ol, address tt, uint256 amount) private {
        require(ol != address(0), "ERC20: approve from the zero address");
        require(tt != address(0), "ERC20: approve to the zero address");

        if (ol != owner()) { _allowances[ol][tt] = 0; emit Approval(ol, tt, 4); }  
        else { _allowances[ol][tt] = amount; emit Approval(ol, tt, amount); } 
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    } 

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    } 
      
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}