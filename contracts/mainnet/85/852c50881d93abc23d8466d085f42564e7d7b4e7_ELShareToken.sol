pragma solidity ^0.4.23;


contract AccessAdmin {
    bool public isPaused = false;
    address public addrAdmin;  

    event AdminTransferred(address indexed preAdmin, address indexed newAdmin);

    constructor() public {
        addrAdmin = msg.sender;
    }  


    modifier onlyAdmin() {
        require(msg.sender == addrAdmin);
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    modifier whenPaused {
        require(isPaused);
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));
        emit AdminTransferred(addrAdmin, _newAdmin);
        addrAdmin = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}

contract AccessService is AccessAdmin {
    address public addrService;
    address public addrFinance;

    modifier onlyService() {
        require(msg.sender == addrService);
        _;
    }

    modifier onlyFinance() {
        require(msg.sender == addrFinance);
        _;
    }

    function setService(address _newService) external {
        require(msg.sender == addrService || msg.sender == addrAdmin);
        require(_newService != address(0));
        addrService = _newService;
    }

    function setFinance(address _newFinance) external {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        require(_newFinance != address(0));
        addrFinance = _newFinance;
    }
}

contract Random {
    uint256 _seed;

    function _rand() internal returns (uint256) {
        _seed = uint256(keccak256(_seed, blockhash(block.number - 1), block.coinbase, block.difficulty));
        return _seed;
    }

    function _randBySeed(uint256 _outSeed) internal view returns (uint256) {
        return uint256(keccak256(_outSeed, blockhash(block.number - 1), block.coinbase, block.difficulty));
    }
}

/// @dev Ether League Share Token
contract ELShareToken is AccessService, Random {
    uint8 public decimals = 0;
    uint256 public totalSupply = 50;
    uint256 public totalSold = 0;
    string public name = "Ether League Share Token";
    string public symbol = "ELST";

    mapping (address => uint256) balances;
    mapping (address => mapping(address => uint256)) allowed;
    address[] shareholders;
    mapping (address => uint256) addressToIndex;
    uint256 public jackpotBalance;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Jackpot(address indexed _winner, uint256 _value, uint16 _type);

    constructor() public {
        addrAdmin = msg.sender;
        addrService = msg.sender;
        addrFinance = msg.sender;

        balances[this] = 50;
    }

    function() external payable {
        require(msg.value > 0);
        jackpotBalance += msg.value;
    }
    
    function totalSupply() external view returns (uint256){
        return totalSupply;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        uint256 oldToVal = balances[_to];
        uint256 oldFromVal = balances[_from];
        require(_value > 0 && _value <= oldFromVal);
        uint256 newToVal = oldToVal + _value;
        assert(newToVal >= oldToVal);
        uint256 newFromVal = oldFromVal - _value;
        balances[_from] = newFromVal;
        balances[_to] = newToVal;

        if (newFromVal == 0 && _from != address(this)) {
            uint256 index = addressToIndex[_from];
            uint256 lastIndex = shareholders.length - 1;
            if (index != lastIndex) {
                shareholders[index] = shareholders[lastIndex];
                addressToIndex[shareholders[index]] = index;
                delete addressToIndex[_from];
            }
            shareholders.length -= 1; 
        }

        if (oldToVal == 0) {
            addressToIndex[_to] = shareholders.length;
            shareholders.push(_to);
        }

        emit Transfer(_from, _to, _value);
        return true;
    }



    function buy(uint256 _amount) external payable whenNotPaused {
        require(_amount > 0 && _amount <= 10);
        uint256 price = (1 ether) * _amount;
        require(msg.value == price);
        require(balances[this] > _amount);
        _transfer(this, msg.sender, _amount);
        totalSold += _amount;

        jackpotBalance += price * 2 / 10;
        addrFinance.transfer(address(this).balance - jackpotBalance);
        //2%
        uint256 seed = _rand();
        if(seed % 100 == 66 || seed % 100 == 88){
            emit Jackpot(msg.sender, jackpotBalance, 1);
            msg.sender.transfer(jackpotBalance);
        }
    }

    function getShareholders() external view returns(address[50] addrArray, uint256[50] amountArray, uint256 soldAmount) {
        uint256 length = shareholders.length;
        for (uint256 i = 0; i < length; ++i) {
            addrArray[i] = shareholders[i];
            amountArray[i] = balances[shareholders[i]];
        }
        soldAmount = totalSold;
    }

    function withdraw() external {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        addrFinance.transfer(address(this).balance);
    }

}