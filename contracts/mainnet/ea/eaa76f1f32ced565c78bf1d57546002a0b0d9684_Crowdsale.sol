pragma solidity 0.4.21;


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
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owner = msg.sender;
        newOwner = address(0);
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
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
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
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
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
    uint public numOfBlocksInMinute; // number of blocks in one minute * 100. eg.
    WhiteList public whiteList;     // whitelist contract
    uint public tokenPriceWei;      // Price of token in wei

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

        require(_whiteList != address(0));
        multisig = 0x10f78f2a70B52e6c3b490113c72Ba9A90ff1b5CA;
        team = 0x10f78f2a70B52e6c3b490113c72Ba9A90ff1b5CA;
        maxCap = 1510000000e8;
        minInvestETH = 1 ether/2;
        currentStep = Step.FundingPreSale;
        numOfBlocksInMinute = 408;          // E.g. 4.38 block/per minute wold be entered as 438
        priorTokensSent = 4365098999e7;     //tokens distributed in private sale and airdrops
        whiteList = _whiteList;             // white list address
        presaleCap = 160000000e8;           // max for sell in presale
        tokenPriceWei = 57142857142857;     // 17500 tokens per ether
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
        require(Step.FundingPreSale == currentStep);
        currentStep = Step.FundingPublicSale;
        minInvestETH = 1 ether/4;
    }

    // @notice in case refunds are needed, money can be returned to the contract
    // and contract switched to mode refunding
    function prepareRefund() public payable onlyOwner() {

        require(crowdsaleClosed);
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

        require(startBlock == 0);
        require(_block <= (numOfBlocksInMinute * 60 * 24 * 54)/100);  // allow max 54 days for campaign
        startBlock = block.number;
        endBlock = startBlock.add(_block);
    }

    // @notice Due to changing average of block time
    // this function will allow on adjusting duration of campaign closer to the end
    function adjustDuration(uint _block) external onlyOwner() {

        require(startBlock > 0);
        require(_block < (numOfBlocksInMinute * 60 * 24 * 60)/100); // allow for max of 60 days for campaign
        require(_block > block.number.sub(startBlock)); // ensure that endBlock is not set in the past
        endBlock = startBlock.add(_block);
    }

    // @notice It will be called by fallback function whenever ether is sent to it
    // @param  _backer {address} address of contributor
    // @return res {bool} true if transaction was successful
    function contribute(address _backer) internal whenNotPaused() respectTimeFrame() returns(bool res) {
        require(!crowdsaleClosed);
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
        multisig.transfer(address(this).balance);   // transfer funds to multisignature wallet

        require(token.transfer(_backer, tokensToSend));   // Transfer tokens

        emit ReceivedETH(_backer, msg.value, tokensToSend); // Register event
        return true;
    }

    // @notice determine if purchase is valid and return proper number of tokens
    // @return tokensToSend {uint} proper number of tokens based on the timline
    function determinePurchase() internal view  returns (uint) {

        require(msg.value >= minInvestETH);   // ensure that min contributions amount is met

        uint tokensToSend = msg.value.mul(1e8) / tokenPriceWei;   //1e8 ensures that token gets 8 decimal values

        if (Step.FundingPublicSale == currentStep) {  // calculate price of token in public sale
            require(totalTokensSent + tokensToSend + priorTokensSent <= maxCap); // Ensure that max cap hasn&#39;t been reached
        }else {
            tokensToSend += (tokensToSend * 50) / 100;
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

        require(token.transfer(team, token.balanceOf(this))); // transfer all remaining tokens to team address
        token.unlock();
    }

    // @notice Fail-safe drain
    function drain() external onlyOwner() {
        multisig.transfer(address(this).balance);
    }

    // @notice Fail-safe token transfer
    function tokenDrain() external onlyOwner() {
        if (block.number > endBlock) {
            require(token.transfer(multisig, token.balanceOf(this)));
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

        require(token.transfer(msg.sender, backer.tokensToSend)); // return allocated tokens
        msg.sender.transfer(backer.weiReceived);  // send back the contribution
        emit RefundETH(msg.sender, backer.weiReceived);
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

    using SafeMath for uint;

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals; // How many decimals to show.
    string public version = "v0.1";
    uint public totalSupply;
    bool public locked;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public crowdSaleAddress;


    // Lock transfer for contributors during the ICO
    modifier onlyUnlocked() {
        if (msg.sender != crowdSaleAddress && msg.sender != owner && locked)
            revert();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != owner && msg.sender != crowdSaleAddress)
            revert();
        _;
    }

    // @notice The Token contract
    function Token(address _crowdsaleAddress) public {

        require(_crowdsaleAddress != address(0));
        locked = true; // Lock the transfer of tokens during the crowdsale
        totalSupply = 2600000000e8;
        name = "Kripton";                           // Set the name for display purposes
        symbol = "LPK";                             // Set the symbol for display purposes
        decimals = 8;                               // Amount of decimals
        crowdSaleAddress = _crowdsaleAddress;
        balances[_crowdsaleAddress] = totalSupply;
    }

    // @notice unlock token for trading
    function unlock() public onlyAuthorized {
        locked = false;
    }

    // @lock token from trading during ICO
    function lock() public onlyAuthorized {
        locked = true;
    }

    // @notice transfer tokens to given address
    // @param _to {address} address or recipient
    // @param _value {uint} amount to transfer
    // @return  {bool} true if successful
    function transfer(address _to, uint _value) public onlyUnlocked returns(bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // @notice transfer tokens from given address to another address
    // @param _from {address} from whom tokens are transferred
    // @param _to {address} to whom tokens are transferred
    // @parm _value {uint} amount of tokens to transfer
    // @return  {bool} true if successful
    function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked returns(bool success) {
        require(balances[_from] >= _value); // Check if the sender has enough
        require(_value <= allowed[_from][msg.sender]); // Check if allowed is greater or equal
        balances[_from] = balances[_from].sub(_value); // Subtract from the sender
        balances[_to] = balances[_to].add(_value); // Add the same to the recipient
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
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
        emit Approval(msg.sender, _spender, _value);
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
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
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
    function removeFromWhiteList(address _user) external onlyOwner() {

        require(whiteList[_user] == true);
        whiteList[_user] = false;
        totalWhiteListed--;
        emit LogRemoveWhiteListed(_user);
    }

    // @notice it will white list one member
    // @param _user {address} of user to whitelist
    // @return true if successful
    function addToWhiteList(address _user) external onlyOwner() {

        if (whiteList[_user] != true) {
            whiteList[_user] = true;
            totalWhiteListed++;
            emit LogWhiteListed(_user, totalWhiteListed);
        }else

            revert();
    }

    // @notice it will white list multiple members
    // @param _user {address[]} of users to whitelist
    // @return true if successful
    function addToWhiteListMultiple(address[] _users) external onlyOwner() {

        for (uint i = 0; i < _users.length; ++i) {

            if (whiteList[_users[i]] != true) {
                whiteList[_users[i]] = true;
                totalWhiteListed++;
            }
        }
        emit LogWhiteListedMultiple(totalWhiteListed);
    }
}