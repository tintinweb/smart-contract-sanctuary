pragma solidity 0.4.24;

// ERC20 Token with ERC223 Token compatibility
// SafeMath from OpenZeppelin Standard
// Added burn functions from Ethereum Token 
// - https://theethereum.wiki/w/index.php/ERC20_Token_Standard
// - https://github.com/Dexaran/ERC23-tokens/blob/Recommended/ERC223_Token.sol
// - https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// - https://www.ethereum.org/token (uncontrolled, non-standard)


// ERC223
interface ContractReceiver {
  function tokenFallback( address from, uint value, bytes data ) external;
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


contract CanYaCoin {

    using SafeMath for uint256;

    string public name = "CanYaCoin";
    string public symbol  = "CAN";
    uint256 public decimals  = 18;
    uint256 public totalSupply  = 100000000 * (10 ** decimals);

    uint256 public maxRefundableGasPrice = 10000000000; // 10 GWEI
    uint256 public transferFeePercentTenths = 10;
    address public feeRecipient;
    address public owner;

    // Mapping
    mapping(address => uint256) balances_;
    mapping(address => mapping(address => uint256)) allowances_;
    mapping(address => bool) feeWhitelist_;

    modifier onlyOwner () {
        require(owner == msg.sender);
        _;
    }

    modifier refundable () {
        uint256 _startGas = gasleft();

        _;

        uint256 gasPrice = tx.gasprice;
        if (gasPrice > maxRefundableGasPrice) gasPrice = maxRefundableGasPrice;
        
        uint256 _endGas = gasleft();
        uint256 _gasUsed = _startGas.sub(_endGas);
        uint256 weiRefund = _gasUsed.mul(gasPrice);
        if (address(this).balance >= weiRefund) msg.sender.transfer(weiRefund);
    }
    
    // Minting event
    function CanYaCoin(address _feeRecipient) public {
        require(_feeRecipient != address(0x0));
        feeWhitelist_[address(this)] = true;
        owner = msg.sender;
        feeRecipient = _feeRecipient;
        balances_[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function() public payable onlyOwner { } // does not accept money from anyone but the owner
    
    // ERC20
    event Approval(address indexed owner, address indexed spender, uint value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setOwner (address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0));
        owner = _newOwner;
    }

    function setFeePercentTenths (uint256 _feePercent) public onlyOwner {
        transferFeePercentTenths = _feePercent;
    }

    function setFeeRecipient (address _feeRecipient) public onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function setMaxRefundableGasPrice (uint256 _newMax) public onlyOwner {
        maxRefundableGasPrice = _newMax;
    }

    function exemptFromFees (address _exempt) public onlyOwner {
        feeWhitelist_[_exempt] = true;
    }

    function revokeFeeExemption (address _notExempt) public onlyOwner {
        feeWhitelist_[_notExempt] = false;
    }

    // ERC20
    function balanceOf(address owner) public constant returns (uint) {
        return balances_[owner];
    }

    // ERC20
    function approve(address spender, uint256 value) public returns (bool success) {
        allowances_[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    // recommended fix for known attack on any ERC20
    function safeApprove(address _spender, uint256 _currentValue, uint256 _value) public returns (bool success) {
        // If current allowance for _spender is equal to _currentValue, then
        // overwrite it with _value and return true, otherwise return false.
        if (allowances_[msg.sender][_spender] == _currentValue) {
            return approve(_spender, _value);
        }
        return false;
    }

    // ERC20
    function allowance(address owner, address spender) public constant returns (uint256 remaining) {
        return allowances_[owner][spender];
    }

    // ERC20
    function transfer(address to, uint256 value) public returns (bool success) {
        bytes memory empty; // null
        _transfer(msg.sender, to, value, empty);
        return true;
    }

    // ERC20
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowances_[from][msg.sender]);
        allowances_[from][msg.sender] -= value;
        bytes memory empty;
        _transfer(from, to, value, empty);
        return true;
    }

    // ERC223 Transfer and invoke specified callback
    function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool success)
    {
        _transfer( msg.sender, to, value, data );
        if (isContract(to)) {
            ContractReceiver rx = ContractReceiver( to );
            require(
                address(rx).call.value(0)(
                    bytes4(keccak256(custom_fallback)),
                    msg.sender,
                    value,
                    data
                )
            );
        }
        return true;
    }

    // ERC223 Transfer to a contract or externally-owned account
    function transfer(address to, uint value, bytes data) public returns (bool success) {
        if (isContract(to)) {
            return transferToContract(to, value, data);
        }
        _transfer(msg.sender, to, value, data);
        return true;
    }

    // ERC223 Transfer to contract and invoke tokenFallback() method
    function transferToContract(address to, uint value, bytes data) private returns (bool success) {
        _transfer(msg.sender, to, value, data);

        ContractReceiver rx = ContractReceiver(to);
        rx.tokenFallback(msg.sender, value, data);

        return true;
    }

    // ERC223 fetch contract size (must be nonzero to be a contract)
    function isContract(address _addr) private constant returns (bool) {
        uint length;
        assembly { length := extcodesize(_addr) }
        return (length > 0);
    }

    event Gas(uint256 gasPrice, uint256 gasUsed, uint256 weiRefund);

    function _transfer(address from, address to, uint value, bytes data) internal refundable {
        require(to != 0x0);
        require(balances_[from] >= value);
        require(balances_[to].add(value) > balances_[to]); // catch overflow

        uint256 _feeAmount = _getTransferFeeAmount(from, to, value);
 
        balances_[from] = balances_[from].sub(value);
        balances_[to] = balances_[to].add(value.sub(_feeAmount));

        balances_[address(this)] = balances_[address(this)].add(_feeAmount);

        emit Transfer(from, to, value); // ERC20-compat version
    }

    function _getTransferFeeAmount(address _from, address _to, uint256 _value) internal returns (uint256) {
        if (!feeWhitelist_[_from]) {
            return _value.div(transferFeePercentTenths.mul(10));
        }
        return 0;
    }

    function releaseFees () public {
        bytes memory empty;
        _transfer(address(this), feeRecipient, balances_[address(this)], empty);
    }
    
    // Ethereum Token
    event Burn(address indexed from, uint256 value);
    
    // Ethereum Token
    function burn(uint256 value) public returns (bool success) {
        require(balances_[msg.sender] >= value);
        balances_[msg.sender] -= value;
        totalSupply -= value;

        emit Burn(msg.sender, value);
        return true;
    }

    // Ethereum Token
    function burnFrom(address from, uint256 value) public returns (bool success) {
        require(balances_[from] >= value);
        require(value <= allowances_[from][msg.sender]);

        balances_[from] -= value;
        allowances_[from][msg.sender] -= value;
        totalSupply -= value;

        emit Burn(from, value);
        return true;
    }
}