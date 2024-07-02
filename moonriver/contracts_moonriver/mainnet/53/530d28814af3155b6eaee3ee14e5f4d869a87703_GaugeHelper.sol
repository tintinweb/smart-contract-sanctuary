// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./SafeERC20.sol";

interface IHToken is IERC20 {
    function mint() external payable returns (uint); //CEther
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function underlying() external returns (address);
}

interface IBAMMv2 is IERC20 {
    function deposit(uint amount) external;
    function withdraw(uint numShares) external;
    function getCollateralValue() external view returns(uint);
    function collateralCount() external view returns(uint);
    function collaterals(uint index) external view returns(address);
    function fetchPrice(address collat) external view returns(uint);
}

interface IGauge is IERC20 {
    function deposit(uint _value, address to) external;
    function withdraw(uint _value) external;
}

interface IMinter {
    function mint(address gauge_addr) external;
    function mint_many(address[] memory gauge_addr) external;
    function mint_for(address gauge_addr, address _for) external;
    function toggle_approve_mint(address minting_user) external;
}

contract GaugeHelper is Ownable {
    using SafeERC20 for IERC20;    

    /// @notice Deposit the underlying token to the Hundred market, 
    ///         then deposit the hToken to the BAMM pool, 
    ///         then deposit the BAMM token to the gauge,
    ///         finally sending the gauge token to the destination address.
    /// @param underlying Underlying token to deposit, e.g. USDC.
    /// @param hToken Hundred market address, e.g. hUSDC
    /// @param bamm Bamm pool address, e.g. bhUSDC
    /// @param gauge Gauge address, e.g. bhUSDC-gauge
    /// @param underlyingAmount Underlying token shares to deposit.
    /// @param to The recipient of the gauge tokens.
    function depositUnderlyingToBammGauge(
        address underlying,
        address hToken,
        address bamm,
        address gauge, 
        uint underlyingAmount, 
        address to
    ) external {
        IERC20 Underlying = IERC20(underlying);
        Underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);
        Underlying.approve(hToken, underlyingAmount);
        IHToken HToken = IHToken(hToken);
        require(HToken.mint(underlyingAmount) == 0, ""); //0 is success
        uint hTokenBalance = HToken.balanceOf(address(this));
        HToken.approve(bamm, hTokenBalance);
        IBAMMv2 Bamm = IBAMMv2(bamm);
        Bamm.deposit(hTokenBalance);
        uint shares = Bamm.balanceOf(address(this));
        Bamm.approve(gauge, shares);
        IGauge Gauge = IGauge(gauge);
        Gauge.deposit(shares, to);
    }

    /// @notice Deposit the underlying token to the Hundred market, 
    ///         then deposit the hToken to the corresponding gauge, 
    ///         finally sending the gauge token to the destination address.
    /// @param underlying Underlying token to deposit, e.g. USDC.
    /// @param hToken Hundred market address, e.g. hUSDC
    /// @param gauge Gauge address, e.g. bhUSDC-gauge
    /// @param underlyingAmount Underlying token shares to deposit.
    /// @param to The recipient of the gauge tokens.
    function depositUnderlyingToGauge(
        address underlying,
        address hToken,
        address gauge, 
        uint underlyingAmount, 
        address to
    ) external {
        IERC20 Underlying = IERC20(underlying);
        Underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);
        Underlying.approve(hToken, underlyingAmount);
        IHToken HToken = IHToken(hToken);
        require(HToken.mint(underlyingAmount) == 0, ""); //0 is success
        uint hTokenBalance = HToken.balanceOf(address(this));
        HToken.approve(gauge, hTokenBalance);
        IGauge Gauge = IGauge(gauge);
        Gauge.deposit(hTokenBalance, to);
    }

    /// @notice Deposit the underlying token to the Hundred market, 
    ///         then deposit the hToken to the corresponding gauge, 
    ///         finally sending the gauge token to the destination address.
    /// @param hToken Hundred market address, e.g. hUSDC
    /// @param gauge Gauge address, e.g. bhUSDC-gauge
    /// @param to The recipient of the gauge tokens.
    function depositEtherToGauge(
        address hToken,
        address gauge, 
        address to
    ) external payable {
        IHToken HToken = IHToken(hToken);
        require(HToken.mint{value: msg.value}() == 0, ""); //0 is success
        uint hTokenBalance = HToken.balanceOf(address(this));
        HToken.approve(gauge, hTokenBalance);
        IGauge Gauge = IGauge(gauge);
        Gauge.deposit(hTokenBalance, to);
    }

    /// @notice Attempts to redeem an hToken to underlying and transfer the
    ///         underlying to the user. If the redeem fails, transfer the
    ///         hToken instead.
    function _tryRedeemAndTransfer(
        address hToken,
        address payable to,
        bool isCEther
    ) internal {
        IHToken HToken = IHToken(hToken);
        uint hTokenBalance = HToken.balanceOf(address(this));
        if (hTokenBalance == 0) return;
        uint result = HToken.redeem(hTokenBalance);
        if (result == 0) {
            if (isCEther) {
                to.transfer(address(this).balance);
            }
            else {
                IERC20 Underlying = IERC20(HToken.underlying());
                Underlying.safeTransfer(to, Underlying.balanceOf(address(this)));
            }
        }
        else { //Failed to redeem, send hTokens to user
            IERC20(HToken).safeTransfer(to, hTokenBalance);
        }
    }

    /// @notice Claims HND rewards for the msg.sender, transfers gauge tokens
    ///         from the sender to this contract and then withdraws the BAMM
    ///         lp tokens from the gauge, withdraws the hTokens from the BAMM
    ///         (both the BAMM's underlying token and any other liquidated hTokens),
    ///         then redeems the hTokens into underlying and transfers all to the
    ///         destination address. If there is not enough liquidity to redeem
    ///         any of the hTokens, transfers the hToken itself instead.
    /// @param minter Gauge's minter address, where HND rewards can be claimed
    /// @param gauge Gauge address, e.g. bhUSDC-gauge
    /// @param bamm Bamm pool address, e.g. bhUSDC
    /// @param hToken Hundred market address, e.g. hUSDC
    /// @param gaugeAmount Gauge tokens to withdraw.
    /// @param to The recipient of the underlying and/or hTokens.
    function withdrawFromBammGaugeToUnderlying(
        address minter,
        address gauge,
        address bamm,
        address hToken,
        uint gaugeAmount,
        address payable to,
        address hETH
    ) external {
        IMinter(minter).mint_for(gauge, msg.sender); //Requires toggle_approve_mint
        IGauge Gauge = IGauge(gauge);
        IERC20(Gauge).safeTransferFrom(msg.sender, address(this), gaugeAmount);
        Gauge.withdraw(gaugeAmount);
        IBAMMv2 Bamm = IBAMMv2(bamm);
        Bamm.withdraw(Bamm.balanceOf(address(this)));
        _tryRedeemAndTransfer(hToken, to, hToken == hETH);
        uint collateralCount = Bamm.collateralCount();
        for (uint i = 0; i < collateralCount; i++) {
            address collateral = Bamm.collaterals(i);
            _tryRedeemAndTransfer(collateral, to, collateral == hETH);
        }
    }

    /// @notice Claims HND rewards for the msg.sender, transfers gauge tokens
    ///         from the sender to this contract and then withdraws the 
    ///         hToken from the gauge, redeems the hTokens to underlying and
    ///         transfers to the destination address. If there is not enough 
    ///         liquidity to redeem the hToken, transfers the hToken itself instead.
    /// @param minter Gauge's minter address, where HND rewards can be claimed
    /// @param gauge Gauge address, e.g. bhUSDC-gauge
    /// @param hToken Hundred market address, e.g. hUSDC
    /// @param gaugeAmount Gauge tokens to withdraw.
    /// @param to The recipient of the underlying and/or hTokens.
    function withdrawFromGaugeToUnderlying(
        address minter,
        address gauge,
        address hToken,
        uint gaugeAmount,
        address payable to,
        bool isCEther
    ) external {
        IMinter(minter).mint_for(gauge, msg.sender); //Requires toggle_approve_mint
        IGauge Gauge = IGauge(gauge);
        IERC20(Gauge).safeTransferFrom(msg.sender, address(this), gaugeAmount);
        Gauge.withdraw(gaugeAmount);
        _tryRedeemAndTransfer(hToken, to, isCEther);
    }

    /// @notice Claims HND rewards for the msg.sender, transfers gauge tokens
    ///         from the sender to this contract and then withdraws the 
    ///         hToken from the source gauge, and deposits it to the 
    ///         destination gauge, on behalf of the `to` address.
    /// @param minter Gauge's minter address, where HND rewards can be claimed
    /// @param gaugeFrom Source gauge address, e.g. bhUSDC-gauge (old)
    /// @param gaugeTo Target gauge address, e.g. bhUSDC-gauge (new)
    /// @param hToken Hundred market address, e.g. hUSDC
    /// @param gaugeAmount Gauge tokens to migrate.
    /// @param to The recipient of the destination gaugeToken.
    function migrateGauge(
        address minter,
        address gaugeFrom,
        address hToken,
        address gaugeTo,
        uint gaugeAmount,
        address to
    ) external {
        IMinter(minter).mint_for(gaugeFrom, msg.sender); //Requires toggle_approve_mint
        IGauge GaugeFrom = IGauge(gaugeFrom);
        IERC20(GaugeFrom).safeTransferFrom(msg.sender, address(this), gaugeAmount);
        GaugeFrom.withdraw(gaugeAmount);
        IERC20 HToken = IERC20(hToken);
        uint hTokenBalance = HToken.balanceOf(address(this));
        HToken.approve(gaugeTo, hTokenBalance);
        IGauge GaugeTo = IGauge(gaugeTo);
        GaugeTo.deposit(hTokenBalance, to);
    }

    receive() external payable {}

    fallback() external payable {}

    function rescueErc20(address token) external {
        IERC20(token).safeTransfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    function rescueETH() external {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

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

pragma solidity 0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint shares) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint shares) external returns (bool);
    function transferFrom(address sender, address recipient, uint shares) external returns (bool);
    function permit(address target, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferWithPermit(address target, address to, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}