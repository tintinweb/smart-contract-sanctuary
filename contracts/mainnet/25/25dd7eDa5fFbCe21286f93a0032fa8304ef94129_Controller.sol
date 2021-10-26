/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity 0.8.7;

//SPDX-License-Identifier: Unlicense

interface ISecureVault {
    function withdrawEthToAddress(uint256 _amount, address payable _addressToWithdraw) external;

    function withdrawTokensToAddress(
        address _token,
        uint256 _amount,
        address _addressToWithdraw
    ) external;
}

interface IExchange {
    function calculatePrice(address _token, uint256 _amount) external returns (uint256);

    function buy(
        address _token,
        uint256 _amount,
        address _addressToSendTokens
    ) external payable;

    function sell(
        address _token,
        uint256 _amount,
        address payable _addressToSendEther
    ) external returns (uint256);
}

interface IController {
    function buy(
        address _exchange,
        address _token,
        uint256 _amount
    ) external;

    function sell(
        address _exchange,
        address _token,
        uint256 _amount
    ) external;

    function transferEth(uint256 _amount, address payable _addressToWithdraw) external;

    function transferToken(
        address _token,
        uint256 _amount,
        address _addressToWithdraw
    ) external;

    function getBalance() external returns (int256);

    function clearBalance() external;

    function withdraw(uint256 _amount) external;
}

contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

contract Controller is IController, Initializable, Ownable {
    using SafeMath for uint256;
    event BuyToken(IExchange exchange, address token, uint256 amount, uint256 boughtPrice);
    event SellToken(IExchange exchange, address token, uint256 amount, uint256 soldPrice);

    address public flashBotCaller;
    ISecureVault public vault;
    int256 public balance;

    modifier onlyFlashBotCaller() {
        require(msg.sender == flashBotCaller, "Only the Flash Bot caller can execute this function");
        _;
    }

    function initialize(ISecureVault _vault, address _flashBotCaller) public initializer {
        vault = _vault;
        flashBotCaller = _flashBotCaller;
    }

    function buy(
        address _exchange,
        address _token,
        uint256 _amount
    ) external override onlyFlashBotCaller {
        uint256 priceOfTokens = IExchange(_exchange).calculatePrice(_token, _amount);
        balance = -int256(priceOfTokens);
        vault.withdrawEthToAddress(priceOfTokens, payable(address(this)));
        IExchange(_exchange).buy{value: priceOfTokens}(_token, _amount, address(vault));
        emit BuyToken(IExchange(_exchange), _token, _amount, priceOfTokens);
    }

    function sell(
        address _exchange,
        address _token,
        uint256 _amount
    ) external override onlyFlashBotCaller {
        vault.withdrawTokensToAddress(_token, _amount, _exchange);
        uint256 sellPrice = IExchange(_exchange).sell(_token, _amount, payable(address(vault)));
        balance += int256(sellPrice);
        emit SellToken(IExchange(_exchange), _token, _amount, sellPrice);
    }

    function transferEth(uint256 _amount, address payable _addressToWithdraw) external override onlyFlashBotCaller {
        vault.withdrawEthToAddress(_amount, _addressToWithdraw);
    }

    function transferToken(
        address _token,
        uint256 _amount,
        address _addressToWithdraw
    ) external override onlyFlashBotCaller {
        vault.withdrawTokensToAddress(_token, _amount, _addressToWithdraw);
    }

    function changeFlashBotCaller(address _flashBotCaller) external onlyOwner {
        flashBotCaller = _flashBotCaller;
    }

    function changeSecureVault(ISecureVault _vault) external onlyOwner {
        vault = _vault;
    }

    function withdraw(uint256 _amount) external override onlyFlashBotCaller {
        vault.withdrawEthToAddress(_amount, payable(flashBotCaller));
    }

    function getBalance() external view override onlyFlashBotCaller returns (int256) {
        return balance;
    }

    function clearBalance() external override onlyFlashBotCaller {
        _resetBalance();
    }

    function _resetBalance() private {
        balance = 0;
    }

    receive() external payable {}
    //transfer(uint256, address)
    //transfer(uint256, string, address)
    //withdraw(uint256)
}