// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


import "./SafeMathUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import { StableMath } from "./StableMath.sol";
import "./IArbToken.sol";
import "./IUSDs.sol";
import "./aeERC20.sol";

/**
 * NOTE that this is an ERC20 token but the invariant that the sum of
 * balanceOf(x) for all x is not >= totalSupply(). This is a consequence of the
 * rebasing design. Any integrations with USDs should be aware.
 */

 /**
  * @title USDs Token Contract on Arbitrum (L2)
  * @dev ERC20 compatible contract for USDs
  * @dev support rebase feature
  * @dev inspired by OUSD: https://github.com/OriginProtocol/origin-dollar/blob/master/contracts/contracts/token/OUSD.sol
  * @author Sperax Foundation
  */
contract USDsL2 is aeERC20, OwnableUpgradeable, IArbToken, IUSDs, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using StableMath for uint256;

    event TotalSupplyUpdated(
        uint256 totalSupply,
        uint256 rebasingCredits,
        uint256 rebasingCreditsPerToken
    );
    event ArbitrumGatewayL1TokenChanged(address gateway, address l1token);

    enum RebaseOptions { NotSet, OptOut, OptIn }

    uint256 private constant MAX_SUPPLY = ~uint128(0); // (2^128) - 1
    uint256 internal _totalSupply;    // the total supply of USDs
    uint256 public totalMinted;    // the total num of USDs minted so far
    uint256 public totalBurnt;     // the total num of USDs burnt so far
    uint256 public mintedViaGateway;    // the total num of USDs minted so far
    uint256 public burntViaGateway;     // the total num of USDs burnt so far
    mapping(address => mapping(address => uint256)) private _allowances;
    address public vaultAddress;    // the address where (i) all collaterals of USDs protocol reside, e.g. USDT, USDC, ETH, etc and (ii) major actions like USDs minting are initiated
    // an user's balance of USDs is based on her balance of "credits."
    // in a rebase process, her USDs balance will change according to her credit balance and the rebase ratio
    mapping(address => uint256) private _creditBalances;
    // the total number of credits of the USDs protocol
    uint256 public rebasingCredits;
    // the rebase ratio = num of credits / num of USDs
    uint256 public rebasingCreditsPerToken;
    // Frozen address/credits are non rebasing (value is held in contracts which
    // do not receive yield unless they explicitly opt in)
    uint256 public nonRebasingSupply;   // num of USDs that are not affected by rebase
    mapping(address => uint256) public nonRebasingCreditsPerToken; // the rebase ratio of non-rebasing accounts just before they opt out
    mapping(address => RebaseOptions) public rebaseState;          // the rebase state of each account, i.e. opt in or opt out

    // Arbitrum Bridge
    address public l2Gateway;
    address public override l1Address;

    function initialize(
        string memory _nameArg,
        string memory _symbolArg,
        address _vaultAddress,
        address _l2Gateway,
        address _l1Address
    ) public initializer {
        aeERC20._initialize(_nameArg, _symbolArg, 18);
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        rebasingCreditsPerToken = 1e18;
        vaultAddress = _vaultAddress;
        l2Gateway = _l2Gateway;
        l1Address = _l1Address;
    }

    /**
     * @dev change the vault address
     * @param newVault the new vault address
     */
    function changeVault(address newVault) external onlyOwner {
        vaultAddress = newVault;
    }

    function version() public pure returns (uint) {
		return 2;
	}
    
    /**
     * @dev Verifies that the caller is the Savings Manager contract
     */
    modifier onlyVault() {
        require(vaultAddress == msg.sender, "Caller is not the Vault");
        _;
    }

    /**
     * @dev check the current total supply of USDs
     * @return The total supply of USDs.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the USDs balance of the specified address.
     * @param _account Address to query the balance of.
     * @return A uint256 representing the _amount of base units owned by the
     *         specified address.
     */
    function balanceOf(address _account) public view override returns (uint256) {
        if (_creditBalances[_account] == 0) return 0;
        return
            _creditBalances[_account].divPrecisely(_creditsPerToken(_account));
    }

    /**
     * @dev Gets the credits balance of the specified address.
     * @param _account The address to query the balance of.
     * @return (uint256, uint256) Credit balance and credits per token of the
     *         address
     */
    function creditsBalanceOf(address _account)
        public
        view
        returns (uint256, uint256)
    {
        return (_creditBalances[_account], _creditsPerToken(_account));
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param _to the address to transfer to.
     * @param _value the _amount to be transferred.
     * @return true on success.
     */
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_to != address(0), "Transfer to zero address");
        require(
            _value <= balanceOf(msg.sender),
            "Transfer greater than balance"
        );

        _executeTransfer(msg.sender, _to, _value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param _from The address you want to send tokens from.
     * @param _to The address you want to transfer to.
     * @param _value The _amount of tokens to be transferred.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        require(_to != address(0), "Transfer to zero address");
        require(_value <= balanceOf(_from), "Transfer greater than balance");

        // notice: allowance balnce check depends on "sub" non-negative check
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(
            _value
        );

        _executeTransfer(_from, _to, _value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev Update the count of non rebasing credits in response to a transfer
     * @param _from The address you want to send tokens from.
     * @param _to The address you want to transfer to.
     * @param _value Amount of USDs to transfer
     */
    function _executeTransfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        bool isNonRebasingTo = _isNonRebasingAccount(_to);
        bool isNonRebasingFrom = _isNonRebasingAccount(_from);

        // Credits deducted and credited might be different due to the
        // differing creditsPerToken used by each account
        uint256 creditsCredited = _value.mulTruncateCeil(_creditsPerToken(_to));
        uint256 creditsDeducted = _value.mulTruncateCeil(_creditsPerToken(_from));

        _creditBalances[_from] = _creditBalances[_from].sub(
            creditsDeducted,
            "Transfer amount exceeds balance"
        );
        _creditBalances[_to] = _creditBalances[_to].add(creditsCredited);

        // update global stats
        if (isNonRebasingTo && !isNonRebasingFrom) {
            // Transfer to non-rebasing account from rebasing account, credits
            // are removed from the non rebasing tally
            nonRebasingSupply = nonRebasingSupply.add(_value);
            // Update rebasingCredits by subtracting the deducted amount
            rebasingCredits = rebasingCredits.sub(creditsDeducted);
        } else if (!isNonRebasingTo && isNonRebasingFrom) {
            // Transfer to rebasing account from non-rebasing account
            // Decreasing non-rebasing credits by the amount that was sent
            nonRebasingSupply = nonRebasingSupply.sub(_value);
            // Update rebasingCredits by adding the credited amount
            rebasingCredits = rebasingCredits.add(creditsCredited);
        }
    }

    /**
     * @dev Function to check the _amount of tokens that an owner has allowed to a _spender.
     * @param _owner The address which owns the funds.
     * @param _spender The address which will spend the funds.
     * @return The number of tokens still available for the _spender.
     */
    function allowance(address _owner, address _spender)
        public
        view
        override returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    /**
     * @dev Approve the passed address to spend the specified _amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param _spender The address which will spend the funds.
     * @param _value The _amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public override returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Increase the _amount of tokens that an owner has allowed to a _spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param _spender The address which will spend the funds.
     * @param _addedValue The _amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][_spender] = _allowances[msg.sender][_spender]
            .add(_addedValue);
        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the _amount of tokens that an owner has allowed to a _spender.
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The _amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 oldValue = _allowances[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            _allowances[msg.sender][_spender] = 0;
        } else {
            _allowances[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Mints new USDs tokens, increasing totalSupply.
     * @param _account the account address the newly minted USDs will be attributed to
     * @param _amount the amount of USDs that will be minted
     */
    function mint(address _account, uint256 _amount) external override onlyVault {
        _mint(_account, _amount);
    }

    /**
     * @dev Creates `_amount` tokens and assigns them to `_account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     * @param _account the account address the newly minted USDs will be attributed to
     * @param _amount the amount of USDs that will be minted
     */
    function _mint(address _account, uint256 _amount) internal override nonReentrant {
        require(_account != address(0), "Mint to the zero address");

        bool isNonRebasingAccount = _isNonRebasingAccount(_account);

        uint256 creditAmount = _amount.mulTruncateCeil(_creditsPerToken(_account));
        _creditBalances[_account] = _creditBalances[_account].add(creditAmount);

        // notice: If the account is non rebasing and doesn't have a set creditsPerToken
        //          then set it i.e. this is a mint from a fresh contract

        // update global stats
        if (isNonRebasingAccount) {
            nonRebasingSupply = nonRebasingSupply.add(_amount);
        } else {
            rebasingCredits = rebasingCredits.add(creditAmount);
        }

        _totalSupply = _totalSupply.add(_amount);
        totalMinted = totalMinted.add(_amount);

        require(_totalSupply < MAX_SUPPLY, "Max supply");

        emit Transfer(address(0), _account, _amount);
    }

    /**
     * @dev Burns tokens, decreasing totalSupply.
     */
    function burn(address account, uint256 amount) external override onlyVault {
        _burn(account, amount);
    }

    /**
     * @dev Destroys `_amount` tokens from `_account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `_account` cannot be the zero address.
     * - `_account` must have at least `_amount` tokens.
     */
    function _burn(address _account, uint256 _amount) internal override nonReentrant {
        require(_account != address(0), "Burn from the zero address");
        if (_amount == 0) {
            return;
        }

        bool isNonRebasingAccount = _isNonRebasingAccount(_account);
        uint256 creditAmount = _amount.mulTruncateCeil(_creditsPerToken(_account));
        uint256 currentCredits = _creditBalances[_account];

        // Remove the credits, burning rounding errors
        if (
            currentCredits == creditAmount || currentCredits - 1 == creditAmount
        ) {
            // Handle dust from rounding
            _creditBalances[_account] = 0;
        } else if (currentCredits > creditAmount) {
            _creditBalances[_account] = _creditBalances[_account].sub(
                creditAmount
            );
        } else {
            revert("Remove exceeds balance");
        }

        // Remove from the credit tallies and non-rebasing supply
        if (isNonRebasingAccount) {
            nonRebasingSupply = nonRebasingSupply.sub(_amount);
        } else {
            rebasingCredits = rebasingCredits.sub(creditAmount);
        }

        _totalSupply = _totalSupply.sub(_amount);
        totalBurnt = totalBurnt.add(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    /**
     * @dev Get the credits per token for an account. Returns a fixed amount
     *      if the account is non-rebasing.
     * @param _account Address of the account.
     */
    function _creditsPerToken(address _account)
        internal
        view
        returns (uint256)
    {
        if (nonRebasingCreditsPerToken[_account] != 0) {
            return nonRebasingCreditsPerToken[_account];
        } else {
            return rebasingCreditsPerToken;
        }
    }

    /**
     * @dev Is an account using rebasing accounting or non-rebasing accounting?
     *      Also, ensure contracts are non-rebasing if they have not opted in.
     * @param _account Address of the account.
     */
    function _isNonRebasingAccount(address _account) internal returns (bool) {
        bool isContract = AddressUpgradeable.isContract(_account);
        if (isContract && rebaseState[_account] == RebaseOptions.NotSet) {
            _ensureRebasingMigration(_account);
        }
        return nonRebasingCreditsPerToken[_account] > 0;
    }

    /**
     * @dev Ensures internal account for rebasing and non-rebasing credits and
     *      supply is updated following deployment of frozen yield change.
     */
    function _ensureRebasingMigration(address _account) internal {
        if (nonRebasingCreditsPerToken[_account] == 0) {
            // Set fixed credits per token for this account
            nonRebasingCreditsPerToken[_account] = rebasingCreditsPerToken;
            // Update non rebasing supply
            nonRebasingSupply = nonRebasingSupply.add(balanceOf(_account));
            // Update credit tallies
            rebasingCredits = rebasingCredits.sub(_creditBalances[_account]);
        }
    }

    /**
     * @dev Add a contract address to the non rebasing exception list. I.e. the
     * address's balance will be part of rebases so the account will be exposed
     * to upside and downside.
     */
    function rebaseOptIn(address toOptIn) public onlyOwner nonReentrant {
        require(_isNonRebasingAccount(toOptIn), "Account has not opted out");

        // Convert balance into the same amount at the current exchange rate
        uint256 newCreditBalance = _creditBalances[toOptIn]
            .mul(rebasingCreditsPerToken)
            .div(_creditsPerToken(toOptIn));

        // Decreasing non rebasing supply
        nonRebasingSupply = nonRebasingSupply.sub(balanceOf(toOptIn));

        _creditBalances[toOptIn] = newCreditBalance;

        // Increase rebasing credits, totalSupply remains unchanged so no
        // adjustment necessary
        rebasingCredits = rebasingCredits.add(_creditBalances[toOptIn]);

        rebaseState[toOptIn] = RebaseOptions.OptIn;

        // Delete any fixed credits per token
        delete nonRebasingCreditsPerToken[toOptIn];
    }

    /**
     * @dev Remove a contract address to the non rebasing exception list.
     */
    function rebaseOptOut(address toOptOut) public onlyOwner nonReentrant {
        require(!_isNonRebasingAccount(toOptOut), "Account has not opted in");

        // Increase non rebasing supply
        nonRebasingSupply = nonRebasingSupply.add(balanceOf(toOptOut));
        // Set fixed credits per token
        nonRebasingCreditsPerToken[toOptOut] = rebasingCreditsPerToken;

        // Decrease rebasing credits, total supply remains unchanged so no
        // adjustment necessary
        rebasingCredits = rebasingCredits.sub(_creditBalances[toOptOut]);

        // Mark explicitly opted out of rebasing
        rebaseState[toOptOut] = RebaseOptions.OptOut;
    }

    /**
     * @dev The rebase function. Modify the supply without minting new tokens. This uses a change in
     *      the exchange rate between "credits" and USDs tokens to change balances.
     * @param _newTotalSupply New total supply of USDs.
     */
    function changeSupply(uint256 _newTotalSupply)
        external
        override
        onlyVault
        nonReentrant
    {
        require(_totalSupply > 0, "Cannot increase 0 supply");

        // special case: if the total supply remains the same
        if (_totalSupply == _newTotalSupply) {
            emit TotalSupplyUpdated(
                _totalSupply,
                rebasingCredits,
                rebasingCreditsPerToken
            );
            return;
        }

        // check if the new total supply surpasses the MAX
        _totalSupply = _newTotalSupply > MAX_SUPPLY
            ? MAX_SUPPLY
            : _newTotalSupply;
        // calculate the new rebase ratio, i.e. credits per token
        rebasingCreditsPerToken = rebasingCredits.divPrecisely(
            _totalSupply.sub(nonRebasingSupply)
        );

        require(rebasingCreditsPerToken > 0, "Invalid change in supply");

        // re-calculate the total supply to accomodate precision error
        _totalSupply = rebasingCredits
            .divPrecisely(rebasingCreditsPerToken)
            .add(nonRebasingSupply);

        emit TotalSupplyUpdated(
            _totalSupply,
            rebasingCredits,
            rebasingCreditsPerToken
        );
    }

    function mintedViaUsers() external view override returns (uint256) {
        return totalMinted.sub(mintedViaGateway);
    }

    function burntViaUsers() external view override returns (uint256) {
        return totalBurnt.sub(burntViaGateway);
    }

    // Arbitrum Bridge
    /**
     * @notice change the arbitrum bridge address and corresponding L1 token address
     * @dev normally this function should not be called after token registration
     * @param newL2Gateway the new bridge address
     * @param newL1Address the new router address
     */
    function changeArbToken(address newL2Gateway, address newL1Address) external onlyOwner {
        l2Gateway = newL2Gateway;
        l1Address = newL1Address;
        emit ArbitrumGatewayL1TokenChanged(l2Gateway, l1Address);
    }

    modifier onlyGateway() {
        require(msg.sender == l2Gateway, "ONLY_l2GATEWAY");
        _;
    }

    function bridgeMint(address account, uint256 amount) external override onlyGateway {
        _mint(account, amount);
        mintedViaGateway = mintedViaGateway.add(mintedViaGateway);
    }

    function bridgeBurn(address account, uint256 amount) external override onlyGateway {
        _burn(account, amount);
        burntViaGateway = burntViaGateway.add(burntViaGateway);
    }
}