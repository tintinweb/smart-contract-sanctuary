pragma solidity ^0.4.24;

// *-----------------------------------------------------------------------*
//       __ _    ________   __________  _____   __
//      / /| |  / / ____/  / ____/ __ \/  _/ | / /
//     / / | | / / __/    / /   / / / // //  |/ / 
//    / /__| |/ / /___   / /___/ /_/ // // /|  /  
//   /_____/___/_____/   \____/\____/___/_/ |_/  
// *-----------------------------------------------------------------------*


/**
 * @title SafeMath
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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


/**
 * @title Ownable
 */
contract Ownable {

    address public owner;
    
    // _from: oldOwner  _to: newOwner
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "");
        _;
    }

    // Transfer owner
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


/**
 * @title Pausable
 */
contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused {
        require(!paused, "");
        _;
    }
    modifier whenPaused {
        require(paused, "");
        _;
    }

    // Pause contract   
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    // Unpause contract
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }

}



/**
 * @title ERC20 interface
 */
contract ERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    // _from: _owner _to: _spender
    event Approval(address indexed _from, address indexed _to, uint256 _amount);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
}


/**
 * @title ERC20Token
 */
contract ERC20Token is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 public totalToken;

    function totalSupply() public view returns (uint256) {
        return totalToken;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "");
        return balances[_owner];
    }

    // Transfer token by internal
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_from != address(0), "");
        require(_to != address(0), "");
        require(balances[_from] >= _value, "");
        require(balances[_to].add(_value) > balances[_to], "");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "");
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(_from != address(0), "");
        require(_to != address(0), "");
        require(balances[_from] >= _value, "");
        require(allowed[_from][msg.sender] >= _value, "");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool){
        require(_spender != address(0), "");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        require(_owner != address(0), "");
        require(_spender != address(0), "");
        return allowed[_owner][_spender];
    }

}


/**
 * @title LVECoin
 */
contract LVECoin is ERC20Token, Pausable {

    string public  constant name        = "LVECoin";
    string public  constant symbol      = "LVE";
    uint256 public constant decimals    = 18;
    // issue all token(20億)
    uint256 private initialToken        = 2000000000 * (10 ** decimals);
    
    // _to: _freezeAddr
    event Freeze(address indexed _to);
    // _to: _unfreezeAddr
    event Unfreeze(address indexed _to);
    event WithdrawalEther(address indexed _to, uint256 _amount);
    
    // freeze account mapping
    mapping(address => bool) public freezeAccountMap;  
    // wallet Address
    address private walletAddr;


    constructor() public{
        totalToken = initialToken;
        walletAddr = 0x4a26c38d74c7aad9a8c5f60703487572602eba7f;
        balances[msg.sender] = totalToken;
        emit Transfer(0x0, msg.sender, totalToken);
    }

    // is freezeable account
    modifier freezeable(address _addr) {
        require(_addr != address(0), "");
        require(!freezeAccountMap[_addr], "");
        _;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused freezeable(msg.sender) returns (bool) {
        require(_to != address(0), "");
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused freezeable(msg.sender) returns (bool) {
        require(_from != address(0), "");
        require(_to != address(0), "");
        return super.transferFrom(_from, _to, _value);
    }
    function approve(address _spender, uint256 _value) public whenNotPaused freezeable(msg.sender) returns (bool) {
        require(_spender != address(0), "");
        return super.approve(_spender, _value);
    }


    // freeze account
    function freezeAccount(address _freezeAddr) public onlyOwner returns (bool) {
        require(_freezeAddr != address(0), "");
        freezeAccountMap[_freezeAddr] = true;
        emit Freeze(_freezeAddr);
        return true;
    }
    
    // unfreeze account
    function unfreezeAccount(address _freezeAddr) public onlyOwner returns (bool) {
        require(_freezeAddr != address(0), "");
        freezeAccountMap[_freezeAddr] = false;
        emit Unfreeze(_freezeAddr);
        return true;
    }

    // if send ether then send ether to owner
    function() public payable {
        require(msg.value > 0, "");
        walletAddr.transfer(msg.value);
        emit WithdrawalEther(walletAddr, msg.value);
    }

}