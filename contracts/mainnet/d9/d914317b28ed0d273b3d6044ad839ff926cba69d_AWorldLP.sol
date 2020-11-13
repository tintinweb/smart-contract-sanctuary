// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at Etherscan.io on 2020-08-20
*/

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

contract AWorldLP is ERC20 {
    using SafeMath for uint256;
    
    address private deployer;
    string public name = "AWorld LP";
    string public symbol = "AWLP";
    uint8 public constant decimals = 4;
    uint256 public constant decimalFactor = 10 ** uint256(decimals);
    uint256 public totalSupply = 2000000 * decimalFactor;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => mapping(address=>uint256))  depositRecords;
    mapping (address => bool) public availableTokenMapping; 
    mapping (address => bool) public frozenAccountMapping;
    
    event DepositToken(address indexed _from, address indexed _to, uint256 indexed _value);
    event WithdrawToken(address indexed _from, address _contractAddress, uint256 indexed _value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        deployer = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public override view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
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
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
    
    function depositToken(address contractAddress, uint256 _value) public returns (bool sucess) {
        require(availableTokenMapping[contractAddress] == true, "Token NOT allow");
        
        (bool success, ) = contractAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), _value));
        if(success) {
            depositRecords[msg.sender][contractAddress] = depositRecords[msg.sender][contractAddress].add(_value);
            totalSupply = totalSupply.add(_value);
            balances[msg.sender] = balances[msg.sender].add(_value);
            emit DepositToken(msg.sender, address(this), _value);
        }
        return success;
    }
    
    function withdrawToken(address contractAddress, uint256 _value) public returns (bool sucess) {
        require(balances[msg.sender] >= _value && depositRecords[msg.sender][contractAddress] >= _value);
        require(frozenAccountMapping[msg.sender] != true, "Address is disabled");
        
        (bool success, ) = contractAddress.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _value));
        if(success) {
            depositRecords[msg.sender][contractAddress] -= _value;
            totalSupply = totalSupply.sub(_value);
            balances[msg.sender] = balances[msg.sender].sub(_value);
            emit WithdrawToken(msg.sender, contractAddress, _value);
        }
        return success;
    }
    
    function transferGovernance(address oldContractAddress, address newContractAddress,uint256 _value) public onlyOwner returns (bool sucess) {
        (bool success, ) = oldContractAddress.call(abi.encodeWithSignature("approve(address,uint256)", newContractAddress, _value));
        return success;
    }
    
    function freezeAccount(address target, bool freeze) public onlyOwner returns (bool sucess) {
        require(target != deployer);
        frozenAccountMapping[target] = freeze;
        return true;
    }
}