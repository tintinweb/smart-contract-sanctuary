pragma solidity ^0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface tokenReward {
    function mint(address receiver, uint amount) external;
    function transferOwnership(address newOwner) external;
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a CRDT owner
 * as they arrive.
 * Initial ICO coin supply = 155 million tokens
 * 90 million will go to the crowdsale
 * 20 million for Pre ICO-investors (with a discount on token price)
 * 15 million for Owners
 * 10 million for FREE Token giveaway for CryptoDaily readers.
 * 5 million for Team, Advisors
 * 5 million Early ICO Signup Bonuses
 * 10 million reserves for Exchange financing
 */
contract Crowdsale {
    using SafeMath for uint;
    
    uint private million = 1000000;
    uint private decimals = 18;

    /**
     * @notice Crowdsale contract is token contract owner
     * @dev Crowdsale contract is deploying token contract
     */
    tokenReward private token;
    
    address private owner;
    address private constant fundsWallet = 0x6623b60E0Eb77DaFc1C0886CCB301A3f3947Fb15;//0x05e21637a43A8a1b2DEB75df7aCe5e10A09b8Ff8;
    address private constant tokenWallet = 0x6623b60E0Eb77DaFc1C0886CCB301A3f3947Fb15;//0xaE29a74F44d930510a9eAAf125C4B38553524a17; 
    
    uint private start;
    uint private finish;
    
    bool private reserveminted = false;
    bool private icoended = false;

    uint private tokensPerEth;
    
    uint private tokensReserved = 65 * million * 10 ** uint256(decimals);
    uint private tokensCrowdsaled = 0;
    uint private tokensLeft = 90 * million * 10 ** uint256(decimals);
    uint private tokensTotal = 155 * million * 10 ** uint256(decimals);
    
    event Mint(address indexed to, uint value);
    event SaleFinished(address target, uint amountRaised);
    
    /**
     * @dev Contract constructor
     * @param addressOfTokenUsedAsReward Address of token used as reward
     * @param UnixTimestampOfICOStart Unix timestamp value when crowdsale starts
     * @param UnixTimestampOfICOEnd Unix timestamp value when crowdsale ends
     * @param _tokensPerEth the number of tokens that a contributor receives for each ETH
     */
    constructor(
        address addressOfTokenUsedAsReward,
        uint UnixTimestampOfICOStart, 
        uint UnixTimestampOfICOEnd, 
        uint _tokensPerEth
    ) public {
        owner = msg.sender;
        token = tokenReward(addressOfTokenUsedAsReward);
        start = UnixTimestampOfICOStart;
        finish = UnixTimestampOfICOEnd;
        tokensPerEth = _tokensPerEth;
    }
    

    /**
     * @dev Throws if called by any account other than the owner.
     * 
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /**
     * @dev Throws if its not crowdsale period.
     * 
     */
    modifier saleIsOn() {
    	require(now >= start && now <= finish && !icoended);
    	_;
    }
    
    /**
     * @dev Throws of hardcap is reached.
     * 
     */    
    modifier isUnderHardCap() { 
        require(getTokensReleased() <= tokensTotal); //is 149 cap? 
        _;
    }
    
    //Getters

    /**
     * @return the address of the token that is used as a reward
     * 
     */
    function getAddressOfTokenUsedAsReward() constant public returns(address){
        return token;
    } 
    
    /**
     * @return number of tokens sold
     * 
     */
    function getTokensCrowdsaled() constant public returns(uint){
        return tokensCrowdsaled;
    }
    
    /**
     * @return number of tokens left
     * 
     */ 
    function getTokensLeft() constant public returns(uint){
        return tokensLeft;
    }
    
    /**
     * @return owner
     * 
     */ 
    function getOwner() constant public returns(address){
        return owner;
    }
    
    /**
     * @return datetime ico start timestamp
     * 
     */
    function getStart() constant public returns(uint){
        return start;
    }
    
    /**
     * @return datetime ico end timestamp
     * 
     */
    function getFinish() constant public returns(uint){
        return finish;
    }
        
    /**
     * @return if crowdsale ended
     * 
     */
    function getIcoEnded() constant public returns(bool){
        return icoended;
    }
    
    /**
     * @return if reserved tokens have been minted
     * 
     */
    function getReserveminted() constant public returns(bool){
        return reserveminted;
    }
    
    /**
     * @return the number of tokens that a contributor receives for each ETH
     * 
     */ 
    function getTokensPerEth() constant public returns(uint){
        return tokensPerEth;
    }
    
    //Setters

    /**
     * @param newStart new Unix timestamp value when crowdsale starts
     * 
     */
    function setStart(uint newStart) onlyOwner public {
        start = newStart; 
    }
    
    /**
     * @param newFinish new Unix timestamp value when crowdsale ends
     * 
     */
    function setFinish(uint newFinish) onlyOwner public {
        finish = newFinish; 
    }
    
    /**
     * @param _tokensPerEth the new number of tokens that a contributor receives for each ETH
     * 
     */
    function setTokensPerEth(uint _tokensPerEth) onlyOwner public {
        tokensPerEth = _tokensPerEth; 
    }
    
    
    //Custom getters and setters 
    
    /**
     * @return total realised tokens
     * 
     */
    function getTokensReleased() constant public returns(uint){
        return tokensReserved + tokensCrowdsaled;
    }
    
    /**
     * @return true if bonus
     * 
     */
    function getIfBonus() constant public returns(bool){
        return (getTokensCrowdsaled() < 50 * million * 10 ** uint256(decimals));
    }
    

    /**
     * @notice Function must be invoked when ICO has been finished. Transfers unsold tokens to the reserve. Throws if tokensLeft = 0
     * @dev onlyOwner modifier 
     * 
     */ 
    function setICOIsFinished() onlyOwner public {
        require(!icoended);
        icoended = true;
        token.mint(tokenWallet, tokensLeft);
        tokensLeft = 0;
        emit SaleFinished(fundsWallet, getTokensReleased());
    }
    
    /**
     * @notice give ownership back to deployer
     * @dev onlyOwner modifier 
     */
    function transferOwnership() onlyOwner public{
        token.transferOwnership(owner);
    }
    
    /**
     * @dev Mint reserved tokens to the owner&#39;s wallet
     * @dev onlyOwner modifier 
     */
    function mintReserve() onlyOwner public  {
        require(!reserveminted);
        reserveminted = true;
        token.mint(tokenWallet, tokensReserved);
    }
    
    /**
     * @notice fallback function 
     * @dev isUnderHardCap, saleIsOn modifiers
     */
    function() isUnderHardCap saleIsOn public payable {
        
        require(msg.sender != 0x0);
        
        //minimal contribution is 3 ETH
        require(msg.value >= 3 ether);
        fundsWallet.transfer(msg.value);
        
        //first 50 miilon tokens with 10% bonus
        uint firstFifty = 50 * million * 10 ** uint256(decimals);
        uint amount = msg.value;
        uint tokensToMint = 0;

        tokensToMint = amount.mul(tokensPerEth);
        
        //add bonus
        if (tokensCrowdsaled.add(tokensToMint) <= firstFifty){
            tokensToMint = tokensToMint.mul(11).div(10); 
        }
        
        token.mint(msg.sender, tokensToMint);
        emit Mint(msg.sender, tokensToMint);
        
        tokensLeft = tokensLeft.sub(tokensToMint);
        tokensCrowdsaled = tokensCrowdsaled.add(tokensToMint);
    }

}