// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(
      data
    );
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

interface IOwnable {
  function manager() external view returns (address);

  function renounceManagement() external;

  function pushManagement(address newOwner_) external;

  function pullManagement() external;
}

contract Ownable is IOwnable {
  address internal _owner;
  address internal _newOwner;

  event OwnershipPushed(
    address indexed previousOwner,
    address indexed newOwner
  );
  event OwnershipPulled(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _owner = msg.sender;
    emit OwnershipPushed(address(0), _owner);
  }

  function manager() public view override returns (address) {
    return _owner;
  }

  modifier onlyManager() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceManagement() public virtual override onlyManager {
    emit OwnershipPushed(_owner, address(0));
    _owner = address(0);
  }

  function pushManagement(address newOwner_)
    public
    virtual
    override
    onlyManager
  {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipPushed(_owner, newOwner_);
    _newOwner = newOwner_;
  }

  function pullManagement() public virtual override {
    require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
    emit OwnershipPulled(_owner, _newOwner);
    _owner = _newOwner;
  }
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

interface IERC721 is IERC165 {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

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
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

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
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

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
  function getApproved(uint256 tokenId)
    external
    view
    returns (address operator);

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
  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool);

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
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  /**
   * @dev Returns the total amount of tokens stored by the contract.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
   * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    external
    view
    returns (uint256 tokenId);

  /**
   * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
   * Use along with {totalSupply} to enumerate all tokens.
   */
  function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC20 {
  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function totalSupply() external view returns (uint256);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(
      data,
      "SafeERC20: low-level call failed"
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        "SafeERC20: ERC20 operation did not succeed"
      );
    }
  }
}

interface IERC20Mintable {
  function mint(uint256 amount_) external;

  function mint(address account_, uint256 ammount_) external;
}

interface IGURUERC20 {
  function burnFrom(address account_, uint256 amount_) external;
}

interface IBondCalculator {
  function valuation(address pair_, uint256 amount_)
    external
    view
    returns (uint256 _value);
}

// There is bond calculator per NFT
interface INFTBondCalculator {
  function valuation() external view returns (uint256 _value);
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
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

contract NidhiTreasuryV2 is Ownable, IERC721Receiver {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Deposit(address indexed token, uint256 amount, uint256 value);
  event DepositNFT(address indexed token, uint256 tokenId, uint256 value);
  event Withdrawal(address indexed token, uint256 amount, uint256 value);
  event WithdrawalNFT(address indexed token, uint256 tokenId, uint256 value);
  event CreateDebt(
    address indexed debtor,
    address indexed token,
    uint256 amount,
    uint256 value
  );
  event CreateDebtNFT(
    address indexed debtor,
    address indexed token,
    uint256 tokenId,
    uint256 value
  );
  event RepayDebt(
    address indexed debtor,
    address indexed token,
    uint256 amount,
    uint256 value
  );
  event RepayDebtNFT(
    address indexed debtor,
    address indexed token,
    uint256 tokenId,
    uint256 value
  );
  event ReservesManaged(address indexed token, uint256 amount);
  event ReservesManagedNFT(address indexed token, uint256 tokenId);
  event ReservesUpdated(uint256 indexed totalReserves);
  event ReservesAudited(uint256 indexed totalReserves);
  event RewardsMinted(
    address indexed caller,
    address indexed recipient,
    uint256 amount
  );
  event ChangeQueued(MANAGING indexed managing, address queued);
  event ChangeActivated(
    MANAGING indexed managing,
    address activated,
    bool result
  );

  enum MANAGING {
    RESERVEDEPOSITOR,
    RESERVESPENDER,
    RESERVETOKEN,
    RESERVEMANAGER,
    LIQUIDITYDEPOSITOR,
    LIQUIDITYTOKEN,
    LIQUIDITYMANAGER,
    DEBTOR,
    REWARDMANAGER,
    SGURU,
    NFTDEPOSITOR,
    NFTSPENDER,
    NFTTOKEN,
    NFTMANAGER
  }

  address public immutable GURU;
  uint256 public immutable blocksNeededForQueue;

  address[] public reserveTokens; // Push only, beware false-positives.
  mapping(address => bool) public isReserveToken;
  mapping(address => uint256) public reserveTokenQueue; // Delays changes to mapping.

  address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isReserveDepositor;
  mapping(address => uint256) public reserveDepositorQueue; // Delays changes to mapping.

  address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isReserveSpender;
  mapping(address => uint256) public reserveSpenderQueue; // Delays changes to mapping.

  address[] public nonFungibleTokens; // Push only, beware false-positives.
  mapping(address => bool) public isNonFungibleToken;
  mapping(address => uint256) public nonFungibleTokenQueue; // Delays changes to mapping.

  address[] public nonFungibleTokenDepositors; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isNonFungibleTokenDepositor;
  mapping(address => uint256) public nonFungibleTokenDepositorQueue; // Delays changes to mapping.

  address[] public nonFungibleTokenSpenders; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isNonFungibleTokenSpender;
  mapping(address => uint256) public nonFungibleTokenSpenderQueue; // Delays changes to mapping.

  address[] public liquidityTokens; // Push only, beware false-positives.
  mapping(address => bool) public isLiquidityToken;
  mapping(address => uint256) public LiquidityTokenQueue; // Delays changes to mapping.

  address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isLiquidityDepositor;
  mapping(address => uint256) public LiquidityDepositorQueue; // Delays changes to mapping.

  mapping(address => address) public bondCalculator; // bond calculator for liquidity token

  address[] public reserveManagers; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isReserveManager;
  mapping(address => uint256) public ReserveManagerQueue; // Delays changes to mapping.

  address[] public nonFungibleTokenManagers; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isNonFungibleTokenManager;
  mapping(address => uint256) public NonFungibleTokenManagerQueue; // Delays changes to mapping.

  address[] public liquidityManagers; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isLiquidityManager;
  mapping(address => uint256) public LiquidityManagerQueue; // Delays changes to mapping.

  address[] public debtors; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isDebtor;
  mapping(address => uint256) public debtorQueue; // Delays changes to mapping.
  mapping(address => uint256) public debtorBalance;

  address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isRewardManager;
  mapping(address => uint256) public rewardManagerQueue; // Delays changes to mapping.

  address public sGURU;
  uint256 public sGURUQueue; // Delays change to sGURU address

  uint256 public totalReserves; // Risk-free value of all assets
  uint256 public totalDebt;

  constructor(
    address _GURU,
    address _DAI,
    address _GURUDAI,
    uint256 _blocksNeededForQueue
  ) {
    require(_GURU != address(0));
    GURU = _GURU;

    isReserveToken[_DAI] = true;
    reserveTokens.push(_DAI);

    isLiquidityToken[_GURUDAI] = true;
    liquidityTokens.push(_GURUDAI);

    blocksNeededForQueue = _blocksNeededForQueue;
  }

  /**
        @notice allow approved address to deposit an asset for GURU
        @param _amount uint
        @param _token address
        @param _profit uint
        @return send_ uint
     */
  function deposit(
    uint256 _amount,
    address _token,
    uint256 _profit
  ) external returns (uint256 send_) {
    require(isReserveToken[_token] || isLiquidityToken[_token], "Not accepted");
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

    if (isReserveToken[_token]) {
      require(isReserveDepositor[msg.sender], "Not approved");
    } else {
      require(isLiquidityDepositor[msg.sender], "Not approved");
    }

    uint256 value = valueOf(_token, _amount);
    // mint GURU needed and store amount of rewards for distribution
    send_ = value.sub(_profit);
    IERC20Mintable(GURU).mint(msg.sender, send_);

    totalReserves = totalReserves.add(value);
    emit ReservesUpdated(totalReserves);

    emit Deposit(_token, _amount, value);
  }

  /**
        @notice allow approved address to deposit an asset for GURU
        @param _token address
        @param _tokenId uint256
        @param _isAllProfit bool
        @return send_ uint
     */
  function depositNFT(
    address _token,
    uint256 _tokenId,
    bool _isAllProfit
  ) external returns (uint256 send_) {
    require(isNonFungibleToken[_token], "Not accepted");
    IERC721(_token).safeTransferFrom(
      msg.sender,
      address(this),
      _tokenId,
      new bytes(0)
    );

    require(isNonFungibleTokenDepositor[msg.sender], "Not approved");

    uint256 value = valueOfNFT(_token);
    // mint GURU needed and store amount of rewards for distribution
    if (!_isAllProfit) {
      IERC20Mintable(GURU).mint(msg.sender, value);
    }

    totalReserves = totalReserves.add(value);
    emit ReservesUpdated(totalReserves);

    emit DepositNFT(_token, _tokenId, value);
  }

  /**
        @notice allow approved address to burn GURU for reserves
        @param _amount uint
        @param _token address
     */
  function withdraw(uint256 _amount, address _token) external {
    require(isReserveToken[_token], "Not accepted"); // Only reserves can be used for redemptions
    require(isReserveSpender[msg.sender] == true, "Not approved");

    uint256 value = valueOf(_token, _amount);
    IGURUERC20(GURU).burnFrom(msg.sender, value);

    totalReserves = totalReserves.sub(value);
    emit ReservesUpdated(totalReserves);

    IERC20(_token).safeTransfer(msg.sender, _amount);

    emit Withdrawal(_token, _amount, value);
  }

  /**
        @notice allow approved address to burn GURU for reserves
        @param _token address
        @param _tokenId uint256
     */
  function withdrawNFT(address _token, uint256 _tokenId) external {
    require(isNonFungibleToken[_token], "Not accepted"); // Only reserves can be used for redemptions
    require(isNonFungibleTokenSpender[msg.sender] == true, "Not approved");

    uint256 value = valueOfNFT(_token);
    IGURUERC20(GURU).burnFrom(msg.sender, value);

    totalReserves = totalReserves.sub(value);
    emit ReservesUpdated(totalReserves);

    IERC721(_token).safeTransferFrom(
      address(this),
      msg.sender,
      _tokenId,
      new bytes(0)
    );

    emit WithdrawalNFT(_token, _tokenId, value);
  }

  /**
        @notice allow approved address to borrow reserves
        @param _amount uint
        @param _token address
     */
  function incurDebt(uint256 _amount, address _token) external {
    require(isDebtor[msg.sender], "Not approved");
    require(isReserveToken[_token], "Not accepted");

    uint256 value = valueOf(_token, _amount);

    uint256 maximumDebt = IERC20(sGURU).balanceOf(msg.sender); // Can only borrow against sGURU held
    uint256 availableDebt = maximumDebt.sub(debtorBalance[msg.sender]);
    require(value <= availableDebt, "Exceeds debt limit");

    debtorBalance[msg.sender] = debtorBalance[msg.sender].add(value);
    totalDebt = totalDebt.add(value);

    totalReserves = totalReserves.sub(value);
    emit ReservesUpdated(totalReserves);

    IERC20(_token).transfer(msg.sender, _amount);

    emit CreateDebt(msg.sender, _token, _amount, value);
  }

  /**
        @notice allow approved address to borrow reserves
        @param _token address
        @param _tokenId uint256
     */
  function incurDebtNFT(address _token, uint256 _tokenId) external {
    require(isDebtor[msg.sender], "Not approved");
    require(isNonFungibleToken[_token], "Not accepted");

    uint256 value = valueOfNFT(_token);

    uint256 maximumDebt = IERC20(sGURU).balanceOf(msg.sender); // Can only borrow against sGURU held
    uint256 availableDebt = maximumDebt.sub(debtorBalance[msg.sender]);
    require(value <= availableDebt, "Exceeds debt limit");

    debtorBalance[msg.sender] = debtorBalance[msg.sender].add(value);
    totalDebt = totalDebt.add(value);

    totalReserves = totalReserves.sub(value);
    emit ReservesUpdated(totalReserves);

    IERC721(_token).safeTransferFrom(
      address(this),
      msg.sender,
      _tokenId,
      new bytes(0)
    );

    emit CreateDebtNFT(msg.sender, _token, _tokenId, value);
  }

  /**
        @notice allow approved address to repay borrowed reserves with reserves
        @param _amount uint
        @param _token address
     */
  function repayDebtWithReserve(uint256 _amount, address _token) external {
    require(isDebtor[msg.sender], "Not approved");
    require(isReserveToken[_token], "Not accepted");

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

    uint256 value = valueOf(_token, _amount);
    debtorBalance[msg.sender] = debtorBalance[msg.sender].sub(value);
    totalDebt = totalDebt.sub(value);

    totalReserves = totalReserves.add(value);
    emit ReservesUpdated(totalReserves);

    emit RepayDebt(msg.sender, _token, _amount, value);
  }

  /**
        @notice allow approved address to repay borrowed reserves with an NFT
        @param _token address
        @param _tokenId uint
     */
  function repayDebtWithNFT(address _token, uint256 _tokenId) external {
    require(isDebtor[msg.sender], "Not approved");
    require(isNonFungibleToken[_token], "Not accepted");

    IERC721(_token).safeTransferFrom(
      msg.sender,
      address(this),
      _tokenId,
      new bytes(0)
    );

    uint256 value = valueOfNFT(_token);
    debtorBalance[msg.sender] = debtorBalance[msg.sender].sub(value);
    totalDebt = totalDebt.sub(value);

    totalReserves = totalReserves.add(value);
    emit ReservesUpdated(totalReserves);

    emit RepayDebtNFT(msg.sender, _token, _tokenId, value);
  }

  /**
        @notice allow approved address to repay borrowed reserves with GURU
        @param _amount uint
     */
  function repayDebtWithGURU(uint256 _amount) external {
    require(isDebtor[msg.sender], "Not approved");

    IGURUERC20(GURU).burnFrom(msg.sender, _amount);

    debtorBalance[msg.sender] = debtorBalance[msg.sender].sub(_amount);
    totalDebt = totalDebt.sub(_amount);

    emit RepayDebt(msg.sender, GURU, _amount, _amount);
  }

  /**
        @notice allow approved address to withdraw assets
        @param _token address
        @param _amount uint
     */
  function manage(address _token, uint256 _amount) external {
    if (isLiquidityToken[_token]) {
      require(isLiquidityManager[msg.sender], "Not approved");
    } else {
      require(isReserveManager[msg.sender], "Not approved");
    }

    uint256 value = valueOf(_token, _amount);
    require(value <= excessReserves(), "Insufficient reserves");

    totalReserves = totalReserves.sub(value);
    emit ReservesUpdated(totalReserves);

    IERC20(_token).safeTransfer(msg.sender, _amount);

    emit ReservesManaged(_token, _amount);
  }

  /**
        @notice allow approved address to withdraw NFTs
        @param _token address
        @param _tokenId uint
     */
  function manageNFT(address _token, uint256 _tokenId) external {
    require(isNonFungibleTokenManager[msg.sender], "Not approved");

    uint256 value = valueOfNFT(_token);
    require(value <= excessReserves(), "Insufficient reserves");

    totalReserves = totalReserves.sub(value);
    emit ReservesUpdated(totalReserves);

    IERC721(_token).safeTransferFrom(
      address(this),
      msg.sender,
      _tokenId,
      new bytes(0)
    );

    emit ReservesManagedNFT(_token, _tokenId);
  }

  /**
        @notice send epoch reward to staking contract
     */
  function mintRewards(address _recipient, uint256 _amount) external {
    require(isRewardManager[msg.sender], "Not approved");
    require(_amount <= excessReserves(), "Insufficient reserves");

    IERC20Mintable(GURU).mint(_recipient, _amount);

    emit RewardsMinted(msg.sender, _recipient, _amount);
  }

  /**
        @notice returns excess reserves not backing tokens
        @return uint
     */
  function excessReserves() public view returns (uint256) {
    return totalReserves.sub(IERC20(GURU).totalSupply().sub(totalDebt));
  }

  /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized reserves before audit
     */
  function auditReserves() external onlyManager {
    uint256 reserves;
    for (uint256 i = 0; i < reserveTokens.length; i++) {
      reserves = reserves.add(
        valueOf(
          reserveTokens[i],
          IERC20(reserveTokens[i]).balanceOf(address(this))
        )
      );
    }
    for (uint256 i = 0; i < liquidityTokens.length; i++) {
      reserves = reserves.add(
        valueOf(
          liquidityTokens[i],
          IERC20(liquidityTokens[i]).balanceOf(address(this))
        )
      );
    }
    for (uint256 i = 0; i < nonFungibleTokens.length; i++) {
      uint256 thisBalance = IERC721(nonFungibleTokens[i]).balanceOf(
        address(this)
      );

      for (uint256 j = 0; j < thisBalance; j++) {
        uint256 tokenId = IERC721(nonFungibleTokens[i]).tokenOfOwnerByIndex(
          address(this),
          j
        );
        reserves = reserves.add(valueOf(nonFungibleTokens[i], tokenId));
      }
    }
    totalReserves = reserves;
    emit ReservesUpdated(reserves);
    emit ReservesAudited(reserves);
  }

  /**
        @notice returns GURU valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
  function valueOf(address _token, uint256 _amount)
    public
    view
    returns (uint256 value_)
  {
    if (isReserveToken[_token]) {
      // convert amount to match GURU decimals
      value_ = _amount.mul(10**IERC20(GURU).decimals()).div(
        10**IERC20(_token).decimals()
      );
    } else if (isLiquidityToken[_token]) {
      value_ = IBondCalculator(bondCalculator[_token]).valuation(
        _token,
        _amount
      );
    }
  }

  /**
        @notice returns GURU valuation of NFT
        @param _token address
        @return value_ uint
     */
  function valueOfNFT(address _token) public view returns (uint256 value_) {
    value_ = INFTBondCalculator(bondCalculator[_token]).valuation();
  }

  /**
        @notice queue address to change boolean in mapping
        @param _managing MANAGING
        @param _address address
        @return bool
     */
  function queue(MANAGING _managing, address _address)
    external
    onlyManager
    returns (bool)
  {
    require(_address != address(0));
    if (_managing == MANAGING.RESERVEDEPOSITOR) {
      // 0
      reserveDepositorQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.RESERVESPENDER) {
      // 1
      reserveSpenderQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.RESERVETOKEN) {
      // 2
      reserveTokenQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.RESERVEMANAGER) {
      // 3
      ReserveManagerQueue[_address] = block.number.add(
        blocksNeededForQueue.mul(2)
      );
    } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
      // 4
      LiquidityDepositorQueue[_address] = block.number.add(
        blocksNeededForQueue
      );
    } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
      // 5
      LiquidityTokenQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.LIQUIDITYMANAGER) {
      // 6
      LiquidityManagerQueue[_address] = block.number.add(
        blocksNeededForQueue.mul(2)
      );
    } else if (_managing == MANAGING.DEBTOR) {
      // 7
      debtorQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.REWARDMANAGER) {
      // 8
      rewardManagerQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.SGURU) {
      // 9
      sGURUQueue = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.NFTDEPOSITOR) {
      // 10
      nonFungibleTokenDepositorQueue[_address] = block.number.add(
        blocksNeededForQueue
      );
    } else if (_managing == MANAGING.NFTSPENDER) {
      // 11
      nonFungibleTokenSpenderQueue[_address] = block.number.add(
        blocksNeededForQueue
      );
    } else if (_managing == MANAGING.NFTTOKEN) {
      // 12
      nonFungibleTokenQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.NFTMANAGER) {
      // 13
      NonFungibleTokenManagerQueue[_address] = block.number.add(
        blocksNeededForQueue.mul(2)
      );
    } else return false;

    emit ChangeQueued(_managing, _address);
    return true;
  }

  /**
        @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @param _calculator address
        @return bool
     */
  function toggle(
    MANAGING _managing,
    address _address,
    address _calculator
  ) external onlyManager returns (bool) {
    require(_address != address(0));
    bool result;
    if (_managing == MANAGING.RESERVEDEPOSITOR) {
      // 0
      if (requirements(reserveDepositorQueue, isReserveDepositor, _address)) {
        reserveDepositorQueue[_address] = 0;
        if (!listContains(reserveDepositors, _address)) {
          reserveDepositors.push(_address);
        }
      }
      result = !isReserveDepositor[_address];
      isReserveDepositor[_address] = result;
    } else if (_managing == MANAGING.RESERVESPENDER) {
      // 1
      if (requirements(reserveSpenderQueue, isReserveSpender, _address)) {
        reserveSpenderQueue[_address] = 0;
        if (!listContains(reserveSpenders, _address)) {
          reserveSpenders.push(_address);
        }
      }
      result = !isReserveSpender[_address];
      isReserveSpender[_address] = result;
    } else if (_managing == MANAGING.RESERVETOKEN) {
      // 2
      if (requirements(reserveTokenQueue, isReserveToken, _address)) {
        reserveTokenQueue[_address] = 0;
        if (!listContains(reserveTokens, _address)) {
          reserveTokens.push(_address);
        }
      }
      result = !isReserveToken[_address];
      isReserveToken[_address] = result;
    } else if (_managing == MANAGING.RESERVEMANAGER) {
      // 3
      if (requirements(ReserveManagerQueue, isReserveManager, _address)) {
        reserveManagers.push(_address);
        ReserveManagerQueue[_address] = 0;
        if (!listContains(reserveManagers, _address)) {
          reserveManagers.push(_address);
        }
      }
      result = !isReserveManager[_address];
      isReserveManager[_address] = result;
    } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
      // 4
      if (
        requirements(LiquidityDepositorQueue, isLiquidityDepositor, _address)
      ) {
        liquidityDepositors.push(_address);
        LiquidityDepositorQueue[_address] = 0;
        if (!listContains(liquidityDepositors, _address)) {
          liquidityDepositors.push(_address);
        }
      }
      result = !isLiquidityDepositor[_address];
      isLiquidityDepositor[_address] = result;
    } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
      // 5
      if (requirements(LiquidityTokenQueue, isLiquidityToken, _address)) {
        LiquidityTokenQueue[_address] = 0;
        if (!listContains(liquidityTokens, _address)) {
          liquidityTokens.push(_address);
        }
      }
      result = !isLiquidityToken[_address];
      isLiquidityToken[_address] = result;
      bondCalculator[_address] = _calculator;
    } else if (_managing == MANAGING.LIQUIDITYMANAGER) {
      // 6
      if (requirements(LiquidityManagerQueue, isLiquidityManager, _address)) {
        LiquidityManagerQueue[_address] = 0;
        if (!listContains(liquidityManagers, _address)) {
          liquidityManagers.push(_address);
        }
      }
      result = !isLiquidityManager[_address];
      isLiquidityManager[_address] = result;
    } else if (_managing == MANAGING.DEBTOR) {
      // 7
      if (requirements(debtorQueue, isDebtor, _address)) {
        debtorQueue[_address] = 0;
        if (!listContains(debtors, _address)) {
          debtors.push(_address);
        }
      }
      result = !isDebtor[_address];
      isDebtor[_address] = result;
    } else if (_managing == MANAGING.REWARDMANAGER) {
      // 8
      if (requirements(rewardManagerQueue, isRewardManager, _address)) {
        rewardManagerQueue[_address] = 0;
        if (!listContains(rewardManagers, _address)) {
          rewardManagers.push(_address);
        }
      }
      result = !isRewardManager[_address];
      isRewardManager[_address] = result;
    } else if (_managing == MANAGING.SGURU) {
      // 9
      sGURUQueue = 0;
      sGURU = _address;
      result = true;
    } else if (_managing == MANAGING.NFTDEPOSITOR) {
      // 10
      if (
        requirements(
          nonFungibleTokenDepositorQueue,
          isNonFungibleTokenDepositor,
          _address
        )
      ) {
        nonFungibleTokenDepositorQueue[_address] = 0;
        if (!listContains(nonFungibleTokenDepositors, _address)) {
          nonFungibleTokenDepositors.push(_address);
        }
      }
      result = !isNonFungibleTokenDepositor[_address];
      isNonFungibleTokenDepositor[_address] = result;
    } else if (_managing == MANAGING.NFTSPENDER) {
      // 11
      if (
        requirements(
          nonFungibleTokenSpenderQueue,
          isNonFungibleTokenSpender,
          _address
        )
      ) {
        nonFungibleTokenSpenderQueue[_address] = 0;
        if (!listContains(nonFungibleTokenSpenders, _address)) {
          nonFungibleTokenSpenders.push(_address);
        }
      }
      result = !isNonFungibleTokenSpender[_address];
      isNonFungibleTokenSpender[_address] = result;
    } else if (_managing == MANAGING.NFTTOKEN) {
      // 12
      if (requirements(nonFungibleTokenQueue, isNonFungibleToken, _address)) {
        nonFungibleTokenQueue[_address] = 0;
        if (!listContains(nonFungibleTokens, _address)) {
          nonFungibleTokens.push(_address);
        }
      }
      result = !isNonFungibleToken[_address];
      isNonFungibleToken[_address] = result;
      bondCalculator[_address] = _calculator;
    } else if (_managing == MANAGING.NFTMANAGER) {
      // 13
      if (
        requirements(
          NonFungibleTokenManagerQueue,
          isNonFungibleTokenManager,
          _address
        )
      ) {
        nonFungibleTokenManagers.push(_address);
        NonFungibleTokenManagerQueue[_address] = 0;
        if (!listContains(nonFungibleTokenManagers, _address)) {
          nonFungibleTokenManagers.push(_address);
        }
      }
      result = !isNonFungibleTokenManager[_address];
      isNonFungibleTokenManager[_address] = result;
    } else return false;

    emit ChangeActivated(_managing, _address, result);
    return true;
  }

  /**
        @notice checks requirements and returns altered structs
        @param queue_ mapping( address => uint )
        @param status_ mapping( address => bool )
        @param _address address
        @return bool 
     */
  function requirements(
    mapping(address => uint256) storage queue_,
    mapping(address => bool) storage status_,
    address _address
  ) internal view returns (bool) {
    if (!status_[_address]) {
      require(queue_[_address] != 0, "Must queue");
      require(queue_[_address] <= block.number, "Queue not expired");
      return true;
    }
    return false;
  }

  /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
  function listContains(address[] storage _list, address _token)
    internal
    view
    returns (bool)
  {
    for (uint256 i = 0; i < _list.length; i++) {
      if (_list[i] == _token) {
        return true;
      }
    }
    return false;
  }

  function onERC721Received(
    address operator,
    address,
    uint256 tokenId,
    bytes calldata
  ) external override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}