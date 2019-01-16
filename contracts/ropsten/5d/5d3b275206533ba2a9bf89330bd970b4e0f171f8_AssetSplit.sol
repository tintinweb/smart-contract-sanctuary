pragma solidity 0.4.25;

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

// Owned Contract
contract Owned {
    
  modifier onlyOwner { require(msg.sender == owner); _; }
  
  event NewOwner(address indexed old, address indexed current);
  
  function setOwner(address _new) onlyOwner public { NewOwner(owner, _new); owner = _new; }

  address public owner = msg.sender;
}

// CanYaCoin Contract
contract CanYaCoin is Owned {

    using SafeMath for uint256;

    // Coin Defaults
    string public name;                                         // Name of Coin
    string public symbol;                                       // Symbol of Coin
    string public URI;                                          // Optional URI
    uint256 public decimals  = 18;                              // Decimals
    uint256 public totalSupply  = 100000000 * (10 ** decimals); // 100m CAN

    // Contract Defaults
    bool public publicCanWhitelist = true;                      // Allow public to whitelist
    uint256 public maxRefundableGasPrice = 10000000000;         // 10 GWEI
    uint256 public transferFeePercentTenths = 10;               // 1%
    uint256 public transferFeeFlat = 0;                         // default 0
    address public feeRecipient;                                // Asset Contract
    address public owner;

    // Mapping
    mapping(address => uint256) balances_;                      // Map balances
    mapping(address => mapping(address => uint256)) allowances_;// Map allowances
    mapping(address => bool) feeWhitelist_;                     // Map whitelist permission
    
    // Events
    event Approval(address indexed owner, address indexed spender, uint value); // ERC20
    event Transfer(address indexed from, address indexed to, uint256 value);    // ERC20
    event Gas(uint256 gasPrice, uint256 gasUsed, uint256 weiRefund);            // CAN223 Gas Refund
    event Burn(address indexed from, uint256 value);                            // Burn
    
    // Minting event
    constructor() public{
        feeWhitelist_[address(this)] = true;
        owner = msg.sender;
        balances_[msg.sender] = totalSupply;
        name = "testCanYaCoin";
        symbol  = "CAN223";
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // Accepts Ether from anyone since this contract refunds gas
    function() public payable { } 

    // Calculates the CanYa Network Fee
    // Tracks gas spent, below a mas gas price threshold (prevents attacks)
    // Checks if in the whitelist (does not apply the fee)
    // Adds a base gas amount to account for the processes outside of the tracking
    // Exits gracefully if no ether in this contract
    modifier refundable () {
        uint256 _startGas = gasleft();
        _;
        if (feeWhitelist_[msg.sender]) return;
        uint256 gasPrice = tx.gasprice;
        if (gasPrice > maxRefundableGasPrice) gasPrice = maxRefundableGasPrice;
        uint256 _endGas = gasleft();
        uint256 _gasUsed = _startGas.sub(_endGas).add(30000);
        uint256 weiRefund = _gasUsed.mul(gasPrice);
        if (address(this).balance >= weiRefund) msg.sender.transfer(weiRefund);
    }
    
    //Update details about the token if necessary
    function updateDetails (string _updatedName,
    string _updatedSymbol) public onlyOwner {
    name = _updatedName;
    symbol  = _updatedSymbol;
    }

    // Get the URI - optional method
    function getURI() public view returns (string) {
    return URI;
    }
    
    //Update token URI
    function updateURI (string _updatedURI) public onlyOwner {
    URI = _updatedURI;
    }

    //Fee is in %, where 10 = 10%
    function setFeePercentTenths (uint256 _feePercent) public onlyOwner {
        transferFeePercentTenths = _feePercent;
    }

    //Fee is flat
    function setFeeFlat (uint256 _feeFlat) public onlyOwner {
        transferFeeFlat = _feeFlat;
    }

    // Set the recipient of fees - should be Asset Contract
    function setFeeRecipient (address _feeRecipient) public onlyOwner {
        feeRecipient = _feeRecipient;
    }

    // Change the anti-sybil attack threshold
    function setMaxRefundableGasPrice (uint256 _newMax) public onlyOwner {
        maxRefundableGasPrice = _newMax;
    }

    // Allows owner to exempt others
    function exemptFromFees (address _exempt) public onlyOwner {
        feeWhitelist_[_exempt] = true;
    }

    // Allows owner to revoke others in case of abuse
    function revokeFeeExemption (address _notExempt) public onlyOwner {
        feeWhitelist_[_notExempt] = false;
    }

    // Allows owner to disable/enable public whitelisting
    function setPublicWhitelistAbility (bool _canWhitelist) public onlyOwner {
        publicCanWhitelist = _canWhitelist;
    }

    // Allows public to opt-out of CanYa Network Fee
    function exemptMeFromFees () public {
        if (publicCanWhitelist) {
            feeWhitelist_[msg.sender] = true;
        }
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
    
    // CAN223 approve everything in address
    function approveMe(address spender) public returns (bool success) {
        uint256 value = balances_[msg.sender];
        allowances_[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    // CAN223 approve all for smart contracts to "unlock""
    function approveAll(address spender) public returns (bool success) {
        uint256 value = balances_[msg.sender];
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

    // Transfer function which includes the gas refund and CanYa network fee
    function _transfer(address from, address to, uint value, bytes data) internal refundable {
        require(to != 0x0);
        require(balances_[from] >= value);
        require(balances_[to].add(value) > balances_[to]);                  // catch overflow

        uint256 _feeAmount = _getTransferFeeAmount(from, value);        // Get fee amount
 
        balances_[from] = balances_[from].sub(value);                       // Subtract from sender         
        balances_[to] = balances_[to].add(value.sub(_feeAmount));           // Add to receiver

        balances_[feeRecipient] = balances_[feeRecipient].add(_feeAmount);  // Add to Fee Recipient

        emit Transfer(from, to, value.sub(_feeAmount));                     // Transaction event
        emit Transfer(from, feeRecipient, _feeAmount);                      // Fee transfer event
    }

    // Calculate fee amount 
    function _getTransferFeeAmount(address _from, uint256 _value) internal returns (uint256) {
        if (!feeWhitelist_[_from]) {
            return _value.div(transferFeePercentTenths.mul(10)) + transferFeeFlat;
        }
        return 0;
    }

    // May not be necessary
    function releaseFees () public {
        bytes memory empty;
        _transfer(address(this), feeRecipient, balances_[address(this)], empty);
    }
    
    // Burn
    function burn(uint256 value) public returns (bool success) {
        require(balances_[msg.sender] >= value);
        balances_[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, value);
        return true;
    }

    // BurnFrom
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

contract AssetSplit is Owned {
    
  using SafeMath for uint256;
  
  CanYaCoin public CanYaCoinToken;

  // Public Addresses
  address public operationalAddress;
  address public daoAddress;
  address public charityAddress;

  // Splits
  uint256 public operationalSplitPercent = 30;
  uint256 public daoSplitPercent = 30;
  uint256 public charitySplitPercent = 10;
  uint256 public burnSplitPercent = 30;

  // Events
  event OperationalSplit(uint256 _split);
  event DaoSplit(uint256 _split);
  event CharitySplit(uint256 _split);
  event BurnSplit(uint256 _split);


  /// @dev Deploys the asset splitting contract
  /// @param _tokenAddress Address of the CAN token contract
  /// @param _operational Address of the operational holdings
  /// @param _dao Address of the reward holdings
  /// @param _charity Address of the charity holdings
  constructor (
    address _tokenAddress,
    address _dao,
    address _operational,
    address _charity) public {
        
    require(_tokenAddress != 0);
    require(_dao != 0);
    require(_operational != 0);
    require(_charity != 0);
    
    CanYaCoinToken = CanYaCoin(_tokenAddress);

    daoAddress = _dao;
    operationalAddress = _operational;
    charityAddress = _charity;
  }

  // Accepts ether from anyone
  function() public payable { } 

  /// @dev Splits the tokens from the owner address to the defined locations
  function split () public {
      
    // Collect current balance
    uint256 assetContractBal = CanYaCoinToken.balanceOf(this);
    
    // Get the amounts of tokens for each recipient 
    uint256 onePercentOfSplit = assetContractBal / 100;
    uint256 operationalSplitAmount = onePercentOfSplit.mul(operationalSplitPercent);
    uint256 daoSplitAmount = onePercentOfSplit.mul(daoSplitPercent);
    uint256 charitySplitAmount = onePercentOfSplit.mul(charitySplitPercent);
    uint256 burnSplitAmount = onePercentOfSplit.mul(burnSplitPercent);

    // Check that it won&#39;t send too many tokens
    require(
      operationalSplitAmount
        .add(daoSplitAmount)
        .add(charitySplitAmount)
        .add(burnSplitAmount)
      <= assetContractBal
    );

    // Requre and make the transfers
    require(CanYaCoinToken.transfer(operationalAddress, operationalSplitAmount));
    require(CanYaCoinToken.transfer(daoAddress, daoSplitAmount));
    require(CanYaCoinToken.transfer(charityAddress, charitySplitAmount));
    require(CanYaCoinToken.burn(burnSplitAmount));

    // Emit the events
    emit OperationalSplit(operationalSplitAmount);
    emit DaoSplit(daoSplitAmount);
    emit CharitySplit(charitySplitAmount);
    emit BurnSplit(burnSplitAmount);
  }

  // Update Addresses
  function updateDaoAddress (address _new) public onlyOwner {
    daoAddress = _new;
  }
  
  function updateOperationalAddress (address _new) public onlyOwner {
    operationalAddress = _new;
  }

  function updateCharityAddress (address _new) public onlyOwner {
    charityAddress = _new;
  }

  //Set split in percentages. 0 = 0%, 30=30%
  // Must sum to 100
  function updateSplits (uint256 _dao, uint256 _ope, uint256 _cha, uint256 _bur) onlyOwner {
    require(_dao + _ope + _cha + _bur == 100);
    daoSplitPercent = _dao;
    operationalSplitPercent = _ope;
    charitySplitPercent = _cha;
    burnSplitPercent = _bur;
  }

}