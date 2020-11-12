// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 < 0.8.0;

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        uint256 c = a / b;
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

contract TokenMine is ERC20 {
    using SafeMath for uint256;
    
    address private deployer;
    string public name = "TEA Token";
    string public symbol = "TEA";
    uint8 public constant decimals = 4;
    uint256 public totalSupply = 100;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => mapping(address=>uint256))  depositRecords;
    mapping (address => bool) public availableTokenMapping; 
    mapping (address => bool) public frozenAccountMapping;
    mapping (address => bool) public minterAccountMapping;
    
    event DepositToken(address indexed _from, address indexed _to, uint256 indexed _value);
    event WithdrawToken(address indexed _from, address _contractAddress, uint256 indexed _value);
    event FrozenAccount(address target, bool frozen);
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    event MintFinished(address minter, uint256 amount);
    event ClaimFinished(address account, uint256 amount);
    event ExchangeFinished(address account, uint256 fromAmount, address contractAddress, uint256 toAmount);

    constructor() {
        balances[msg.sender] = totalSupply;
        minterAccountMapping[msg.sender] = true;
        deployer = msg.sender;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public override view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(frozenAccountMapping[msg.sender] != true, "Address is disabled");
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(frozenAccountMapping[msg.sender] != true, "Address is disabled");
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        require(frozenAccountMapping[msg.sender] != true, "Address is disabled");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        require(frozenAccountMapping[msg.sender] != true, "Address is disabled");
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        require(frozenAccountMapping[msg.sender] != true, "Address is disabled");
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    modifier onlyOwner {
        require(msg.sender == deployer);
        _;
    }
    
    function balanceOfToken(address _account, address _contractAddress) public view returns (uint) {
        return depositRecords[_account][_contractAddress];
    }
    
    function enableToken(address _tokenAddress) public onlyOwner {
        availableTokenMapping[_tokenAddress] = true;
    }
    
    function disableToken(address _tokenAddress) public onlyOwner {
        availableTokenMapping[_tokenAddress] = false;
    }
    
    function transferOwnerShip(address _newOwer) public onlyOwner {
        deployer = _newOwer;
    }

    function addMinter(address account) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        minterAccountMapping[account] = true;
    }

    function removeMinter(address account) public onlyOwner {
        minterAccountMapping[account] = false;
    }

    function mint(uint amount) public {
        require(minterAccountMapping[msg.sender] == true, "Minter is disabled");

        totalSupply = totalSupply.add(amount);
        balances[deployer] = balances[deployer].add(amount);
        emit MintFinished(deployer, amount);
    }

    function claim(address account, uint amount) public {
        require(account != address(0), "ERC20: mint to the zero address");
        require(frozenAccountMapping[account] != true, "Address is disabled");
        require(minterAccountMapping[msg.sender] == true, "Minter is disabled");

        balances[deployer] = balances[deployer].sub(amount);
        balances[account] = balances[account].add(amount);
        emit ClaimFinished(account, amount);
    }

    function exchange(address account, uint fromAmount, address contractAddress, uint toAmount) public {
        require(account != address(0), "ERC20: mint to the zero address");
        require(frozenAccountMapping[account] != true, "Address is disabled");
        require(minterAccountMapping[msg.sender] == true, "Minter is disabled");
        
        (bool success, ) = contractAddress.call(abi.encodeWithSignature("transfer(address,uint256)", account, toAmount));
        if(success) {
            totalSupply = totalSupply.sub(fromAmount / 2);
            balances[deployer] = balances[deployer].add(fromAmount);
            balances[account] = balances[account].sub(fromAmount);
            emit ExchangeFinished(account, fromAmount, contractAddress, toAmount);
        }
    }
    
    function depositToken(address contractAddress, uint256 _value) public returns (bool result) {
        require(availableTokenMapping[contractAddress] == true, "Token NOT allow");
        
        (bool success, ) = contractAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), _value));
        if(success) {
            depositRecords[msg.sender][contractAddress] = depositRecords[msg.sender][contractAddress].add(_value);
            emit DepositToken(msg.sender, address(this), _value);
        }
        return success;
    }
    
    function withdrawToken(address contractAddress, uint256 _value) public returns (bool result) {
        require(depositRecords[msg.sender][contractAddress] >= _value);
        require(frozenAccountMapping[msg.sender] != true, "Address is disabled");
        
        (bool success, ) = contractAddress.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _value));
        if(success) {
            depositRecords[msg.sender][contractAddress] -= _value;
            emit WithdrawToken(msg.sender, contractAddress, _value);
        }
        return success;
    }
    
    function transferToMine(address _to, uint256 _value) public returns (bool result) {
        require(availableTokenMapping[msg.sender] == true);
        require(frozenAccountMapping[_to] != true, "Address is disabled");
        depositRecords[_to][msg.sender] = depositRecords[_to][msg.sender].add(_value);
        return true;
    }
    
    function freezeAccount(address target, bool freeze) public onlyOwner returns (bool result) {
        require(target != deployer);
        frozenAccountMapping[target] = freeze;
        return true;
    }
}