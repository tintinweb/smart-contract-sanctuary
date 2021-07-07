/**
 *Submitted for verification at polygonscan.com on 2021-07-07
*/

pragma solidity ^0.5.0;


interface Structs {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 guaranteedAmount;
        uint256 flags;
        address referrer;
        bytes permit;
    }

    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

contract TradingBot is Structs {
    event StartBalance(uint256 balance);
    event EndBalance(uint256 balance);
    event fromBeforeBalance(uint256 balance);
    event toAfterBalance(uint256 balance);
    event toBeforeBalance(uint256 balance);
    event fromAfterBalance(uint256 balance);

    // Addresses
    address payable OWNER;

    // OneInch Config
    address ONE_INCH_ADDRESS = 0x11111112542D85B3EF69AE05771c2dCCff4fAa26;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == OWNER, "caller is not the owner!");
        _;
    }

    // Allow the contract to receive Ether
    function () external payable {}

    constructor() public payable {
        OWNER = msg.sender;
    }

    function arb(address _fromToken, address _toToken, uint256 _fromAmount, bytes memory _toCallData, bytes memory _fromCallData) onlyOwner payable public {
        _arb(_fromToken, _toToken, _fromAmount, _toCallData, _fromCallData);
    }

    function _arb(address _fromToken, address _toToken, uint256 _fromAmount, bytes memory _toCallData, bytes memory _fromCallData) internal {
        // Track original balance
        uint256 _startBalance = IERC20(_fromToken).balanceOf(address(this));
        emit StartBalance(_startBalance);

        // Perform the arb trade
        _trade(_fromToken, _toToken, _fromAmount, _toCallData, _fromCallData);

        // Track result balance
        uint256 _endBalance = IERC20(_fromToken).balanceOf(address(this));
        emit EndBalance(_endBalance);

        // Require that arbitrage is profitable
        require(_endBalance > _startBalance, "End balance must exceed start balance.");
    }

    function trade(address _fromToken, address _toToken, uint256 _fromAmount, bytes memory _toCallData, bytes memory _fromCallData) onlyOwner payable public {
        _trade(_fromToken, _toToken, _fromAmount, _toCallData, _fromCallData);
    }

    function _trade(address _fromToken, address _toToken, uint256 _fromAmount, bytes memory _toCallData, bytes memory _fromCallData) internal {
        // Track the balance of the token RECEIVED from the trade
        uint256 _beforeBalance = IERC20(_toToken).balanceOf(address(this));

        emit fromBeforeBalance(_beforeBalance);
        emit toBeforeBalance(IERC20(_fromToken).balanceOf(address(this)));
        // Swap on 1Inch: give _fromToken, receive _toToken
        _oneInchSwap(_fromToken, _toToken, _fromAmount, _toCallData);

        // Calculate the how much of the token we received
        uint256 _afterBalance = IERC20(_toToken).balanceOf(address(this));
        emit toAfterBalance(_afterBalance);
        emit fromAfterBalance(IERC20(_fromToken).balanceOf(address(this)));
        // Read _toToken balance after swap
        uint256 _toAmount = _afterBalance - _beforeBalance;

        // Swap on 1Inch: give _toToken, receive _fromToken
         _oneInchSwap(_toToken, _fromToken, _toAmount, _fromCallData);
    }

    function oneInchSwap(address _from, address _to, uint256 _amount, bytes memory _oneInchCallData) onlyOwner public payable {
        _oneInchSwap(_from, _to, _amount, _oneInchCallData);
    }

    //_oneInchCalldata is a tx data from /swap endpoint of 1inch api
    function _oneInchSwap(address _from, address _to, uint256 _amount, bytes memory _oneInchCallData) internal {
        // Setup contracts
        IERC20 _fromIERC20 = IERC20(_from);
        uint256 _beforeBalance = IERC20(_to).balanceOf(address(this));

        emit toBeforeBalance(_beforeBalance);
        emit fromBeforeBalance(IERC20(_from).balanceOf(address(this)));
        // Approve tokens
        _fromIERC20.approve(ONE_INCH_ADDRESS, _amount);

        // Swap tokens: give _from, get _to
        (bool success,) = ONE_INCH_ADDRESS.call.value(msg.value)(_oneInchCallData);
        require(success, '1INCH_SWAP_CALL_FAILED');

        uint256 _afterBalance = IERC20(_to).balanceOf(address(this));

        emit toAfterBalance(_afterBalance);
        emit fromAfterBalance(IERC20(_from).balanceOf(address(this)));
        // Reset approval
        _fromIERC20.approve(ONE_INCH_ADDRESS, 0);
    }

    // KEEP THIS FUNCTION IN CASE THE CONTRACT RECEIVES TOKENS!
    function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(OWNER, balance);
    }

    // KEEP THIS FUNCTION IN CASE THE CONTRACT KEEPS LEFTOVER ETHER!
    function withdrawEther() public onlyOwner {
        address self = address(this);
        // workaround for a possible solidity bug
        uint256 balance = self.balance;
        address(OWNER).transfer(balance);
    }
}