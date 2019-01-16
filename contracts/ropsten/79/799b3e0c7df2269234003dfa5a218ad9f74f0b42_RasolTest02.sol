// base code by https://github.com/bitfwdcommunity/Issue-your-own-ERC20-token/blob/master/contracts/erc20_tutorial.sol
// created by rasol, Voiceloco
// test version 1

pragma solidity 0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public 
    onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// Token Lock Contract
// ----------------------------------------------------------------------------
contract Lock is Owned{
    
    // global lock status
    bool public isGlobalLocked;
    // address lock status map
    mapping( address => bool) public isAddressLockedMap;

    event AddressLocked(address lockedAddress);
    event AddressUnlocked(address unlockedaddress);
    event GlobalLocked();
    event GlobalUnlocked();

    // Check for global lock status to be unlocked
    modifier checkGlobalLocked {
        require(!isGlobalLocked);
        _;
    }

    // Check for address lock to be unlocked
    modifier checkAddressLocked {
        require(!isAddressLockedMap[msg.sender]);
        _;
    }

    function lockGlobalToken() public
    onlyOwner
    returns (bool)
    {
        isGlobalLocked = true;
        return isGlobalLocked;
        emit GlobalLocked();
    }

    function unlockGlobalToken() public
    onlyOwner
    returns (bool)
    {
        isGlobalLocked = false;
        return isGlobalLocked;
        emit GlobalUnlocked();
    }

    function lockAddressToken(address target) public
    onlyOwner
    returns (bool)
    {
        isAddressLockedMap[target] = true;
        emit AddressLocked(target);
        return isAddressLockedMap[target];
    }

    function unlockAddressToken(address target) public
    onlyOwner
    returns (bool)
    {
        isAddressLockedMap[target] = false;
        emit AddressUnlocked(target);
        return isAddressLockedMap[target];
    }
    
}

contract Reward is Owned{
    struct RewardHistory{
        string caller;
        string callee;
        uint256 tokenAmount;
    }
    
    mapping(address => RewardHistory[]) public rewardHistoryMap;
    address[] public routerArray;
    
    function addRouter(address target) public
    onlyOwner
    returns (bool){
        routerArray.push(target);
        return true;
    }
    
    function getRandomRouter() public
    returns (address){
        uint randNonce = 0;
        uint random = uint(keccak256(now, msg.sender, 0)) % routerArray.length;
        return routerArray[random];
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract RasolTest02 is ERC20Interface, Owned, SafeMath, Lock, Reward {
    string public symbol;
    string public  name;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    mapping(address => uint) balances;
    mapping(address => uint) balances2;

    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint) rewardHistoryLengthArray;
    
    event Burn();



    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        symbol = tokenSymbol;
        name = tokenName;
        totalSupply = initialSupply;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return totalSupply;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public  
    checkGlobalLocked
    checkAddressLocked
    returns (bool success){
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public 
    checkGlobalLocked
    returns (bool success) {
        // check "from" address Lock
        require(!isAddressLockedMap[from]);
        
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
    }
    
    // ------------------------------------------------------------------------
    // burn token
    // ------------------------------------------------------------------------
    function burn(uint256 tokens) public
    onlyOwner
    returns (bool)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        totalSupply = safeSub(totalSupply, tokens);
        emit Burn();
        
        return true;
    }
    
    // ------------------------------------------------------------------------
    // reward random router
    // ------------------------------------------------------------------------
    function callAndReward(string caller, string callee, uint256 amount) public
    returns (bool){
        address targetRouter = getRandomRouter();
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        balances[targetRouter] = safeAdd(balances[targetRouter], amount);
        rewardHistoryMap[targetRouter].push(RewardHistory(caller, callee, amount));
        rewardHistoryLengthArray[targetRouter] = safeAdd(rewardHistoryLengthArray[targetRouter], 1);
        emit Transfer(msg.sender, targetRouter, amount);
        
        return true;
    }
    
    // function test(address target) public constant returns (bytes32[] caller, bytes32[] callee, uint[] amount){
    //     bytes32[] memory callerData = new bytes32[](10);
    //     bytes32[] memory calleeData = new bytes32[](10);
    //     uint[] memory amountData = new uint[](10);
        
    //     for(uint i = rewardHistoryMap[target].length - 1 ; i >= 0 ; i--){
    //         callerData[i] = rewardHistoryMap[target].caller;
    //     }
    // }
    
    function rewardHistoryLengthOf(address target) public constant returns(uint256){
        return rewardHistoryMap[target].length;
    }
    
    function rewardHistoryMapOf(address target, uint256 index) public constant returns(string caller, string callee, uint256 amount){
        return (rewardHistoryMap[target][index].caller, rewardHistoryMap[target][index].callee, rewardHistoryMap[target][index].tokenAmount);
    }
    
    function getAllRouter() public constant returns(address[]){
        return routerArray;
    }
    
    // function test(adress target) public constant returns(bytes32[] caller, bytes32[] callee, uint256[] amount){
        
    // }
    
    function getRewardHistory(address target) public constant returns (bytes32[] caller, bytes32[] callee, uint256[] amount){
        bytes32[] memory callerData = new bytes32[](10);
        bytes32[] memory calleeData = new bytes32[](10);
        uint[] memory amountData = new uint[](10);
        
        uint j = 0;
        for(uint i = rewardHistoryMap[target].length - 1 ; i >= 0 ; i--){
            callerData[j] = stringToBytes32(rewardHistoryMap[target][i].caller);
            calleeData[j] = stringToBytes32(rewardHistoryMap[target][i].callee);
            amountData[j] = rewardHistoryMap[target][i].tokenAmount;
            j++;
            if(i==0){
                break;
            }
        }
        
        return (callerData, calleeData, amountData);
    }
    
    function stringToBytes32(string memory source) returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }

}