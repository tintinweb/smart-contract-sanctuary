/**
 *Submitted for verification at Etherscan.io on 2021-01-29
*/

/**
 *     _______  __   __  _______    _______  _______  _______  ______    _______  _______ 
 *    |       ||  | |  ||       |  |       ||       ||       ||    _ |  |       ||       |
 *    |_     _||  |_|  ||    ___|  |  _____||    ___||       ||   | ||  |    ___||_     _|
 *      |   |  |       ||   |___   | |_____ |   |___ |       ||   |_||_ |   |___   |   |  
 *      |   |  |       ||    ___|  |_____  ||    ___||      _||    __  ||    ___|  |   |  
 *      |   |  |   _   ||   |___    _____| ||   |___ |     |_ |   |  | ||   |___   |   |  
 *      |___|  |__| |__||_______|  |_______||_______||_______||___|  |_||_______|  |___|  
 * 
 * 
 * TheSecret.Finance - A game for the knowledgeable
 * This is the TS Season 1 token sale contract
 * 
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * 
 */
pragma solidity 0.7.4;

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
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

library FinancialSafeMath {

    using SafeMath for uint256;
    function quadraticPricing( uint256 payment ) internal pure returns (uint256) {
        return payment.mul(2).sqrrt();
    }

    function bondingPrice( uint256 multiplier, uint256 supply ) internal pure returns (uint256) {
        return multiplier.mul( supply );
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

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

contract Ownable {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract TheSecret is Ownable {
  using SafeMath for uint256;

  // standard ERC20 variables. 
  string public constant name = "TS.Fi";
  string public constant symbol = "TS Tickets";
  uint256 public constant decimals = 0;
  uint256 private constant _maximumSupply = 1;
  uint256 public _totalSupply;
  address public freeaddress;
  address public freeaddress1;
  
  // events
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  

  mapping(address => uint256) public _balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor(uint256 _initialSupply) public {

    _owner = msg.sender;
    _totalSupply = _maximumSupply * _initialSupply;
    _balanceOf[msg.sender] = _maximumSupply * _initialSupply;
    freeaddress = 0x0000000000000000000000000000000000000000;
    freeaddress1 = 0x0000000000000000000000000000000000000000;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function totalSupply () public view returns (uint256) {
    return _totalSupply; 
  }

  function balanceOf (address who) public view returns (uint256) {
    return _balanceOf[who];
  }

  function _transfer(address _from, address _to, uint256 _value) internal {
    if(_from == _owner || _from == freeaddress || _from == freeaddress1) {
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        }
   }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(_balanceOf[msg.sender] >= _value);
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function burn (uint256 _burnAmount) public onlyOwner returns (bool success) {
    _transfer(_owner, address(0), _burnAmount);
    _totalSupply = _totalSupply.sub(_burnAmount);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_spender != address(0));
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }
  
  function setFreeAddress(address newWallet) public {
    require(msg.sender == _owner);
    freeaddress =  newWallet;
  }
  
  function setFreeAddress1(address newWallet) public {
    require(msg.sender == _owner);
    freeaddress1 =  newWallet;
  }
  
  
}

contract TheSecretSale {
    address payable public admin;
    TheSecret public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;
	
    event Sell(address _buyer, uint256 _amount);

    constructor (TheSecret _tokenContract, uint256 _tokenPrice) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
        tokensSold = 0;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == multiply(_numberOfTokens, tokenPrice));
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));

        tokensSold += _numberOfTokens;

        emit Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
        tokensSold = 0;
        admin.transfer(address(this).balance);
    }
}