// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable no-empty-blocks
pragma solidity ^0.7.5;

import "@ensdomains/ens/contracts/ENS.sol";
import "./Governance/RadicleToken.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// commitments are kept in a seperate contract to allow the state to be reused
// between different versions of the registrar
contract Commitments {
    address public owner;
    modifier auth {
        require(msg.sender == owner, "Commitments: unauthorized");
        _;
    }
    event SetOwner(address usr);

    /// Mapping from the commitment to the block number in which the commitment was made
    mapping(bytes32 => uint256) public commited;

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address usr) external auth {
        owner = usr;
        emit SetOwner(usr);
    }

    function commit(bytes32 commitment) external auth {
        commited[commitment] = block.number;
    }
}

contract Registrar {
    // --- DATA ---

    /// The ENS registry.
    ENS public immutable ens;

    /// The Radicle ERC20 token.
    RadicleToken public immutable rad;

    /// @notice EIP-712 name for this contract
    string public constant NAME = "Registrar";

    /// The commitment storage contract
    Commitments public immutable commitments = new Commitments();

    /// The namehash of the `eth` TLD in the ENS registry, eg. namehash("eth").
    bytes32 public constant ETH_NODE = keccak256(abi.encodePacked(bytes32(0), keccak256("eth")));

    /// The namehash of the node in the `eth` TLD, eg. namehash("radicle.eth").
    bytes32 public immutable radNode;

    /// The token ID for the node in the `eth` TLD, eg. sha256("radicle").
    uint256 public immutable tokenId;

    /// The minimum number of blocks that must have passed between a commitment and name registration
    uint256 public minCommitmentAge;

    /// Registration fee in *Radicle* (uRads).
    uint256 public registrationFeeRad = 10e18;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant COMMIT_TYPEHASH =
        keccak256("Commit(bytes32 commitment,uint256 nonce,uint256 expiry,uint256 submissionFee)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    // --- LOGS ---

    /// @notice A name was registered.
    event NameRegistered(string indexed name, bytes32 indexed label, address indexed owner);

    /// @notice A commitment was made
    event CommitmentMade(bytes32 commitment, uint256 blockNumber);

    /// @notice The contract admin was changed
    event AdminChanged(address newAdmin);

    /// @notice The registration fee was changed
    event RegistrationRadFeeChanged(uint256 amt);

    /// @notice The ownership of the domain was changed
    event DomainOwnershipChanged(address newOwner);

    /// @notice The resolver changed
    event ResolverChanged(address resolver);

    /// @notice The ttl changed
    event TTLChanged(uint64 amt);

    /// @notice The minimum age for a commitment was changed
    event MinCommitmentAgeChanged(uint256 amt);

    // --- AUTH ---

    /// The contract admin who can set fees.
    address public admin;

    /// Protects admin-only functions.
    modifier adminOnly {
        require(msg.sender == admin, "Registrar: only the admin can perform this action");
        _;
    }

    // --- INIT ---

    constructor(
        ENS _ens,
        RadicleToken _rad,
        address _admin,
        uint256 _minCommitmentAge,
        bytes32 _radNode,
        uint256 _tokenId
    ) {
        ens = _ens;
        rad = _rad;
        admin = _admin;
        minCommitmentAge = _minCommitmentAge;
        radNode = _radNode;
        tokenId = _tokenId;
    }

    // --- USER FACING METHODS ---

    /// Commit to a future name registration
    function commit(bytes32 commitment) public {
        _commit(msg.sender, commitment);
    }

    /// Commit to a future name and submit permit in the same transaction
    function commitWithPermit(
        bytes32 commitment,
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        rad.permit(owner, address(this), value, deadline, v, r, s);
        _commit(msg.sender, commitment);
    }

    /// Commit to a future name with a 712-signed message
    function commitBySig(
        bytes32 commitment,
        uint256 nonce,
        uint256 expiry,
        uint256 submissionFee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator =
            keccak256(
                abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(NAME)), getChainId(), address(this))
            );
        bytes32 structHash =
            keccak256(abi.encode(COMMIT_TYPEHASH, commitment, nonce, expiry, submissionFee));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Registrar::commitBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Registrar::commitBySig: invalid nonce");
        require(block.timestamp <= expiry, "Registrar::commitBySig: signature expired");
        rad.transferFrom(signatory, msg.sender, submissionFee);
        _commit(signatory, commitment);
    }

    /// Commit to a future name with a 712-signed message and submit permit in the same transaction
    function commitBySigWithPermit(
        bytes32 commitment,
        uint256 nonce,
        uint256 expiry,
        uint256 submissionFee,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) public {
        rad.permit(owner, address(this), value, deadline, permitV, permitR, permitS);
        commitBySig(commitment, nonce, expiry, submissionFee, v, r, s);
    }

    function _commit(address payer, bytes32 commitment) internal {
        require(commitments.commited(commitment) == 0, "Registrar::commit: already commited");

        rad.burnFrom(payer, registrationFeeRad);
        commitments.commit(commitment);

        emit CommitmentMade(commitment, block.number);
    }

    /// Register a subdomain
    function register(
        string calldata name,
        address owner,
        uint256 salt
    ) external {
        bytes32 label = keccak256(bytes(name));
        bytes32 commitment = keccak256(abi.encodePacked(name, owner, salt));
        uint256 commited = commitments.commited(commitment);

        require(valid(name), "Registrar::register: invalid name");
        require(available(name), "Registrar::register: name has already been registered");
        require(commited != 0, "Registrar::register: must commit before registration");
        require(
            commited + minCommitmentAge < block.number,
            "Registrar::register: commitment too new"
        );

        ens.setSubnodeRecord(radNode, label, owner, ens.resolver(radNode), ens.ttl(radNode));

        emit NameRegistered(name, label, owner);
    }

    /// Check whether a name is valid.
    function valid(string memory name) public pure returns (bool) {
        uint256 len = bytes(name).length;
        return len >= 2 && len <= 128;
    }

    /// Check whether a name is available for registration.
    function available(string memory name) public view returns (bool) {
        bytes32 label = keccak256(bytes(name));
        bytes32 node = namehash(radNode, label);
        return ens.owner(node) == address(0);
    }

    /// Get the "namehash" of a label.
    function namehash(bytes32 parent, bytes32 label) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, label));
    }

    // --- ADMIN METHODS ---

    /// Set the owner of the domain.
    function setDomainOwner(address newOwner) public adminOnly {
        IERC721 ethRegistrar = IERC721(ens.owner(ETH_NODE));

        ens.setOwner(radNode, newOwner);
        ethRegistrar.transferFrom(address(this), newOwner, tokenId);
        commitments.setOwner(newOwner);

        emit DomainOwnershipChanged(newOwner);
    }

    /// Set a new resolver for radicle.eth.
    function setDomainResolver(address resolver) public adminOnly {
        ens.setResolver(radNode, resolver);
        emit ResolverChanged(resolver);
    }

    /// Set a new ttl for radicle.eth
    function setDomainTTL(uint64 ttl) public adminOnly {
        ens.setTTL(radNode, ttl);
        emit TTLChanged(ttl);
    }

    /// Set the minimum commitment age
    function setMinCommitmentAge(uint256 amt) public adminOnly {
        minCommitmentAge = amt;
        emit MinCommitmentAgeChanged(amt);
    }

    /// Set a new registration fee
    function setRadRegistrationFee(uint256 amt) public adminOnly {
        registrationFeeRad = amt;
        emit RegistrationRadFeeChanged(amt);
    }

    /// Set a new admin
    function setAdmin(address newAdmin) public adminOnly {
        admin = newAdmin;
        emit AdminChanged(newAdmin);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        // solhint-disable no-inline-assembly
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

pragma solidity >=0.4.24;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2020 Compound Labs, Inc.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its
// contributors may be used to endorse or promote products derived from this
// software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

contract RadicleToken {
    /// @notice EIP-20 token name for this token
    string public constant NAME = "Radicle";

    /// @notice EIP-20 token symbol for this token
    string public constant SYMBOL = "RAD";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant DECIMALS = 18;

    /// @notice Total number of tokens in circulation
    uint256 public totalSupply = 100000000e18; // 100 million tokens

    // Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) internal allowances;

    // Official record of token balances for each account
    mapping(address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for EIP-2612 permit
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new token
     * @param account The initial account to grant all the tokens
     */
    constructor(address account) {
        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
    }

    /* @notice Token name */
    function name() public pure returns (string memory) {
        return NAME;
    }

    /* @notice Token symbol */
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    /* @notice Token decimals */
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    /* @notice domainSeparator */
    // solhint-disable func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(NAME)), getChainId(), address(this))
            );
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint256) {
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
    function approve(address spender, uint256 rawAmount) external returns (bool) {
        _approve(msg.sender, spender, rawAmount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 rawAmount
    ) internal {
        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "RadicleToken::approve: amount exceeds 96 bits");
        }

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "RadicleToken::transfer: amount exceeds 96 bits");
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
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "RadicleToken::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance =
                sub96(
                    spenderAllowance,
                    amount,
                    "RadicleToken::transferFrom: transfer amount exceeds spender allowance"
                );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Burn `rawAmount` tokens from `account`
     * @param account The address of the account to burn
     * @param rawAmount The number of tokens to burn
     */
    function burnFrom(address account, uint256 rawAmount) public {
        require(account != address(0), "RadicleToken::burnFrom: cannot burn from the zero address");
        uint96 amount = safe96(rawAmount, "RadicleToken::burnFrom: amount exceeds 96 bits");

        address spender = msg.sender;
        uint96 spenderAllowance = allowances[account][spender];
        if (spender != account && spenderAllowance != uint96(-1)) {
            uint96 newAllowance =
                sub96(
                    spenderAllowance,
                    amount,
                    "RadicleToken::burnFrom: burn amount exceeds allowance"
                );
            allowances[account][spender] = newAllowance;
            emit Approval(account, spender, newAllowance);
        }

        balances[account] = sub96(
            balances[account],
            amount,
            "RadicleToken::burnFrom: burn amount exceeds balance"
        );
        emit Transfer(account, address(0), amount);

        _moveDelegates(delegates[account], address(0), amount);

        totalSupply -= rawAmount;
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
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "RadicleToken::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "RadicleToken::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "RadicleToken::delegateBySig: signature expired");
        _delegate(signatory, delegatee);
    }

    /**
     * @notice Approves spender to spend on behalf of owner.
     * @param owner The signer of the permit
     * @param spender The address to approve
     * @param deadline The time at which the signature expires
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 structHash =
            keccak256(
                abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline)
            );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        require(owner == ecrecover(digest, v, r, s), "RadicleToken::permit: invalid signature");
        require(owner != address(0), "RadicleToken::permit: invalid signature");
        require(block.timestamp <= deadline, "RadicleToken::permit: signature expired");
        _approve(owner, spender, value);
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
    function getPriorVotes(address account, uint256 blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "RadicleToken::getPriorVotes: not yet determined");

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

    function _transferTokens(
        address src,
        address dst,
        uint96 amount
    ) internal {
        require(
            src != address(0),
            "RadicleToken::_transferTokens: cannot transfer from the zero address"
        );
        require(
            dst != address(0),
            "RadicleToken::_transferTokens: cannot transfer to the zero address"
        );

        balances[src] = sub96(
            balances[src],
            amount,
            "RadicleToken::_transferTokens: transfer amount exceeds balance"
        );
        balances[dst] = add96(
            balances[dst],
            amount,
            "RadicleToken::_transferTokens: transfer amount overflows"
        );
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew =
                    sub96(srcRepOld, amount, "RadicleToken::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew =
                    add96(dstRepOld, amount, "RadicleToken::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber =
            safe32(block.number, "RadicleToken::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        // solhint-disable no-inline-assembly
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}