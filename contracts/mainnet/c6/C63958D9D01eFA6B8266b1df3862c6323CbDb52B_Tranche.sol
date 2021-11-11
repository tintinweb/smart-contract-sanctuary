// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IWrappedPosition.sol";
import "./interfaces/ITranche.sol";
import "./interfaces/ITrancheFactory.sol";
import "./interfaces/IInterestToken.sol";

import "./libraries/ERC20Permit.sol";
import "./libraries/DateString.sol";

/// @author Element Finance
/// @title Tranche
contract Tranche is ERC20Permit, ITranche {
    IInterestToken public immutable override interestToken;
    IWrappedPosition public immutable position;
    IERC20 public immutable underlying;
    uint8 internal immutable _underlyingDecimals;

    // The outstanding amount of underlying which
    // can be redeemed from the contract from Principal Tokens
    // NOTE - we use smaller sizes so that they can be one storage slot
    uint128 public valueSupplied;
    // The total supply of interest tokens
    uint128 public override interestSupply;
    // The timestamp when tokens can be redeemed.
    uint256 public immutable unlockTimestamp;
    // The amount of slippage allowed on the Principal token redemption [0.1 basis points]
    uint256 internal constant _SLIPPAGE_BP = 1e13;
    // The speedbump variable records the first timestamp where redemption was attempted to be
    // performed on a tranche where loss occurred. It blocks redemptions for 48 hours after
    // it is triggered in order to (1) prevent atomic flash loan price manipulation (2)
    // give 48 hours to remediate any other loss scenario before allowing withdraws
    uint256 public speedbump;
    // Const which is 48 hours in seconds
    uint256 internal constant _FORTY_EIGHT_HOURS = 172800;
    // An event to listen for when negative interest withdraw are triggered
    event SpeedBumpHit(uint256 timestamp);

    /// @notice Constructs this contract
    constructor() ERC20Permit("Element Principal Token ", "eP") {
        // Assume the caller is the Tranche factory.
        ITrancheFactory trancheFactory = ITrancheFactory(msg.sender);
        (
            address wpAddress,
            uint256 expiration,
            IInterestToken interestTokenTemp,
            // solhint-disable-next-line
            address unused
        ) = trancheFactory.getData();
        interestToken = interestTokenTemp;

        IWrappedPosition wpContract = IWrappedPosition(wpAddress);
        position = wpContract;

        // Store the immutable time variables
        unlockTimestamp = expiration;
        // We use local because immutables are not readable in construction
        IERC20 localUnderlying = wpContract.token();
        underlying = localUnderlying;
        // We load and store the underlying decimals
        uint8 localUnderlyingDecimals = localUnderlying.decimals();
        _underlyingDecimals = localUnderlyingDecimals;
        // And set this contract to have the same
        _setupDecimals(localUnderlyingDecimals);
    }

    /// @notice We override the optional extra construction function from ERC20 to change names
    function _extraConstruction() internal override {
        // Assume the caller is the Tranche factory and that this is called from constructor
        // We have to do this double load because of the lack of flexibility in constructor ordering
        ITrancheFactory trancheFactory = ITrancheFactory(msg.sender);
        (
            address wpAddress,
            uint256 expiration,
            // solhint-disable-next-line
            IInterestToken unused,
            address dateLib
        ) = trancheFactory.getData();

        string memory strategySymbol = IWrappedPosition(wpAddress).symbol();

        // Write the strategySymbol and expiration time to name and symbol

        // This logic was previously encoded as calling a library "DateString"
        // in line and directly. However even though this code is only in the constructor
        // it both made the code of this contract much bigger and made the factory
        // un deployable. So we needed to use the library as an external contract
        // but solidity does not have support for address to library conversions
        // or other support for working directly with libraries in a type safe way.
        // For that reason we have to use this ugly and non type safe hack to make these
        // contracts deployable. Since the library is an immutable in the factory
        // the security profile is quite similar to a standard external linked library.

        // We load the real storage slots of the symbol and name storage variables
        uint256 namePtr;
        uint256 symbolPtr;
        assembly {
            namePtr := name.slot
            symbolPtr := symbol.slot
        }
        // We then call the 'encodeAndWriteTimestamp' function on our library contract
        (bool success1, ) = dateLib.delegatecall(
            abi.encodeWithSelector(
                DateString.encodeAndWriteTimestamp.selector,
                strategySymbol,
                expiration,
                namePtr
            )
        );
        (bool success2, ) = dateLib.delegatecall(
            abi.encodeWithSelector(
                DateString.encodeAndWriteTimestamp.selector,
                strategySymbol,
                expiration,
                symbolPtr
            )
        );
        // Assert that both calls succeeded
        assert(success1 && success2);
    }

    /// @notice An aliasing of the getter for valueSupplied to improve ERC20 compatibility
    /// @return The number of principal tokens which exist.
    function totalSupply() external view returns (uint256) {
        return uint256(valueSupplied);
    }

    /**
    @notice Deposit wrapped position tokens and receive interest and Principal ERC20 tokens.
            If interest has already been accrued by the wrapped position
            tokens held in this contract, the number of Principal tokens minted is
            reduced in order to pay for the accrued interest.
    @param _amount The amount of underlying to deposit
    @param _destination The address to mint to
    @return The amount of principal and yield token minted as (pt, yt)
     */
    function deposit(uint256 _amount, address _destination)
        external
        override
        returns (uint256, uint256)
    {
        // Transfer the underlying to be wrapped into the position
        underlying.transferFrom(msg.sender, address(position), _amount);
        // Now that we have funded the deposit we can call
        // the prefunded deposit
        return prefundedDeposit(_destination);
    }

    /// @notice This function calls the prefunded deposit method to
    ///         create wrapped position tokens held by the contract. It should
    ///         only be called when a transfer has already been made to
    ///         the wrapped position contract of the underlying
    /// @param _destination The address to mint to
    /// @return the amount of principal and yield token minted as (pt, yt)
    /// @dev WARNING - The call which funds this method MUST be in the same transaction
    //                 as the call to this method or you risk loss of funds
    function prefundedDeposit(address _destination)
        public
        override
        returns (uint256, uint256)
    {
        // We check that this it is possible to deposit
        require(block.timestamp < unlockTimestamp, "expired");
        // Since the wrapped position contract holds a balance we use the prefunded deposit method
        (
            uint256 shares,
            uint256 usedUnderlying,
            uint256 balanceBefore
        ) = position.prefundedDeposit(address(this));
        // The implied current value of the holding of this contract in underlying
        // is the balanceBefore*(usedUnderlying/shares) since (usedUnderlying/shares)
        // is underlying per share and balanceBefore is the balance of this contract
        // in position tokens before this deposit.
        uint256 holdingsValue = (balanceBefore * usedUnderlying) / shares;
        // This formula is inputUnderlying - inputUnderlying*interestPerUnderlying
        // Accumulated interest has its value in the interest tokens so we have to mint less
        // principal tokens to account for that.
        // NOTE - If a pool has more than 100% interest in the period this will revert on underflow
        //        The user cannot discount the principal token enough to pay for the outstanding interest accrued.
        (uint256 _valueSupplied, uint256 _interestSupply) = (
            uint256(valueSupplied),
            uint256(interestSupply)
        );
        // We block deposits in negative interest rate regimes
        // The +2 allows for very small rounding errors which occur when
        // depositing into a tranche which is attached to a wp which has
        // accrued interest but the tranche has not yet accrued interest
        // and the first deposit into the tranche is substantially smaller
        // than following ones.
        require(_valueSupplied <= holdingsValue + 2, "E:NEG_INT");

        uint256 adjustedAmount;
        // Have to split on the initialization case and negative interest case
        if (_valueSupplied > 0 && holdingsValue > _valueSupplied) {
            adjustedAmount =
                usedUnderlying -
                ((holdingsValue - _valueSupplied) * usedUnderlying) /
                _interestSupply;
        } else {
            adjustedAmount = usedUnderlying;
        }
        // We record the new input of reclaimable underlying
        (valueSupplied, interestSupply) = (
            uint128(_valueSupplied + adjustedAmount),
            uint128(_interestSupply + usedUnderlying)
        );
        // We mint interest token for each underlying provided
        interestToken.mint(_destination, usedUnderlying);
        // We mint principal token discounted by the accumulated interest.
        _mint(_destination, adjustedAmount);
        // We return the number of principal token and yield token
        return (adjustedAmount, usedUnderlying);
    }

    /**
    @notice Burn principal tokens to withdraw underlying tokens.
    @param _amount The number of tokens to burn.
    @param _destination The address to send the underlying too
    @return The number of underlying tokens released
    @dev This method will return 1 underlying for 1 principal except when interest
         is negative, in which case the principal tokens is redeemable pro rata for
         the assets controlled by this vault.
         Also note: Redemption has the possibility of at most _SLIPPAGE_BP
         numerical error on each redemption so each principal token may occasionally redeem
         for less than 1 unit of underlying. Max loss defaults to 0.1 BP ie 0.001% loss
     */
    function withdrawPrincipal(uint256 _amount, address _destination)
        external
        override
        returns (uint256)
    {
        // No redemptions before unlock
        require(block.timestamp >= unlockTimestamp, "E:Not Expired");
        // If the speedbump == 0 it's never been hit so we don't need
        // to change the withdraw rate.
        uint256 localSpeedbump = speedbump;
        uint256 withdrawAmount = _amount;
        uint256 localSupply = uint256(valueSupplied);
        if (localSpeedbump != 0) {
            // Load the assets we have in this vault
            uint256 holdings = position.balanceOfUnderlying(address(this));
            // If we check and the interest rate is no longer negative then we
            // allow normal 1 to 1 withdraws [even if the speedbump was hit less
            // than 48 hours ago, to prevent possible griefing]
            if (holdings < localSupply) {
                // We allow the user to only withdraw their percent of holdings
                // NOTE - Because of the discounting mechanics this causes account loss
                //        percentages to be slightly perturbed from overall loss.
                //        ie: tokens holders who join when interest has accumulated
                //        will get slightly higher percent loss than those who joined earlier
                //        in the case of loss at the end of the period. Biases are very
                //        small except in extreme cases.
                withdrawAmount = (_amount * holdings) / localSupply;
                // If the interest rate is still negative and we are not 48 hours after
                // speedbump being set we revert
                require(
                    localSpeedbump + _FORTY_EIGHT_HOURS < block.timestamp,
                    "E:Early"
                );
            }
        }
        // Burn from the sender
        _burn(msg.sender, _amount);
        // Remove these principal token from the interest calculations for future interest redemptions
        valueSupplied = uint128(localSupply) - uint128(_amount);
        // Load the share balance of the vault before withdrawing [gas note - both the smart
        // contract and share value is warmed so this is actually quite a cheap lookup]
        uint256 shareBalanceBefore = position.balanceOf(address(this));
        // Calculate the min output
        uint256 minOutput = withdrawAmount -
            (withdrawAmount * _SLIPPAGE_BP) /
            1e18;
        // We make the actual withdraw from the position.
        (uint256 actualWithdraw, uint256 sharesBurned) = position
            .withdrawUnderlying(_destination, withdrawAmount, minOutput);

        // At this point we check that the implied contract holdings before this withdraw occurred
        // are more than enough to redeem all of the principal tokens for underlying ie that no
        // loss has happened.
        uint256 balanceBefore = (shareBalanceBefore * actualWithdraw) /
            sharesBurned;
        if (balanceBefore < localSupply) {
            // Require that that the speedbump has been set.
            require(localSpeedbump != 0, "E:NEG_INT");
            // This assert should be very difficult to hit because it is checked above
            // but may be possible with  complex reentrancy.
            assert(localSpeedbump + _FORTY_EIGHT_HOURS < block.timestamp);
        }
        return (actualWithdraw);
    }

    /// @notice This function allows someone to trigger the speedbump and eventually allow
    ///         pro rata withdraws
    function hitSpeedbump() external {
        // We only allow setting the speedbump once
        require(speedbump == 0, "E:AlreadySet");
        // We only allow setting it when withdraws can happen
        require(block.timestamp >= unlockTimestamp, "E:Not Expired");
        // We require that the total holds are less than the supply of
        // principal token we need to redeem
        uint256 totalHoldings = position.balanceOfUnderlying(address(this));
        if (totalHoldings < valueSupplied) {
            // We emit a notification so that if a speedbump is hit the community
            // can investigate.
            // Note - this is a form of defense mechanism because any flash loan
            //        attack must be public for at least 48 hours before it has
            //        affects.
            emit SpeedBumpHit(block.timestamp);
            // Set the speedbump
            speedbump = block.timestamp;
        } else {
            revert("E:NoLoss");
        }
    }

    /**
    @notice Burn interest tokens to withdraw underlying tokens.
    @param _amount The number of interest tokens to burn.
    @param _destination The address to send the result to
    @return The number of underlying token released
    @dev Due to slippage the redemption may receive up to _SLIPPAGE_BP less
         in output compared to the floating rate.
     */
    function withdrawInterest(uint256 _amount, address _destination)
        external
        override
        returns (uint256)
    {
        require(block.timestamp >= unlockTimestamp, "E:Not Expired");
        // Burn tokens from the sender
        interestToken.burn(msg.sender, _amount);
        // Load the underlying value of this contract
        uint256 underlyingValueLocked = position.balanceOfUnderlying(
            address(this)
        );
        // Load a stack variable to avoid future sloads
        (uint256 _valueSupplied, uint256 _interestSupply) = (
            uint256(valueSupplied),
            uint256(interestSupply)
        );
        // Interest is value locked minus current value
        uint256 interest = underlyingValueLocked > _valueSupplied
            ? underlyingValueLocked - _valueSupplied
            : 0;
        // The redemption amount is the interest per token times the amount
        uint256 redemptionAmount = (interest * _amount) / _interestSupply;
        uint256 minRedemption = redemptionAmount -
            (redemptionAmount * _SLIPPAGE_BP) /
            1e18;
        // Store that we reduced the supply
        interestSupply = uint128(_interestSupply - _amount);
        // Redeem position tokens for underlying
        (uint256 redemption, ) = position.withdrawUnderlying(
            _destination,
            redemptionAmount,
            minRedemption
        );
        return (redemption);
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

import "./IERC20Permit.sol";
import "./IInterestToken.sol";

interface ITranche is IERC20Permit {
    function deposit(uint256 _shares, address destination)
        external
        returns (uint256, uint256);

    function prefundedDeposit(address _destination)
        external
        returns (uint256, uint256);

    function withdrawPrincipal(uint256 _amount, address _destination)
        external
        returns (uint256);

    function withdrawInterest(uint256 _amount, address _destination)
        external
        returns (uint256);

    function interestToken() external view returns (IInterestToken);

    function interestSupply() external view returns (uint128);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../InterestToken.sol";
import "../libraries/DateString.sol";

interface ITrancheFactory {
    function getData()
        external
        returns (
            address,
            uint256,
            InterestToken,
            address
        );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20Permit.sol";

interface IInterestToken is IERC20Permit {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
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
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library DateString {
    uint256 public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 public constant SECONDS_PER_HOUR = 60 * 60;
    uint256 public constant SECONDS_PER_MINUTE = 60;
    int256 public constant OFFSET19700101 = 2440588;

    // This function was forked from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    // solhint-disable-next-line private-vars-leading-underscore
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);
        // solhint-disable-next-line var-name-mixedcase
        int256 L = __days + 68569 + OFFSET19700101;
        // solhint-disable-next-line var-name-mixedcase
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    /// @dev Writes a prefix and an timestamp encoding to an output storage location
    ///      This function is designed to only work with ASCII encoded strings. No emojis please.
    /// @param _prefix The string to write before the timestamp
    /// @param _timestamp the timestamp to encode and store
    /// @param _output the storage location of the output string
    /// NOTE - Current cost ~90k if gas is problem revisit and use assembly to remove the extra
    ///        sstore s.
    function encodeAndWriteTimestamp(
        string memory _prefix,
        uint256 _timestamp,
        string storage _output
    ) external {
        _encodeAndWriteTimestamp(_prefix, _timestamp, _output);
    }

    /// @dev Sn internal version of the above function 'encodeAndWriteTimestamp'
    // solhint-disable-next-line
    function _encodeAndWriteTimestamp(
        string memory _prefix,
        uint256 _timestamp,
        string storage _output
    ) internal {
        // Cast the prefix string to a byte array
        bytes memory bytePrefix = bytes(_prefix);
        // Cast the output string to a byte array
        bytes storage bytesOutput = bytes(_output);
        // Copy the bytes from the prefix onto the byte array
        // NOTE - IF PREFIX CONTAINS NON-ASCII CHARS THIS WILL CAUSE AN INCORRECT STRING LENGTH
        for (uint256 i = 0; i < bytePrefix.length; i++) {
            bytesOutput.push(bytePrefix[i]);
        }
        // Add a '-' to the string to separate the prefix from the the date
        bytesOutput.push(bytes1("-"));
        // Add the date string
        timestampToDateString(_timestamp, _output);
    }

    /// @dev Converts a unix second encoded timestamp to a date format (year, month, day)
    ///      then writes the string encoding of that to the output pointer.
    /// @param _timestamp the unix seconds timestamp
    /// @param _outputPointer the storage pointer to change.
    function timestampToDateString(
        uint256 _timestamp,
        string storage _outputPointer
    ) public {
        _timestampToDateString(_timestamp, _outputPointer);
    }

    /// @dev Sn internal version of the above function 'timestampToDateString'
    // solhint-disable-next-line
    function _timestampToDateString(
        uint256 _timestamp,
        string storage _outputPointer
    ) internal {
        // We pretend the string is a 'bytes' only push UTF8 encodings to it
        bytes storage output = bytes(_outputPointer);
        // First we get the day month and year
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            _timestamp / SECONDS_PER_DAY
        );
        // First we add encoded day to the string
        {
            // Round out the second digit
            uint256 firstDigit = day / 10;
            // add it to the encoded byte for '0'
            output.push(bytes1(uint8(bytes1("0")) + uint8(firstDigit)));
            // Extract the second digit
            uint256 secondDigit = day % 10;
            // add it to the string
            output.push(bytes1(uint8(bytes1("0")) + uint8(secondDigit)));
        }
        // Next we encode the month string and add it
        if (month == 1) {
            stringPush(output, "J", "A", "N");
        } else if (month == 2) {
            stringPush(output, "F", "E", "B");
        } else if (month == 3) {
            stringPush(output, "M", "A", "R");
        } else if (month == 4) {
            stringPush(output, "A", "P", "R");
        } else if (month == 5) {
            stringPush(output, "M", "A", "Y");
        } else if (month == 6) {
            stringPush(output, "J", "U", "N");
        } else if (month == 7) {
            stringPush(output, "J", "U", "L");
        } else if (month == 8) {
            stringPush(output, "A", "U", "G");
        } else if (month == 9) {
            stringPush(output, "S", "E", "P");
        } else if (month == 10) {
            stringPush(output, "O", "C", "T");
        } else if (month == 11) {
            stringPush(output, "N", "O", "V");
        } else if (month == 12) {
            stringPush(output, "D", "E", "C");
        } else {
            revert("date decoding error");
        }
        // We take the last two digits of the year
        // Hopefully that's enough
        {
            uint256 lastDigits = year % 100;
            // Round out the second digit
            uint256 firstDigit = lastDigits / 10;
            // add it to the encoded byte for '0'
            output.push(bytes1(uint8(bytes1("0")) + uint8(firstDigit)));
            // Extract the second digit
            uint256 secondDigit = lastDigits % 10;
            // add it to the string
            output.push(bytes1(uint8(bytes1("0")) + uint8(secondDigit)));
        }
    }

    function stringPush(
        bytes storage output,
        bytes1 data1,
        bytes1 data2,
        bytes1 data3
    ) internal {
        output.push(data1);
        output.push(data2);
        output.push(data3);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./libraries/ERC20Permit.sol";
import "./libraries/DateString.sol";

import "./interfaces/IInterestToken.sol";
import "./interfaces/ITranche.sol";

contract InterestToken is ERC20Permit, IInterestToken {
    // The tranche address which controls the minting
    ITranche public immutable tranche;

    /// @dev Initializes the ERC20 and writes the correct names
    /// @param _tranche The tranche contract address
    /// @param _strategySymbol The symbol of the associated WrappedPosition contract
    /// @param _timestamp The unlock time on the tranche
    /// @param _decimals The decimal encoding for this token
    constructor(
        address _tranche,
        string memory _strategySymbol,
        uint256 _timestamp,
        uint8 _decimals
    )
        ERC20Permit(
            _processName("Element Yield Token ", _strategySymbol, _timestamp),
            _processSymbol("eY", _strategySymbol, _timestamp)
        )
    {
        tranche = ITranche(_tranche);
        _setupDecimals(_decimals);
    }

    /// @notice We use this function to add the date to the name string
    /// @param _name start of the name
    /// @param _strategySymbol the strategy symbol
    /// @param _timestamp the unix second timestamp to be encoded and added to the end of the string
    function _processName(
        string memory _name,
        string memory _strategySymbol,
        uint256 _timestamp
    ) internal returns (string memory) {
        // Set the name in the super
        name = _name;
        // Use the library to write the rest
        DateString._encodeAndWriteTimestamp(_strategySymbol, _timestamp, name);
        // load and return the name
        return name;
    }

    /// @notice We use this function to add the date to the name string
    /// @param _symbol start of the symbol
    /// @param _strategySymbol the strategy symbol
    /// @param _timestamp the unix second timestamp to be encoded and added to the end of the string
    function _processSymbol(
        string memory _symbol,
        string memory _strategySymbol,
        uint256 _timestamp
    ) internal returns (string memory) {
        // Set the symbol in the super
        symbol = _symbol;
        // Use the library to write the rest
        DateString._encodeAndWriteTimestamp(
            _strategySymbol,
            _timestamp,
            symbol
        );
        // load and return the name
        return symbol;
    }

    /// @dev Aliasing of the lookup method for the supply of yield tokens which
    ///      improves our ERC20 compatibility.
    /// @return The total supply of yield tokens
    function totalSupply() external view returns (uint256) {
        return uint256(tranche.interestSupply());
    }

    /// @dev Prevents execution if the caller isn't the tranche
    modifier onlyMintAuthority() {
        require(
            msg.sender == address(tranche),
            "caller is not an authorized minter"
        );
        _;
    }

    /// @dev Mints tokens to an address
    /// @param _account The account to mint to
    /// @param _amount The amount to mint
    function mint(address _account, uint256 _amount)
        external
        override
        onlyMintAuthority
    {
        _mint(_account, _amount);
    }

    /// @dev Burns tokens from an address
    /// @param _account The account to burn from
    /// @param _amount The amount of token to burn
    function burn(address _account, uint256 _amount)
        external
        override
        onlyMintAuthority
    {
        _burn(_account, _amount);
    }
}