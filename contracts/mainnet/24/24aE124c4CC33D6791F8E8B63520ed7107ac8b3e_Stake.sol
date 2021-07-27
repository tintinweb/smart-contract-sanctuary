/*
    Copyright 2020, 2021 Empty Set Squad <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Decimal.sol";

/**
 * @title IManagedToken
 * @notice Generic interface for ERC20 tokens that can be minted and burned by their owner
 * @dev Used by Dollar and Stake in this protocol
 */
interface IManagedToken {

    /**
     * @notice Mints `amount` tokens to the {owner}
     * @param amount Amount of token to mint
     */
    function burn(uint256 amount) external;

    /**
     * @notice Burns `amount` tokens from the {owner}
     * @param amount Amount of token to burn
     */
    function mint(uint256 amount) external;
}

/**
 * @title IGovToken
 * @notice Generic interface for ERC20 tokens that have Compound-governance features
 * @dev Used by Stake and other compatible reserve-held tokens
 */
interface IGovToken {

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external;
}

/**
 * @title IReserve
 * @notice Interface for the protocol reserve
 */
interface IReserve {
    /**
     * @notice The price that one ESD can currently be sold to the reserve for
     * @dev Returned as a Decimal.D256
     *      Normalizes for decimals (e.g. 1.00 USDC == Decimal.one())
     * @return Current ESD redemption price
     */
    function redeemPrice() external view returns (Decimal.D256 memory);
}

interface IRegistry {
    /**
     * @notice USDC token contract
     */
    function usdc() external view returns (address);

    /**
     * @notice Compound protocol cUSDC pool
     */
    function cUsdc() external view returns (address);

    /**
     * @notice ESD stablecoin contract
     */
    function dollar() external view returns (address);

    /**
     * @notice ESDS governance token contract
     */
    function stake() external view returns (address);

    /**
     * @notice ESD reserve contract
     */
    function reserve() external view returns (address);

    /**
     * @notice ESD governor contract
     */
    function governor() external view returns (address);

    /**
     * @notice ESD timelock contract, owner for the protocol
     */
    function timelock() external view returns (address);

    /**
     * @notice Migration contract to bride v1 assets with current system
     */
    function migrator() external view returns (address);

    /**
     * @notice Registers a new address for USDC
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setUsdc(address newValue) external;

    /**
     * @notice Registers a new address for cUSDC
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setCUsdc(address newValue) external;

    /**
     * @notice Registers a new address for ESD
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setDollar(address newValue) external;

    /**
     * @notice Registers a new address for ESDS
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setStake(address newValue) external;

    /**
     * @notice Registers a new address for the reserve
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setReserve(address newValue) external;

    /**
     * @notice Registers a new address for the governor
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setGovernor(address newValue) external;

    /**
     * @notice Registers a new address for the timelock
     * @dev Owner only - governance hook
     *      Does not automatically update the owner of all owned protocol contracts
     * @param newValue New address to register
     */
    function setTimelock(address newValue) external;

    /**
     * @notice Registers a new address for the v1 migration contract
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setMigrator(address newValue) external;
}

/*
    Copyright 2021 Empty Set Squad <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../Interfaces.sol";

/*
 * audit-info: Forked from Compound's Comp contract:
 *             https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol
 *
 *             Sections that have been changed from the original have been denoted with audit notes
 *             Additionally "Comp" has been renamed to "Stake" throughout
 */

/*
 * audit-info: Beginning of modified code section
 */

contract Stake is IManagedToken, Ownable {

    /// @notice EIP-20 token name for this token
    string public constant name = "Empty Set Share";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "ESS";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    /// @dev Initialized at 0, use mint() for initial distribution to migrator & incentivizer(s)
    uint public totalSupply;

    /*
     * audit-info: End of modified code section
     */

    /// @notice Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*
     * audit-info: Beginning of modified code section
     */

    /**
     * @notice Mint new tokens
     * @param rawAmount The number of tokens to be minted
     */
    function mint(uint rawAmount) public onlyOwner {
        // mint the amount
        uint96 amount = safe96(rawAmount, "Stake::mint: amount exceeds 96 bits");
        totalSupply = safe96(SafeMath.add(totalSupply, amount), "Stake::mint: totalSupply exceeds 96 bits");

        // transfer the amount to the recipient
        balances[owner()] = add96(balances[owner()], amount, "Stake::mint: transfer amount overflows");
        emit Transfer(address(0), owner(), amount);

        // move delegates
        _moveDelegates(address(0), delegates[owner()], amount);
    }

    /**
     * @notice Mint new tokens
     * @param rawAmount The number of tokens to be minted
     */
    function burn(uint rawAmount) public onlyOwner {
        // burn the amount
        uint96 amount = safe96(rawAmount, "Stake::burn: amount exceeds 96 bits");
        totalSupply = safe96(
            SafeMath.sub(totalSupply, amount, "Stake::burn: amount exceeds totalSupply"),
            "Stake::burn: totalSupply exceeds 96 bits");

        // transfer the amount to the recipient
        balances[owner()] = sub96(balances[owner()], amount, "Stake::burn: transfer amount overflows");
        emit Transfer(owner(), address(0), amount);

        // move delegates
        _moveDelegates(delegates[owner()], address(0), amount);
    }

    /*
     * audit-info: End of modified code section
     */

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
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "Stake::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
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
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Stake::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "Stake::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "Stake::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Stake::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Stake::delegateBySig: invalid nonce");
        require(now <= expiry, "Stake::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "Stake::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "Stake::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Stake::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "Stake::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "Stake::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "Stake::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "Stake::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "Stake::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

/*
    Copyright 2019 dYdX Trading Inc.
    Copyright 2020, 2021 Empty Set Squad <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Decimal
 * @notice Library that defines a fixed-point number with 18 decimal places.
 *
 * audit-info: Extended from dYdX's Decimal library:
 *             https://github.com/dydxprotocol/solo/blob/master/contracts/protocol/lib/Decimal.sol
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    /**
     * @notice Fixed-point base for Decimal.D256 values
     */
    uint256 constant BASE = 10**18;

    // ============ Structs ============


    /**
     * @notice Main struct to hold Decimal.D256 state
     * @dev Represents the number value / BASE
     */
    struct D256 {
        /**
         * @notice Underlying value of the Decimal.D256
         */
        uint256 value;
    }

    // ============ Static Functions ============

    /**
     * @notice Returns a new Decimal.D256 struct initialized to represent 0.0
     * @return Decimal.D256 representation of 0.0
     */
    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    /**
     * @notice Returns a new Decimal.D256 struct initialized to represent 1.0
     * @return Decimal.D256 representation of 1.0
     */
    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    /**
     * @notice Returns a new Decimal.D256 struct initialized to represent `a`
     * @param a Integer to transform to Decimal.D256 type
     * @return Decimal.D256 representation of integer`a`
     */
    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    /**
     * @notice Returns a new Decimal.D256 struct initialized to represent `a` / `b`
     * @param a Numerator of ratio to transform to Decimal.D256 type
     * @param b Denominator of ratio to transform to Decimal.D256 type
     * @return Decimal.D256 representation of ratio `a` / `b`
     */
    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    /**
     * @notice Adds integer `b` to Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Integer to add to `self`
     * @return Resulting Decimal.D256
     */
    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    /**
     * @notice Subtracts integer `b` from Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Integer to subtract from `self`
     * @return Resulting Decimal.D256
     */
    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    /**
     * @notice Subtracts integer `b` from Decimal.D256 `self`
     * @dev Reverts on underflow with reason `reason`
     * @param self Original Decimal.D256 number
     * @param b Integer to subtract from `self`
     * @param reason Revert reason
     * @return Resulting Decimal.D256
     */
    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    /**
     * @notice Subtracts integer `b` from Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Integer to subtract from `self`
     * @return 0 on underflow, or the Resulting Decimal.D256
     */
    function subOrZero(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        uint256 amount = b.mul(BASE);
        return D256({ value: self.value > amount ? self.value.sub(amount) : 0 });
    }

    /**
     * @notice Multiplies Decimal.D256 `self` by integer `b`
     * @param self Original Decimal.D256 number
     * @param b Integer to multiply `self` by
     * @return Resulting Decimal.D256
     */
    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    /**
     * @notice Divides Decimal.D256 `self` by integer `b`
     * @param self Original Decimal.D256 number
     * @param b Integer to divide `self` by
     * @return Resulting Decimal.D256
     */
    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    /**
     * @notice Divides Decimal.D256 `self` by integer `b`
     * @dev Reverts on divide-by-zero with reason `reason`
     * @param self Original Decimal.D256 number
     * @param b Integer to divide `self` by
     * @param reason Revert reason
     * @return Resulting Decimal.D256
     */
    function div(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b, reason) });
    }

    /**
     * @notice Exponentiates Decimal.D256 `self` to the power of integer `b`
     * @dev Not optimized - is only suitable to use with small exponents
     * @param self Original Decimal.D256 number
     * @param b Integer exponent
     * @return Resulting Decimal.D256
     */
    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    /**
     * @notice Adds Decimal.D256 `b` to Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to add to `self`
     * @return Resulting Decimal.D256
     */
    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    /**
     * @notice Subtracts Decimal.D256 `b` from Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to subtract from `self`
     * @return Resulting Decimal.D256
     */
    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    /**
     * @notice Subtracts Decimal.D256 `b` from Decimal.D256 `self`
     * @dev Reverts on underflow with reason `reason`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to subtract from `self`
     * @param reason Revert reason
     * @return Resulting Decimal.D256
     */
    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    /**
     * @notice Subtracts Decimal.D256 `b` from Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to subtract from `self`
     * @return 0 on underflow, or the Resulting Decimal.D256
     */
    function subOrZero(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value > b.value ? self.value.sub(b.value) : 0 });
    }

    /**
     * @notice Multiplies Decimal.D256 `self` by Decimal.D256 `b`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to multiply `self` by
     * @return Resulting Decimal.D256
     */
    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    /**
     * @notice Divides Decimal.D256 `self` by Decimal.D256 `b`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to divide `self` by
     * @return Resulting Decimal.D256
     */
    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    /**
     * @notice Divides Decimal.D256 `self` by Decimal.D256 `b`
     * @dev Reverts on divide-by-zero with reason `reason`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to divide `self` by
     * @param reason Revert reason
     * @return Resulting Decimal.D256
     */
    function div(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value, reason) });
    }

    /**
     * @notice Checks if `b` is equal to `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is equal to `self`
     */
    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    /**
     * @notice Checks if `b` is greater than `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is greater than `self`
     */
    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    /**
     * @notice Checks if `b` is less than `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is less than `self`
     */
    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    /**
     * @notice Checks if `b` is greater than or equal to `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is greater than or equal to `self`
     */
    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    /**
     * @notice Checks if `b` is less than or equal to `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is less than or equal to `self`
     */
    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    /**
     * @notice Checks if `self` is equal to 0
     * @param self Original Decimal.D256 number
     * @return Whether `self` is equal to 0
     */
    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    /**
     * @notice Truncates the decimal part of `self` and returns the integer value as a uint256
     * @param self Original Decimal.D256 number
     * @return Truncated Integer value as a uint256
     */
    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ General Math ============

    /**
     * @notice Determines the minimum of `a` and `b`
     * @param a First Decimal.D256 number to compare
     * @param b Second Decimal.D256 number to compare
     * @return Resulting minimum Decimal.D256
     */
    function min(D256 memory a, D256 memory b) internal pure returns (Decimal.D256 memory) {
        return lessThan(a, b) ? a : b;
    }

    /**
     * @notice Determines the maximum of `a` and `b`
     * @param a First Decimal.D256 number to compare
     * @param b Second Decimal.D256 number to compare
     * @return Resulting maximum Decimal.D256
     */
    function max(D256 memory a, D256 memory b) internal pure returns (Decimal.D256 memory) {
        return greaterThan(a, b) ? a : b;
    }

    // ============ Core Methods ============

    /**
     * @notice Multiplies `target` by ratio `numerator` / `denominator`
     * @dev Internal only - helper
     * @param target Original Integer number
     * @param numerator Integer numerator of ratio
     * @param denominator Integer denominator of ratio
     * @return Resulting Decimal.D256 number
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    /**
     * @notice Multiplies `target` by ratio `numerator` / `denominator`
     * @dev Internal only - helper
     *      Reverts on divide-by-zero with reason `reason`
     * @param target Original Integer number
     * @param numerator Integer numerator of ratio
     * @param denominator Integer denominator of ratio
     * @param reason Revert reason
     * @return Resulting Decimal.D256 number
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator,
        string memory reason
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator, reason);
    }

    /**
     * @notice Compares Decimal.D256 `a` to Decimal.D256 `b`
     * @dev Internal only - helper
     * @param a First Decimal.D256 number to compare
     * @param b Second Decimal.D256 number to compare
     * @return 0 if a < b, 1 if a == b, 2 if a > b
     */
    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
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
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}