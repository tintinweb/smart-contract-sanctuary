pragma solidity ^0.4.24;

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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

interface ERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SafeBoxCoin is ERC20 {
    using SafeMath for uint;
       
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function SafeBoxCoin() public {
        _symbol = "SBC";
        _name = "SafeBoxCoin";
        _decimals = 18;
        _totalSupply = 252000000;
        balances[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
      require(_to != address(0));
      require(_value <= balances[msg.sender]);
      balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
      balances[_to] = SafeMath.add(balances[_to], _value);
      emit Transfer(msg.sender, _to, _value);
      return true;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract SafeBox is SafeBoxCoin {
    
    mapping (address => user) private users;
    user private user_object;
    address private owner;
    address private account_1;
    address private account_2;
    uint256 private divided_value;
    Safe safe_object;
    mapping (address =>  mapping (string => Safe)) private map_data_safe_benefited;
    Prices public prices;
    
    struct Prices {
        uint256 create;
        uint256 edit;
        uint256 active_contract;
    }


    function SafeBox() public {
        owner = msg.sender;
        account_1 = 0x8Fc18dc65E432CaA9583F7024CC7B40ed99fd8e4;
        account_2 = 0x51cbdb8CE8dE444D0cBC0a2a64066A852e14ff51;
        prices.create = 1000;
        prices.edit = 1000;
        prices.active_contract = 7500;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function set_prices(uint256 _create, uint256 _edit, uint256 _active_contract) public onlyOwner returns (bool success){
        prices.create = _create;
        prices.edit = _edit;
        prices.active_contract = _active_contract;
        return true;
    }


    function _transfer(uint256 _value) private returns (bool) {
      require(owner != address(0));
      require(_value <= SafeBoxCoin.balances[msg.sender]);
      SafeBoxCoin.balances[msg.sender] = SafeMath.sub(SafeBoxCoin.balances[msg.sender], _value);
      divided_value = _value / 2;
      SafeBoxCoin.balances[owner] = SafeMath.add(SafeBoxCoin.balances[owner], divided_value);
      SafeBoxCoin.balances[account_1] = SafeMath.add(SafeBoxCoin.balances[account_1], divided_value / 2);
      SafeBoxCoin.balances[account_2] = SafeMath.add(SafeBoxCoin.balances[account_2], divided_value / 2);
      emit Transfer(msg.sender, owner, _value);
      return true;
    }

    function set_status_user(address _address, bool _active_contract) public onlyOwner returns (bool success) {
        users[_address].active_contract = _active_contract;
        return true;
    }

    function set_active_contract() public returns (bool success) {
        require(_transfer(prices.active_contract));
        users[msg.sender].active_contract = true;
        return true;
    }

    function get_status_user(address _address) public view returns (
            bool _user_exists, bool _active_contract){
        _active_contract = users[_address].active_contract;
        _user_exists = users[_address].exists;
        return (_active_contract, _user_exists);
    }

    struct user {
        bool exists;
        address endereco;
        bool active_contract;
    }

    function _create_user(address _address) private {
        user_object = user(true, _address, true);
        users[_address] = user_object;
    }
    
    struct Safe {
        address safe_owner_address;
        bool exists;
        string safe_name;
        address benefited_address;
        string data;
    }


    function create_safe(address _benef, string _data, string _safe_name) public returns (bool success) {
        require(map_data_safe_benefited[_benef][_safe_name].exists == false);
        require(_transfer(prices.create));
        if(users[msg.sender].exists == false){
            _create_user(msg.sender);
        }
        safe_object = Safe(msg.sender, true, _safe_name, _benef, _data);
        map_data_safe_benefited[_benef][_safe_name] = safe_object;
        return true;
    }

    function edit_safe(address _benef, string _new_data,
            string _safe_name) public returns (bool success) {
        require(map_data_safe_benefited[_benef][_safe_name].exists == true);
        require(users[msg.sender].exists == true);
        require(_transfer(prices.edit));
        map_data_safe_benefited[_benef][_safe_name].data = _new_data;
        return true;
    }

    function get_data_benefited(address _benef,
            string _safe_name) public view returns (string) {
        require(map_data_safe_benefited[_benef][_safe_name].exists == true);
        address _safe_owner_address = map_data_safe_benefited[_benef][_safe_name].safe_owner_address;
        require(users[_safe_owner_address].active_contract == true);
        return map_data_safe_benefited[_benef][_safe_name].data;
    }
}