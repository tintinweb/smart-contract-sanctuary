pragma solidity 0.4.21;

contract Maths {

    function Mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function Div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function Sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function Add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

}

contract Owned is Maths {

    address public owner;
    address public collector;
    bool public transfer_status = true;
    event OwnershipChanged(address indexed _invoker, address indexed _newOwner);        
    event TransferStatusChanged(bool _newStatus);
    uint256 public TotalSupply = 500000000000000000000000000;
    mapping(address => uint256) UserBalances;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
        
    function Owned() public {
        owner = msg.sender;
        collector = msg.sender;
    }

    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function ChangeOwner(address _AddressToMake) public _onlyOwner returns (bool _success) {

        owner = _AddressToMake;
        emit OwnershipChanged(msg.sender, _AddressToMake);

        return true;

    }
    
    function ChangeCollector(address _AddressToMake) public _onlyOwner returns (bool _success) {

        collector = _AddressToMake;

        return true;

    }

    function ChangeTransferStatus(bool _newStatus) public _onlyOwner returns (bool _success) {

        transfer_status = _newStatus;
        emit TransferStatusChanged(_newStatus);
    
        return true;
    
    }
	
   function Mint(uint256 _amount) public _onlyOwner returns (bool _success) {

        TotalSupply = Add(TotalSupply, _amount);
        UserBalances[msg.sender] = Add(UserBalances[msg.sender], _amount);
	
    	emit Transfer(address(0), msg.sender, _amount);

        return true;

    }

    function Burn(uint256 _amount) public _onlyOwner returns (bool _success) {

        require(Sub(UserBalances[msg.sender], _amount) >= 0);
        TotalSupply = Sub(TotalSupply, _amount);
        UserBalances[msg.sender] = Sub(UserBalances[msg.sender], _amount);
	
	    emit Transfer(msg.sender, address(0), _amount);

        return true;

    }
        
}

contract Core is Owned {

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event OrderPaid(uint256 indexed _orderID, uint256 _value);

    string public name = "CoinMarketAlert";
    string public symbol = "CMA";
    uint256 public decimals = 18;
    mapping(uint256 => bool) public OrdersPaid;
    mapping(address => mapping(address => uint256)) public Allowance;

    function Core() public {

        UserBalances[msg.sender] = TotalSupply;

    }

    function _transferCheck(address _sender, address _recipient, uint256 _amount) private view returns (bool success) {

        require(transfer_status == true);
        require(_amount > 0);
        require(_recipient != address(0));
        require(UserBalances[_sender] >= _amount);
        require(Sub(UserBalances[_sender], _amount) >= 0);
        require(Add(UserBalances[_recipient], _amount) > UserBalances[_recipient]);
        
        return true;

    }
    
    function payOrder(uint256 _orderID, uint256 _amount) public returns (bool status) {
        
        require(OrdersPaid[_orderID] == false);
        require(_transferCheck(msg.sender, collector, _amount));
        UserBalances[msg.sender] = Sub(UserBalances[msg.sender], _amount);
        UserBalances[collector] = Add(UserBalances[collector], _amount);
		OrdersPaid[_orderID] = true;
        emit OrderPaid(_orderID,  _amount);
		emit Transfer(msg.sender, collector, _amount);
        
        return true;
        

    }

    function transfer(address _receiver, uint256 _amount) public returns (bool status) {

        require(_transferCheck(msg.sender, _receiver, _amount));
        UserBalances[msg.sender] = Sub(UserBalances[msg.sender], _amount);
        UserBalances[_receiver] = Add(UserBalances[_receiver], _amount);
        emit Transfer(msg.sender, _receiver, _amount);
        
        return true;

    }

    function transferFrom(address _owner, address _receiver, uint256 _amount) public returns (bool status) {

        require(_transferCheck(_owner, _receiver, _amount));
        require(Sub(Allowance[_owner][msg.sender], _amount) >= 0);
        Allowance[_owner][msg.sender] = Sub(Allowance[_owner][msg.sender], _amount);
        UserBalances[_owner] = Sub(UserBalances[_owner], _amount);
        UserBalances[_receiver] = Add(UserBalances[_receiver], _amount);
        emit Transfer(_owner, _receiver, _amount);

        return true;

    }

    function multiTransfer(address[] _destinations, uint256[] _values) public returns (uint256) {

		for (uint256 i = 0; i < _destinations.length; i++) {
            require(transfer(_destinations[i], _values[i]));
        }

        return (i);

    }

    function approve(address _spender, uint256 _amount) public returns (bool approved) {

        require(_amount >= 0);
        Allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);

        return true;

    }

    function balanceOf(address _address) public view returns (uint256 balance) {

        return UserBalances[_address];

    }

    function allowance(address _owner, address _spender) public view returns (uint256 allowed) {

        return Allowance[_owner][_spender];

    }

    function totalSupply() public view returns (uint256 supply) {

        return TotalSupply;

    }

}