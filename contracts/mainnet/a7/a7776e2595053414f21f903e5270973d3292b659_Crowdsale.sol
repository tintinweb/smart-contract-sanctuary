pragma solidity ^ 0.4.17;


library SafeMath {
    function mul(uint a, uint b) pure internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) pure internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) pure internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) 
            owner = newOwner;
    }

    function kill() public {
        if (msg.sender == owner) 
            selfdestruct(owner);
    }

    modifier onlyOwner() {
        if (msg.sender == owner)
            _;
    }
}


contract Pausable is Ownable {
    bool public stopped;

    modifier stopInEmergency {
        if (stopped) {
            revert();
        }
        _;
    }

    modifier onlyInEmergency {
        if (!stopped) {
            revert();
        }
        _;
    }

    // Called by the owner in emergency, triggers stopped state
    function emergencyStop() external onlyOwner() {
        stopped = true;
    }

    // Called by the owner to end of emergency, returns to normal state
    function release() external onlyOwner() onlyInEmergency {
        stopped = false;
    }
}

contract WhiteList is Ownable {

    function isWhiteListedAndAffiliate(address _user) external view returns (bool, address);
}

// Crowdsale Smart Contract
// This smart contract collects ETH and in return sends tokens to contributors
contract Crowdsale is Pausable {

    using SafeMath for uint;

    struct Backer {
        uint weiReceived; // amount of ETH contributed
        uint tokensToSend; // amount of tokens  sent  
        bool claimed;
        bool refunded; // true if user has been refunded       
    }

    Token public token; // Token contract reference   
    address public multisig; // Multisig contract that will receive the ETH    
    address public team; // Address at which the team tokens will be sent   
    uint public teamTokens; // tokens for the team.     
    uint public ethReceivedPresale; // Number of ETH received in presale
    uint public ethReceivedMain; // Number of ETH received in public sale
    uint public totalTokensSent; // Number of tokens sent to ETH contributors
    uint public totalAffiliateTokensSent;
    uint public startBlock; // Crowdsale start block
    uint public endBlock; // Crowdsale end block
    uint public maxCap; // Maximum number of tokens to sell
    uint public minCap; // Minimum number of ETH to raise
    uint public minInvestETH; // Minimum amount to invest   
    bool public crowdsaleClosed; // Is crowdsale still in progress
    Step public currentStep;  // to allow for controled steps of the campaign 
    uint public refundCount;  // number of refunds
    uint public totalRefunded; // total amount of refunds    
    uint public tokenPriceWei;  // price of token in wei
    WhiteList public whiteList; // white list address
    uint public numOfBlocksInMinute;// number of blocks in one minute * 100. eg. 
    uint public claimCount; // number of claims
    uint public totalClaimed; // Total number of tokens claimed
    

    mapping(address => Backer) public backers; //backer list
    mapping(address => uint) public affiliates; // affiliates list
    address[] public backersIndex; // to be able to itarate through backers for verification.  
    mapping(address => uint) public claimed;  // Tokens claimed by contibutors

    
    // @notice to verify if action is not performed out of the campaing range
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) 
            revert();
        _;
    }

    // @notice to set and determine steps of crowdsale
    enum Step {
        Unknown,
        FundingPreSale,     // presale mode
        FundingPublicSale,  // public mode
        Refunding,  // in case campaign failed during this step contributors will be able to receive refunds
        Claiming    // set this step to enable claiming of tokens. 
    }

    // Events
    event ReceivedETH(address indexed backer, address indexed affiliate, uint amount, uint tokenAmount, uint affiliateTokenAmount);
    event RefundETH(address backer, uint amount);
    event TokensClaimed(address backer, uint count);


    // Crowdsale  {constructor}
    // @notice fired when contract is crated. Initilizes all constnat and initial values.
    function Crowdsale(WhiteList _whiteListAddress) public {
        multisig = 0x49447Ea549CCfFDEF2E9a9290709d6114346df88; 
        team = 0x49447Ea549CCfFDEF2E9a9290709d6114346df88;                                         
        startBlock = 0; // Should wait for the call of the function start
        endBlock = 0; // Should wait for the call of the function start                  
        tokenPriceWei = 108110000000000;
        maxCap = 210000000e18;         
        minCap = 21800000e18;        
        totalTokensSent = 0;  //TODO: add tokens sold in private sale
        setStep(Step.FundingPreSale);
        numOfBlocksInMinute = 416;    
        whiteList = WhiteList(_whiteListAddress);    
        teamTokens = 45000000e18;
    }

    // @notice to populate website with status of the sale 
    function returnWebsiteData() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, Step, bool, bool) {            
    
        return (startBlock, endBlock, backersIndex.length, ethReceivedPresale.add(ethReceivedMain), maxCap, minCap, totalTokensSent, tokenPriceWei, currentStep, stopped, crowdsaleClosed);
    }

    // @notice Specify address of token contract
    // @param _tokenAddress {address} address of token contract
    // @return res {bool}
    function updateTokenAddress(Token _tokenAddress) external onlyOwner() returns(bool res) {
        token = _tokenAddress;
        return true;
    }

    // @notice set the step of the campaign 
    // @param _step {Step}
    function setStep(Step _step) public onlyOwner() {
        currentStep = _step;
        
        if (currentStep == Step.FundingPreSale) {  // for presale 
          
            minInvestETH = 1 ether/5;                             
        }else if (currentStep == Step.FundingPublicSale) { // for public sale           
            minInvestETH = 1 ether/10;               
        }      
    }

    // {fallback function}
    // @notice It will call internal function which handels allocation of Ether and calculates tokens.
    function () external payable {           
        contribute(msg.sender);
    }

    // @notice It will be called by owner to start the sale    
    function start(uint _block) external onlyOwner() {   

        require(_block < 335462);  // 4.16*60*24*56 days = 335462     
        startBlock = block.number;
        endBlock = startBlock.add(_block); 
    }

    // @notice Due to changing average of block time
    // this function will allow on adjusting duration of campaign closer to the end 
    function adjustDuration(uint _block) external onlyOwner() {

        require(_block < 389376);  // 4.16*60*24*65 days = 389376     
        require(_block > block.number.sub(startBlock)); // ensure that endBlock is not set in the past
        endBlock = startBlock.add(_block); 
    }

    // @notice It will be called by fallback function whenever ether is sent to it
    // @param  _backer {address} address contributor
    // @return res {bool} true if transaction was successful
    function contribute(address _backer) internal stopInEmergency respectTimeFrame returns(bool res) {

        uint affiliateTokens;

        var(isWhiteListed, affiliate) = whiteList.isWhiteListedAndAffiliate(_backer);

        require(isWhiteListed);      // ensure that user is whitelisted
    
        require(currentStep == Step.FundingPreSale || currentStep == Step.FundingPublicSale); // ensure that this is correct step
        require(msg.value >= minInvestETH);   // ensure that min contributions amount is met
          
        uint tokensToSend = determinePurchase();

        if (affiliate != address(0)) {
            affiliateTokens = (tokensToSend * 5) / 100; // give 5% of tokens to affiliate
            affiliates[affiliate] += affiliateTokens;
            Backer storage referrer = backers[affiliate];
            referrer.tokensToSend = referrer.tokensToSend.add(affiliateTokens);
        }
        
        require(totalTokensSent.add(tokensToSend.add(affiliateTokens)) < maxCap); // Ensure that max cap hasn&#39;t been reached  
            
        Backer storage backer = backers[_backer];
    
        if (backer.tokensToSend == 0)      
            backersIndex.push(_backer);
           
        backer.tokensToSend = backer.tokensToSend.add(tokensToSend); // save contributors tokens to be sent
        backer.weiReceived = backer.weiReceived.add(msg.value);  // save how much was the contribution
        totalTokensSent += tokensToSend + affiliateTokens;     // update the total amount of tokens sent
        totalAffiliateTokensSent += affiliateTokens;
    
        if (Step.FundingPublicSale == currentStep)  // Update the total Ether recived
            ethReceivedMain = ethReceivedMain.add(msg.value);
        else
            ethReceivedPresale = ethReceivedPresale.add(msg.value);     
       
        multisig.transfer(this.balance);   // transfer funds to multisignature wallet             
    
        ReceivedETH(_backer, affiliate, msg.value, tokensToSend, affiliateTokens); // Register event
        return true;
    }

    // @notice determine if purchase is valid and return proper number of tokens
    // @return tokensToSend {uint} proper number of tokens based on the timline     
    function determinePurchase() internal view  returns (uint) {
       
        require(msg.value >= minInvestETH);                        // ensure that min contributions amount is met  
        uint tokenAmount = msg.value.mul(1e18) / tokenPriceWei;    // calculate amount of tokens

        uint tokensToSend;  

        if (currentStep == Step.FundingPreSale)
            tokensToSend = calculateNoOfTokensToSend(tokenAmount); 
        else
            tokensToSend = tokenAmount;
                                                                                                       
        return tokensToSend;
    }

    // @notice This function will return number of tokens based on time intervals in the campaign
    // @param _tokenAmount {uint} amount of tokens to allocate for the contribution
    function calculateNoOfTokensToSend(uint _tokenAmount) internal view  returns (uint) {
              
        if (block.number <= startBlock + (numOfBlocksInMinute * 60 * 24 * 14) / 100)        // less equal then/equal 14 days
            return  _tokenAmount + (_tokenAmount * 40) / 100;  // 40% bonus
        else if (block.number <= startBlock + (numOfBlocksInMinute * 60 * 24 * 28) / 100)   // less equal  28 days
            return  _tokenAmount + (_tokenAmount * 30) / 100; // 30% bonus
        else
            return  _tokenAmount + (_tokenAmount * 20) / 100;   // remainder of the campaign 20% bonus
          
    }

    // @notice erase contribution from the database and do manual refund for disapproved users
    // @param _backer {address} address of user to be erased
    function eraseContribution(address _backer) external onlyOwner() {

        Backer storage backer = backers[_backer];        
        backer.refunded = true;
        totalTokensSent = totalTokensSent.sub(backer.tokensToSend);        
    }

    // @notice allow on manual addition of contributors
    // @param _backer {address} of contributor to be added
    // @parm _amountTokens {uint} tokens to be added
    function addManualContributor(address _backer, uint _amountTokens) external onlyOwner() {

        Backer storage backer = backers[_backer];        
        backer.tokensToSend = backer.tokensToSend.add(_amountTokens);
        if (backer.tokensToSend == 0)      
            backersIndex.push(_backer);
        totalTokensSent = totalTokensSent.add(_amountTokens);
    }


    // @notice contributors can claim tokens after public ICO is finished
    // tokens are only claimable when token address is available and lock-up period reached. 
    function claimTokens() external {
        claimTokensForUser(msg.sender);
    }

    // @notice this function can be called by admin to claim user&#39;s token in case of difficulties
    // @param _backer {address} user address to claim tokens for
    function adminClaimTokenForUser(address _backer) external onlyOwner() {
        claimTokensForUser(_backer);
    }

    // @notice in case refunds are needed, money can be returned to the contract
    // and contract switched to mode refunding
    function prepareRefund() public payable onlyOwner() {
        
        require(msg.value == ethReceivedMain + ethReceivedPresale); // make sure that proper amount of ether is sent
        currentStep == Step.Refunding;
    }

    // @notice return number of contributors
    // @return  {uint} number of contributors   
    function numberOfBackers() public view returns(uint) {
        return backersIndex.length;
    }
 
    // @notice called to send tokens to contributors after ICO and lockup period. 
    // @param _backer {address} address of beneficiary
    // @return true if successful
    function claimTokensForUser(address _backer) internal returns(bool) {       

        require(currentStep == Step.Claiming);
                  
        Backer storage backer = backers[_backer];

        require(!backer.refunded);      // if refunded, don&#39;t allow for another refund           
        require(!backer.claimed);       // if tokens claimed, don&#39;t allow refunding            
        require(backer.tokensToSend != 0);   // only continue if there are any tokens to send           

        claimCount++;
        claimed[_backer] = backer.tokensToSend;  // save claimed tokens
        backer.claimed = true;
        totalClaimed += backer.tokensToSend;
        
        if (!token.transfer(_backer, backer.tokensToSend)) 
            revert(); // send claimed tokens to contributor account

        TokensClaimed(_backer, backer.tokensToSend);  
    }


    // @notice This function will finalize the sale.
    // It will only execute if predetermined sale time passed or all tokens are sold.
    // it will fail if minimum cap is not reached
    function finalize() external onlyOwner() {

        require(!crowdsaleClosed);        
        // purchasing precise number of tokens might be impractical, thus subtract 1000 tokens so finalizition is possible
        // near the end 
        require(block.number >= endBlock || totalTokensSent >= maxCap.sub(1000));                 
        require(totalTokensSent >= minCap);  // ensure that minimum was reached

        crowdsaleClosed = true;  
        
        if (!token.transfer(team, teamTokens)) // transfer all remaing tokens to team address
            revert();

        if (!token.burn(this, maxCap - totalTokensSent)) // burn all unsold tokens
            revert();  
        token.unlock();                      
    }

    // @notice Failsafe drain
    function drain() external onlyOwner() {
        multisig.transfer(this.balance);               
    }

    // @notice Failsafe token transfer
    function tokenDrian() external onlyOwner() {
        if (block.number > endBlock) {
            if (!token.transfer(team, token.balanceOf(this))) 
                revert();
        }
    }
    
    // @notice it will allow contributors to get refund in case campaign failed
    function refund() external stopInEmergency returns (bool) {

        require(currentStep == Step.Refunding);         
       
        require(this.balance > 0);  // contract will hold 0 ether at the end of campaign.                                  
                                    // contract needs to be funded through fundContract() 

        Backer storage backer = backers[msg.sender];

        require(backer.weiReceived > 0);  // esnure that user has sent contribution
        require(!backer.refunded);         // ensure that user hasn&#39;t been refunded yet
        require(!backer.claimed);       // if tokens claimed, don&#39;t allow refunding   
       
        backer.refunded = true;  // save refund status to true
    
        refundCount++;
        totalRefunded = totalRefunded.add(backer.weiReceived);
        msg.sender.transfer(backer.weiReceived);  // send back the contribution 
        RefundETH(msg.sender, backer.weiReceived);
        return true;
    }
}


contract ERC20 {
    uint public totalSupply;
   
    function transfer(address to, uint value) public returns(bool ok);  
}


// The token
contract Token is ERC20, Ownable {

    function returnTokens(address _member, uint256 _value) public returns(bool);
    function unlock() public;
    function balanceOf(address _owner) public view returns(uint balance);
    function burn( address _member, uint256 _value) public returns(bool);
}