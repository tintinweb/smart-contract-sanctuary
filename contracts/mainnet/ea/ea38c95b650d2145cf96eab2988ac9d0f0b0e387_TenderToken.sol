pragma solidity ^0.4.24;
 
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract Erc20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @dev (from OpenZeppelin)
 */
library LibSafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
 
    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
 
    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
 
    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
 
    /**
     * @dev Safe a * b / c
     */
    function mulDiv(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        uint256 d = mul(a, b);
        return div(d, c);
    }
}
 
 
contract OwnedToken {
    using LibSafeMath for uint256;
   
    /**
     * ERC20 info
     */
    string public name = &#39;Altty&#39;;
    string public symbol = &#39;LTT&#39;;
    uint8 public decimals = 18;
    /**
     * Allowence list
     */
    mapping (address => mapping (address => uint256)) private allowed;
    /**
     * Count of token at each account
     */
    mapping(address => uint256) private shares;
    /**
     * Total amount
     */
    uint256 private shareCount_;
    /**
     * Owner (main admin)
     */
    address public owner = msg.sender;
    /**
     * List of admins
     */
    mapping(address => bool) public isAdmin;
    /**
     * List of address on hold
     */
    mapping(address => bool) public holded;
 
    /**
     * Events
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed owner, uint256 amount);
    event Mint(address indexed to, uint256 amount);
 
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    /**
     * @dev Throws if not admin
     */
    modifier onlyAdmin() {
        require(isAdmin[msg.sender]);
        _;
    }
 
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0)); // if omittet addres, default is 0
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    /**
     * Empower/fire admin
     */
    function empowerAdmin(address _user) onlyOwner public {
        isAdmin[_user] = true;
    }
    function fireAdmin(address _user) onlyOwner public {
        isAdmin[_user] = false;
    }
    /**
     * Hold account
     */
    function hold(address _user) onlyOwner public {
        holded[_user] = true;
    }
    /**
     * Unhold account
     */
    function unhold(address _user) onlyOwner public {
        holded[_user] = false;
    }
   
    /**
     * Edit token info
     */
    function setName(string _name)  onlyOwner public {
        name = _name;
    }
    function setSymbol(string _symbol)  onlyOwner public {
        symbol = _symbol;
    }
    function setDecimals(uint8 _decimals)  onlyOwner public {
        decimals = _decimals;
    }
 
    /**
     * @dev total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return shareCount_;
    }
 
    /**
     * @dev Gets the balance of the specified address
     * @param _owner The address to query the the balance of
     * @return An uint256 representing the amount owned by the passed address
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return shares[_owner];
    }
 
    /**
     * @dev Internal transfer tokens from one address to another
     * @dev if adress is zero - mint or destroy tokens
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function shareTransfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(!holded[_from]);
        if(_from == address(0)) {
            emit Mint(_to, _value);
            shareCount_ =shareCount_.add(_value);
        } else {
            require(_value <= shares[_from]);
            shares[_from] = shares[_from].sub(_value);
        }
        if(_to == address(0)) {
            emit Burn(msg.sender, _value);
            shareCount_ =shareCount_.sub(_value);
        } else {
            shares[_to] =shares[_to].add(_value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to
     * @param _value The amount to be transferred
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        return shareTransfer(msg.sender, _to, _value);
    }
 
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return shareTransfer(_from, _to, _value);
    }
 
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
 
    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
 
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
 
    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
   
    /**
     * @dev Withdraw ethereum for a specified address
     * @param _to The address to transfer to
     * @param _value The amount to be transferred
     */
    function withdraw(address _to, uint256 _value) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_value <= address(this).balance);
        _to.transfer(_value);
        return true;
    }
   
    /**
     * @dev Withdraw token (assets of our contract) for a specified address
     * @param token The address of token for transfer
     * @param _to The address to transfer to
     * @param amount The amount to be transferred
     */
    function withdrawToken(address token, address _to, uint256 amount) onlyOwner public returns (bool) {
        require(token != address(0));
        require(Erc20Basic(token).balanceOf(address(this)) >= amount);
        bool transferOk = Erc20Basic(token).transfer(_to, amount);
        require(transferOk);
        return true;
    }
}
 
contract TenderToken is OwnedToken {
    // dividends
    uint256 public price = 3 ether / 1000000;
    uint256 public sellComission = 2900; // 2.9%
    uint256 public buyComission = 2900; // 2.9%
   
    // dividers
    uint256 public priceUnits = 1 ether;
    uint256 public sellComissionUnits = 100000;
    uint256 public buyComissionUnits = 100000;
   
    /**
     * Orders structs
     */
    struct SellOrder {
        address user;
        uint256 shareNumber;
    }
    struct BuyOrder {
        address user;
        uint256 amountWei;
    }
   
    /**
     * Current orders list and total amounts in order
     */
    SellOrder[] public sellOrder;
    BuyOrder[] public buyOrder;
    uint256 public sellOrderTotal;
    uint256 public buyOrderTotal;
   
 
    /**
     * Magic buy-order create
     * NB!!! big gas cost (non standart), see docs
     */
    function() public payable {
        if(!isAdmin[msg.sender]) {
            buyOrder.push(BuyOrder(msg.sender, msg.value));
            buyOrderTotal += msg.value;
        }
    }
 
    /**
     * Magic sell-order create
     */
    function shareTransfer(address _from, address _to, uint256 _value) internal returns (bool) {
        if(_to == address(this)) {
            sellOrder.push(SellOrder(msg.sender, _value));
            sellOrderTotal += _value;
        }
        return super.shareTransfer(_from, _to, _value);
    }
 
    /**
     * Configurate current price/comissions
     */
    function setPrice(uint256 _price) onlyAdmin public {
        price = _price;
    }
    function setSellComission(uint _sellComission) onlyOwner public {
        sellComission = _sellComission;
    }
    function setBuyComission(uint _buyComission) onlyOwner public {
        buyComission = _buyComission;
    }
    function setPriceUnits(uint256 _priceUnits) onlyOwner public {
        priceUnits = _priceUnits;
    }
    function setSellComissionUnits(uint _sellComissionUnits) onlyOwner public {
        sellComissionUnits = _sellComissionUnits;
    }
    function setBuyComissionUnits(uint _buyComissionUnits) onlyOwner public {
        buyComissionUnits = _buyComissionUnits;
    }
   
    /**
     * @dev Calculate default price for selected number of shares
     * @param shareNumber number of shares
     * @return amount
     */
    function shareToWei(uint256 shareNumber) public view returns (uint256) {
        uint256 amountWei = shareNumber.mulDiv(price, priceUnits);
        uint256 comissionWei = amountWei.mulDiv(sellComission, sellComissionUnits);
        return amountWei.sub(comissionWei);
    }
 
    /**
     * @dev Calculate count of shares what can buy with selected amount for default price
     * @param amountWei amount for buy share
     * @return number of shares
     */
    function weiToShare(uint256 amountWei) public view returns (uint256) {
        uint256 shareNumber = amountWei.mulDiv(priceUnits, price);
        uint256 comissionShare = shareNumber.mulDiv(buyComission, buyComissionUnits);
        return shareNumber.sub(comissionShare);
    }
   
    /**
     * Confirm all buys/sells
     */
    function confirmAllBuys() external onlyAdmin {
        while(buyOrder.length > 0) {
            _confirmOneBuy();
        }
    }
    function confirmAllSells() external onlyAdmin {
        while(sellOrder.length > 0) {
            _confirmOneSell();
        }
    }
   
    /**
     * Confirm one sell/buy (for problems fix)
     */
    function confirmOneBuy() external onlyAdmin {
        if(buyOrder.length > 0) {
            _confirmOneBuy();
        }
    }
    function confirmOneSell() external onlyAdmin {
        _confirmOneSell();
    }
    /**
     * Cancel one sell (for problem fix)
     */
    function cancelOneSell() internal {
        uint256 i = sellOrder.length-1;
        shareTransfer(address(this), sellOrder[i].user, sellOrder[i].shareNumber);
        sellOrderTotal -= sellOrder[i].shareNumber;
        delete sellOrder[sellOrder.length-1];
        sellOrder.length--;
    }
   
    /**
     * Internal buy/sell
     */
    function _confirmOneBuy() internal {
        uint256 i = buyOrder.length-1;
        uint256 amountWei = buyOrder[i].amountWei;
        uint256 shareNumber = weiToShare(amountWei);
        address user = buyOrder[i].user;
        shareTransfer(address(0), user, shareNumber);
        buyOrderTotal -= amountWei;
        delete buyOrder[buyOrder.length-1];
        buyOrder.length--;
    }
    function _confirmOneSell() internal {
        uint256 i = sellOrder.length-1;
        uint256 shareNumber = sellOrder[i].shareNumber;
        uint256 amountWei = shareToWei(shareNumber);
        address user = sellOrder[i].user;
        shareTransfer(address(this), address(0), shareNumber);
        sellOrderTotal -= shareNumber;
        user.transfer(amountWei);
        delete sellOrder[sellOrder.length-1];
        sellOrder.length--;
    }
}