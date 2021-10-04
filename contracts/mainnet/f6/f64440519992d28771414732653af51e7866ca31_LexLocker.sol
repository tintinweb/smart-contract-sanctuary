/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

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

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

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
    uint256 lockerCount;
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant INVOICE_HASH = keccak256("DepositWithInvoiceSig(address depositor,address receiver,address resolver,string details)");

    mapping(uint256 => string) public agreements;
    mapping(uint256 => Locker) public lockers;
    mapping(address => Resolver) public resolvers;

    constructor(IBentoBoxMinimal _bento, address _lexDAO, address _wETH) {
        bento = _bento;
        bento.registerProtocol();
        lexDAO = _lexDAO;
        wETH = _wETH;
        
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("LexLocker")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
    
    /// @dev Events to assist web3 applications.
    event Deposit(
        bool bento,
        bool nft,
        address indexed depositor, 
        address indexed receiver, 
        address resolver,
        address token, 
        uint256 value, 
        uint256 indexed registration,
        string details);
    event DepositWithInvoiceSig(address indexed depositor, address indexed receiver);
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
        uint256 value;
        uint256 termination;
    }
    
    /// @dev Tracks registered resolver status.
    struct Resolver {
        bool active;
        uint8 fee;
    }
    
    // **** ESCROW PROTOCOL **** //
    // ------------------------ //
    /// @notice Deposits tokens (ERC-20/721) into escrow 
    /// - locked funds can be released by `msg.sender` `depositor` 
    /// - both parties can {lock} for `resolver`. 
    /// @param receiver The account that receives funds.
    /// @param resolver The account that unlock funds.
    /// @param token The asset used for funds.
    /// @param value The amount of funds - if `nft`, the 'tokenId' in first value is used.
    /// @param termination Unix time upon which `depositor` can claim back funds.
    /// @param nft If 'false', ERC-20 is assumed, otherwise, non-fungible asset.
    /// @param details Describes context of escrow - stamped into event.
    function deposit(
        address receiver, 
        address resolver, 
        address token, 
        uint256 value,
        uint256 termination,
        bool nft, 
        string memory details
    ) public payable returns (uint256 registration) {
        require(resolvers[resolver].active, "resolver not active");
        require(resolver != msg.sender && resolver != receiver, "resolver cannot be party"); /// @dev Avoid conflicts.
   
        /// @dev Handle ETH/ERC-20/721 deposit.
        if (msg.value != 0) {
            require(msg.value == value, "wrong msg.value");
            /// @dev Overrides to clarify ETH is used.
            if (token != address(0)) token = address(0);
            if (nft) nft = false;
        } else {
            safeTransferFrom(token, msg.sender, address(this), value);
        }
 
        /// @dev Increment registered lockers and assign # to escrow deposit.
        unchecked {
            lockerCount++;
        }
        registration = lockerCount;
        lockers[registration] = Locker(false, nft, false, msg.sender, receiver, resolver, token, value, termination);
        
        emit Deposit(false, nft, msg.sender, receiver, resolver, token, value, registration, details);
    }

    /// @notice Deposits tokens (ERC-20/721) into BentoBox escrow 
    /// - locked funds can be released by `msg.sender` `depositor` 
    /// - both parties can {lock} for `resolver`. 
    /// @param receiver The account that receives funds.
    /// @param resolver The account that unlock funds.
    /// @param token The asset used for funds (note: NFT not supported in BentoBox).
    /// @param value The amount of funds (note: locker converts to 'shares').
    /// @param termination Unix time upon which `depositor` can claim back funds.
    /// @param wrapBento If 'false', raw ERC-20 is assumed, otherwise, BentoBox 'shares'.
    /// @param details Describes context of escrow - stamped into event.
    function depositBento(
        address receiver, 
        address resolver, 
        address token, 
        uint256 value,
        uint256 termination,
        bool wrapBento,
        string memory details
    ) public payable returns (uint256 registration) {
        require(resolvers[resolver].active, "resolver not active");
        require(resolver != msg.sender && resolver != receiver, "resolver cannot be party"); /// @dev Avoid conflicts.
 
        /// @dev Conversion/check for BentoBox shares.
        value = bento.toShare(token, value, false);

        /// @dev Handle ETH/ERC-20 deposit.
        if (msg.value != 0) {
            require(msg.value == value, "wrong msg.value");
            /// @dev Override to clarify wETH is used in BentoBox for ETH.
            if (token != wETH) token = wETH;
            bento.deposit{value: msg.value}(address(0), address(this), address(this), 0, msg.value);
        } else if (wrapBento) {
            safeTransferFrom(token, msg.sender, address(bento), value);
            bento.deposit(token, address(bento), address(this), 0, value);
        } else {
            bento.transfer(token, msg.sender, address(this), value);
        }

        /// @dev Increment registered lockers and assign # to escrow deposit.
        unchecked {
            lockerCount++;
        }
        registration = lockerCount;
        lockers[registration] = Locker(true, false, false, msg.sender, receiver, resolver, token, value, termination);
        
        emit Deposit(true, false, msg.sender, receiver, resolver, token, value, registration, details);
    }
    
    /// @notice Validates deposit request 'invoice' for locker escrow.
    /// @param receiver The account that receives funds.
    /// @param resolver The account that unlock funds.
    /// @param token The asset used for funds.
    /// @param value The amount of funds - if `nft`, the 'tokenId'.
    /// @param termination Unix time upon which `depositor` can claim back funds.
    /// @param bentoBoxed If 'false', regular deposit is assumed, otherwise, BentoBox.
    /// @param nft If 'false', ERC-20 is assumed, otherwise, non-fungible asset.
    /// @param wrapBento If 'false', raw ERC-20 is assumed, otherwise, BentoBox 'shares'.
    /// @param details Describes context of escrow - stamped into event.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function depositWithInvoiceSig(
        address receiver, 
        address resolver, 
        address token, 
        uint256 value,
        uint256 termination,
        bool bentoBoxed,
        bool nft, 
        bool wrapBento,
        string memory details,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        /// @dev Validate basic elements of invoice.
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
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
        require(recoveredAddress == receiver, "invalid invoice");

        /// @dev Perform deposit.
        if (!bentoBoxed) {
            deposit(receiver, resolver, token, value, termination, nft, details);
        } else {
            depositBento(receiver, resolver, token, value, termination, wrapBento, details);
        }
        
        emit DepositWithInvoiceSig(msg.sender, receiver);
    }
    
    /// @notice Releases escrowed assets to designated `receiver` 
    /// - can only be called by `depositor` if not `locked`
    /// - can be called after `termination` as optional extension.
    /// @param registration The index of escrow deposit.
    function release(uint256 registration) external {
        Locker storage locker = lockers[registration]; 
        
        require(!locker.locked, "locked");
        require(msg.sender == locker.depositor, "not depositor");
        
        /// @dev Handle asset transfer.
        if (locker.token == address(0)) { /// @dev Release ETH.
            safeTransferETH(locker.receiver, locker.value);
        } else if (locker.bento) { /// @dev Release BentoBox shares.
            bento.transfer(locker.token, address(this), locker.receiver, locker.value);
        } else if (!locker.nft) { /// @dev Release ERC-20.
            safeTransfer(locker.token, locker.receiver, locker.value);
        } else { /// @dev Release NFT.
            safeTransferFrom(locker.token, address(this), locker.receiver, locker.value);
        }
        
        delete lockers[registration];
        
        emit Release(registration);
    }
    
    /// @notice Releases escrowed assets back to designated `depositor` 
    /// - can only be called by `depositor` if `termination` reached.
    /// @param registration The index of escrow deposit.
    function withdraw(uint256 registration) external {
        Locker storage locker = lockers[registration];
        
        require(msg.sender == locker.depositor, "not depositor");
        require(!locker.locked, "locked");
        require(block.timestamp >= locker.termination, "not terminated");
        
        /// @dev Handle asset transfer.
        if (locker.token == address(0)) { /// @dev Release ETH.
            safeTransferETH(locker.depositor, locker.value);
        } else if (locker.bento) { /// @dev Release BentoBox shares.
            bento.transfer(locker.token, address(this), locker.depositor, locker.value);
        } else if (!locker.nft) { /// @dev Release ERC-20.
            safeTransfer(locker.token, locker.depositor, locker.value);
        } else { /// @dev Release NFT.
            safeTransferFrom(locker.token, address(this), locker.depositor, locker.value);
        }
        
        delete lockers[registration];
        
        emit Withdraw(registration);
    }

    // **** DISPUTE PROTOCOL **** //
    // ------------------------- //
    /// @notice Locks escrowed assets for resolution - can only be called by locker parties.
    /// @param registration The index of escrow deposit.
    /// @param details Description of lock action (note: can link to secure dispute details, etc.).
    function lock(uint256 registration, string calldata details) external {
        Locker storage locker = lockers[registration];
        
        require(msg.sender == locker.depositor || msg.sender == locker.receiver, "not party");
        
        locker.locked = true;
        
        emit Lock(registration, details);
    }
    
    /// @notice Resolves locked escrow deposit in split between parties - if NFT, must be complete award (so, one party receives '0')
    /// - `resolverFee` is automatically deducted from both parties' awards.
    /// @param registration The registration index of escrow deposit.
    /// @param depositorAward The sum given to `depositor`.
    /// @param receiverAward The sum given to `receiver`.
    /// @param details Description of resolution (note: can link to secure judgment details, etc.).
    function resolve(uint256 registration, uint256 depositorAward, uint256 receiverAward, string calldata details) external {
        Locker storage locker = lockers[registration]; 
        
        require(msg.sender == locker.resolver, "not resolver");
        require(locker.locked, "not locked");
        require(depositorAward + receiverAward == locker.value, "not remainder");
        
        /// @dev Calculate resolution fee and apply to awards.
        uint256 resolverFee = locker.value / resolvers[locker.resolver].fee;
        depositorAward -= resolverFee / 2;
        receiverAward -= resolverFee / 2;
        
        /// @dev Handle asset transfers.
        if (locker.token == address(0)) { /// @dev Split ETH.
            safeTransferETH(locker.depositor, depositorAward);
            safeTransferETH(locker.receiver, receiverAward);
            safeTransferETH(locker.resolver, resolverFee);
        } else if (locker.bento) { /// @dev ...BentoBox shares.
            bento.transfer(locker.token, address(this), locker.depositor, depositorAward);
            bento.transfer(locker.token, address(this), locker.receiver, receiverAward);
            bento.transfer(locker.token, address(this), locker.resolver, resolverFee);
        } else if (!locker.nft) { /// @dev ...ERC20.
            safeTransfer(locker.token, locker.depositor, depositorAward);
            safeTransfer(locker.token, locker.receiver, receiverAward);
            safeTransfer(locker.token, locker.resolver, resolverFee);
        } else { /// @dev Award NFT.
            if (depositorAward != 0) {
                safeTransferFrom(locker.token, address(this), locker.depositor, locker.value);
            } else {
                safeTransferFrom(locker.token, address(this), locker.receiver, locker.value);
            }
        }
        
        delete lockers[registration];
        
        emit Resolve(registration, depositorAward, receiverAward, details);
    }
    
    /// @notice Registers an account to serve as a potential `resolver`.
    /// @param active Tracks willingness to serve - if 'true', can be joined to a locker.
    /// @param fee The divisor to determine resolution fee - e.g., if '20', fee is 5% of locker.
    function registerResolver(bool active, uint8 fee) external {
        resolvers[msg.sender] = Resolver(active, fee);
        emit RegisterResolver(msg.sender, active, fee);
    }

    // **** LEXDAO PROTOCOL **** //
    // ------------------------ //
    /// @notice Protocol for LexDAO to maintain agreements that can be stamped into lockers.
    /// @param index # to register agreement under.
    /// @param agreement Text or link to agreement, etc. - this allows for amendments.
    function registerAgreement(uint256 index, string calldata agreement) external {
        require(msg.sender == lexDAO, "not LexDAO");
        agreements[index] = agreement;
        emit RegisterAgreement(index, agreement);
    }

    /// @notice Protocol for LexDAO to update role.
    /// @param _lexDAO Account to assign role to.
    function updateLexDAO(address _lexDAO) external {
        require(msg.sender == lexDAO, "not LexDAO");
        lexDAO = _lexDAO;
        emit UpdateLexDAO(_lexDAO);
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
                    assembly { result := add(result, 0x04) }
                    revert(abi.decode(result, (string)));
                }
                results[i] = result;
            }
        }
    }

    /// @notice Provides EIP-2612 signed approval for this contract to spend user tokens.
    /// @param token Address of ERC-20 token.
    /// @param amount Token amount to grant spending right over.
    /// @param deadline Termination for signed approval (UTC timestamp in seconds).
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
        /// @dev permit(address,address,uint256,uint256,uint8,bytes32,bytes32).
        (bool success, ) = token.call(abi.encodeWithSelector(0xd505accf, msg.sender, address(this), amount, deadline, v, r, s));
        require(success, "permit failed");
    }

    /// @notice Provides DAI-derived signed approval for this contract to spend user tokens.
    /// @param token Address of ERC-20 token.
    /// @param nonce Token owner's nonce - increases at each call to {permit}.
    /// @param expiry Termination for signed approval - UTC timestamp in seconds.
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
        /// @dev permit(address,address,uint256,uint256,bool,uint8,bytes32,bytes32).
        (bool success, ) = token.call(abi.encodeWithSelector(0x8fcbaf0c, msg.sender, address(this), nonce, expiry, true, v, r, s));
        require(success, "permit failed");
    }

    /// @dev Provides way to sign approval for `bento` spends by locker.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function setBentoApproval(uint8 v, bytes32 r, bytes32 s) external {
        bento.setMasterContractApproval(msg.sender, address(this), true, v, r, s);
    }
    
    // **** TRANSFER HELPERS **** //
    // ------------------------- //
    /// @notice Provides 'safe' ERC-20 {transfer} for tokens that don't consistently return 'true/false'.
    /// @param token Address of ERC-20 token.
    /// @param recipient Account to send tokens to.
    /// @param value Token amount to send.
    function safeTransfer(address token, address recipient, uint256 value) private {
        /// @dev transfer(address,uint256).
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, recipient, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "transfer failed");
    }

    /// @notice Provides 'safe' ERC-20/721 {transferFrom} for tokens that don't consistently return 'true/false'.
    /// @param token Address of ERC-20/721 token.
    /// @param sender Account to send tokens from.
    /// @param recipient Account to send tokens to.
    /// @param value Token amount to send - if NFT, 'tokenId'.
    function safeTransferFrom(address token, address sender, address recipient, uint256 value) private {
        /// @dev transferFrom(address,address,uint256).
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, sender, recipient, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "pull failed");
    }
    
    /// @notice Provides 'safe' ETH transfer.
    /// @param recipient Account to send ETH to.
    /// @param value ETH amount to send.
    function safeTransferETH(address recipient, uint256 value) private {
        (bool success, ) = recipient.call{value: value}("");
        require(success, "eth transfer failed");
    }
}