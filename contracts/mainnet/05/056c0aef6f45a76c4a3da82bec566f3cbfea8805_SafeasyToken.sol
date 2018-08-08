pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

// https://github.com/ethereum/EIPs/issues/20
interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function decimals() public view returns(uint digits);

    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract BurnableToken is ERC20 {

    function burn(uint256 _value) public returns (bool success);
    function burnFrom(address _from, uint256 _value) public returns (bool success);

    event Burn(address indexed _from, uint256 _value);
}

contract Ownable {

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Ownable() public {
        owner = msg.sender;
    }

    address newOwner=0x0;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    ///change the owner
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /// accept the ownership
    function acceptOwnership() public{
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    /// `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Controlled is Ownable{

    function Controlled() public {
        exclude[msg.sender] = true;
        exclude[this] = true;
    }

    modifier onlyAdmin() {
        if(msg.sender != owner){
            require(admins[msg.sender]);
        }
        _;
    }

    mapping(address => bool) admins;

    // Flag that determines if the token is transferable or not.
    bool public transferEnabled = false;

    // frozen account
    mapping(address => bool) exclude;
    mapping(address => bool) locked;
    mapping(address => bool) public frozenAccount;


    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);


    function setAdmin(address _addr, bool isAdmin) public onlyOwner
    returns (bool success){
        admins[_addr]=isAdmin;
        return true;
    }


    function enableTransfer(bool _enable) public onlyOwner{
        transferEnabled=_enable;
    }


    function setExclude(address _addr, bool isExclude) public onlyOwner returns (bool success){
        exclude[_addr]=isExclude;
        return true;
    }

    function setLock(address _addr, bool isLock) public onlyAdmin returns (bool success){
        locked[_addr]=isLock;
        return true;
    }


    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    modifier transferAllowed(address _addr) {
        require(!frozenAccount[_addr]);
        if (!exclude[_addr]) {
            require(transferEnabled);
            require(!locked[_addr]);
        }
        _;
    }

}

contract TokenERC20 is  ERC20, BurnableToken, Controlled {

    using SafeMath for uint256;

   // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    string public version = &#39;v1.0&#39;;

    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balanceOf
    mapping (address => uint256)  public balanceOf;
    mapping (address => mapping (address => uint256))  public allowance;


    function totalSupply() public view returns (uint supply){
        return totalSupply;
    }
    function decimals() public view returns(uint digits){
        return decimals;
    }

    function balanceOf(address _owner) public view returns (uint balance){
        return balanceOf[_owner];
    }
    function allowance(address _owner, address _spender) public view returns (uint remaining){
        return allowance[_owner][_spender];
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) transferAllowed(_from) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) transferAllowed(_from) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }

}

contract AdvancedToken is  TokenERC20 {

    uint  constant internal ETH_DECIMALS = 18;
    uint  constant internal PRECISION = (10**18);

    // allocate end time, default is now plus 1 days
    uint256 public allocateEndTime;

    function AdvancedToken() public {
       allocateEndTime = now + 1 days;
    }

    // Allocate tokens to the users
    // @param _owners The owners list of the token
    // @param _values The value list of the token (value = _value * 10 ** decimals)
    function allocateTokens(address[] _owners, uint256[] _values) public onlyOwner {
        require(allocateEndTime > now);
        require(_owners.length == _values.length);
        for(uint256 i = 0; i < _owners.length ; i++){
            address to = _owners[i];
            uint256 value = _values[i] * 10 ** uint256(decimals);
            require(totalSupply + value > totalSupply && balanceOf[to] + value > balanceOf[to]) ;
            totalSupply += value;
            balanceOf[to] += value;
        }
    }


    //Early stage investing
    bool enableEarlyStage = false;
    uint256 public totalEarlyStage;
    uint256 remainEarlyStage;
    uint256 earlyStagePrice;   //PRECISION=10**18
    uint256 earlyStageGiftRate;     //x/10000

    // air drop token
    bool enableAirdrop = false;
    uint256 public totalAirdrop;
    uint256 remainAirdrop;
    mapping (address => bool) dropList;
    uint256 public airdropValue;


    modifier canEarlyStage() {
        require(enableEarlyStage && remainEarlyStage>0 && earlyStagePrice>0 && balanceOf[this]>0);
        _;
    }

    modifier canAirdrop() {
        require(enableAirdrop && remainAirdrop>0);
        _;
    }

    modifier canGetTokens() {
        require(enableAirdrop && remainAirdrop>0 &&  airdropValue>0);
        require(dropList[msg.sender] == false);
        _;
    }

    function setEarlyParams (bool isEarlyStage, uint256 _price, uint256 _earlyStageGiftRate) onlyOwner public {
        if(isEarlyStage){
            require(_price>0);
            require(_earlyStageGiftRate>=0 && _earlyStageGiftRate<= 10000 );
        }
        enableEarlyStage = isEarlyStage;
        if(_price>0){
            earlyStagePrice = _price;
        }
        if(_earlyStageGiftRate>0){
            earlyStageGiftRate = _earlyStageGiftRate;
        }

    }

    function setAirdropParams (bool isAirdrop, uint256 _value) onlyAdmin public {
        if(isAirdrop){
            require(_value>0);
        }
        airdropValue = _value;
    }


    function setAirdorpList(address[] addresses, bool hasDrop) onlyAdmin public {
        for (uint i = 0; i < addresses.length; i++) {
            dropList[addresses[i]] = hasDrop;
        }
    }


    /// @notice Buy tokens from contract by sending ether
     function buy() payable public {
         _buy(msg.value);
     }

    function _buy(uint256 value)  private returns(uint256){
        uint256 amount = 0;
        if(value>0){
            amount = uint256(PRECISION).mul(value).div(earlyStagePrice).div(10**uint256(ETH_DECIMALS-decimals));    // calculates the amount
        }
        if(amount>0){
            _transfer(this, msg.sender, amount);
            if(earlyStageGiftRate>0){
                _transfer(this, msg.sender, amount.mul(earlyStageGiftRate).div(10000));
            }
        }
        return amount;
    }


    function () payable public {
        if(msg.value>0){
            _buy(msg.value);
        }
        if( enableAirdrop && remainAirdrop>0  &&  airdropValue>0 && dropList[msg.sender] == false){
             _getTokens();
        }
    }


    function _airdrop(address _owner, uint256 _value)  canAirdrop private returns(bool) {
        require(_value>0);
        _transfer(this, _owner, _value);
        return true;
    }

     // drop token
    function airdrop(address[] _owners, uint256 _value) onlyAdmin canAirdrop public {
         require(_value>0 && remainAirdrop>= _value * _owners.length);
         for(uint256 i = 0; i < _owners.length ; i++){
             _airdrop(_owners[i], _value);
        }
     }


    function _getTokens()  private returns(bool) {
        address investor = msg.sender;
        uint256 toGive = airdropValue;
        if (toGive > 0) {
            _airdrop(investor, toGive);
            dropList[investor] = true;
        }
        return true;
    }

    /*
    * Proxy transfer  token. When some users of the ethereum account has no ether,
    * he or she can authorize the agent for broadcast transactions, and agents may charge agency fees
    * @param _from
    * @param _to
    * @param _value
    * @param feeProxy
    * @param _v
    * @param _r
    * @param _s
    */
    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeProxy,
        uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){
        require(_value + _feeProxy >= _value);
        require(balanceOf[_from] >=_value  + _feeProxy);
        uint256 nonce = nonces[_from];
        bytes32 h = keccak256(_from,_to,_value,_feeProxy,nonce);
        require(_from == ecrecover(h,_v,_r,_s));
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(balanceOf[msg.sender] + _feeProxy > balanceOf[msg.sender]);
        balanceOf[_from] -= (_value  + _feeProxy);
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        if(_feeProxy>0){
            balanceOf[msg.sender] += _feeProxy;
            Transfer(_from, msg.sender, _feeProxy);
        }
        nonces[_from] = nonce + 1;
        return true;
    }

    // support withdraw
    event TokenWithdraw(ERC20 token, uint amount, address sendTo);

    /**
     * @dev Withdraw all ERC20 compatible tokens
     * @param token ERC20 The address of the token contract
     */
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyOwner {
        require(token.transfer(sendTo, amount));
        TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

    /**
     * @dev Withdraw Ethers
     */
    function withdrawEther(uint amount, address sendTo) external onlyOwner {
        sendTo.transfer(amount);
        EtherWithdraw(amount, sendTo);
    }


    // The nonce for avoid transfer replay attacks
    mapping(address => uint256) nonces;

    /*
     * Get the nonce
     * @param _addr
     */
    function getNonce(address _addr) public constant returns (uint256){
        return nonces[_addr];
    }

}


contract SafeasyToken is AdvancedToken {

   function SafeasyToken() public{
        name = "Safeasy Token";
        decimals = 6;
        symbol = "SET";
        version = &#39;v1.1&#39;;

        uint256 initialSupply = uint256(2* 10 ** 9);
        totalSupply = initialSupply.mul( 10 ** uint256(decimals));

        enableEarlyStage = true;
        totalEarlyStage = totalSupply.div(100).mul(30);
        remainEarlyStage = totalEarlyStage;
        earlyStagePrice = 10 ** 14; // 10**18=1:1eth, 10**15=1000:1eth
        earlyStageGiftRate = 2000;  // 100=1%
        enableAirdrop = true;
        totalAirdrop = totalSupply.div(100).mul(15);
        remainAirdrop = totalAirdrop;
        airdropValue = 50000000;

        uint256 totalDistributed = totalEarlyStage.add(totalAirdrop);
        balanceOf[this] = totalDistributed;
        balanceOf[msg.sender] = totalSupply.sub(totalDistributed);

    }
}