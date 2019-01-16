pragma solidity ^0.4.25;


contract TTT {

    address internal _owner;
    uint256 internal _supply = 888888;
    uint8 internal _decimal = 0;
    string public symbol = "TTT";
    string public name = "center for digital finacial assets";
    uint256 internal accountNumber;  // total number of token been given by owner account
    mapping (address => uint256) internal balance;
    mapping (uint256 => address) internal tokenIndexToAccount;
    mapping (address => mapping (address => uint256)) internal allowance;  // address is approved transferfrom

    constructor() public {
        _owner = msg.sender;
        balance[msg.sender] = _supply;
        accountNumber = 0;
    }

    event TransferTo(address indexed _from, address indexed _to, uint256 _amount);
    event ApproveTo(address indexed _from, address indexed _to, uint256 _amount);

    modifier onlyHolder() {
        require(msg.sender == _owner);
        _;
    }

    function balanceOf(address _account) public view returns (uint256) {
        require(_account != address(0));
        return balance[_account];
    }

    function getTotalSupply() public view returns (uint256) {
        return _supply;
    }

    function transfer(address _to, uint256 _amount) public onlyHolder() {
       //not transfer to 0 account
        require(_to != address(0));
        // avoid overflow
        require(_amount == uint256(_amount));
        // main account has enough token
        require(balance[msg.sender] >= _amount);
        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
        accountNumber++;
        // record address which owned token
        tokenIndexToAccount[accountNumber] = _to;
        emit TransferTo(msg.sender, _to, _amount);
    }

    function approve(address _to, uint256 _amount) public {
        require(_to != address(0));
        require(_amount == uint256(_amount));
        // balance[msg.sender] does not need lager than allowance
        allowance[msg.sender][_to] = _amount;
        emit ApproveTo(msg.sender, _to, _amount);
    }

    function transerFrom(address _from, address _to, uint256 _amount) public {
        require(_from != address(0));
        require(_to != address(0));
        require(_amount == uint256(_amount));
        require(allowance[_from][msg.sender] >= _amount && balance[_from] >= _amount);
        balance[_from] -= _amount;
        balance[_to] += _amount;
        allowance[_from][msg.sender] -= _amount;
        emit TransferTo(_from, _to, _amount);
    }
}