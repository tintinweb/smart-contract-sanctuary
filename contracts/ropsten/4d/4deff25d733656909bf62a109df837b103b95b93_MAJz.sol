pragma solidity 0.4.24;

/****************************************************************************
*                   ******MAJz Token Smart Contract******                   *
*                   Symbol      :   MAZ                                     *
*                   Name        :   MAJz                                    *
*                   Total Supply:   560 000 000                             *
*                   Decimals    :   18                                      *
*                   Almar Blockchain Technology                             *
*                   *************************************                   *
****************************************************************************/


/****************************************************************************
*                       Safemath Library                                    *
*                       to prevent Over / Underflow                         *
****************************************************************************/
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b; assert(c >= a); return c; }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) { assert(b <= a); return a - b; }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0){return 0;} c = a * b; assert(c / a == b); return c; }

    function div(uint256 a, uint256 b) internal pure returns (uint256) { return a / b; }
}


/****************************************************************************
*                   Standart ERC20 Token Interface                          *
*                   Contains Standart Token Functionalities                 *
****************************************************************************/
contract ERC20Token {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _targetAddress) public view returns (uint256);
    function transfer(address _targetAddress, uint256 _value) public returns (bool);
    event Transfer(address indexed _originAddress, address indexed _targetAddress, uint256 _value);
    
    function allowance(address _originAddress, address _targetAddress) public view returns (uint256);
    function approve(address _originAddress, uint256 _value) public returns (bool);
    function transferFrom(address _originAddress, address _targetAddress, uint256 _value) public returns (bool);
    event Approval(address indexed _originAddress, address indexed _targetAddress, uint256 _value);
}


/****************************************************************************
*                       Ownership Contract                                  *
*                       for authorization Control                           *
****************************************************************************/
contract Ownership {
    address public owner;

    modifier onlyOwner() { require(msg.sender == owner); _; }
    modifier validDestination(address _targetAddress) { require(_targetAddress != address(0x0)); _; }
}


/****************************************************************************
*                       The Token Contract                                  *
*                       with Extended funtionalities                        *
****************************************************************************/
contract MAJz is ERC20Token, Ownership {
    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    //Constructor of the Token
    constructor() public{
        symbol = "MAZ";
        name = "MAJz";
        decimals = 18;
        totalSupply = 560000000000000000000000000;
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply); 
    }


    /****************************************************************************
    *                   Basic Token Functions                                   *
    ****************************************************************************/
    //Returns the totalSupply
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    //Return the balance of an specified account
    function balanceOf(address _targetAddress) public view returns (uint256) {
        return balances[_targetAddress];
    }
    
    //Transfer function. Validates targetAdress not to be 0x0
    function transfer(address _targetAddress, uint256 _value) validDestination(_targetAddress) public returns (bool) {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value); //SafeMath will throw if value > balance
        balances[_targetAddress] = SafeMath.add(balances[_targetAddress], _value);
        emit Transfer(msg.sender, _targetAddress, _value); 
        return true; 
    }

    /****************************************************************************
    *                   ERC20 Token Functions                                   *
    ****************************************************************************/
    function allowance(address _originAddress, address _targetAddress) public view returns (uint256){
        return allowed[_originAddress][_targetAddress];
    }

    function approve(address _targetAddress, uint256 _value) public returns (bool) {
        allowed[msg.sender][_targetAddress] = _value;
        emit Approval(msg.sender, _targetAddress, _value);
        return true;
    }

    function transferFrom(address _originAddress, address _targetAddress, uint256 _value) public returns (bool) {
        balances[_originAddress] = SafeMath.sub(balances[_originAddress], _value); //SafeMath will throw if _value> balanceOf[_originAddress]
        allowed[_originAddress][msg.sender] = SafeMath.sub(allowed[_originAddress][msg.sender], _value); //SafeMath will throw if _value > allowance
        balances[_targetAddress] = SafeMath.add(balances[_targetAddress], _value);
        emit Transfer(_originAddress, _targetAddress, _value);
        return true;
    }

    function () public payable {
        revert();
    }

    /****************************************************************************
    *                   Extended Functionalites                                 *
    ****************************************************************************/

    //Burn the specified amount (_value) of tokens
    function burnTokens(uint256 _value) public onlyOwner returns (bool){
        balances[owner] = SafeMath.sub(balances[owner], _value); //SafeMath will throw if value > balance
        totalSupply = SafeMath.sub(totalSupply, _value);
        emit BurnTokens(_value);
        return true;
    }

    //Emit new tokens
    function emitTokens(uint256 _value) public onlyOwner returns (bool){
        balances[owner] = SafeMath.add(balances[owner], _value); //SafeMath will throw if Overflow
        totalSupply = SafeMath.add(totalSupply, _value);
        emit EmitTokens(_value);
        return true;
    }

    //Revert a transfer in case of error. onlyOwner
    function revertTransfer(address _targetAddress, uint256 _value) public onlyOwner returns (bool) {
        balances[_targetAddress] = SafeMath.sub(balances[_targetAddress], _value);
        balances[owner] = SafeMath.add(balances[owner], _value);
        emit RevertTransfer(_targetAddress, _value);
        return true;
    }
    
    event RevertTransfer(address _targetAddress, uint256 _value);
    event BurnTokens(uint256 _value);
    event EmitTokens(uint256 _value);
}