// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./PMGPermission.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
  Poly payment contract
 */
contract DPolyPay is PMGPermission {
    struct STokenSupport {
        address _address; // erc token contract address register
        uint256 _type; // erc type, current all is erc20
    }

    //
    // Merchant received and withdrawn record
    //
    struct SMerchantRecord {
        uint256 total; // The merchant has earned in total currently
        uint256 freeze; // freeze
        uint256 withdrawn; // The merchant withdrew the earnings accumulatively
        uint256 feeRate; // The fee rate for the token symbol of the merchant
    }

    string private _platFormSymbol = "000"; // 000 is used for platform coin. ETH , MATIC

    mapping(string => mapping(string => SMerchantRecord)) private _merchantRecord;
    string[] private _merchantIndexes;

    mapping(string => STokenSupport) private _tokensSupport;
    string[] private _tokenSupprtIndexes;

    constructor() {
        //
        // default: add platform token
        //
        addTokenSupport(_platFormSymbol, address(0x0));
        addMerchant("000");
    }

    event EAddTokenSupport(string indexed symbol, address tokenAddr);

    event EApprovePay(
        string indexed merchant,
        string indexed orderId,
        string indexed symbol,
        uint256 moneyCount
    );
    event EDealPay(
        string indexed merchant,
        string indexed orderId,
        string indexed symbol,
        uint256 moneyCount
    );

    event EDealSettle(
        string indexed merchant,
        string indexed settleId,
        string indexed symbol,
        address to,
        uint256 moneyCount
    );
    
    event EPlatformSettleAccount( 
        string indexed settleId,
        string indexed symbol,
        address to,
        uint256 moneyCount
    );

    function _stringEQ(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encode(a)) == keccak256(abi.encode(b));
    }

    function _ifMerchantExists(string memory merchant)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _merchantIndexes.length; i++) {
            if (_stringEQ(_merchantIndexes[i], merchant)) {
                return true;
            }
        }
        return false;
    }

    function _ifSymbolExists(string memory symbol)
        internal
        view
        returns (bool)
    {
        if (_stringEQ(symbol, _platFormSymbol)) {
            return true;
        }

        for (uint256 i = 0; i < _tokenSupprtIndexes.length; i++) {
            if (_stringEQ(_tokenSupprtIndexes[i], symbol)) {
                return true;
            }
        }
        return false;
    }

    function adjustFee(string memory merchant, string memory symbol, uint256 feeRate) public OnlyOwner {
        _merchantRecord[merchant][symbol].feeRate = feeRate;
    }

    function addTokenSupport(string memory symbol, address tokenAddr)
        public
        OnlyOwner
    { 
        // require(_ifSymbolExists(symbol) == false, "Err-AddTokenSupport");
            
        _tokensSupport[symbol] = STokenSupport(tokenAddr, 0);
        if (!_ifSymbolExists(symbol)) {
            _tokenSupprtIndexes.push(symbol);
        }
        emit EAddTokenSupport(symbol, tokenAddr);
    }

    function tokenSupports() public view returns (string[] memory) {
        return _tokenSupprtIndexes;
    }

    function merchantSupports() public view returns (string[] memory) {
        return _merchantIndexes;
    }

    function addMerchant(string memory merchant) public OnlyOwner {
        require(_ifMerchantExists(merchant) == false, "Err-addMerchant");
        _merchantIndexes.push(merchant);
    }

    function dealPay(
        string memory merchant,
        string memory symbol,
        uint256 moneyCount,
        string memory orderId
    ) public payable {
        require(_ifMerchantExists(merchant), "Err-dealPay-Merchant");
        require(_ifSymbolExists(symbol), "Err-dealPay-Symbol");
        if (_stringEQ(symbol, _platFormSymbol)) {
            // do nothing, money now to contract
            require(moneyCount == 0, "Err-dealPay-NoNeedTokenValue");
            moneyCount = msg.value;
        } else {
            require(msg.value == 0, "Err-dealPay-NoNeedPlatformToken");
            require(
                IERC20(_tokensSupport[symbol]._address).transferFrom(
                    msg.sender,
                    address(this),
                    moneyCount
                ),
                "Err-dealPay-TransferFrom"
            );
        }
        _merchantRecord[merchant][symbol].total += moneyCount;
        emit EDealPay(merchant, orderId, symbol, moneyCount);
    }

    function balanceOf(string memory merchant, string memory symbol)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _merchantRecord[merchant][symbol].total,
            _merchantRecord[merchant][symbol].freeze,
            _merchantRecord[merchant][symbol].withdrawn,
            _merchantRecord[merchant][symbol].feeRate
        );
    }

    function balanceOfPlatForm() public view returns (uint256) {
        return address(this).balance;
    }

    // Transfer to the merchant account with all the earnings
    // The merchant has to be withdrawn all the earnings except for the service fees every time.
    function dealSettle(
        string memory merchant,
        string memory symbol,
        string memory settleId,
        address to
    ) public OnlyOwner {
        require(_ifMerchantExists(merchant), "Err-dealSettle-Merchant");
        require(_ifSymbolExists(symbol), "Err-dealSettle-Symbol");

        uint256 merchantTotalBalance = _merchantRecord[merchant][symbol].total;
        uint256 feeRate = _merchantRecord[merchant][symbol].feeRate;
        uint256 total = (merchantTotalBalance * (100 - feeRate)) / 100;
        require(total > 0, "Err-dealSettle-InsufficientBalance");

        if (_stringEQ(symbol, _platFormSymbol)) {
            payable(to).transfer(total);
        } else {
            require(
                IERC20(_tokensSupport[symbol]._address).transfer(to, total),
                "Err-dealSettle-Transfer"
            );
        }
        _merchantRecord[merchant][symbol].withdrawn += total;
        emit EDealSettle(merchant, settleId, symbol, to, total);
        _merchantRecord[merchant][symbol].total = 0; 
    }

    // Transfer to the platform account with all the service fee
    function platformSettleAccount( 
        string memory settleId,
        string memory symbol,
        address to
    ) public OnlyOwner {  
        require(_ifSymbolExists(symbol), "Err-platformSettleAccount-Symbol");

        uint256 bal = 0;
        if (_stringEQ(symbol, _platFormSymbol)) {
            uint256 total = address(this).balance;
            require(total > 0, "Err-platformSettleAccount-InsufficientCoinBalance");
            payable(to).transfer(total);
            bal = total;
        } else {
            uint256 total = IERC20(_tokensSupport[symbol]._address).balanceOf(address(this));
            require(total > 0, "Err-platformSettleAccount-InsufficientTokenBalance");
            require(
                IERC20(_tokensSupport[symbol]._address).transfer(to, total),
                "Err-platformSettleAccount-Transfer"
            );
            bal = total;
        }
        emit EPlatformSettleAccount(settleId, symbol, to, bal);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PMGPermission {
  address private _owner;
  event EChangeOwner(address from, address to);
  constructor() {
    _owner = msg.sender;
  }

  function changeOwner(address newOwner) public OnlyOwner {
    emit EChangeOwner(_owner, newOwner);
    _owner = newOwner;
  }

  function ownerOf() public view returns (address){
    return _owner;
  }

  modifier OnlyOwner() {
    require(msg.sender == _owner, "invalid permission");
    _;
  }
}

// SPDX-License-Identifier: MIT

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