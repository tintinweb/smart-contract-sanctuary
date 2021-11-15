// SPDX-License-Identifier: Apache-2.0
// WARNING: This has been validated for yearn vaults version 4.2, do not use for lower or higher
//          versions without review
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IYearnVault.sol";
import "./YVaultAssetProxy.sol";

/// @author Element Finance
/// @title Yearn Vault Asset Proxy
contract YVaultV4AssetProxy is YVaultAssetProxy {
    /// @notice Constructs this contract by calling into the super constructor
    /// @param vault_ The yearn v2 vault, must be version 0.4.2
    /// @param _token The underlying token.
    ///               This token should revert in the event of a transfer failure.
    /// @param _name The name of the token created
    /// @param _symbol The symbol of the token created
    constructor(
        address vault_,
        IERC20 _token,
        string memory _name,
        string memory _symbol
    ) YVaultAssetProxy(vault_, _token, _name, _symbol) {}

    /// @notice Overrides the version checking to check for 0.4.2 instead
    /// @param _vault The yearn vault address
    /// @dev This function can be overridden by an inheriting upgrade contract
    function _versionCheck(IYearnVault _vault) internal override view {
        string memory apiVersion = _vault.apiVersion();
        require(_stringEq(apiVersion, "0.4.2"), "Unsupported Version");
    }

    /// @notice Converts an input of shares to it's output of underlying or an input
    ///      of underlying to an output of shares, using yearn 's deposit pricing
    /// @param amount the amount of input, shares if 'sharesIn == true' underlying if not
    /// @param sharesIn true to convert from yearn shares to underlying, false to convert from
    ///                 underlying to yearn shares
    /// @dev WARNING - Fails for 0.3.2-0.3.5, please only use with 0.4.2
    /// @return The converted output of either underlying or yearn shares
    function _yearnDepositConverter(uint256 amount, bool sharesIn)
        internal
        override
        view
        returns (uint256)
    {
        // Load the yearn price per share
        uint256 pricePerShare = vault.pricePerShare();
        // If we are converted shares to underlying
        if (sharesIn) {
            // If the input is shares we multiply by the price per share
            return (pricePerShare * amount) / 10**vaultDecimals;
        } else {
            // If the input is in underlying we divide by price per share
            return (amount * 10**vaultDecimals) / (pricePerShare + 1);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IERC20 {
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    // Note this is non standard but nearly all ERC20 have exposed decimal functions
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IYearnVault is IERC20 {
    function deposit(uint256, address) external returns (uint256);

    function withdraw(
        uint256,
        address,
        uint256
    ) external returns (uint256);

    // Returns the amount of underlying per each unit [1e18] of yearn shares
    function pricePerShare() external view returns (uint256);

    function governance() external view returns (address);

    function setDepositLimit(uint256) external;

    function totalSupply() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function apiVersion() external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
// WARNING: This has been validated for yearn vaults up to version 0.2.11.
// Using this code with any later version can be unsafe.
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IYearnVault.sol";
import "./WrappedPosition.sol";

/// @author Element Finance
/// @title Yearn Vault v1 Asset Proxy
contract YVaultAssetProxy is WrappedPosition {
    IYearnVault public immutable vault;
    uint8 public immutable vaultDecimals;

    // This contract allows deposits to a reserve which can
    // be used to short circuit the deposit process and save gas

    // The following mapping tracks those non-transferable deposits
    mapping(address => uint256) public reserveBalances;
    // These variables store the token balances of this contract and
    // should be packed by solidity into a single slot.
    uint128 public reserveUnderlying;
    uint128 public reserveShares;
    // This is the total amount of reserve deposits
    uint256 public reserveSupply;

    /// @notice Constructs this contract and stores needed data
    /// @param vault_ The yearn v2 vault
    /// @param _token The underlying token.
    ///               This token should revert in the event of a transfer failure.
    /// @param _name The name of the token created
    /// @param _symbol The symbol of the token created
    constructor(
        address vault_,
        IERC20 _token,
        string memory _name,
        string memory _symbol
    ) WrappedPosition(_token, _name, _symbol) {
        vault = IYearnVault(vault_);
        _token.approve(vault_, type(uint256).max);
        uint8 localVaultDecimals = IERC20(vault_).decimals();
        vaultDecimals = localVaultDecimals;
        require(
            uint8(_token.decimals()) == localVaultDecimals,
            "Inconsistent decimals"
        );
        // We check that this is a compatible yearn version
        _versionCheck(IYearnVault(vault_));
    }

    /// @notice An override-able version checking function, reverts if the vault has the wrong version
    /// @param _vault The yearn vault address
    /// @dev This function can be overridden by an inheriting upgrade contract
    function _versionCheck(IYearnVault _vault) internal virtual view {
        string memory apiVersion = _vault.apiVersion();
        require(
            _stringEq(apiVersion, "0.3.0") ||
                _stringEq(apiVersion, "0.3.1") ||
                _stringEq(apiVersion, "0.3.2") ||
                _stringEq(apiVersion, "0.3.3") ||
                _stringEq(apiVersion, "0.3.4") ||
                _stringEq(apiVersion, "0.3.5"),
            "Unsupported Version"
        );
    }

    /// @notice checks if two strings are equal
    /// @param s1 string one
    /// @param s2 string two
    /// @return bool whether they are equal
    function _stringEq(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        bytes32 h1 = keccak256(abi.encodePacked(s1));
        bytes32 h2 = keccak256(abi.encodePacked(s2));
        return (h1 == h2);
    }

    /// @notice This function allows a user to deposit to the reserve
    ///      Note - there's no incentive to do so. You could earn some
    ///      interest but less interest than yearn. All deposits use
    ///      the underlying token.
    /// @param _amount The amount of underlying to deposit
    function reserveDeposit(uint256 _amount) external {
        // Transfer from user, note variable 'token' is the immutable
        // inherited from the abstract WrappedPosition contract.
        token.transferFrom(msg.sender, address(this), _amount);
        // Load the reserves
        (uint256 localUnderlying, uint256 localShares) = _getReserves();
        // Calculate the total reserve value
        uint256 totalValue = localUnderlying;
        totalValue += _yearnDepositConverter(localShares, true);
        // If this is the first deposit we need different logic
        uint256 localReserveSupply = reserveSupply;
        uint256 mintAmount;
        if (localReserveSupply == 0) {
            // If this is the first mint the tokens are exactly the supplied underlying
            mintAmount = _amount;
        } else {
            // Otherwise we mint the proportion that this increases the value held by this contract
            mintAmount = (localReserveSupply * _amount) / totalValue;
        }

        // This hack means that the contract will never have zero balance of underlying
        // which levels the gas expenditure of the transfer to this contract. Permanently locks
        // the smallest possible unit of the underlying.
        if (localUnderlying == 0 && localShares == 0) {
            _amount -= 1;
        }
        // Set the reserves that this contract has more underlying
        _setReserves(localUnderlying + _amount, localShares);
        // Note that the sender has deposited and increase reserveSupply
        reserveBalances[msg.sender] += mintAmount;
        reserveSupply = localReserveSupply + mintAmount;
    }

    /// @notice This function allows a holder of reserve balance to withdraw their share
    /// @param _amount The number of reserve shares to withdraw
    function reserveWithdraw(uint256 _amount) external {
        // Remove 'amount' from the balances of the sender. Because this is 8.0 it will revert on underflow
        reserveBalances[msg.sender] -= _amount;
        // We load the reserves
        (uint256 localUnderlying, uint256 localShares) = _getReserves();
        uint256 localReserveSupply = reserveSupply;
        // Then we calculate the proportion of the shares to redeem
        uint256 userShares = (localShares * _amount) / localReserveSupply;
        // First we withdraw the proportion of shares tokens belonging to the caller
        uint256 freedUnderlying = vault.withdraw(userShares, address(this), 0);
        // We calculate the amount of underlying to send
        uint256 userUnderlying = (localUnderlying * _amount) /
            localReserveSupply;

        // We then store the updated reserve amounts
        _setReserves(
            localUnderlying - userUnderlying,
            localShares - userShares
        );
        // We note a reduction in local supply
        reserveSupply = localReserveSupply - _amount;

        // We send the redemption underlying to the caller
        // Note 'token' is an immutable from shares
        token.transfer(msg.sender, freedUnderlying + userUnderlying);
    }

    /// @notice Makes the actual deposit into the yearn vault
    ///         Tries to use the local balances before depositing
    /// @return Tuple (the shares minted, amount underlying used)
    function _deposit() internal override returns (uint256, uint256) {
        //Load reserves
        (uint256 localUnderlying, uint256 localShares) = _getReserves();
        // Get the amount deposited
        uint256 amount = token.balanceOf(address(this)) - localUnderlying;
        // fixing for the fact there's an extra underlying
        if (localUnderlying != 0 || localShares != 0) {
            amount -= 1;
        }
        // Calculate the amount of shares the amount deposited is worth
        uint256 neededShares = _yearnDepositConverter(amount, false);

        // If we have enough in local reserves we don't call out for deposits
        if (localShares > neededShares) {
            // We set the reserves
            _setReserves(localUnderlying + amount, localShares - neededShares);
            // And then we short circuit execution and return
            return (neededShares, amount);
        }
        // Deposit and get the shares that were minted to this
        uint256 shares = vault.deposit(localUnderlying + amount, address(this));

        // calculate the user share
        uint256 userShare = (amount * shares) / (localUnderlying + amount);

        // We set the reserves
        _setReserves(0, localShares + shares - userShare);
        // Return the amount of shares the user has produced, and the amount used for it.
        return (userShare, amount);
    }

    /// @notice Withdraw the number of shares and will short circuit if it can
    /// @param _shares The number of shares to withdraw
    /// @param _destination The address to send the output funds
    /// @param _underlyingPerShare The possibly precomputed underlying per share
    function _withdraw(
        uint256 _shares,
        address _destination,
        uint256 _underlyingPerShare
    ) internal override returns (uint256) {
        // If we do not have it we load the price per share
        if (_underlyingPerShare == 0) {
            _underlyingPerShare = _pricePerShare();
        }
        // We load the reserves
        (uint256 localUnderlying, uint256 localShares) = _getReserves();
        // Calculate the amount of shares the amount deposited is worth
        uint256 needed = (_shares * _pricePerShare()) / (10**vaultDecimals);
        // If we have enough underlying we don't have to actually withdraw
        if (needed < localUnderlying) {
            // We set the reserves to be the new reserves
            _setReserves(localUnderlying - needed, localShares + _shares);
            // Then transfer needed underlying to the destination
            // 'token' is an immutable in WrappedPosition
            token.transfer(_destination, needed);
            // Short circuit and return
            return (needed);
        }
        // If we don't have enough local reserves we do the actual withdraw
        // Withdraws shares from the vault. Max loss is set at 100% as
        // the minimum output value is enforced by the calling
        // function in the WrappedPosition contract.
        uint256 amountReceived = vault.withdraw(
            _shares + localShares,
            address(this),
            10000
        );

        // calculate the user share
        uint256 userShare = (_shares * amountReceived) /
            (localShares + _shares);

        _setReserves(localUnderlying + amountReceived - userShare, 0);
        // Transfer the underlying to the destination 'token' is an immutable in WrappedPosition
        token.transfer(_destination, userShare);
        // Return the amount of underlying
        return userShare;
    }

    /// @notice Get the underlying amount of tokens per shares given
    /// @param _amount The amount of shares you want to know the value of
    /// @return Value of shares in underlying token
    function _underlying(uint256 _amount)
        internal
        override
        view
        returns (uint256)
    {
        return (_amount * _pricePerShare()) / (10**vaultDecimals);
    }

    /// @notice Get the price per share in the vault
    /// @return The price per share in units of underlying;
    function _pricePerShare() internal view returns (uint256) {
        return vault.pricePerShare();
    }

    /// @notice Function to reset approvals for the proxy
    function approve() external {
        token.approve(address(vault), 0);
        token.approve(address(vault), type(uint256).max);
    }

    /// @notice Helper to get the reserves with one sload
    /// @return Tuple (reserve underlying, reserve shares)
    function _getReserves() internal view returns (uint256, uint256) {
        return (uint256(reserveUnderlying), uint256(reserveShares));
    }

    /// @notice Helper to set reserves using one sstore
    /// @param _newReserveUnderlying The new reserve of underlying
    /// @param _newReserveShares The new reserve of wrapped position shares
    function _setReserves(
        uint256 _newReserveUnderlying,
        uint256 _newReserveShares
    ) internal {
        reserveUnderlying = uint128(_newReserveUnderlying);
        reserveShares = uint128(_newReserveShares);
    }

    /// @notice Converts an input of shares to it's output of underlying or an input
    ///      of underlying to an output of shares, using yearn 's deposit pricing
    /// @param amount the amount of input, shares if 'sharesIn == true' underlying if not
    /// @param sharesIn true to convert from yearn shares to underlying, false to convert from
    ///                 underlying to yearn shares
    /// @dev WARNING - In yearn 0.3.1 - 0.3.5 this is an exact match for deposit logic
    ///                but not withdraw logic in versions 0.3.2-0.3.5. In versions 0.4.0+
    ///                it is not a match for yearn deposit ratios.
    /// @return The converted output of either underlying or yearn shares
    function _yearnDepositConverter(uint256 amount, bool sharesIn)
        internal
        virtual
        view
        returns (uint256)
    {
        // Load the yearn total supply and assets
        uint256 yearnTotalSupply = vault.totalSupply();
        uint256 yearnTotalAssets = vault.totalAssets();
        // If we are converted shares to underlying
        if (sharesIn) {
            // then we get the fraction of yearn shares this is and multiply by assets
            return (yearnTotalAssets * amount) / yearnTotalSupply;
        } else {
            // otherwise we figure out the faction of yearn assets this is and see how
            // many assets we get out.
            return (yearnTotalSupply * amount) / yearnTotalAssets;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IWrappedPosition.sol";

import "./libraries/ERC20Permit.sol";

/// @author Element Finance
/// @title Wrapped Position Core
abstract contract WrappedPosition is ERC20Permit, IWrappedPosition {
    IERC20 public immutable override token;

    /// @notice Constructs this contract
    /// @param _token The underlying token.
    ///               This token should revert in the event of a transfer failure.
    /// @param _name the name of this contract
    /// @param _symbol the symbol for this contract
    constructor(
        IERC20 _token,
        string memory _name,
        string memory _symbol
    ) ERC20Permit(_name, _symbol) {
        token = _token;
        // We set our decimals to be the same as the underlying
        _setupDecimals(_token.decimals());
    }

    /// We expect that the following logic will be present in an integration implementation
    /// which inherits from this contract

    /// @dev Makes the actual deposit into the 'vault'
    /// @return Tuple (shares minted, amount underlying used)
    function _deposit() internal virtual returns (uint256, uint256);

    /// @dev Makes the actual withdraw from the 'vault'
    /// @return returns the amount produced
    function _withdraw(
        uint256,
        address,
        uint256
    ) internal virtual returns (uint256);

    /// @dev Converts between an internal balance representation
    ///      and underlying tokens.
    /// @return The amount of underlying the input is worth
    function _underlying(uint256) internal virtual view returns (uint256);

    /// @notice Get the underlying balance of an address
    /// @param _who The address to query
    /// @return The underlying token balance of the address
    function balanceOfUnderlying(address _who)
        external
        override
        view
        returns (uint256)
    {
        return _underlying(balanceOf[_who]);
    }

    /// @notice Returns the amount of the underlying asset a certain amount of shares is worth
    /// @param _shares Shares to calculate underlying value for
    /// @return The value of underlying assets for the given shares
    function getSharesToUnderlying(uint256 _shares)
        external
        override
        view
        returns (uint256)
    {
        return _underlying(_shares);
    }

    /// @notice Entry point to deposit tokens into the Wrapped Position contract
    ///         Transfers tokens on behalf of caller so the caller must set
    ///         allowance on the contract prior to call.
    /// @param _amount The amount of underlying tokens to deposit
    /// @param _destination The address to mint to
    /// @return Returns the number of Wrapped Position tokens minted
    function deposit(address _destination, uint256 _amount)
        external
        override
        returns (uint256)
    {
        // Send tokens to the proxy
        token.transferFrom(msg.sender, address(this), _amount);
        // Calls our internal deposit function
        (uint256 shares, ) = _deposit();
        // Mint them internal ERC20 tokens corresponding to the deposit
        _mint(_destination, shares);
        return shares;
    }

    /// @notice Entry point to deposit tokens into the Wrapped Position contract
    ///         Assumes the tokens were transferred before this was called
    /// @param _destination the destination of this deposit
    /// @return Returns (WP tokens minted, used underlying,
    ///                  senders WP balance before mint)
    /// @dev WARNING - The call which funds this method MUST be in the same transaction
    //                 as the call to this method or you risk loss of funds
    function prefundedDeposit(address _destination)
        external
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Calls our internal deposit function
        (uint256 shares, uint256 usedUnderlying) = _deposit();

        uint256 balanceBefore = balanceOf[_destination];

        // Mint them internal ERC20 tokens corresponding to the deposit
        _mint(_destination, shares);
        return (shares, usedUnderlying, balanceBefore);
    }

    /// @notice Exit point to withdraw tokens from the Wrapped Position contract
    /// @param _destination The address which is credited with tokens
    /// @param _shares The amount of shares the user is burning to withdraw underlying
    /// @param _minUnderlying The min output the caller expects
    /// @return The amount of underlying transferred to the destination
    function withdraw(
        address _destination,
        uint256 _shares,
        uint256 _minUnderlying
    ) public override returns (uint256) {
        return _positionWithdraw(_destination, _shares, _minUnderlying, 0);
    }

    /// @notice This function burns enough tokens from the sender to send _amount
    ///          of underlying to the _destination.
    /// @param _destination The address to send the output to
    /// @param _amount The amount of underlying to try to redeem for
    /// @param _minUnderlying The minium underlying to receive
    /// @return The amount of underlying released, and shares used
    function withdrawUnderlying(
        address _destination,
        uint256 _amount,
        uint256 _minUnderlying
    ) external override returns (uint256, uint256) {
        // First we load the number of underlying per unit of Wrapped Position token
        uint256 oneUnit = 10**decimals;
        uint256 underlyingPerShare = _underlying(oneUnit);
        // Then we calculate the number of shares we need
        uint256 shares = (_amount * oneUnit) / underlyingPerShare;
        // Using this we call the normal withdraw function
        uint256 underlyingReceived = _positionWithdraw(
            _destination,
            shares,
            _minUnderlying,
            underlyingPerShare
        );
        return (underlyingReceived, shares);
    }

    /// @notice This internal function allows the caller to provide a precomputed 'underlyingPerShare'
    ///         so that we can avoid calling it again in the internal function
    /// @param _destination The destination to send the output to
    /// @param _shares The number of shares to withdraw
    /// @param _minUnderlying The min amount of output to produce
    /// @param _underlyingPerShare The precomputed shares per underlying
    /// @return The amount of underlying released
    function _positionWithdraw(
        address _destination,
        uint256 _shares,
        uint256 _minUnderlying,
        uint256 _underlyingPerShare
    ) internal returns (uint256) {
        // Burn users shares
        _burn(msg.sender, _shares);

        // Withdraw that many shares from the vault
        uint256 withdrawAmount = _withdraw(
            _shares,
            _destination,
            _underlyingPerShare
        );

        // We revert if this call doesn't produce enough underlying
        // This security feature is useful in some edge cases
        require(withdrawAmount >= _minUnderlying, "Not enough underlying");
        return withdrawAmount;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "./IERC20.sol";

interface IWrappedPosition is IERC20Permit {
    function token() external view returns (IERC20);

    function balanceOfUnderlying(address who) external view returns (uint256);

    function getSharesToUnderlying(uint256 shares)
        external
        view
        returns (uint256);

    function deposit(address sender, uint256 amount) external returns (uint256);

    function withdraw(
        address sender,
        uint256 _shares,
        uint256 _minUnderlying
    ) external returns (uint256);

    function withdrawUnderlying(
        address _destination,
        uint256 _amount,
        uint256 _minUnderlying
    ) external returns (uint256, uint256);

    function prefundedDeposit(address _destination)
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../interfaces/IERC20Permit.sol";

// This default erc20 library is designed for max efficiency and security.
// WARNING: By default it does not include totalSupply which breaks the ERC20 standard
//          to use a fully standard compliant ERC20 use 'ERC20PermitWithSupply"
abstract contract ERC20Permit is IERC20Permit {
    // --- ERC20 Data ---
    // The name of the erc20 token
    string public name;
    // The symbol of the erc20 token
    string public override symbol;
    // The decimals of the erc20 token, should default to 18 for new tokens
    uint8 public override decimals;

    // A mapping which tracks user token balances
    mapping(address => uint256) public override balanceOf;
    // A mapping which tracks which addresses a user allows to move their tokens
    mapping(address => mapping(address => uint256)) public override allowance;
    // A mapping which tracks the permit signature nonces for users
    mapping(address => uint256) public override nonces;

    // --- EIP712 niceties ---
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public override DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32
        public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Initializes the erc20 contract
    /// @param name_ the value 'name' will be set to
    /// @param symbol_ the value 'symbol' will be set to
    /// @dev decimals default to 18 and must be reset by an inheriting contract for
    ///      non standard decimal values
    constructor(string memory name_, string memory symbol_) {
        // Set the state variables
        name = name_;
        symbol = symbol_;
        decimals = 18;

        // By setting these addresses to 0 attempting to execute a transfer to
        // either of them will revert. This is a gas efficient way to prevent
        // a common user mistake where they transfer to the token address.
        // These values are not considered 'real' tokens and so are not included
        // in 'total supply' which only contains minted tokens.
        balanceOf[address(0)] = type(uint256).max;
        balanceOf[address(this)] = type(uint256).max;

        // Optional extra state manipulation
        _extraConstruction();

        // Computes the EIP 712 domain separator which prevents user signed messages for
        // this contract to be replayed in other contracts.
        // https://eips.ethereum.org/EIPS/eip-712
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice An optional override function to execute and change state before immutable assignment
    function _extraConstruction() internal virtual {}

    // --- Token ---
    /// @notice Allows a token owner to send tokens to another address
    /// @param recipient The address which will be credited with the tokens
    /// @param amount The amount user token to send
    /// @return returns true on success, reverts on failure so cannot return false.
    /// @dev transfers to this contract address or 0 will fail
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        // We forward this call to 'transferFrom'
        return transferFrom(msg.sender, recipient, amount);
    }

    /// @notice Transfers an amount of erc20 from a spender to a receipt
    /// @param spender The source of the ERC20 tokens
    /// @param recipient The destination of the ERC20 tokens
    /// @param amount the number of tokens to send
    /// @return returns true on success and reverts on failure
    /// @dev will fail transfers which send funds to this contract or 0
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        // Load balance and allowance
        uint256 balance = balanceOf[spender];
        require(balance >= amount, "ERC20: insufficient-balance");
        // We potentially have to change allowances
        if (spender != msg.sender) {
            // Loading the allowance in the if block prevents vanilla transfers
            // from paying for the sload.
            uint256 allowed = allowance[spender][msg.sender];
            // If the allowance is max we do not reduce it
            // Note - This means that max allowances will be more gas efficient
            // by not requiring a sstore on 'transferFrom'
            if (allowed != type(uint256).max) {
                require(allowed >= amount, "ERC20: insufficient-allowance");
                allowance[spender][msg.sender] = allowed - amount;
            }
        }
        // Update the balances
        balanceOf[spender] = balance - amount;
        // Note - In the constructor we initialize the 'balanceOf' of address 0 and
        //        the token address to uint256.max and so in 8.0 transfers to those
        //        addresses revert on this step.
        balanceOf[recipient] = balanceOf[recipient] + amount;
        // Emit the needed event
        emit Transfer(spender, recipient, amount);
        // Return that this call succeeded
        return true;
    }

    /// @notice This internal minting function allows inheriting contracts
    ///         to mint tokens in the way they wish.
    /// @param account the address which will receive the token.
    /// @param amount the amount of token which they will receive
    /// @dev This function is virtual so that it can be overridden, if you
    ///      are reviewing this contract for security you should ensure to
    ///      check for overrides
    function _mint(address account, uint256 amount) internal virtual {
        // Add tokens to the account
        balanceOf[account] = balanceOf[account] + amount;
        // Emit an event to track the minting
        emit Transfer(address(0), account, amount);
    }

    /// @notice This internal burning function allows inheriting contracts to
    ///         burn tokens in the way they see fit.
    /// @param account the account to remove tokens from
    /// @param amount  the amount of tokens to remove
    /// @dev This function is virtual so that it can be overridden, if you
    ///      are reviewing this contract for security you should ensure to
    ///      check for overrides
    function _burn(address account, uint256 amount) internal virtual {
        // Reduce the balance of the account
        balanceOf[account] = balanceOf[account] - amount;
        // Emit an event tracking transfers
        emit Transfer(account, address(0), amount);
    }

    /// @notice This function allows a user to approve an account which can transfer
    ///         tokens on their behalf.
    /// @param account The account which will be approve to transfer tokens
    /// @param amount The approval amount, if set to uint256.max the allowance does not go down on transfers.
    /// @return returns true for compatibility with the ERC20 standard
    function approve(address account, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        // Set the senders allowance for account to amount
        allowance[msg.sender][account] = amount;
        // Emit an event to track approvals
        emit Approval(msg.sender, account, amount);
        return true;
    }

    /// @notice This function allows a caller who is not the owner of an account to execute the functionality of 'approve' with the owners signature.
    /// @param owner the owner of the account which is having the new approval set
    /// @param spender the address which will be allowed to spend owner's tokens
    /// @param value the new allowance value
    /// @param deadline the timestamp which the signature must be submitted by to be valid
    /// @param v Extra ECDSA data which allows public key recovery from signature assumed to be 27 or 28
    /// @param r The r component of the ECDSA signature
    /// @param s The s component of the ECDSA signature
    /// @dev The signature for this function follows EIP 712 standard and should be generated with the
    ///      eth_signTypedData JSON RPC call instead of the eth_sign JSON RPC call. If using out of date
    ///      parity signing libraries the v component may need to be adjusted. Also it is very rare but possible
    ///      for v to be other values, those values are not supported.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // The EIP 712 digest for this function
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner],
                        deadline
                    )
                )
            )
        );
        // Require that the owner is not zero
        require(owner != address(0), "ERC20: invalid-address-0");
        // Require that we have a valid signature from the owner
        require(owner == ecrecover(digest, v, r, s), "ERC20: invalid-permit");
        // Require that the signature is not expired
        require(
            deadline == 0 || block.timestamp <= deadline,
            "ERC20: permit-expired"
        );
        // Format the signature to the default format
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ERC20: invalid signature 's' value"
        );
        // Increment the signature nonce to prevent replay
        nonces[owner]++;
        // Set the allowance to the new value
        allowance[owner][spender] = value;
        // Emit an approval event to be able to track this happening
        emit Approval(owner, spender, value);
    }

    /// @notice Internal function which allows inheriting contract to set custom decimals
    /// @param decimals_ the new decimal value
    function _setupDecimals(uint8 decimals_) internal {
        // Set the decimals
        decimals = decimals_;
    }
}

// Forked from openzepplin
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

