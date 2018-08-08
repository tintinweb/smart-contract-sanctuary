pragma solidity ^ 0.4.18;


library SafeMath {
    function mul(uint a, uint b) internal pure  returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal pure  returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure  returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
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

// @notice  Whitelist interface which will hold whitelisted users
contract WhiteList is Ownable {

    function isWhiteListed(address _user) external view returns (bool);        
}

// Crowdsale Smart Contract
// This smart contract collects ETH and in return sends tokens to contributors
contract Crowdsale is Pausable {

    using SafeMath for uint;

    struct Backer {
        uint weiReceived; // amount of ETH contributed
        uint tokensToSend; // amount of tokens  sent      
        bool refunded;
    }

    Token public token; // Token contract reference   
    address public multisig; // Multisig contract that will receive the ETH    
    address public team; // Address at which the team tokens will be sent        
    uint public ethReceivedPresale; // Number of ETH received in presale
    uint public ethReceivedMain; // Number of ETH received in public sale
    uint public tokensSentPresale; // Tokens sent during presale
    uint public tokensSentMain; // Tokens sent during public ICO   
    uint public totalTokensSent; // Total number of tokens sent to contributors
    uint public startBlock; // Crowdsale start block
    uint public endBlock; // Crowdsale end block
    uint public maxCap; // Maximum number of tokens to sell    
    uint public minInvestETH; // Minimum amount to invest   
    bool public crowdsaleClosed; // Is crowdsale still in progress
    Step public currentStep;  // To allow for controlled steps of the campaign 
    uint public refundCount;  // Number of refunds
    uint public totalRefunded; // Total amount of Eth refunded          
    uint public dollarToEtherRatio; // how many dollars are in one eth. Amount uses two decimal values. e.g. $333.44/ETH would be passed as 33344 
    uint public numOfBlocksInMinute; // number of blocks in one minute * 100. eg. 
    WhiteList public whiteList;     // whitelist contract

    mapping(address => Backer) public backers; // contributors list
    address[] public backersIndex; // to be able to iterate through backers for verification.              
    uint public priorTokensSent; 
    uint public presaleCap;
   

    // @notice to verify if action is not performed out of the campaign range
    modifier respectTimeFrame() {
        require(block.number >= startBlock && block.number <= endBlock);
        _;
    }

    // @notice to set and determine steps of crowdsale
    enum Step {      
        FundingPreSale,     // presale mode
        FundingPublicSale,  // public mode
        Refunding  // in case campaign failed during this step contributors will be able to receive refunds
    }

    // Events
    event ReceivedETH(address indexed backer, uint amount, uint tokenAmount);
    event RefundETH(address indexed backer, uint amount);

    // Crowdsale  {constructor}
    // @notice fired when contract is crated. Initializes all constant and initial values.
    // @param _dollarToEtherRatio {uint} how many dollars are in one eth.  $333.44/ETH would be passed as 33344
    function Crowdsale(WhiteList _whiteList) public {               
        multisig = 0x10f78f2a70B52e6c3b490113c72Ba9A90ff1b5CA; 
        team = 0x10f78f2a70B52e6c3b490113c72Ba9A90ff1b5CA; 
        maxCap = 1510000000e8;             
        minInvestETH = 1 ether/2;    
        currentStep = Step.FundingPreSale;
        dollarToEtherRatio = 56413;       
        numOfBlocksInMinute = 408;          // E.g. 4.38 block/per minute wold be entered as 438                  
        priorTokensSent = 4365098999e7;     //tokens distributed in private sale and airdrops
        whiteList = _whiteList;             // white list address
        presaleCap = 107000000e8;           // max for sell in presale

    }

    // @notice to populate website with status of the sale and minimize amout of calls for each variable
    function returnWebsiteData() external view returns(uint, uint, uint, uint, uint, uint, Step, bool, bool) {            
    
        return (startBlock, endBlock, backersIndex.length, ethReceivedPresale + ethReceivedMain, maxCap, totalTokensSent, currentStep, paused, crowdsaleClosed);
    }

    // @notice Specify address of token contract
    // @param _tokenAddress {address} address of token contract
    // @return res {bool}
    function setTokenAddress(Token _tokenAddress) external onlyOwner() returns(bool res) {
        require(token == address(0));
        token = _tokenAddress;
        return true;
    }

    // @notice set the step of the campaign from presale to public sale
    // contract is deployed in presale mode
    // WARNING: there is no way to go back
    function advanceStep() public onlyOwner() {

        currentStep = Step.FundingPublicSale;                                             
        minInvestETH = 1 ether/4;                                     
    }

    // @notice in case refunds are needed, money can be returned to the contract
    // and contract switched to mode refunding
    function prepareRefund() public payable onlyOwner() {
        
        require(msg.value == ethReceivedPresale.add(ethReceivedMain)); // make sure that proper amount of ether is sent
        currentStep = Step.Refunding;
    }

    // @notice return number of contributors
    // @return  {uint} number of contributors   
    function numberOfBackers() public view returns(uint) {
        return backersIndex.length;
    }

    // {fallback function}
    // @notice It will call internal function which handles allocation of Ether and calculates tokens.
    // Contributor will be instructed to specify sufficient amount of gas. e.g. 250,000 
    function () external payable {           
        contribute(msg.sender);
    }

    // @notice It will be called by owner to start the sale    
    function start(uint _block) external onlyOwner() {   

        require(_block <= (numOfBlocksInMinute * 60 * 24 * 55)/100);  // allow max 55 days for campaign 323136
        startBlock = block.number;
        endBlock = startBlock.add(_block); 
    }

    // @notice Due to changing average of block time
    // this function will allow on adjusting duration of campaign closer to the end 
    function adjustDuration(uint _block) external onlyOwner() {

        require(_block < (numOfBlocksInMinute * 60 * 24 * 60)/100); // allow for max of 60 days for campaign
        require(_block > block.number.sub(startBlock)); // ensure that endBlock is not set in the past
        endBlock = startBlock.add(_block); 
    }   

    // @notice due to Ether to Dollar flacutation this value will be adjusted during the campaign
    // @param _dollarToEtherRatio {uint} new value of dollar to ether ratio
    function adjustDollarToEtherRatio(uint _dollarToEtherRatio) external onlyOwner() {
        require(_dollarToEtherRatio > 0);
        dollarToEtherRatio = _dollarToEtherRatio;
    }

    // @notice It will be called by fallback function whenever ether is sent to it
    // @param  _backer {address} address of contributor
    // @return res {bool} true if transaction was successful
    function contribute(address _backer) internal whenNotPaused() respectTimeFrame() returns(bool res) {

        require(whiteList.isWhiteListed(_backer));      // ensure that user is whitelisted

        uint tokensToSend = determinePurchase();
            
        Backer storage backer = backers[_backer];

        if (backer.weiReceived == 0)
            backersIndex.push(_backer);
       
        backer.tokensToSend += tokensToSend; // save contributor&#39;s total tokens sent
        backer.weiReceived = backer.weiReceived.add(msg.value);  // save contributor&#39;s total ether contributed

        if (Step.FundingPublicSale == currentStep) { // Update the total Ether received and tokens sent during public sale
            ethReceivedMain = ethReceivedMain.add(msg.value);
            tokensSentMain += tokensToSend;
        }else {                                                 // Update the total Ether recived and tokens sent during presale
            ethReceivedPresale = ethReceivedPresale.add(msg.value); 
            tokensSentPresale += tokensToSend;
        }
                                                     
        totalTokensSent += tokensToSend;     // update the total amount of tokens sent        
        multisig.transfer(this.balance);   // transfer funds to multisignature wallet    

        if (!token.transfer(_backer, tokensToSend)) 
            revert(); // Transfer tokens             

        ReceivedETH(_backer, msg.value, tokensToSend); // Register event
        return true;
    }

    // @notice determine if purchase is valid and return proper number of tokens
    // @return tokensToSend {uint} proper number of tokens based on the timline
    function determinePurchase() internal view  returns (uint) {

        require(msg.value >= minInvestETH);   // ensure that min contributions amount is met  
        uint tokenAmount = dollarToEtherRatio.mul(msg.value)/4e10;  // price of token is $0.01 and there are 8 decimals for the token
        
        uint tokensToSend;
          
        if (Step.FundingPublicSale == currentStep) {  // calculate price of token in public sale
            tokensToSend = tokenAmount;
            require(totalTokensSent + tokensToSend + priorTokensSent <= maxCap); // Ensure that max cap hasn&#39;t been reached  
        }else {
            tokensToSend = tokenAmount + (tokenAmount * 50) / 100; 
            require(totalTokensSent + tokensToSend <= presaleCap); // Ensure that max cap hasn&#39;t been reached for presale            
        }                                                        
       
        return tokensToSend;
    }

    
    // @notice This function will finalize the sale.
    // It will only execute if predetermined sale time passed or all tokens are sold.
    // it will fail if minimum cap is not reached
    function finalize() external onlyOwner() {

        require(!crowdsaleClosed);        
        // purchasing precise number of tokens might be impractical, thus subtract 1000 
        // tokens so finalization is possible near the end 
        require(block.number >= endBlock || totalTokensSent + priorTokensSent >= maxCap - 1000);                        
        crowdsaleClosed = true; 
        
        if (!token.transfer(team, token.balanceOf(this))) // transfer all remaining tokens to team address
            revert();        
        token.unlock();                      
    }

    // @notice Fail-safe drain
    function drain() external onlyOwner() {
        multisig.transfer(this.balance);               
    }

    // @notice Fail-safe token transfer
    function tokenDrain() external onlyOwner() {
        if (block.number > endBlock) {
            if (!token.transfer(multisig, token.balanceOf(this))) 
                revert();
        }
    }
    
    // @notice it will allow contributors to get refund in case campaign failed
    // @return {bool} true if successful
    function refund() external whenNotPaused() returns (bool) {

        require(currentStep == Step.Refunding);                        

        Backer storage backer = backers[msg.sender];

        require(backer.weiReceived > 0);  // ensure that user has sent contribution
        require(!backer.refunded);        // ensure that user hasn&#39;t been refunded yet

        backer.refunded = true;  // save refund status to true
        refundCount++;
        totalRefunded = totalRefunded + backer.weiReceived;

        if (!token.transfer(msg.sender, backer.tokensToSend)) // return allocated tokens
            revert();                            
        msg.sender.transfer(backer.weiReceived);  // send back the contribution 
        RefundETH(msg.sender, backer.weiReceived);
        return true;
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

// The token
contract Token is ERC20, Ownable {
   
    function unlock() public;

}