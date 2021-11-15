// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

// Inheritance
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Libraries
import "./libraries/Address.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/SafeMath.sol";

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IERC1155.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IHolderVault.sol";
import "./interfaces/IRoundManager.sol";
import "./interfaces/IAirdropVault.sol";

contract Crowdfunding is OwnableUpgradeable {
    // ========== LIBRARIES ==========
    using SafeMath for uint256;

    // ========== STATE VARIABLES ==========
    address private onekeyToken;
    address private targetAssest;
    address private ETH;
    address private vault;

    address public holderContract;
    address public airdropContract;
    address public roundContract;

    mapping(address => bool) private stableCoins;
    mapping(uint256 => Wallet) public wallets;
    mapping(address => bool) private allowedSwapTargets;
    mapping(address => bool) private allowedSellTokens;

    uint256 public gasPriceLimit;

    struct Wallet {
        uint256 pID;
        uint256 prices;
        uint256 referral;
        uint256 holder;
        uint256 airdrop;
        uint256 airdropWeight;
        uint256 jackpot;
    }

    // ========== EVENTS ==========
    event SetRewarContracts(address holder, address airdrop, address round);
    event SetAcceptableStableCoin(address indexed _token, bool _status);
    event SetProduct(Wallet wallet);
    event AddAllowedSwapTarget(address indexed _target);
    event DeleteAllowedSwapTarget(address indexed _target);
    event AddAllowedSellToken(address indexed _token);
    event DeleteAllowedSellToken(address indexed _token);

    event WalletOrder(
        uint256 indexed pID,
        address indexed buyer,
        uint256 pAmount,
        address indexed referral,
        address sellToken,
        uint256 sellAmount,
        uint256 amount
    );
    event RewardDetail(
        address indexed referral,
        uint256 referralAmount,
        uint256 holderAmount,
        uint256 jackpotAmount,
        uint256 airdropAmount
    );

    // ========== CONSTRUCTOR ==========
    function initialize(
        address _onekeyToken,
        address _targetAssest,
        address _vault
    ) public initializer {
        __Ownable_init();
        require(owner() != address(0), "Zap: owner must be set");
        
        require(_onekeyToken != address(0), "_onekeyToken is a zero address");
        require(_targetAssest != address(0), "_targetAssest is a zero address");
        require(_vault != address(0), "_vault is a zero address");

        onekeyToken = _onekeyToken;
        ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        targetAssest = _targetAssest;
        vault = _vault;
    }

    // ========== SETTERS ==========
    function updateRewardContracts(
        address _holder,
        address _airdrop,
        address _manager
    ) external onlyOwner {
        require(_holder != address(0), "_holder is a zero address");
        require(_airdrop != address(0), "_airdrop is a zero address");
        require(_manager != address(0), "_manager is a zero address");

        holderContract = _holder;
        airdropContract = _airdrop;
        roundContract = _manager;

        emit SetRewarContracts(_holder, _airdrop, _manager);
    }

    function updateStableCoins(
        address[] calldata _tokens,
        bool[] calldata _status
    ) external onlyOwner {
        require(_tokens.length == _status.length, "INVALID_PARAMS");
        for (uint256 i = 0; i < _tokens.length; i++) {
            stableCoins[_tokens[i]] = _status[i];
            emit SetAcceptableStableCoin(_tokens[i], _status[i]);
        }
    }

    function updateWallets(Wallet[] calldata _wallets) external onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            wallets[_wallets[i].pID] = _wallets[i];
            emit SetProduct(_wallets[i]);
        }
    }

    function setGasPriceLimit(uint256 _gasPriceLimit) external onlyOwner {
        require(_gasPriceLimit > 0, "INVALID_PARAMS");
        gasPriceLimit = _gasPriceLimit;
    }

    function addAllowedSwapTargets(address[] calldata _targets) external onlyOwner {
        require(_targets.length > 0, "INVALID_PARAMS");
        
        for (uint256 i = 0; i < _targets.length; i++) {
            allowedSwapTargets[_targets[i]] = true;
            emit AddAllowedSwapTarget(_targets[i]);
        }
    }

    function deleteAllowedSwapTargets(address[] calldata _targets) external onlyOwner {
        require(_targets.length > 0, "INVALID_PARAMS");
        
        for (uint256 i = 0; i < _targets.length; i++) {
            if (allowedSwapTargets[_targets[i]]) {
                delete allowedSwapTargets[_targets[i]];
                emit DeleteAllowedSwapTarget(_targets[i]);
            }
        }
    }

    function addAllowedSellTokens(address[] calldata _tokens) external onlyOwner {
        require(_tokens.length > 0, "INVALID_PARAMS");
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedSellTokens[_tokens[i]] = true;
            emit AddAllowedSellToken(_tokens[i]);
        }
    }

    function deleteAllowedSellTokens(address[] calldata _tokens) external onlyOwner {
        require(_tokens.length > 0, "INVALID_PARAMS");
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (allowedSellTokens[_tokens[i]]) {
                delete allowedSellTokens[_tokens[i]];
                emit DeleteAllowedSellToken(_tokens[i]);
            }
        }
    }

    // ========== PUBLIC FUNCTIONS ==========
    function buyWallet(
        uint256 _pID,
        uint256 _pAmount,
        address _referral,
        address _sellToken,
        uint256 _sellAmount,
        address _spender,
        address payable _swapTarget,
        bytes calldata _swapCallData
    ) external payable {
        require(allowedSwapTargets[_swapTarget], "INVALID_SWAP_TARGET");
        require(allowedSellTokens[_sellToken], "INVALID_SELL_TOKEN");
        require(tx.origin == msg.sender, "EOA_ONLY");
        
        Wallet memory wallet = wallets[_pID];

        require(wallet.prices > 0 && _pAmount > 0, "PRODUCT_NOT_SUPPORT");

        if (_sellToken == ETH) {
            require(msg.value >= _sellAmount, "WRONG_INPUT_PARMS");
        } else {
            require(
                _sellToken != address(0) && _sellAmount > 0,
                "WRONG_INPUT_PARMS"
            );
            TransferHelper.safeTransferFrom(
                _sellToken,
                msg.sender,
                address(this),
                _sellAmount
            );
        }

        uint256 amount;

        if (_sellToken != targetAssest) {
            _fillQuote(
                _sellToken,
                _sellAmount,
                _spender,
                _swapTarget,
                _swapCallData
            );

            amount = IERC20(targetAssest).balanceOf(address(this));

            if (stableCoins[_sellToken]) {
                require(
                    _sellAmount >= wallet.prices.mul(_pAmount),
                    "SELL_TOKEN_NOT_SUPPORT"
                );
            } else {
                require(
                    amount >= wallet.prices.mul(_pAmount),
                    "INSUFFICIENT_AMOUNT"
                );
            }
        } else {
            amount = wallet.prices.mul(_pAmount);
            require(_sellAmount >= amount, "INSUFFICIENT_AMOUNT");
        }

        IERC1155(onekeyToken).mint(msg.sender, _pID, _pAmount, "");

        emit WalletOrder(_pID, msg.sender, _pAmount, _referral, _sellToken, _sellAmount, amount);

        (uint256 finalReward,) = _deliverReward(_referral, _pID, _pAmount, amount);

        IRoundManager(roundContract).updateRoundTime(
            _pID,
            msg.sender,
            finalReward
        );

        TransferHelper.safeTransfer(
            targetAssest,
            vault,
            IERC20(targetAssest).balanceOf(address(this))
        );
    }

    function _fillQuote(
        address _sellToken,
        uint256 _sellAmount,
        address _spender,
        address payable _swapTarget,
        bytes calldata _swapCallData
    ) internal {
        if (_sellToken != ETH)
            TransferHelper.safeApprove(_sellToken, _spender, _sellAmount);

        (bool success, ) = _swapTarget.call{value: msg.value}(_swapCallData);

        require(success, "SWAP_CALL_FAILED");
    }

    function _deliverReward(
        address _referral,
        uint256 _pID,
        uint256 _pAmount,
        uint256 _amount
    ) internal returns (uint256 jackpotAmount, uint256 airdropAmount) {
        Wallet memory wallet = wallets[_pID];

        uint256 referralAmount;

        if (_referral != address(0) && _referral != msg.sender) {
            referralAmount = wallet.referral.mul(_amount).div(1000);
            TransferHelper.safeTransfer(
                targetAssest,
                _referral,
                referralAmount
            );
        }

        uint256 holderAmount = wallet.holder.mul(_amount).div(1000);
        TransferHelper.safeTransfer(targetAssest, holderContract, holderAmount);
        IHolderVault(holderContract).addOrder(
            msg.sender,
            wallet.airdropWeight.mul(_pAmount),
            holderAmount
        );

        airdropAmount = wallet.airdrop.mul(_amount).div(1000);
        TransferHelper.safeTransfer(
            targetAssest,
            airdropContract,
            airdropAmount
        );

        uint256 index = IAirdropVault(airdropContract).getCurrentIndex();

        uint256[2] memory luckyNumbers = [index, index.add(wallet.airdropWeight.mul(_pAmount)).sub(1)];

        IAirdropVault(airdropContract).enroll(
            msg.sender,
            luckyNumbers,
            airdropAmount
        );

        jackpotAmount = wallet.jackpot.mul(_amount).div(1000);
        TransferHelper.safeTransfer(targetAssest, roundContract, jackpotAmount);

        emit RewardDetail(
            _referral,
            referralAmount,
            holderAmount,
            airdropAmount,
            jackpotAmount
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;


library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IHolderVault {
    
    event Deposit(address indexed user, uint256 amount);

    function claim(address _user) external ;

    function addOrder(address _user, uint256 _amount, uint256 _reward) external ;

    function pendingReward(address _user) external view returns (uint256 amount) ;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IRoundManager  {

    event SetTimeInterval(uint256 _orderInterval, uint256 _roundInterval);

    event RoudTimeUpdate(uint256 indexed roud, uint256 beginAt, uint256 endAt);

    event RoundEnd(uint256 indexed round, address indexed winer, uint256 indexed amount);
    
    event JackpotClaimed(address indexed winer, uint256 indexed round, uint256 amount);
   
    function setTimeInterval(uint256 _orderInterval, uint256 _roundInterval) external;
    
    function updateRoundTime(uint256 _pID, address _buyer, uint256 _reward) external;
    
    function endRound() external;

    function claimJackpot(uint256 _rID) external;

    function getCurrendRound() external view returns (uint256);

    function getCurrentRoundReward() external view returns (uint256);

    function getRoundlastedOrder(uint256 _rID) external view returns (address buyer, uint256 blockNumber);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAirdropVault {

    event DiceRolled(bytes32 indexed requestId, uint256 indexed round);
    
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);

    function enroll(address _buyer, uint256[2] calldata _luckyNumber, uint256 _amount ) external;

    function rollup(uint256 _seed) external returns (bytes32 requestId);

    function withdrawLINK(address _to, uint256 _value) external ;

    function claimAirdrop(uint256 _round) external ;

    function getCurrentIndex() external view returns (uint256 index);

    function getCurrentRoundReward() external view returns (uint256 amount);

    function getLuckyNumbers(address _account) external view returns (uint256[2][] memory numbers);

    function getRoundLuckyNumbers(uint256 _round) external view returns (uint256 number);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

