/**
 *Submitted for verification at Etherscan.io on 2021-02-05
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

contract Destructible is Owned {

    function destroy() public onlyOwner {selfdestruct(owner);}
    
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

contract ERC20Capped is IERC20 {
    
    using SafeMath for uint256;
    uint256 public MaxSupply;

    constructor (uint256) internal {
        require(MaxSupply <= 2500000e18, "cannot be exceeded");
        MaxSupply = MaxSupply;

    }
    
    function cap() public view returns (uint256) {
        return MaxSupply;

    }
}

contract Fiscus is Context, Owned, IERC20, Destructible {

    using SafeMath for uint256;
    
    string public constant name = "Fiscus";
    string public constant symbol = "FISCUS";
    uint8 public constant decimals = 18;
    
    uint256 public _totalSupply;
    uint256 public MaxSupply;
    uint256 private supply;

    uint public constant EthCapMin = 0.01 ether;
    uint public constant EthCapMax = 50 ether;

    uint256 public Rate = 100;
    uint public startDate = now;
    bool public closed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Purchase(address indexed purchaser, uint256 value);
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
    
    function changeRate(uint256 _Rate) public virtual onlyOwner {
        Rate = _Rate;
        emit ChangeRate(Rate);

    }
    
    function closeSale() public virtual onlyOwner {
        require(!closed);
        closed = true;
        
    }
    
    receive() external payable {
        
        uint256 amount = msg.value * Rate;
        
        require(now >= startDate || (msg.sender == owner && msg.value >= EthCapMin));
        require(msg.value >= EthCapMin, "Sender cannot sent less than minimum");
        require(msg.value <= EthCapMax, "Sender cannot sent exceed than maximum");
        require(amount > 0, "Sent less than token price");
        require(amount <= balanceOf(address(this)), "Not have enough available tokens");
        require(!closed);
        
        _balances[address(this)] = _balances[address(this)].sub(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _totalSupply = _balances[owner] + _balances[address(this)] + _balances[msg.sender];
        
        emit Transfer(address(this), msg.sender, amount);

    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return _balances[tokenOwner];

    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
        
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return _allowed[tokenOwner][spender];

    }

    function transfer(address to, uint value) public returns (bool success) {
        require(_balances[msg.sender] >= value, 'Sender does not have suffencient balance');
        require(to != address(this) || to != address(0), 'Cannot send to yourself or 0x0');
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;

    }

    function approve(address spender, uint value) public returns (bool success) {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;

    }

    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(value <= balanceOf(from), "Token Holder does not have enough balance");
        require(value <= allowance(from, msg.sender), "Transfer not approved by token holder");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;

    }
    
    function mint(address account, uint256 amount) public virtual onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, _totalSupply);
        
    }
    
    function burn(address account, uint256 amount) public virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        
    }
    
    function burnFrom(address account, uint256 amount) public virtual onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        
    }
    
    constructor() public {

        owner = msg.sender;
        _balances[address(this)] = 75000e18;
        supply = 75000e18;
        emit Transfer(address(0), address(this), 75000e18);
        mint(msg.sender, 425000e18);
        MaxSupply = 2500000e18;
        
    }
    
}