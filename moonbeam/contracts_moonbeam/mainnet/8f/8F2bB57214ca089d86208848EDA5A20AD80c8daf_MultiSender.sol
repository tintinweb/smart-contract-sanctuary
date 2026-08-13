//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "./Storage.sol";
import "./IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct ProductItem {
    bytes32 i18nId;
    bytes32 appId;
    uint256 price;
    uint128 payType;
    uint128 off;
    uint256 duration;
    uint256 createdAt;
    address createdBy;
    address updatedBy;
}

struct VIPStats {
    uint256 startedAt;
    uint256 expiredAt;
}

interface IFinance {
    function queryProduct(bytes32 id) external returns (ProductItem memory);

    function checkout(
        bytes32 orderid,
        address payer,
        bytes32 skuId,
        address inviter
    ) external payable;
}

interface IVIP {
    function queryVIP(bytes32 appId, address target)
        external
        view
        returns (VIPStats memory vipStats);
}

contract MultiSender is Ownable {
    event MultisendTokenOK(address indexed _from, address indexed token);
    event WithdrawSuccessed(address indexed _from);
    event WithdrawERC20Successed(address indexed _from, address indexed token);

    address public checkoutContract;
    address public vipContract;

    function setCheckoutContract(address _checkout) public onlyOwner {
        checkoutContract = _checkout;
    }

    function setVipContract(address _vip) public onlyOwner {
        vipContract = _vip;
    }

    constructor(address _checkout, address _vip) {
        checkoutContract = _checkout;
        vipContract = _vip;
    }

    function multisendToken(
        address token,
        address[] memory _contributors,
        uint256[] memory _balances,
        address inviter,
        bytes32 orderid,
        bytes32 appId
    ) public payable {
        //solhint-disable reason-string
        require(
            _contributors.length <= 100,
            "MultiSenderV1: _contributors length must be less than or equal to 100"
        );
        //solhint-disable reason-string
        require(
            _contributors.length == _balances.length,
            "MultiSenderV1: _contributors length and _balances length must be the same"
        );

        uint256 total = 0;
        for (uint256 i = 0; i < _balances.length; i++) {
            total = total + _balances[i];
        }
        uint256 minMainCoin = total;

        if (address(0) != token) {
            minMainCoin = 0;
        }
        IVIP vip = IVIP(vipContract);

        VIPStats memory vipInfo = vip.queryVIP(appId, msg.sender);
        // solhint-disable not-rely-on-time
        if (vipInfo.expiredAt < block.timestamp) {
            // Non-VIP need to pay
            IFinance finance = IFinance(checkoutContract);
            bytes32 skuId = querySkuId(_contributors.length);

            require(
                msg.value > minMainCoin,
                "MultiSenderV1: msg.value should greater than the amount of tokens"
            );

            // Main Coin multisend: Pay the software fee, msg.value minus the number of tokens to be sent
            // ERC20 token multisend: Pay the software fee
            // uint256 v = uint256(msg.value) - minMainCoin;
            uint256 v = msg.value - minMainCoin;

            finance.checkout{value: v * 1 wei}(
                orderid,
                msg.sender,
                skuId,
                inviter
            );
        } else {
            //   VIP send for free
            if (address(0) == token) {
                require(
                    msg.value == total,
                    "MultiSenderV1: msg.value should be equal to the amount of tokens you want to send without paying software fees"
                );
            } else {
                require(msg.value == 0, "MultiSenderV1: msg.value should be 0");
            }
        }

        if (address(0) == token) {
            //solhint-disable reason-string
            require(
                msg.value >= total,
                "MultiSenderV1: insufficient MainCoin balance"
            );
            // Main Coin multisend
            executeNativeTokenTransfer(_contributors, _balances);
        } else {
            IERC20 eRC20Token = IERC20(token);
            require(
                eRC20Token.balanceOf(msg.sender) >= total,
                "MultiSenderV1: insufficient ERC20Coin balance"
            );
            //solhint-disable reason-string
            require(
                eRC20Token.allowance(msg.sender, address(this)) >= total,
                "MultiSenderV1: insufficient allowance"
            );
            // ERC20 token multisend
            executeERC20Transfer(eRC20Token, _contributors, _balances);
        }

        //  event MultisendTokenOK
        emit MultisendTokenOK(msg.sender, token);
    }

    function executeNativeTokenTransfer(
        address[] memory receivers,
        uint256[] memory _balances
    ) internal {
        for (uint256 i = 0; i < receivers.length; i++) {
            address payable recipient = payable(address(receivers[i]));
            // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
            (bool success, ) = recipient.call{value: _balances[i]}(
                "0x506f7765726564206279206269756269752e746f6f6c73000000000000000000"
            );
            require(
                success,
                "Address: unable to send value, recipient may have reverted"
            );
        }
    }

    function executeERC20Transfer(
        IERC20 eRC20Token,
        address[] memory receivers,
        uint256[] memory _balances
    ) internal {
        for (uint256 i = 0; i < receivers.length; i++) {
            eRC20Token.transferFrom(msg.sender, receivers[i], _balances[i]);
        }
    }

    function querySkuId(uint256 len) public pure returns (bytes32 skuId) {
        if (len <= 20) {
            return
                0x6d756c746973656e6465722d6e6f746f76657232302d7070702d306400000000;
        } else {
            return
                0x6d756c746973656e6465722d6f76657232302d7070702d306400000000000000;
        }
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Finance: insufficient balance");
        address payable recipient = payable(address(owner()));
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );

        emit WithdrawSuccessed(address(owner()));
    }

    function withdrawERC20(address token) public onlyOwner {
        IERC20 erc20Token = IERC20(token);
        require(
            erc20Token.balanceOf(address(this)) > 0,
            "Address: insufficient balance"
        );
        erc20Token.transfer(
            address(owner()),
            erc20Token.balanceOf(address(this))
        );
        emit WithdrawERC20Successed(address(owner()), token);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Storage {
    struct VIPStats {
        uint256 startedAt;
        uint256 expiredAt;
    }
    mapping(address => VIPStats) internal vipMap;
    address public checkoutContract;
    address[] internal vips;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}