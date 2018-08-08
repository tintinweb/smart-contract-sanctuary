pragma solidity ^0.4.21;

contract ERC20Interface {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
}

contract ERC20Token is ERC20Interface {

    using SafeMath for uint256;

    // Total amount of tokens issued
    uint256 internal totalTokenIssued;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    function totalSupply() public view returns (uint256) {
        return totalTokenIssued;
    }

    /* Get the account balance for an address */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /* Check whether an address is a contract address */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return (size > 0);
    }


    /* Transfer the balance from owner&#39;s account to another account */
    function transfer(address _to, uint256 _amount) public returns (bool) {

        require(_to != address(0x0));

        // Do not allow to transfer token to contract address to avoid tokens getting stuck
        require(isContract(_to) == false);

        // amount sent cannot exceed balance
        require(balances[msg.sender] >= _amount);


        // update balances
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to]        = balances[_to].add(_amount);

        // log event
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }


    /* Allow _spender to withdraw from your account up to _amount */
    function approve(address _spender, uint256 _amount) public returns (bool) {

        require(_spender != address(0x0));

        // update allowed amount
        allowed[msg.sender][_spender] = _amount;

        // log event
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /* Spender of tokens transfers tokens from the owner&#39;s balance */
    /* Must be pre-approved by owner */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {

        require(_to != address(0x0));

        // Do not allow to transfer token to contract address to avoid tokens getting stuck
        require(isContract(_to) == false);

        // balance checks
        require(balances[_from] >= _amount);
        require(allowed[_from][msg.sender] >= _amount);

        // update balances and allowed amount
        balances[_from]            = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to]              = balances[_to].add(_amount);

        // log event
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /* Returns the amount of tokens approved by the owner */
    /* that can be transferred by spender */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

contract MainSale is Ownable {

    using SafeMath for uint256;

    ShareToken public shrToken;

    bool public isIcoRunning = false;

    uint256 public tokenPriceInCent = 2; // cent or $0.02
    uint256 public ethUsdRateInCent = 0;// cent

    // Any token amount must be multiplied by this const to reflect decimals
    uint256 constant E2 = 10**2;

    /* Allow whitelisted users to send ETH to token contract for buying tokens */
    function () external payable {
        require (isIcoRunning);
        require (ethUsdRateInCent != 0);

        // Only whitelisted address can buy tokens. Otherwise, refund
        require (shrToken.isWhitelisted(msg.sender));

        // Calculate the amount of tokens based on the received ETH
        uint256 tokens = msg.value.mul(ethUsdRateInCent).mul(E2).div(tokenPriceInCent).div(10**18);

        uint256 totalIssuedTokens = shrToken.totalMainSaleTokenIssued();
        uint256 totalMainSaleLimit = shrToken.totalMainSaleTokenLimit();

        // If the allocated tokens exceed the limit, must refund to user
        if (totalIssuedTokens.add(tokens) > totalMainSaleLimit) {

            uint256 tokensAvailable = totalMainSaleLimit.sub(totalIssuedTokens);
            uint256 tokensToRefund = tokens.sub(tokensAvailable);
            uint256 ethToRefundInWei = tokensToRefund.mul(tokenPriceInCent).mul(10**18).div(E2).div(ethUsdRateInCent);

            // Refund
            msg.sender.transfer(ethToRefundInWei);

            // Update actual tokens to be sold
            tokens = tokensAvailable;

            // Stop ICO
            isIcoRunning = false;
        }

        shrToken.sell(msg.sender, tokens);
    }

    function withdrawTo(address _to) public onlyOwner {

        require(_to != address(0));
        _to.transfer(address(this).balance);
    }

    function withdrawToOwner() public onlyOwner {

        withdrawTo(owner);
    }

    function setEthUsdRateInCent(uint256 _ethUsdRateInCent) public onlyOwner {

        ethUsdRateInCent = _ethUsdRateInCent; // "_ethUsdRateInCent"
    }

    function setTokenPriceInCent(uint256 _tokenPriceInCent) public onlyOwner {

        tokenPriceInCent = _tokenPriceInCent;
    }

    function stopICO() public onlyOwner {

        isIcoRunning = false;
    }

    function startICO(uint256 _ethUsdRateInCent, address _tokenAddress) public onlyOwner {

        require(_ethUsdRateInCent > 0);
        require( _tokenAddress != address(0x0) );

        ethUsdRateInCent = _ethUsdRateInCent;
        shrToken = ShareToken(_tokenAddress);

        isIcoRunning = true;
    }

    function remainingTokensForSale() public view returns (uint256) {

        uint256 totalMainSaleLimit = shrToken.totalMainSaleTokenLimit();
        return totalMainSaleLimit.sub(shrToken.totalMainSaleTokenIssued());
    }
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        return (a / b);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return (a - b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract WhiteListManager is Ownable {

    // The list here will be updated by multiple separate WhiteList contracts
    mapping (address => bool) public list;

    function unset(address addr) public onlyOwner {

        list[addr] = false;
    }

    function unsetMany(address[] addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {

            unset(addrList[i]);
        }
    }

    function set(address addr) public onlyOwner {

        list[addr] = true;
    }

    function setMany(address[] addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {

            set(addrList[i]);
        }
    }

    function isWhitelisted(address addr) public view returns (bool) {

        return list[addr];
    }
}

contract ShareToken is ERC20Token, WhiteListManager {

    using SafeMath for uint256;

    string public constant name = "ShareToken";
    string public constant symbol = "SHR";
    uint8  public constant decimals = 2;

    address public icoContract;

    // Any token amount must be multiplied by this const to reflect decimals
    uint256 constant E2 = 10**2;

    mapping(address => bool) public rewardTokenLocked;
    bool public mainSaleTokenLocked = true;

    uint256 public constant TOKEN_SUPPLY_MAINSALE_LIMIT = 1000000000 * E2; // 1,000,000,000 tokens (1 billion)
    uint256 public constant TOKEN_SUPPLY_AIRDROP_LIMIT  = 6666666667; // 66,666,666.67 tokens (0.066 billion)
    uint256 public constant TOKEN_SUPPLY_BOUNTY_LIMIT   = 33333333333; // 333,333,333.33 tokens (0.333 billion)

    uint256 public airDropTokenIssuedTotal;
    uint256 public bountyTokenIssuedTotal;

    uint256 public constant TOKEN_SUPPLY_SEED_LIMIT      = 500000000 * E2; // 500,000,000 tokens (0.5 billion)
    uint256 public constant TOKEN_SUPPLY_PRESALE_LIMIT   = 2500000000 * E2; // 2,500,000,000.00 tokens (2.5 billion)
    uint256 public constant TOKEN_SUPPLY_SEED_PRESALE_LIMIT = TOKEN_SUPPLY_SEED_LIMIT + TOKEN_SUPPLY_PRESALE_LIMIT;

    uint256 public seedAndPresaleTokenIssuedTotal;

    uint8 private constant PRESALE_EVENT    = 0;
    uint8 private constant MAINSALE_EVENT   = 1;
    uint8 private constant BOUNTY_EVENT     = 2;
    uint8 private constant AIRDROP_EVENT    = 3;

    function ShareToken() public {

        totalTokenIssued = 0;
        airDropTokenIssuedTotal = 0;
        bountyTokenIssuedTotal = 0;
        seedAndPresaleTokenIssuedTotal = 0;
        mainSaleTokenLocked = true;
    }

    function unlockMainSaleToken() public onlyOwner {

        mainSaleTokenLocked = false;
    }

    function lockMainSaleToken() public onlyOwner {

        mainSaleTokenLocked = true;
    }

    function unlockRewardToken(address addr) public onlyOwner {

        rewardTokenLocked[addr] = false;
    }

    function unlockRewardTokenMany(address[] addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {

            unlockRewardToken(addrList[i]);
        }
    }

    function lockRewardToken(address addr) public onlyOwner {

        rewardTokenLocked[addr] = true;
    }

    function lockRewardTokenMany(address[] addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {

            lockRewardToken(addrList[i]);
        }
    }

    // Check if a given address is locked. The address can be in the whitelist or in the reward
    function isLocked(address addr) public view returns (bool) {

        // Main sale is running, any addr is locked
        if (mainSaleTokenLocked) {
            return true;
        } else {

            // Main sale is ended and thus any whitelist addr is unlocked
            if (isWhitelisted(addr)) {
                return false;
            } else {
                // If the addr is in the reward, it must be checked if locked
                // If the addr is not in the reward, it is considered unlocked
                return rewardTokenLocked[addr];
            }
        }
    }

    function totalSupply() public view returns (uint256) {

        return totalTokenIssued.add(seedAndPresaleTokenIssuedTotal).add(airDropTokenIssuedTotal).add(bountyTokenIssuedTotal);
    }

    function totalMainSaleTokenIssued() public view returns (uint256) {

        return totalTokenIssued;
    }

    function totalMainSaleTokenLimit() public view returns (uint256) {

        return TOKEN_SUPPLY_MAINSALE_LIMIT;
    }

    function totalPreSaleTokenIssued() public view returns (uint256) {

        return seedAndPresaleTokenIssuedTotal;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {

        require(isLocked(msg.sender) == false);
        require(isLocked(_to) == false);

        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {

        require(isLocked(_from) == false);
        require(isLocked(_to) == false);

        return super.transferFrom(_from, _to, _amount);
    }

    function setIcoContract(address _icoContract) public onlyOwner {

        // Allow to set the ICO contract only once
        require(icoContract == address(0));
        require(_icoContract != address(0));

        icoContract = _icoContract;
    }

    function sell(address buyer, uint256 tokens) public returns (bool success) {

        require (icoContract != address(0));
        // The sell() method can only be called by the fixedly-set ICO contract
        require (msg.sender == icoContract);
        require (tokens > 0);
        require (buyer != address(0));

        // Only whitelisted address can buy tokens. Otherwise, refund
        require (isWhitelisted(buyer));

        require (totalTokenIssued.add(tokens) <= TOKEN_SUPPLY_MAINSALE_LIMIT);

        // Register tokens issued to the buyer
        balances[buyer] = balances[buyer].add(tokens);

        // Update total amount of tokens issued
        totalTokenIssued = totalTokenIssued.add(tokens);

        emit Transfer(address(MAINSALE_EVENT), buyer, tokens);

        return true;
    }

    function rewardAirdrop(address _to, uint256 _amount) public onlyOwner {

        // this check also ascertains _amount is positive
        require(_amount <= TOKEN_SUPPLY_AIRDROP_LIMIT);

        require(airDropTokenIssuedTotal < TOKEN_SUPPLY_AIRDROP_LIMIT);

        uint256 remainingTokens = TOKEN_SUPPLY_AIRDROP_LIMIT.sub(airDropTokenIssuedTotal);
        if (_amount > remainingTokens) {
            _amount = remainingTokens;
        }

        // Register tokens to the receiver
        balances[_to] = balances[_to].add(_amount);

        // Update total amount of tokens issued
        airDropTokenIssuedTotal = airDropTokenIssuedTotal.add(_amount);

        // Lock the receiver
        rewardTokenLocked[_to] = true;

        emit Transfer(address(AIRDROP_EVENT), _to, _amount);
    }

    function rewardBounty(address _to, uint256 _amount) public onlyOwner {

        // this check also ascertains _amount is positive
        require(_amount <= TOKEN_SUPPLY_BOUNTY_LIMIT);

        require(bountyTokenIssuedTotal < TOKEN_SUPPLY_BOUNTY_LIMIT);

        uint256 remainingTokens = TOKEN_SUPPLY_BOUNTY_LIMIT.sub(bountyTokenIssuedTotal);
        if (_amount > remainingTokens) {
            _amount = remainingTokens;
        }

        // Register tokens to the receiver
        balances[_to] = balances[_to].add(_amount);

        // Update total amount of tokens issued
        bountyTokenIssuedTotal = bountyTokenIssuedTotal.add(_amount);

        // Lock the receiver
        rewardTokenLocked[_to] = true;

        emit Transfer(address(BOUNTY_EVENT), _to, _amount);
    }

    function rewardBountyMany(address[] addrList, uint256[] amountList) public onlyOwner {

        require(addrList.length == amountList.length);

        for (uint256 i = 0; i < addrList.length; i++) {

            rewardBounty(addrList[i], amountList[i]);
        }
    }

    function rewardAirdropMany(address[] addrList, uint256[] amountList) public onlyOwner {

        require(addrList.length == amountList.length);

        for (uint256 i = 0; i < addrList.length; i++) {

            rewardAirdrop(addrList[i], amountList[i]);
        }
    }

    function handlePresaleToken(address _to, uint256 _amount) public onlyOwner {

        require(_amount <= TOKEN_SUPPLY_SEED_PRESALE_LIMIT);

        require(seedAndPresaleTokenIssuedTotal < TOKEN_SUPPLY_SEED_PRESALE_LIMIT);

        uint256 remainingTokens = TOKEN_SUPPLY_SEED_PRESALE_LIMIT.sub(seedAndPresaleTokenIssuedTotal);
        require (_amount <= remainingTokens);

        // Register tokens to the receiver
        balances[_to] = balances[_to].add(_amount);

        // Update total amount of tokens issued
        seedAndPresaleTokenIssuedTotal = seedAndPresaleTokenIssuedTotal.add(_amount);

        emit Transfer(address(PRESALE_EVENT), _to, _amount);

        // Also add to whitelist
        set(_to);
    }

    function handlePresaleTokenMany(address[] addrList, uint256[] amountList) public onlyOwner {

        require(addrList.length == amountList.length);

        for (uint256 i = 0; i < addrList.length; i++) {

            handlePresaleToken(addrList[i], amountList[i]);
        }
    }
}