/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

pragma solidity ^0.8.1;


contract HoverX {
      modifier onlyHoverXAdmin(){
        address hoverXholder = msg.sender;
        require(administrators[hoverXholder]);
        _;
    }
    modifier onlyHoverXHolder() {
        require(myTokens() > 0);
        _;
    }
    modifier onlyPrelaunchContract(){
        require(msg.sender==address(preLaunchSwapAddress));
        _;
    }
    modifier onlyActive(){
        require(!blocked[msg.sender],"Blocked!");
        _;
    }

    /*==============================
    =            EVENTS            =
    ==============================*/
    event Approval(
        address indexed tokenOwner, 
        address indexed spender,
        uint tokens
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    event Withdraw(
        address indexed customerAddress,
        uint256 BnbWithdrawn
    );
    event RewardWithdraw(
        address indexed customerAddress,
        uint256 indexed incomeType,
        uint256 tokens
    );
    event Buy(
        address indexed buyer,
        uint256 tokensBought
    );
    event Sell(
        address indexed seller,
        uint256 tokensSold
    );
    event Stake(
        address indexed staker,
        uint256 tokenStaked
    );
    event Unstake(
        address indexed staker,
        uint256 tokenRestored
    );
    event Join(
    address indexed _address,
    uint256 indexed _package_amount,
    address indexed _referrer,
    uint256  _package_value,
    uint256 price
    );
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public  _name = "HoverX Token";
    string public _symbol = "HVRX";
    uint8 public _decimals = 9;
    uint256 public _totalSupply = 25000000000000000;
    uint256 public  currentPrice_ = 1000000;
    uint256 internal rewardPercent = 10000; //comes multiplied by 1000 from outside
    uint256 public tokenSupply_ = 0;

    // Please verify the website https://HoverX.com before purchasing tokens
    address public preLaunchSwapAddress;
    address payable devAddress; // Growth funds
    mapping(address => uint256) internal hvrxAccountLedger_;
    mapping(address => uint256) internal hvrxStakingLedger_;
    mapping(address => mapping (address => uint256)) public allowance;
    mapping(address=>uint256) public addressNonce;
    mapping(address=>uint256) internal stakingMonths;
    address payable hadmin;
    address defaultReferrer;
    address stakeHolder;
    address commissionHolder;
    uint256 commFunds;
    uint256 public startTimestamp;
    string private secret;
    mapping(address => bool) internal administrators;
    mapping(address =>string) internal snaHash;
    mapping (address => string) internal addressToString; // make it internal
    mapping (address => uint256) public hvrxPackage;
    mapping (address=>bool) public blocked;

    constructor()
    {
        hadmin = payable(msg.sender);
        administrators[hadmin] = true; 
        commissionHolder = hadmin;
        commFunds = 0;
        startTimestamp  = block.timestamp;
    }
    
    /**********************************************************************/
    /**************************UPGRADABLES*********************************/
    /**********************************************************************/
    function name() public view virtual  returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual  returns ( uint256) {
        return _decimals;
    }
    function updateSwapAddress(address _address) onlyHoverXAdmin public {
        preLaunchSwapAddress = _address;
    }
    
    function updateAddressNonce(address _address, uint256 nonce ) onlyHoverXAdmin public {
        addressNonce[_address] = nonce;
    }
    
    function upgradeContract(address[] memory _users, uint256[] memory _balances)
    onlyHoverXAdmin()
    public
    { 
        for(uint i = 0; i<_users.length;i++)
        {
            hvrxAccountLedger_[_users[i]] += _balances[i];
            tokenSupply_ += _balances[i];
            emit Transfer(address(this),_users[i], _balances[i]);
        }
    }
    
    function updateSecret(string memory _secret) onlyHoverXAdmin public {
        secret = _secret;
    }
    
    function getSecret() onlyHoverXAdmin() public view returns (string memory) {
       return secret;
    }
    
   function getNonce(address _address) public view returns (uint256) {
       return addressNonce[_address];
   }
   
    function upgradeDetails(uint256 _currentPrice, uint256 _commFunds)
    onlyHoverXAdmin()
    public
    {
        currentPrice_ = _currentPrice;
        commFunds = _commFunds;
    }
    
    function setupHolders(address _commissionHolder, uint mode_, address _defaultReferrer)
    onlyHoverXAdmin()
    public
    {
        if(mode_ == 1)
        {
            commissionHolder = _commissionHolder;
        }
        if(mode_ == 2)
        {
            stakeHolder = _commissionHolder;
        }
        defaultReferrer = _defaultReferrer;
    }
    
    function withdrawStake(uint256[] memory _amount, address[] memory hoverXholder)
        onlyHoverXAdmin()
        public 
    {
        for(uint i = 0; i<hoverXholder.length; i++)
        {
            uint256 _toAdd = _amount[i];
            hvrxAccountLedger_[hoverXholder[i]] = _SafeMath.add(hvrxAccountLedger_[hoverXholder[i]],_toAdd);
            hvrxAccountLedger_[stakeHolder] = _SafeMath.sub(hvrxAccountLedger_[stakeHolder], _toAdd);
            emit Unstake(hoverXholder[i], _toAdd);
            emit Transfer(address(this),hoverXholder[i],_toAdd);
        }
    }
    
    function blockUnblockAddress(address _address, bool _blocked)onlyHoverXAdmin public{
        blocked[_address] = _blocked;
    }
    
    /**********************************************************************/
    /*************************BUY/SELL/STAKE*******************************/
    /**********************************************************************/
    

    function holdStake(uint256 _amount, uint256 months) 
    onlyHoverXHolder()
    public
    {
        require(!isContract(msg.sender),"Stake from contract is not allowed");
        hvrxAccountLedger_[msg.sender] = _SafeMath.sub(hvrxAccountLedger_[msg.sender], _amount);
        hvrxAccountLedger_[stakeHolder] = _SafeMath.add(hvrxAccountLedger_[stakeHolder], _amount);
        hvrxStakingLedger_[msg.sender] = _amount;
        if(months>0){
            stakingMonths[msg.sender]=months;
        }
        emit Stake(msg.sender, _amount);
    }
        
    function unstake(uint256 _amount, address hoverXholder)
    onlyHoverXAdmin()
    public
    {
        hvrxAccountLedger_[stakeHolder] = _SafeMath.sub(hvrxAccountLedger_[stakeHolder], _amount);
        hvrxAccountLedger_[hoverXholder] = _SafeMath.add(hvrxAccountLedger_[hoverXholder],_amount);
        hvrxStakingLedger_[hoverXholder] = _SafeMath.sub(hvrxStakingLedger_[hoverXholder], _amount);
        emit Unstake(hoverXholder, _amount);
    }
    
    function withdrawRewards(uint256 _amount, address hoverXholder)
        onlyHoverXAdmin()
        public 
    {
        hvrxAccountLedger_[hoverXholder] = _SafeMath.add(hvrxAccountLedger_[hoverXholder],_amount);
        tokenSupply_ = _SafeMath.add (tokenSupply_,_amount);
    }
    
    function getStake(address hvrxHolder) public view returns (uint256){
        return hvrxStakingLedger_[hvrxHolder];
    }
    
    function withdrawComm(uint256[] memory _amount, address[] memory hoverXholder)
        onlyHoverXAdmin()
        public 
    {
        for(uint i = 0; i<hoverXholder.length; i++)
        {
            uint256 _toAdd = _amount[i];
            hvrxAccountLedger_[hoverXholder[i]] = _SafeMath.add(hvrxAccountLedger_[hoverXholder[i]],_toAdd);
            hvrxAccountLedger_[commissionHolder] = _SafeMath.sub(hvrxAccountLedger_[commissionHolder], _toAdd);
            emit RewardWithdraw(hoverXholder[i], 99, _toAdd);
            emit Transfer(address(this),hoverXholder[i],_toAdd);
        }
    }
    
    function withdrawBnbs(uint256 _amount)
    public
    onlyHoverXAdmin()
    {
        require(!isContract(msg.sender),"Withdraw from contract is not allowed");
        devAddress.transfer(_amount);
        commFunds = _SafeMath.sub(commFunds,_amount);
    }
    
    /**
     * Liquifies tokens to Bnb.
     */
     
    function setAdministrator(address _address) public onlyHoverXAdmin(){
        administrators[_address] = true;
    }
    
    function registerDev(address payable _devAddress)
    onlyHoverXAdmin()
    public
    {
        devAddress = _devAddress;
    }
    
    function approve(address delegate, uint numTokens) public returns (bool) {
      allowance[msg.sender][delegate] = numTokens;
      emit Approval(msg.sender, delegate, numTokens);
      return true;
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
      require(numTokens <= hvrxAccountLedger_[owner]);
      require(numTokens <= allowance[owner][msg.sender]);
      hvrxAccountLedger_[owner] = _SafeMath.sub(hvrxAccountLedger_[owner],numTokens);
      allowance[owner][msg.sender] =_SafeMath.sub(allowance[owner][msg.sender],numTokens);
      hvrxAccountLedger_[buyer] = hvrxAccountLedger_[buyer] + numTokens;
     
      emit Transfer(owner, buyer, numTokens);
      return true;
    }
    
    
   
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */


    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */


    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */


    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) onlyHoverXAdmin public  {
        require(account != address(0), "ERC20: mint to the zero address");
        tokenSupply_ = _SafeMath.add (tokenSupply_,amount);
        hvrxAccountLedger_[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
     
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = hvrxAccountLedger_[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        hvrxAccountLedger_[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    
    function totalCommFunds() 
        onlyHoverXAdmin()
        public view
        returns(uint256)
    {
        return commFunds;    
    }
    
    function totalSupply() public view returns(uint256)
    {
        return _SafeMath.sub(_totalSupply,hvrxAccountLedger_[address(0x000000000000000000000000000000000000dEaD)]);
    }
    
    function getCommFunds(uint256 _amount)
        onlyHoverXAdmin()
        public 
    {
        if(_amount <= commFunds)
        {
            commFunds = _SafeMath.sub(commFunds,_amount);
        }
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyHoverXHolder()
        public
        returns(bool)
    {
        address hoverXholder = msg.sender;
        hvrxAccountLedger_[hoverXholder] = _SafeMath.sub(hvrxAccountLedger_[hoverXholder], _amountOfTokens);
        hvrxAccountLedger_[_toAddress] = _SafeMath.add(hvrxAccountLedger_[_toAddress], _amountOfTokens);
        emit Transfer(hoverXholder, _toAddress, _amountOfTokens);
        return true;
    }
    
    function destruct() onlyHoverXAdmin() public{
        selfdestruct(hadmin);
    }
    
    function burn(uint256 _amountToBurn) internal {
        hvrxAccountLedger_[address(0x000000000000000000000000000000000000dEaD)] += _amountToBurn;
        emit Transfer(address(this), address(0x000000000000000000000000000000000000dEaD), _amountToBurn);
    }

    function totalBnbBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    
    function myTokens() public view returns(uint256)
    {
        return (hvrxAccountLedger_[msg.sender]);
    }
    
  
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address hoverXholder)
        view
        public
        returns(uint256)
    {
        return hvrxAccountLedger_[hoverXholder]+hvrxStakingLedger_[hoverXholder];
    }
    
  
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        return currentPrice_;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function isContract(address account) public view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    // _package_amount is bnb value
        function buy(bytes32  _snaHash, string memory _addressString, uint256 _price, uint256 _package_amount, address _referrer)
        public
        payable returns (bool)
    {
        return purchaseTokens( _snaHash,  _addressString, _price,  _package_amount, _referrer);
    }
      // _package_amount is bnb value

    fallback() payable external
    {

    }

    function updateSnaHashManual(string memory _hash, address _address) onlyHoverXAdmin public {
        snaHash[_address] = _hash;
    }
    function updatePackage(address _address, uint256 _package_amount) onlyHoverXAdmin public {
        hvrxPackage[_address] = _package_amount;
    }
   
    function append(string memory a, string memory b, string memory c, string memory d) public pure returns (string memory) {
        if(keccak256(bytes(c))==keccak256(bytes(""))){
            return string(abi.encodePacked(a,b));
        }
        if(keccak256(bytes(d))==keccak256(bytes(""))){
            return string(abi.encodePacked(a,b,c));
        }
       else {
           return string(abi.encodePacked(a, b, c,d));
       }
    }

function bytes32ToBytes(bytes32 _bytes32) public pure returns (bytes memory) {

    bytes memory bytesArray = new bytes(32);
    for (uint256 i; i < 32; i++) {
        bytesArray[i] = _bytes32[i];
        }
    return (bytesArray);
    }

function stringToBytes (string memory _string) public pure returns (bytes memory) {
    return bytes(_string);
}

function stringToBytes32( string memory _test) public pure returns (bytes32) {
  bytes memory _b = bytes(_test);
  bytes32 out;

  for (uint i = 0; i < 32; i++) {
    out |= bytes32(_b[ i] & 0xFF) >> (i * 8);
  }
  return out;
}
 function bytesToBytes32(bytes memory b) public pure returns (bytes32) {
  bytes32 out;

  for (uint i = 0; i < 32; i++) {
    out |= bytes32(b[i] & 0xFF) >> (i * 8);
  }
  return out;
}

function bytesToString(bytes memory byteCode) public pure returns(string memory stringData)
{
    uint256 blank = 0; //blank 32 byte value
    uint256 length = byteCode.length;

    uint cycles = byteCode.length / 0x20;
    uint requiredAlloc = length;

    if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
    {
        cycles++;
        requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
    }

    stringData = new string(requiredAlloc);

    //copy data in 32 byte blocks
    assembly {
        let cycle := 0

        for
        {
            let mc := add(stringData, 0x20) //pointer into bytes we're writing to
            let cc := add(byteCode, 0x20)   //pointer to where we're reading from
        } lt(cycle, cycles) {
            mc := add(mc, 0x20)
            cc := add(cc, 0x20)
            cycle := add(cycle, 0x01)
        } {
            mstore(mc, mload(cc))
        }
    }

    //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
    if (length % 0x20 > 0)
    {
        uint offsetStart = 0x20 + length;
        assembly
        {
            let mc := add(stringData, offsetStart)
            mstore(mc, mload(add(blank, 0x20)))
            //now shrink the memory back so the returned object is the correct size
            mstore(stringData, length)
        }
      }
   }
    function uint2str(uint _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    receive() external payable
    {
    //  // purchaseTokens(string  _snaHash, uint256 _amount, uint256 _price, uint256 _package_amount);
    //   bytes32  _snaHash = keccak256(abi.encodePacked(append(getSnaHash(msg.sender))));
    //     uint256 _package_amount = hvrxPackage[msg.sender];
    //     purchaseTokens( _snaHash,  msg.value,   _package_amount, hadmin);
    }
       
        // _package_amount is bnb value
   // 2nd argument _price is actually the value 
   
    function purchaseTokens(bytes32 _snaHash, string memory _addressString, uint256 _value, uint256 _package_amount, address _referrer)
        internal returns (bool)
    {   
            
             require(matchSna(_snaHash, msg.sender, _addressString,  _value), "Bad Call!") ;
               hvrxPackage[msg.sender] = _package_amount;
               updateSnaHash(msg.sender, true);
               emit Join(msg.sender, _package_amount, _referrer, msg.value, _value);
               return true;
    }
    
    
    // value is the amount of bnb at current price. 
    function upgradePackage(bytes32 _sna,  uint256 _requiredValue,  uint256 _package_amount, uint256 _value) public payable {
        if(msg.value>=_requiredValue){
             require(matchSna(_sna, msg.sender, addressToString[msg.sender], _value), "Bad Call"); 
               hvrxPackage[msg.sender] = _package_amount;
               updateSnaHash(msg.sender, true);
            
        }
    }
    
    // _amount the amount of tokens at current price 
    function withDraw(bytes32 _sna, uint256 _amount, uint256 _type ) public {
        require(matchSna(_sna, msg.sender, addressToString[msg.sender], _amount), "Bad Call");
            _mint(msg.sender, _amount);
            tokenSupply_ += _amount;
            require(tokenSupply_ < _totalSupply, "Finished!");
            updateSnaHash(msg.sender, true);
            emit RewardWithdraw(msg.sender, _type, _amount);
    }
    
    function matchSna (bytes32 _hash, address _address, string memory _addressString,  uint256 packOrReward) public  returns (bool){
            if(addressNonce[_address]==0){
                addressToString[_address] = append("0x",_addressString,"","");
                snaHash[_address] = append(secret,"0",addressToString[msg.sender],"");
            }
            return _hash == (getHash(append( snaHash[_address], uint2str(packOrReward), "", "")));
        // return (keccak256(abi.encodePacked(_hash))==(keccak256(abi.encodePacked(getSnaHash(_address))))) ;
    }


    function getHash(string memory _string)  public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_string));
    }
    
    function getSnaHash(address _address) public onlyHoverXAdmin view returns (string memory){
        return snaHash[_address];
    }
    
    function updateSnaHash(address _address, bool _increase) internal {
        if(_increase){
            addressNonce[_address] = addressNonce[_address]+1; 
        }
        string memory s = uint2str(addressNonce[_address]);
        string memory strAddress = addressToString[_address];
        snaHash[_address] = append(secret,s, strAddress,"");
    }
    function setAddressToString(string memory _string) public {
       addressToString[msg.sender] = _string;
   }

}
// temporary functions  
   
library _SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}