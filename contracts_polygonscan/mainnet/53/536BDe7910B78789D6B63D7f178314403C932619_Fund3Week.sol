/**
 *Submitted for verification at polygonscan.com on 2021-10-25
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File contracts/fund.sol

pragma solidity 0.8.7;
//SPDX-License-Identifier: UNLICENSED

contract Fund3Week {
    address owner = msg.sender;

    // Tokens used to deposit
    address[] public usdTokens;

    uint256 public dateToReleaseFunds;
    uint256 public dateToTransferFundsToNextContract;
    uint256 ownerFullControlTime;

    address public nextContract;

    mapping(address => mapping(address => uint256)) public userDeposits;


    modifier onlyActive() {
        require(dateToReleaseFunds > 0, "!active");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "!owner");
        _;
    }

    modifier timeUnlocked() {
        require(block.timestamp > dateToReleaseFunds, "!time");
        _;
    }

    modifier onlyHuman() {
        require(msg.sender == tx.origin, "!human");
        _;
    }

    constructor(address[] memory _usdTokens) {
        usdTokens = _usdTokens;
    }

    function activate() public onlyOwner {
        require(dateToReleaseFunds == 0, "!only once");
        dateToReleaseFunds = block.timestamp + 21 days;
        dateToTransferFundsToNextContract = dateToReleaseFunds + 2 days;
        ownerFullControlTime = dateToTransferFundsToNextContract + 14 days;
    }

    /***
    Deposit funds to contract.
    ***/
    function deposit(uint256 _amount) onlyActive onlyHuman public {
        require(block.timestamp < dateToReleaseFunds, "!too late");
        receivePayment(msg.sender, _amount);
    }

    /***
    Withdraw funds. If @devs didn't suggest implementation of new contract users withdraw 100% thier funds
    In other case 5% fee penalty
    ***/
    function withdraw() onlyActive onlyHuman timeUnlocked public {
        uint256 fee = 0;
        if (nextContract != address(0)) fee = 5; // 5%

        uint256 _len = usdTokens.length;
        for(uint256 i = 0; i < _len;i++) {
            uint256 _amount = userDeposits[msg.sender][usdTokens[i]];
            if (_amount > 0) {
                uint256 _amountFee = _amount * fee / 100;
                if (_amountFee > 0) {
                    IERC20(usdTokens[i]).transfer(owner, _amountFee);
                    _amount -= _amountFee;
                }

                userDeposits[msg.sender][usdTokens[i]] = 0;
                IERC20(usdTokens[i]).transfer(msg.sender, _amount);
            }
        }
    }

    /***
    Set implementation of new contract
    ***/
    function setNextContract(address _newContract) public onlyOwner {
        require(block.timestamp < dateToReleaseFunds, "!too late");
        nextContract = _newContract;
    }

    /***
    Transfer(migrate) funds to new contract. User have a time until @dateToTransferFundsToNextContract to validate new contract
    ***/
    function transferFunds() public timeUnlocked onlyOwner {
        address _nextContract = nextContract;
        require(_nextContract != address(0), "!contract");
        require(block.timestamp > dateToTransferFundsToNextContract, "!time");

        uint256 _len = usdTokens.length;

        for(uint256 i = 0;i < _len;i++) {
            IERC20 _token = IERC20(usdTokens[i]);
            _token.transfer(_nextContract, _token.balanceOf(address(this)));
        }
    }

    /***
    Accept payment in any allowed token
    ***/
    function receivePayment(address _userAddress, uint256 _amount) internal {
        uint256 _len = usdTokens.length;
        for(uint256 i = 0; i < _len;i++) {
            IERC20 activeCurrency = IERC20(usdTokens[i]);
            uint256 decimals = IERC20Metadata(usdTokens[i]).decimals();
            uint256 _amountInActiveCurrency = _amount * (10 ** decimals) / 1e18;
            if (activeCurrency.allowance(_userAddress, address(this)) >= _amountInActiveCurrency && activeCurrency.balanceOf(_userAddress) >= _amountInActiveCurrency) {
                activeCurrency.transferFrom(_userAddress, address(this), _amountInActiveCurrency);
                userDeposits[_userAddress][usdTokens[i]] += _amountInActiveCurrency;
                // SUCCESS
                return;
            }
        }
        revert("!payment failed");
    }

    /***
    In case something goes wrong, for example user sent wrong token to contract or sent from an exchange...
    ***/
    function externalCallEth(address payable[] memory  _to, bytes[] memory _data, uint256[] memory ethAmount) public onlyOwner payable {
        require(block.timestamp > ownerFullControlTime, "!time");

        for(uint16 i = 0; i < _to.length; i++) {
            _cast(_to[i], _data[i], ethAmount[i]);
        }
    }

    function _cast(address payable _to, bytes memory _data, uint256 _value) internal {
        bool success;
        bytes memory returndata;
        (success, returndata) = _to.call{value:_value}(_data);
        require(success, string (returndata));
    }
}