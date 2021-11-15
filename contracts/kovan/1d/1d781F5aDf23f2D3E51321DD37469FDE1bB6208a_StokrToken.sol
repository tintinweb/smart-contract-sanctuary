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

pragma solidity 0.5.16;

import "../whitelist/Whitelisted.sol";
import "./ERC20.sol";
import "./ProfitSharing.sol";


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

pragma solidity 0.5.16;

import "../math/SafeMath.sol";
import "../ownership/Ownable.sol";


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

pragma solidity 0.5.16;

import "../whitelist/Whitelisted.sol";
import "./TokenRecoverable.sol";
import "./MintableToken.sol";


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

pragma solidity 0.5.16;

import "../ownership/Ownable.sol";


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

pragma solidity 0.5.16;

import "../ownership/Ownable.sol";


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

pragma solidity 0.5.16;

import "../ownership/Ownable.sol";
import "./Whitelist.sol";


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

