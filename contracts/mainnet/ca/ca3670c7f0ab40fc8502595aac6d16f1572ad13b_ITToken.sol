pragma solidity ^0.4.18;

// accepted from zeppelin-solidity https://github.com/OpenZeppelin/zeppelin-solidity
/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address _who) public constant returns (uint);
  function allowance(address _owner, address _spender) public constant returns (uint);

  function transfer(address _to, uint _value) public returns (bool ok);
  function transferFrom(address _from, address _to, uint _value) public returns (bool ok);
  function approve(address _spender, uint _value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ITToken is ERC20, Ownable, SafeMath {

    // Token related informations
    string public constant name = "INFINITY TRAVEL TOKEN";
    string public constant symbol = "ITT";
    uint256 public constant decimals = 18; // decimal places

    // Start withdraw of tokens
    uint256 public startWithdraw;

    // MultiSig Wallet Address
    address public ITTMultisig;

    // Address of wallet from which tokens assigned
    address public ethExchangeWallet;

    uint256 public tokensPerEther = 1000;

    bool public startStop = false;

    mapping (address => uint256) public walletAngelPESales;
    mapping (address => uint256) public walletFoundingInitiatorSales;

    mapping (address => uint256) public releasedAngelPESales;
    mapping (address => uint256) public releasedFoundingInitiatorSales;

    mapping (uint => address) public walletAddresses;

    // Mapping of token balance and allowed address for each address with transfer limit
    mapping (address => uint256) balances;
    //mapping of allowed address for each address with tranfer limit
    mapping (address => mapping (address => uint256)) allowed;

    function ITToken() public {
        totalSupply = 500000000 ether;
        balances[msg.sender] = totalSupply;
    }

    // Only to be called by Owner of this contract
    // @param _id Id of lock wallet address
    // @param _walletAddress Address of lock wallet
    function addWalletAddresses(uint _id, address _walletAddress) onlyOwner external{
        require(_walletAddress != address(0));
        walletAddresses[_id] = _walletAddress;
    }

    // Owner can Set Multisig wallet
    // @param _ittMultisig address of Multisig wallet.
    function setITTMultiSig(address _ittMultisig) onlyOwner external{
        require(_ittMultisig != address(0));
        ITTMultisig = _ittMultisig;
    }

    // Only to be called by Owner of this contract
    // @param _ethExchangeWallet Ether Address of exchange wallet
    function setEthExchangeWallet(address _ethExchangeWallet) onlyOwner external {
        require(_ethExchangeWallet != address(0));
        ethExchangeWallet = _ethExchangeWallet;
    }

    // Only to be called by Owner of this contract
    // @param _tokensPerEther Tokens per ether during ICO stages
    function setTokensPerEther(uint256 _tokensPerEther) onlyOwner external {
        require(_tokensPerEther > 0);
        tokensPerEther = _tokensPerEther;
    }

    function startStopICO(bool status) onlyOwner external {
        startStop = status;
    }

    function startLockingPeriod() onlyOwner external {
        startWithdraw = now;
    }

    // Assign tokens to investor with locking period
    function assignToken(address _investor,uint256 _tokens) external {
        // Tokens assigned by only Angel Sales,PE Sales,Founding Investor and Initiator Team wallets
        require(msg.sender == walletAddresses[0] || msg.sender == walletAddresses[1] || msg.sender == walletAddresses[2] || msg.sender == walletAddresses[3]);

        // Check investor address and tokens.Not allow 0 value
        require(_investor != address(0) && _tokens > 0);
        // Check wallet have enough token balance to assign
        require(_tokens <= balances[msg.sender]);
        
        // Debit the tokens from the wallet
        balances[msg.sender] = safeSub(balances[msg.sender],_tokens);

        // Assign tokens to the investor
        if(msg.sender == walletAddresses[0] || msg.sender == walletAddresses[1]){
            walletAngelPESales[_investor] = safeAdd(walletAngelPESales[_investor],_tokens);
        }
        else if(msg.sender == walletAddresses[2] || msg.sender == walletAddresses[3]){
            walletFoundingInitiatorSales[_investor] = safeAdd(walletFoundingInitiatorSales[_investor],_tokens);
        }
        else{
            revert();
        }
    }

    function withdrawTokens() public {
        require(walletAngelPESales[msg.sender] > 0 || walletFoundingInitiatorSales[msg.sender] > 0);
        uint256 withdrawableAmount = 0;

        if (walletAngelPESales[msg.sender] > 0) {
            uint256 withdrawableAmountANPES = getWithdrawableAmountANPES(msg.sender);
            walletAngelPESales[msg.sender] = safeSub(walletAngelPESales[msg.sender], withdrawableAmountANPES);
            releasedAngelPESales[msg.sender] = safeAdd(releasedAngelPESales[msg.sender],withdrawableAmountANPES);
            withdrawableAmount = safeAdd(withdrawableAmount, withdrawableAmountANPES);
        }
        if (walletFoundingInitiatorSales[msg.sender] > 0) {
            uint256 withdrawableAmountFIIT = getWithdrawableAmountFIIT(msg.sender);
            walletFoundingInitiatorSales[msg.sender] = safeSub(walletFoundingInitiatorSales[msg.sender], withdrawableAmountFIIT);
            releasedFoundingInitiatorSales[msg.sender] = safeAdd(releasedFoundingInitiatorSales[msg.sender], withdrawableAmountFIIT);
            withdrawableAmount = safeAdd(withdrawableAmount, withdrawableAmountFIIT);
        }
        require(withdrawableAmount > 0);
        // Assign tokens to the sender
        balances[msg.sender] = safeAdd(balances[msg.sender], withdrawableAmount);
    }

    // For wallet Angel Sales and PE Sales
    function getWithdrawableAmountANPES(address _investor) public view returns(uint256) {
        require(startWithdraw != 0);
        // interval in months
        uint interval = safeDiv(safeSub(now,startWithdraw),30 days);
        // total allocatedTokens
        uint _allocatedTokens = safeAdd(walletAngelPESales[_investor],releasedAngelPESales[_investor]);
        // Atleast 6 months
        if (interval < 6) { 
            return (0); 
        } else if (interval >= 6 && interval < 12) {
            return safeSub(getPercentageAmount(25,_allocatedTokens), releasedAngelPESales[_investor]);
        } else if (interval >= 12 && interval < 18) {
            return safeSub(getPercentageAmount(50,_allocatedTokens), releasedAngelPESales[_investor]);
        } else if (interval >= 18 && interval < 24) {
            return safeSub(getPercentageAmount(75,_allocatedTokens), releasedAngelPESales[_investor]);
        } else if (interval >= 24) {
            return safeSub(_allocatedTokens, releasedAngelPESales[_investor]);
        }
    }

    // For wallet Founding Investor and Initiator Team
    function getWithdrawableAmountFIIT(address _investor) public view returns(uint256) {
        require(startWithdraw != 0);
        // interval in months
        uint interval = safeDiv(safeSub(now,startWithdraw),30 days);
        // total allocatedTokens
        uint _allocatedTokens = safeAdd(walletFoundingInitiatorSales[_investor],releasedFoundingInitiatorSales[_investor]);
        // Atleast 24 months
        if (interval < 24) { 
            return (0); 
        } else if (interval >= 24) {
            return safeSub(_allocatedTokens, releasedFoundingInitiatorSales[_investor]);
        }
    }

    function getPercentageAmount(uint256 percent,uint256 _tokens) internal pure returns (uint256) {
        return safeDiv(safeMul(_tokens,percent),100);
    }

    // Sale of the tokens. Investors can call this method to invest into ITT Tokens
    function() payable external {
        // Allow only to invest in ICO stage
        require(startStop);

        //Sorry !! We only allow to invest with minimum 0.5 Ether as value
        require(msg.value >= (0.5 ether));

        // multiply by exchange rate to get token amount
        uint256 calculatedTokens = safeMul(msg.value, tokensPerEther);

        // Wait we check tokens available for assign
        require(balances[ethExchangeWallet] >= calculatedTokens);

        // Call to Internal function to assign tokens
        assignTokens(msg.sender, calculatedTokens);
    }

    // Function will transfer the tokens to investor&#39;s address
    // Common function code for assigning tokens
    function assignTokens(address investor, uint256 tokens) internal {
        // Debit tokens from ether exchange wallet
        balances[ethExchangeWallet] = safeSub(balances[ethExchangeWallet], tokens);

        // Assign tokens to the sender
        balances[investor] = safeAdd(balances[investor], tokens);

        // Finally token assigned to sender, log the creation event
        Transfer(ethExchangeWallet, investor, tokens);
    }

    function finalizeCrowdSale() external{
        // Check ITT Multisig wallet set or not
        require(ITTMultisig != address(0));
        // Send fund to multisig wallet
        require(ITTMultisig.send(address(this).balance));
    }

    // @param _who The address of the investor to check balance
    // @return balance tokens of investor address
    function balanceOf(address _who) public constant returns (uint) {
        return balances[_who];
    }

    // @param _owner The address of the account owning tokens
    // @param _spender The address of the account able to transfer the tokens
    // @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint) {
        return allowed[_owner][_spender];
    }

    //  Transfer `value` ITTokens from sender&#39;s account
    // `msg.sender` to provided account address `to`.
    // @param _to The address of the recipient
    // @param _value The number of ITTokens to transfer
    // @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) public returns (bool ok) {
        //validate receiver address and value.Not allow 0 value
        require(_to != 0 && _value > 0);
        uint256 senderBalance = balances[msg.sender];
        //Check sender have enough balance
        require(senderBalance >= _value);
        senderBalance = safeSub(senderBalance, _value);
        balances[msg.sender] = senderBalance;
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    //  Transfer `value` ITTokens from sender &#39;from&#39;
    // to provided account address `to`.
    // @param from The address of the sender
    // @param to The address of the recipient
    // @param value The number of ITTokens to transfer
    // @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) public returns (bool ok) {
        //validate _from,_to address and _value(Now allow with 0)
        require(_from != 0 && _to != 0 && _value > 0);
        //Check amount is approved by the owner for spender to spent and owner have enough balances
        require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value);
        balances[_from] = safeSub(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
        Transfer(_from, _to, _value);
        return true;
    }

    //  `msg.sender` approves `spender` to spend `value` tokens
    // @param spender The address of the account able to transfer the tokens
    // @param value The amount of wei to be approved for transfer
    // @return Whether the approval was successful or not
    function approve(address _spender, uint _value) public returns (bool ok) {
        //validate _spender address
        require(_spender != 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

}