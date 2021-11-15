pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

// Deploy step
// 0. Deploy the token buy  contract such as stable if not exist
// 1. Deploy the token contract with the ICO end time
// 2. Deploy the Crowdsale contract using the token address of the contract just deployed
// 3. Set the Crowdsale address inside the token contract with the setCrowdsale() function to distribute the tokens
// 4. Make the Crowdsale address public to your investors so that they can send ether to it to buy tokens


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract ICOToken is ERC20 {

   address public crowdsaleAddress;
   
   address payable public owner;
   
   uint256 public ICOEndTime;
      
   
   modifier onlyCrowdsale {
       require(msg.sender == crowdsaleAddress, "Only crowdsale can send token");
       _;
   }
   
   modifier onlyOwner {
       require(msg.sender == owner, "Allow only owner");
       _;
   }
   
   modifier afterCrowdsale {
       require(block.timestamp > ICOEndTime || msg.sender == crowdsaleAddress);
       _;
   }
   
   
  constructor (uint256 _ICOEndTime, uint256 _fundingGoal, string memory _fullName, string memory _shortName) ERC20(_fullName, _shortName) {
      
      require(_ICOEndTime > 0, "Need more than zero");
      require(_fundingGoal > 0, "Funding more than zero");

      owner = payable(msg.sender);
      
      ICOEndTime = _ICOEndTime;
    
      // initial deposit balance to contract owner
      
      uint256 initialDeposit = _fundingGoal * 10 ** decimals();

      _mint(owner, initialDeposit);
   }
   
   function setCrowdsale(address _crowdsaleAddress) public onlyOwner {
       
       require(_crowdsaleAddress != address(0));
       
       crowdsaleAddress = _crowdsaleAddress;
       
       // approve crowdsale contract to send token in owner deposit account
       approve(crowdsaleAddress, type(uint256).max);
   }
   
   function buyTokens(address _receiver, uint256 _amount) public onlyCrowdsale {
       
       require(_receiver != address(0));
       
       require(_amount > 0);
       
       // transfer from deposit to receiver in name of crowdsaleAddress
       
       transferFrom(owner, _receiver, _amount);
   }
   
   // @notice Override the functions to not allow token transfers until the end of the ICO

   function transfer(address _to, uint256 _value) public override afterCrowdsale returns (bool) {
       return super.transfer(_to, _value);
   }
   
   // @notice Override the functions to not allow token transfers until the end of the ICO
   
    function transferFrom(address _from, address _to, uint256 _value) public override afterCrowdsale returns (bool) {
       return super.transferFrom(_from, _to, _value);
    }
  
   
    function emergencyExtract() external onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    function balanceOfOwner() public view returns (uint256) {
        return balanceOf(owner) / 10 ** decimals();
    }

}

contract ICO {
    using SafeMath for uint256;
    
    // tell this sell is complete or not
    bool icoCompleted;
    // tell this time when ico start
    uint256 public icoStartTime;
    // tell this time when ico end
    uint256 public icoEndTime;
    // set token exchange rate
    uint256 public tokenRateEth;
    // use from ICO TOKEN Contract
    ICOToken public token;
    // how much money raised so far
    uint256 public fundingGoal;
    // this is owner of this money raised
    address payable public owner;
    // token raised so far
    uint256 public tokenRaised;
    // ether get
    uint256 public etherRaised;
    // keep exceed ethers
    uint256 public etherExceeds;     
    
    // token get
    uint256 public tokenBuyRaised;
    // keep exceed token buy
    uint256 public tokenBuyExceeds;   
    // set token exchange rate for token
    uint256 public tokenRateTokenBuy;
    // set token address to accept as buy token
    mapping(address => bool) public whitelistTokenBuyAddress;
    
    

    event BuyToken(address indexed buyer, uint256 ethPaid, uint256 tokenBought);
    event BuyTokenWithToken(address indexed buyer, uint256 tokenPaid, uint256 tokenBought);
    event ExtractEther(address indexed withdrawer, uint256 ethReceived);
    event EmergencyWithdrawEther(address indexed withdrawer, uint256 ethReceived);    
    event ExtractToken(address indexed withdrawer, uint256 tokenReceived);
    event EmergencyWithdrawToken(address indexed withdrawer, uint256 tokenReceived);  
    
    modifier whenIcoCompleted {
        require(icoCompleted, "This ico not complete yet");
        _;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Allow only owner");
        _;
    }    
    
    constructor(
        uint256 _icoStartTime,
        uint256 _icoEndTime,
        uint256 _tokenRateEth,
        address _tokenAddress,
        uint256 _fundingGoal,
        address _tokenBuyAddress,
        uint256 _tokenRateTokenBuy
    ) {    
        require (
            _icoStartTime != 0 &&
            
            _icoEndTime != 0 &&
            
            _tokenRateEth != 0 &&
            
            _tokenAddress != address(0) &&
            
            _fundingGoal != 0

        , "Some value are not valid");
        
        icoCompleted = false;
        
        icoStartTime = _icoStartTime;
        
        icoEndTime = _icoEndTime;
        
        token = ICOToken(_tokenAddress);
        
        tokenRateEth = _tokenRateEth;
        
        fundingGoal = _fundingGoal * 10 ** token.decimals();
        
        owner = payable(msg.sender);
        
        whitelistTokenBuyAddress[_tokenBuyAddress] = true;
        
        tokenRateTokenBuy = _tokenRateTokenBuy;
    }
        
    
    function buy() public payable {
        
        require(tokenRaised < fundingGoal, "ICO Raise to CAP");
        
        require(block.timestamp > icoStartTime && block.timestamp < icoEndTime, "End time for ICO");
        
        uint256 tokensToBuy;
        
        uint256 etherUsed = msg.value;
        
        address payable sender = payable(msg.sender);
        
        uint256 etherExceed;
        
        uint256 etherUnit = 1 ether;
        
        // incase token have 5 decimal but ether is 18 decimal
        // also multiply with token rate 
        // tokensToBuy = msg.value * 1e5 / 1 ether * tokenRateEth;
        
        
        // if have token instance can change to use decimals
        // formular 
        // ######
        // etherUsed * (10 ** token.decimals()) / 1 ether * tokenRateEth;
        // ######
        tokensToBuy = etherUsed.mul(10 ** token.decimals()).div(etherUnit).mul(tokenRateEth);
        
        // Check if we have reached and exceeded the funding goal to refund the exceeding tokens and ether
        if (tokenRaised.add(tokensToBuy) > fundingGoal) {
            
            uint256 tokenExceed = tokenRaised.add(tokensToBuy).sub(fundingGoal);
            
            
            // test convert rate
            // formular
            // etherExceed = tokenExceed * 1 ether / 10 ** token.decimals() / tokenRateEth;
            // from tutorial
            // exceedingEther = exceedingTokens * 1 ether / tokenRateEth / token.decimals();
            
            etherExceed = tokenExceed.mul(etherUnit).div(10 ** token.decimals()).div(tokenRateEth);
                                    
            sender.transfer(etherExceed);
            
            etherUsed = etherUsed.sub(etherExceed);
            
            tokensToBuy = tokensToBuy.sub(tokenExceed);
            
        }
        
        // send token to buyer
        token.buyTokens(msg.sender, tokensToBuy);
        
        // increase token raised and ether raised variable
        
        tokenRaised = tokenRaised.add(tokensToBuy);
        
        // etherRaised += etherUsed / 1 ether;
        etherRaised = etherRaised.add(etherUsed);
        
        // total eth exceed
        etherExceeds = etherExceeds.add(etherExceed);

        emit BuyToken(msg.sender, etherUsed, tokensToBuy);
    }
    
    
    function buyWithToken(uint256 _amount, address _tokenBuyAddress) public {
        
        require(whitelistTokenBuyAddress[_tokenBuyAddress], "Not allow this token to buy");
        
        require(tokenRaised < fundingGoal, "ICO Raise to CAP");
        
        require(block.timestamp > icoStartTime && block.timestamp < icoEndTime, "End time for ICO");
        
        // set token buy instance
        ERC20 tokenBuy = ERC20(_tokenBuyAddress);
        
        uint256 tokensToReceived;
        
        uint256 tokenBuyUsed = _amount;
        
        address sender = msg.sender;
        
        uint256 tokenBuyExceed;
        
        uint256 tokenBuyUnit = 10 ** tokenBuy.decimals();
        
        uint256 tokenReceivedUnit = 10 ** token.decimals();
        
        
        // trasfer token buy to crowdsale 
        
        tokenBuy.transferFrom(sender, address(this), tokenBuyUsed);
        
        // calculate token to token
        tokensToReceived = tokenBuyUsed.mul(tokenReceivedUnit).div(tokenBuyUnit).mul(tokenRateTokenBuy);
        
        // Check if we have reached and exceeded the funding goal to refund the exceeding tokens and ether
        if (tokenRaised.add(tokensToReceived) > fundingGoal) {
            
            uint256 tokensToReceivedExceed = tokenRaised.add(tokensToReceived).sub(fundingGoal);
            
            // formular
            // tokenBuyExceed = tokenExceed * 10 ** tokenBuyUnit / 10 ** token.decimals() / tokenRateEth;
            
            tokenBuyExceed = tokensToReceivedExceed.mul(tokenBuyUnit).div(tokenReceivedUnit).div(tokenRateTokenBuy);

            // transfer exceed token to user
                
            tokenBuy.transfer(sender, tokenBuyExceed);
            
            tokenBuyUsed = tokenBuyUsed.sub(tokenBuyExceed);
            
            tokensToReceived = tokensToReceived.sub(tokensToReceivedExceed);
            
        }
        
        // send token to buyer
        token.buyTokens(sender, tokensToReceived);
        
        // increase token raised and ether raised variable
        
        tokenRaised = tokenRaised.add(tokensToReceived);
        
        // count raised token
        tokenBuyRaised = tokenBuyRaised.add(tokenBuyUsed);

        emit BuyTokenWithToken(msg.sender, tokenBuyUsed, tokensToReceived);
    }


    
    function unBuy() public payable {
        uint256 tokenToConvert = 10;
        uint256 weiFromTokens;
        
        //  weiFromTokens = tokensToConvert * 1 ether / tokenRateEth / 1e5;
        
        weiFromTokens = tokenToConvert * 1 ether / 1e5 / tokenRateEth;
    }
    
    
    
    // withdraw money raised to owner 
    function extractEther() public whenIcoCompleted onlyOwner {
        
        owner.transfer(address(this).balance);

        emit ExtractEther(msg.sender, address(this).balance);
    }

    // withdraw money raised to owner 
    function emergencyWithdrawEther() public onlyOwner {
        
        owner.transfer(address(this).balance);

        emit EmergencyWithdrawEther(msg.sender, address(this).balance);
    }
    
     // withdraw money raised to owner 
    function extractToken(address _tokenAddress) public whenIcoCompleted onlyOwner {
        
        ERC20 tokenBuy = ERC20(_tokenAddress);
        
        uint256 allTokenBalance = tokenBuy.balanceOf(address(this));
        
        tokenBuy.transfer(owner, allTokenBalance);

        emit ExtractToken(msg.sender, allTokenBalance);
    }

    // withdraw money raised to owner 
    function emergencyWithdrawToken(address _tokenAddress) public onlyOwner {
        
        ERC20 tokenBuy = ERC20(_tokenAddress);
        
        uint256 allTokenBalance = tokenBuy.balanceOf(address(this));
        
        tokenBuy.transfer(owner, allTokenBalance);

        emit ExtractToken(msg.sender, allTokenBalance);
    }
    
    
    // According to solidity version 0.6.0, we have a breaking change. The unnamed function commonly referred to as “fallback function” 
    // was split up into a new fallback function that is defined using the fallback keyword and a receive ether function defined using the receive keyword. 
    // If present, the receive ether function is called whenever the call data is empty (whether or not ether is received). This function is implicitly payable. 
    // The new fallback function is called when no other function matches (if the receive ether function does not exist then this includes calls with empty call data). 
    // You can make this function payable or not. If it is not payable then transactions not matching any other function which send value will revert. 
    // You should only need to implement the new fallback function if you are following an upgrade or proxy pattern.
    
    // https://solidity.readthedocs.io/en/v0.6.7/060-breaking-changes.html#semantic-and-syntactic-changes



    fallback() external payable {
        
        buy();
        
    }
    
    receive() external payable {
        
        buy();
        
    }
    
    // set token address later 
    function setTokenAddress(address _tokenAddress) public onlyOwner {

        token = ICOToken(_tokenAddress);

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

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

