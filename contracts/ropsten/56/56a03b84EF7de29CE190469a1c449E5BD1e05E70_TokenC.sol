/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity 0.5.16;

library SafeMath {

    function add(uint a, uint b) internal pure returns(uint) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint a, uint b) internal pure returns(uint) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract TokenC{

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;

    address  public owner;
    mapping(address => uint)internal balances;
    mapping(address => mapping(address => uint))internal allowed;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approvel(address indexed _from, address indexed _to, uint _value);

    constructor()public{

        owner = msg.sender;

        name = "Ray";
        symbol = "Re";
        decimals = 18;
         totalSupply = 1000000 * (10 ** decimals);
        balances[owner] = totalSupply;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "ERC20:Only Owner Accessible");
        _;
    }

    function balanceOf(address _user)public view returns(uint _balances){
        return (balances[_user]);
    }


    function allowance(address _sender, address _receiver)public view returns(uint _allowance){
        return (allowed[_sender][_receiver]);
    }

    function transfer(address _to, uint _amount)external returns(bool){

        require(msg.sender != address(0), "ERC20:Sender Address is Invalid");
        require(_to != address(0), "ERC20:Receiver address is Invalid");
        require(balances[msg.sender] >= _amount, "ERC20:Token Value is Invalid");
        require(_amount > 0, "ERC20:Insufficent Amount");

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(msg.sender, _to, _amount);
        return true;

    }

    function approvel(address _receiver, uint _amount)public returns(bool){

        require(msg.sender != address(0), "ERC20:Sender Address is Invalid");
        require(_receiver != address(0), "ERC20:Receiver address is Invalid");
        require(balances[msg.sender] >= _amount, "ERC20:Token Value is Invalid");

        allowed[msg.sender][_receiver] = _amount;
        emit Approvel(msg.sender, _receiver, _amount);
        return true;

    }

    function transferFrom(address _sender, address _receiver, uint _amount)public returns(bool){

        require(_sender != address(0), "ERC20:Sender Address is Invalid");
        require(_receiver != address(0), "ERC20:Receiver address is Invalid");
        require(allowed[_sender][msg.sender] >= _amount, "ERC20:Approvel Token Value is Invalid");
        require(balances[_sender] >= _amount, "ERC20:Sender Token Value is Invalid");

        allowed[_sender][msg.sender] = allowed[_sender][msg.sender].sub(_amount);
        balances[_sender] = balances[_sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);

        emit Transfer(_sender, _receiver, _amount);
        return true;

    }

    function increaseAllowance(address _receiver, uint _amount)public returns(bool){

        require(msg.sender != address(0), "ERC20:Sender Address is Invalid");
        require(_receiver != address(0), "ERC20:Receiver address is Invalid");
        require(allowed[msg.sender][_receiver] > 0, "ERC20:Not Approvel Token Value");
        require(_amount > 0, "ERC20:Insufficent Amount");

        allowed[msg.sender][_receiver] = allowed[msg.sender][_receiver].add(_amount);
        emit Approvel(msg.sender, _receiver, _amount);
        return true;
    }

    function decreaseAllowance(address _receiver, uint _amount)public returns(bool){

        require(msg.sender != address(0), "ERC20:Sender Address is Invalid");
        require(_receiver != address(0), "ERC20:Receiver address is Invalid");
        require(allowed[msg.sender][_receiver] > 0, "ERC20:Not Approvel Token Value");
        require(_amount > 0, "ERC20:Insufficent Amount");

        allowed[msg.sender][_receiver] = allowed[msg.sender][_receiver].sub(_amount);
        emit Approvel(msg.sender, _receiver, _amount);
        return true;
    }

    function mint(address _sender, uint _amount)external onlyOwner{

        require(_sender != address(0), "ERC20:Sender Address is Invalid");
        require(_amount > 0, "ERC20:Token Value is Invalid");

        balances[_sender] = balances[_sender].add(_amount);
        totalSupply = totalSupply.add(_amount);

        emit Transfer(address(0), _sender, _amount);

    }
     function burn(uint _amount)external{

        require(msg.sender != address(0), "ERC20:Address is Invalid");
        require(balances[msg.sender] >= _amount, "ERC20:Token Value is Invalid");
        require(_amount > 0, "ERC20:Insufficent Amount");

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(address(0), msg.sender, _amount);


    }



}