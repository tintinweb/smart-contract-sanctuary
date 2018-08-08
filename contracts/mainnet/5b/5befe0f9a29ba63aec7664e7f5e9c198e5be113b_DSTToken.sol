pragma solidity ^0.4.18;

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


  // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
    // OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract DSTToken is ERC20, Ownable, SafeMath {

    // Token related informations
    string public constant name = "Decentralize Silver Token";
    string public constant symbol = "DST";
    uint256 public constant decimals = 18; // decimal places

    uint256 public tokensPerEther = 1500;

    // MultiSig Wallet Address
    address public DSTMultisig;

    // Wallet L,M,N and O address
    address dstWalletLMNO;

    bool public startStop = false;

    mapping (address => uint256) public walletA;
    mapping (address => uint256) public walletB; 
    mapping (address => uint256) public walletC;
    mapping (address => uint256) public walletF;
    mapping (address => uint256) public walletG;
    mapping (address => uint256) public walletH;

    mapping (address => uint256) public releasedA;
    mapping (address => uint256) public releasedB; 
    mapping (address => uint256) public releasedC;
    mapping (address => uint256) public releasedF;
    mapping (address => uint256) public releasedG; 
    mapping (address => uint256) public releasedH;

    // Mapping of token balance and allowed address for each address with transfer limit
    mapping (address => uint256) balances;
    //mapping of allowed address for each address with tranfer limit
    mapping (address => mapping (address => uint256)) allowed;

    struct WalletConfig{
        uint256 start;
        uint256 cliff;
        uint256 duration;
    }

    mapping (uint => address) public walletAddresses;
    mapping (uint => WalletConfig) public allWalletConfig;

    // @param _dstWalletLMNO Ether Address for wallet L,M,N and O
    // Only to be called by Owner of this contract
    function setDSTWalletLMNO(address _dstWalletLMNO) onlyOwner external{
        require(_dstWalletLMNO != address(0));
        dstWalletLMNO = _dstWalletLMNO;
    }

    // Owner can Set Multisig wallet
    // @param _dstMultisig address of Multisig wallet.
    function setDSTMultiSig(address _dstMultisig) onlyOwner external{
        require(_dstMultisig != address(0));
        DSTMultisig = _dstMultisig;
    }

    function startStopICO(bool status) onlyOwner external{
        startStop = status;
    }

    function addWalletAddressAndTokens(uint _id, address _walletAddress, uint256 _tokens) onlyOwner external{
        require(_walletAddress != address(0));
        walletAddresses[_id] = _walletAddress;
        balances[_walletAddress] = safeAdd(balances[_walletAddress],_tokens); // wallet tokens initialize        
    }

    // function preAllocation(uint256 _walletId, uint256 _tokens) onlyOwner external{
    //     require(_tokens > 0);
    //     balances[walletAddresses[_walletId]] = safeAdd(balances[walletAddresses[_walletId]],_tokens); // wallet tokens initialize
    // }

    function addWalletConfig(uint256 _id, uint256 _start, uint256 _cliff, uint256 _duration) onlyOwner external{
        uint256 start = safeAdd(_start,now);
        uint256 cliff = safeAdd(start,_cliff);
        allWalletConfig[_id] = WalletConfig(
            start,
            cliff,
            _duration
        );
    }

    function assignToken(address _investor,uint256 _tokens) external {
        // Check investor address and tokens.Not allow 0 value
        require(_investor != address(0) && _tokens > 0);
        // Check wallet have enough token balance to assign
        require(_tokens <= balances[msg.sender]);
        
        // Debit the tokens from the wallet
        balances[msg.sender] = safeSub(balances[msg.sender],_tokens);
        // Increasing the totalSupply
        totalSupply = safeAdd(totalSupply, _tokens);

        // Assign tokens to the investor
        if(msg.sender == walletAddresses[0]){
            walletA[_investor] = safeAdd(walletA[_investor],_tokens);
        }
        else if(msg.sender == walletAddresses[1]){
            walletB[_investor] = safeAdd(walletB[_investor],_tokens);
        }
        else if(msg.sender == walletAddresses[2]){
            walletC[_investor] = safeAdd(walletC[_investor],_tokens);
        }
        else if(msg.sender == walletAddresses[5]){
            walletF[_investor] = safeAdd(walletF[_investor],_tokens);
        }
        else if(msg.sender == walletAddresses[6]){
            walletG[_investor] = safeAdd(walletG[_investor],_tokens);
        }
        else if(msg.sender == walletAddresses[7]){
            walletH[_investor] = safeAdd(walletH[_investor],_tokens);
        }
        else{
            revert();
        }
    }

    function assignTokenIJK(address _userAddress,uint256 _tokens) external {
        require(msg.sender == walletAddresses[8] || msg.sender == walletAddresses[9] || msg.sender == walletAddresses[10]);
        // Check investor address and tokens.Not allow 0 value
        require(_userAddress != address(0) && _tokens > 0);
        // Assign tokens to the investor
        assignTokensWallet(msg.sender,_userAddress, _tokens);
    }

    function withdrawToken() public {
        //require(walletA[msg.sender] > 0 || walletB[msg.sender] > 0 || walletC[msg.sender] > 0);
        uint256 currentBalance = 0;
        if(walletA[msg.sender] > 0){
            uint256 unreleasedA = getReleasableAmount(0,msg.sender);
            walletA[msg.sender] = safeSub(walletA[msg.sender], unreleasedA);
            currentBalance = safeAdd(currentBalance, unreleasedA);
            releasedA[msg.sender] = safeAdd(releasedA[msg.sender], unreleasedA);
        }
        if(walletB[msg.sender] > 0){
            uint256 unreleasedB = getReleasableAmount(1,msg.sender);
            walletB[msg.sender] = safeSub(walletB[msg.sender], unreleasedB);
            currentBalance = safeAdd(currentBalance, unreleasedB);
            releasedB[msg.sender] = safeAdd(releasedB[msg.sender], unreleasedB);
        }
        if(walletC[msg.sender] > 0){
            uint256 unreleasedC = getReleasableAmount(2,msg.sender);
            walletC[msg.sender] = safeSub(walletC[msg.sender], unreleasedC);
            currentBalance = safeAdd(currentBalance, unreleasedC);
            releasedC[msg.sender] = safeAdd(releasedC[msg.sender], unreleasedC);
        }
        require(currentBalance > 0);
        // Assign tokens to the sender
        balances[msg.sender] = safeAdd(balances[msg.sender], currentBalance);
    }

    function withdrawBonusToken() public {
        //require(walletF[msg.sender] > 0 || walletG[msg.sender] > 0 || walletH[msg.sender] > 0);
        uint256 currentBalance = 0;
        if(walletF[msg.sender] > 0){
            uint256 unreleasedF = getReleasableBonusAmount(5,msg.sender);
            walletF[msg.sender] = safeSub(walletF[msg.sender], unreleasedF);
            currentBalance = safeAdd(currentBalance, unreleasedF);
            releasedF[msg.sender] = safeAdd(releasedF[msg.sender], unreleasedF);
        }
        if(walletG[msg.sender] > 0){
            uint256 unreleasedG = getReleasableBonusAmount(6,msg.sender);
            walletG[msg.sender] = safeSub(walletG[msg.sender], unreleasedG);
            currentBalance = safeAdd(currentBalance, unreleasedG);
            releasedG[msg.sender] = safeAdd(releasedG[msg.sender], unreleasedG);
        }
        if(walletH[msg.sender] > 0){
            uint256 unreleasedH = getReleasableBonusAmount(7,msg.sender);
            walletH[msg.sender] = safeSub(walletH[msg.sender], unreleasedH);
            currentBalance = safeAdd(currentBalance, unreleasedH);
            releasedH[msg.sender] = safeAdd(releasedH[msg.sender], unreleasedH);
        }
        require(currentBalance > 0);
        // Assign tokens to the sender
        balances[msg.sender] = safeAdd(balances[msg.sender], currentBalance);
    }

    function getReleasableAmount(uint256 _walletId,address _beneficiary) public view returns (uint256){
        uint256 totalBalance;

        if(_walletId == 0){
            totalBalance = safeAdd(walletA[_beneficiary], releasedA[_beneficiary]);    
            return safeSub(getData(_walletId,totalBalance), releasedA[_beneficiary]);
        }
        else if(_walletId == 1){
            totalBalance = safeAdd(walletB[_beneficiary], releasedB[_beneficiary]);
            return safeSub(getData(_walletId,totalBalance), releasedB[_beneficiary]);
        }
        else if(_walletId == 2){
            totalBalance = safeAdd(walletC[_beneficiary], releasedC[_beneficiary]);
            return safeSub(getData(_walletId,totalBalance), releasedC[_beneficiary]);
        }
        else{
            revert();
        }
    }

    function getReleasableBonusAmount(uint256 _walletId,address _beneficiary) public view returns (uint256){
        uint256 totalBalance;

        if(_walletId == 5){
            totalBalance = safeAdd(walletF[_beneficiary], releasedF[_beneficiary]);    
            return safeSub(getData(_walletId,totalBalance), releasedF[_beneficiary]);
        }
        else if(_walletId == 6){
            totalBalance = safeAdd(walletG[_beneficiary], releasedG[_beneficiary]);
            return safeSub(getData(_walletId,totalBalance), releasedG[_beneficiary]);
        }
        else if(_walletId == 7){
            totalBalance = safeAdd(walletH[_beneficiary], releasedH[_beneficiary]);
            return safeSub(getData(_walletId,totalBalance), releasedH[_beneficiary]);
        }
        else{
            revert();
        }
    }

    function getData(uint256 _walletId,uint256 _totalBalance) public view returns (uint256) {
        uint256 availableBalanceIn = safeDiv(safeMul(_totalBalance, safeSub(allWalletConfig[_walletId].cliff, allWalletConfig[_walletId].start)), allWalletConfig[_walletId].duration);
        return safeMul(availableBalanceIn, safeDiv(getVestedAmount(_walletId,_totalBalance), availableBalanceIn));
    }

    function getVestedAmount(uint256 _walletId,uint256 _totalBalance) public view returns (uint256) {
        uint256 cliff = allWalletConfig[_walletId].cliff;
        uint256 start = allWalletConfig[_walletId].start;
        uint256 duration = allWalletConfig[_walletId].duration;

        if (now < cliff) {
            return 0;
        } else if (now >= safeAdd(start,duration)) {
            return _totalBalance;
        } else {
            return safeDiv(safeMul(_totalBalance,safeSub(now,start)),duration);
        }
    }

    // Sale of the tokens. Investors can call this method to invest into DST Tokens
    function() payable external {
        // Allow only to invest in ICO stage
        require(startStop);
        // Sorry !! We only allow to invest with minimum 1 Ether as value
        require(msg.value >= 1 ether);

        // multiply by exchange rate to get newly created token amount
        uint256 createdTokens = safeMul(msg.value, tokensPerEther);

        // Call to Internal function to assign tokens
        assignTokensWallet(walletAddresses[3],msg.sender, createdTokens);
    }

    // DST accepts Cash Investment through manual process in Fiat Currency
    // DST Team will assign the tokens to investors manually through this function
    //@ param cashInvestor address of investor
    //@ param assignedTokens number of tokens to give to investor
    function cashInvestment(address cashInvestor, uint256 assignedTokens) onlyOwner external {
        // Check if cashInvestor address is set or not
        // By mistake tokens mentioned as 0, save the cost of assigning tokens.
        require(cashInvestor != address(0) && assignedTokens > 0);

        // Call to Internal function to assign tokens
        assignTokensWallet(walletAddresses[4],cashInvestor, assignedTokens);
    }

    // // Function will transfer the tokens to investor&#39;s address
    // // Common function code for Crowdsale Investor And Cash Investor 
    // function assignTokens(address investor, uint256 tokens) internal {
    //     // Creating tokens and  increasing the totalSupply
    //     totalSupply = safeAdd(totalSupply, tokens);

    //     // Assign new tokens to the sender
    //     balances[investor] = safeAdd(balances[investor], tokens);

    //     // Finally token created for sender, log the creation event
    //     Transfer(0, investor, tokens);
    // }

    // Function will transfer the tokens to investor&#39;s address
    // Common function code for Crowdsale Investor And Cash Investor 
    function assignTokensWallet(address walletAddress,address investor, uint256 tokens) internal {
        // Check wallet have enough token balance to assign
        require(tokens <= balances[walletAddress]);
        // Creating tokens and  increasing the totalSupply
        totalSupply = safeAdd(totalSupply, tokens);

        // Debit the tokens from wallet
        balances[walletAddress] = safeSub(balances[walletAddress],tokens);
        // Assign new tokens to the sender
        balances[investor] = safeAdd(balances[investor], tokens);

        // Finally token created for sender, log the creation event
        Transfer(0, investor, tokens);
    }

    function finalizeCrowdSale() external{
        // Check DST Multisig wallet set or not
        require(DSTMultisig != address(0));
        // Send fund to multisig wallet
        require(DSTMultisig.send(address(this).balance));
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

    //  Transfer `value` DST tokens from sender&#39;s account
    // `msg.sender` to provided account address `to`.
    // @param _to The address of the recipient
    // @param _value The number of DST tokens to transfer
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

    //  Transfer `value` DST tokens from sender &#39;from&#39;
    // to provided account address `to`.
    // @param from The address of the sender
    // @param to The address of the recipient
    // @param value The number of miBoodle to transfer
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

    // This method is only use for debit DSTToken from DST wallet L,M,N and O
    // @dev Required state: is dstWalletLMNO set
    // @param _walletAddress The address of the wallet from tokens debit
    // @param token The number of DST tokens to debit
    // @return Whether the debit was successful or not
    function debitWalletLMNO(address _walletAddress,uint256 token) external onlyDSTWalletLMNO returns (bool){
        // Check if DST wallet LMNO is set or not
        require(dstWalletLMNO != address(0));
        // Check wallet have enough token and token is valid
        require(balances[_walletAddress] >= token && token > 0);
        // Increasing the totalSupply
        totalSupply = safeAdd(totalSupply, token);
        // Debit tokens from wallet balance
        balances[_walletAddress] = safeSub(balances[_walletAddress],token);
        return true;
    }

    // This method is only use for credit DSTToken to DST wallet L,M,N and O users
    // @dev Required state: is dstWalletLMNO set
    // @param claimAddress The address of the wallet user to credit tokens
    // @param token The number of DST tokens to credit
    // @return Whether the credit was successful or not
    function creditWalletUserLMNO(address claimAddress,uint256 token) external onlyDSTWalletLMNO returns (bool){
        // Check if DST wallet LMNO is set or not
        require(dstWalletLMNO != address(0));
        // Check claiment address and token is valid or not
        require(claimAddress != address(0) && token > 0);
        // Assign tokens to user
        balances[claimAddress] = safeAdd(balances[claimAddress], token);
        // balances[_walletAddress] = safeSub(balances[_walletAddress],token);
        return true;
    }

    // DSTWalletLMNO related modifer
    // @dev Throws if called by any account other than the DSTWalletLMNO owner
    modifier onlyDSTWalletLMNO() {
        require(msg.sender == dstWalletLMNO);
        _;
    }
}