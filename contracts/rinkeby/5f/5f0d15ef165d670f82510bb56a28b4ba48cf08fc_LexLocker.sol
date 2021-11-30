/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from RariCapital (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// License-Identifier: AGPL-3.0-only
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

/// @notice Minimal BentoBox vault interface.
/// @dev `token` is aliased as `address` from `IERC20` for simplicity.
interface IBentoBoxMinimal {
    /// @notice Registers contract so that users can approve it for BentoBox.
    function registerProtocol() external;

    /// @notice Provides way for users to sign approval for BentoBox spends.
    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount represented in shares.
    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;
}

/// @notice Bilateral escrow for ETH and ERC-20/721 tokens with BentoBox integration.
/// @author LexDAO LLC.
contract LexLocker {
    IBentoBoxMinimal immutable bento;
    address public lexDAO;
    address immutable wETH;
    
    uint256 public lockerCount;
    
    /// @dev Chain Id at this contract's deployment.
    uint256 immutable INITIAL_CHAIN_ID;
    /// @dev EIP-712 typehash for this contract's domain at deployment.
    bytes32 immutable INITIAL_DOMAIN_SEPARATOR;
    /// @dev EIP-712 typehash for invoicing deposits.
    bytes32 constant INVOICE_HASH = keccak256("DepositInvoiceSig(address depositor,address receiver,address resolver,string details)");

    mapping(uint256 => string) public agreements;
    mapping(uint256 => Locker) public lockers;
    mapping(address => Resolver) public resolvers;
    mapping(address => uint256) public lastActionTimestamp;
    
    /// @notice Initialize contract.
    /// @param bento_ BentoBox vault contract.
    /// @param lexDAO_ Legal engineering guild.
    /// @param wETH_ Wrapped ether (or native asset) supported on BentoBox.
    constructor(IBentoBoxMinimal bento_, address lexDAO_, address wETH_) {
        bento_.registerProtocol();
        bento = bento_;
        lexDAO = lexDAO_;
        wETH = wETH_;
        
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }
    
    /// @dev Events to assist web3 applications.
    event Deposit(
        bool bento,
        bool nft,
        address indexed depositor, 
        address indexed receiver, 
        address resolver,
        address token, 
        uint256 sum,
        uint256 termination,
        uint256 indexed registration,
        string details);
    event DepositInvoiceSig(address indexed depositor, address indexed receiver);
    event Release(uint256 indexed registration);
    event Withdraw(uint256 indexed registration);
    event Lock(uint256 indexed registration, string details);
    event Resolve(uint256 indexed registration, uint256 indexed depositorAward, uint256 indexed receiverAward, string details);
    event RegisterResolver(address indexed resolver, bool indexed active, uint256 indexed fee);
    event RegisterAgreement(uint256 indexed index, string agreement);
    event UpdateLexDAO(address indexed lexDAO);
    
    /// @dev Tracks registered escrow status.
    struct Locker {
        bool bento;
        bool nft; 
        bool locked;
        address depositor;
        address receiver;
        address resolver;
        address token;
        uint256[] value;
        uint256 currentMilestone;
        uint256 paid;
        uint256 sum;
        uint256 termination;
    }
    
    /// @dev Tracks registered resolver status.
    struct Resolver {
        bool active;
        uint8 fee;
    }
    
    /// @dev Ensures registered resolver cooldown.
    modifier cooldown() {
        unchecked {
            require(block.timestamp - lastActionTimestamp[msg.sender] > 8 weeks, "NOT_COOLED_DOWN");
        }
        _;
    }
    
    /// @dev Reentrancy guard.
    uint256 unlocked = 1;
    modifier nonReentrant() {
        require(unlocked == 1, "LOCKED");
        unlocked = 2;
        _;
        unlocked = 1;
    }
    
    /// @notice EIP-712 typehash for this contract's domain.
    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeparator) {
        domainSeparator = block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }
    
    function _computeDomainSeparator() private view returns (bytes32 domainSeparator) {
        domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("LexLocker")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
    
    // **** ESCROW PROTOCOL **** //
    // ------------------------ //
    
    /// @notice Returns escrow milestone deposits per `value` array.
    /// @param registration The index of escrow deposit.
    function getMilestones(uint256 registration) external view returns (uint256[] memory milestones) {
        milestones = lockers[registration].value;
    }
    
    /// @notice Deposits tokens (ERC-20/721) into escrow 
    /// - locked funds can be released by `msg.sender` `depositor` 
    /// - both parties can {lock} for `resolver`. 
    /// @param receiver The account that receives funds.
    /// @param resolver The account that unlock funds.
    /// @param token The asset used for funds.
    /// @param value The amount of funds in milestones - if `nft`, the 'tokenId' in first value is used.
    /// @param termination Unix time upon which `depositor` can claim back funds.
    /// @param nft If 'false', ERC-20 is assumed, otherwise, non-fungible asset.
    /// @param details Describes context of escrow - stamped into event.
    function deposit(
        address receiver, 
        address resolver, 
        address token, 
        uint256[] memory value,
        uint256 termination,
        bool nft, 
        string memory details
    ) public payable nonReentrant returns (uint256 registration) {
        require(resolvers[resolver].active, "RESOLVER_NOT_ACTIVE");
        require(resolver != msg.sender && resolver != receiver, "RESOLVER_CANNOT_BE_PARTY"); // Avoid conflicts.
        
        // Tally up `sum` from `value` milestones.
        uint256 sum;
        unchecked {
            for (uint256 i = 0; i < value.length; i++) {
                sum += value[i];
            }
        }
        
        // Handle ETH/ERC-20/721 deposit.
        if (msg.value != 0) {
            require(msg.value == sum, "WRONG_MSG_VALUE");
            // Overrides to clarify ETH is used.
            if (token != address(0)) token = address(0);
            if (nft) nft = false;
        } else {
            SafeTransferLib.safeTransferFrom(token, msg.sender, address(this), sum);
        }
 
        registration = lockerCount;
        lockers[registration] = 
            Locker(
                false, nft, false, msg.sender, receiver, resolver, token, value, 0, 0, sum, termination);
        
        // Increment registered lockers.
        unchecked {
            lockerCount++;
        }
        
        emit Deposit(false, nft, msg.sender, receiver, resolver, token, sum, termination, registration, details);
    }
    
    /// @notice Deposits tokens (ERC-20/721) into BentoBox escrow 
    /// - locked funds can be released by `msg.sender` `depositor` 
    /// - both parties can {lock} for `resolver`. 
    /// @param receiver The account that receives funds.
    /// @param resolver The account that unlock funds.
    /// @param token The asset used for funds (note: NFT not supported in BentoBox).
    /// @param value The amount of funds in milestones (note: locker converts to 'shares').
    /// @param termination Unix time upon which `depositor` can claim back funds.
    /// @param wrapBento If 'false', raw ERC-20 is assumed, otherwise, BentoBox 'shares'.
    /// @param details Describes context of escrow - stamped into event.
    function depositBento(
        address receiver, 
        address resolver, 
        address token, 
        uint256[] memory value,
        uint256 termination,
        bool wrapBento,
        string memory details
    ) public payable nonReentrant returns (uint256 registration) {
        require(resolvers[resolver].active, "RESOLVER_NOT_ACTIVE");
        require(resolver != msg.sender && resolver != receiver, "RESOLVER_CANNOT_BE_PARTY"); // Avoid conflicts.
        
        // Tally up `sum` from `value` milestones.
        uint256 sum;
        unchecked {
            for (uint256 i = 0; i < value.length; i++) {
                sum += value[i];
            }
        }
        
        // Handle ETH/ERC-20 deposit.
        if (msg.value != 0) {
            require(msg.value == sum, "WRONG_MSG_VALUE");
            // Override to clarify wETH is used in BentoBox for ETH.
            if (token != wETH) token = wETH;
            (, sum) = bento.deposit{value: msg.value}(address(0), address(this), address(this), msg.value, 0);
        } else if (wrapBento) {
            SafeTransferLib.safeTransferFrom(token, msg.sender, address(bento), sum);
            (, sum) = bento.deposit(token, address(bento), address(this), sum, 0);
        } else {
            bento.transfer(token, msg.sender, address(this), sum);
        }

        registration = lockerCount;
        lockers[registration] = 
        Locker(
            true, false, false, msg.sender, receiver, resolver, token, value, 0, 0, sum, termination);
        
        // Increment registered lockers.
        unchecked {
            lockerCount++;
        }
        
        emit Deposit(false, false, msg.sender, receiver, resolver, token, sum, termination, registration, details);
    }
    
    /// @notice Validates deposit request 'invoice' for locker escrow.
    /// @param receiver The account that receives funds.
    /// @param resolver The account that unlock funds.
    /// @param token The asset used for funds.
    /// @param value The amount of funds in milestones - if `nft`, the 'tokenId'.
    /// @param termination Unix time upon which `depositor` can claim back funds.
    /// @param bentoBoxed If 'false', regular deposit is assumed, otherwise, BentoBox.
    /// @param nft If 'false', ERC-20 is assumed, otherwise, non-fungible asset.
    /// @param wrapBento If 'false', raw ERC-20 is assumed, otherwise, BentoBox 'shares'.
    /// @param details Describes context of escrow - stamped into event.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function depositInvoiceSig(
        address receiver, 
        address resolver, 
        address token, 
        uint256[] memory value,
        uint256 termination,
        bool bentoBoxed,
        bool nft, 
        bool wrapBento,
        string memory details,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        // Validate basic elements of invoice.
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            INVOICE_HASH,
                            msg.sender,
                            receiver,
                            resolver,
                            details
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == receiver, "INVALID_INVOICE");

        // Perform deposit.
        if (!bentoBoxed) {
            deposit(receiver, resolver, token, value, termination, nft, details);
        } else {
            depositBento(receiver, resolver, token, value, termination, wrapBento, details);
        }
        
        emit DepositInvoiceSig(msg.sender, receiver);
    }
    
    /// @notice Releases escrowed assets to designated `receiver` 
    /// - can only be called by `depositor` if not `locked`
    /// - can be called after `termination` as optional extension
    /// - escrowed sum is released in order of `value` milestones array.
    /// @param registration The index of escrow deposit.
    function release(uint256 registration) external nonReentrant {
        Locker storage locker = lockers[registration]; 
        
        require(!locker.locked, "LOCKED");
        require(msg.sender == locker.depositor, "NOT_DEPOSITOR");
        
        unchecked {
            // Handle asset transfer.
            if (locker.token == address(0)) { // Release ETH.
                SafeTransferLib.safeTransferETH(locker.receiver, locker.value[locker.currentMilestone]);
                locker.paid += locker.value[locker.currentMilestone];
                locker.currentMilestone++;
            } else if (locker.bento) { // Release BentoBox shares.
                bento.transfer(locker.token, address(this), locker.receiver, locker.value[locker.currentMilestone]);
                locker.paid += locker.value[locker.currentMilestone];
                locker.currentMilestone++;
            } else if (!locker.nft) { // ERC-20.
                SafeTransferLib.safeTransfer(locker.token, locker.receiver, locker.value[locker.currentMilestone]);
                locker.paid += locker.value[locker.currentMilestone];
                locker.currentMilestone++;
            } else { // Release NFT (note: set to single milestone).
                SafeTransferLib.safeTransferFrom(locker.token, address(this), locker.receiver, locker.value[0]);
                locker.paid += locker.value[0];
            }
        }
        
        // If remainder paid out or NFT released, delete from storage.
        if (locker.paid == locker.sum) {
            delete lockers[registration];
        }
        
        emit Release(registration);
    }
    
    /// @notice Releases escrowed assets back to designated `depositor` 
    /// - can only be called by `depositor` if `termination` reached.
    /// @param registration The index of escrow deposit.
    function withdraw(uint256 registration) external nonReentrant {
        Locker storage locker = lockers[registration];
        
        require(msg.sender == locker.depositor, "NOT_DEPOSITOR");
        require(!locker.locked, "LOCKED");
        require(block.timestamp >= locker.termination, "NOT_TERMINATED");
        
        // Handle asset transfer.
        unchecked {
            if (locker.token == address(0)) { // Release ETH.
                SafeTransferLib.safeTransferETH(locker.depositor, locker.sum - locker.paid);
            } else if (locker.bento) { // Release BentoBox shares.
                bento.transfer(locker.token, address(this), locker.depositor, locker.sum - locker.paid);
            } else if (!locker.nft) { // Release ERC-20.
                SafeTransferLib.safeTransfer(locker.token, locker.depositor, locker.sum - locker.paid);
            } else { // Release NFT.
                SafeTransferLib.safeTransferFrom(locker.token, address(this), locker.depositor, locker.value[0]);
            }
        }
        
        delete lockers[registration];
        
        emit Withdraw(registration);
    }

    // **** DISPUTE PROTOCOL **** //
    // ------------------------- //
    
    /// @notice Locks escrowed assets for resolution - can only be called by locker parties.
    /// @param registration The index of escrow deposit.
    /// @param details Description of lock action (note: can link to secure dispute details, etc.).
    function lock(uint256 registration, string calldata details) external nonReentrant {
        Locker storage locker = lockers[registration];
        
        require(msg.sender == locker.depositor || msg.sender == locker.receiver, "NOT_PARTY");
        
        locker.locked = true;
        
        emit Lock(registration, details);
    }
    
    /// @notice Resolves locked escrow deposit in split between parties - if NFT, must be complete award (so, one party receives '0')
    /// - `resolverFee` is automatically deducted from both parties' awards.
    /// @param registration The registration index of escrow deposit.
    /// @param depositorAward The sum given to `depositor`.
    /// @param receiverAward The sum given to `receiver`.
    /// @param details Description of resolution (note: can link to secure judgment details, etc.).
    function resolve(uint256 registration, uint256 depositorAward, uint256 receiverAward, string calldata details) external nonReentrant {
        Locker storage locker = lockers[registration]; 
        
        uint256 remainder = locker.sum - locker.paid;
        
        require(msg.sender == locker.resolver, "NOT_RESOLVER");
        require(locker.locked, "NOT_LOCKED");
        require(depositorAward + receiverAward == remainder, "NOT_REMAINDER");

        // Calculate resolution fee from remainder and apply to awards.
        uint256 resolverFee = remainder / resolvers[locker.resolver].fee;
        depositorAward -= resolverFee / 2;
        receiverAward -= resolverFee / 2;
        
        // Handle asset transfers.
        if (locker.token == address(0)) { // Split ETH.
            SafeTransferLib.safeTransferETH(locker.depositor, depositorAward);
            SafeTransferLib.safeTransferETH(locker.receiver, receiverAward);
            SafeTransferLib.safeTransferETH(locker.resolver, resolverFee);
        } else if (locker.bento) { // ...BentoBox shares.
            bento.transfer(locker.token, address(this), locker.depositor, depositorAward);
            bento.transfer(locker.token, address(this), locker.receiver, receiverAward);
            bento.transfer(locker.token, address(this), locker.resolver, resolverFee);
        } else if (!locker.nft) { // ...ERC20.
            SafeTransferLib.safeTransfer(locker.token, locker.depositor, depositorAward);
            SafeTransferLib.safeTransfer(locker.token, locker.receiver, receiverAward);
            SafeTransferLib.safeTransfer(locker.token, locker.resolver, resolverFee);
        } else { // Award NFT.
            if (depositorAward != 0) {
                SafeTransferLib.safeTransferFrom(locker.token, address(this), locker.depositor, locker.value[0]);
            } else {
                SafeTransferLib.safeTransferFrom(locker.token, address(this), locker.receiver, locker.value[0]);
            }
        }
        
        delete lockers[registration];
        
        emit Resolve(registration, depositorAward, receiverAward, details);
    }
    
    /// @notice Registers an account to serve as a potential `resolver`.
    /// @param active Tracks willingness to serve - if 'true', can be joined to a locker.
    /// @param fee The divisor to determine resolution fee - e.g., if '20', fee is 5% of locker.
    function registerResolver(bool active, uint8 fee) external cooldown nonReentrant {
        require(fee != 0, "FEE_MUST_BE_GREATER_THAN_ZERO");
        resolvers[msg.sender] = Resolver(active, fee);
        lastActionTimestamp[msg.sender] = block.timestamp;
        emit RegisterResolver(msg.sender, active, fee);
    }

    // **** LEXDAO PROTOCOL **** //
    // ------------------------ //
    
    /// @notice Protocol for LexDAO to maintain agreements that can be stamped into lockers.
    /// @param index # to register agreement under.
    /// @param agreement Text or link to agreement, etc. - this allows for amendments.
    function registerAgreement(uint256 index, string calldata agreement) external {
        require(msg.sender == lexDAO, "NOT_LEXDAO");
        agreements[index] = agreement;
        emit RegisterAgreement(index, agreement);
    }

    /// @notice Protocol for LexDAO to update role.
    /// @param lexDAO_ Account to assign role to.
    function updateLexDAO(address lexDAO_) external {
        require(msg.sender == lexDAO, "NOT_LEXDAO");
        lexDAO = lexDAO_;
        emit UpdateLexDAO(lexDAO_);
    }

    // **** BATCHER UTILITIES **** //
    // -------------------------- //
    
    /// @notice Enables calling multiple methods in a single call to this contract.
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(data[i]);
                if (!success) {
                    if (result.length < 68) revert();
                    assembly { 
                        result := add(result, 0x04) 
                    }
                    revert(abi.decode(result, (string)));
                }
                results[i] = result;
            }
        }
    }

    /// @notice Provides EIP-2612 signed approval for this contract to spend user tokens.
    /// @param token Address of ERC-20 token.
    /// @param amount Token amount to grant spending right over.
    /// @param deadline Termination for signed approval in Unix time.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permitThis(
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // permit(address,address,uint256,uint256,uint8,bytes32,bytes32).
        (bool success, ) = token.call(abi.encodeWithSelector(0xd505accf, msg.sender, address(this), amount, deadline, v, r, s));
        require(success, "PERMIT_FAILED");
    }

    /// @notice Provides DAI-derived signed approval for this contract to spend user tokens.
    /// @param token Address of ERC-20 token.
    /// @param nonce Token owner's nonce - increases at each call to {permit}.
    /// @param expiry Termination for signed approval in Unix time.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permitThisAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // permit(address,address,uint256,uint256,bool,uint8,bytes32,bytes32).
        (bool success, ) = token.call(abi.encodeWithSelector(0x8fcbaf0c, msg.sender, address(this), nonce, expiry, true, v, r, s));
        require(success, "PERMIT_FAILED");
    }

    /// @notice Provides way to sign approval for `bento` spends by locker.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function setBentoApproval(uint8 v, bytes32 r, bytes32 s) external {
        bento.setMasterContractApproval(msg.sender, address(this), true, v, r, s);
    }
}