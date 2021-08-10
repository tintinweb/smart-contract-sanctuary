/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-05
*/

pragma solidity ^0.7.6;
contract BaBiToken {
    using SafeMath for uint256;
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event Approval(address indexed owner, address indexed spender, uint value);

    
    /* Token Basic Details */
    string public tokenName = "BaBiToken";
    string public tokenSymbol = "BBT";
    uint8 public decimal = 9;
    uint256 public totalSupply = 1000000000 * 10**9;
    uint256 public preSaleLimit = 580000000 * 10**9;
    uint256 public pricePerToken = 3448275900000;
	uint256 public devFunds = 20000000 * 10**9;
    uint256 public marketingFunds = 30000000 * 10**9;
    uint256 public preSaleDone = 0;

    /* Variable Declaration */
    // uint256 public basisPointsRate = 0;
    // uint256 public maximumFee = 0;
    address payable internal owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public preSaleBalance;
    bool preSaleAllowed = true;
    mapping (address => mapping (address => uint)) public allowed;
    // uint256 holdingAmount = 0*10**6;
    address dev = address(0x30E8a02c3E8AeCC4e2848827b68214528EEFe0ee);
    address marketing = address(0xe526E05bca618C3D17efe4BE954298508700405c);

    modifier onlyOwner() {
        require(msg.sender == owner,"Only Owner Can Call This.");
        _;
    }
    
    constructor()
    {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
		_transferDevFunds(owner);
        _transferMarketingFunds(owner);
        emit Transfer(address(0),owner,totalSupply);
    }

function _transferDevFunds(address sender) public {
        _transfer(sender, dev, devFunds);
}
	
function _transferMarketingFunds(address sender) public {
    /*_tOwned[sender] = _tOwned[sender].sub(marketingFunds);
    _rOwned[sender] = _rOwned[sender].sub(marketingFunds);
    _tOwned[marketing] = _tOwned[marketing].add(marketingFunds);
    _rOwned[marketing] = _rOwned[marketing].add(marketingFunds);
    emit Transfer(_msgSender(), marketing, marketingFunds);*/
    _transfer(sender, marketing, marketingFunds);
}

function getPreSaleDone () external view returns(uint256) {
            return preSaleDone ;
    }
    
    function disablePresale() external onlyOwner returns(bool){
        preSaleAllowed = false;
        return preSaleAllowed;
    }
    
    function enablePresale() external onlyOwner returns(bool){
        preSaleAllowed = true;
        return preSaleAllowed;
    }

    function getTotalSupply() external view returns(uint256) {
            return totalSupply;
    }

    function getPricePerToken() external view returns(uint256) {
        return pricePerToken;
    }
    
    
    function name() external view returns(string memory) {
        return tokenName;
    }

    function symbol() external view returns(string memory) {
        return tokenSymbol;
    }


    function decimals() external view returns(uint8){
            return decimal;
    }
    

    function getTokenBalance(address tokenHolderAddress) external view returns(uint256) {
            return balanceOf[tokenHolderAddress];
    }

    function getContractAddress() external view returns(address) {
        return address(this);
    }
    
    function getPreSaleBalance(address tokenHolderAddress) external view returns(uint256) {
            return preSaleBalance[tokenHolderAddress];
    }
    
    function preSalePurchase() public payable returns (bool) {
        require(msg.sender == tx.origin, "Origin and Sender Mismatched");
        address buyer = msg.sender;
        uint256 bnbValue = msg.value;
        uint256 totalTokenValue = (bnbValue.mul(10**9)).div(pricePerToken);
        require(msg.sender != owner, "Owner can not Purchase Presale");
        require(preSaleAllowed, "Pre Sale Not Allowed");
        preSaleDone = preSaleDone.add(totalTokenValue);
        require(preSaleDone <= preSaleLimit, "Pre Sale Completed");
        require(totalTokenValue > 0, "Purchase more than 0");
        require(buyer != address(0), "ERC20: mint to the zero address");
        _transfer(owner, buyer, totalTokenValue);
        owner.transfer(address(this).balance);
        /*emit Transfer(address(this), buyer, taxedTokenAmount);*/
        return true;
    }


    function transfer(address recipient, uint256 amount) external  returns (bool) {
        require(msg.sender == tx.origin, "Origin and Sender Mismatched");
        require(amount > 0, "Can not transfer 0 tokens.");
        require(balanceOf[msg.sender] >= amount, "Insufficient Token Balance.");
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        balanceOf[sender] = balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function payoutToPresaleOwner() public payable onlyOwner{
            owner.transfer(address(this).balance);

    }
    
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balanceOf[from] = SafeMath.sub(balanceOf[from], tokens);
        allowed[from][msg.sender] = SafeMath.sub(allowed[from][msg.sender], tokens);
        balanceOf[to] = SafeMath.add(balanceOf[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
}

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