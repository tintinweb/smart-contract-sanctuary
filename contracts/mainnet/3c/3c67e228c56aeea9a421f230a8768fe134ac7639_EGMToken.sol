pragma solidity 0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of user permissions.
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public{
        owner = msg.sender;
    }


  /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * @title ERC20
 * @dev ERC20 interface
 */
contract ERC20 {            
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function mint(uint256 value) public returns (bool);
    function burn(uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}





/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

/**
 * eGold Mining Token
 */


contract EGMToken is ERC20, Ownable {

    using SafeMath for uint256;

    uint256  public  totalSupply = 20000000 * 1 ether;

    mapping  (address => uint256)             public          _balances;
    mapping  (address => mapping (address => uint256)) public  _approvals;


    string   public  name = "EGM Token";
    string   public  symbol = "EGM";
    uint256  public  decimals = 18;

    event Mint(uint256 wad);
    event Burn(uint256 wad);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

    constructor () public{
        _balances[msg.sender] = totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) public view returns (uint256) {
        return _approvals[src][guy];
    }
    
    function transfer(address dst, uint256 wad) public returns (bool) {
        require(dst != address(0));
        require(wad > 0 && _balances[msg.sender] >= wad);
        _balances[msg.sender] = _balances[msg.sender].sub(wad);
        _balances[dst] = _balances[dst].add(wad);
        emit Transfer(msg.sender, dst, wad);
        return true;
    }
    
    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        require(src != address(0));
        require(dst != address(0));
        require(wad > 0 && _balances[src] >= wad && _approvals[src][msg.sender] >= wad);
        _approvals[src][msg.sender] = _approvals[src][msg.sender].sub(wad);
        _balances[src] = _balances[src].sub(wad);
        _balances[dst] = _balances[dst].add(wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    
    function approve(address guy, uint256 wad) public returns (bool) {
        require(guy != address(0));
        require(wad > 0 && wad <= _balances[msg.sender]);
        _approvals[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function mint(uint256 wad) public onlyOwner returns (bool) {
        require(wad > 0);
        _balances[msg.sender] = _balances[msg.sender].add(wad);
        totalSupply = totalSupply.add(wad);
        emit Mint(wad);
        return true;
    }

    function burn(uint256 wad) public onlyOwner returns (bool)  {
        require(wad > 0 && wad <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender].sub(wad);
        totalSupply = totalSupply.sub(wad);
        emit Burn(wad);
        return true;
    }
}