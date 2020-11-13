// File: contracts/ownership/Ownable.sol

pragma solidity 0.5.16;

/// @title Ownable
/// @dev Provide a simple access control with a single authority: the owner
contract Ownable {

    // Ethereum address of current owner
    address public owner;

    // Ethereum address of the next owner
    // (has to claim ownership first to become effective owner)
    address public newOwner;

    // @dev Log event on ownership transferred
    // @param previousOwner Ethereum address of previous owner
    // @param newOwner Ethereum address of new owner
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev Forbid call by anyone but owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Restricted to owner");
        _;
    }

    /// @dev Deployer account becomes initial owner
    constructor() public {
        owner = msg.sender;
    }

    /// @dev  Transfer ownership to a new Ethereum account (safe method)
    ///       Note: the new owner has to claim his ownership to become effective owner.
    /// @param _newOwner  Ethereum address to transfer ownership to
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0), "New owner is zero");

        newOwner = _newOwner;
    }

    /// @dev  Transfer ownership to a new Ethereum account (unsafe method)
    ///       Note: It's strongly recommended to use the safe variant via transferOwnership
    ///             and claimOwnership, to prevent accidental transfers to a wrong address.
    /// @param _newOwner  Ethereum address to transfer ownership to
    function transferOwnershipUnsafe(address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0), "New owner is zero");

        _transferOwnership(_newOwner);
    }

    /// @dev  Become effective owner (if dedicated so by previous owner)
    function claimOwnership() public {
        require(msg.sender == newOwner, "Restricted to new owner");

        _transferOwnership(msg.sender);
    }

    /// @dev  Transfer ownership (internal method)
    /// @param _newOwner  Ethereum address to transfer ownership to
    function _transferOwnership(address _newOwner) private {
        if (_newOwner != owner) {
            emit OwnershipTransferred(owner, _newOwner);

            owner = _newOwner;
        }
        newOwner = address(0x0);
    }

}

// File: contracts/whitelist/Whitelist.sol

pragma solidity 0.5.16;



/// @title Whitelist
/// @author STOKR
contract Whitelist is Ownable {

    // Set of admins
    mapping(address => bool) public admins;

    // Set of Whitelisted addresses
    mapping(address => bool) public isWhitelisted;

    /// @dev Log entry on admin added to set
    /// @param admin An Ethereum address
    event AdminAdded(address indexed admin);

    /// @dev Log entry on admin removed from set
    /// @param admin An Ethereum address
    event AdminRemoved(address indexed admin);

    /// @dev Log entry on investor added set
    /// @param admin An Ethereum address
    /// @param investor An Ethereum address
    event InvestorAdded(address indexed admin, address indexed investor);

    /// @dev Log entry on investor removed from set
    /// @param admin An Ethereum address
    /// @param investor An Ethereum address
    event InvestorRemoved(address indexed admin, address indexed investor);

    /// @dev Only admin
    modifier onlyAdmin() {
        require(admins[msg.sender], "Restricted to whitelist admin");
        _;
    }

    /// @dev Add admin to set
    /// @param _admin An Ethereum address
    function addAdmin(address _admin) public onlyOwner {
        require(_admin != address(0x0), "Whitelist admin is zero");

        if (!admins[_admin]) {
            admins[_admin] = true;

            emit AdminAdded(_admin);
        }
    }

    /// @dev Remove admin from set
    /// @param _admin An Ethereum address
    function removeAdmin(address _admin) public onlyOwner {
        require(_admin != address(0x0), "Whitelist admin is zero");  // Necessary?

        if (admins[_admin]) {
            admins[_admin] = false;

            emit AdminRemoved(_admin);
        }
    }

    /// @dev Add investor to set of whitelisted addresses
    /// @param _investors A list where each entry is an Ethereum address
    function addToWhitelist(address[] calldata _investors) external onlyAdmin {
        for (uint256 i = 0; i < _investors.length; i++) {
            if (!isWhitelisted[_investors[i]]) {
                isWhitelisted[_investors[i]] = true;

                emit InvestorAdded(msg.sender, _investors[i]);
            }
        }
    }

    /// @dev Remove investor from set of whitelisted addresses
    /// @param _investors A list where each entry is an Ethereum address
    function removeFromWhitelist(address[] calldata _investors) external onlyAdmin {
        for (uint256 i = 0; i < _investors.length; i++) {
            if (isWhitelisted[_investors[i]]) {
                isWhitelisted[_investors[i]] = false;

                emit InvestorRemoved(msg.sender, _investors[i]);
            }
        }
    }

}

// File: contracts/whitelist/Whitelisted.sol

pragma solidity 0.5.16;




/// @title Whitelisted
/// @author STOKR
contract Whitelisted is Ownable {

    Whitelist public whitelist;

    /// @dev  Log entry on change of whitelist contract instance
    /// @param previous  Ethereum address of previous whitelist
    /// @param current   Ethereum address of new whitelist
    event WhitelistChange(address indexed previous, address indexed current);

    /// @dev Ensure only whitelisted addresses can call
    modifier onlyWhitelisted(address _address) {
        require(whitelist.isWhitelisted(_address), "Address is not whitelisted");
        _;
    }

    /// @dev Constructor
    /// @param _whitelist address of whitelist contract
    constructor(Whitelist _whitelist) public {
        setWhitelist(_whitelist);
    }

    /// @dev Set the address of whitelist
    /// @param _newWhitelist An Ethereum address
    function setWhitelist(Whitelist _newWhitelist) public onlyOwner {
        require(address(_newWhitelist) != address(0x0), "Whitelist address is zero");

        if (address(_newWhitelist) != address(whitelist)) {
            emit WhitelistChange(address(whitelist), address(_newWhitelist));

            whitelist = Whitelist(_newWhitelist);
        }
    }

}

// File: contracts/token/TokenRecoverable.sol

pragma solidity 0.5.16;



/// @title TokenRecoverable
/// @author STOKR
contract TokenRecoverable is Ownable {

    // Address that can do the TokenRecovery
    address public tokenRecoverer;

    /// @dev  Event emitted when the TokenRecoverer changes
    /// @param previous  Ethereum address of previous token recoverer
    /// @param current   Ethereum address of new token recoverer
    event TokenRecovererChange(address indexed previous, address indexed current);

    /// @dev Event emitted in case of a TokenRecovery
    /// @param oldAddress Ethereum address of old account
    /// @param newAddress Ethereum address of new account
    event TokenRecovery(address indexed oldAddress, address indexed newAddress);

    /// @dev Restrict operation to token recoverer
    modifier onlyTokenRecoverer() {
        require(msg.sender == tokenRecoverer, "Restricted to token recoverer");
        _;
    }

    /// @dev Constructor
    /// @param _tokenRecoverer Ethereum address of token recoverer
    constructor(address _tokenRecoverer) public {
        setTokenRecoverer(_tokenRecoverer);
    }

    /// @dev Set token recoverer
    /// @param _newTokenRecoverer Ethereum address of new token recoverer
    function setTokenRecoverer(address _newTokenRecoverer) public onlyOwner {
        require(_newTokenRecoverer != address(0x0), "New token recoverer is zero");

        if (_newTokenRecoverer != tokenRecoverer) {
            emit TokenRecovererChange(tokenRecoverer, _newTokenRecoverer);

            tokenRecoverer = _newTokenRecoverer;
        }
    }

    /// @dev Recover token
    /// @param _oldAddress address
    /// @param _newAddress address
    function recoverToken(address _oldAddress, address _newAddress) public;

}

// File: contracts/token/ERC20.sol

pragma solidity 0.5.16;


/// @title ERC20 interface
/// @dev see https://github.com/ethereum/EIPs/issues/20
interface ERC20 {

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    function allowance(address _owner, address _spender) external view returns (uint);
    function approve(address _spender, uint _value) external returns (bool);
    function transfer(address _to, uint _value) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);

}

// File: contracts/math/SafeMath.sol

pragma solidity 0.5.16;


/// @title SafeMath
/// @dev Math operations with safety checks that throw on error
library SafeMath {

    /// @dev Add two integers
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;

        assert(c >= a);

        return c;
    }

    /// @dev Subtract two integers
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);

        return a - b;
    }

    /// @dev Multiply tow integers
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;

        assert(c / a == b);

        return c;
    }

    /// @dev Floor divide two integers
    function div(uint a, uint b) internal pure returns (uint) {
        return a / b;
    }

}

// File: contracts/token/ProfitSharing.sol

pragma solidity 0.5.16;




/// @title ProfitSharing
/// @author STOKR
contract ProfitSharing is Ownable {

    using SafeMath for uint;


    // An InvestorAccount object keeps track of the investor's
    // - balance: amount of tokens he/she holds (always up-to-date)
    // - profitShare: amount of wei this token owed him/her at the last update
    // - lastTotalProfits: determines when his/her profitShare was updated
    // Note, this construction requires:
    // - totalProfits to never decrease
    // - totalSupply to be fixed
    // - profitShare of all involved parties to get updated prior to any token transfer
    // - lastTotalProfits to be set to current totalProfits upon profitShare update
    struct InvestorAccount {
        uint balance;           // token balance
        uint lastTotalProfits;  // totalProfits [wei] at the time of last profit share update
        uint profitShare;       // profit share [wei] of last update
    }


    // Investor account database
    mapping(address => InvestorAccount) public accounts;

    // Authority who is allowed to deposit profits [wei] on this
    address public profitDepositor;

    // Authority who is allowed to distribute profit shares [wei] to investors
    // (so, that they don't need to withdraw it by themselves)
    address public profitDistributor;

    // Amount of total profits [wei] stored to this token
    // In contrast to the wei balance (which may be reduced due to profit share withdrawal)
    // this value will never decrease
    uint public totalProfits;

    // As long as the total supply isn't fixed, i.e. new tokens can appear out of thin air,
    // the investors' profit shares aren't determined
    bool public totalSupplyIsFixed;

    // Total amount of tokens
    uint internal totalSupply_;


    /// @dev  Log entry on change of profit deposit authority
    /// @param previous  Ethereum address of previous profit depositor
    /// @param current   Ethereum address of new profit depositor
    event ProfitDepositorChange(
        address indexed previous,
        address indexed current
    );

    /// @dev  Log entry on change of profit distribution authority
    /// @param previous  Ethereum address of previous profit distributor
    /// @param current   Ethereum address of new profit distributor
    event ProfitDistributorChange(
        address indexed previous,
        address indexed current
    );

    /// @dev Log entry on profit deposit
    /// @param depositor Profit depositor's address
    /// @param amount Deposited profits in wei
    event ProfitDeposit(
        address indexed depositor,
        uint amount
    );

    /// @dev Log entry on profit share update
    /// @param investor Investor's address
    /// @param amount New wei amount the token owes the investor
    event ProfitShareUpdate(
        address indexed investor,
        uint amount
    );

    /// @dev Log entry on profit withdrawal
    /// @param investor Investor's address
    /// @param amount Wei amount the investor withdrew from this token
    event ProfitShareWithdrawal(
        address indexed investor,
        address indexed beneficiary,
        uint amount
    );


    /// @dev Restrict operation to profit deposit authority only
    modifier onlyProfitDepositor() {
        require(msg.sender == profitDepositor, "Restricted to profit depositor");
        _;
    }

    /// @dev Restrict operation to profit distribution authority only
    modifier onlyProfitDistributor() {
        require(msg.sender == profitDistributor, "Restricted to profit distributor");
        _;
    }

    /// @dev Restrict operation to when total supply doesn't change anymore
    modifier onlyWhenTotalSupplyIsFixed() {
        require(totalSupplyIsFixed, "Total supply may change");
        _;
    }

    /// @dev Constructor
    /// @param _profitDepositor Profit deposit authority
    constructor(address _profitDepositor, address _profitDistributor) public {
        setProfitDepositor(_profitDepositor);
        setProfitDistributor(_profitDistributor);
    }

    /// @dev Profit deposit if possible via fallback function
    function () external payable {
        require(msg.data.length == 0, "Fallback call with data");

        depositProfit();
    }

    /// @dev Change profit depositor
    /// @param _newProfitDepositor An Ethereum address
    function setProfitDepositor(address _newProfitDepositor) public onlyOwner {
        require(_newProfitDepositor != address(0x0), "New profit depositor is zero");

        if (_newProfitDepositor != profitDepositor) {
            emit ProfitDepositorChange(profitDepositor, _newProfitDepositor);

            profitDepositor = _newProfitDepositor;
        }
    }

    /// @dev Change profit distributor
    /// @param _newProfitDistributor An Ethereum address
    function setProfitDistributor(address _newProfitDistributor) public onlyOwner {
        require(_newProfitDistributor != address(0x0), "New profit distributor is zero");

        if (_newProfitDistributor != profitDistributor) {
            emit ProfitDistributorChange(profitDistributor, _newProfitDistributor);

            profitDistributor = _newProfitDistributor;
        }
    }

    /// @dev Deposit profit
    function depositProfit() public payable onlyProfitDepositor onlyWhenTotalSupplyIsFixed {
        require(totalSupply_ > 0, "Total supply is zero");

        totalProfits = totalProfits.add(msg.value);

        emit ProfitDeposit(msg.sender, msg.value);
    }

    /// @dev Profit share owing
    /// @param _investor An Ethereum address
    /// @return A positive number
    function profitShareOwing(address _investor) public view returns (uint) {
        if (!totalSupplyIsFixed || totalSupply_ == 0) {
            return 0;
        }

        InvestorAccount memory account = accounts[_investor];

        return totalProfits.sub(account.lastTotalProfits)
                           .mul(account.balance)
                           .div(totalSupply_)
                           .add(account.profitShare);
    }

    /// @dev Update profit share
    /// @param _investor An Ethereum address
    function updateProfitShare(address _investor) public onlyWhenTotalSupplyIsFixed {
        uint newProfitShare = profitShareOwing(_investor);

        accounts[_investor].lastTotalProfits = totalProfits;
        accounts[_investor].profitShare = newProfitShare;

        emit ProfitShareUpdate(_investor, newProfitShare);
    }

    /// @dev Withdraw profit share
    function withdrawProfitShare() public {
        _withdrawProfitShare(msg.sender, msg.sender);
    }

    function withdrawProfitShareTo(address payable _beneficiary) public {
        _withdrawProfitShare(msg.sender, _beneficiary);
    }

    /// @dev Withdraw profit share
    function withdrawProfitShares(address payable[] calldata _investors)
        external
        onlyProfitDistributor
    {
        for (uint i = 0; i < _investors.length; ++i) {
            _withdrawProfitShare(_investors[i], _investors[i]);
        }
    }

    /// @dev Withdraw profit share
    function _withdrawProfitShare(address _investor, address payable _beneficiary) internal {
        updateProfitShare(_investor);

        uint withdrawnProfitShare = accounts[_investor].profitShare;

        accounts[_investor].profitShare = 0;
        _beneficiary.transfer(withdrawnProfitShare);

        emit ProfitShareWithdrawal(_investor, _beneficiary, withdrawnProfitShare);
    }

}

// File: contracts/token/MintableToken.sol

pragma solidity 0.5.16;





/// @title MintableToken
/// @author STOKR
/// @dev Extension of the ERC20 compliant ProfitSharing Token
///      that allows the creation of tokens via minting for a
///      limited time period (until minting gets finished).
contract MintableToken is ERC20, ProfitSharing, Whitelisted {

    address public minter;
    uint public numberOfInvestors = 0;

    /// @dev Log entry on mint
    /// @param to Beneficiary who received the newly minted tokens
    /// @param amount The amount of minted token units
    event Minted(address indexed to, uint amount);

    /// @dev Log entry on mint finished
    event MintFinished();

    /// @dev Restrict an operation to be callable only by the minter
    modifier onlyMinter() {
        require(msg.sender == minter, "Restricted to minter");
        _;
    }

    /// @dev Restrict an operation to be executable only while minting was not finished
    modifier canMint() {
        require(!totalSupplyIsFixed, "Total supply has been fixed");
        _;
    }

    /// @dev Set minter authority
    /// @param _minter Ethereum address of minter authority
    function setMinter(address _minter) public onlyOwner {
        require(minter == address(0x0), "Minter has already been set");
        require(_minter != address(0x0), "Minter is zero");

        minter = _minter;
    }

    /// @dev Mint tokens, i.e. create tokens out of thin air
    /// @param _to Beneficiary who will receive the newly minted tokens
    /// @param _amount The amount of minted token units
    function mint(address _to, uint _amount) public onlyMinter canMint onlyWhitelisted(_to) {
        if (accounts[_to].balance == 0) {
            numberOfInvestors++;
        }

        totalSupply_ = totalSupply_.add(_amount);
        accounts[_to].balance = accounts[_to].balance.add(_amount);

        emit Minted(_to, _amount);
        emit Transfer(address(0x0), _to, _amount);
    }

    /// @dev Finish minting -- this should be irreversible
    function finishMinting() public onlyMinter canMint {
        totalSupplyIsFixed = true;

        emit MintFinished();
    }

}

// File: contracts/token/StokrToken.sol

pragma solidity 0.5.16;





/// @title StokrToken
/// @author Stokr
contract StokrToken is MintableToken, TokenRecoverable {

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    mapping(address => mapping(address => uint)) internal allowance_;

    /// @dev Log entry on self destruction of the token
    event TokenDestroyed();

    /// @dev Constructor
    /// @param _whitelist       Ethereum address of whitelist contract
    /// @param _tokenRecoverer  Ethereum address of token recoverer
    constructor(
        string memory _name,
        string memory _symbol,
        Whitelist _whitelist,
        address _profitDepositor,
        address _profitDistributor,
        address _tokenRecoverer
    )
        public
        Whitelisted(_whitelist)
        ProfitSharing(_profitDepositor, _profitDistributor)
        TokenRecoverable(_tokenRecoverer)
    {
        name = _name;
        symbol = _symbol;
    }

    /// @dev  Self destruct can only be called by crowdsale contract in case the goal wasn't reached
    function destruct() public onlyMinter {
        emit TokenDestroyed();
        selfdestruct(address(uint160(owner)));
    }

    /// @dev Recover token
    /// @param _oldAddress  address of old account
    /// @param _newAddress  address of new account
    function recoverToken(address _oldAddress, address _newAddress)
        public
        onlyTokenRecoverer
        onlyWhitelisted(_newAddress)
    {
        // Ensure that new address is *not* an existing account.
        // Check for account.profitShare is not needed because of following implication:
        //   (account.lastTotalProfits == 0) ==> (account.profitShare == 0)
        require(accounts[_newAddress].balance == 0 && accounts[_newAddress].lastTotalProfits == 0,
                "New address exists already");

        updateProfitShare(_oldAddress);

        accounts[_newAddress] = accounts[_oldAddress];
        delete accounts[_oldAddress];

        emit TokenRecovery(_oldAddress, _newAddress);
        emit Transfer(_oldAddress, _newAddress, accounts[_newAddress].balance);
    }

    /// @dev  Total supply of this token
    /// @return  Token amount
    function totalSupply() public view returns (uint) {
        return totalSupply_;
    }

    /// @dev  Token balance
    /// @param _investor  Ethereum address of token holder
    /// @return           Token amount
    function balanceOf(address _investor) public view returns (uint) {
        return accounts[_investor].balance;
    }

    /// @dev  Allowed token amount a third party trustee may transfer
    /// @param _investor  Ethereum address of token holder
    /// @param _spender   Ethereum address of third party
    /// @return           Allowed token amount
    function allowance(address _investor, address _spender) public view returns (uint) {
        return allowance_[_investor][_spender];
    }

    /// @dev  Approve a third party trustee to transfer tokens
    ///       Note: additional requirements are enforced within internal function.
    /// @param _spender  Ethereum address of third party
    /// @param _value    Maximum token amount that is allowed to get transferred
    /// @return          Always true
    function approve(address _spender, uint _value) public returns (bool) {
        return _approve(msg.sender, _spender, _value);
    }

    /// @dev  Increase the amount of tokens a third party trustee may transfer
    ///       Note: additional requirements are enforces within internal function.
    /// @param _spender  Ethereum address of third party
    /// @param _amount   Additional token amount that is allowed to get transferred
    /// @return          Always true
    function increaseAllowance(address _spender, uint _amount) public returns (bool) {
        require(allowance_[msg.sender][_spender] + _amount >= _amount, "Allowance overflow");

        return _approve(msg.sender, _spender, allowance_[msg.sender][_spender].add(_amount));
    }

    /// @dev  Decrease the amount of tokens a third party trustee may transfer
    ///       Note: additional requirements are enforces within internal function.
    /// @param _spender  Ethereum address of third party
    /// @param _amount   Reduced token amount that is allowed to get transferred
    /// @return          Always true
    function decreaseAllowance(address _spender, uint _amount) public returns (bool) {
        require(_amount <= allowance_[msg.sender][_spender], "Amount exceeds allowance");

        return _approve(msg.sender, _spender, allowance_[msg.sender][_spender].sub(_amount));
    }

    /// @dev  Check if a token transfer is possible
    /// @param _from   Ethereum address of token sender
    /// @param _to     Ethereum address of token recipient
    /// @param _value  Token amount to transfer
    /// @return        True iff a transfer with given pramaters would succeed
    function canTransfer(address _from, address _to, uint _value)
        public view returns (bool)
    {
        return totalSupplyIsFixed
            && _from != address(0x0)
            && _to != address(0x0)
            && _value <= accounts[_from].balance
            && whitelist.isWhitelisted(_from)
            && whitelist.isWhitelisted(_to);
    }

    /// @dev  Check if a token transfer by third party is possible
    /// @param _spender  Ethereum address of third party trustee
    /// @param _from     Ethereum address of token holder
    /// @param _to       Ethereum address of token recipient
    /// @param _value    Token amount to transfer
    /// @return          True iff a transfer with given pramaters would succeed
    function canTransferFrom(address _spender, address _from, address _to, uint _value)
        public view returns (bool)
    {
        return canTransfer(_from, _to, _value) && _value <= allowance_[_from][_spender];
    }

    /// @dev  Token transfer
    ///       Note: additional requirements are enforces within internal function.
    /// @param _to     Ethereum address of token recipient
    /// @param _value  Token amount to transfer
    /// @return        Always true
    function transfer(address _to, uint _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    /// @dev  Token transfer by a third party
    ///       Note: additional requirements are enforces within internal function.
    /// @param _from   Ethereum address of token holder
    /// @param _to     Ethereum address of token recipient
    /// @param _value  Token amount to transfer
    /// @return        Always true
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_value <= allowance_[_from][msg.sender], "Amount exceeds allowance");

        return _approve(_from, msg.sender, allowance_[_from][msg.sender].sub(_value))
            && _transfer(_from, _to, _value);
    }

    /// @dev  Approve a third party trustee to transfer tokens (internal implementation)
    /// @param _from     Ethereum address of token holder
    /// @param _spender  Ethereum address of third party
    /// @param _value    Maximum token amount the trustee is allowed to transfer
    /// @return          Always true
    function _approve(address _from, address _spender, uint _value)
        internal
        onlyWhitelisted(_from)
        onlyWhenTotalSupplyIsFixed
        returns (bool)
    {
        allowance_[_from][_spender] = _value;

        emit Approval(_from, _spender, _value);

        return true;
    }

    /// @dev  Token transfer (internal implementation)
    /// @param _from   Ethereum address of token sender
    /// @param _to     Ethereum address of token recipient
    /// @param _value  Token amount to transfer
    /// @return        Always true
    function _transfer(address _from, address _to, uint _value)
        internal
        onlyWhitelisted(_from)
        onlyWhitelisted(_to)
        onlyWhenTotalSupplyIsFixed
        returns (bool)
    {
        require(_to != address(0x0), "Recipient is zero");
        require(_value <= accounts[_from].balance, "Amount exceeds balance");

        updateProfitShare(_from);
        updateProfitShare(_to);

        accounts[_from].balance = accounts[_from].balance.sub(_value);
        accounts[_to].balance = accounts[_to].balance.add(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

}

// File: contracts/crowdsale/RateSourceInterface.sol

pragma solidity 0.5.16;


/// @title RateSource
/// @author STOKR
interface RateSource {

    /// @dev The current price of an Ether in EUR cents
    /// @return Current ether rate
    function etherRate() external view returns (uint);

}

// File: contracts/crowdsale/MintingCrowdsale.sol

pragma solidity 0.5.16;






/// @title MintingCrowdsale
/// @author STOKR
contract MintingCrowdsale is Ownable {
    using SafeMath for uint;

    // Maximum Time of offering period after extension
    uint constant MAXOFFERINGPERIOD = 183 days;

    // Ether rate oracle contract providing the price of an Ether in EUR cents
    RateSource public rateSource;

    // The token to be sold
    // In the following, the term "token unit" always refers to the smallest
    // and non-divisible quantum. Thus, token unit amounts are always integers.
    // One token is expected to consist of 10^18 token units.
    MintableToken public token;

    // Token amounts in token units
    // The public and the private sale are both capped (i.e. two distinct token pools)
    // The tokenRemaining variables keep track of how many token units are available
    // for the respective type of sale
    uint public tokenCapOfPublicSale;
    uint public tokenCapOfPrivateSale;
    uint public tokenRemainingForPublicSale;
    uint public tokenRemainingForPrivateSale;

    // Prices are in Euro cents (i.e. 1/100 EUR)
    uint public tokenPrice;

    // The minimum amount of tokens a purchaser has to buy via one transaction
    uint public tokenPurchaseMinimum;

    // The maximum total amount of tokens a purchaser may buy during start phase
    uint public tokenPurchaseLimit;

    // Total token purchased by investor (while purchase amount is limited)
    mapping(address => uint) public tokenPurchased;

    // Public sale period
    uint public openingTime;
    uint public closingTime;
    uint public limitEndTime;

    // Ethereum address where invested funds will be transferred to
    address payable public companyWallet;

    // Amount and receiver of reserved tokens
    uint public tokenReservePerMill;
    address public reserveAccount;

    // Wether this crowdsale was finalized or not
    bool public isFinalized = false;


    /// @dev Log entry upon token distribution event
    /// @param beneficiary Ethereum address of token recipient
    /// @param amount Number of token units
    /// @param isPublicSale Whether the distribution was via public sale
    event TokenDistribution(address indexed beneficiary, uint amount, bool isPublicSale);

    /// @dev Log entry upon token purchase event
    /// @param buyer Ethereum address of token purchaser
    /// @param value Worth in wei of purchased token amount
    /// @param amount Number of token units
    event TokenPurchase(address indexed buyer, uint value, uint amount);

    /// @dev Log entry upon opening time change event
    /// @param previous Previous opening time of sale
    /// @param current Current opening time of sale
    event OpeningTimeChange(uint previous, uint current);

    /// @dev Log entry upon closing time change event
    /// @param previous Previous closing time of sale
    /// @param current Current closing time of sale
    event ClosingTimeChange(uint previous, uint current);

    /// @dev Log entry upon finalization event
    event Finalization();


    /// @dev Constructor
    /// @param _rateSource Ether rate oracle contract
    /// @param _token The token to be sold
    /// @param _tokenCapOfPublicSale Maximum number of token units to mint in public sale
    /// @param _tokenCapOfPrivateSale Maximum number of token units to mint in private sale
    /// @param _tokenPurchaseMinimum Minimum amount of tokens an investor has to buy at once
    /// @param _tokenPurchaseLimit Maximum total token amounts individually buyable in limit phase
    /// @param _tokenPrice Price of a token in EUR cent
    /// @param _openingTime Block (Unix) timestamp of sale opening time
    /// @param _closingTime Block (Unix) timestamp of sale closing time
    /// @param _limitEndTime Block (Unix) timestamp until token purchases are limited
    /// @param _companyWallet Ethereum account who will receive sent ether
    /// @param _tokenReservePerMill Per mill amount of sold tokens to mint for reserve account
    /// @param _reserveAccount Ethereum address of reserve tokens recipient
    constructor(
        RateSource _rateSource,
        MintableToken _token,
        uint _tokenCapOfPublicSale,
        uint _tokenCapOfPrivateSale,
        uint _tokenPurchaseMinimum,
        uint _tokenPurchaseLimit,
        uint _tokenReservePerMill,
        uint _tokenPrice,
        uint _openingTime,
        uint _closingTime,
        uint _limitEndTime,
        address payable _companyWallet,
        address _reserveAccount
    )
        public
    {
        require(address(_rateSource) != address(0x0), "Rate source is zero");
        require(address(_token) != address(0x0), "Token address is zero");
        require(_token.minter() == address(0x0), "Token has another minter");
        require(_tokenCapOfPublicSale > 0, "Cap of public sale is zero");
        require(_tokenCapOfPrivateSale > 0, "Cap of private sale is zero");
        require(_tokenPurchaseMinimum <= _tokenCapOfPublicSale
                && _tokenPurchaseMinimum <= _tokenCapOfPrivateSale,
                "Purchase minimum exceeds cap");
        require(_tokenPrice > 0, "Token price is zero");
        require(_openingTime >= now, "Opening lies in the past");
        require(_closingTime >= _openingTime, "Closing lies before opening");
        require(_companyWallet != address(0x0), "Company wallet is zero");
        require(_reserveAccount != address(0x0), "Reserve account is zero");


        // Note: There are no time related requirements regarding limitEndTime.
        //       If it's below openingTime, token purchases will never be limited.
        //       If it's above closingTime, token purchases will always be limited.
        if (_limitEndTime > _openingTime) {
            // But, if there's a purchase limitation phase, the limit must be at
            // least the purchase minimum or above to make purchases possible.
            require(_tokenPurchaseLimit >= _tokenPurchaseMinimum,
                    "Purchase limit is below minimum");
        }

        // Utilize safe math to ensure the sum of three token pools does't overflow
        _tokenCapOfPublicSale.add(_tokenCapOfPrivateSale).mul(_tokenReservePerMill);

        rateSource = _rateSource;
        token = _token;
        tokenCapOfPublicSale = _tokenCapOfPublicSale;
        tokenCapOfPrivateSale = _tokenCapOfPrivateSale;
        tokenPurchaseMinimum = _tokenPurchaseMinimum;
        tokenPurchaseLimit= _tokenPurchaseLimit;
        tokenReservePerMill = _tokenReservePerMill;
        tokenPrice = _tokenPrice;
        openingTime = _openingTime;
        closingTime = _closingTime;
        limitEndTime = _limitEndTime;
        companyWallet = _companyWallet;
        reserveAccount = _reserveAccount;

        tokenRemainingForPublicSale = _tokenCapOfPublicSale;
        tokenRemainingForPrivateSale = _tokenCapOfPrivateSale;
    }



    /// @dev Fallback function: buys tokens
    function () external payable {
        require(msg.data.length == 0, "Fallback call with data");

        buyTokens();
    }

    /// @dev Distribute tokens purchased off-chain via public sale
    ///      Note: additional requirements are enforced in internal function.
    /// @param beneficiaries List of recipients' Ethereum addresses
    /// @param amounts List of token units each recipient will receive
    function distributeTokensViaPublicSale(
        address[] memory beneficiaries,
        uint[] memory amounts
    )
        public
    {
        tokenRemainingForPublicSale =
            distributeTokens(tokenRemainingForPublicSale, beneficiaries, amounts, true);
    }

    /// @dev Distribute tokens purchased off-chain via private sale
    ///      Note: additional requirements are enforced in internal function.
    /// @param beneficiaries List of recipients' Ethereum addresses
    /// @param amounts List of token units each recipient will receive
    function distributeTokensViaPrivateSale(
        address[] memory beneficiaries,
        uint[] memory amounts
    )
        public
    {
        tokenRemainingForPrivateSale =
            distributeTokens(tokenRemainingForPrivateSale, beneficiaries, amounts, false);
    }

    /// @dev Check whether the sale has closed
    /// @return True iff sale closing time has passed
    function hasClosed() public view returns (bool) {
        return now >= closingTime || tokenRemainingForPublicSale == 0;
    }

    /// @dev Check wether the sale is open
    /// @return True iff sale opening time has passed and sale is not closed yet
    function isOpen() public view returns (bool) {
        return now >= openingTime && !hasClosed();
    }

    /// @dev Determine the remaining open time of sale
    /// @return Time in seconds until sale gets closed, or 0 if sale was closed
    function timeRemaining() public view returns (uint) {
        if (hasClosed()) {
            return 0;
        }

        return closingTime - now;
    }

    /// @dev Determine the amount of sold tokens (off-chain and on-chain)
    /// @return Token units amount
    function tokenSold() public view returns (uint) {
        return (tokenCapOfPublicSale - tokenRemainingForPublicSale)
             + (tokenCapOfPrivateSale - tokenRemainingForPrivateSale);
    }

    /// @dev Purchase tokens
    function buyTokens() public payable {
        require(isOpen(), "Sale is not open");

        uint etherRate = rateSource.etherRate();

        require(etherRate > 0, "Ether rate is zero");

        // Units:  [1e-18*ether] * [cent/ether] / [cent/token] => [1e-18*token]
        uint amount = msg.value.mul(etherRate).div(tokenPrice);

        require(amount <= tokenRemainingForPublicSale, "Not enough tokens available");
        require(amount >= tokenPurchaseMinimum, "Investment is too low");

        // Is the total amount an investor can purchase with Ether limited?
        if (now < limitEndTime) {
            uint purchased = tokenPurchased[msg.sender].add(amount);

            require(purchased <= tokenPurchaseLimit, "Purchase limit reached");

            tokenPurchased[msg.sender] = purchased;
        }

        tokenRemainingForPublicSale = tokenRemainingForPublicSale.sub(amount);

        token.mint(msg.sender, amount);
        forwardFunds();

        emit TokenPurchase(msg.sender, msg.value, amount);
    }

    /// @dev Change the start time of offering period without changing its duration.
    /// @param _newOpeningTime new openingTime of the crowdsale
    function changeOpeningTime(uint _newOpeningTime) public onlyOwner {
        require(now < openingTime, "Sale has started already");
        require(now < _newOpeningTime, "OpeningTime not in the future");

        uint _newClosingTime = _newOpeningTime + (closingTime - openingTime);

        emit OpeningTimeChange(openingTime, _newOpeningTime);
        emit ClosingTimeChange(closingTime, _newClosingTime);

        openingTime = _newOpeningTime;
        closingTime = _newClosingTime;
    }

    /// @dev Extend the offering period of the crowd sale.
    /// @param _newClosingTime new closingTime of the crowdsale
    function changeClosingTime(uint _newClosingTime) public onlyOwner {
        require(!hasClosed(), "Sale has already ended");
        require(_newClosingTime > now, "ClosingTime not in the future");
        require(_newClosingTime > openingTime, "New offering is zero");
        require(_newClosingTime - openingTime <= MAXOFFERINGPERIOD, "New offering too long");

        emit ClosingTimeChange(closingTime, _newClosingTime);

        closingTime = _newClosingTime;
    }

    /// @dev Finalize, i.e. end token minting phase and enable token transfers
    function finalize() public onlyOwner {
        require(!isFinalized, "Sale has already been finalized");
        require(hasClosed(), "Sale has not closed");

        if (tokenReservePerMill > 0) {
            token.mint(reserveAccount, tokenSold().mul(tokenReservePerMill).div(1000));
        }
        token.finishMinting();
        isFinalized = true;

        emit Finalization();
    }

    /// @dev Distribute tokens purchased off-chain (in Euro) to investors
    /// @param tokenRemaining Token units available for sale
    /// @param beneficiaries Ethereum addresses of purchasers
    /// @param amounts Token unit amounts to deliver to each investor
    /// @return Token units available for sale after distribution
    function distributeTokens(
        uint tokenRemaining,
        address[] memory beneficiaries,
        uint[] memory amounts,
        bool isPublicSale
    )
        internal
        onlyOwner
        returns (uint)
    {
        require(!isFinalized, "Sale has been finalized");
        require(beneficiaries.length == amounts.length, "Lengths are different");

        for (uint i = 0; i < beneficiaries.length; ++i) {
            address beneficiary = beneficiaries[i];
            uint amount = amounts[i];

            require(amount <= tokenRemaining, "Not enough tokens available");

            tokenRemaining = tokenRemaining.sub(amount);
            token.mint(beneficiary, amount);

            emit TokenDistribution(beneficiary, amount, isPublicSale);
        }

        return tokenRemaining;
    }

    /// @dev Forward invested ether to company wallet
    function forwardFunds() internal {
        companyWallet.transfer(address(this).balance);
    }

}

// File: contracts/crowdsale/StokrCrowdsale.sol

pragma solidity 0.5.16;




/// @title StokrCrowdsale
/// @author STOKR
contract StokrCrowdsale is MintingCrowdsale {

    // Soft cap in token units
    uint public tokenGoal;

    // As long as the goal is not reached funds of purchases are held back
    // and investments are assigned to investors here to enable a refunding
    // if the goal is missed upon finalization
    mapping(address => uint) public investments;


    // Log entry upon investor refund event
    event InvestorRefund(address indexed investor, uint value);


    /// @dev Constructor
    /// @param _token The token
    /// @param _tokenCapOfPublicSale Available token units for public sale
    /// @param _tokenCapOfPrivateSale Available token units for private sale
    /// @param _tokenGoal Minimum number of sold token units to be successful
    /// @param _tokenPurchaseMinimum Minimum amount of tokens an investor has to buy at once
    /// @param _tokenPurchaseLimit Maximum total token amounts individually buyable in limit phase
    /// @param _tokenReservePerMill Additional reserve tokens in per mill of sold tokens
    /// @param _tokenPrice Price of a token in EUR cent
    /// @param _rateSource Ethereum address of ether rate setting authority
    /// @param _openingTime Block (Unix) timestamp of sale opening time
    /// @param _closingTime Block (Unix) timestamp of sale closing time
    /// @param _limitEndTime Block (Unix) timestamp until token purchases are limited
    /// @param _companyWallet Ethereum account who will receive sent ether
    /// @param _reserveAccount An address
    constructor(
        RateSource _rateSource,
        StokrToken _token,
        uint _tokenCapOfPublicSale,
        uint _tokenCapOfPrivateSale,
        uint _tokenGoal,
        uint _tokenPurchaseMinimum,
        uint _tokenPurchaseLimit,
        uint _tokenReservePerMill,
        uint _tokenPrice,
        uint _openingTime,
        uint _closingTime,
        uint _limitEndTime,
        address payable _companyWallet,
        address _reserveAccount
    )
        public
        MintingCrowdsale(
            _rateSource,
            _token,
            _tokenCapOfPublicSale,
            _tokenCapOfPrivateSale,
            _tokenPurchaseMinimum,
            _tokenPurchaseLimit,
            _tokenReservePerMill,
            _tokenPrice,
            _openingTime,
            _closingTime,
            _limitEndTime,
            _companyWallet,
            _reserveAccount
        )
    {
        require(
            _tokenGoal <= _tokenCapOfPublicSale + _tokenCapOfPrivateSale,
            "Goal is not attainable"
        );

        tokenGoal = _tokenGoal;
    }

    /// @dev Wether the goal of sold tokens was reached or not
    /// @return True if the sale can be considered successful
    function goalReached() public view returns (bool) {
        return tokenSold() >= tokenGoal;
    }

    /// @dev Investors can claim refunds here if crowdsale was unsuccessful
    function distributeRefunds(address payable[] calldata _investors) external {
        for (uint i = 0; i < _investors.length; ++i) {
            refundInvestor(_investors[i]);
        }
    }

    /// @dev Investors can claim refunds here if crowdsale was unsuccessful
    function claimRefund() public {
        refundInvestor(msg.sender);
    }

    /// @dev Overwritten. Kill the token if goal was missed
    function finalize() public onlyOwner {
        super.finalize();

        if (!goalReached()) {
            StokrToken(address(token)).destruct();
        }
    }

    function distributeTokensViaPublicSale(
        address[] memory beneficiaries,
        uint[] memory amounts
    )
        public
    {
        super.distributeTokensViaPublicSale(beneficiaries, amounts);
        // The goal may get reached due to token distribution,
        // so forward any accumulated funds to the company wallet.
        forwardFunds();
    }

    function distributeTokensViaPrivateSale(
        address[] memory beneficiaries,
        uint[] memory amounts
    )
        public
    {
        super.distributeTokensViaPrivateSale(beneficiaries, amounts);
        // The goal may get reached due to token distribution,
        // so forward any accumulated funds to the company wallet.
        forwardFunds();
    }

    /// @dev Overwritten. Funds are held back until goal was reached
    function forwardFunds() internal {
        if (goalReached()) {
            super.forwardFunds();
        }
        else {
            investments[msg.sender] = investments[msg.sender].add(msg.value);
        }
    }

    /// @dev Refund an investor if the sale was not successful
    /// @param _investor Ethereum address of investor
    function refundInvestor(address payable _investor) internal {
        require(isFinalized, "Sale has not been finalized");
        require(!goalReached(), "Goal was reached");

        uint investment = investments[_investor];

        if (investment > 0) {
            investments[_investor] = 0;
            _investor.transfer(investment);

            emit InvestorRefund(_investor, investment);
        }
    }

}

// File: contracts/crowdsale/StokrCrowdsaleFactory.sol

pragma solidity 0.5.16;




// Helper contract to deploy a new StokrCrowdsale contract

contract StokrCrowdsaleFactory {

    function createNewCrowdsale(
        StokrToken token,
        uint tokenPrice,
        uint[6] calldata amounts,    // [tokenCapOfPublicSale, tokenCapOfPrivateSale, tokenGoal,
                                     //  tokenPurchaseMinimum, tokenPurchaseLimit,
                                     //  tokenReservePerMill]
        uint[3] calldata period,     // [openingTime, closingTime, limitEndTime]
        address[2] calldata wallets  // [companyWallet, reserveAccount]
    )
        external
        returns (StokrCrowdsale)
    {
        StokrCrowdsale crowdsale = new StokrCrowdsale(
            RateSource(msg.sender),         // rateSource
            token,
            amounts[0],                     // tokenCapOfPublicSale
            amounts[1],                     // tokenCapOfPrivateSale
            amounts[2],                     // tokenGoal
            amounts[3],                     // tokenPurchaseMinimum
            amounts[4],                     // tokenPurchaseLimit
            amounts[5],                     // tokenReservePerMill
            tokenPrice,                     // tokenPrice
            period[0],                      // openingTime
            period[1],                      // closingTime
            period[2],                      // limitEndTime
            address(uint160(wallets[0])),   // companyWallet
            wallets[1]);                    // reserveAccount

        crowdsale.transferOwnershipUnsafe(msg.sender);

        return crowdsale;
    }

}