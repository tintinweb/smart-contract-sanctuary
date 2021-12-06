/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

pragma solidity ^0.4.24;

contract ERC20Interface{
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract DesiCoin is ERC20Interface{
    string private _name = "DesiCoin";
    string private _symbol = "DSC";
    uint private _supply = 0;
    uint8  private _decimals = 0;
    address public founder;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() public{
        founder = msg.sender;
        _supply = 1000000;
        balances[founder] = _supply;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        require(balances[msg.sender] >= _value );

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(allowed[_from][_to] >= _value);
        require(balances[_from] >= _value );

        balances[_to] += _value;
        balances[_from] -= _value;

        allowed[_from][_to] -= _value;
        return true;
    }

    function name() public view returns(string){
        return _name;
    }

    function symbol() public view returns(string){
        return _symbol;
    }

    function decimals() public view returns (uint8){
        return _decimals;
    }

    function totalSupply() public view returns (uint256){
        return _supply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender] >= _value);

        balances[_to] += _value;
        balances[msg.sender] -= _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

}


contract DesiICO is DesiCoin{
    address public admin;
    address public deposit;

    uint tokenPrice = 1000000000000000;

    uint public hardCap = 300000000000000000000;

    uint public raisedAmount;
    uint public saleStart = now;
    uint public saleEnd = saleStart + 2419200;
    uint public coinStartTrade = saleEnd + 604800;
    uint public maxInvestment = 5000000000000000000;
    uint public minInvestment = 100000000000000;

    enum State {beforeStart, running, afterEnd, halted}

    State public icoState;

	event InvestEvent(address investor, uint value, uint tokens);

    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }

    constructor(address _deposit) public{
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }

    function halt() public onlyAdmin{
        icoState = State.halted;
    }

    function restart() public onlyAdmin{
        icoState = State.running;
    }

    function changeDepositAddress(address newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }

    function getCurrentState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }

    function invest() public payable returns(bool){
		icoState = getCurrentState();
		
		require(icoState == State.running);
		require(msg.value >= minInvestment && msg.value <= maxInvestment);

		uint tokens = msg.value / tokenPrice;

		require(raisedAmount + msg.value <= hardCap);

		raisedAmount += msg.value;

		balances[msg.sender] += tokens;
		balances[founder] -= tokens;

		deposit.transfer(msg.value);
		emit InvestEvent(msg.sender, msg.value, tokens);
		return true;
    }

	function transfer(address _to, uint256 _value) public returns (bool success){
		require(block.timestamp > coinStartTrade);
		super.transfer(_to, _value);

		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
		require(block.timestamp > coinStartTrade);
		super.transferFrom(_from, _to, _value);

		return true;
	
	}

	function burn() public{
		icoState = getCurrentState();

		require(icoState == State.afterEnd);
		balances[founder] = 0;
	}

	function () payable  public{
		invest();
	}
}