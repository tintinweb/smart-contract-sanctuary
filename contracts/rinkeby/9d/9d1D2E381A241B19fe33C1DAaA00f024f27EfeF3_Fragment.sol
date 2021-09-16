/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// File: contracts/lib/SafeMath.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;



/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/intf/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
}

// File: contracts/lib/SafeERC20.sol


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
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

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/lib/DecimalMath.sol



/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant ONE2 = 10**36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(10**18);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).divCeil(d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).div(target);
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).divCeil(target);
    }

    function powFloor(uint256 target, uint256 e) internal pure returns (uint256) {
        if (e == 0) {
            return 1;
        } else if (e == 1) {
            return target;
        } else {
            uint p = powFloor(target, e.div(2));
            p = p.mul(p) / (10**18);
            if (e % 2 == 1) {
                p = p.mul(target) / (10**18);
            }
            return p;
        }
    }
}

// File: contracts/DODOVendingMachine/intf/IDVM.sol


interface IDVM {
    function init(
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external;

    function _BASE_TOKEN_() external returns (address);

    function _QUOTE_TOKEN_() external returns (address);

    function _MT_FEE_RATE_MODEL_() external returns (address);

    function getVaultReserve() external returns (uint256 baseReserve, uint256 quoteReserve);

    function sellBase(address to) external returns (uint256);

    function sellQuote(address to) external returns (uint256);

    function buyShares(address to) external returns (uint256,uint256,uint256);

    function addressToShortString(address _addr) external pure returns (string memory);

    function getMidPrice() external view returns (uint256 midPrice);

    function sellShares(
        uint256 shareAmount,
        address to,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        bytes calldata data,
        uint256 deadline
    ) external  returns (uint256 baseAmount, uint256 quoteAmount);

}

// File: contracts/intf/IDODOCallee.sol

interface IDODOCallee {
    function DVMSellShareCall(
        address sender,
        uint256 burnShareAmount,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;

    function DVMFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;

    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;

    function DSPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;

    function CPCancelCall(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external;

	function CPClaimBidCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;

    function NFTRedeemCall(
        address payable assetTo,
        uint256 quoteAmount,
        bytes calldata
    ) external;
}

// File: contracts/external/ERC20/InitializableFragERC20.sol



contract InitializableFragERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint256 public totalSupply;

    bool public initialized;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function init(
        address _creator,
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol
    ) public {
        require(!initialized, "TOKEN_INITIALIZED");
        initialized = true;
        totalSupply = _totalSupply;
        balances[_creator] = _totalSupply;
        name = _name;
        symbol = _symbol;
        emit Transfer(address(0), _creator, _totalSupply);
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "FROM_ADDRESS_IS_EMPTY");
        require(recipient != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[sender], "BALANCE_NOT_ENOUGH");

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

}

// File: contracts/CollateralVault/intf/ICollateralVault.sol



interface ICollateralVault {
    function _OWNER_() external returns (address);

    function init(address owner, string memory name, string memory baseURI) external;

    function directTransferOwnership(address newOwner) external;
}

// File: contracts/GeneralizedFragment/impl/Fragment.sol


interface IBuyoutModel {
  function getBuyoutStatus(address fragAddr, address user) external view returns (int);
}

contract Fragment is InitializableFragERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Storage ============
    
    bool public _IS_BUYOUT_;
    uint256 public _BUYOUT_TIMESTAMP_;
    uint256 public _BUYOUT_PRICE_;
    uint256 public _DISTRIBUTION_RATIO_;

    address public _COLLATERAL_VAULT_;
    address public _VAULT_PRE_OWNER_;
    address public _QUOTE_;
    address public _DVM_;
    address public _DEFAULT_MAINTAINER_;
    address public _BUYOUT_MODEL_;

    bool internal _FRAG_INITIALIZED_;

    // ============ Event ============
    event RemoveNftToken(address nftContract, uint256 tokenId, uint256 amount);
    event AddNftToken(address nftContract, uint256 tokenId, uint256 amount);
    event InitInfo(address vault, string name, string baseURI);
    event CreateFragment();
    event Buyout(address newOwner);
    event Redeem(address sender, uint256 baseAmount, uint256 quoteAmount);


    function init(
      address dvm, 
      address vaultPreOwner,
      address collateralVault,
      uint256 _totalSupply, 
      uint256 ownerRatio,
      uint256 buyoutTimestamp,
      address defaultMaintainer,
      address buyoutModel,
      uint256 distributionRatio,
      string memory _symbol
    ) external {
        require(!_FRAG_INITIALIZED_, "DODOFragment: ALREADY_INITIALIZED");
        _FRAG_INITIALIZED_ = true;

        // init local variables
        _DVM_ = dvm;
        _QUOTE_ = IDVM(_DVM_)._QUOTE_TOKEN_();
        _VAULT_PRE_OWNER_ = vaultPreOwner;
        _COLLATERAL_VAULT_ = collateralVault;
        _BUYOUT_TIMESTAMP_ = buyoutTimestamp;
        _DEFAULT_MAINTAINER_ = defaultMaintainer;
        _BUYOUT_MODEL_ = buyoutModel;
        _DISTRIBUTION_RATIO_ = distributionRatio;

        // init FRAG meta data
        name = string(abi.encodePacked("DODO_FRAG_", _symbol));
        symbol = string(abi.encodePacked("d_", _symbol));
        super.init(address(this), _totalSupply, name, symbol);

        // init FRAG distribution
        uint256 vaultPreOwnerBalance = DecimalMath.mulFloor(_totalSupply, ownerRatio);
        uint256 distributionBalance = DecimalMath.mulFloor(vaultPreOwnerBalance, distributionRatio);
        
        if(distributionBalance > 0) _transfer(address(this), _DEFAULT_MAINTAINER_, distributionBalance);
        _transfer(address(this), _VAULT_PRE_OWNER_, vaultPreOwnerBalance.sub(distributionBalance));
        _transfer(address(this), _DVM_, _totalSupply.sub(vaultPreOwnerBalance));

        // init DVM liquidity
        IDVM(_DVM_).buyShares(address(this));
    }


    function buyout(address newVaultOwner) external {
        require(_BUYOUT_TIMESTAMP_ != 0, "DODOFragment: NOT_SUPPORT_BUYOUT");
        require(block.timestamp > _BUYOUT_TIMESTAMP_, "DODOFragment: BUYOUT_NOT_START");
        require(!_IS_BUYOUT_, "DODOFragment: ALREADY_BUYOUT");

        int buyoutFee = IBuyoutModel(_BUYOUT_MODEL_).getBuyoutStatus(address(this), newVaultOwner);
        require(buyoutFee != -1, "DODOFragment: USER_UNABLE_BUYOUT");

        _IS_BUYOUT_ = true;
      
        _BUYOUT_PRICE_ = IDVM(_DVM_).getMidPrice();
        uint256 requireQuote = DecimalMath.mulCeil(_BUYOUT_PRICE_, totalSupply);
        uint256 payQuote = IERC20(_QUOTE_).balanceOf(address(this));
        require(payQuote >= requireQuote, "DODOFragment: QUOTE_NOT_ENOUGH");

        IDVM(_DVM_).sellShares(
          IERC20(_DVM_).balanceOf(address(this)),
          address(this),
          0,
          0,
          "",
          uint256(-1)
        ); 

        uint256 redeemFrag = totalSupply.sub(balances[address(this)]).sub(balances[_VAULT_PRE_OWNER_]);
        uint256 ownerQuoteWithoutFee = IERC20(_QUOTE_).balanceOf(address(this)).sub(DecimalMath.mulCeil(_BUYOUT_PRICE_, redeemFrag));
        _clearBalance(address(this));
        _clearBalance(_VAULT_PRE_OWNER_);

        uint256 buyoutFeeAmount =  DecimalMath.mulFloor(ownerQuoteWithoutFee, uint256(buyoutFee));
      
        IERC20(_QUOTE_).safeTransfer(_DEFAULT_MAINTAINER_, buyoutFeeAmount);
        IERC20(_QUOTE_).safeTransfer(_VAULT_PRE_OWNER_, ownerQuoteWithoutFee.sub(buyoutFeeAmount));

        ICollateralVault(_COLLATERAL_VAULT_).directTransferOwnership(newVaultOwner);

        emit Buyout(newVaultOwner);
    }


    function redeem(address to, bytes calldata data) external {
        require(_IS_BUYOUT_, "DODOFragment: NEED_BUYOUT");

        uint256 baseAmount = balances[msg.sender];
        uint256 quoteAmount = DecimalMath.mulFloor(_BUYOUT_PRICE_, baseAmount);
        _clearBalance(msg.sender);
        IERC20(_QUOTE_).safeTransfer(to, quoteAmount);

        if (data.length > 0) {
          IDODOCallee(to).NFTRedeemCall(
            msg.sender,
            quoteAmount,
            data
          );
        }

        emit Redeem(msg.sender, baseAmount, quoteAmount);
    }

    function getBuyoutRequirement() external view returns (uint256 requireQuote){
        require(_BUYOUT_TIMESTAMP_ != 0, "NOT SUPPORT BUYOUT");
        require(!_IS_BUYOUT_, "ALREADY BUYOUT");
        uint256 price = IDVM(_DVM_).getMidPrice();
        requireQuote = DecimalMath.mulCeil(price, totalSupply);
    }

    function _clearBalance(address account) internal {
        uint256 clearBalance = balances[account];
        balances[account] = 0;
        balances[address(0)] = balances[address(0)].add(clearBalance);
        emit Transfer(account, address(0), clearBalance);
    }
}