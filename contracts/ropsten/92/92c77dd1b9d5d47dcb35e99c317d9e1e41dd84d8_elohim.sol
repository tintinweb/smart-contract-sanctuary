/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

pragma solidity 0.5.7;
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
        require(b > 0);
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
        require(b != 0);
        return a % b;
    }
}
contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract ERC20 is IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender]-value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender]+addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender]-subtractedValue);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from]-value;
        _balances[to] = _balances[to]+value;
        emit Transfer(from, to, value);
    }
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply+value;
        _balances[account] = _balances[account]+value;
        emit Transfer(address(0), account, value);
    }
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply-value;
        _balances[account] = _balances[account]-value;
        emit Transfer(account, address(0), value);
    }
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender]-value);
    }
}
contract ERC20Burnable is ERC20 {
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}
contract ERC20Mintable is ERC20 {
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, bytes calldata _extraData) external;
}

contract elohim is ERC20Mintable, ERC20Burnable {
    string public constant name = "Elohim Coin";
    string public constant symbol = "Eloh";
    uint256 public constant decimals = 18;
    uint256 public initialSupply = (10000000000000000*(10**18));
    constructor () public {
        _mint(msg.sender, initialSupply);
    }

    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData)
        external
        returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, _extraData);
            return true;
        }
    }
}