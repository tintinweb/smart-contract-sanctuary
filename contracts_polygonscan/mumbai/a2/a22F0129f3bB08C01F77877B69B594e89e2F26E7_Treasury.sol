// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "../interfaces/IOffer.sol";
import "../interfaces/ITreasury.sol";
import "../utils/Ownable.sol";
import "../utils/Pausable.sol";
import "../interfaces/IERC20.sol";

contract Treasury is Ownable, Pausable {
    IOffer private _offersContract;
    IERC20 private _tradeTokensContract;
    mapping(address => bool) private _tokenWhitelist;
    mapping(address => bool) private _withdrawalwhitelist;
    mapping(address => uint256) private _stableAPY;
    uint256 private _tradeAPY;
    mapping(uint256 => Lend) private _lends;
    mapping(uint256 => LendFinished) private _lendsFinished;
    uint256 private _countLends;

    // contract with offers to work with
    function offersContract() public view returns (IOffer) {
        return _offersContract;
    }

    // sen new offers contract
    function setOffersContract(address _newOffersContract)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _newOffersContract != address(0),
            "Offer address cannot be zero"
        );
        emit OffersContractSet(address(_offersContract), _newOffersContract);
        _offersContract = IOffer(_newOffersContract);
        return true;
    }

    // contract with trade tokens to work with
    function tradeTokensContract() public view returns (IERC20) {
        return _tradeTokensContract;
    }

    // set new trade tokens contract
    function setTradeTokensContract(address _newTradeTokensContract)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _newTradeTokensContract != address(0),
            "Address cannot be zero"
        );
        _tradeTokensContract = IERC20(_newTradeTokensContract);
        return true;
    }


    // add new erc20 to known list to use later by token name
    function whitelistERC20(address _address) public onlyOwner returns (bool) {
        _tokenWhitelist[_address] = true;
        return true;
    }

    // transfer advance according to offer's information
    function transferAdvance(uint256 _offerId)
        public
        whenNotPaused
        onlyOwner
        returns (bool)
    {
        (
            address _tokenAddress,
            uint256 _amount,
            address _address
        ) = offersContract().getAmountsForTransfers(_offerId);
        require(_tokenWhitelist[_tokenAddress]);
        IERC20 token = IERC20(_tokenAddress);

        emit AdvanceForOffer(_offerId, _tokenAddress, _address, _amount);
        offersContract().changeStatusFromTreasury(_offerId, 4);
        return token.transfer(_address, _amount);
    }

    // transfer trade tokens according to offer's information
    function transferByFinishedOffer(uint256 _offerId)
        public
        whenNotPaused
        onlyOwner
        returns (bool)
    {
        (
            uint256 _amount,
            address _address
        ) = offersContract().getAmountsForFinish(_offerId);
        tradeTokensContract().transfer(_address, _amount);
        offersContract().changeStatusFromTreasury(_offerId, 7);
        return true;
    }

    // admin withdrawal to whitelisted addresses
    function adminTransfer(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public onlyOwner returns (bool) {
        require(_withdrawalwhitelist[recipient], "Not whitelisted");
        IERC20 token = IERC20(tokenAddress); // allow to withdrawal any tokens
        return token.transfer(recipient, amount);
    }

    // admin add address to whitelist for withdrawals
    function adminWithdrawalWhitelistAddressUpdate(
        address recipient,
        bool _status
    ) public onlyOwner returns (bool) {
        _withdrawalwhitelist[recipient] = _status;
        return true;
    }

    // any stable apy getter
    function stableAPY(address tokenAddress) public view returns (uint256) {
        return _stableAPY[tokenAddress];
    }

    // any stable apy setter
    function adminSetStableAPY(uint256 _apy, address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        _stableAPY[tokenAddress] = _apy;
        return true;
    }

    // trade apy getter
    function tradeAPY() public view returns (uint256) {
        return _tradeAPY;
    }

    // trade apy setter
    function adminSetTradeAPY(uint256 _apy) public onlyOwner returns (bool) {
        _tradeAPY = _apy;
        return true;
    }

    // new lend creation
    function newLend(Lend memory _lend) public whenNotPaused onlyOwner {
        _lend.status = 1;
        _lend.startStableAPY = stableAPY(_lend.tokenAddress);
        _lend.startTradeAPY = tradeAPY();
        _countLends = _countLends + 1;
        _lends[_countLends] = _lend;
        emit NewLend(_countLends, _lend);
    }

    // lend finish trigger function
    function endLend(uint256 _id, LendFinished memory _lend)
        public
        whenNotPaused
        onlyOwner
    {
        require(
            _lends[_id].status == 1 && _lend.finishedAt >= block.timestamp,
            "Wrong args"
        );

        uint256 earnedTotal = ((_lends[_id].lentAmountUsd *
            stableAPY(_lends[_id].tokenAddress) *
            (_lends[_id].tenure / 365)) / 100000) + _lends[_id].lentAmountUsd;
        _lends[_id].status = 2;
        _lend.earnedTotal = earnedTotal;
        _lend.endStableAPY = stableAPY(_lends[_id].tokenAddress);
        _lend.endTradeAPY = tradeAPY();
        // TODO: check calculation _lend.accuredTrade
        _lendsFinished[_id] = _lend;
        emit FinishedLend(_id, earnedTotal, _lend.accuredTrade);
    }

    // anyone can claim any lend rewards(not sure how much of which tokens have to send to lender)
    function claimLend(uint256 _id) public whenNotPaused {
        require(_lends[_id].status == 2, "Wrong state");
        _lends[_id].status = 3;
        IERC20 stable = IERC20(_lends[_id].tokenAddress);
        require(stable.transfer(_lends[_id].lenderAddress, _lendsFinished[_id].earnedTotal), 'token transfer error');
        require(tradeTokensContract().transfer(_lends[_id].lenderAddress, _lendsFinished[_id].accuredTrade), 'trade transfer error');
        emit LendClaimed(_id);
    }

    event NewLend(uint256 id, Lend lend);
    event FinishedLend(uint256 id, uint256 earnedUsd, uint256 accuredTrade);
    event LendClaimed(uint256 id);
    event OffersContractSet(
        address oldOffersContract,
        address newOffersContract
    );
    event AdvanceForOffer(
        uint256 id,
        address tokenAddress,
        address offerAddress,
        uint256 advancedAmount
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

struct OfferItem {
    uint256 amount;
    uint8 status;
    uint256 duration;
    uint8 grade;
    uint256 tenure;
    uint256 pricingId;
    address offerAddress;
    uint256 factoringFee;
    uint256 discount;
    uint256 advancePercentage;
    uint256 reservePercentage;
    uint256 gracePeriod;
    address tokenAddress;
}

struct OfferItemAdvanceAllocated {
    string polytradeInvoiceNo;
    uint256 clientCreateDate;
    uint256 actualAmount;
    uint256 disbursingAdvanceDate;
    uint256 advancedAmount;
    uint256 reserveHeldAmount;
    uint256 dueDate;
    uint256 amountDue;
    uint256 totalFee;
}

struct OfferItemPaymentReceived {
    uint256 paymentDate;
    string paymentRefNo;
    uint256 receivedAmount;
    string appliedToInvoiceRefNo;
    int256 unAppliedOrShortAmount;
}
struct OfferItemRefunded {
    string invoiceRefNo;
    uint256 invoiceAmount;
    uint256 amountReceived;
    uint256 paymentReceivedDate;
    uint256 numberOfLateDays;
    uint256 fee;
    uint256 lateFee;
    uint256 netAmount;
    uint256 dateClosed;
    uint256 toPayTradeTokens;
}

interface IOffer {
    function getAmountsForTransfers(uint256 _id)
        external
        returns (
            address _tokenAddress,
            uint256 _amount,
            address _address
        );

    function getAmountsForFinish(uint256 _id)
        external
        returns (
            uint256 _amount,
            address _address
        );

    function changeStatusFromTreasury(uint256 _id, uint8 status)
        external
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

struct Lend {
    uint256 status;
    uint256 lentAmount;
    uint256 lentAmountUsd;
    uint256 createDate;
    uint256 endDate;
    uint256 tenure;
    uint256 startStableAPY;
    uint256 startTradeAPY;
    address lenderAddress;
    address tokenAddress;
}

struct LendFinished {
    uint256 endStableAPY;
    uint256 finishedAt;
    uint256 endTradeAPY;
    uint256 accuredTrade;
    uint256 earnedTotal;
}

interface ITreasury {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import './Ownable.sol';

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}