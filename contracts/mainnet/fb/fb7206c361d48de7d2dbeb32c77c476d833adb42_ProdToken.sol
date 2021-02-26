/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity 0.7.3;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract MultiOwnable {

    mapping (address => bool) public isOwner;
    address[] public ownerHistory;

    event OwnerAddedEvent(address indexed _newOwner);
    event OwnerRemovedEvent(address indexed _oldOwner);

    constructor() {
        // Add default owner
        address owner = msg.sender;
        ownerHistory.push(owner);
        isOwner[owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only owners allowed");
        _;
    }

    function ownerHistoryCount() public view returns (uint) {
        return ownerHistory.length;
    }

    /** Add extra owner. */
    function addOwner(address owner) onlyOwner public {
        require(owner != address(0), "Only valid addresses allowed");
        require(!isOwner[owner], "Owner is already added");
        ownerHistory.push(owner);
        isOwner[owner] = true;
        emit OwnerAddedEvent(owner);
    }

    /** Remove extra owner. */
    function removeOwner(address owner) onlyOwner public {
        require(isOwner[owner], "Owner is not defined");
        isOwner[owner] = false;
        emit OwnerRemovedEvent(owner);
    }
}

interface ERC20 {

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

abstract contract StandardToken is ERC20 {

    using SafeMath for uint;

    uint256 public totalSupply;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner) public override virtual view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferInternal(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Forbidden to transfer to zero address");

        trackBalance(_from);
        trackBalance(_to);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

    function approveInternal(address _owner, address _spender, uint256 _value) internal returns (bool) {
        require(_spender != address(0), "Forbidden to approve zero address");

        allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);

        return true;
    }

    function transfer(address _to, uint256 _value) public override virtual returns (bool) {
        transferInternal(msg.sender, _to, _value);

        return true;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) public override virtual returns (bool) {
        require(_from != address(0), "Forbidden to transfer from zero address");
        require(_to != address(0), "Forbidden to transfer to zero address");

        trackBalance(_from);
        trackBalance(_to);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);

        emit Transfer(_from, _to, _value);

        return true;
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) public override virtual returns (bool) {
        return approveInternal(msg.sender, _spender, _value);
    }

    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) public override virtual view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function trackBalance(address account) public virtual;
}

contract CommonToken is StandardToken, MultiOwnable {
    using SafeMath for uint;

    struct Dividend {
        uint256 amount;
        uint256 block;
    }

    struct UserDividend {
        uint256 lastClaimedDividend;
        uint256 balanceTillDividend;
    }

    string public constant name   = 'BRKROFX';
    string public constant symbol = 'BRKROFX';
    uint8 public constant decimals = 18;

    uint256 public saleLimit;   // 30% of tokens for sale (10% presale & 20% public sale).

    // The main account that holds all tokens at the beginning and during tokensale.
    address public seller; // Seller address (main holder of tokens)

    address public distributor; // Distributor address

    uint256 public tokensSold; // (e18) Number of tokens sold through all tiers or tokensales.
    uint256 public totalSales; // Total number of sales (including external sales) made through all tiers or tokensales.

    // Lock the transfer functions during tokensales to prevent price speculations.
    bool public locked = true;

    mapping (address => uint256) public nonces;
    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public immutable DOMAIN_SEPARATOR;

    mapping (address => bool) public dividendDistributors;

    Dividend [] public dividends;
    mapping(address => UserDividend) public userDividends;
    mapping(address => mapping(uint256 => uint256)) public balanceByDividends;

    event SellEvent(address indexed _seller, address indexed _buyer, uint256 _value);
    event ChangeSellerEvent(address indexed _oldSeller, address indexed _newSeller);
    event Burn(address indexed _burner, uint256 _value);
    event Unlock();
    event DividendAdded(uint256 _dividendId, uint256 _value, uint256 _block);
    event DividendClaimed(address _account, uint256 _dividendId, uint256 _value);

    constructor(
        address _seller
    ) MultiOwnable() {

        totalSupply = 1_000_000_000 ether;
        saleLimit   = 300_000_000 ether;

        seller = _seller;
        distributor = msg.sender;

        uint sellerTokens = totalSupply;
        balances[seller] = sellerTokens;
        emit Transfer(address(0x0), seller, sellerTokens);

        uint256 chainId;
        assembly {chainId := chainid()}

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    modifier ifUnlocked(address _from) {
        require(!locked, "Allowed only if unlocked");
        _;
    }

    modifier onlyDistributor() {
        require(msg.sender == distributor, "Allowed only for distributor");
        _;
    }

    modifier onlyDividendDistributor() {
        require(dividendDistributors[msg.sender], "Allowed only for dividend distributor");
        _;
    }

    /** Can be called once by super owner. */
    function unlock() onlyOwner public {
        require(locked, "I am locked");
        locked = false;
        emit Unlock();
    }

    /**
     * An address can become a new seller only in case it has no tokens.
     * This is required to prevent stealing of tokens  from newSeller via
     * 2 calls of this function.
     */
    function changeSeller(address newSeller) onlyOwner public returns (bool) {
        require(newSeller != address(0), "Invalid seller address");
        require(seller != newSeller, "New seller is same");

        // To prevent stealing of tokens from newSeller via 2 calls of changeSeller:
        require(balances[newSeller] == 0, "New seller balance is not empty");

        address oldSeller = seller;
        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = unsoldTokens;
        emit Transfer(oldSeller, newSeller, unsoldTokens);

        seller = newSeller;
        emit ChangeSellerEvent(oldSeller, newSeller);
        return true;
    }

    function changeDistributor(address newDistributor) onlyOwner public returns (bool) {
        distributor = newDistributor;

        return true;
    }

    /**
     * User-friendly alternative to sell() function.
     */
    function sellNoDecimals(address _to, uint256 _value) public returns (bool) {
        return sell(_to, _value * 1e18);
    }

    function sell(address _to, uint256 _value) onlyDistributor public returns (bool) {

        // Check that we are not out of limit and still can sell tokens:
        require(tokensSold.add(_value) <= saleLimit, "Sell exceeds allowed limit");

        require(_to != address(0), "Can't sell to zero address");
        require(_value > 0, "_value is 0");
        require(_value <= balances[seller], "Can't sell more tokens then available");

        balances[seller] = balances[seller].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(seller, _to, _value);

        totalSales++;
        tokensSold = tokensSold.add(_value);
        emit SellEvent(seller, _to, _value);
        return true;
    }

    /**
     * Until all tokens are sold, tokens can be transfered to/from owner's accounts.
     */
    function transfer(address _to, uint256 _value) ifUnlocked(msg.sender) public override returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * Until all tokens are sold, tokens can be transfered to/from owner's accounts.
     */
    function transferFrom(address _from, address _to, uint256 _value) ifUnlocked(_from) public override returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) public returns (bool) {
        require(_value > 0, "_value is 0");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(msg.sender, address(0x0), _value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(deadline >= block.timestamp, 'CommonToken: expired deadline');

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);

        require(recoveredAddress != address(0) && recoveredAddress == owner, 'CommonToken: invalid permit');

        approveInternal(owner, spender, value);
    }

    function transferByPermit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        permit(owner, spender, value, deadline, v, r, s);

        require(msg.sender == spender, "CommonToken: spender should be method caller");

        transferFrom(owner, spender, value);
    }

    function dividendsCount() public view returns (uint256 count) {
        return dividends.length;
    }

    function setDividendsDistributor(address _dividendDistributor, bool _allowed) public onlyOwner {
        dividendDistributors[_dividendDistributor] = _allowed;
    }

    function addDividend(uint256 _dividendTokens) public onlyDividendDistributor {
        require(_dividendTokens > 0, "CommonToken: not enough dividend tokens shared");
        require(balanceOf(msg.sender) >= _dividendTokens, "CommonToken: not enough balance to create dividend");

        dividends.push(Dividend(_dividendTokens, block.number));

        transferInternal(msg.sender, address(this), _dividendTokens);

        emit DividendAdded(dividends.length - 1, _dividendTokens, block.number);
    }

    function claimDividend() public {
        claimDividendsFor(msg.sender, 1);
    }

    function claimDividends(uint256 _dividendsCount) public {
        claimDividendsFor(msg.sender, _dividendsCount);
    }

    function claimAllDividends() public {
        claimAllDividendsFor(msg.sender);
    }

    function claimDividendFor(address _account) public {
        claimDividendsFor(_account, 1);
    }

    function claimDividendsFor(address _account, uint256 _dividendsCount) public {
        require(_dividendsCount > 0, "CommonToken: Dividends count to claim should be greater than 0");
        require(dividends.length > 0, "CommonToken: No dividends present");

        trackBalance(_account);

        uint256 _fromDividend = userDividends[_account].lastClaimedDividend;
        uint256 _toDividend = _fromDividend.add(_dividendsCount);

        require(_toDividend <= dividends.length, "CommonToken: no dividends available for claim");

        uint256 totalDividends = 0;

        for (uint256 i = _fromDividend; i < _toDividend; i++) {
            uint256 dividendsFraction = dividends[i].amount.mul(balanceByDividends[_account][i]).div(totalSupply);
            totalDividends = totalDividends.add(dividendsFraction);

            emit DividendClaimed(_account, i, dividendsFraction);
        }

        userDividends[_account].lastClaimedDividend = _toDividend;

        transferInternal(address(this), _account, totalDividends);

        emit Transfer(address(this), _account, totalDividends);
    }

    function claimAllDividendsFor(address _account) public {
        claimDividendsFor(_account, dividends.length.sub(userDividends[_account].lastClaimedDividend));
    }

    function trackBalance(address account) public override {
        if (dividends.length == 0) {
            return;
        }

        if (balanceOf(account) == 0 && userDividends[account].lastClaimedDividend == 0) {
            userDividends[account].lastClaimedDividend = dividends.length;

            return;
        }

        if (userDividends[account].balanceTillDividend < dividends.length) {
            for (uint256 i = userDividends[account].balanceTillDividend; i < dividends.length; i++) {
                balanceByDividends[account][i] = balanceOf(account);
            }

            userDividends[account].balanceTillDividend = dividends.length;
        }
    }
}

contract ProdToken is CommonToken {
    constructor() CommonToken(
        0xF774c190CDAD67578f7181F74323F996041cAcfd
    ) {}
}