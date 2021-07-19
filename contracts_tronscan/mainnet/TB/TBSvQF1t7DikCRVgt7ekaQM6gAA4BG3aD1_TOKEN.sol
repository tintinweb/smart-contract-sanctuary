//SourceUnit: BlackList.sol

pragma solidity ^0.5.10;

import "./Ownable.sol";


contract BlackList is Ownable {


    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    mapping (address => bool) public isBlackListed;

    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    event AddedBlackList(address indexed _user);

    event RemovedBlackList(address indexed _user);

}


//SourceUnit: ITRC20.sol

pragma solidity ^0.5.10;


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


//SourceUnit: ITRC677.sol

pragma solidity ^0.5.10;

import "./ITRC20.sol";

contract  ITRC677 is ITRC20{
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


//SourceUnit: Ownable.sol

pragma solidity ^0.5.10;

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


//SourceUnit: StandardTokenWithFees.sol

pragma solidity ^0.5.10;

import "./TRC20.sol";
import "./Ownable.sol";

contract StandardTokenWithFees is TRC20 {

    // Additional variables for use if transaction fees ever became necessary
    uint256 public basisPointsRate = 0;
    uint256 public maximumFee = 0;

    mapping (address => bool) public isWhiteList ;


    function  calcFee(uint _value) view private returns (uint) {
        if(isWhiteList[msg.sender]){
            return 0;
        }
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        return fee;
    }

    function transfer(address _to, uint _value) public returns (bool) {
        uint fee =calcFee(_value);

        uint sendAmount = _value.sub(fee);

        super.transfer(_to, sendAmount);
        if (fee > 0) {
            super.transfer(owner, fee);
        }
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint fee = calcFee(_value);
        uint sendAmount = _value.sub(fee);

        super.transferFrom(_from,_to,sendAmount);
        if (fee > 0) {
            super.transferFrom(_from,owner,fee);
        }
        return true;
    }

    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(uint(10)** decimals());
        emit  Params(basisPointsRate, maximumFee);
    }


    function  addWhiteList(address addr) public onlyOwner{
        isWhiteList[addr] = true;
        emit AddedWhiteList(addr);
    }
    function  removeWhiteList(address addr) public onlyOwner{
        isWhiteList[addr] = false;
        emit RemovedWhiteList(addr);
    }

    function getWhiteListStatus(address _maker) external view returns (bool) {
        return isWhiteList[_maker];
    }

    // Called if contract ever adds fees
    event Params(uint feeBasisPoints, uint maxFee);

    event AddedWhiteList(address indexed _user);

    event RemovedWhiteList(address indexed _user);

}


//SourceUnit: TOKEN.sol

pragma solidity ^0.5.10;

import "./TRC677.sol";

contract TOKEN is TRC677 {

    constructor () public TRC20Detailed("MCOW", "MCOW", 2) {
        _mint(msg.sender, 1e11 * (10 ** uint(decimals())));
    }


}


//SourceUnit: TRC20.sol

pragma solidity ^0.5.10;

import "./SafeMath.sol";
import "./TRC20Detailed.sol";
import "./BlackList.sol";

contract TRC20 is TRC20Detailed,BlackList {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(!isBlackListed[msg.sender]);
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        _mint(account,amount);
        return true;
    }

    function burn(address account, uint256 value)  public onlyOwner returns (bool) {
        _burn(account,value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function burnFrom(address account, uint256 amount) public returns (bool) {
        _burnFrom(account,amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(!isBlackListed[sender]);
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), " transfer from the zero address");
        require(recipient != address(0), " transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), " mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), " burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), " approve from the zero address");
        require(spender != address(0), " approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}


//SourceUnit: TRC20Detailed.sol

pragma solidity ^0.5.10;

import "./ITRC20.sol";

contract TRC20Detailed is ITRC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}



//SourceUnit: TRC677.sol

pragma solidity ^0.5.10;

import "./ITRC677.sol";
import "./StandardTokenWithFees.sol";
import "./TRC677Receiver.sol";

contract TRC677 is ITRC677,StandardTokenWithFees{

    /**
    * @dev transfer token to a contract address with additional data if the recipient is a contact.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data The extra data to be passed to the receiving contract.
    */
    function transferAndCall(address _to, uint _value, bytes memory _data) public returns (bool success){
        super.transfer(_to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
            contractFallback(_to, _value, _data);
        }
        return true;
    }


    // PRIVATE

    function contractFallback(address _to, uint _value, bytes memory _data) private{
        TRC677Receiver receiver = TRC677Receiver(_to);
        receiver.onTokenTransfer(msg.sender, _value, _data);
    }

    function isContract(address _addr) private view returns (bool hasCode){
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }
}


//SourceUnit: TRC677Receiver.sol

pragma solidity ^0.5.10;


contract TRC677Receiver {
    function onTokenTransfer(address _sender, uint _value, bytes calldata _data) external;
}