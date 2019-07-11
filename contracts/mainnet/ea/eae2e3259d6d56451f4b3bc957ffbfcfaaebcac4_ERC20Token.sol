/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.4.24;

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














contract BasicCrowdsale is Ownable
{
    using SafeMath for uint256;
    BasicERC20 token;

    address public ownerWallet;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalEtherRaised = 0;
    uint256 public minDepositAmount;
    uint256 public maxDepositAmount;

    uint256 public softCapEther;
    uint256 public hardCapEther;

    mapping(address => uint256) private deposits;

    constructor () public {

    }

    function () external payable {
        buy(msg.sender);
    }

    function getSettings () view public returns(uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _totalEtherRaised,
        uint256 _minDepositAmount,
        uint256 _maxDepositAmount,
        uint256 _tokensLeft ) {

        _startTime = startTime;
        _endTime = endTime;
        _rate = getRate();
        _totalEtherRaised = totalEtherRaised;
        _minDepositAmount = minDepositAmount;
        _maxDepositAmount = maxDepositAmount;
        _tokensLeft = tokensLeft();
    }

    function tokensLeft() view public returns (uint256)
    {
        return token.balanceOf(address(0x0));
    }

    function changeMinDepositAmount (uint256 _minDepositAmount) onlyOwner public {
        minDepositAmount = _minDepositAmount;
    }

    function changeMaxDepositAmount (uint256 _maxDepositAmount) onlyOwner public {
        maxDepositAmount = _maxDepositAmount;
    }

    function getRate() view public returns (uint256) {
        assert(false);
    }

    function getTokenAmount(uint256 weiAmount) public view returns(uint256) {
        return weiAmount.mul(getRate());
    }

    function checkCorrectPurchase() view internal {
        require(startTime < now && now < endTime);
        require(msg.value >= minDepositAmount);
        require(msg.value < maxDepositAmount);
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

        // update state
        totalEtherRaised = totalEtherRaised.add(msg.value);

        token.transferFrom(address(0x0), userAddress, tokens);

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
        userAddress.transfer(amount);
    }
}


contract CrowdsaleCompatible is BasicERC20, Ownable
{
    BasicCrowdsale public crowdsale = BasicCrowdsale(0x0);

    // anyone can unfreeze tokens when crowdsale is finished
    function unfreezeTokens() public
    {
        assert(now > crowdsale.endTime());
        isTokenTransferable = true;
    }

    // change owner to 0x0 to lock this function
    function initializeCrowdsale(address crowdsaleContractAddress, uint256 tokensAmount) onlyOwner public  {
        transfer((address)(0x0), tokensAmount);
        allowance[(address)(0x0)][crowdsaleContractAddress] = tokensAmount;
        crowdsale = BasicCrowdsale(crowdsaleContractAddress);
        isTokenTransferable = false;
        transferOwnership(0x0); // remove an owner
    }
}







contract EditableToken is BasicERC20, Ownable {
    using SafeMath for uint256;

    // change owner to 0x0 to lock this function
    function editTokenProperties(string _name, string _symbol, int256 extraSupplay) onlyOwner public {
        name = _name;
        symbol = _symbol;
        if (extraSupplay > 0)
        {
            balanceOf[owner] = balanceOf[owner].add(uint256(extraSupplay));
            totalSupply = totalSupply.add(uint256(extraSupplay));
            emit Transfer(address(0x0), owner, uint256(extraSupplay));
        }
        else if (extraSupplay < 0)
        {
            balanceOf[owner] = balanceOf[owner].sub(uint256(extraSupplay * -1));
            totalSupply = totalSupply.sub(uint256(extraSupplay * -1));
            emit Transfer(owner, address(0x0), uint256(extraSupplay * -1));
        }
    }
}







contract ThirdPartyTransferableToken is BasicERC20{
    using SafeMath for uint256;

    struct confidenceInfo {
        uint256 nonce;
        mapping (uint256 => bool) operation;
    }
    mapping (address => confidenceInfo) _confidence_transfers;

    function nonceOf(address src) view public returns (uint256) {
        return _confidence_transfers[src].nonce;
    }

    function transferByThirdParty(uint256 nonce, address where, uint256 amount, uint8 v, bytes32 r, bytes32 s) public returns (bool){
        assert(where != address(this));
        assert(where != address(0x0));

        bytes32 hash = sha256(this, nonce, where, amount);
        address src = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s);
        assert(balanceOf[src] >= amount);
        assert(nonce == _confidence_transfers[src].nonce+1);

        assert(_confidence_transfers[src].operation[uint256(hash)]==false);

        balanceOf[src] = balanceOf[src].sub(amount);
        balanceOf[where] = balanceOf[where].add(amount);
        _confidence_transfers[src].nonce += 1;
        _confidence_transfers[src].operation[uint256(hash)] = true;

        emit Transfer(src, where, amount);

        return true;
    }
}



contract ERC20Token is CrowdsaleCompatible, EditableToken, ThirdPartyTransferableToken {
    using SafeMath for uint256;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() public
    {
        balanceOf[0xdffd1e7fb9a88b7ab3316fdf7575c14fdb0c3b3a] = uint256(100000) * 10**18;
        emit Transfer(address(0x0), 0xdffd1e7fb9a88b7ab3316fdf7575c14fdb0c3b3a, balanceOf[0xdffd1e7fb9a88b7ab3316fdf7575c14fdb0c3b3a]);

        transferOwnership(0xdffd1e7fb9a88b7ab3316fdf7575c14fdb0c3b3a);

        totalSupply = 100000 * 10**18;                  // Update total supply
        name = &#39;Bitcoin40&#39;;                                   // Set the name for display purposes
        symbol = &#39;BHT&#39;;                               // Set the symbol for display purposes
        decimals = 18;                                           // Amount of decimals for display purposes
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () public {
        assert(false);     // Prevents accidental sending of ether
    }
}