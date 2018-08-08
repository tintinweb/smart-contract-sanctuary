pragma solidity ^ 0.4.17;


library SafeMath {

    function mul(uint a, uint b) internal pure returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal pure  returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal  pure returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns(uint);

    function allowance(address owner, address spender) public view returns(uint);

    function transfer(address to, uint value) public returns(bool ok);

    function transferFrom(address from, address to, uint value) public returns(bool ok);

    function approve(address spender, uint value) public returns(bool ok);

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
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
    modifier whenPaused() {
        require(paused);
        _;
    }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}


// Whitelist smart contract
// This smart contract keeps list of addresses to whitelist
contract WhiteList is Ownable {
    
    mapping(address => bool) public whiteList;
    uint public totalWhiteListed; //white listed users number

    event LogWhiteListed(address indexed user, uint whiteListedNum);
    event LogWhiteListedMultiple(uint whiteListedNum);
    event LogRemoveWhiteListed(address indexed user);

    // @notice it will return status of white listing
    // @return true if user is white listed and false if is not
    function isWhiteListed(address _user) external view returns (bool) {

        return whiteList[_user]; 
    }

    // @notice it will remove whitelisted user
    // @param _contributor {address} of user to unwhitelist
    function removeFromWhiteList(address _user) external onlyOwner() returns (bool) {
       
        require(whiteList[_user] == true);
        whiteList[_user] = false;
        totalWhiteListed--;
        LogRemoveWhiteListed(_user);
        return true;
    }

    // @notice it will white list one member
    // @param _user {address} of user to whitelist
    // @return true if successful
    function addToWhiteList(address _user) external onlyOwner()  returns (bool) {

        if (whiteList[_user] != true) {
            whiteList[_user] = true;
            totalWhiteListed++;
            LogWhiteListed(_user, totalWhiteListed);            
        }
        return true;
    }

    // @notice it will white list multiple members
    // @param _user {address[]} of users to whitelist
    // @return true if successful
    function addToWhiteListMultiple(address[] _users) external onlyOwner()  returns (bool) {

        for (uint i = 0; i < _users.length; ++i) {

            if (whiteList[_users[i]] != true) {
                whiteList[_users[i]] = true;
                totalWhiteListed++;                          
            }           
        }
        LogWhiteListedMultiple(totalWhiteListed); 
        return true;
    }
}


// @note this contract can be inherited by Crowdsale and TeamAllocation contracts and
// control release of tokens through even time release based on the inputted duration time interval
contract TokenVesting is Ownable {
    using SafeMath for uint;

    struct TokenHolder {
        uint weiReceived; // amount of ETH contributed
        uint tokensToSend; // amount of tokens  sent  
        bool refunded; // true if user has been refunded       
        uint releasedAmount; // amount released through vesting schedule
        bool revoked; // true if right to continue vesting is revoked
    }

    event Released(uint256 amount, uint256 tokenDecimals);
    event ContractUpdated(bool done);

    uint256 public cliff;  // time in  when vesting should begin
    uint256 public startCountDown;  // time when countdown starts
    uint256 public duration; // duration of period in which vesting takes place   
    Token public token;  // token contract containing tokens
    mapping(address => TokenHolder) public tokenHolders; //tokenHolder list
    WhiteList public whiteList; // whitelist contract
    uint256 public presaleBonus;
    
    // @note constructor 
    /**
    function TokenVesting(uint256 _start, uint256 _cliff, uint256 _duration) public {   
         require(_cliff <= _duration);   
        duration = _duration;
        cliff = _start.add(_cliff);
        startCountDown = _start;         
        ContractUpdated(true);                    
    }
    */
    // @notice Specify address of token contract
    // @param _tokenAddress {address} address of token contract
    // @return res {bool}
    function initilizeVestingAndTokenAndWhiteList(Token _tokenAddress, 
                                        uint256 _start, 
                                        uint256 _cliff, 
                                        uint256 _duration,
                                        uint256 _presaleBonus, 
                                        WhiteList _whiteList) external onlyOwner() returns(bool res) {
        require(_cliff <= _duration);   
        require(_tokenAddress != address(0));
        duration = _duration;
        cliff = _start.add(_cliff);
        startCountDown = _start;  
        token = _tokenAddress; 
        whiteList = _whiteList;
        presaleBonus = _presaleBonus;
        ContractUpdated(true);
        return true;    
    }

    // @notice Specify address of token contract
    // @param _tokenAddress {address} address of token contract
    // @return res {bool}
    function initilizeVestingAndToken(Token _tokenAddress, 
                                        uint256 _start, 
                                        uint256 _cliff, 
                                        uint256 _duration,
                                        uint256 _presaleBonus
                                        ) external onlyOwner() returns(bool res) {
        require(_cliff <= _duration);   
        require(_tokenAddress != address(0));
        duration = _duration;
        cliff = _start.add(_cliff);
        startCountDown = _start;  
        token = _tokenAddress;        
        presaleBonus = _presaleBonus;
        ContractUpdated(true);
        return true;    
    }

    function returnVestingSchedule() external view returns (uint, uint, uint) {

        return (duration, cliff, startCountDown);
    }

    // @note owner can revoke access to continue vesting of tokens
    // @param _user {address} of user to revoke their right to vesting
    function revoke(address _user) public onlyOwner() {

        TokenHolder storage tokenHolder = tokenHolders[_user];
        tokenHolder.revoked = true; 
    }

    function vestedAmountAvailable() public view returns (uint amount, uint decimals) {

        TokenHolder storage tokenHolder = tokenHolders[msg.sender];
        uint tokensToRelease = vestedAmount(tokenHolder.tokensToSend);

     //   if (tokenHolder.releasedAmount + tokensToRelease > tokenHolder.tokensToSend)
      //      return (tokenHolder.tokensToSend - tokenHolder.releasedAmount, token.decimals());
     //   else 
        return (tokensToRelease - tokenHolder.releasedAmount, token.decimals());
    }
    
    // @notice Transfers vested available tokens to beneficiary   
    function release() public {

        TokenHolder storage tokenHolder = tokenHolders[msg.sender];        
        // check if right to vesting is not revoked
        require(!tokenHolder.revoked);                                   
        uint tokensToRelease = vestedAmount(tokenHolder.tokensToSend);      
        uint currentTokenToRelease = tokensToRelease - tokenHolder.releasedAmount;
        tokenHolder.releasedAmount += currentTokenToRelease;            
        token.transfer(msg.sender, currentTokenToRelease);

        Released(currentTokenToRelease, token.decimals());
    }
  
    // @notice this function will determine vested amount
    // @param _totalBalance {uint} total balance of tokens assigned to this user
    // @return {uint} amount of tokens available to transfer
    function vestedAmount(uint _totalBalance) public view returns (uint) {

        if (now < cliff) {
            return 0;
        } else if (now >= startCountDown.add(duration)) {
            return _totalBalance;
        } else {
            return _totalBalance.mul(now.sub(startCountDown)) / duration;
        }
    }
}


// Crowdsale Smart Contract
// This smart contract collects ETH and in return sends  tokens to the Backers
contract Crowdsale is Pausable, TokenVesting {

    using SafeMath for uint;

    address public multisigETH; // Multisig contract that will receive the ETH
    address public commissionAddress;  // address to deposit commissions
    uint public tokensForTeam; // tokens for the team
    uint public ethReceivedPresale; // Number of ETH received in presale
    uint public ethReceivedMain; // Number of ETH received in main sale
    uint public totalTokensSent; // Number of tokens sent to ETH contributors
    uint public tokensSentMain;
    uint public tokensSentPresale;       
    uint public tokensSentDev;         
    uint public startBlock; // Crowdsale start block
    uint public endBlock; // Crowdsale end block
    uint public maxCap; // Maximum number of token to sell
    uint public minCap; // Minimum number of ETH to raise
    uint public minContributionMainSale; // Minimum amount to contribute in main sale
    uint public minContributionPresale; // Minimum amount to contribut in presale
    uint public maxContribution;
    bool public crowdsaleClosed; // Is crowdsale still on going
    uint public tokenPriceWei;
    uint public refundCount;
    uint public totalRefunded;
    uint public campaignDurationDays; // campaign duration in days 
    uint public firstPeriod; 
    uint public secondPeriod; 
    uint public thirdPeriod; 
    uint public firstBonus; 
    uint public secondBonus;
    uint public thirdBonus;
    uint public multiplier;
    uint public status;    
    Step public currentStep;  // To allow for controlled steps of the campaign 
   
    // Looping through Backer
    //mapping(address => Backer) public backers; //backer list
    address[] public holdersIndex;   // to be able to itarate through backers when distributing the tokens
    address[] public devIndex;   // to be able to itarate through backers when distributing the tokens

    // @notice to set and determine steps of crowdsale
    enum Step {      
        FundingPreSale,     // presale mode
        FundingMainSale,  // public mode
        Refunding  // in case campaign failed during this step contributors will be able to receive refunds
    }

    // @notice to verify if action is not performed out of the campaing range
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) 
            revert();
        _;
    }

    modifier minCapNotReached() {
        if (totalTokensSent >= minCap) 
            revert();
        _;
    }

    // Events
    event LogReceivedETH(address indexed backer, uint amount, uint tokenAmount);
    event LogStarted(uint startBlockLog, uint endBlockLog);
    event LogFinalized(bool success);  
    event LogRefundETH(address indexed backer, uint amount);
    event LogStepAdvanced();
    event LogDevTokensAllocated(address indexed dev, uint amount);
    event LogNonVestedTokensSent(address indexed user, uint amount);

    // Crowdsale  {constructor}
    // @notice fired when contract is crated. Initilizes all constnat variables.
    function Crowdsale(uint _decimalPoints,
                        address _multisigETH,
                        uint _toekensForTeam, 
                        uint _minContributionPresale,
                        uint _minContributionMainSale,
                        uint _maxContribution,                        
                        uint _maxCap, 
                        uint _minCap, 
                        uint _tokenPriceWei, 
                        uint _campaignDurationDays,
                        uint _firstPeriod, 
                        uint _secondPeriod, 
                        uint _thirdPeriod, 
                        uint _firstBonus, 
                        uint _secondBonus,
                        uint _thirdBonus) public {
        multiplier = 10**_decimalPoints;
        multisigETH = _multisigETH; 
        tokensForTeam = _toekensForTeam * multiplier; 
        minContributionPresale = _minContributionPresale; 
        minContributionMainSale = _minContributionMainSale;
        maxContribution = _maxContribution;       
        maxCap = _maxCap * multiplier;       
        minCap = _minCap * multiplier;
        tokenPriceWei = _tokenPriceWei;
        campaignDurationDays = _campaignDurationDays;
        firstPeriod = _firstPeriod; 
        secondPeriod = _secondPeriod; 
        thirdPeriod = _thirdPeriod;
        firstBonus = _firstBonus;
        secondBonus = _secondBonus;
        thirdBonus = _thirdBonus;       
        //TODO replace this address below with correct address.
        commissionAddress = 0x326B5E9b8B2ebf415F9e91b42c7911279d296ea1;
        //commissionAddress = 0x853A3F142430658A32f75A0dc891b98BF4bDF5c1;
        currentStep = Step.FundingPreSale; 
    }

    // @notice to populate website with status of the sale 
    function returnWebsiteData() external view returns(uint, 
        uint, uint, uint, uint, uint, uint, uint, uint, uint, bool, bool, uint, Step) {
    
        return (startBlock, endBlock, numberOfBackers(), ethReceivedPresale + ethReceivedMain, maxCap, minCap, 
                totalTokensSent, tokenPriceWei, minContributionPresale, minContributionMainSale, 
                paused, crowdsaleClosed, token.decimals(), currentStep);
    }
    
    // @notice this function will determine status of crowdsale
    function determineStatus() external view returns (uint) {
       
        if (crowdsaleClosed)            // ICO finihsed
            return 1;   

        if (block.number < endBlock && totalTokensSent < maxCap - 100)   // ICO in progress
            return 2;            
    
        if (totalTokensSent < minCap && block.number > endBlock)      // ICO failed    
            return 3;            
    
        if (endBlock == 0)           // ICO hasn&#39;t been started yet 
            return 4;            
    
        return 0;         
    } 

    // {fallback function}
    // @notice It will call internal function which handels allocation of Ether and calculates tokens.
    function () public payable {    
             
        contribute(msg.sender);
    }

    // @notice to allow for contribution from interface
    function contributePublic() external payable {
        contribute(msg.sender);
    }

    // @notice set the step of the campaign from presale to public sale
    // contract is deployed in presale mode
    // WARNING: there is no way to go back
    function advanceStep() external onlyOwner() {
        currentStep = Step.FundingMainSale;
        LogStepAdvanced();
    }

    // @notice It will be called by owner to start the sale    
    function start() external onlyOwner() {
        startBlock = block.number;
        endBlock = startBlock + (4*60*24*campaignDurationDays); // assumption is that one block takes 15 sec. 
        crowdsaleClosed = false;
        LogStarted(startBlock, endBlock);
    }

    // @notice This function will finalize the sale.
    // It will only execute if predetermined sale time passed or all tokens are sold.
    function finalize() external onlyOwner() {

        require(!crowdsaleClosed);                       
        require(block.number >= endBlock || totalTokensSent > maxCap - 1000);
                    // - 1000 is used to allow closing of the campaing when contribution is near 
                    // finished as exact amount of maxCap might be not feasible e.g. you can&#39;t easily buy few tokens. 
                    // when min contribution is 0.1 Eth.  

        require(totalTokensSent >= minCap);
        crowdsaleClosed = true;
        
        // transfer commission portion to the platform
        commissionAddress.transfer(determineCommissions());         
        
        // transfer remaning funds to the campaign wallet
        multisigETH.transfer(this.balance);
        
        /*if (!token.transfer(owner, token.balanceOf(this))) 
            revert(); // transfer tokens to admin account  
            
        if (!token.burn(this, token.balanceOf(this))) 
            revert();  // burn all the tokens remaining in the contract   */
        token.unlock();    // release lock from transfering tokens. 

        LogFinalized(true);        
    }

    // @notice it will allow contributors to get refund in case campaign failed
    // @return {bool} true if successful
    function refund() external whenNotPaused returns (bool) {      
        
        uint totalEtherReceived = ethReceivedPresale + ethReceivedMain;

        require(totalEtherReceived < minCap);  // ensure that campaign failed
        require(this.balance > 0);  // contract will hold 0 ether at the end of campaign.
                                    // contract needs to be funded through fundContract() 
        TokenHolder storage backer = tokenHolders[msg.sender];

        require(backer.weiReceived > 0);  // ensure that user has sent contribution
        require(!backer.refunded);        // ensure that user hasn&#39;t been refunded yet

        backer.refunded = true;  // save refund status to true
        refundCount++;
        totalRefunded += backer.weiReceived;

        if (!token.burn(msg.sender, backer.tokensToSend)) // burn tokens
            revert();        
        msg.sender.transfer(backer.weiReceived);  // send back the contribution 
        LogRefundETH(msg.sender, backer.weiReceived);
        return true;
    }

    // @notice allocate tokens to dev/team/advisors
    // @param _dev {address} 
    // @param _amount {uint} amount of tokens
    function devAllocation(address _dev, uint _amount) external onlyOwner() returns (bool) {

        require(_dev != address(0));
        require(crowdsaleClosed); 
        require(totalTokensSent.add(_amount) <= token.totalSupply());
        devIndex.push(_dev);
        TokenHolder storage tokenHolder = tokenHolders[_dev];
        tokenHolder.tokensToSend = _amount;
        tokensSentDev += _amount;
        totalTokensSent += _amount;        
        LogDevTokensAllocated(_dev, _amount); // Register event
        return true;

    }

    // @notice Failsafe drain
    function drain(uint _amount) external onlyOwner() {
        owner.transfer(_amount);           
    }

    // @notice transfer tokens which are not subject to vesting
    // @param _recipient {addres}
    // @param _amont {uint} amount to transfer
    function transferTokens(address _recipient, uint _amount) external onlyOwner() returns (bool) {

        require(_recipient != address(0));
        if (!token.transfer(_recipient, _amount))
            revert();
        LogNonVestedTokensSent(_recipient, _amount);
    }

    // @notice determine amount of commissions for the platform    
    function determineCommissions() public view returns (uint) {
     
        if (this.balance <= 500 ether) {
            return (this.balance * 10)/100;
        }else if (this.balance <= 1000 ether) {
            return (this.balance * 8)/100;
        }else if (this.balance < 10000 ether) {
            return (this.balance * 6)/100;
        }else {
            return (this.balance * 6)/100;
        }
    }

    // @notice return number of contributors
    // @return  {uint} number of contributors
    function numberOfBackers() public view returns (uint) {
        return holdersIndex.length;
    }

    // @notice It will be called by fallback function whenever ether is sent to it
    // @param  _backer {address} address of beneficiary
    // @return res {bool} true if transaction was successful
    function contribute(address _backer) internal whenNotPaused respectTimeFrame returns(bool res) {

        //require(msg.value <= maxContribution);

        if (whiteList != address(0))  // if whitelist initialized verify member whitelist status
            require(whiteList.isWhiteListed(_backer));  // ensure that user is whitelisted
          
        uint tokensToSend = calculateNoOfTokensToSend(); // calculate number of tokens

        // Ensure that max cap hasn&#39;t been reached
        require(totalTokensSent + tokensToSend <= maxCap);
        
        TokenHolder storage backer = tokenHolders[_backer];

        if (backer.weiReceived == 0)
            holdersIndex.push(_backer);

        if (Step.FundingMainSale == currentStep) { // Update the total Ether received and tokens sent during public sale
            require(msg.value >= minContributionMainSale); // stop when required minimum is not met    
            ethReceivedMain = ethReceivedMain.add(msg.value);
            tokensSentMain += tokensToSend;
        }else {  
            require(msg.value >= minContributionPresale); // stop when required minimum is not met
            ethReceivedPresale = ethReceivedPresale.add(msg.value); 
            tokensSentPresale += tokensToSend;
        }  
       
        backer.tokensToSend += tokensToSend;
        backer.weiReceived = backer.weiReceived.add(msg.value);       
        totalTokensSent += tokensToSend;      
        
        // tokens are not transferrd to contributors during this phase
        // tokens will be transferred based on the vesting schedule, when contributor
        // calls release() function of this contract
        LogReceivedETH(_backer, msg.value, tokensToSend); // Register event
        return true;
    }

    // @notice This function will return number of tokens based on time intervals in the campaign
    function calculateNoOfTokensToSend() internal view returns (uint) {

        uint tokenAmount = msg.value.mul(multiplier) / tokenPriceWei;

        if (Step.FundingMainSale == currentStep) {
        
            if (block.number <= startBlock + firstPeriod) {  
                return  tokenAmount + tokenAmount.mul(firstBonus) / 100;
            }else if (block.number <= startBlock + secondPeriod) {
                return  tokenAmount + tokenAmount.mul(secondBonus) / 100; 
            }else if (block.number <= startBlock + thirdPeriod) { 
                return  tokenAmount + tokenAmount.mul(thirdBonus) / 100;        
            }else {              
                return  tokenAmount; 
            }
        }else 
            return  tokenAmount + tokenAmount.mul(presaleBonus) / 100;
    }  
}


// The  token
contract Token is ERC20, Ownable {

    using SafeMath for uint;
    // Public variables of the token
    string public name;
    string public symbol;
    uint public decimals; // How many decimals to show.
    string public version = "v0.1";
    uint public totalSupply;
    bool public locked;
    address public crowdSaleAddress;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
    // Lock transfer during the ICO
    modifier onlyUnlocked() {
        if (msg.sender != crowdSaleAddress && locked && msg.sender != owner) 
            revert();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != crowdSaleAddress && msg.sender != owner) 
            revert();
        _;
    }

    // The Token constructor     
    function Token(uint _initialSupply,
            string _tokenName,
            uint _decimalUnits,
            string _tokenSymbol,
            string _version,
            address _crowdSaleAddress) public {      
        locked = true;  // Lock the transfer of tokens during the crowdsale
        totalSupply = _initialSupply * (10**_decimalUnits);     
                                        
        name = _tokenName; // Set the name for display purposes
        symbol = _tokenSymbol; // Set the symbol for display purposes
        decimals = _decimalUnits; // Amount of decimals for display purposes
        version = _version;
        crowdSaleAddress = _crowdSaleAddress;              
        balances[crowdSaleAddress] = totalSupply;   
    }

    function unlock() public onlyAuthorized {
        locked = false;
    }

    function lock() public onlyAuthorized {
        locked = true;
    }

    function burn(address _member, uint256 _value) public onlyAuthorized returns(bool) {
        require(balances[_member] >= _value);
        balances[_member] -= _value;
        totalSupply -= _value;
        Transfer(_member, 0x0, _value);
        return true;
    }

   
    // @notice transfer tokens to given address
    // @param _to {address} address or recipient
    // @param _value {uint} amount to transfer
    // @return  {bool} true if successful
    function transfer(address _to, uint _value) public onlyUnlocked returns(bool) {

        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // @notice transfer tokens from given address to another address
    // @param _from {address} from whom tokens are transferred
    // @param _to {address} to whom tokens are transferred
    // @param _value {uint} amount of tokens to transfer
    // @return  {bool} true if successful
    function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked returns(bool success) {

        require(_to != address(0));
        require(balances[_from] >= _value); // Check if the sender has enough
        require(_value <= allowed[_from][msg.sender]); // Check if allowed is greater or equal
        balances[_from] -= _value; // Subtract from the sender
        balances[_to] += _value; // Add the same to the recipient
        allowed[_from][msg.sender] -= _value;  // adjust allowed
        Transfer(_from, _to, _value);
        return true;
    }

      // @notice to query balance of account
    // @return _owner {address} address of user to query balance
    function balanceOf(address _owner) public view returns(uint balance) {
        return balances[_owner];
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // @notice to query of allowance of one user to the other
    // @param _owner {address} of the owner of the account
    // @param _spender {address} of the spender of the account
    // @return remaining {uint} amount of remaining allowance
    function allowance(address _owner, address _spender) public view returns(uint remaining) {
        return allowed[_owner][_spender];
    }

    /**
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}