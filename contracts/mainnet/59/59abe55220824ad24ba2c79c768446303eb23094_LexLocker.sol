/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

/// @notice Bilateral escrow for ETH and ERC-20/721 tokens.
/// @author LexDAO LLC.
contract LexLocker {
    uint256 lockerCount;
    mapping(uint256 => Locker) public lockers;
    mapping(address => Resolver) public resolvers;
    
    /// @dev Events to assist web3 applications.
    event Deposit(
        bool nft,
        address indexed depositor, 
        address indexed receiver, 
        address resolver,
        address token, 
        uint256 value, 
        uint256 indexed registration,
        string details);
    event Release(uint256 indexed registration);
    event Lock(uint256 indexed registration);
    event Resolve(uint256 indexed registration, uint256 indexed depositorAward, uint256 indexed receiverAward, string details);
    event RegisterResolver(address indexed resolver, bool indexed active, uint256 indexed fee);
    
    /// @dev Tracks registered escrow status.
    struct Locker {  
        bool nft; 
        bool locked;
        address depositor;
        address receiver;
        address resolver;
        address token;
        uint256 value;
    }
    
    /// @dev Tracks registered resolver status.
    struct Resolver {
        bool active;
        uint8 fee;
    }
    
     // **** ESCROW PROTOCOL ****  //
    // -------------------------- //
    /// @notice Deposits tokens (ERC-20/721) into escrow - locked funds can be released by `msg.sender` `depositor` - both parties can {lock} for `resolver`. 
    /// @param receiver The account that receives funds.
    /// @param resolver The account that unlock funds.
    /// @param token The asset used for funds.
    /// @param value The amount of funds - if `nft`, the 'tokenId'.
    /// @param nft If 'false', ERC-20 is assumed, otherwise, non-fungible asset.
    /// @param details Describes context of escrow - stamped into event.
    function deposit(
        address receiver, 
        address resolver, 
        address token, 
        uint256 value, 
        bool nft, 
        string calldata details
    ) external payable returns (uint256 registration) {
        require(resolvers[resolver].active, "resolver not active");
        
        /// @dev Handle ETH/ERC-20/721 deposit.
        if (msg.value != 0) {
            require(msg.value == value, "wrong msg.value");
            /// @dev Override to clarify ETH is used.
            if (token != address(0)) token = address(0);
        } else {
            safeTransferFrom(token, msg.sender, address(this), value);
        }
        
        /// @dev Increment registered lockers and assign # to escrow deposit.
        lockerCount++;
        registration = lockerCount;
        lockers[registration] = Locker(nft, false, msg.sender, receiver, resolver, token, value);
        
        emit Deposit(nft, msg.sender, receiver, resolver, token, value, registration, details);
    }
    
    /// @notice Releases escrowed assets to designated `receiver` - can only be called by `depositor` if not `locked`.
    /// @param registration The index of escrow deposit.
    function release(uint256 registration) external {
        Locker storage locker = lockers[registration]; 
        
        require(msg.sender == locker.depositor, "not depositor");
        require(!locker.locked, "locked");
        
        /// @dev Handle asset transfer.
        if (locker.token == address(0)) { /// @dev Release ETH.
            safeTransferETH(locker.receiver, locker.value);
        } else if (!locker.nft) { /// @dev Release ERC-20.
            safeTransfer(locker.token, locker.receiver, locker.value);
        } else { /// @dev Release NFT.
            safeTransferFrom(locker.token, address(this), locker.receiver, locker.value);
        }
        
        delete lockers[registration];
        
        emit Release(registration);
    }
    
     // **** DISPUTE PROTOCOL ****  //
    // --------------------------- //
    /// @notice Locks escrowed assets for resolution - can only be called by locker parties.
    /// @param registration The index of escrow deposit.
    function lock(uint256 registration) external {
        Locker storage locker = lockers[registration];
        
        require(msg.sender == locker.depositor || msg.sender == locker.receiver, "Not locker party");
        
        locker.locked = true;
        
        emit Lock(registration);
    }
    
    /// @notice Resolves locked escrow deposit in split between parties - if NFT, must be complete award (so, one party receives '0').
    /// @param registration The registration index of escrow deposit.
    /// @param depositorAward The sum given to `depositor`.
    /// @param receiverAward The sum given to `receiver`.
    function resolve(uint256 registration, uint256 depositorAward, uint256 receiverAward, string calldata details) external {
        Locker storage locker = lockers[registration]; 
        
        require(msg.sender == locker.resolver, "not resolver");
        require(locker.locked, "not locked");
        require(depositorAward + receiverAward == locker.value, "not remainder");
        
        /// @dev Calculate resolution fee and apply to awards.
        unchecked {
            uint256 resolverFee = locker.value / resolvers[locker.resolver].fee / 2;
            depositorAward -= resolverFee;
            receiverAward -= resolverFee;
        }
        
        /// @dev Handle asset transfer.
        if (locker.token == address(0)) { /// @dev Split ETH.
            safeTransferETH(locker.depositor, depositorAward);
            safeTransferETH(locker.receiver, receiverAward);
        } else if (!locker.nft) { /// @dev ...ERC20.
            safeTransfer(locker.token, locker.depositor, depositorAward);
            safeTransfer(locker.token, locker.receiver, receiverAward);
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
    
    function registerResolver(bool active, uint8 fee) external {
        resolvers[msg.sender] = Resolver(active, fee);
        emit RegisterResolver(msg.sender, active, fee);
    }
    
     // **** TRANSFER HELPERS **** //
    // -------------------------- //
    /// @notice Provides 'safe' ERC-20/721 {transfer} for tokens that don't consistently return 'true/false'.
    /// @param token Address of ERC-20/721 token.
    /// @param recipient Account to send tokens to.
    /// @param value Token amount to send - if NFT, 'tokenId'.
    function safeTransfer(address token, address recipient, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, recipient, value)); // @dev transfer(address,uint256).
        require(success && (data.length == 0 || abi.decode(data, (bool))), "transfer failed");
    }

    /// @notice Provides 'safe' ERC-20/721 {transferFrom} for tokens that don't consistently return 'true/false'.
    /// @param token Address of ERC-20/721 token.
    /// @param sender Account to send tokens from.
    /// @param recipient Account to send tokens to.
    /// @param value Token amount to send - if NFT, 'tokenId'.
    function safeTransferFrom(address token, address sender, address recipient, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, sender, recipient, value)); // @dev transferFrom(address,address,uint256).
        require(success && (data.length == 0 || abi.decode(data, (bool))), "pull transfer failed");
    }
    
    /// @notice Provides 'safe' ETH transfer.
    /// @param recipient Account to send ETH to.
    /// @param value ETH amount to send.
    function safeTransferETH(address recipient, uint256 value) private {
        (bool success, ) = recipient.call{value: value}("");
        require(success, "eth transfer failed");
    }
}