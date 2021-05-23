/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.8.3;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return  payable(address(msg.sender));
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

abstract contract ERC20Basic {
    function balanceOf(address who) virtual public view returns (uint256);
    function transfer(address to, uint256 value) virtual public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) virtual public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) virtual public returns (bool);
    function approve(address spender, uint256 value) virtual public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is Ownable, ERC20Basic, ReentrancyGuard{
    using SafeMath for uint;
    uint256 public _totalSupply;
    bool private _isFeeEnabled;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 public _taxFee;

    uint256 public _liquidityFee;

    uint256 public _burnFee;

    uint256 public _donationFee;
    address private donationWallet ;
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 private _tDonationTotal;
    uint256 private _tLiquidityTotal;
    uint256 public _maxTxAmount;
    event Donate(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Returns the Total Supply of the token.
     */


    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }
    function totalDonation() public view returns (uint256) {
        return _tDonationTotal;
    }
    function totalLiquidity() public view returns (uint256) {
        return _tLiquidityTotal;
    }

    function setdonationWallet(address newWallet) external onlyOwner() {
        donationWallet = newWallet;
    }

    /**
     * @dev Returns if Fee Calculation is enabled for the token.
     */
    function isFeeEnabled() public view returns (bool) {
        return _isFeeEnabled;
    }
    function setFeeEnabled(bool feeEnabled) public returns (bool) {
        _isFeeEnabled=feeEnabled;
        return true;
    }

    function transfer(address to, uint256 value) public onlyOwner override(ERC20Basic) returns (bool) {
        require(to != address(0),'Cannot Transfer to 0x0 Account');
        require(value <= balances[msg.sender],'Cannot Transfer Value greater than Balance');
        require(value <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        assert(balances[msg.sender] <= value);
        _transfer(msg.sender,to,value);
        return true;
    }

    function balanceOf(address _owner) public override(ERC20Basic) view returns (uint256 balance) {
        return balances[_owner];
    }
    function transferFrom(address from, address to, uint256 value) public override(ERC20Basic) returns (bool) {
        require(to != address(0),'Cannot Transfer to 0x0 Account');
        require(value <= balances[from],'Cannot Transfer Value greater than Balance');
        require(value <= allowed[from][msg.sender],'Cannot Transfer Value greater than Allowed');
        assert(balances[from] <= value);
        allowed[from][msg.sender] = allowed[from][msg.sender] - (value);
        _transfer(from,to,value);
        return true;
    }
    function donate(address to, uint256 value) public onlyOwner  returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);
        assert(balances[msg.sender] <= value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Donate(msg.sender, to, value);
        return true;
    }
    function _transfer(address from, address to, uint256 value) private returns (bool) {
        if(_isFeeEnabled){
            //Calculate all the deductions
            uint _tFeeAmt=value.mul(_taxFee).div(10**3);
            uint _tBurnAmt=value.mul(_burnFee).div(10**3);
            uint _tDonationAmt=value.mul(_donationFee).div(10**3);
            uint _tLiquidityAmt=value.mul(_liquidityFee).div(10**3);

            //Cumulative add all the deductions
            _tFeeTotal= _tFeeTotal.add(_tFeeAmt);
            _tBurnTotal=_tBurnTotal.add(_tBurnAmt);
            _tDonationTotal=_tDonationTotal.add(_tDonationAmt);
            _tLiquidityTotal=_tLiquidityTotal.add(_tLiquidityAmt);
            balances[from] = balances[from].sub(value);

            //Adjust the value with the amount to be deducted
            value=value.sub(_tFeeAmt);
            donate(donationWallet, _tDonationAmt);
            burn(_tBurnAmt);
        }
        //Now transfer the balance
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public override(ERC20Basic) returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function allowance(address owner, address spender) public override(ERC20Basic) view returns (uint256) {
        return allowed[owner][spender];
    }
    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            assert(oldValue <= subtractedValue);
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    //MINT Section
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;
    modifier canMint() {
        require(!mintingFinished,'Minting has already finished');
        _;
    }
    function mint(address to, uint256 amount) onlyOwner canMint virtual public returns (bool) {
        _totalSupply = _totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    //BURN SECTION
    event Burn(address indexed burner, uint256 value);
    function burn(uint256 _amount) public {
        require(_amount <= balances[msg.sender],'Cannot burn Amount more than available balance');
        address burner = msg.sender;
        assert(balances[burner] <= _amount);
        balances[burner] = balances[burner] - (_amount);
        assert(_totalSupply <= _amount);
        _totalSupply -=  (_amount);
        emit Burn(burner, _amount);
    }
}


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Token is BasicToken {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private totalSupply_;
    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor () payable {
        _name = "LIQUIDITYTOKEN";
        _symbol = "LQT";
        _decimals = 18;
        _totalSupply = 1 * 10**9 * 10**18;
        _taxFee = 25 ;
        _liquidityFee = 10;
        _burnFee = 5;
        _donationFee = 10;
        _maxTxAmount = 100000 * 10**18;
        setFeeEnabled(true);
        balances[msg.sender] = _totalSupply;// Give the creator all initial tokens
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

}