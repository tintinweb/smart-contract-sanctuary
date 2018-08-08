pragma solidity ^0.4.13;

interface IAffiliateList {
    /**
     * @dev Sets the given address as an affiliate.
     *      If the address is not currently an affiliate, startTimestamp is required
     *      and endTimestamp is optional.
     *      If the address is already registered as an affiliate, both values are optional.
     * @param startTimestamp Timestamp when the address became/becomes an affiliate.
     * @param endTimestamp Timestamp when the address will no longer be an affiliate.
     */
    function set(address addr, uint startTimestamp, uint endTimestamp) external;

    /**
     * @dev Retrieves the start and end timestamps for the given address.
     *      It is sufficient to check the start value to determine if the address
     *      is an affiliate (start will be greater than zero).
     */
    function get(address addr) external view returns (uint start, uint end);

    /**
     * @dev Returns true if the address is, was, or will be an affiliate at the given time.
     */
    function inListAsOf(address addr, uint time) external view returns (bool);
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract IInvestorList {
    string public constant ROLE_REGD = "regd";
    string public constant ROLE_REGCF = "regcf";
    string public constant ROLE_REGS = "regs";
    string public constant ROLE_UNKNOWN = "unknown";

    function inList(address addr) public view returns (bool);
    function addAddress(address addr, string role) public;
    function getRole(address addr) public view returns (string);
    function hasRole(address addr, string role) public view returns (bool);
}

contract Ownable {
    address public owner;
    address public newOwner;

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
     * @dev Starts the 2-step process of changing ownership. The new owner
     * must then call `acceptOwnership()`.
     */
    function changeOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    /**
     * @dev Completes the process of transferring ownership to a new owner.
     */
    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
            newOwner = 0;
        }
    }

}

contract AffiliateList is Ownable, IAffiliateList {
    event AffiliateAdded(address addr, uint startTimestamp, uint endTimestamp);
    event AffiliateUpdated(address addr, uint startTimestamp, uint endTimestamp);

    mapping (address => uint) public affiliateStart;
    mapping (address => uint) public affiliateEnd;

    function set(address addr, uint startTimestamp, uint endTimestamp) public onlyOwner {
        require(addr != address(0));

        uint existingStart = affiliateStart[addr];

        if(existingStart == 0) {
            // this is a new address

            require(startTimestamp != 0);
            affiliateStart[addr] = startTimestamp;

            if(endTimestamp != 0) {
                require(endTimestamp > startTimestamp);
                affiliateEnd[addr] = endTimestamp;
            }

            emit AffiliateAdded(addr, startTimestamp, endTimestamp);
        }
        else {
            // this address was previously registered

            if(startTimestamp == 0) {
                // don&#39;t update the start timestamp

                if(endTimestamp == 0) {
                    affiliateStart[addr] = 0;
                    affiliateEnd[addr] = 0;
                }
                else {
                    require(endTimestamp > existingStart);
                }
            }
            else {
                // update the start timestamp
                affiliateStart[addr] = startTimestamp;

                if(endTimestamp != 0) {
                    require(endTimestamp > startTimestamp);
                }
            }
            affiliateEnd[addr] = endTimestamp;

            emit AffiliateUpdated(addr, startTimestamp, endTimestamp);
        }
    }

    function get(address addr) public view returns (uint start, uint end) {
        return (affiliateStart[addr], affiliateEnd[addr]);
    }

    function inListAsOf(address addr, uint time) public view returns (bool) {
        uint start;
        uint end;
        (start, end) = get(addr);
        if(start == 0) {
            return false;
        }
        if(time < start) {
            return false;
        }
        if(end != 0 && time >= end) {
            return false;
        }
        return true;
    }
}

contract InvestorList is Ownable, IInvestorList {
    event AddressAdded(address addr, string role);
    event AddressRemoved(address addr, string role);

    mapping (address => string) internal investorList;

    /**
     * @dev Throws if called by any account that&#39;s not investorListed.
     * @param role string
     */
    modifier validRole(string role) {
        require(
            keccak256(bytes(role)) == keccak256(bytes(ROLE_REGD)) ||
            keccak256(bytes(role)) == keccak256(bytes(ROLE_REGCF)) ||
            keccak256(bytes(role)) == keccak256(bytes(ROLE_REGS)) ||
            keccak256(bytes(role)) == keccak256(bytes(ROLE_UNKNOWN))
        );
        _;
    }

    /**
     * @dev Getter to determine if address is in investorList.
     * @param addr address
     * @return true if the address was added to the investorList, false if the address was already in the investorList
     */
    function inList(address addr)
        public
        view
        returns (bool)
    {
        if (bytes(investorList[addr]).length != 0) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Getter for address role if address is in list.
     * @param addr address
     * @return string for address role
     */
    function getRole(address addr)
        public
        view
        returns (string)
    {
        require(inList(addr));
        return investorList[addr];
    }

    /**
     * @dev Returns a boolean indicating if the given address is in the list
     *      with the given role.
     * @param addr address to check
     * @param role role to check
     * @ return boolean for whether the address is in the list with the role
     */
    function hasRole(address addr, string role)
        public
        view
        returns (bool)
    {
        return keccak256(bytes(role)) == keccak256(bytes(investorList[addr]));
    }

    /**
     * @dev Add single address to the investorList.
     * @param addr address
     * @param role string
     */
    function addAddress(address addr, string role)
        onlyOwner
        validRole(role)
        public
    {
        investorList[addr] = role;
        emit AddressAdded(addr, role);
    }

    /**
     * @dev Add multiple addresses to the investorList.
     * @param addrs addresses
     * @param role string
     */
    function addAddresses(address[] addrs, string role)
        onlyOwner
        validRole(role)
        public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            addAddress(addrs[i], role);
        }
    }

    /**
     * @dev Remove single address from the investorList.
     * @param addr address
     */
    function removeAddress(address addr)
        onlyOwner
        public
    {
        // removeRole(addr, ROLE_WHITELISTED);
        require(inList(addr));
        string memory role = investorList[addr];
        investorList[addr] = "";
        emit AddressRemoved(addr, role);
    }

    /**
     * @dev Remove multiple addresses from the investorList.
     * @param addrs addresses
     */
    function removeAddresses(address[] addrs)
        onlyOwner
        public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (inList(addrs[i])) {
                removeAddress(addrs[i]);
            }
        }
    }

}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ISecurityController {
    function balanceOf(address _a) public view returns (uint);
    function totalSupply() public view returns (uint);

    function isTransferAuthorized(address _from, address _to) public view returns (bool);
    function setTransferAuthorized(address from, address to, uint expiry) public;

    function transfer(address _from, address _to, uint _value) public returns (bool success);
    function transferFrom(address _spender, address _from, address _to, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint);
    function approve(address _owner, address _spender, uint _value) public returns (bool success);
    function increaseApproval(address _owner, address _spender, uint _addedValue) public returns (bool success);
    function decreaseApproval(address _owner, address _spender, uint _subtractedValue) public returns (bool success);

    function burn(address _owner, uint _amount) public;
    function ledgerTransfer(address from, address to, uint val) public;
    function setLedger(address _ledger) public;
    function setSale(address _sale) public;
    function setToken(address _token) public;
    function setAffiliateList(address _affiliateList) public;
}

contract SecurityController is ISecurityController, Ownable {
    ISecurityLedger public ledger;
    ISecurityToken public token;
    ISecuritySale public sale;
    IInvestorList public investorList;
    ITransferAuthorizations public transferAuthorizations;
    IAffiliateList public affiliateList;

    uint public lockoutPeriod = 10 * 60 * 60; // length in seconds of the lockout period

    // restrict who can grant transfer authorizations
    mapping(address => bool) public transferAuthPermission;

    constructor() public {
    }

    function setTransferAuthorized(address from, address to, uint expiry) public {
        // Must be called from address in the transferAuthPermission mapping
        require(transferAuthPermission[msg.sender]);

        // don&#39;t allow &#39;from&#39; to be zero
        require(from != 0);

        // verify expiry is in future, but not more than 30 days
        if(expiry > 0) {
            require(expiry > block.timestamp);
            require(expiry <= (block.timestamp + 30 days));
        }

        transferAuthorizations.set(from, to, expiry);
    }

    // functions below this line are onlyOwner

    function setLockoutPeriod(uint _lockoutPeriod) public onlyOwner {
        lockoutPeriod = _lockoutPeriod;
    }

    function setToken(address _token) public onlyOwner {
        token = ISecurityToken(_token);
    }

    function setLedger(address _ledger) public onlyOwner {
        ledger = ISecurityLedger(_ledger);
    }

    function setSale(address _sale) public onlyOwner {
        sale = ISecuritySale(_sale);
    }

    function setInvestorList(address _investorList) public onlyOwner {
        investorList = IInvestorList(_investorList);
    }

    function setTransferAuthorizations(address _transferAuthorizations) public onlyOwner {
        transferAuthorizations = ITransferAuthorizations(_transferAuthorizations);
    }

    function setAffiliateList(address _affiliateList) public onlyOwner {
        affiliateList = IAffiliateList(_affiliateList);
    }

    function setTransferAuthPermission(address agent, bool hasPermission) public onlyOwner {
        require(agent != address(0));
        transferAuthPermission[agent] = hasPermission;
    }

    modifier onlyToken() {
        require(msg.sender == address(token));
        _;
    }

    modifier onlyLedger() {
        require(msg.sender == address(ledger));
        _;
    }

    // public functions

    function totalSupply() public view returns (uint) {
        return ledger.totalSupply();
    }

    function balanceOf(address _a) public view returns (uint) {
        return ledger.balanceOf(_a);
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return ledger.allowance(_owner, _spender);
    }

    function isTransferAuthorized(address _from, address _to) public view returns (bool) {
        // A `from` address could have both an allowance for the `to` address
        // and a global allowance (to the zero address). We pick the maximum
        // of the two.

        uint expiry = transferAuthorizations.get(_from, _to);
        uint globalExpiry = transferAuthorizations.get(_from, 0);
        if(globalExpiry > expiry) {
            expiry = globalExpiry;
        }

        return expiry > block.timestamp;
    }

    /**
     * @dev Determines whether the given transfer is possible. Returns multiple
     *      boolean flags specifying how the transfer must occur.
     *      This is kept public to provide for testing and subclasses overriding behavior.
     * @param _from Address the tokens are being transferred from
     * @param _to Address the tokens are being transferred to
     * @param _value Number of tokens that would be transferred
     * @param lockoutTime A point in time, specified in epoch time, that specifies
     *                    the lockout period (typically 1 year before now).
     * @return canTransfer Whether the transfer can occur at all.
     * @return useLockoutTime Whether the lockoutTime should be used to determine which tokens to transfer.
     * @return newTokensAreRestricted Whether the transferred tokens should be marked as restricted.
     * @return preservePurchaseDate Whether the purchase date on the tokens should be preserved, or reset to &#39;now&#39;.
     */
    function checkTransfer(address _from, address _to, uint _value, uint lockoutTime)
        public
        returns (bool canTransfer, bool useLockoutTime, bool newTokensAreRestricted, bool preservePurchaseDate) {

        // DEFAULT BEHAVIOR:
        //
        // If there exists a Transfer Agent authorization, allow transfer regardless
        //
        // All transfers from an affiliate must be authorized by Transfer Agent
        //   - tokens become restricted
        //
        // From Reg S to Reg S: allowable, regardless of holding period
        //
        // otherwise must meet holding period

        // presently this isn&#39;t used, so always setting to false to avoid warning
        preservePurchaseDate = false;

        bool transferIsAuthorized = isTransferAuthorized(_from, _to);

        bool fromIsAffiliate = affiliateList.inListAsOf(_from, block.timestamp);
        bool toIsAffiliate = affiliateList.inListAsOf(_to, block.timestamp);

        if(transferIsAuthorized) {
            canTransfer = true;
            if(fromIsAffiliate || toIsAffiliate) {
                newTokensAreRestricted = true;
            }
            // useLockoutTime will remain false
            // preservePurchaseDate will remain false
        }
        else if(!fromIsAffiliate) {
            // see if both are Reg S
            if(investorList.hasRole(_from, investorList.ROLE_REGS())
                && investorList.hasRole(_to, investorList.ROLE_REGS())) {
                canTransfer = true;
                // newTokensAreRestricted will remain false
                // useLockoutTime will remain false
                // preservePurchaseDate will remain false
            }
            else {
                if(ledger.transferDryRun(_from, _to, _value, lockoutTime) == _value) {
                    canTransfer = true;
                    useLockoutTime = true;
                    // newTokensAreRestricted will remain false
                    // preservePurchaseDate will remain false
                }
            }
        }
    }

    // functions below this line are onlyLedger

    // let the ledger send transfer events (the most obvious case
    // is when we mint directly to the ledger and need the Transfer()
    // events to appear in the token)
    function ledgerTransfer(address from, address to, uint val) public onlyLedger {
        token.controllerTransfer(from, to, val);
    }

    // functions below this line are onlyToken

    function transfer(address _from, address _to, uint _value) public onlyToken returns (bool success) {
        //TODO: this could be configurable
        uint lockoutTime = block.timestamp - lockoutPeriod;
        bool canTransfer;
        bool useLockoutTime;
        bool newTokensAreRestricted;
        bool preservePurchaseDate;
        (canTransfer, useLockoutTime, newTokensAreRestricted, preservePurchaseDate)
            = checkTransfer(_from, _to, _value, lockoutTime);

        if(!canTransfer) {
            return false;
        }

        uint overrideLockoutTime = lockoutTime;
        if(!useLockoutTime) {
            overrideLockoutTime = 0;
        }

        return ledger.transfer(_from, _to, _value, overrideLockoutTime, newTokensAreRestricted, preservePurchaseDate);
    }

    function transferFrom(address _spender, address _from, address _to, uint _value) public onlyToken returns (bool success) {
        //TODO: this could be configurable
        uint lockoutTime = block.timestamp - lockoutPeriod;
        bool canTransfer;
        bool useLockoutTime;
        bool newTokensAreRestricted;
        bool preservePurchaseDate;
        (canTransfer, useLockoutTime, newTokensAreRestricted, preservePurchaseDate)
            = checkTransfer(_from, _to, _value, lockoutTime);

        if(!canTransfer) {
            return false;
        }

        uint overrideLockoutTime = lockoutTime;
        if(!useLockoutTime) {
            overrideLockoutTime = 0;
        }

        return ledger.transferFrom(_spender, _from, _to, _value, overrideLockoutTime, newTokensAreRestricted, preservePurchaseDate);
    }

    function approve(address _owner, address _spender, uint _value) public onlyToken returns (bool success) {
        return ledger.approve(_owner, _spender, _value);
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue) public onlyToken returns (bool success) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue) public onlyToken returns (bool success) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }

    function burn(address _owner, uint _amount) public onlyToken {
        ledger.burn(_owner, _amount);
    }
}

interface ISecurityLedger {
    function balanceOf(address _a) external view returns (uint);
    function totalSupply() external view returns (uint);

    function transferDryRun(address _from, address _to, uint amount, uint lockoutTime) external returns (uint transferrableCount);
    function transfer(address _from, address _to, uint _value, uint lockoutTime, bool newTokensAreRestricted, bool preservePurchaseDate) external returns (bool success);
    function transferFrom(address _spender, address _from, address _to, uint _value, uint lockoutTime, bool newTokensAreRestricted, bool preservePurchaseDate) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint);
    function approve(address _owner, address _spender, uint _value) external returns (bool success);
    function increaseApproval(address _owner, address _spender, uint _addedValue) external returns (bool success);
    function decreaseApproval(address _owner, address _spender, uint _subtractedValue) external returns (bool success);

    function burn(address _owner, uint _amount) external;
    function setController(address _controller) external;
}

contract SecurityLedger is Ownable {
    using SafeMath for uint256;

    struct TokenLot {
        uint amount;
        uint purchaseDate;
        bool restricted;
    }
    mapping(address => TokenLot[]) public tokenLotsOf;

    SecurityController public controller;
    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint public totalSupply;
    uint public mintingNonce;
    bool public mintingStopped;


    constructor() public {
    }

    // functions below this line are onlyOwner

    function setController(address _controller) public onlyOwner {
        controller = SecurityController(_controller);
    }

    function stopMinting() public onlyOwner {
        mintingStopped = true;
    }

    //TODO: not sure if this function should stay long term
    function mint(address addr, uint value, uint timestamp) public onlyOwner {
        require(!mintingStopped);

        uint time = timestamp;
        if(time == 0) {
            time = block.timestamp;
        }

        balanceOf[addr] = balanceOf[addr].add(value);
        tokenLotsOf[addr].push(TokenLot(value, time, true));
        controller.ledgerTransfer(0, addr, value);
        totalSupply = totalSupply.add(value);
    }

    function multiMint(uint nonce, uint256[] bits, uint timestamp) external onlyOwner {
        require(!mintingStopped);
        if (nonce != mintingNonce) return;
        mintingNonce = mintingNonce.add(1);
        uint256 lomask = (1 << 96) - 1;
        uint created = 0;

        uint time = timestamp;
        if(time == 0) {
            time = block.timestamp;
        }

        for (uint i = 0; i < bits.length; i++) {
            address addr = address(bits[i]>>96);
            uint value = bits[i] & lomask;
            balanceOf[addr] = balanceOf[addr].add(value);
            tokenLotsOf[addr].push(TokenLot(value, time, true));
            controller.ledgerTransfer(0, addr, value);
            created = created.add(value);
        }
        totalSupply = totalSupply.add(created);
    }

    // send received tokens to anyone
    function sendReceivedTokens(address token, address sender, uint amount) public onlyOwner {
        ERC20Basic t = ERC20Basic(token);
        require(t.transfer(sender, amount));
    }

    // functions below this line are onlyController

    modifier onlyController() {
        require(msg.sender == address(controller));
        _;
    }

    /**
     * @dev Walks through the list of TokenLots for the given address, attempting to find
     *      `amount` tokens that can be transferred. It uses the given `lockoutTime` if
     *      the supplied value is not zero. If `removeTokens` is true the tokens are
     *      actually removed from the address, otherwise this function acts as a dry run.
     *      The value returned is the actual number of transferrable tokens found, up to
     *      the maximum value of `amount`.
     */
    function walkTokenLots(address from, address to, uint amount, uint lockoutTime, bool removeTokens,
        bool newTokensAreRestricted, bool preservePurchaseDate)
        internal returns (uint numTransferrableTokens)
    {
        TokenLot[] storage fromTokenLots = tokenLotsOf[from];
        for(uint i=0; i<fromTokenLots.length; i++) {
            TokenLot storage lot = fromTokenLots[i];
            uint lotAmount = lot.amount;

            // skip if there are no available tokens
            if(lotAmount == 0) {
                continue;
            }

            if(lockoutTime > 0) {
                // skip if it is more recent than the lockout period AND it&#39;s restricted
                if(lot.restricted && lot.purchaseDate > lockoutTime) {
                    continue;
                }
            }

            uint remaining = amount - numTransferrableTokens;

            if(lotAmount >= remaining) {
                numTransferrableTokens = numTransferrableTokens.add(remaining);
                if(removeTokens) {
                    lot.amount = lotAmount.sub(remaining);
                    if(to != address(0)) {
                        if(preservePurchaseDate) {
                            tokenLotsOf[to].push(TokenLot(remaining, lot.purchaseDate, newTokensAreRestricted));
                        }
                        else {
                            tokenLotsOf[to].push(TokenLot(remaining, block.timestamp, newTokensAreRestricted));
                        }
                    }
                }
                break;
            }

            // If we&#39;re here, then amount in this lot is not yet enough.
            // Take all of it.
            numTransferrableTokens = numTransferrableTokens.add(lotAmount);
            if(removeTokens) {
                lot.amount = 0;
                if(to != address(0)) {
                    if(preservePurchaseDate) {
                        tokenLotsOf[to].push(TokenLot(lotAmount, lot.purchaseDate, newTokensAreRestricted));
                    }
                    else {
                        tokenLotsOf[to].push(TokenLot(lotAmount, block.timestamp, newTokensAreRestricted));
                    }
                }
            }
        }
    }

    function transferDryRun(address from, address to, uint amount, uint lockoutTime) public onlyController returns (uint) {
        return walkTokenLots(from, to, amount, lockoutTime, false, false, false);
    }

    function transfer(address _from, address _to, uint _value, uint lockoutTime, bool newTokensAreRestricted, bool preservePurchaseDate) public onlyController returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        // ensure number of tokens removed from TokenLots is as expected
        uint tokensTransferred = walkTokenLots(_from, _to, _value, lockoutTime, true, newTokensAreRestricted, preservePurchaseDate);
        require(tokensTransferred == _value);

        // adjust balances
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        return true;
    }

    function transferFrom(address _spender, address _from, address _to, uint _value, uint lockoutTime, bool newTokensAreRestricted, bool preservePurchaseDate) public onlyController returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        // ensure there is enough allowance
        uint allowed = allowance[_from][_spender];
        if (allowed < _value) return false;

        // ensure number of tokens removed from TokenLots is as expected
        uint tokensTransferred = walkTokenLots(_from, _to, _value, lockoutTime, true, newTokensAreRestricted, preservePurchaseDate);
        require(tokensTransferred == _value);

        // adjust balances
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        allowance[_from][_spender] = allowed.sub(_value);
        return true;
    }

    function approve(address _owner, address _spender, uint _value) public onlyController returns (bool success) {
        // require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[_owner][_spender] != 0)) {
            return false;
        }

        allowance[_owner][_spender] = _value;
        return true;
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue) public onlyController returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        allowance[_owner][_spender] = oldValue.add(_addedValue);
        return true;
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue) public onlyController returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        if (_subtractedValue > oldValue) {
            allowance[_owner][_spender] = 0;
        } else {
            allowance[_owner][_spender] = oldValue.sub(_subtractedValue);
        }
        return true;
    }

    function burn(address _owner, uint _amount) public onlyController {
        require(balanceOf[_owner] >= _amount);

        balanceOf[_owner] = balanceOf[_owner].sub(_amount);

        // remove tokens from TokenLots
        // (i.e. transfer them to 0)
        walkTokenLots(_owner, address(0), _amount, 0, true, false, false);

        totalSupply = totalSupply.sub(_amount);
    }
}

interface ISecuritySale {
    function setLive(bool newLiveness) external;
    function setInvestorList(address _investorList) external;
}

contract SecuritySale is Ownable {

    bool public live;        // sale is live right now
    IInvestorList public investorList; // approved contributors

    event SaleLive(bool liveness);
    event EtherIn(address from, uint amount);
    event StartSale();
    event EndSale();

    constructor() public {
        live = false;
    }

    function setInvestorList(address _investorList) public onlyOwner {
        investorList = IInvestorList(_investorList);
    }

    function () public payable {
        require(live);
        require(investorList.inList(msg.sender));
        emit EtherIn(msg.sender, msg.value);
    }

    // set liveness
    function setLive(bool newLiveness) public onlyOwner {
        if(live && !newLiveness) {
            live = false;
            emit EndSale();
        }
        else if(!live && newLiveness) {
            live = true;
            emit StartSale();
        }
    }

    // withdraw all of the Ether to owner
    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    // withdraw some of the Ether to owner
    function withdrawSome(uint value) public onlyOwner {
        require(value <= address(this).balance);
        msg.sender.transfer(value);
    }

    // withdraw tokens to owner
    function withdrawTokens(address token) public onlyOwner {
        ERC20Basic t = ERC20Basic(token);
        require(t.transfer(msg.sender, t.balanceOf(this)));
    }

    // send received tokens to anyone
    function sendReceivedTokens(address token, address sender, uint amount) public onlyOwner {
        ERC20Basic t = ERC20Basic(token);
        require(t.transfer(sender, amount));
    }
}

interface ISecurityToken {
    function balanceOf(address addr) external view returns(uint);
    function transfer(address to, uint amount) external returns(bool);
    function controllerTransfer(address _from, address _to, uint _value) external;
}

contract SecurityToken is Ownable{
    using SafeMath for uint256;

    ISecurityController public controller;
    // these public fields are set once in constructor
    string public name;
    string public symbol;
    uint8 public decimals;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(string _name, string  _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    // functions below this line are onlyOwner

    function setController(address _c) public onlyOwner {
        controller = ISecurityController(_c);
    }

    // send received tokens to anyone
    function sendReceivedTokens(address token, address sender, uint amount) public onlyOwner {
        ERC20Basic t = ERC20Basic(token);
        require(t.transfer(sender, amount));
    }

    // functions below this line are public

    function balanceOf(address a) public view returns (uint) {
        return controller.balanceOf(a);
    }

    function totalSupply() public view returns (uint) {
        return controller.totalSupply();
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return controller.allowance(_owner, _spender);
    }

    function burn(uint _amount) public {
        controller.burn(msg.sender, _amount);
        emit Transfer(msg.sender, 0x0, _amount);
    }

    // functions below this line are onlyPayloadSize

    // TODO: investigate this security optimization more
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length >= numwords.mul(32).add(4));
        _;
    }

    function isTransferAuthorized(address _from, address _to) public onlyPayloadSize(2) view returns (bool) {
        return controller.isTransferAuthorized(_from, _to);
    }

    function transfer(address _to, uint _value) public onlyPayloadSize(2) returns (bool success) {
        if (controller.transfer(msg.sender, _to, _value)) {
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3) returns (bool success) {
        if (controller.transferFrom(msg.sender, _from, _to, _value)) {
            emit Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function approve(address _spender, uint _value) onlyPayloadSize(2) public returns (bool success) {
        if (controller.approve(msg.sender, _spender, _value)) {
            emit Approval(msg.sender, _spender, _value);
            return true;
        }
        return false;
    }

    function increaseApproval (address _spender, uint _addedValue) public onlyPayloadSize(2) returns (bool success) {
        if (controller.increaseApproval(msg.sender, _spender, _addedValue)) {
            uint newval = controller.allowance(msg.sender, _spender);
            emit Approval(msg.sender, _spender, newval);
            return true;
        }
        return false;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public onlyPayloadSize(2) returns (bool success) {
        if (controller.decreaseApproval(msg.sender, _spender, _subtractedValue)) {
            uint newval = controller.allowance(msg.sender, _spender);
            emit Approval(msg.sender, _spender, newval);
            return true;
        }
        return false;
    }

    // functions below this line are onlyController

    modifier onlyController() {
        assert(msg.sender == address(controller));
        _;
    }

    function controllerTransfer(address _from, address _to, uint _value) public onlyController {
        emit Transfer(_from, _to, _value);
    }

    function controllerApprove(address _owner, address _spender, uint _value) public onlyController {
        emit Approval(_owner, _spender, _value);
    }
}

interface ITransferAuthorizations {
    function setController(address _controller) external;
    function get(address from, address to) external view returns (uint);
    function set(address from, address to, uint expiry) external;
}

contract TransferAuthorizations is Ownable, ITransferAuthorizations {

    /**
     * @dev The first key is the `from` address. The second key is the `to` address.
     *      The uint value of the mapping is the epoch time (seconds since 1/1/1970)
     *      of the expiration of the approved transfer.
     */
    mapping(address => mapping(address => uint)) public authorizations;

    /**
     * @dev This controller is the only contract allowed to call the `set` function.
     */
    address public controller;

    event TransferAuthorizationSet(address from, address to, uint expiry);

    function setController(address _controller) public onlyOwner {
        controller = _controller;
    }

    modifier onlyController() {
        assert(msg.sender == controller);
        _;
    }

    /**
     * @dev Sets the authorization for a transfer to occur between the &#39;from&#39; and
     *      &#39;to&#39; addresses, to expire at the &#39;expiry&#39; time.
     * @param from The address from which funds would be transferred.
     * @param to The address to which funds would be transferred. This can be
     *           the zero address to allow transfers to any address.
     * @param expiry The epoch time (seconds since 1/1/1970) at which point this
     *               authorization will no longer be valid.
     */
    function set(address from, address to, uint expiry) public onlyController {
        require(from != 0);
        authorizations[from][to] = expiry;
        emit TransferAuthorizationSet(from, to, expiry);
    }

    /**
     * @dev Returns the expiration time for the transfer authorization between the
     *      given addresses. Returns 0 if not allowed.
     * @param from The address from which funds would be transferred.
     * @param to The address to which funds would be transferred. This can be
     *           the zero address to allow transfers to any address.
     */
    function get(address from, address to) public view returns (uint) {
        return authorizations[from][to];
    }
}