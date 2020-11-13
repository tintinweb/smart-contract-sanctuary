pragma solidity ^0.6.6;


contract Ownable {
    address public owner;

    event TransferOwnership(address _from, address _to);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }
}

contract ReSupply is Ownable {
    
    using SafeMath for uint256;
    
    event Resupplier(uint256 indexed epoch, uint256 scaleFact);
    event NewResupplier(address oldResupplier, address NewResupplier);
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    string public name     = "ReSupply";
    string public symbol   = "RSP";
    uint8  public decimals = 18;
    
    address public resupplier;
    
    address public rewardAddress;

    /**
     * @notice Internal decimals used to handle scaling factor
     */
    uint256 public constant internalDecimals = 10**24;

    /**
     * @notice Used for percentage maths
     */
    uint256 public constant BASE = 10**18;

    /**
     * @notice Used for setting the anty fraud system
     */
    bool private isContractInitialized = false;
    uint256 public constant START = 1604687400;
    uint256 public  DAYS = 45;

    /**
     * @notice Scaling factor that adjusts everyone's balances if the price is above the peg
     */
    uint256 public rSPScaleFact  = BASE;

    mapping (address => uint256) internal _rSPBalances;
    mapping (address => mapping (address => uint256)) internal _allowedFragments;
    
    
    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;
    mapping(address => bool) public whitelistResupplier;
    
    
    address public noResupplierAddress;
    address public sellerAddress;
    
    uint256 initSupply = 0;
    uint256 _totalSupply = 0;
    uint16 public SELL_FEE = 33;
    uint16 public TX_FEE = 50;
    
    event WhitelistFrom(address _addr, bool _whitelisted);
    event WhitelistTo(address _addr, bool _whitelisted);
    event WhitelistResupplier(address _addr, bool _whitelisted);
    
     constructor(
        uint256 initialSupply,
        address initialSupplyAddr
        
        ) public {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
        _mint(initialSupplyAddr,initialSupply);
        isContractInitialized = true;
        
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function getSellBurn(uint256 value) public view returns (uint256)  {
        uint256 nPercent = value.divRound(SELL_FEE);
        return nPercent;
    }
    function getTxBurn(uint256 value) public view returns (uint256)  {
        uint256 nPercent = value.divRound(TX_FEE);
        return nPercent;
    }
    
    function _isWhitelisted(address _from, address _to) internal view returns (bool) {
        return whitelistFrom[_from]||whitelistTo[_to];
    }
    function _isResupplierWhitelisted(address _addr) internal view returns (bool) {
        return whitelistResupplier[_addr];
    }

    function setWhitelistedTo(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
    }
    
    function setTxFee(uint16 fee) external onlyResupplier {
        TX_FEE = fee;
    }
    
    function setSellFee(uint16 fee) external onlyResupplier {
        SELL_FEE = fee;
    }
    
    function setWhitelistedFrom(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistFrom(_addr, _whitelisted);
        whitelistFrom[_addr] = _whitelisted;
    }
      
    function setWhitelistedResupplier(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistResupplier(_addr, _whitelisted);
        whitelistResupplier[_addr] = _whitelisted;
    }
    
    function setNoResupplierAddress(address _addr) external onlyOwner {
        noResupplierAddress = _addr;
    }
    
    // Configures the seller address
    function setSellerAddress(address _addr) external onlyOwner {
        sellerAddress = _addr;
    }
   
   


    modifier onlyResupplier() {
        require(msg.sender == resupplier);
        _;
    }



    
    /**
    * @notice Computes the current max scaling factor
    */
    function maxScaleFact()
        external
        view
        returns (uint256)
    {
        return _maxScaleFact();
    }

    function _maxScaleFact()
        internal
        view
        returns (uint256)
    {
        // scaling factor can only go up to 2**256-1 = initSupply * rSPScaleFact
        // this is used to check if rSPScaleFact will be too high to compute balances when rebasing.
        return uint256(-1) / initSupply;
    }

   
    function _mint(address to, uint256 amount)
        internal
    {
      // increase totalSupply
      _totalSupply = _totalSupply.add(amount);

      // get underlying value
      uint256 rSPValue = amount.mul(internalDecimals).div(rSPScaleFact);

      // increase initSupply
      initSupply = initSupply.add(rSPValue);

      // make sure the mint didnt push maxScaleFact too low
      require(rSPScaleFact <= _maxScaleFact(), "max scaling factor too low");

      // add balance
      _rSPBalances[to] = _rSPBalances[to].add(rSPValue);
      
      emit Transfer(address(0),to,amount);

     
    }

   function isActive() public view returns (bool) {
        return (
            isContractInitialized == true &&
            now >= START && // Must be after the START date
            now <= START.add(DAYS * 1 days)&& // Must be before the end date
            endOfPSWP() == false
            );
    }

    function endOfPSWP() public view returns (bool) {
        return (now >= START.add(DAYS * 1 days));
    }

    function endEarly(uint256 _DAYS) external onlyOwner {
        DAYS = DAYS - _DAYS;
    }

    /**
    * @dev Transfer tokens to a specified address.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @return True on success, false otherwise.
    */
    function transfer(address to, uint256 value)
        external
        returns (bool)
    {
       
        // underlying balance is stored in rSP, so divide by current scaling factor

        // note, this means as scaling factor grows, dust will be untransferrable.
        // minimum transfer value == rSPScaleFact / 1e24;
        
        // get amount in underlying
        //from noresupplierWallet

      if (isActive() == false || msg.sender == owner || msg.sender == sellerAddress){

        if(_isResupplierWhitelisted(msg.sender)){
            uint256 noReValue = value.mul(internalDecimals).div(BASE);
            uint256 noReNextValue = noReValue.mul(BASE).div(rSPScaleFact);
            _rSPBalances[msg.sender] = _rSPBalances[msg.sender].sub(noReValue); //value==underlying
            _rSPBalances[to] = _rSPBalances[to].add(noReNextValue);
            emit Transfer(msg.sender, to, value);
        }
        else if(_isResupplierWhitelisted(to)){
            uint256 fee = getSellBurn(value);
            uint256 tokensToBurn = fee/2;
            uint256 tokensForRewards = fee-tokensToBurn;
            uint256 tokensToTransfer = value-fee;
                
            uint256 rSPValue = value.mul(internalDecimals).div(rSPScaleFact);
            uint256 rSPValueKeep = tokensToTransfer.mul(internalDecimals).div(rSPScaleFact);
            uint256 rSPValueReward = tokensForRewards.mul(internalDecimals).div(rSPScaleFact);
            
            
            uint256 rSPNextValue = rSPValueKeep.mul(rSPScaleFact).div(BASE);
            
            _totalSupply = _totalSupply-fee;
            _rSPBalances[address(0)] = _rSPBalances[address(0)].add(fee/2);
            _rSPBalances[msg.sender] = _rSPBalances[msg.sender].sub(rSPValue); 
            _rSPBalances[to] = _rSPBalances[to].add(rSPNextValue);
            _rSPBalances[rewardAddress] = _rSPBalances[rewardAddress].add(rSPValueReward);
            emit Transfer(msg.sender, to, tokensToTransfer);
            emit Transfer(msg.sender, address(0), tokensToBurn);
            emit Transfer(msg.sender, rewardAddress, tokensForRewards);
        }
        else{
          if(!_isWhitelisted(msg.sender, to)){
                uint256 fee = getTxBurn(value);
                uint256 tokensToBurn = fee/2;
                uint256 tokensForRewards = fee-tokensToBurn;
                uint256 tokensToTransfer = value-fee;
                    
                uint256 rSPValue = value.mul(internalDecimals).div(rSPScaleFact);
                uint256 rSPValueKeep = tokensToTransfer.mul(internalDecimals).div(rSPScaleFact);
                uint256 rSPValueReward = tokensForRewards.mul(internalDecimals).div(rSPScaleFact);
                
                _totalSupply = _totalSupply-fee;
                _rSPBalances[address(0)] = _rSPBalances[address(0)].add(fee/2);
                _rSPBalances[msg.sender] = _rSPBalances[msg.sender].sub(rSPValue); 
                _rSPBalances[to] = _rSPBalances[to].add(rSPValueKeep);
                _rSPBalances[rewardAddress] = _rSPBalances[rewardAddress].add(rSPValueReward);
                
                
                emit Transfer(msg.sender, to, tokensToTransfer);
                emit Transfer(msg.sender, address(0), tokensToBurn);
                emit Transfer(msg.sender, rewardAddress, tokensForRewards);
           }
             else{
                uint256 rSPValue = value.mul(internalDecimals).div(rSPScaleFact);
               
                _rSPBalances[msg.sender] = _rSPBalances[msg.sender].sub(rSPValue); 
                _rSPBalances[to] = _rSPBalances[to].add(rSPValue);
                emit Transfer(msg.sender, to, rSPValue);
             }
        }
        return true;
      }
    else {return false;} }



    /**
    * @dev Transfer tokens from one address to another.
    * @param from The address you want to send tokens from.
    * @param to The address you want to transfer to.
    * @param value The amount of tokens to be transferred.
    */
    function transferFrom(address from, address to, uint256 value)
        external
        returns (bool)
    {
        // decrease allowance
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);
        
        if (isActive() == false || msg.sender == owner || msg.sender == sellerAddress){

        if(_isResupplierWhitelisted(from)){
            uint256 noReValue = value.mul(internalDecimals).div(BASE);
            uint256 noReNextValue = noReValue.mul(BASE).div(rSPScaleFact);
            _rSPBalances[from] = _rSPBalances[from].sub(noReValue); //value==underlying
            _rSPBalances[to] = _rSPBalances[to].add(noReNextValue);
            emit Transfer(from, to, value);
        }
        else if(_isResupplierWhitelisted(to)){
            uint256 fee = getSellBurn(value);
            uint256 tokensForRewards = fee-(fee/2);
            uint256 tokensToTransfer = value-fee;
            
            uint256 rSPValue = value.mul(internalDecimals).div(rSPScaleFact);
            uint256 rSPValueKeep = tokensToTransfer.mul(internalDecimals).div(rSPScaleFact);
            uint256 rSPValueReward = tokensForRewards.mul(internalDecimals).div(rSPScaleFact);
            uint256 rSPNextValue = rSPValueKeep.mul(rSPScaleFact).div(BASE);
            
            _totalSupply = _totalSupply-fee;
            
            _rSPBalances[from] = _rSPBalances[from].sub(rSPValue); 
            _rSPBalances[to] = _rSPBalances[to].add(rSPNextValue);
            _rSPBalances[rewardAddress] = _rSPBalances[rewardAddress].add(rSPValueReward);
            _rSPBalances[address(0)] = _rSPBalances[address(0)].add(fee/2);
            emit Transfer(from, to, tokensToTransfer);
            emit Transfer(from, address(0), fee/2);
            emit Transfer(from, rewardAddress, tokensForRewards);
        }
        else{
          if(!_isWhitelisted(from, to)){
                uint256 fee = getTxBurn(value);
                uint256 tokensToBurn = fee/2;
                uint256 tokensForRewards = fee-tokensToBurn;
                uint256 tokensToTransfer = value-fee;
                    
                uint256 rSPValue = value.mul(internalDecimals).div(rSPScaleFact);
                uint256 rSPValueKeep = tokensToTransfer.mul(internalDecimals).div(rSPScaleFact);
                uint256 rSPValueReward = tokensForRewards.mul(internalDecimals).div(rSPScaleFact);
            
                _totalSupply = _totalSupply-fee;
                _rSPBalances[address(0)] = _rSPBalances[address(0)].add(fee/2);
                _rSPBalances[from] = _rSPBalances[from].sub(rSPValue); 
                _rSPBalances[to] = _rSPBalances[to].add(rSPValueKeep);
                _rSPBalances[rewardAddress] = _rSPBalances[rewardAddress].add(rSPValueReward);
                emit Transfer(from, to, tokensToTransfer);
                emit Transfer(from, address(0), tokensToBurn);
                emit Transfer(from, rewardAddress, tokensForRewards);
           }
             else{
                uint256 rSPValue = value.mul(internalDecimals).div(rSPScaleFact);
               
                _rSPBalances[from] = _rSPBalances[from].sub(rSPValue); 
                _rSPBalances[to] = _rSPBalances[to].add(rSPValue);
                emit Transfer(from, to, rSPValue);
                
            
             }
        }
        return true;
      }
    }
    

    /**
    * @param who The address to query.
    * @return The balance of the specified address.
    */
    function balanceOf(address who)
      external
      view
      returns (uint256)
    {
      if(_isResupplierWhitelisted(who)){
        return _rSPBalances[who].mul(BASE).div(internalDecimals);
      }
      else{
        return _rSPBalances[who].mul(rSPScaleFact).div(internalDecimals);
      }
    }

    /** @notice Currently returns the internal storage amount
    * @param who The address to query.
    * @return The underlying balance of the specified address.
    */
    function balanceOfUnderlying(address who)
      external
      view
      returns (uint256)
    {
      return _rSPBalances[who];
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        external
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /* - Governance Functions - */

    /** @notice sets the resupplier
     * @param resupplier_ The address of the resupplier contract to use for authentication.
     */
    function _setResupplier(address resupplier_)
        external
        onlyOwner
    {
        address oldResupplier = resupplier;
        resupplier = resupplier_;
        emit NewResupplier(oldResupplier, resupplier_);
    }
    
     function _setRewardAddress(address rewards_)
        external
        onlyOwner
    {
        rewardAddress = rewards_;
      
    }
    
    /**
    * @notice Initiates a new resupplier operation, provided the minimum time period has elapsed.
    *
    * @dev The supply adjustment equals (totalSupply * DeviationFromTargetRate) / resupplierLag
    *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
    *      and targetRate is CpiOracleRate / baseCpi
    */
    function resupply(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    )
        external
        onlyResupplier
        returns (uint256)
    {
        if (indexDelta == 0 || !positive) {
          emit Resupplier(epoch, rSPScaleFact);
          return _totalSupply;
        }

            uint256 newScaleFact = rSPScaleFact.mul(BASE.add(indexDelta)).div(BASE);
            if (newScaleFact < _maxScaleFact()) {
                rSPScaleFact = newScaleFact;
            } else {
              rSPScaleFact = _maxScaleFact();
            }
        

        _totalSupply = ((initSupply.sub(_rSPBalances[address(0)]).sub(_rSPBalances[noResupplierAddress]))
                        .mul(rSPScaleFact).div(internalDecimals))
                        .add(_rSPBalances[noResupplierAddress].mul(BASE).div(internalDecimals));
        emit Resupplier(epoch, rSPScaleFact);
        return _totalSupply;
    }
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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
  
  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
  
  function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }
}