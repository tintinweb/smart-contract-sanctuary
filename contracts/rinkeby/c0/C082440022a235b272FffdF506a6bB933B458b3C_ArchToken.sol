/************************************************************************
 ~~~ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\ ~~~~
 ~~~ @@@@@@ ░█████╗░██████╗░░█████╗░██╗░░██╗███████╗██████╗░ @@@@@@ | ~~~
 ~~~ @@@@@  ██╔══██╗██╔══██╗██╔══██╗██║░░██║██╔════╝██╔══██╗  @@@@@ | ~~~
 ~~~ @@@@@  ███████║██████╔╝██║░░╚═╝███████║█████╗░░██████╔╝ @@@@@@ | ~~~
 ~~~ @@@@@  ██╔══██║██╔══██╗██║░░██╗██╔══██║██╔══╝░░██╔══██╗  @@@@@ | ~~~
 ~~~ @@@@@  ██║░░██║██║░░██║╚█████╔╝██║░░██║███████╗██║░░██║  @@@@@ | ~~~
 ~~~ @@@@@  ╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝  @@@@@ | ~~~
 ~~~ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ | ~~~
 ~~~ \_____________________________________________________________\| ~~~
 ************************************************************************/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./lib/SafeMath.sol";

/**
 * @title ArchToken
 * @dev The governance token for Archer DAO
 * ERC-20 with supply controls + add-ons to allow for offchain signing
 * See EIP-712, EIP-2612, and EIP-3009 for details
 */
contract ArchToken {
    using SafeMath for uint256;

    /// @notice EIP-20 token name for this token
    string public name = "Archer DAO Governance Token";

    /// @notice EIP-20 token symbol for this token
    string public symbol = "ARCH";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint256 public totalSupply = 100_000_000e18; // 100 million

    /// @notice Address which may mint/burn tokens
    address public supplyManager;

    /// @notice Address which may change token metadata
    address public metadataManager;

    /// @notice The timestamp after which a supply change may occur
    uint256 public supplyChangeAllowedAfter;

    /// @notice The initial minimum time between changing the token supply
    uint32 public supplyChangeWaitingPeriod = 1 days * 365;

    /// @notice Hard cap on the minimum time between changing the token supply
    uint32 public constant supplyChangeWaitingPeriodMinimum = 1 days * 90;

    /// @notice Cap on the total amount that can be minted at each mint (measured in bips: 10,000 bips = 1% of current totalSupply)
    uint16 public mintCap = 20_000;

    /// @dev Allowance amounts on behalf of others
    mapping (address => mapping (address => uint256)) internal allowances;

    /// @dev Official record of token balances for each account
    mapping (address => uint256) internal balances;

    /// @notice The EIP-712 typehash for the contract's domain
    /// keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    
    /// @notice The EIP-712 version hash
    /// keccak256("1");
    bytes32 public constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    /// @notice The EIP-712 typehash for permit (EIP-2612)
    /// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice The EIP-712 typehash for transferWithAuthorization (EIP-3009)
    /// keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)");
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    /// @notice The EIP-712 typehash for receiveWithAuthorization (EIP-3009)
    /// keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH = 0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @dev authorizer address > nonce > state (true = used / false = unused)
    mapping (address => mapping (bytes32 => bool)) public authorizationState;

    /// @notice An event that's emitted when the mintCap is changed
    event MintCapChanged(uint16 indexed oldMintCap, uint16 indexed newMintCap);

    /// @notice An event that's emitted when the supplyManager address is changed
    event SupplyManagerChanged(address indexed oldManager, address indexed newManager);

    /// @notice An event that's emitted when the supplyChangeWaitingPeriod is changed
    event SupplyChangeWaitingPeriodChanged(uint32 indexed oldWaitingPeriod, uint32 indexed newWaitingPeriod);

    /// @notice An event that's emitted when the metadataManager address is changed
    event MetadataManagerChanged(address indexed oldManager, address indexed newManager);

    /// @notice An event that's emitted when the token name and symbol are changed
    event TokenMetaUpdated(string indexed name, string indexed symbol);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice An event that's emitted whenever an authorized transfer occurs
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    /**
     * @notice Construct a new Arch token
     * @param _metadataManager The account with the ability to change token metadata
     * @param _supplyManager The address with minting ability
     * @param _firstSupplyChangeAllowed The timestamp after which the first supply change may occur
     */
    constructor(address _metadataManager, address _supplyManager, uint256 _firstSupplyChangeAllowed) {
        require(_firstSupplyChangeAllowed >= block.timestamp, "Arch::constructor: minting can only begin after deployment");

        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);

        supplyChangeAllowedAfter = _firstSupplyChangeAllowed;
        supplyManager = _supplyManager;
        emit SupplyManagerChanged(address(0), _supplyManager);

        metadataManager = _metadataManager;
        emit MetadataManagerChanged(address(0), metadataManager);
    }

    /**
     * @notice Change the supplyManager address
     * @param newSupplyManager The address of the new supply manager
     * @return true if successful
     */
    function setSupplyManager(address newSupplyManager) external returns (bool) {
        require(msg.sender == supplyManager, "Arch::setSupplyManager: only SM can change SM");
        emit SupplyManagerChanged(supplyManager, newSupplyManager);
        supplyManager = newSupplyManager;
        return true;
    }

    /**
     * @notice Change the metadataManager address
     * @param newMetadataManager The address of the new metadata manager
     * @return true if successful
     */
    function setMetadataManager(address newMetadataManager) external returns (bool) {
        require(msg.sender == metadataManager, "Arch::setMetadataManager: only MM can change MM");
        emit MetadataManagerChanged(metadataManager, newMetadataManager);
        metadataManager = newMetadataManager;
        return true;
    }

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param amount The number of tokens to be minted
     * @return Boolean indicating success of mint
     */
    function mint(address dst, uint256 amount) external returns (bool) {
        require(msg.sender == supplyManager, "Arch::mint: only the supplyManager can mint");
        require(dst != address(0), "Arch::mint: cannot transfer to the zero address");
        require(amount <= totalSupply.mul(mintCap).div(1000000), "Arch::mint: exceeded mint cap");
        require(block.timestamp >= supplyChangeAllowedAfter, "Arch::mint: minting not allowed yet");

        // update the next supply change allowed timestamp
        supplyChangeAllowedAfter = block.timestamp.add(supplyChangeWaitingPeriod);

        // mint the amount
        _mint(dst, amount);
        return true;
    }

    /**
     * @notice Burn tokens
     * @param src The account that will burn tokens
     * @param amount The number of tokens to be burned
     * @return Boolean indicating success of burn
     */
    function burn(address src, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        require(spender == supplyManager, "Arch::burn: only the supplyManager can burn");
        require(src != address(0), "Arch::burn: cannot transfer from the zero address");
        require(block.timestamp >= supplyChangeAllowedAfter, "Arch::burn: burning not allowed yet");
        
        uint256 spenderAllowance = allowances[src][spender];
        // check allowance and reduce by amount
        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(
                amount,
                "Arch::burn: burn amount exceeds allowance"
            );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        // update the next supply change allowed timestamp
        supplyChangeAllowedAfter = block.timestamp.add(supplyChangeWaitingPeriod);

        // burn the amount
        _burn(src, amount);
        return true;
    }

    /**
     * @notice Set the maximum amount of tokens that can be minted at once
     * @param newCap The new mint cap in bips (10,000 bips = 1% of totalSupply)
     * @return true if successful
     */
    function setMintCap(uint16 newCap) external returns (bool) {
        require(msg.sender == supplyManager, "Arch::setMintCap: only SM can change mint cap");
        emit MintCapChanged(mintCap, newCap);
        mintCap = newCap;
        return true;
    }

    /**
     * @notice Set the minimum time between supply changes
     * @param period The new supply change waiting period
     * @return true if succssful
     */
    function setSupplyChangeWaitingPeriod(uint32 period) external returns (bool) {
        require(msg.sender == supplyManager, "Arch::setSupplyChangeWaitingPeriod: only SM can change waiting period");
        require(period >= supplyChangeWaitingPeriodMinimum, "Arch::setSupplyChangeWaitingPeriod: waiting period must be > minimum");
        emit SupplyChangeWaitingPeriodChanged(supplyChangeWaitingPeriod, period);
        supplyChangeWaitingPeriod = period;
        return true;
    }

    /**
     * @notice Update the token name and symbol
     * @param tokenName The new name for the token
     * @param tokenSymbol The new symbol for the token
     * @return true if successful
     */
    function updateTokenMetadata(string memory tokenName, string memory tokenSymbol) external returns (bool) {
        require(msg.sender == metadataManager, "Arch::updateTokenMeta: only MM can update token metadata");
        name = tokenName;
        symbol = tokenSymbol;
        emit TokenMetaUpdated(name, symbol);
        return true;
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * It is recommended to use increaseAllowance and decreaseAllowance instead
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Increase the allowance by a given amount
     * @param spender Spender's address
     * @param addedValue Amount of increase in allowance
     * @return True if successful
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _increaseAllowance(msg.sender, spender, addedValue);
        return true;
    }

    /**
     * @notice Decrease the allowance by a given amount
     * @param spender Spender's address
     * @param subtractedValue Amount of decrease in allowance
     * @return True if successful
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        _decreaseAllowance(msg.sender, spender, subtractedValue);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spender
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param value The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "Arch::permit: signature expired");

        bytes32 encodeData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        _validateSignedData(owner, encodeData, v, r, s);

        _approve(owner, spender, value);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(
                amount,
                "Arch::transferFrom: transfer amount exceeds allowance"
            );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Transfer tokens with a signed authorization
     * @param from Payer's address (Authorizer)
     * @param to Payee's address
     * @param value Amount to be transferred
     * @param validAfter The time after which this is valid (unix time)
     * @param validBefore The time before which this is valid (unix time)
     * @param nonce Unique nonce
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        require(block.timestamp > validAfter, "Arch::transferWithAuth: auth not yet valid");
        require(block.timestamp < validBefore, "Arch::transferWithAuth: auth expired");
        require(!authorizationState[from][nonce],  "Arch::transferWithAuth: auth already used");

        bytes32 encodeData = keccak256(abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce));
        _validateSignedData(from, encodeData, v, r, s);

        authorizationState[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transferTokens(from, to, value);
    }

    /**
     * @notice Receive a transfer with a signed authorization from the payer
     * @dev This has an additional check to ensure that the payee's address matches
     * the caller of this function to prevent front-running attacks.
     * @param from Payer's address (Authorizer)
     * @param to Payee's address
     * @param value Amount to be transferred
     * @param validAfter The time after which this is valid (unix time)
     * @param validBefore The time before which this is valid (unix time)
     * @param nonce Unique nonce
     * @param v v of the signature
     * @param r r of the signature
     * @param s s of the signature
     */
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(to == msg.sender, "Arch::receiveWithAuth: caller must be the payee");
        require(block.timestamp > validAfter, "Arch::receiveWithAuth: auth not yet valid");
        require(block.timestamp < validBefore, "Arch::receiveWithAuth: auth expired");
        require(!authorizationState[from][nonce],  "Arch::receiveWithAuth: auth already used");

        bytes32 encodeData = keccak256(abi.encode(RECEIVE_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce));
        _validateSignedData(from, encodeData, v, r, s);

        authorizationState[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transferTokens(from, to, value);
    }

    /**
     * @notice EIP-712 Domain separator
     * @return Separator
     */
    function getDomainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                VERSION_HASH,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @notice Recovers address from signed data and validates the signature
     * @param signer Address that signed the data
     * @param encodeData Data signed by the address
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function _validateSignedData(address signer, bytes32 encodeData, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                encodeData
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "Arch::validateSig: invalid signature");
    }

    /**
     * @notice Approval implementation
     * @param owner The address of the account which owns tokens
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Arch::_approve: approve from the zero address");
        require(spender != address(0), "Arch::_approve: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _increaseAllowance(
        address owner,
        address spender,
        uint256 addedValue
    ) internal {
        _approve(owner, spender, allowances[owner][spender].add(addedValue));
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal {
        _approve(
            owner,
            spender,
            allowances[owner][spender].sub(
                subtractedValue,
                "Arch::_decreaseAllowance: decreased allowance below zero"
            )
        );
    }

    /**
     * @notice Transfer implementation
     * @param from The address of the account which owns tokens
     * @param to The address of the account which is receiving tokens
     * @param value The number of tokens that are being transferred
     */
    function _transferTokens(address from, address to, uint256 value) internal {
        require(to != address(0), "Arch::_transferTokens: cannot transfer to the zero address");

        balances[from] = balances[from].sub(
            value,
            "Arch::_transferTokens: transfer exceeds from balance"
        );
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @notice Mint implementation
     * @param to The address of the account which is receiving tokens
     * @param value The number of tokens that are being minted
     */
    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balances[to] = balances[to].add(value);
        emit Transfer(address(0), to, value);
    }

    /**
     * @notice Burn implementation
     * @param from The address of the account which owns tokens
     * @param value The number of tokens that are being burned
     */
    function _burn(address from, uint256 value) internal {
        balances[from] = balances[from].sub(
            value,
            "Arch::_burn: burn amount exceeds from balance"
        );
        totalSupply = totalSupply.sub(
            value,
            "Arch::_burn: burn amount exceeds total supply"
        );
        emit Transfer(from, address(0), value);
    }

    /**
     * @notice Current id of the chain where this contract is deployed
     * @return Chain id
     */
    function _getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}