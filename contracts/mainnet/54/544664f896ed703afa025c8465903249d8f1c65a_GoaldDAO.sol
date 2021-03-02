/**
 *Submitted for verification at Etherscan.io on 2021-03-02
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;


interface IGoaldToken is IERC20 {
    /** Gets the base url for Goald metadata. */
    function getBaseTokenURI() external view returns (string memory);

    /** Gets the total number of deployed Goalds. */
    function getGoaldCount() external view returns (uint256);

    /** Returns the current stage of the DAO's governance. */
    function getGovernanceStage() external view returns (uint256);

    /** Gets the current DAO address. */
    function getLatestDAO() external view returns (address);

    /** Called by the latest DAO when a new Goald has been deployed. */
    function goaldDeployed(address recipient, address goaldAddress) external returns (uint256);
}

/** Tracks all DAO functionality for the Goald token. Each version of the DAO manages its own balances and rewards. */
contract GoaldDAO {
    /** @dev The number of decimals is small to allow for rewards of tokens with substantially different exchange rates. */
    uint8 private constant DECIMALS = 2;

    /** 
     * @dev The minimum amount of tokens necessary to be eligible for a reward. This is "one token", considering decimal places. We
     * are choosing two decimal places because we are initially targeting WBTC, which has 8. This way we can do a minimum reward ratio
     * of 1 / 1,000,000 of a WBTC, relative to our token. So at $25,000 (2020 value), the minimum reward would be $250 (assuming we
     * have issued all 10,000 tokens).
     */
    uint256 private constant REWARD_THRESHOLD = 10**uint256(DECIMALS);

    /** @dev The current owner of the proxy. This will become the Goald token (as delgated DAO manager) when the DAO is initiated. */
    address public  _owner;

    /** @dev Which Uniswap router we're currently using for trades. */
    address private _uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /** @dev The address of the Goald token. Set in constructer and should never have to be changed. */
    address public  _goaldToken = 0x5Cd9207c3A81FB7A73c9D71CDd413B85b4a7D045;

    /** @dev The address of the token that will be used as a liquidity intermediary within Uniswap for indirect swaps (e.g., WETH). */
    address private _intermediaryToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;


    /** @dev Which deployers are allowed to create new Goalds. We use a mapping for O(1) lookups and an array for complete list. */
    mapping (address => bool) private _allowedDeployersMap;
    address[] private _allowedDeployersList;

    /** @dev The addresses of all deployed goalds. */
    address[] private _deployedGoalds;

    /** @dev The owner of each deployed goald. */
    address[] private _goaldOwners;

    /** @dev The id offset to account for Goalds deployed in previous versions of the DAO. */
    uint256   private _idOffset;


    /** @dev Which ERC20 contract will be used for rewards (e.g., WBTC). */
    address   private _rewardToken = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    /** @dev How many holders are eligible for rewards. This is used to determine how much should be reserved. */
    uint256   private _rewardHolders;

    /** @dev How much of the current balance is reserved for rewards. */
    uint256   private _reservedRewardBalance;

    /** @dev How many holders have yet to withdraw a given reward. */
    uint256[] private _rewardHolderCounts;

    /** @dev The multipliers for each reward. */
    uint256[] private _rewardMultipliers;

    /** @dev The remaining reserves for a given reward. */
    uint256[] private _rewardReserves;

    /** @dev The minimum reward index to check eligibility against for a given address. */
    mapping (address => uint256) private _minimumRewardIndex;
    
    /** @dev The available reward balance for a given address. */
    mapping (address => uint256) private _rewardBalance;

    /**
     * @dev The stage of the governance token. Tokens can be issued based on deployments regardless of what stage we are in. Identical
     * to `GoaldToken.governanceStage`. Cannot be set directly.
     *
     * Statuses:
     *      0: Created, with no governance protocol initiated. The initial governance issuance can be claimed.
     *      1: Initial governance issuance has been claimed.
     *      2: The governance protocal has been initiated.
     *      3: All governance tokens have been issued.
     */
    uint256 private constant STAGE_INITIAL               = 0;
    uint256 private constant STAGE_ISSUANCE_CLAIMED      = 1;
    uint256 private constant STAGE_DAO_INITIATED         = 2;
    uint256 private constant STAGE_ALL_GOVERNANCE_ISSUED = 3;
    uint256 private _governanceStage;

    // Reentrancy reversions are the only calls to revert (in this contract) that do not have reasons. We add a third state, 'frozen'
    // to allow for locking non-admin functions. The contract may be permanently frozen if it has been upgraded.
    uint256 private constant RE_NOT_ENTERED = 1;
    uint256 private constant RE_ENTERED     = 2;
    uint256 private constant RE_FROZEN      = 3;
    uint256 private _status;

    // Set when the DAO is ready to deploy things.
    uint256 private constant NOT_READY = 0;
    uint256 private constant READY = 1;
    uint256 private _ready;

    constructor(/* address goaldToken, address rewardToken, address intermediaryToken */) public {
        // Hard-coded for deployment.
        // _goaldToken = goaldToken;
        // _rewardToken = rewardToken;
        // _intermediaryToken = intermediaryToken;

        // Copy over current state values.
        IGoaldToken token = IGoaldToken(/* goaldToken */ 0x5Cd9207c3A81FB7A73c9D71CDd413B85b4a7D045);
        _governanceStage = token.getGovernanceStage();

        // The owner of this contract depends on whether or not the DAO has been initialized.
        if (_governanceStage < STAGE_DAO_INITIATED) {
            _owner = msg.sender;
        } else {
            _owner = _goaldToken;
        }

        _status = RE_NOT_ENTERED;
    }

    /// Events ///

    event RewardCreated(uint256 multiplier, string reason);

    /// Admin Functions ///

    /** Adds more allowed deployers. */
    function addAllowedDeployers(address[] calldata newDeployers) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner, "Not owner");

        uint256 count = newDeployers.length;
        uint256 index;
        address newDeployer;
        for (; index < count; index++) {
            newDeployer = newDeployers[index];

            // Don't revert if it already exists.
            if (!_allowedDeployersMap[newDeployer]) {
                // Add the deployer.
                _allowedDeployersMap[newDeployer] = true;
                _allowedDeployersList.push(newDeployer);
            }
        }
    }

    /** Freezes the proxy contract. Only admin functions can be called. */
    function freeze() external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        require(msg.sender == _owner, "Not owner");

        _status = RE_FROZEN;
    }

    /** Called if the DAO manager is no longer a holder after burning the initialization tokens. */
    function initializeDecreasesHolders() external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        require(msg.sender == _goaldToken, "Not GOALD token");
        require(_governanceStage == STAGE_ISSUANCE_CLAIMED, "Wrong governance stage");

        _rewardHolders --;
    }

    /** Called if the DAO manager is now a holder after claiming the initialization tokens. */
    function issuanceIncreasesHolders() external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        require(msg.sender == _goaldToken, "Not GOALD token");
        require(_governanceStage == STAGE_INITIAL, "Wrong governance stage");

        _rewardHolders ++;
    }

    /** Makes this DAO ready for deployments (regardless of whether or not there are authorized ones). */
    function makeReady(uint256 governanceStage, uint256 idOffset) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _goaldToken, "Not Goald token");
        require(_ready == NOT_READY,       "Already ready");

        _governanceStage = governanceStage;
        _idOffset = idOffset;
        _ready = READY;
        
        // The owner of this contract depends on whether or not the DAO has been initialized.
        if (governanceStage >= STAGE_DAO_INITIATED) {
            _owner = _goaldToken;
        }
    }

    /** Removes an allowed deployer by index. We require the index for no-traversal removal against a known address. */
    function removeAllowedDeployer(address deployerAddress, uint256 index) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner,                 "Not owner");
        require(index < _allowedDeployersList.length, "Out of bounds");

        // Check the address.
        address indexAddress = _allowedDeployersList[index];
        require(indexAddress == deployerAddress,       "Address mismatch");
        require(_allowedDeployersMap[deployerAddress], "Already restricted");

        // Remove the deployer.
        _allowedDeployersMap[deployerAddress] = false;
        _allowedDeployersList[index] = _allowedDeployersList[index - 1];
        _allowedDeployersList.pop();
    }

    /** Updates the goald token. Should never have to be called. */
    function setGoaldToken(address newAddress) external {
        // Reentrancy guard.
        require(_status == RE_FROZEN);
        require(msg.sender == _owner,        "Not owner");
        require(newAddress != address(0),    "Can't be zero address");
        require(newAddress != address(this), "Can't be this address");

        // The DAO has been initialized, so carry over the new address.
        if (_owner == _goaldToken) {
            _owner = newAddress;
        }

        _goaldToken = newAddress;
    }

    /** Sets the token that is used as an intermediary in Uniswap swaps for token pairs that have insufficient liquidity. */
    function setIntermediaryTokenAddress(address newAddress) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner,     "Not owner");
        require(newAddress != address(0), "Can't be zero address");

        _intermediaryToken = newAddress;
    }

    /** Update the owner, so long as the DAO hasn't been initialized. */
    function setOwner(address newOwner) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner,   "Not owner");
        require(newOwner != address(0), "Can't be zero address");
        require(_owner != _goaldToken, "Already initialized");

        _owner = newOwner;
    }

    /** The uniswap router for converting tokens within this proxys. */
    function setUniswapRouterAddress(address newAddress) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner,     "Not owner");
        require(newAddress != address(0), "Can't be zero address");

        _uniswapRouterAddress = newAddress;
    }

    /** Unfreezes the proxy contract. Non-admin functions can again be called. */
    function unfreeze() external {
        // Reentrancy guard.
        require(_status == RE_FROZEN);
        require(msg.sender == _owner, "Not owner");

        _status = RE_NOT_ENTERED;
    }

    /// Goald Deployers ///

    /** Returns the address of the deployer at the specified index. */
    function getDeployerAt(uint256 index) external view returns (address) {
        return _allowedDeployersList[index];
    }

    /** Returns the number of allowed deployers. */
    function getDeployerCount() external view returns (uint256) {
        return _allowedDeployersList.length;
    }

    /** Returns the address and owner of the Goald at the specified index. */
    function getGoaldAt(uint256 index) external view returns (address[2] memory) {
        return [_deployedGoalds[index], _goaldOwners[index]];
    }

    /** Returns the number of goalds deployed from this DAO. */
    function getGoaldCount() external view returns (uint256) {
        return _deployedGoalds.length;
    }

    /** Returns the ID offset of the Goalds tracked by this DAO. */
    function getIDOffset() external view returns (uint256) {
        return _idOffset;
    }

    /** Gets the token that is used as an intermediary in Uniswap swaps for token pairs that have insufficient liquidity. */
    function getIntermediaryToken() external view returns (address) {
        return _intermediaryToken;
    }

    /** Returns the next Goald id so that we have a unique ID for each NFT, regardless of which deployer was used. */
    function getNextGoaldId() external view returns (uint256) {
        return IGoaldToken(_goaldToken).getGoaldCount() + 1;
    }

    /** Returns the current address that fees will be sent to. */
    function getProxyAddress() external view returns (address) {
        return IGoaldToken(_goaldToken).getLatestDAO();
    }

    /** Return the metadata for a specific Goald. */
    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        uint256 temp = tokenId;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = tokenId;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }

        return string(abi.encodePacked(IGoaldToken(_goaldToken).getBaseTokenURI(), string(buffer)));
    }

    /** Returns the address of the uniswap router. */
    function getUniswapRouterAddress() external view returns (address) {
        return _uniswapRouterAddress;
    }

    /** Returns if the address is an allowed deployer. */
    function isAllowedDeployer(address deployer) external view returns (bool) {
        return _allowedDeployersMap[deployer];
    }

    /**
     * Called when a deployer deploys a new Goald. Currently we use this to distribute the governance token according to the following
     * schedule. An additional 12,000 tokens will be claimable by the deployer of this proxy. This will create a total supply of
     * 21,000 tokens. Once the governance protocal is set up, 11,000 tokens will be burned to initiate that mechanism. That will leave
     * 10% ownership for the deployer of the contract, with the remaining 90% disbused on Goald creations. No rewards can be paid out
     * before the governance protocal has been initiated.
     *
     *      # Goalds    # Tokens
     *       0 -  9       100
     *      10 - 19        90
     *      20 - 29        80
     *      30 - 39        70
     *      40 - 49        60
     *      50 - 59        50
     *      60 - 69        40
     *      70 - 79        30
     *      80 - 89        20
     *      90 - 99        10
     *       < 3600         1
     */
    function notifyGoaldCreated(address creator, address goaldAddress) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        _status = RE_ENTERED;

        require(_allowedDeployersMap[msg.sender], "Not allowed deployer");

        IGoaldToken goaldToken = IGoaldToken(_goaldToken);
        require(goaldToken.getLatestDAO() == address(this), "Not latest DAO");

        // Must be ready for deployment.
        require(_ready == READY, "Not ready");

        // All governance tokens have been issued.
        if (_governanceStage == STAGE_ALL_GOVERNANCE_ISSUED) {
            goaldToken.goaldDeployed(creator, goaldAddress);

            // Track the goald and its owner.
            _deployedGoalds.push(goaldAddress);
            _goaldOwners.push(creator);

            return;
        }

        // We might be creating a new holder.
        bool increaseHolders;
        if (goaldToken.balanceOf(creator) < REWARD_THRESHOLD) {
            increaseHolders = true;
        }

        // Get the amount of tokens minted.
        uint256 amount = goaldToken.goaldDeployed(creator, goaldAddress);

        // It's possible we have issued all governance tokens without the DAO initiated.
        if (amount > 0) {
            // Update their reward balance.
            _checkRewardBalance(creator);

            if (increaseHolders) {
                _rewardHolders ++;
            }
        }

        // We have issued all tokens, so move to the last stage of governance. This will short circuit this function on future calls.
        // This will result in unnecessary gas if the DAO is never initiated and all 3600 token-earning goalds are created. But the
        // DAO should be initiated long before that.
        else if (_governanceStage == STAGE_DAO_INITIATED) {
            _governanceStage = STAGE_ALL_GOVERNANCE_ISSUED;
        }

        // Track the goald and its owner.
        _deployedGoalds.push(goaldAddress);
        _goaldOwners.push(creator);

        // By storing the original amount once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = RE_NOT_ENTERED;
    }

    /** Updates the owner of a deployed Goald. */
    function setGoaldOwner(uint256 id) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        _status = RE_ENTERED;

        // Get the index of the Goald.
        uint256 index = id - _idOffset;
        require(index < _deployedGoalds.length, "Invalid id");

        // We don't have the address as a parameter to make sure we have the correct value stored here.
        address owner = IERC721(_deployedGoalds[index]).ownerOf(id);
        _goaldOwners[index] = owner;

        // By storing the original amount once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = RE_NOT_ENTERED;
    }

    /// Governance ///

    /** Uses Uniswap to convert all held amount of a specific token into the reward token, using the provided path. */
    function convertToken(address[] calldata path, uint256 deadline) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        _status = RE_ENTERED;
        require(msg.sender == _owner, "Not owner");
            
        // Make sure this contract actually has a balance.
        IERC20 tokenContract = IERC20(path[0]);
        uint256 amount = tokenContract.balanceOf(address(this));
        require(amount > 0, "No balance for token");

        // Make sure the reward token is the last address in the path. Since the array is calldata we don't want to spend the gas to
        // push this onto the end.
        require(path[path.length - 1] == _rewardToken, "Last must be reward token");

        // Swap the tokens.
        tokenContract.approve(_uniswapRouterAddress, amount);
        IUniswapV2Router02(_uniswapRouterAddress).swapExactTokensForTokens(amount, 1, path, address(this), deadline);

        // By storing the original amount once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = RE_NOT_ENTERED;
    }

    /**
     * Uses Uniswap to convert all held amount of specific tokens into the reward token. The tokens must have a direct path,
     * otherwise the intermediary is used for increased liquidity.
     */
    function convertTokens(address[] calldata tokenAddresses, bool isIndirect, uint256 deadline) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        _status = RE_ENTERED;
        require(msg.sender == _owner, "Not owner");

        // The path between a given token and the reward token within Uniswap.
        address[] memory path;
        if (isIndirect) {
            path = new address[](3);
            path[1] = _intermediaryToken;
            path[2] = _rewardToken;
        } else {
            path = new address[](2);
            path[1] = _rewardToken;
        }
        IUniswapV2Router02 uniswap = IUniswapV2Router02(_uniswapRouterAddress);

        address tokenAddress;
        IERC20 tokenContract;
        
        uint256 amount;
        uint256 count = tokenAddresses.length;
        for (uint256 i; i < count; i ++) {
            // Validate the token.
            tokenAddress = tokenAddresses[i];
            require(tokenAddress != address(0),    "Can't be zero address");
            require(tokenAddress != address(this), "Can't be this address");
            require(tokenAddress != _rewardToken,  "Can't be target address");
            
            // Make sure this contract actually has a balance.
            tokenContract = IERC20(tokenAddress);
            amount = tokenContract.balanceOf(address(this));
            if (amount == 0) {
                continue;
            }

            // Swap the tokens.
            tokenContract.approve(_uniswapRouterAddress, amount);
            path[0] = tokenAddress;
            uniswap.swapExactTokensForTokens(amount, 1, path, address(this), deadline);
        }

        // By storing the original amount once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = RE_NOT_ENTERED;
    }

    /** This should always be the same as `GoaldToken.getGovernanceStage()`. */
    function getGovernanceStage() external view returns (uint256) {
        return _governanceStage;
    }

    /** Called when the DAO has been initialized. */
    function updateGovernanceStage() external {
        uint256 governanceStage = IGoaldToken(_goaldToken).getGovernanceStage();

        // Make sure the owner is updated to the goald token if the DAO has been initiated.
        if (governanceStage >= STAGE_DAO_INITIATED && _owner != _goaldToken) {
            _owner = _goaldToken;
        }

        _governanceStage = governanceStage;
    }

    /**
     * Changes which token will be the reward token. This can only happen if there is no balance in reserve held for rewards. If a
     * change is desired despite there being excess rewards, call `withdrawReward()` on behalf of each holder to drain the reserve.
     */
    function setRewardToken(address newToken) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner,        "Not owner");
        require(newToken != address(0),      "Can't be zero address");
        require(newToken != address(this),   "Can't be this address");
        require(_reservedRewardBalance == 0, "Have reserved balance");

        _rewardToken = newToken;
    }

    /// Rewards ///

    /**
     * Check which rewards a given address is eligible for, and update their current reward balance to reflect that total. Since
     * balances are static until transferred (or minted in the case of a new Goald being created), this function is called before
     * any change to a given addresses' balance. Ths will bring them up to date with any past, unclaimed rewards. Any future rewards
     * will be dependant on their balance after the change.
     */
    function _checkRewardBalance(address holder) internal {
        // There is no need for reentrancy since this only updates the `_rewardBalance` for a given holder according to the amounts
        // they are already owed according to the current state. If this is an unexpected reentrant call, then that holder gets the
        // benefit of this math without having to pay the gas.

        // The total number of rewards issued.
        uint256 count = _rewardMultipliers.length;

        // The holder has already claimed all rewards.
        uint256 currentMinimumIndex = _minimumRewardIndex[holder];
        if (currentMinimumIndex == count) {
            return;
        }

        // The holder is not eligible for a reward according to their current balance.
        uint256 balance = IGoaldToken(_goaldToken).balanceOf(holder);
        if (balance < REWARD_THRESHOLD) {
            // Mark that they have been checked for all rewards.
            if (currentMinimumIndex < count) {
                _minimumRewardIndex[holder] = count;
            }

            return;
        }

        // Calculate the balance increase according to which rewards the holder has yet to claim. We don't change how much is held in
        // reserve, even if the balance would close out a given reward. Those tokens must still be held until such time as the holder
        // chooses to claim (or someone claims on their behalf).
        uint256 multiplier;
        uint256 totalMultiplier;
        for (; currentMinimumIndex < count; currentMinimumIndex ++) {
            // This can never overflow since a reward can't be created unless there is enough reserve balance to cover its
            // multiplier, which already checks for overflows, likewise `multiplier * balance` can never overflow.
            multiplier = _rewardMultipliers[currentMinimumIndex];
            totalMultiplier += multiplier;

            // Close out this reward.
            if (_rewardHolderCounts[currentMinimumIndex] == 1) {
                _rewardHolderCounts[currentMinimumIndex] = 0;
                _rewardReserves[currentMinimumIndex] = 0;
                // We don't wipe `_rewardMultipliers` here despite this being the last holder, so we have a historical record.
            } else {
                _rewardHolderCounts[currentMinimumIndex]--;
                _rewardReserves[currentMinimumIndex] -= multiplier * balance;
            }
        }
        _minimumRewardIndex[holder] = count;

        // Update their claimable balance.
        uint256 currentBalance = _rewardBalance[holder];
        require(currentBalance + (totalMultiplier * balance) > currentBalance, "Balance overflow");
        _rewardBalance[holder] = currentBalance + (totalMultiplier * balance);
    }

    /**
     * Creates a new reward. Rewards are only paid out to holders who have at least "one token" at time of creation. The reward
     * is a multiplier, representing how many reward tokens (e.g., WBTC) should be paid out for one governance token. reward
     * eligibility is only updated in state in two cases:
     *      1) When a reward is being withdrawn (in which it is set to zero).
     *      2) When the governance token is transferred (balances are checked before the transfer, on both sender and recipient).
     */
    function createReward(uint256 multiplier, string calldata reason) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        _status = RE_ENTERED;
        require(msg.sender == _owner,                    "Not owner");
        require(_governanceStage >= STAGE_DAO_INITIATED, "DAO not initiated");
        require(multiplier > 0,                          "Multiplier must be > 0");

        // Make sure we can actually create a reward with that amount. This balance of the reward token at this proxy address should
        // never decrease except when rewards are claimed by holders.
        uint256 reservedRewardBalance = _reservedRewardBalance;
        uint256 currentBalance = IERC20(_rewardToken).balanceOf(address(this));
        require(currentBalance >= reservedRewardBalance, "Current reserve insufficient");
        uint256 reserveIncrease = IGoaldToken(_goaldToken).totalSupply() * multiplier;
        require(reserveIncrease <= (currentBalance - reservedRewardBalance), "Multiplier too large");

        // Increase the reserve.
        require((reservedRewardBalance + reserveIncrease) > reservedRewardBalance, "Reserved overflow error");
        _reservedRewardBalance += reserveIncrease;

        // Keep track of the holders, reserve, and multiplier for this reward. These values will not increase after being set here.
        uint256 holders = _rewardHolders;
        require(holders > 0, "Must have a holder");
        _rewardHolderCounts.push(holders);
        _rewardMultipliers.push(multiplier);
        _rewardReserves.push(reserveIncrease);

        // Hello world!
        emit RewardCreated(multiplier, reason);

        // By storing the original amount once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = RE_NOT_ENTERED;
    }

    /** Returns the reward balance for a holder according to the true state, not the hard state. See: `_checkRewardBalance()`. */
    function getHolderRewardBalance(address holder) external view returns (uint256) {
        uint256 count = _rewardMultipliers.length;
        uint256 balance = IGoaldToken(_goaldToken).balanceOf(holder);
        uint256 rewardBalance = _rewardBalance[holder];
        uint256 currentMinimumIndex = _minimumRewardIndex[holder];
        for (; currentMinimumIndex < count; currentMinimumIndex ++) {
            rewardBalance += _rewardMultipliers[currentMinimumIndex] * balance;
        }

        return rewardBalance;
    }

    /** Return the general reward details. */
    function getRewardDetails() external view returns (uint256[4] memory) {
        return [
            uint256(_rewardToken),
            _rewardReserves.length,
            _rewardHolders,
            _reservedRewardBalance
        ];
    }

    /** Get the details of the reward at the specified index.*/
    function getRewardDetailsAt(uint256 index) external view returns (uint256[3] memory) {
        return [
            _rewardMultipliers[index],
            _rewardHolderCounts[index],
            _rewardReserves[index]
        ];
    }

    /**
     * Withdraws the current reward balance. The sender doesn't need to have any current balance of the governance token to
     * withdraw, so long as they have a preexisting outstanding balance. This has a provided recipient so that we can drain the
     * reward pool as necessary (e.g., for changing the reward token).
     */
    function withdrawReward(address holder) external {
        // Reentrancy guard. Allow owner to drain the pool even if frozen.
        require(_status == RE_NOT_ENTERED || (_status == RE_FROZEN && msg.sender == _owner));
        _status = RE_ENTERED;

        // Update their balance.
        _checkRewardBalance(holder);

        // Revert so gas estimators will show a failure.
        uint256 balance = _rewardBalance[holder];
        require(balance > 0, "No reward balance");

        // Wipe the balance.
        _rewardBalance[holder] = 0;
        require(_reservedRewardBalance - balance > 0, "Reserved balance underflow");
        _reservedRewardBalance -= balance;

        // Give them their balance.
        IERC20(_rewardToken).transfer(holder, balance);

        // By storing the original amount once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = RE_NOT_ENTERED;
    }

    /// ERC20 Overrides ///

    /** Update the reward balances prior to the transfer completing. */
    function preTransfer(address sender, address recipient) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        _status = RE_ENTERED;

        // Caller must be the Goald token
        require(msg.sender == _goaldToken, "Caller not Goald token");

        // Update the reward balances prior to the transfer for both sender and receiver.
        _checkRewardBalance(sender);
        _checkRewardBalance(recipient);

        // By storing the original amount once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = RE_NOT_ENTERED;
    }

    /** Updates holder counts after doing a transfer. */
    function postTransfer(address sender, uint256 senderBefore, uint256 senderAfter, uint256 recipientBefore, uint256 recipientAfter) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);

        // Caller must be the Goald token
        require(msg.sender == _goaldToken, "Caller not Goald token");

        // See if we need to change `_rewardHolders`.
        if        (senderBefore  < REWARD_THRESHOLD && senderAfter >= REWARD_THRESHOLD) {
            _rewardHolders ++;
        } else if (senderBefore >= REWARD_THRESHOLD && senderAfter  < REWARD_THRESHOLD) {
            _rewardHolders --;
        }
        if        (recipientBefore  < REWARD_THRESHOLD && recipientAfter >= REWARD_THRESHOLD) {
            _rewardHolders ++;
        } else if (recipientBefore >= REWARD_THRESHOLD && recipientAfter  < REWARD_THRESHOLD) {
            _rewardHolders --;
        }

        // The sender has no balance, so clear their minimum index. This should save on total storage space for this contract. We do
        // not clear the reward balance even if their token balance is zero, since they still have a claim to that balance.
        if (senderAfter == 0) {
            _minimumRewardIndex[sender] = 0;
        }
    }
}