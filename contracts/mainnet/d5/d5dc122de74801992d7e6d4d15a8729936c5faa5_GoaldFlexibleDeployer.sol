/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}


interface IGoaldDAO721 {
    /** Updates the owner of a deployed Goald. */
    function setGoaldOwner(uint256 id) external;
}

/*
 * This is an implementation of the ERC721 standard for the Goald project that acts as a psuedo NFT (only has one token).
 *
 * See: @openzeppelin/contracts/token/ERC721/ERC721.sol
 */

contract Goald721 {
    //// ERC165 ////
    
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /// IERC721 ///

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    //// ERC721 ////

    /*
     *     bytes4(keccak256('balanceOf(address)'))                              == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)'))                                == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)'))                        == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)'))                            == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)'))                 == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)'))               == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)'))           == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)'))       == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^
     *        0x081812fc ^ 0xa22cb465 ^ 0xe985e9c5 ^
     *        0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    /** @dev The address that is allowed to `safeTransferFrom()` the token. */
    address _approvedTransferer;

    /** @dev The addresses that are always approved and also set third-party approvals. */
    mapping(address => bool) _approveForAllAddresses;
    
    /** @dev Token name. */
    string  private _name;

    /** @dev Token symbol. */
    string  private _symbol;
    
    /** @dev We only need to track ownership as a state rather than a balance since each Goald contract only issues a single token. */
    address internal _owner;

    /** @dev We are only tracking a single token, so we can manage its id as state. */
    uint256 internal _tokenId;

    /// Goald ///
    
    /** @dev The address of the Goald DAO which fees will be paid into. */
    address internal _daoAddress;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name, string memory symbol, uint256 tokenId) public {
        //// ERC165 ////
        
        // Derived contracts need only register support for their own interfaces, we register support for ERC165 itself here.
        _supportedInterfaces[INTERFACE_ID_ERC165] = true;

        // Register the supported interface to conform to ERC721 via ERC165.
        _supportedInterfaces[INTERFACE_ID_ERC721] = true;

        // Register the ERC721MEtatadata extension.
        // NOTE: `tokenURI(uint256)` is not implemented in this contract.
        _supportedInterfaces[INTERFACE_ID_ERC721_METADATA] = true;


        //// ERC721 ////

        _name    = name;
        _symbol  = symbol;
        _tokenId = tokenId;
    }

    //// ERC165 ////

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /// ERC721  - Views ///

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external view returns (uint256) {
        return owner == _owner ? 1 : 0;
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) external view returns (address) {
        require(tokenId == _tokenId, "Wrong token id");

        return _approvedTransferer;
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        require(owner == _owner, "Not owner");

        return _approveForAllAddresses[operator];
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        return tokenId == _tokenId ? _owner : address(0);
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    //// ERC721 - Non Views ////

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external {
        require(
               tokenId == _tokenId
            && (
                   msg.sender == _owner
                || _approveForAllAddresses[msg.sender]
               )
        , "Wrong token or not authorized");

        _approvedTransferer = to;

        emit Approval(_owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, ""), "ERC721: not ERC721Receiver");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: not ERC721Receiver");
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(msg.sender == _owner, "Not owner");

        _approveForAllAddresses[operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external {
        _transfer(from, to, tokenId);
    }

    //// ERC721 - Internal ////
    
    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
        // If the recipient isn't a contract we can move on. This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the constructor execution.
        uint256 size;
        assembly { size := extcodesize(to) }
        if (size == 0) {
            return true;
        }

        // Otherwise validate that they can receive the token.
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            msg.sender,
            from,
            tokenId,
            _data
        ));
        if (success) {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == ERC721_RECEIVED);
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: not ERC721Receiver");
            }
        }
    }
    
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(
            // Throw these in here as well to save gas.
               to != address(0)
            && tokenId == _tokenId

            && from == _owner
            && (msg.sender == _owner || msg.sender ==_approvedTransferer || _approveForAllAddresses[msg.sender])
        , "Not authorized");

        // Clear approvals from the previous owner.
        _approvedTransferer = address(0);

        // Update the owner.
        _owner = to;

        emit Transfer(from, to, tokenId);

        // GoaldDAO.setGoaldOwner transforms the id into an index using its `_idOffset`.
        IGoaldDAO721(_daoAddress).setGoaldOwner(tokenId - 1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;


interface IGoaldDAO {
    /** Returns the next Goald id so that we have a unique ID for each NFT, regardless of which deployer was used. */
    function getNextGoaldId() external view returns (uint256);

    /** Returns the current address that fees will be sent to. */
    function getProxyAddress() external view returns (address);

    /** Return the metadata for a specific Goald. */
    function getTokenURI(uint256 tokenId) external view returns (string memory);

    /** Returns the address of the uniswap router. */
    function getUniswapRouterAddress() external view returns (address);

    /** Returns true if this deployer is allowed to deploy a goald. */
    function isAllowedDeployer(address deployer) external view returns (bool);

    /** Lets the DAO know that a Goald was created. */
    function notifyGoaldCreated(address creator, address goaldAddress) external;

    /** Updates the owner of a deployed Goald. */
    function setGoaldOwner(uint256 id) external;
}

contract GoaldFlexibleDeployer {
    address constant DAO_ADDRESS = 0x544664F896eD703Afa025c8465903249D8f1C65A;

    event GoaldDeployed(address goaldAddress);

    /**
     * See the constructor of the Goald contract for details on the parameters. There is no concern for reentrancy since this is the
     * only function, and multiple calls will probably hit the block gas limit very quickly.
     */
    function deploy(
        address collateralToken,
        address paymentToken,
        uint96  fee,
        uint8   feeIntervalDays,
        uint16  totalIntervals,
        string memory name
    ) external returns (address) {
        // Make sure that we are allowed to create new Goald.
        IGoaldDAO latestDAO = IGoaldDAO(IGoaldDAO(DAO_ADDRESS).getProxyAddress());
        require(latestDAO.getProxyAddress() == address(latestDAO), "DAO address mismatch");
        require(latestDAO.isAllowedDeployer(address(this)), "Not allowed deployer");

        // Create the goald.
        GoaldFlexible goald = new GoaldFlexible(
            address(latestDAO),
            msg.sender,
            name,
            latestDAO.getNextGoaldId(),
            collateralToken,
            paymentToken,
            latestDAO.getUniswapRouterAddress(),
            fee,
            feeIntervalDays,
            totalIntervals
        );
        address goaldAddress = address(goald);

        // Tell the proxy we created a goald.
        latestDAO.notifyGoaldCreated(msg.sender, goaldAddress);

        // Hello world!
        emit GoaldDeployed(goaldAddress);

        return goaldAddress;
    }
}

contract GoaldFlexible is Goald721 {
    // The masks and shift distances for each value from the packed state variable. This works for both arithmatic and logical shifts,
    // though currrently shifts are logical. This is for big endian values.
    // READ:
    //      1) AND the MASK with the packed values to expose the slot
    //      2) RIGHT SHIFT to get the raw value
    //
    //      value = (_staticValues & MASK) >> SHIFT
    //      
    // WRITE:
    //      1) LEFT SHIFT to position with the slot
    //      2) AND the MASK with the shifted value, to get rid of dirty bits
    //      3) AND the NEGATIVE MASK with the packed values to wipe the slot
    //      4) OR the shifted value to update
    //
    //      _staticValues = ((value << SHIFT) & MASK) | (_staticValues & ~MASK)
    uint256 private constant FEE_MASK                     = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 private constant FEE_SHIFT                    = 0;

    uint256 private constant FEE_INTERVAL_DAYS_MASK       = 0x1FF000000000000000000000000000000000000000000;
    uint256 private constant FEE_INTERVAL_DAYS_SHIFT      = 168;

    uint256 private constant TOTAL_INTERVALS_MASK         = 0x1FFFFE00000000000000000000000000000000000000000000;
    uint256 private constant TOTAL_INTERVALS_SHIFT        = 177;

    uint256 private constant FINALIZATION_TIMESTAMP_MASK  = 0x1FFFFFFFFFFFE0000000000000000000000000000000000000000000000000;
    uint256 private constant FINALIZATION_TIMESTAMP_SHIFT = 197;

    uint256 private constant FINALIZED_MASK               = 0x20000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant FINALIZED_SHIFT              = 245;

    // The divisor used to calculate the fee paid to the Goald DAO. This is currently 0.25%.
    uint256 private constant FEE_DIVISOR = 400;


    /** @dev The collateral token stored (e.g., WBTC). */
    address private _collateralAddress;

    /** @dev The payment token taken (e.g., WETH). */
    address private _paymentAddress;

    /** @dev The address of the Uniswap router which will facilitate the swap between the payment token and the collateral token. */
    address private _uniswapRouterAddress;

    /**
     * @dev The owner of the Goald can optionally appoint a steward. The steward's only authority is to update the uniswap router
     * address or replace themself. This is intended if the Goald needs separation between ownership and management (e.g., via DAOs).
     */
    address private _steward;

    /**
     * @dev Packed static values (all uints). The only one that will change is `finalized`, and only once.
     *
     *  bits    offset    variable name            description
     *  ----    ------    -------------            -----------
     *   168         0    fee                      The fee per interval of the goald.
     *     9       168    feeIntervalDays          How many days between each fee payment; minimum 1.
     *    20       177    totalIntervals           The total number of intervals this goald will have when it is finalized.
     *    48       197    finalizationTimestamp    When the Goald can be finalized if it isn't paid in full.
     *     1       245    finalized                If the Goald can be withdrawn from.
     */
    uint256 private _staticValues;

    /** @dev The total amount of the payment token that must be paid over the life of the Goald to finalize it. */
    uint256 private _requiredTotalFeePaid;

    /** @dev The total amount of the payment token that has been paid over the life of the Goald. */
    uint256 private _totalFeePaid;

    // We include this here instead of the `nonReentrant` modifier to reduce gas costs. We also might change the reentrancy state
    // multiple times within a single function depending on needs.
    // See OpenZeppelin - ReentrancyGuard for more.
    // Reentrancy reversions are the only calls to revert (in this contract) that do not have reasons.
    uint256 private constant RE_NOT_ENTERED = 1;
    uint256 private constant RE_ENTERED     = 2;
    uint256 private _status;

    /// Events ///

    /** @dev Emitted whenever a fee is paid. */
    event FeePaid(address paymentToken, uint256 feePaid, uint256 feeTokensSpent, uint256 collateralTokensReceived);

    /** @dev Emitted when the collateral pool has been withdrawn from. */
    event Withdrawal(uint256 amount);

    /** @dev Emitted when the Uniswap router address has changed. */
    event RouterAddressChanged(address newAddress);

    /** @dev Emitted when the steward address has changed. */
    event StewardChanged(address newSteward);

    /// Modifiers ///

    /** @dev Applied to functions that must be guarded against reentrancy which only the owner or steward can call. */
    modifier nonReentrant_OnlyOwnerSteward {
        require(_status == RE_NOT_ENTERED && (msg.sender == _owner || msg.sender == _steward));
        _status = RE_ENTERED;

        _;

        // Store the original amount to get a refund.
        _status = RE_NOT_ENTERED;
    }

    /**
     * @dev Applied to functions that must be guarded against reentrancy which only the owner or steward can call. This modifier
     * doesn't update the current value of `_status`, so it cannot make any non-internal function calls.
     */
    modifier nonReentrant_OnlyOwnerSteward_InternalCallsOnly {
        require(_status == RE_NOT_ENTERED && (msg.sender == _owner || msg.sender == _steward));

        _;
    }

    /** @dev Applied to functions that must be guarded against reentrancy, but are otherwise publicly accessible. */
    modifier nonReentrant_Public {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        _status = RE_ENTERED;

        _;

        // Store the original amount to get a refund.
        _status = RE_NOT_ENTERED;
    }

    /// Constructor ///

    /**
     * @param daoAddress The address of the Goald DAO.
     * @param owner Who owns the goald and is required to pay the fees to maintain it (though anyone can pay the fees).
     * @param name The name of this goald.
     * @param goaldId The unique id of this Goald.
     * @param collateralToken Which token will be used as collateral in the collateral pool (e.g., WBTC).
     * @param paymentToken Which token will be used to pay for the collateral token (e.g., WETH).
     * @param uniswapRouterAddress The address of the liquidity swap router.
     * @param fee The periodic fee required to be paid to maintain the goald; minimum 1. Anyone can pay the fee.
     * @param feeIntervalDays How many days between each fee payment; minimum 1.
     * @param totalIntervals How many fee intervals must pass before the goald finalizes; minimum 1.
     */
    constructor(
        address daoAddress,
        address owner,
        string memory name,
        uint256 goaldId,
        address collateralToken,
        address paymentToken,
        address uniswapRouterAddress,
        uint256 fee,
        uint256 feeIntervalDays,
        uint256 totalIntervals
    ) Goald721(name, "GOALD", goaldId) public {
        // Do validation. We don't do any validation on the addresses being contracts, only that they are unique among themselves
        // and are not obviously invalid. It is up to the user to use addresses that are ERC20 compliant.
        require(
            // Validate the addresses.
               daoAddress      != address(0)
            && daoAddress      != address(this)
            && owner           != address(0)
            && owner           != address(this)
            && owner           != collateralToken
            && owner           != paymentToken
            && collateralToken != address(0)
            && collateralToken != address(this)
            && collateralToken != paymentToken
            && paymentToken    != address(0)
            && paymentToken    != address(this)

            // Validate the numbers.
            && fee             > 0 && fee             <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF // uint168
            && feeIntervalDays > 0 && feeIntervalDays <= 0x1FF                                        // uint9
            && totalIntervals  > 0 && totalIntervals  <= 0xFFFFF                                      // uint20
        , "Invalid parameters");

        // Clean any dirty bits from the number values.
        fee             = fee             & (FEE_MASK               >> FEE_SHIFT);
        feeIntervalDays = feeIntervalDays & (FEE_INTERVAL_DAYS_MASK >> FEE_INTERVAL_DAYS_SHIFT);
        totalIntervals  = totalIntervals  & (TOTAL_INTERVALS_MASK   >> TOTAL_INTERVALS_SHIFT);
        uint256 finalizationTimestamp = block.timestamp + (totalIntervals * feeIntervalDays * 1 days);

        // Set the addresses.
        _daoAddress           = daoAddress;
        _collateralAddress    = collateralToken;
        _paymentAddress       = paymentToken;
        _owner                = owner;
        _uniswapRouterAddress = uniswapRouterAddress;

        // Store the values.
        _requiredTotalFeePaid = fee * totalIntervals;
        _staticValues = 0
            | (fee                   << FEE_SHIFT)
            | (feeIntervalDays       << FEE_INTERVAL_DAYS_SHIFT)
            | (totalIntervals        << TOTAL_INTERVALS_SHIFT)
            | (finalizationTimestamp << FINALIZATION_TIMESTAMP_SHIFT);

        // Set us up for reentrancy guarding.
        _status = RE_NOT_ENTERED;
    }

    /// Views ///

    /**
     * Single view over all internal state variables.
     *
     * Returns:
     *     Proxy contract address
     *     Collateral token address
     *     Payment token address (or 0 for ETH)
     *     Uniswap router address
     *     Next fee timestamp
     *     Packed state values
     */
    function getDetails() external view returns (uint256[10] memory details) {
        address collateralAddress = _collateralAddress;

        // Important Addresses.
        details[0] = uint256(_daoAddress);
        details[1] = uint256(collateralAddress);
        details[2] = uint256(_paymentAddress);
        details[3] = uint256(_uniswapRouterAddress);
        details[4] = uint256(_steward);
        details[5] = uint256(_owner);

        // The id of this Goald.
        details[6] = _tokenId;

        // The total amount paid into the Goald so far.
        details[7] = _totalFeePaid;

        // Current balance.
        details[8] = IERC20(collateralAddress).balanceOf(address(this));

        // Packed values.
        details[9] = _staticValues;
    }

    /// External Functions ///

    /**
     * Pay out the stored collateral. This can only be called by and paid out to the owner, not a third party, even the steward. This
     * This can only be called once the finalization date has been reached, but can be called multiple times after that if desired.
     */
    function withdrawFromGoald(uint256 amount) external {
        // So we can extract the packed values without unnecessary SLOADs.
        uint256 values = _staticValues;
        uint256 finalized             = (values & FINALIZED_MASK)              >> FINALIZED_SHIFT;
        uint256 finalizationTimestamp = (values & FINALIZATION_TIMESTAMP_MASK) >> FINALIZATION_TIMESTAMP_SHIFT;

        // Rather than using a `nonReentrant_OnlyOwner` modifier, we include the reentrancy guard manually. This save gas since we're
        // caching `_owner` into `owner`.
        address owner = _owner;
        require(
               _status == RE_NOT_ENTERED
            && msg.sender == owner
            && (
                // This is only set during a call to `payFee` if the Goald has been fully paid out.
                   finalized > 0
                || block.timestamp >= finalizationTimestamp
            )
        , "Not authorized");
        _status = RE_ENTERED;

        // Make sure we have something to withdraw.
        IERC20 collateralToken = IERC20(_collateralAddress);
        uint256 currentGoaldBalance = collateralToken.balanceOf(address(this));
        uint256 currentOwnerBalance = collateralToken.balanceOf(owner);
        require(
               amount > 0
            && amount <= currentGoaldBalance
            && currentOwnerBalance + amount > currentOwnerBalance
        , "Invalid amount");

        // Transfer the collateral.
        require(collateralToken.transfer(owner, amount));

        // Validate the transfer.
        require(
               collateralToken.balanceOf(address(this)) == currentGoaldBalance - amount
            && collateralToken.balanceOf(owner)         == currentOwnerBalance + amount
        , "Post transfer balance wrong");

        // Hello world!
        emit Withdrawal(amount);

        // Store the original amount to get a refund.
        _status = RE_NOT_ENTERED;
    }
 

    /** Pay the goald fee. Overpayments change the finalization date. */
    function payFee(uint256 amount, address[] calldata swapPath, uint256 deadline) external nonReentrant_Public {
        // Make sure we have a valid swap path.
        require(swapPath.length > 1 && swapPath[swapPath.length - 1] == _collateralAddress, "Invalid swap path");

        // Clean up any dirty bits in the amount. We don't validate that this is more than zero. At best, the swap function will
        // revert (either on input being zero, or minimum output not being more than one). At worst, The user called this function
        // with invalid parameters.
        amount = amount & (FEE_MASK >> FEE_SHIFT);

        // Make sure we have the most up to date DAO address. If this call reverts, then no fees can be paid.
        address daoAddress = IGoaldDAO(_daoAddress).getProxyAddress();
        if (address(daoAddress) != daoAddress) {
            _daoAddress = daoAddress;
        }

        uint256[] memory amounts;
        uint256 receivedAmount;
        { // Scoped to prevent stack too deep error.
            // Transfer from the user.
            IERC20 paymentContract = IERC20(swapPath[0]);
            uint256 fee = amount / FEE_DIVISOR;
            amount -= fee;
            require(paymentContract.transferFrom(msg.sender, address(this), amount)); 
            if (fee > 0) {
                require(paymentContract.transferFrom(msg.sender, daoAddress, fee));
            }

            // We'll be verifying uniswap did what it said it did.
            IERC20 collateralContract = IERC20(_collateralAddress);
            uint256 currentCollateralBalance = collateralContract.balanceOf(address(this));

            // Set the router's allowance to cover the trade. We are only authorizing enough for the collateral amount.
            address uniswapRouterAddress = _uniswapRouterAddress;
            require(paymentContract.approve(uniswapRouterAddress, amount));
            
            // Try and transfer from the user to the goald. We use Uniswap to get the collateral token. We don't care how much of the
            // collateral was returned, so long as it is greater than zero.
            amounts = IUniswapV2Router02(uniswapRouterAddress).swapExactTokensForTokens(amount, 1, swapPath, address(this), deadline);

            // Double check the balance. Amounts is the same length as `_uniPath`: 3.
            receivedAmount = amounts[swapPath.length - 1];
            require(currentCollateralBalance + receivedAmount > currentCollateralBalance, "UNI: Overflow error");
            require(collateralContract.balanceOf(address(this)) == currentCollateralBalance + receivedAmount, "UNI: Wrong balance");

            // Reset the router's allowance to zero to prevent unauthorized spending / double spending. The refund would be larger if
            // it was kept non-zero, but though one token can be considered miniscule (e.g., for WETH, which has 18 decimal places),
            // we still must be diligent.
            require(paymentContract.approve(uniswapRouterAddress, 0));
        }

        // The Goald hasn't been finalized yet, so update the total amount paid. We don't keep track of how many payments have
        // been made afer the it has been finalized.
        if ((_staticValues & FINALIZED_MASK) >> FINALIZED_SHIFT == 0) {
            // Calculate the new total.
            uint256 totalFeePaid = _totalFeePaid;
            uint256 newTotalFeePaid = totalFeePaid + amount;

            // We'll consider an overflow on the amount paid to be the same as fully paying out the Goald.
            if (newTotalFeePaid < totalFeePaid) {
                _staticValues |= FINALIZED_MASK;
            } else if (newTotalFeePaid >= _requiredTotalFeePaid) {
                _staticValues |= FINALIZED_MASK;
            } else {
                _totalFeePaid = newTotalFeePaid;
            }
        }

        // Hello world!
        emit FeePaid(swapPath[0], amount, amounts[0], receivedAmount);
    }

    /** Failsafe so the owner can withdraw any tokens other than the collateral token that may end up within this Goald. */
    function transferERC20(address tokenAddress, uint256 amount) external nonReentrant_OnlyOwnerSteward {
        require(tokenAddress != _collateralAddress, "Invalid address");
        require(IERC20(tokenAddress).transfer(_owner, amount));
    }

    /**
     * Changes the uniswap router contract address for the swaps. This can be changed to anything that has the same API:
     * 
     * `swapExactTokensForTokens(
     *      uint256   amount,
     *      uint256   minAmount,
     *      address[] path,
     *      address   destination,
     *      uint256   deadline
     *  ) external returns (uint256[] amounts);`
     *
     * Only the owner or steward of the Goald can update the router.
     */
    function updateRouterAddress(address newAddress) external nonReentrant_OnlyOwnerSteward_InternalCallsOnly {
        // We're not doing address validation because this function is restricted to only two callers: the owner or steward. However,
        // the things we would validate against would be:
        //
        // 1) Not being the zero address. Since that address doesn't support the swap function it would revert on any payments.
        // 2) The goald address (or the deployer address). Again, neither support the swap function.
        // 3) The DAO address / a token address. Again, neither support the swap function (although a unified proxy DAO is possible).
        // 4) The steward / owner. It's possible this condition is legitimate.

        // Update the router address.
        _uniswapRouterAddress = newAddress;

        emit RouterAddressChanged(newAddress);
    }

    /** Changes the steward. This can be set to the zero address to disable steward functionality.*/
    function updateSteward(address newSteward) external nonReentrant_OnlyOwnerSteward_InternalCallsOnly {
        // We don't do any validation on the new steward. Either the new address can be aware of its stewardship abilities or it
        // cannot. In the second case, it doesn't matter what it is. In the first case, it would pass all theoretical validation.

        // Update the steward.
        _steward = newSteward;

        emit StewardChanged(newSteward);
    }

    /// "Overridden" Functions ///

    /** See {IERC721Metadata-tokenURI}. Pull metadata from the DAO. */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(tokenId == _tokenId, "Wrong token");

        return IGoaldDAO(_daoAddress).getTokenURI(tokenId);
    }
}