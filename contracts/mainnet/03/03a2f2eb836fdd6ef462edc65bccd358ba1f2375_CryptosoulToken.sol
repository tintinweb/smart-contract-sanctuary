pragma solidity ^0.4.24;

library SafeMath 
{
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 result = a * b;
        assert(a == 0 || result / a == b);
        return result;
    }
 
    function div(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 result = a / b;
        return result;
    }
 
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a); 
        return a - b; 
    } 
  
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    { 
        uint256 result = a + b; 
        assert(result >= a);
        return result;
    }
 
    function getAllValuesSum(uint256[] values)
        internal
        pure
        returns(uint256)
    {
        uint256 result = 0;
        
        for (uint i = 0; i < values.length; i++){
            result = add(result, values[i]);
        }
        return result;
    }
}

contract Ownable {
    constructor() public {
        ownerAddress = msg.sender;
    }

    event TransferOwnership(
        address indexed previousOwner,
        address indexed newOwner
    );

    address public ownerAddress;
    //wallet that can change owner
    address internal masterKey = 0x819466D9C043DBb7aB4E1168aB8E014c3dCAA470;
   
    function transferOwnership(address newOwner) 
        public 
        returns(bool);
    
   
    modifier onlyOwner() {
        require(msg.sender == ownerAddress);
        _;
    }
    // Prevents user to send transaction on his own address
    modifier notSender(address owner){
        require(msg.sender != owner);
        _;
    }
}

contract ERC20Basic
{
    event Transfer(
        address indexed from, 
        address indexed to,
        uint256 value
    );
    
    uint256 public totalSupply;
    
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}

contract BasicToken is ERC20Basic, Ownable {
    using SafeMath for uint256;

    struct WalletData {
        uint256 tokensAmount;
        uint256 freezedAmount;
        bool canFreezeTokens;
    }
   
    mapping(address => WalletData) wallets;

    function transfer(address to, uint256 value)
        public
        notSender(to)
        returns(bool)
    {    
        require(to != address(0) 
        && wallets[msg.sender].tokensAmount >= value 
        && (wallets[msg.sender].canFreezeTokens && checkIfCanUseTokens(msg.sender, value)));

        uint256 amount = wallets[msg.sender].tokensAmount.sub(value);
        wallets[msg.sender].tokensAmount = amount;
        wallets[to].tokensAmount = wallets[to].tokensAmount.add(value);
        
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner)
        public
        view
        returns(uint256 balance)
    {
        return wallets[owner].tokensAmount;
    }
    // Check wallet on unfreeze tokens amount
    function checkIfCanUseTokens(
        address owner,
        uint256 amount
    ) 
        internal
        view
        returns(bool) 
    {
        uint256 unfreezedAmount = wallets[owner].tokensAmount - wallets[owner].freezedAmount;
        return amount <= unfreezedAmount;
    }
}

contract FreezableToken is BasicToken {
    event AllowFreeze(address indexed who);
    event DissallowFreeze(address indexed who);
    event FreezeTokens(address indexed who, uint256 freezeAmount);
    event UnfreezeTokens(address indexed who, uint256 unfreezeAmount);
        
    uint256 public freezeTokensAmount = 0;
    
    // Give permission to a wallet for freeze tokens.
    function allowFreezing(address owner)
        public
        onlyOwner
        returns(bool)
    {
        require(!wallets[owner].canFreezeTokens);
        wallets[owner].canFreezeTokens = true;
        emit AllowFreeze(owner);
        return true;
    }
    
    function dissalowFreezing(address owner)
        public
        onlyOwner
        returns(bool)
    {
        require(wallets[owner].canFreezeTokens);
        wallets[owner].canFreezeTokens = false;
        wallets[owner].freezedAmount = 0;
        
        emit DissallowFreeze(owner);
        return true;
    }
    
    function freezeAllowance(address owner)
        public
        view
        returns(bool)
    {
        return wallets[owner].canFreezeTokens;   
    }
    // Freeze tokens on sender wallet if have permission.
    function freezeTokens(
        uint256 amount
    )
        public
        isFreezeAllowed
        returns(bool)
    {
        uint256 freezedAmount = wallets[msg.sender].freezedAmount.add(amount);
        require(wallets[msg.sender].tokensAmount >= freezedAmount);
        wallets[msg.sender].freezedAmount = freezedAmount;
        emit FreezeTokens(msg.sender, amount);
        return true;
    }
    
    function showFreezedTokensAmount(address owner)
    public
    view
    returns(uint256)
    {
        return wallets[owner].freezedAmount;
    }
    
    function unfreezeTokens(
        uint256 amount
    ) 
        public
        isFreezeAllowed
        returns(bool)
    {
        uint256 freezeAmount = wallets[msg.sender].freezedAmount.sub(amount);
        wallets[msg.sender].freezedAmount = freezeAmount;
        emit UnfreezeTokens(msg.sender, amount);
        return true;
    }
    
    function getUnfreezedTokens(address owner)
    internal
    view
    returns(uint256)
    {
        return wallets[owner].tokensAmount - wallets[owner].freezedAmount;
    }
    
    modifier isFreezeAllowed() {
        require(freezeAllowance(msg.sender));
        _;
    }
}

contract MultisendableToken is FreezableToken
{
    using SafeMath for uint256;

    function massTransfer(
        address[] addresses,
        uint[] values
    ) 
        public
        onlyOwner
        returns(bool) 
    {
        for (uint i = 0; i < addresses.length; i++){
            transferFromOwner(addresses[i], values[i]);
        }
        return true;
    }

    function transferFromOwner(
        address to,
        uint256 value
    )
        internal
        onlyOwner
    {
        require(to != address(0)
        && wallets[ownerAddress].tokensAmount >= value
        && (freezeAllowance(ownerAddress) && checkIfCanUseTokens(ownerAddress, value)));
        
        uint256 freezeAmount = wallets[ownerAddress].tokensAmount.sub(value);
        wallets[ownerAddress].tokensAmount = freezeAmount;
        wallets[to].tokensAmount = wallets[to].tokensAmount.add(value);
        
        emit Transfer(ownerAddress, to, value);
    }
}
    
contract Airdropper is MultisendableToken
{
    using SafeMath for uint256[];
    
    event Airdrop(uint256 tokensDropped, uint256 airdropCount);
    event AirdropFinished();
    
    uint256 public airdropsCount = 0;
    uint256 public airdropTotalSupply = 0;
    uint256 public distributedTokensAmount = 0;
    bool public airdropFinished = false;
    
    function airdropToken(
        address[] addresses,
        uint256[] values
    ) 
        public
        onlyOwner
        returns(bool) 
    {
        uint256 result = distributedTokensAmount + values.getAllValuesSum();
        require(!airdropFinished && result <= airdropTotalSupply);
        
        distributedTokensAmount = result;
        airdropsCount++;
        
        emit Airdrop(values.getAllValuesSum(), airdropsCount);
        return massTransfer(addresses, values);
    }
    
    function finishAirdrops() public onlyOwner {
        // Can&#39;t finish airdrop before send all tokens for airdrop.
        require(distributedTokensAmount == airdropTotalSupply);
        airdropFinished = true;
        emit AirdropFinished();
    }
}

contract CryptosoulToken is Airdropper {
    event Mint(address indexed to, uint256 value);
    event AllowMinting();
    event Burn(address indexed from, uint256 value);
    
    string constant public name = "CryptoSoul";
    string constant public symbol = "SOUL";
    uint constant public decimals = 6;
    
    uint256 constant public START_TOKENS = 500000000 * 10**decimals; //500M start
    uint256 constant public MINT_AMOUNT = 1360000 * 10**decimals;
    uint32 constant public MINT_INTERVAL_SEC = 1 days; // 24 hours
    uint256 constant private MAX_BALANCE_VALUE = 2**256 - 1;
    uint constant public startMintingData = 1538352000;
    
    uint public nextMintPossibleTime = 0;
    bool public canMint = false;
    
    constructor() public {
        wallets[ownerAddress].tokensAmount = START_TOKENS;
        wallets[ownerAddress].canFreezeTokens = true;
        totalSupply = START_TOKENS;
        airdropTotalSupply = 200000000 * 10**decimals;
        emit Mint(ownerAddress, START_TOKENS);
    }

    function allowMinting()
    public
    onlyOwner
    {
        // Can start minting token after 01.10.2018
        require(now >= startMintingData);
        nextMintPossibleTime = now;
        canMint = true;
        emit AllowMinting();
    }

    function mint()
        public
        onlyOwner
        returns(bool)
    {
        require(canMint &&
        totalSupply + MINT_AMOUNT <= MAX_BALANCE_VALUE
        && now >= nextMintPossibleTime);
        nextMintPossibleTime = nextMintPossibleTime.add(MINT_INTERVAL_SEC);
        uint256 freezeAmount = wallets[ownerAddress].tokensAmount.add(MINT_AMOUNT);
        wallets[ownerAddress].tokensAmount = freezeAmount;
        totalSupply = totalSupply.add(MINT_AMOUNT);
        
        emit Mint(ownerAddress, MINT_AMOUNT);
        return true;
    }

    function burn(uint256 value)
        public
        onlyOwner
        returns(bool)
    {
        require(checkIfCanUseTokens(ownerAddress, value)
        && wallets[ownerAddress].tokensAmount >= value);
        
        uint256 freezeAmount = wallets[ownerAddress].tokensAmount.sub(value);
        wallets[ownerAddress].tokensAmount = freezeAmount;
        totalSupply = totalSupply.sub(value);                             
        
        emit Burn(ownerAddress, value);
        return true;
    }
    
    function transferOwnership(address newOwner) 
        public
        returns(bool)
    {
        require(msg.sender == masterKey && newOwner != address(0));
        // Transfer token data from old owner to new.
        wallets[newOwner].tokensAmount = wallets[ownerAddress].tokensAmount;
        wallets[newOwner].canFreezeTokens = true;
        wallets[newOwner].freezedAmount = wallets[ownerAddress].freezedAmount;
        wallets[ownerAddress].freezedAmount = 0;
        wallets[ownerAddress].tokensAmount = 0;
        wallets[ownerAddress].canFreezeTokens = false;
        emit TransferOwnership(ownerAddress, newOwner);
        ownerAddress = newOwner;
        return true;
    }
    
    function()
        public
        payable
    {
        revert();
    }
}