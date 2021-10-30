// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Auth.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";

interface INeuralPepe is IERC721Enumerable {
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}

interface IAiRouter {
  function distributeTax(uint256 taxAmount) external;
  function isInSwap() external view returns (bool);
  function supportsDistribureFunction() external pure returns (bool);
  function authorize(address adr) external;
  function liquifyBack() external;
}

contract AI is IBEP20, Auth {
  using SafeMath for uint256;

	string constant _name = "AIv2";
  string constant _symbol = "AI";
  uint8 constant _decimals = 18;

  // Constants
  uint256 public constant SECONDS_IN_A_DAY = 86400;
  uint256 public constant emissionEnd = 1933606800;
  uint256 public constant aiSnapshot = 1632158133;

  // Public variables
  uint256 public emissionPerDay = 2300000000000000000;
  uint256 private MAX_EMISSION_PER_DAY = 10000000000000000000;
  uint256 private _totalSupply;

	mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) _allowances;
  mapping (address => bool) isFeeExempt;
  mapping(uint256 => uint256) private _lastClaim;
  mapping (address => address) private _taxAddresses;
  mapping (address => uint256) private _taxAmount;
  mapping (address => bool) private _isLaunched;

  // Fees. Some may be completely inactive at all times.
  uint256 feeDenominator = 1000;

  address private _pepeAddress;
  address[] private pairs; 
  INeuralPepe private PEPE = INeuralPepe(_pepeAddress);

  bool public swapEnabled = true;

  event TaxCollectionEnabled(bool enabledOrNot);

	constructor(uint256 valueToMint) Auth(msg.sender) {
    isFeeExempt[msg.sender] = true;
    isFeeExempt[address(this)] = true;
    
		_mint(owner, valueToMint);
	}

	receive() external payable {}

  function totalSupply() external view override returns (uint256) { return _totalSupply; }
  function decimals() external pure override returns (uint8) { return _decimals; }
  function symbol() external pure override returns (string memory) { return _symbol; }
  function name() external pure override returns (string memory) { return _name; }
  function getOwner() external view override returns (address) { return owner; }
  function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
  function burn(uint256 burnQuantity) public override returns (bool) {
      _balances[msg.sender] = _balances[msg.sender].sub(burnQuantity);
      _totalSupply = _totalSupply.sub(burnQuantity);
      emit Transfer(msg.sender, address(0), burnQuantity);
      return true;
  }
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
    }
  function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
  function approve(address spender, uint256 amount) public override returns (bool) {
      _allowances[msg.sender][spender] = amount;
      emit Approval(msg.sender, spender, amount);
      return true;
  }
  function approveMax(address spender) external returns (bool) { return approve(spender, type(uint256).max); }
  function transfer(address recipient, uint256 amount) external override returns (bool) { return _transferFrom(msg.sender, recipient, amount); }
	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    if (_allowances[sender][msg.sender] != type(uint256).max) {
      require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
      _allowances[sender][msg.sender] -= amount;
    }
    return _transferFrom(sender, recipient, amount);
  }
	function _basicTransfer(address sender, address recipient, uint256 amount) internal  returns (bool) {
		require(amount <= _balances[sender], "Insufficient Balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
  }
  // function basicTransfer(address recipient, uint256 amount) external override returns (bool) { return _basicTransfer(msg.sender, recipient, amount); }

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(amount > 0);
    address tradeAddress = returnTradeAddress(sender, recipient);
    bool isInSwap = tradeAddress != address(0) ? IAiRouter(_taxAddresses[tradeAddress]).isInSwap() : true;

    if (isInSwap || tradeAddress == address(0)) {
      return _basicTransfer(sender, recipient, amount);
    }

    // activates the liquidity on DEX
    if (!_isLaunched[tradeAddress] && recipient == tradeAddress && tradeAddress != address(0)) {
        require(_balances[sender] > 0);
        require(sender == owner, "Only the owner can be the first to add liquidity.");
        _isLaunched[tradeAddress] = !_isLaunched[tradeAddress];
        
        return _basicTransfer(sender, recipient, amount);
    }

    require(amount <= _balances[sender], "Insufficient Balance");
    _balances[sender] -= amount;

    // checks whether it needs to take a fee and takes it before transferring to the 
    uint256 amountReceived = shouldTakeFee(sender, recipient, tradeAddress) ? takeFee(sender, amount, tradeAddress) : amount;
    uint256 tax = amount.sub(amountReceived);

    if (shouldSwapBack(tradeAddress) && !isInSwap && tax > 0) {
      try IAiRouter(_taxAddresses[tradeAddress]).liquifyBack() {} catch {}
    }

    _balances[recipient] += amountReceived;
    emit Transfer(sender, recipient, amountReceived);
    return true;
  }
  
  // returns taxable pair if sender or recepient is in pairs array
  function returnTradeAddress(address sender, address recipient) internal view returns (address) {
    address[] memory liqPairs = pairs;
    for (uint256 i = 0; i < liqPairs.length; i++) {
      if (sender == liqPairs[i] || recipient == liqPairs[i]) {
        return liqPairs[i];
      }
    }
    return address(0);
  }

	// Decides whether this trade should take a fee.
	// Trades with pairs are always taxed, unless sender or receiver is exempted.
	// Non trades, like wallet to wallet, are configured, untaxed by default.
	function shouldTakeFee(address sender, address recipient, address tradeAddress) internal view returns (bool) {
    if (isFeeExempt[sender] || isFeeExempt[recipient] || !_isLaunched[tradeAddress] || !swapEnabled) {
			return false;
		}

    address[] memory liqPairs = pairs;
    for (uint256 i = 0; i < liqPairs.length; i++) {
        if (sender == liqPairs[i] || recipient == liqPairs[i]) {
        return true;
      }
    }

    return false;
    }

  // Takes fee and triggers router function to re-balance fee for different wallets.
	function takeFee(address sender, uint256 amount, address tradeAddress) internal returns (uint256) {
		if (!_isLaunched[tradeAddress]) { return amount; }

		uint256 liqFee = 0;
    
    // If there is a liquidity tax active for autoliq, the contract keeps it.
    if (_taxAmount[tradeAddress] > 0) {
      liqFee = amount.mul(_taxAmount[tradeAddress]).div(feeDenominator);
      _balances[_taxAddresses[tradeAddress]] += liqFee;
      emit Transfer(sender, _taxAddresses[tradeAddress], liqFee);

      try IAiRouter(_taxAddresses[tradeAddress]).distributeTax(liqFee) {} catch {}
    }

    return amount - liqFee;
  }

  // Checks whether it should buy back and add liquidity
  function shouldSwapBack(address tradeAddress) internal view returns (bool) {
      return _isLaunched[tradeAddress]
          && msg.sender != tradeAddress
          && swapEnabled
          && _balances[_taxAddresses[tradeAddress]] > 0;
  }

  // activates auto-liquidity
	function setSwapEnabled(bool set) external authorized {
		swapEnabled = set;
		emit TaxCollectionEnabled(set);
	}

  // Sets a wallet address to be taxable or not
  function setIsFeeExempt(address holder, bool exempt) external authorized {
      isFeeExempt[holder] = exempt;
  }

	// Recover any BNB sent to the contract by mistake.
	function rescue() external {
    payable(owner).transfer(address(this).balance);
  }

  // Adds trading pair along with the tax address (where we should route tax) and tax amount
	function addPair(address pair, address taxAddress, uint256 _newTaxAmount) external authorized {
    pairs.push(pair);
    _taxAddresses[pair] = taxAddress;
    _taxAmount[pair] = _newTaxAmount;
  }
  
  // removed the latest added pair
  function removeLastPair() external authorized {
      pairs.pop();
  }
  
  function _getAddressIndex(address tradeAddress) private view returns (uint) {
    for(uint i = 0; i < pairs.length; i++) {
      if (pairs[i] == tradeAddress) {
        return i.add(1);
      }
    }
    return 0;
  }
  /**
    * @dev Only owner can call this function. Remove taxable address.
  */
  function removePair(address pairAddressToRemove) public onlyOwner {
    require(_isTradeAddressExists(pairAddressToRemove), 'The address you try to remove doesnt exist');
    uint addressIndex = _getAddressIndex(pairAddressToRemove).sub(1);

    for (uint i = addressIndex; i < pairs.length - 1; i++) {
      pairs[i] = pairs[pairs.length - 1];
    }
    pairs.pop();
  }

    /**
    * @dev Internal functions.
    */
  function _isTradeAddressExists(address tradeAddress) private view returns (bool) {
    if (pairs.length == 0) { return false; }
    for(uint i = 0; i < pairs.length; i++) {
      if (pairs[i] == tradeAddress) {
        return true;
      }
    }
    return false;
  }


  /**
  * @dev When accumulated AIs have last been claimed for a Neural Pepe index
  */
  function lastClaim(uint256 tokenIndex) public view returns (uint256) {
      require(PEPE.ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
      
      uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0 ? uint256(_lastClaim[tokenIndex]) : aiSnapshot;
      return lastClaimed;
  }

  /**
    * @dev Accumulated AI tokens for a Neural Pepe token index.
    */
  function accumulated(uint256 tokenIndex) public view returns (uint256) {
      require(PEPE.ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
      require(tokenIndex < PEPE.totalSupply(), "AI at index has not been minted yet");

      uint256 lastClaimed = lastClaim(tokenIndex);

      // Sanity check if last claim was on or after emission end
      if (lastClaimed >= emissionEnd) return 0;

      uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd; // Getting the min value of both
      uint256 totalAccumulated = accumulationPeriod.sub(lastClaimed).mul(emissionPerDay).div(SECONDS_IN_A_DAY);

      return totalAccumulated;
  }

  /**
    * @dev Claim mints AIs and supports multiple Neural Pepe token indices at once.
    */
  function claim(uint256[] memory tokenIndices) public override returns (uint256) {
      uint256 totalClaimQty = 0;
      for (uint i = 0; i < tokenIndices.length; i++) {
          // Sanity check for non-minted index
          require(tokenIndices[i] < PEPE.totalSupply(), "AI at index has not been minted yet");
          // Duplicate token index check
          for (uint j = i + 1; j < tokenIndices.length; j++) {
              require(tokenIndices[i] != tokenIndices[j], "Duplicate token index");
          }

          uint tokenIndex = tokenIndices[i];
          require(PEPE.ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");

          uint256 claimQty = accumulated(tokenIndex);
          if (claimQty != 0) {
              totalClaimQty = totalClaimQty.add(claimQty);
              _lastClaim[tokenIndex] = block.timestamp;
          }
      }

      require(totalClaimQty != 0, "No accumulated AI");
      _mint(msg.sender, totalClaimQty);
      return totalClaimQty;
  }

  /**
    * @dev Only owner can call this function. Change AI emission per day.
    */
  function changeEmissionPerDay(uint256 _newEmissionPerDay) public onlyOwner {
    require(_newEmissionPerDay >= 0 || _newEmissionPerDay <= MAX_EMISSION_PER_DAY, 'invalid emission per day');
    emissionPerDay = _newEmissionPerDay;
  }


  /**
  * @dev Only owner can call this function. Changes tax address and Tax amount for the pair, can be between 1 and 20.
  */
  function changeTaxAddressAndAmount(address tradeAddress, address taxAddress, uint256 _newTaxAmount) public onlyOwner {
    require(_newTaxAmount >= 0 && _newTaxAmount <= 200, 'Provide valid tax between 1 and 20');
    require(_taxAddresses[tradeAddress] != address(0), 'Trade address doesnt exist');

    _taxAddresses[tradeAddress] = taxAddress;
    _taxAmount[tradeAddress] = _newTaxAmount;
    isFeeExempt[taxAddress] = true;
  }

  function changePepeAddress(address newPepeAddress) public onlyOwner {
    _pepeAddress = newPepeAddress;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

import "./IERC721.sol";


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

import "./IERC165.sol";


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

  function burn(uint256 burnQuantity) external returns (bool);

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


  function claim(uint256[] memory tokenIndices) external returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}