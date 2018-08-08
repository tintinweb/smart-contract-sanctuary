pragma solidity ^0.4.21;

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

contract SafeCoin is ERC20 {
    using SafeMath for uint;
       
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function SafeCoin() public {
        _symbol = "SFC";
        _name = "SafeCoin";
        _decimals = 18;
        _totalSupply = 500000000;
        balances[msg.sender] = _totalSupply;
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
      require(_to != address(0));
      require(_value <= balances[_from]);
      balances[_from] = SafeMath.sub(balances[_from], _value);
      balances[_to] = SafeMath.add(balances[_to], _value);
      emit Transfer(_from, _to, _value);
      return true;
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

contract SafeBox is SafeCoin {
    // ========================================================================================================
    // ========================================================================================================
    // FUNCTIONS RELATING TO THE MANAGEMENT OF THE CONTRACT ===================================================
    mapping (address => user) private users;
    user private user_object;
    address private owner;
    
    struct Prices {
        uint8 create;
        uint8 edit;
        uint8 active_contract;
    }

    Prices public prices;

    function SafeBox() public {
        owner = msg.sender;
        prices.create = 10;
        prices.edit = 10;
        prices.active_contract = 10;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Muda o dono do contrato
    function set_prices(uint8 _create, uint8 _edit, uint8 _active_contract) public onlyOwner returns (bool success){
        prices.create = _create;
        prices.edit = _edit;
        prices.active_contract = _active_contract;
        return true;
    }

    function _my_transfer(address _address, uint8 _price) private returns (bool) {
        SafeCoin._transfer(_address, owner, _price);
        return true;
    }


    // ========================================================================================================
    // ========================================================================================================
    // FUNCOES RELATIVAS AO GERENCIAMENTO DE USUARIOS =========================================================
    function set_status_user(address _address, bool _live_user, bool _active_contract) public onlyOwner returns (bool success) {
        users[_address].live_user = _live_user;
        users[_address].active_contract = _active_contract;
        return true;
    }

    function set_active_contract() public returns (bool success) {
        require(_my_transfer(msg.sender, prices.active_contract));
        users[msg.sender].active_contract = true;
        return true;
    }

    // PUBLIC TEMPORARIAMENTE, DEPOIS PRIVATE
    function get_status_user(address _address) public view returns (
            bool _live_user, bool _active_contract, bool _user_exists){
        _live_user = users[_address].live_user;
        _active_contract = users[_address].active_contract;
        _user_exists = users[_address].exists;
        return (_live_user, _active_contract, _user_exists);
    }

    // Criando objeto usuario
    struct user {
        bool exists;
        address endereco;
        bool live_user;
        bool active_contract;
    }

    function _create_user(address _address) private {
        /*
            Fun&#231;&#227;o privada cria user
        */
        user_object = user(true, _address, true, true);
        users[_address] = user_object;
    }
    
    // ========================================================================================================
    // ========================================================================================================
    // FUN&#199;&#212;ES REFERENTES AOS COFRES ==========================================================================
    struct Safe {
        address safe_owner_address;
        bool exists;
        string safe_name;
        address benefited_address;
        string data;
    }

    Safe safe_object;
    // Endereco titular + safe_name = ObjetoDados 
    mapping (address =>  mapping (string =>  Safe)) private map_data_safe_owner;
    // Endereco benefited_address = ObjetoDados     
    mapping (address =>  mapping (string =>  Safe)) private map_data_safe_benefited;

    function create_safe(address _benef, string _data, string _safe_name) public returns (bool success) {
        require(map_data_safe_owner[msg.sender][_safe_name].exists == false);
        require(_my_transfer(msg.sender, prices.create));
        if(users[msg.sender].exists == false){
            _create_user(msg.sender);
        }
        // Transfere os tokens para o owner
        // Cria um struct Safe
        safe_object = Safe(msg.sender, true, _safe_name, _benef, _data);
        // Salva o cofre no dicionario do titular
        map_data_safe_owner[msg.sender][_safe_name] = safe_object;
        // Salva o cofre no dicionario do beneficiado
        map_data_safe_benefited[_benef][_safe_name] = safe_object;
        return true;
    }

    function edit_safe(address _benef, string _new_data,
                         string _safe_name) public returns (bool success) {
        require(map_data_safe_owner[msg.sender][_safe_name].exists == true);
        require(users[msg.sender].exists == true);
        require(_my_transfer(msg.sender, prices.edit));
        // _token.transferToOwner(msg.sender, owner, prices.edit, senha_owner);
        // Salva o cofre no dicionario do titular
        map_data_safe_owner[msg.sender][_safe_name].data = _new_data;
        // Salva o cofre no dicionario do beneficiado
        map_data_safe_benefited[_benef][_safe_name].data = _new_data;
        return true;
    }

    //  Get infor do cofre beneficiado
    function get_data_benefited(address _benef,
            string _safe_name) public view returns (string) {
        require(map_data_safe_benefited[_benef][_safe_name].exists == true);
        address _safe_owner_address = map_data_safe_benefited[_benef][_safe_name].safe_owner_address;
        require(users[_safe_owner_address].live_user == false);
        require(users[_safe_owner_address].active_contract == true);
        return map_data_safe_benefited[_benef][_safe_name].data;
    }

    //  Get infor do cofre beneficiado
    function get_data_owner(address _address, string _safe_name)
            public view returns (address _benefited_address, string _data) {
        require(map_data_safe_owner[_address][_safe_name].exists == true);
        require(users[_address].active_contract == true);
        _benefited_address = map_data_safe_owner[_address][_safe_name].benefited_address;
        _data = map_data_safe_owner[_address][_safe_name].data;
        return (_benefited_address, _data);
    }

}