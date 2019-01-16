pragma solidity ^0.4.25;


contract TTT {

    address public owner;
    uint256 public totalSupply;
    uint256 public decimals;
    string public symbol;
    string public name;

    mapping (address => uint256) internal balance;
    mapping (address => uint256) internal availableBalance; // record every address owned token
    mapping (address => mapping (address => uint256)) internal allowance;
    mapping (address => uint256) internal amountToFrozenOfAddress; // record token amount that address been forzen

    // 88888,8,"TT","center for digital finacial assets"
    constructor(
        uint256 _totalSupply,
        uint256 _decimals,
        string _symbol,
        string _name
    ) public {
        owner = msg.sender;
        totalSupply = _totalSupply;
        decimals = _decimals;
        symbol = _symbol;
        name = _name;
        balance[msg.sender] = _totalSupply;
        availableBalance[msg.sender] = _totalSupply;

    }

    event TransferTo(address indexed _from, address indexed _to, uint256 _amount);
    event ApproveTo(address indexed _from, address indexed _spender, uint256 _amount);
    // event froze and un froze
    event FrozenAddress(address indexed _owner, uint256 _amount);
    event UnFrozenAddress(address indexed _owner, uint256 _amount);
    // owner&#39;s token been burn
    event Burn(address indexed _owner, uint256 indexed _amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "only holder can call this function");
        _;
    }

    // require available_balance > total_balance -forzen_balance
    modifier isAvailableEnough(address _owner, uint256 _amount) {
        require( availableBalance[_owner] >= _amount, "available_balance not enough");
        _;
    }

    // this contract not acccpt ether transfer
    function () public payable {
        revert("can not recieve ether");
    }

    // set new owner
    function setOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function balanceOf(address _account) public view returns (uint256) {
        require(_account != address(0));
        return balance[_account];
    }

    function getTotalSupply()public view returns (uint256) {
        return totalSupply;
    }

    function transfer(address _to, uint256 _amount) public isAvailableEnough(msg.sender, _amount) {
        require(_to != address(0), "address can not be 0x0");
        require(availableBalance[msg.sender] >= _amount);
        balance[msg.sender] = balance[msg.sender] - _amount;
        availableBalance[msg.sender] = availableBalance[msg.sender] - _amount; // desc availableBalance of msg.sender
        balance[_to] = balance[_to]+_amount;
        availableBalance[msg.sender] = availableBalance[msg.sender] + _amount;
        emit TransferTo(msg.sender, _to, _amount);
    }

    // approve will reset old allowance and give a new allowance to privileges address,
    //allowance allowed larger than balance[msg.sender]
    function approve(address _spender, uint256 _amount) public {
        require(_spender != address(0));
        require(_amount == uint256(_amount));
        allowance[msg.sender][_spender] = _amount;
        emit ApproveTo(msg.sender, _spender, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public isAvailableEnough(_from, _amount) {
        require(_from != address(0) && _to != address(0));
        //require(_amount == uint256(_amount));
        require(allowance[_from][msg.sender] >= _amount && availableBalance[_from] >= _amount);
        balance[_from] = balance[_from] - _amount;
        balance[_to] = balance[_to] + _amount;
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - _amount;
        availableBalance[_from] = availableBalance[_from] - _amount;
        availableBalance[_to] = availableBalance[_to] + _amount;
        emit TransferTo(_from, _to, _amount);
    }

    // froze token owned by _woner address
    function froze(address _owner, uint256 _amount) public onlyOwner {
        amountToFrozenOfAddress[_owner] = _amount;
        availableBalance[_owner] = availableBalance[_owner] - _amount;
        emit FrozenAddress(_owner, _amount);
    }

    function unFroze(address _owner, uint256 _amount) public onlyOwner {
        amountToFrozenOfAddress[_owner] = amountToFrozenOfAddress[_owner] - _amount;
        availableBalance[_owner] = availableBalance[_owner] + _amount;
        emit UnFrozenAddress(_owner, _amount);
    }

    // burn token owned by _owner address and decrease totalSupply permanently
    function burn(address _owner, uint256 _amount) public onlyOwner {
        require(_owner != address(0));
        balance[_owner] = balance[_owner] - _amount;
        availableBalance[_owner] = availableBalance[_owner] - _amount;
        totalSupply = totalSupply - _amount;
        emit Burn(_owner, _amount);
    }
}