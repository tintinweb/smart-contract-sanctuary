/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.4.24;

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
    constructor() public {
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
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract BasicERC20
{
    /* Public variables of the token */
    string public standard = &#39;ERC20&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    bool public isTokenTransferable = true;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        assert(isTokenTransferable);
        assert(balanceOf[msg.sender] >= _value);             // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
    returns (bool success)  {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        assert(isTokenTransferable || _from == address(0x0)); // allow to transfer for crowdsale
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}








/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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



contract BasicCrowdsale is Ownable
{
    using SafeMath for uint256;
    BasicERC20 token;

    address public ownerWallet;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalEtherRaised = 0;
    uint256 public totalTokensSold = 0;

    uint256 public softCapEther;
    uint256 public hardCapEther;

    mapping(address => uint256) private deposits;
    mapping(address => uint256) public amounts;

    constructor () public {

    }

    function () external payable {
        buy(msg.sender);
    }

    function getSettings () view public returns(uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _totalEtherRaised,
        uint256 _maxAmount,
        uint256 _tokensLeft ) {

        _startTime = startTime;
        _endTime = endTime;
        _rate = getRate();
        _totalEtherRaised = totalEtherRaised;
        _maxAmount = getMaxAmount();
        _tokensLeft = tokensLeft();
    }

    function tokensLeft() view public returns (uint256)
    {
        return token.balanceOf(address(0x0));
    }

    function getRate() view public returns (uint256) {
        assert(false);
    }

    function getMinAmount(address userAddress) view public returns (uint256) {
        assert(false);
    }

    function getMaxAmount() view public returns (uint256) {
        assert(false);
    }

    function getTokenAmount(uint256 weiAmount) public view returns(uint256) {
        return weiAmount.mul(getRate());
    }

    function checkCorrectPurchase() view internal {
        require(startTime < now && now < endTime);
        require(totalEtherRaised + msg.value < hardCapEther);
    }

    function isCrowdsaleFinished() view public returns(bool)
    {
        return totalEtherRaised >= hardCapEther || now > endTime;
    }

    function buy(address userAddress) public payable {
        require(userAddress != address(0));
        checkCorrectPurchase();

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(msg.value);

        assert(tokens >= getMinAmount(userAddress));
        assert(tokens.add(totalTokensSold) <= getMaxAmount());

        // update state
        totalEtherRaised = totalEtherRaised.add(msg.value);
        totalTokensSold = totalTokensSold.add(tokens);

        token.transferFrom(address(0x0), userAddress, tokens);
        amounts[userAddress] = amounts[userAddress].add(tokens);

        if (totalEtherRaised >= softCapEther)
        {
            ownerWallet.transfer(this.balance);
        }
        else
        {
            deposits[userAddress] = deposits[userAddress].add(msg.value);
        }
    }

    function getRefundAmount(address userAddress) view public returns (uint256)
    {
        if (totalEtherRaised >= softCapEther) return 0;
        return deposits[userAddress];
    }

    function refund(address userAddress) public
    {
        assert(totalEtherRaised < softCapEther && now > endTime);
        uint256 amount = deposits[userAddress];
        deposits[userAddress] = 0;
        amounts[userAddress] = 0;
        userAddress.transfer(amount);
    }
}



contract Crowdsale is BasicCrowdsale
{
    constructor () public {
        ownerWallet = 0xb02ea41cf7e8c47d5958defda88e46b9786e12ae;
        startTime = 1564617600;
        endTime = 1609459199;
        token = BasicERC20(0x2a629aac0a49c7f51f23a6ff92deecf27b554aa0);
        softCapEther = 1000000000000000000;
        hardCapEther = 125000000000000000000000000;

        transferOwnership(0xb02ea41cf7e8c47d5958defda88e46b9786e12ae);
    }

    function getRate() view public returns (uint256) {
        // you can convert unix timestamp to human date here https://www.epochconverter.com
        // 2019-08-01T00:00:00
        if (block.timestamp <= 1567296000) return 9;
        // 2019-10-30T00:00:00
        if (block.timestamp <= 1575158400) return 7;
        return 5;

    }

    function getMinAmount(address userAddress) view public returns (uint256) {
        // you can convert unix timestamp to human date here https://www.epochconverter.com
        // 2019-08-01T00:00:00
        if (block.timestamp <= 1567296000){
            if(amounts[userAddress] < 10000000000000000000000){
                return uint256(10000000000000000000000).sub(amounts[userAddress]);
            }
            else{
                return 1000000000000000000;
            }
        }
        // 2019-10-30T00:00:00
        if (block.timestamp <= 1575158400){
            if(amounts[userAddress] < 10000000000000000000000){
                return uint256(10000000000000000000000).sub(amounts[userAddress]);
            }
            else{
                return 1000000000000000000;
            }
        }
        return 1;
    }

    function getMaxAmount() view public returns (uint256) {
        // you can convert unix timestamp to human date here https://www.epochconverter.com
        // 2019-08-01T00:00:00
        if (block.timestamp <= 1567296000) return 100000000000000000000000000;
        // 2019-10-30T00:00:00
        if (block.timestamp <= 1575158400) return 100000000000000000000000000;
        return 750000000000000000000000000;
    }
}