/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

pragma solidity ^0.5.7;

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract IRC20Vanilla {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20Vanilla is IRC20Vanilla {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    constructor(address _manager, uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol
    ) public {
        balances[_manager] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


contract swapper is ReentrancyGuard {
    using SafeMath for uint256;

    ERC20Vanilla public token_v1;
    ERC20Vanilla public token_v2;
    
    address public masterAddress;
    address public supply_address;
    
    bool public locked;

    mapping (address => uint256) public tokens_to_claim;
    
    constructor (ERC20Vanilla _token_v1, ERC20Vanilla _token_v2, address _supply_address) public {
        
        locked = false;
        token_v1 = _token_v1;
        token_v2 = _token_v2;
        supply_address = _supply_address;
        masterAddress = msg.sender;
        
        /*
            tokens_to_claim[0x8Bb5db1cf37B4289c3e4e3443CE9d8344b49FF08] = 88200000000000000;
            tokens_to_claim[0x46A659Ad8aEcB89Df20Cf37A96C307299e9A4d74] = 308700000000000000;
        */
    }

    function bulkLoad(address[] memory adds, uint256[] memory amounts) public onlyMaster {
        for (uint256 index = 0; index < adds.length; index++) {
            tokens_to_claim[adds[index]] = amounts[index];
        }
    }

    function loadForEmergencyOnly(address a, uint256 b) public onlyMaster {
        tokens_to_claim[a] = b;
    }

    function modify_token_v1(ERC20Vanilla _newVal) external onlyMaster {
        token_v1 = _newVal;
    }
    function modify_token_v2(ERC20Vanilla _newVal) external onlyMaster {
        token_v2 = _newVal;
    }

    function change_master(address _newVal) external onlyMaster {
        masterAddress = _newVal;
    }
    
    function change_supply_address(address _newVal) external onlyMaster {
        supply_address = _newVal;
    }
    
    // dudas
    // 1) cual admin puede cargar la lista blanca == el admin que creo el contrato
    
    // 2) Approve completo del balance del token CATE 1 o Approve solo del monto que puede cambiar
    // 3) El usuario aprueba todo su balance del token 1 al contrato (por defecto la interfaz debe poner todo el balance que tiene el usuario conectado)
    // debe tener almenos cuantos tokens viejos para poder  hacer swap?
    
    function check_amount_to_change_available(address _account) public view returns(uint256){
        uint256 amount;
        if(token_v1.balanceOf(_account) < tokens_to_claim[_account]){
            amount = token_v1.balanceOf(_account);
        }else{
            amount = tokens_to_claim[_account];
        }
        
        // if(token_v1.balanceOf(_account) < 1){
        //     amount = 0;
        // }
        return amount;
    }
    
    function swap() public nonReentrant whenOpen {
        uint256 amount_to_change = check_amount_to_change_available(msg.sender);
        // require(amount_to_change >= 1, "you don't have enough funds for swap");
        
        require(token_v2.allowance(supply_address, address(this)) >= amount_to_change, "Not enough allowance");
        // token_v1.approve(address(this), amount_to_change);
        tokens_to_claim[msg.sender] = tokens_to_claim[msg.sender].sub(amount_to_change);
        token_v1.transferFrom(msg.sender, address(this), amount_to_change);
        token_v2.transferFrom(supply_address, msg.sender, amount_to_change.mul(10));
    }
    
    function lock() public onlyMaster {
        locked = true;
    }
    
    function unlock() public onlyMaster {
        locked = false;
    }
    
    modifier onlyMaster() {
        require(msg.sender == masterAddress);
        _;
    }

    modifier whenOpen() {
        require(locked == false, "swapper locked");
        _;
    }

}