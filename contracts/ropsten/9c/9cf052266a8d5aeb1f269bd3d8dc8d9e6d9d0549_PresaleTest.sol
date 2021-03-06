/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract Context {
    
    function _msgSender() internal view virtual returns (address payable) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes memory) {this;return msg.data;}
    
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
    }

        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'Cannot divide by zero');
        return a % b;
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
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
     
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
        
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

contract Owned is Context {

    address payable public owner;
    address payable public newOwner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        owner = newOwner;
    }
}

interface IERC20 {}
contract ERC20 is Context, IERC20, Owned {}

library SafeERC20 {
    
    using SafeMath for uint256;
    using Address for address;
    
    function balanceOf(address account) external view returns (uint256) {}
    function safeTransfer(IERC20, address to, uint256 value) internal{}
    function safeTransferFrom(IERC20, address from, address to, uint256 value) internal{}
    function safeApprove(IERC20, address spender, uint256 value) internal{}
    function safeIncreaseAllowance(IERC20, address spender, uint256 value) internal {}
    function safeDecreaseAllowance(IERC20, address spender, uint256 value) internal {}
    function callOptionalReturn(IERC20, bytes memory data) private {}
    }

contract PresaleTest is Context, Owned, IERC20 {
    using SafeMath for uint256;
    
    uint public constant EthCapMin = 0.1 ether;
    uint public constant EthCapMax = 50 ether;
    uint256 public rate = 100;
    uint public startDate = now;
    bool public closed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event ChangeRate(uint256 value);

    mapping(address => uint256) _balances;
    mapping(address => mapping (address => uint256)) private _allowed;
    mapping(address => uint256) public contributions;
    
    function TokenWithdraw(uint value) public virtual onlyOwner {
        _balances[address(this)] = _balances[address(this)].sub(value);
        _balances[owner] = _balances[owner].add(value);
        emit Transfer(address(this), owner, value);
    }
    
    function EtherWithdraw() public virtual onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    function changeRate(uint256 _rate) public virtual onlyOwner {
        rate = _rate;
        emit ChangeRate(rate);
    }
    
    function closeSale() public virtual onlyOwner {
        require(!closed);
        closed = true;
    }
    
    receive() external payable {
        
        uint256 amount = msg.value * rate;
        require(now >= startDate || (msg.sender == owner && msg.value >= EthCapMin));
        require(msg.value >= EthCapMin && msg.value <= EthCapMax);
        require(amount > 0, "Sent less than token price");
        require(amount <= balanceOf(address(this)), "Not have enough available tokens");
        require(!closed);
        if (msg.value == 0) {revert();}
        if (amount == 0) {revert();} 
        _balances[address(this)] = _balances[address(this)].sub(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        emit Transfer(address(this), msg.sender, amount);
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return _balances[tokenOwner];
    }
    
    function transfer(address to, uint value) public returns (bool success) {
        require(_balances[msg.sender] >= value, 'Sender does not have suffencient balance');
        require(to != address(this) || to != address(0), 'Cannot send to yourself or 0x0');
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function burnFrom(address account, uint256 amount) public virtual onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }
}