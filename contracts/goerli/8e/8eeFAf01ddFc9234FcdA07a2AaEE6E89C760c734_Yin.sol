// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
//import "pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol";
//import "@BakeryProject/bakery-swap-periphery/contracts/interfaces/IBakerySwapRouter.sol";
//import "@BakeryProject/bakery-swap-core/contracts/interfaces/IBakerySwapFactory.sol";

contract ERC20Fee is Context, IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;

  constructor(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;

    router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    factory = IUniswapV2Factory(router.factory());
    lpPair = IUniswapV2Pair(factory.createPair(address(this), router.WETH()));

    _mint(address(this), 100000000000000000000000000000000);
    _approve(address(this), address(router), _totalSupply);
  }

  function name() public view virtual returns (string memory) {
    return _name;
  }
  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }
  function decimals() public view virtual returns (uint8) {
    return 18;
  }
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    _approve(sender, _msgSender(), currentAllowance - amount);

    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));

    return true;
  }
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    _balances[account] = accountBalance.sub(amount);
    _totalSupply = _totalSupply.sub(amount);

    emit Transfer(account, address(0), amount);
  }
  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

  //----------------------------------------------------------------------------------------------------

  uint256 private feePercentage = 100;
  uint256 private lpHolderAmount = 1;
  uint256 private lpHolderFee = 5000;
  uint256 private burnPercentage = 5000;
  address public burnAddress = address(0x000000000000000000000000000000000000dEaD);
  address public oppositeAddress = address(0);
  address[] public buybackPath;
  uint256 public proposalVotingDuration = 86400;
  uint256 public minSelfVoteAmount = 10000000000000000000;

  IUniswapV2Router02 private router;
  IUniswapV2Factory private factory;
  IUniswapV2Pair private lpPair;

  mapping (address => bool) private _isExcluded;

  event Buyback(uint256 inputAmount, uint256 outputAmount);
  event BuybackFailed(uint256 inputAmount, string msg);
  event Burn(uint256 amount);
  event OppositeAddressChanged(address _address);
  event FeePercentageChanged(uint256 newPercentage);
  event LPHolderAmountChanged(uint256 newPercentage);
  event LPHolderFeeChanged(uint256 newPercentage);
  event ProposalVotingDurationChanged(uint256 newDuration);
  event BurnPercentageChanged(uint256 newPercentage);
  event MinSelfVoteAmountChanged(uint256 newAmount);
  event ProposalAdded(uint256 index);

  struct Proposal {
    uint256 index;
    address proposer;
    uint256 selfVotes;
    uint256 timestamp;
    ProposalType _type;
    uint256 value;
    uint256 proVotes;
    uint256 conVotes;
  }

  enum ProposalType {
    FeePercentage,
    LPFeePercentage,
    LPAmount,
    BurnPercentage
  }

  Proposal[] public proposals;

  function makeProposal(ProposalType _type, uint256 value, uint256 votes) public {
    require(votes >= minSelfVoteAmount, "makeProposal: self voting amount must be >=minSelfVoteAmount");
    require(_balances[_msgSender()] >= votes, "makeProposal: transfer amount exceeds balance");

    if (proposals.length > 0) {
      for (uint256 i = proposals.length; i >= 1; i--) {
        if (proposals[i-1]._type == _type) {
          require(proposals[i-1].timestamp.add(proposalVotingDuration) < block.timestamp, "makeProposal: proposal with same type is already running");
        }
      }
    }

    if (_type == ProposalType.FeePercentage) {
      require(value < 10000, "makeProposal: feePercentage can't be >=100%");
    }
    if (_type == ProposalType.LPFeePercentage) {
      require(value < 10000, "makeProposal: lpHolderFee can't be >=100%");
    }
    if (_type == ProposalType.LPAmount) {
      require(value > 0, "makeProposal: lpHolderAmount can't be 0");
    }
    if (_type == ProposalType.BurnPercentage) {
      require(value <= 10000, "makeProposal: burnPercentage can't be >100%");
    }

    proposals.push(Proposal({
      index: proposals.length,
      proposer: _msgSender(),
      selfVotes: votes,
      timestamp: block.timestamp,
      _type: _type,
      value: value,
      proVotes: votes,
      conVotes: 0
    }));
    _transferExcluded(_msgSender(), address(burnAddress), votes);
    emit ProposalAdded(proposals.length.sub(1));
  }

  function closeProposal(uint256 index) public onlyOwner {
    require(proposals.length > index, "closeProposal: proposal doesn't exist");
    proposals[index].timestamp = 0;
    proposals[index].proVotes = 0;
    proposals[index].conVotes = 1;
  }

  function voteProposal(uint256 index, uint256 amount, bool pro) public {
    require(proposals.length > index, "voteProposal: proposal doesn't exist");
    require(_balances[_msgSender()] >= amount, "voteProposal: transfer amount exceeds balance");
    require(proposals[index].timestamp.add(proposalVotingDuration) >= block.timestamp, "voteProposal: voting phase has ended");
    if (pro) {
      proposals[index].proVotes = proposals[index].proVotes.add(amount);
    } else {
      proposals[index].conVotes = proposals[index].conVotes.add(amount);
    }
    _transferExcluded(_msgSender(), address(burnAddress), amount);
  }

  function getProposalStatus(uint256 index) public view returns (bool) {
    require(proposals.length > index, "voteProposal: proposal doesn't exist");
    return proposals[index].timestamp.add(proposalVotingDuration) >= block.timestamp;
  }

  function proposalProposerVotes(uint256 index) public view returns (uint256) {
    require(proposals.length > index, "voteProposal: proposal doesn't exist");
    return proposals[index].selfVotes;
  }

  function getFeePercentage() public view returns (uint256) {
    if (proposals.length == 0) {
      return feePercentage;
    }

    for (uint256 i = proposals.length; i >= 1; i--) {
      if (proposals[i-1]._type == ProposalType.FeePercentage &&
          proposals[i-1].timestamp.add(proposalVotingDuration) < block.timestamp &&
            proposals[i-1].proVotes > proposals[i-1].conVotes) {
        return proposals[i-1].value;
      }
    }

    return feePercentage;
  }

  function getLPHolderFee() public view returns (uint256) {
    if (proposals.length == 0) {
      return lpHolderFee;
    }

    for (uint256 i = proposals.length; i >= 1; i--) {
      if (proposals[i-1]._type == ProposalType.LPFeePercentage &&
          proposals[i-1].timestamp.add(proposalVotingDuration) < block.timestamp &&
            proposals[i-1].proVotes > proposals[i-1].conVotes) {
        return proposals[i-1].value;
      }
    }

    return lpHolderFee;
  }

  function getLPHolderAmount() public view returns (uint256) {
    if (proposals.length == 0) {
      return lpHolderAmount;
    }

    for (uint256 i = proposals.length; i >= 1; i--) {
      if (proposals[i-1]._type == ProposalType.LPAmount &&
          proposals[i-1].timestamp.add(proposalVotingDuration) < block.timestamp &&
            proposals[i-1].proVotes > proposals[i-1].conVotes) {
        return proposals[i-1].value;
      }
    }

    return lpHolderAmount;
  }

  function getBurnPercentage() public view returns (uint256) {
    if (proposals.length == 0) {
      return burnPercentage;
    }

    for (uint256 i = proposals.length; i >= 1; i--) {
      if (proposals[i-1]._type == ProposalType.BurnPercentage &&
          proposals[i-1].timestamp.add(proposalVotingDuration) < block.timestamp &&
            proposals[i-1].proVotes > proposals[i-1].conVotes) {
        return proposals[i-1].value;
      }
    }

    return burnPercentage;
  }

  /**
  * @dev Sets the value for {minSelfVoteAmount}
  */
  function setMinSelfVoteAmount(uint256 _minSelfVoteAmount) public onlyOwner {
    require(msg.sender == owner(), "setMinSelfVoteAmount: FORBIDDEN");
    require(_minSelfVoteAmount > 0, "setMinSelfVoteAmount: minSelfVoteAmount can't be 0");
    minSelfVoteAmount = _minSelfVoteAmount;
    emit MinSelfVoteAmountChanged(minSelfVoteAmount);
  }

  /**
  * @dev Sets the value for {proposalVotingDuration}
  */
  function setProposalVotingDuration(uint256 _proposalVotingDuration) public onlyOwner {
    require(msg.sender == owner(), "setProposalVotingDuration: FORBIDDEN");
    require(_proposalVotingDuration > 0, "setProposalVotingDuration: proposalVotingDuration can't be 0");
    proposalVotingDuration = _proposalVotingDuration;
    emit ProposalVotingDurationChanged(proposalVotingDuration);
  }

  /**
  * @dev Sets the value for {lpHolderAmount}
  */
  function setLPHolderAmount(uint256 _lpHolderAmount) public onlyOwner {
    require(msg.sender == owner(), "setLPHolderAmount: FORBIDDEN");
    require(_lpHolderAmount > 0, "setLPHolderAmount: lpHolderAmount can't be 0");
    lpHolderAmount = _lpHolderAmount;
    emit LPHolderAmountChanged(lpHolderAmount);
  }

  /**
  * @dev Sets the value for {lpHolderFee}
  */
  function setLPHolderFee(uint256 _lpHolderFee) public onlyOwner {
    require(msg.sender == owner(), "setLPHolderFee: FORBIDDEN");
    require(_lpHolderFee < 10000, "setLPHolderFee: fee can't be >=100%");
    lpHolderFee = _lpHolderFee;
    emit LPHolderFeeChanged(lpHolderFee);
  }

  /**
  * @dev Sets the value for {feePercentage}
  */
  function setFeePercentage(uint256 _feePercentage) public onlyOwner {
    require(msg.sender == owner(), "setFeePercentage: FORBIDDEN");
    require(_feePercentage < 10000, "setFeePercentage: fee can't be >=100%");
    feePercentage = _feePercentage;
    emit FeePercentageChanged(feePercentage);
  }

  /**
  * @dev Sets the value for {burnPercentage}
  */
  function setBurnPercentage(uint256 _burnPercentage) public onlyOwner {
    require(msg.sender == owner(), "setBurnPercentage: FORBIDDEN");
    require(_burnPercentage <= 10000, "setBurnPercentage: burnPercentage can't be >100%");
    burnPercentage = _burnPercentage;
    emit BurnPercentageChanged(burnPercentage);
  }

  /**
  * @dev Sets the value for {oppositeAddress}
  */
  function setOppositeAddress(address _address) public onlyOwner {
    require(msg.sender == owner(), "setOppositeAddress: FORBIDDEN");
    require(_address != address(0), "setOppositeAddress: address can't be the zero address");
    oppositeAddress = _address;
    buybackPath = [address(this), router.WETH(), oppositeAddress];
    emit OppositeAddressChanged(oppositeAddress);
  }

  function isExcluded(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  function excludeAccount(address _address) external onlyOwner {
    require(msg.sender == owner(), "excludeAccount: FORBIDDEN");
    require(!_isExcluded[_address], "excludeAccount: account is already excluded");
    _isExcluded[_address] = true;
  }

  function includeAccount(address _address) external onlyOwner {
    require(msg.sender == owner(), "includeAccount: FORBIDDEN");
    require(_isExcluded[_address], "includeAccount: account is not excluded");
    _isExcluded[_address] = false;
  }

  function addLiquidity() public payable onlyOwner {
    router.addLiquidityETH{value: msg.value}(address(this), _totalSupply, _totalSupply, msg.value, burnAddress, block.timestamp + 1200);
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "_transfer: transfer from the zero address");
    require(recipient != address(0), "_transfer: transfer to the zero address");
    require(amount > 0, "_transfer: transfer amount must be greater than zero");
    require(_balances[sender] >= amount, "_transfer: transfer amount exceeds balance");

    uint256 fee = getFeePercentage();
    uint256 lpFee = getLPHolderFee();
    uint256 lpAmount = getLPHolderAmount();

    if (fee == 0 ||
        sender == address(this) ||
          _isExcluded[sender] ||
            recipient == address(0) ||
              sender == address(router) ||
                recipient == address(router) ||
                  sender == address(lpPair) ||
                    recipient == address(lpPair)
       ) {
         _transferExcluded(sender, recipient, amount);
         if (recipient == burnAddress) {
           emit Burn(amount);
         }
       } else if (lpPair.balanceOf(sender) >= lpAmount) {
         _transferStandard(sender, recipient, amount, fee.mul(lpFee).div(10000));
       } else {
         _transferStandard(sender, recipient, amount, fee);
       }
  }

  function _transferStandard(address sender, address recipient, uint256 amount, uint256 _fee) private {
    uint256 fee = amount.mul(_fee).div(10000);
    uint256 burn = fee.mul(getBurnPercentage()).div(10000);
    uint256 buyback = fee.sub(burn, "_transferStandard: fee exeeds amount");
    _transferExcluded(sender, recipient, amount.sub(fee, "_transferStandard: fee exeeds amount"));
    _transferExcluded(sender, burnAddress, burn);
    emit Burn(burn);
    if (buyback > 0 && !_triggerBuyback(sender, buyback)) {
      _transferExcluded(address(this), burnAddress, buyback);
      emit Burn(burn);
    }
  }

  function _transferExcluded(address sender, address recipient, uint256 amount) private {
    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "_transferExcluded: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _triggerBuyback(address sender, uint256 amount) private returns (bool) {
    if (oppositeAddress == address(0)) {
      emit BuybackFailed(amount, "ADDRESS_ERROR");
      return false;
    }

    _transferExcluded(sender, address(this), amount);
    return _buyback(amount);
  }

  function _buyback(uint256 amount) private returns (bool) {
    require(_balances[address(this)] >= amount, "_buyback: buyback amount exceeds balance");
    _approve(address(this), address(router), _totalSupply);
    try router.swapExactTokensForTokens(amount, 1, buybackPath, burnAddress, block.timestamp + 1200) returns (uint[] memory amounts) {
      emit Buyback(amount, amounts[amounts.length - 1]);
      return true;
    } catch Error(string memory error) {
      emit BuybackFailed(amount, error);
      return false;
    } catch {
      emit BuybackFailed(amount, "UNISWAP_ERROR");
      return false;
    }
  }

  function burned() public view returns (uint256 amount) {
    return _balances[burnAddress];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20Fee.sol";

contract Yin is ERC20Fee('Yin', 'YIN') {}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}