//SourceUnit: contract2.sol

pragma solidity >=0.4.25 <=0.6.12;

library SafeMath {
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

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function transferToMany(address _from,address[] calldata _to, uint _totalValue, uint[] calldata  _value) external returns (bool success);
        
        
    function transferFromToken(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    
    function tokenName() external view returns (string memory);
    function tokenSymbol() external view returns (string memory);
    function tokenDecimals() external view returns (uint8);
    function tokenTotalSupply() external view returns (uint256);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Stake {
}

interface Reserve {
}
contract TRXConnectPro is IERC20 {

    string public constant name = "TRX Connect Pro";
    string public constant symbol = "TCP";
    uint8 public constant decimals = 8;
    uint256 totalSupply_ = 10000000 * 10**uint(decimals);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);



    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    

    using SafeMath for uint256;

    constructor(Stake _StakeToken,Reserve _ReserveTokenCon) public {
        balances[msg.sender] = totalSupply_*30/100;
        balances[address(_StakeToken)] = totalSupply_*50/100;
        balances[address(_ReserveTokenCon)] = totalSupply_*20/100;
    }
    
    

    function totalSupply() public  view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public  view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function tokenName() public  view returns (string memory) {
        return name;
    }
    
    function tokenSymbol() public  view returns (string memory) {
        return symbol;
    }
    
    function tokenDecimals() public  view returns (uint8) {
        return decimals;
    }
    
    function tokenTotalSupply() public  view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address receiver, uint256 numTokens) public  returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transferToMany(address _from, address[] memory  _tos, uint _totalValue,uint[] memory _values) internal  {
        // Prevent transfer to 0x0 address. Use burn() instead
        // Check if the sender has enough
        require(balances[_from] >= _totalValue,'No enough tokens!');
        
        // applying the loop
        for(uint i = 0; i < _tos.length; i++) {
            address _to = _tos[i];
            uint _value = _values[i];
            // Check for overflows
            require(balances[_to] + _value >= balances[_to]);
            // Save this for an assertion in the future
            uint previousBalances = balances[_from] + balances[_to];
            // Subtract from the sender
            balances[_from] -= _value;
            // Add the same to the recipient
            balances[_to] += _value;
            emit Transfer(_from, _to, _value);
            // Asserts are used to use static analysis to find bugs in your code. They should never fail
            assert(balances[_from] + balances[_to] == previousBalances);
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
    
    function transferFromToken(address sender, address receiver,uint256 numTokens) public  returns (bool) {
        require(numTokens <= balances[sender]);
        balances[sender] = balances[sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public  returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public  view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public  returns (bool) {
        require(numTokens <= balances[owner], "owner token balance is low");
        require(numTokens <= allowed[owner][msg.sender],"token amount is not apprroved");

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
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
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply_ -= _value;                      // Updates totalSupply
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
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowed
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender's allowed
        totalSupply_ -= _value;                              // Update totalSupply_
        emit Burn(_from, _value);
        return true;
    }
}


contract StakerContract is Stake{
    string public name;
    
    constructor() public {
        name = 'StakeContract';
    }
}

contract ReserveTokenContract is Reserve{
    string public name;
    
    constructor() public {
        name = 'ReserveTokenContract';
    }
}


contract TRXPRO {

    event Bought(uint256 amount);
    event Sold(uint256 amount);
    event staked(address _staker,uint256 amount);
    event OwnershipTransferred(address indexed _from, address indexed _to);


    IERC20 public token;
    Stake public StakeToken;
    Reserve public ReserveTokenCon;
    
    uint8 public constant trxDecimals = 6;
    
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

    constructor(address _owner,uint256 _key,uint256 _referralKey,uint256 _matchingRoiKey,uint256 _unstakeKey,uint256 _reserveTokenkey,address _RoiOwner) public {
        StakeToken = new StakerContract();
        ReserveTokenCon = new ReserveTokenContract();
        token = new TRXConnectPro(StakeToken,ReserveTokenCon);
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
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some Ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        
        address(uint160(RoiOwner)).transfer(msg.value*RoiOwnerPercent/200);
    }
    
    
    function transferTokenBuy(uint256 _key, uint256 _token,address _reciever) public payable onlyRoiOwner onlyAuthorized(_key){
        uint256 amountTobuy = _token;
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some Ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(_reciever, amountTobuy);
        
        emit Bought(amountTobuy);
    }
    
    /*
    @param amount - token amount which will be swap
    amount will be in 8 decimal place
    */
    function swap(uint256 amount,address _reciever) public payable {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 senderBalance = token.balanceOf(_reciever);
        require(senderBalance >= amount, "Sender token balance is low");
        
        // send the token
        token.transferFromToken(_reciever,address(this), amount);
        
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
        uint256 senderBalance = token.balanceOf(_to);
        require(senderBalance >= amount, "Sender token balance is low");
        
        // send the token from sender to staker
        token.transferFromToken(_to,address(StakeToken), amount);
        
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
        token.transferFromToken(address(StakeToken),_to, returnAmount);
        
        totalStaked[_to] = totalStaked[_to]-amount;
        
        emit staked(_to,amount);
    }
    
    function balanceOf(address tokenOwner) public  view returns (uint256) {
        return token.balanceOf(tokenOwner);
    }
    
    function balanceOfContract() public  view returns (uint256) {
        return address(this).balance;
    }
    
    function tokenName() public  view returns (string memory) {
        return token.tokenName();
    }
    
    function tokenSymbol() public view returns (string memory) {
        return token.tokenSymbol();
    }
    
    function tokenDecimals() public view returns (uint8) {
        return token.tokenDecimals();
    }
    
    function tokenTotalSupply() public view returns (uint256) {
        return token.tokenTotalSupply();
    }
    
    // Send the referral commission
    function transferReferralComm(uint256 _referralKey, address[] memory _to, uint _totalValue, uint[] memory  _value) public onlyRoiOwner onlyreferralAuthorized(_referralKey)returns (bool success) {
        token.transferToMany(address(StakeToken), _to,_totalValue, _value);
        return true;
    }
    
    // Send the matching commission and roi
    function transferMatchingCommAndRoi(uint256 _matchingRoiKey,address[] memory _to, uint _totalValue, uint[] memory  _value) public onlyRoiOwner onlyMatchingRoiAuthorized(_matchingRoiKey) returns (bool success) {
        token.transferToMany(address(StakeToken), _to,_totalValue, _value);
        return true;
    }
    
    
    // Send the reserve token
    function transferReserveToken(uint256 _ReserveTokenkey, address[] memory _to, uint _totalValue, uint[] memory  _value) public onlyRoiOwner onlyreserveTokenkeyAuthorized(_ReserveTokenkey) returns (bool success) {
        token.transferToMany(address(ReserveTokenCon), _to,_totalValue, _value);
        return true;
    }
    
    

}