/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

pragma solidity ^0.7.4;

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


contract Showprise is ERC20 {
    using SafeMath for uint256;
    address public deployer;
    address public pendingDeployer;
    string public name = "Showprise";
    string public symbol = "PRISE";
    uint8 public constant decimals = 18;
    uint256 private constant decimalFactor = 10 ** uint256(decimals);
    uint256 public constant totalSupply = 100000000 * decimalFactor;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    bool public initialMinted = false;
    bool allowTransfer = true;
    
    modifier onlyDeployer() {
        require(deployer == msg.sender, "Caller is not the deployer");
        _;
    }
    
    modifier transferAllowed() {
        require(allowTransfer == true, "Transfer not allowed");
        _;
    }
    

    constructor() {
        deployer = msg.sender;
    }
    
    function intialMint() public onlyDeployer {
        require(initialMinted == false);
        mint(deployer, totalSupply);
        initialMinted = true;
    }
    
    function _setPendingDeployer(address _pendingDeployer) external onlyDeployer {
        pendingDeployer = _pendingDeployer;
    }
    
    function _acceptDeployer() external {
        require(msg.sender == pendingDeployer, "Call must be from pending Deployer ");
        deployer = pendingDeployer;
        pendingDeployer = address(0);
    }
    
    
    function mint(address _owner, uint256 ammount) public onlyDeployer returns (bool) {
        balances[_owner] = balances[_owner].add(ammount);
        emit Transfer(address(0), _owner, ammount);
        return true;
    }
    
    
    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function _burn(address account, uint256 amount) external onlyDeployer {
        require(account != address(0));
        require(amount <= balances[account]);
        balances[account] = balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function transfer(address _to, uint256 _value) external transferAllowed override returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external transferAllowed override returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function pauseTransfers() external onlyDeployer () {
        allowTransfer = false;
    }
    
    function resumeTransfers() external onlyDeployer () {
        allowTransfer = true;
    }

    function approve(address _spender, uint256 _value) external override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(address _spender, uint _addedValue) external returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}