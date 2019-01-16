pragma solidity ^0.4.25;


library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a && c >= b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a - b;
        require(c <= a && c <= b);
        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == c/a && b == c/b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a != 0 && b != 0);
        uint256 c = a/b;
        require(a == b * c + a % b);
        return c;
    }
}


contract TTTVV {
    // use SafeMath for uint256 mul div add sub
    using SafeMath for uint256;
    address public owner;
    uint256 public totalSupply;
    uint256 public decimals;
    string public symbol;
    string public name;

    mapping (address => uint256) internal balance;
    mapping (address => mapping (address => uint256)) internal allowance;
    mapping (address => uint256) internal amountToFrozenAddress; // record token amount that address been forzen

    // 88888,8,"TTTVV","center for digital finacial assets"
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

    }

    event TransferTo(address indexed _from, address indexed _to, uint256 _amount);
    event ApproveTo(address indexed _from, address indexed _spender, uint256 _amount);
    // event froze and un froze
    event FrozenAddress(address indexed _owner, uint256 _amount);
    event UnFrozenAddress(address indexed _owner, uint256 _amount);
    // owner&#39;s token been burn
    event Burn(address indexed _owner, uint256 indexed _amount);

    modifier onlyHolder() {
        require(msg.sender == owner, "only holder can call this function");
        _;
    }
    
    // require available_balance > total_balance -forzen_balance
    modifier isAvailableEnough(address _owner, uint256 _amount) {
        require(balance[_owner].safeSub(amountToFrozenAddress[_owner]) >= _amount, "no enough available balance");
        _;
    }

    // this contract not acccpt ether transfer
    function () public payable {
        revert("can not recieve ether");
    }
    
    // set new owner
    function setOwner(address _newOwner) public onlyHolder {
        require(_newOwner != address(0x0));
        owner = _newOwner;
    }

    function balanceOf(address _account) public view returns (uint256) {
        require(_account != address(0x0));
        return balance[_account];
    }

    function getTotalSupply()public view returns (uint256) {
        return totalSupply;
    }

    function transfer(address _to, uint256 _amount) public isAvailableEnough(_to, _amount){
       //not transfer to 0 account
        require(_to != address(0x0));
        balance[msg.sender] = balance[msg.sender].safeSub(_amount);
        balance[_to] = balance[_to].safeAdd(_amount);

        emit TransferTo(msg.sender, _to, _amount);
    }

    // approve will reset old allowance and give a new allowance to privileges address,
    //allowance allowed larger than balance[msg.sender]
    function approve(address _spender, uint256 _amount) public {
        require(_spender != address(0x0));
        allowance[msg.sender][_spender] = _amount;
        emit ApproveTo(msg.sender, _spender, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public isAvailableEnough(_to, _amount) {
        require(_from != address(0x0) && _to != address(0x0));
        balance[_from] = balance[_from].safeSub(_amount);
        balance[_to] = balance[_to].safeAdd(_amount);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].safeSub(_amount);
        emit TransferTo(_from, _to, _amount);
    }

    // froze token owned by _woner address
    function froze(address _owner, uint256 _amount) public onlyHolder {
        amountToFrozenAddress[_owner] = _amount;
        emit FrozenAddress(_owner, _amount);
    }

    function unFroze(address _owner, uint256 _amount) public onlyHolder {
        amountToFrozenAddress[_owner] = amountToFrozenAddress[_owner].safeSub(_amount);
        emit UnFrozenAddress(_owner, _amount);
    }

    // burn token owned by _woner address and decrease totalSupply permanently
    function burn(address _owner, uint256 _amount) public onlyHolder {
        require(_owner != address(0x0));
        balance[_owner] = balance[_owner].safeSub(_amount);
        totalSupply = totalSupply.safeSub(_amount);
        emit Burn(_owner, _amount);
    }
}