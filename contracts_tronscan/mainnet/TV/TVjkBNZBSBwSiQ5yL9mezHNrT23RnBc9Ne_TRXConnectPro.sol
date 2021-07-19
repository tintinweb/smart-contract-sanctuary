//SourceUnit: solidity.sol

pragma solidity >=0.5.4 <0.6.0;


contract ReserveTokenContract {
    string public name;
    
    constructor() public {
        name = 'ReserveTokenCon';
    }
}

contract BuyerSwapperContract {
    string public name;
    
    constructor() public {
        name = 'BuyerSwapperCont';
    }
}

contract StakerContract{
    string public name;
    
    constructor() public {
        name = 'StakeCont';
    }
}

contract TRXConnectPro {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    
    event Bought(uint256 amount);
    event Sold(uint256 amount);
    event staked(address _staker,uint256 amount);
    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    
    BuyerSwapperContract public BYSWCon;
    StakerContract public StakeTokenCon;
    ReserveTokenContract public ReserveTokenCon;
    
    
    
    address public owner;
    address public newOwner;
    address public RoiOwner;
    uint256 public token_rate;
    uint256 public swap_fees;
    uint256 public RoiOwnerPercent;
    uint256 public unstakeFee; // fees in percent
    uint256 private key;
    uint256 private referralKey;
    uint256 private matchingRoiKey;
    uint256 private unstakeKey;
    uint256 private reserveTokenkey;
    
     modifier onlyOwner {
        require(msg.sender == owner,'Invalid Owner!');
        _;
    }
    
    modifier onlyRoiOwner {
        require(msg.sender == RoiOwner,'Invalid ROI Owner!');
        _;
    }
    
    modifier onlyAuthorized(uint256 _key) {
        require(key == _key,'Invalid key!');
        _;
    }
    
    modifier onlyreferralAuthorized(uint256 _key) {
        require(referralKey == _key,'Invalid key!');
        _;
    }
    modifier onlyMatchingRoiAuthorized(uint256 _matchingRoiKey) {
        require(matchingRoiKey == _matchingRoiKey,'Invalid key!');
        _;
    }
    modifier onlyUnstakeAuthorized(uint256 _unstakeKey) {
        require(unstakeKey == _unstakeKey,'Invalid key!');
        _;
    }
    
    modifier onlyreserveTokenkeyAuthorized(uint256 _reserveTokenkey) {
        require(reserveTokenkey == _reserveTokenkey,'Invalid key!');
        _;
    }
    
    
    
    
    mapping(address=>uint256) public totalStaked; 


    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    uint256 initialSupply = 10000000; 
    string tokenName = "TRX Connect Pro";
    string tokenSymbol = "TCP";
    constructor(address _owner,uint256 _key,uint256 _referralKey,uint256 _matchingRoiKey,uint256 _unstakeKey,uint256 _reserveTokenkey,address _RoiOwner) public {
        BYSWCon = new BuyerSwapperContract();
        StakeTokenCon = new StakerContract();
        ReserveTokenCon = new ReserveTokenContract();
        
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        // balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        balanceOf[address(BYSWCon)] = totalSupply*30/100;
        balanceOf[address(StakeTokenCon)] = totalSupply*50/100;
        balanceOf[address(ReserveTokenCon)] = totalSupply*20/100;
        
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        
        
        owner = _owner;
        token_rate = 200000000;
        swap_fees = 1;
        unstakeFee = 10;
        key = _key;
        RoiOwner = _RoiOwner;
        RoiOwnerPercent = 1;
        referralKey = _referralKey;
        matchingRoiKey = _matchingRoiKey;
        unstakeKey = _unstakeKey;
        reserveTokenkey = _reserveTokenkey;
    }
    
    
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0000000000000000000000000000000000000000);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
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
     * Internal transfer, only can be called by this contract
     */
    function _transferToMany(address _from, address[] memory  _tos, uint _totalValue,uint[] memory _values) internal  {
        // Prevent transfer to 0x0 address. Use burn() instead
        // Check if the sender has enough
        require(balanceOf[_from] >= _totalValue,'No enough tokens!');
        
        // applying the loop
        for(uint i = 0; i < _tos.length; i++) {
            address _to = _tos[i];
            uint _value = _values[i];
            // Check for overflows
            require(balanceOf[_to] + _value >= balanceOf[_to]);
            // Save this for an assertion in the future
            uint previousBalances = balanceOf[_from] + balanceOf[_to];
            // Subtract from the sender
            balanceOf[_from] -= _value;
            // Add the same to the recipient
            balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
            // Asserts are used to use static analysis to find bugs in your code. They should never fail
            assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        }
    }
    
    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferToMany(address _sender,address[] memory _to, uint _totalValue, uint[] memory  _value) public returns (bool success) {
        _transferToMany(_sender, _to,_totalValue, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
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
        emit Burn(msg.sender, _value);
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
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
    
    
    
     function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function transferRoiOwnership(address _RoiOwner) public onlyRoiOwner {
        RoiOwner = _RoiOwner;
    }
    
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    
    function changeKey(uint256 _key) public onlyOwner {
        key = _key;
    }
    
    function changeReferralKey(uint256 _key) public onlyOwner {
        referralKey = _key;
    }
    
    function changeUnstakekey(uint256 _key) public onlyOwner {
        unstakeKey = _key;
    }
    function changeReserveTokenkeykey(uint256 _key) public onlyOwner {
        reserveTokenkey = _key;
    }
    function changeTokenRate(uint256 _token_rate) public onlyOwner {
        token_rate = _token_rate;
    }
    
    function buy(uint256 _token,address _reciever) public payable{
        uint256 amountTobuy = _token;
        uint256 dexBalance = balanceOf[address(BYSWCon)];
        require(amountTobuy > 0, "You need to send some Ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        
        address(uint160(RoiOwner)).transfer(msg.value*RoiOwnerPercent/200);
    }
    
    function transferTokenBuy(uint256 _key, uint256 _token,address _reciever) public payable onlyRoiOwner onlyAuthorized(_key){
        uint256 amountTobuy = _token;
        uint256 dexBalance = balanceOf[address(BYSWCon)];
        require(amountTobuy > 0, "You need to send some Ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        // transfer(_reciever, amountTobuy);
        
        _transfer(address(BYSWCon), _reciever, amountTobuy);
        
        emit Bought(amountTobuy);
    }
    
    /*
    @param amount - token amount which will be swap
    amount will be in 8 decimal place
    */
    function swap(uint256 amount,address _reciever) public payable {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 senderBalance = balanceOf[address(_reciever)];
        require(senderBalance >= amount, "Sender token balance is low");
        
        // send the token
         _transfer(msg.sender,address(BYSWCon), amount);
    }
    
    function swapTrx(uint256 _key,uint256 _TrxAmount,address _reciever) public payable onlyRoiOwner onlyAuthorized(_key){
        require(_TrxAmount <= address(this).balance, "Contract balance is low");
        
        address(uint160(_reciever)).transfer(_TrxAmount);
        emit Sold(_TrxAmount);
    }
    
    
    function ownertrnasfertTrx(uint256 _TrxAmount) public payable onlyOwner{
        require(_TrxAmount <= address(this).balance, "Contract balance is low");
        
        (msg.sender).transfer(_TrxAmount);
        emit Sold(_TrxAmount);
    }
    
    
    function withdrawTrx(uint256 _TrxAmount,address _reciever) public payable onlyOwner{
        require(_TrxAmount <= address(this).balance, "Contract balance is low");
        address(uint160(_reciever)).transfer(_TrxAmount);
    }
    
    /*
    @param amount - token amount which will be stake
    amount will be in 8 decimal place
    */
    function stake(uint256 amount,address _to) public payable {
        require(amount > 0, "You need to stake at least some tokens");
        uint256 senderBalance = balanceOf[_to];
        require(senderBalance >= amount, "Sender token balance is low");
        
        // send the token from sender to staker
         _transfer(msg.sender,address(StakeTokenCon), amount);
        
        if(totalStaked[_to]>=0){
            totalStaked[_to] = totalStaked[_to]+amount;
        }else{
             totalStaked[_to] = amount;
        }
        emit staked(_to,amount);
    }
    
    /*
    @param amount - token amount which will be stake
    amount will be in 8 decimal place
    */
    function unstake(uint256 _key,uint256 amount,address _to) public payable onlyRoiOwner onlyUnstakeAuthorized(_key) {
        require(amount > 0, "You need to unstake at least some tokens");
        uint256 senderTotalStaked = totalStaked[_to];
        require(senderTotalStaked >= amount, "Sender token balance is low");
        
        uint256 returnAmount = amount- amount*unstakeFee/100;
        // send the token from staker to sender
        _transfer(address(StakeTokenCon),_to, returnAmount);
        
        totalStaked[_to] = totalStaked[_to]-amount;
        
        emit staked(_to,amount);
    }
    
    // Send the referral commission
    function transferReferralComm(uint256 _referralKey, address[] memory _to, uint _totalValue, uint[] memory  _value) public onlyRoiOwner onlyreferralAuthorized(_referralKey)returns (bool success) {
        transferToMany(address(StakeTokenCon), _to,_totalValue, _value);
        return true;
    }
    
    
    // Send the matching commission and roi
    function transferMatchingCommAndRoi(uint256 _matchingRoiKey,address[] memory _to, uint _totalValue, uint[] memory  _value) public onlyRoiOwner onlyMatchingRoiAuthorized(_matchingRoiKey) returns (bool success) {
        transferToMany(address(StakeTokenCon), _to,_totalValue, _value);
        return true;
    }
    
    // / Send the reserve token
    function transferReserveToken(uint256 _ReserveTokenkey, address[] memory _to, uint _totalValue, uint[] memory  _value) public onlyRoiOwner onlyreserveTokenkeyAuthorized(_ReserveTokenkey) returns (bool success) {
        transferToMany(address(ReserveTokenCon), _to,_totalValue, _value);
        return true;
    }
    
    
    
    function balanceOfToken(address tokenOwner) public  view returns (uint256) {
        return balanceOf[tokenOwner];
    }
    
    
    function balanceOfContract() public  view returns (uint256) {
        return address(this).balance;
    }
    
    
    
    
    
    
}