/**
 *Submitted for verification at Etherscan.io on 2020-12-24
*/

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract BlackList is Owned {

    mapping (address=>bool) public _blacklist;

    /**
     * @notice lock account
     */
    function lockAccount(address _address) public onlyOwner{
        _blacklist[_address] = true;
    }

    /**
     * @notice Unlock account
     */
    function unlockAccount(address _address) public onlyOwner{
        _blacklist[_address] = false;
    }


    /**
     * @notice check address has in BlackList
     */
    function isLocked(address _address) public view returns(bool){
        return _blacklist[_address];
    }

}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
	}

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes calldata _extraData) external;
}

contract OKTOToken is ERC20('OKTO', 'OKTO', 18), ReentrancyGuard, Owned, BlackList {
    using SafeMath for uint256;
    uint256 public totalTokenSold;
    uint256 public eatherEarnedInCurrentRound;
    uint256 public totalEtherEarned;
    uint256 public currentRound = 0;  //currentRound = 0 means ICO didnt started yet; currentRound >= 3 ico ended
    bool public frozen = true;
    bool public buyableFlag = true;

    uint[] public milestone = [1, 108e18 , 297e18];
    uint[] public price = [0, 50000, 33333];
    uint256 public min = 0.2e18;
    uint256 public maxStep = 5e18;
    mapping(address=>mapping(uint256=>uint256)) balances;
    uint256 public upperCap;

    uint256 weight;

    constructor () public {
        _mint(address(this), 90000000 * 1e18);
        upperCap = 37800000 * 1e18;
    }

    function currentRoundPrice() public view returns (uint256) {
        if(currentRound>=price.length)
            return _postIcoPrice();
    	return price[currentRound];
    }

    function currentRoundVolume() public view returns (uint256) {
        if(currentRound>=price.length)
            return 0;
    	return milestone[currentRound]*price[currentRound];
    }

    function currentRoundMilestoneInEther() public view returns (uint256) {
        if(currentRound>=price.length)
            return 0;
    	return milestone[currentRound];
    }

    function tokensLeft() public view returns (uint256) {
        return upperCap.sub(totalTokenSold);
    }

    function _postIcoPrice() private view returns (uint256) {
        return price[price.length.sub(1)].div(2);
    }

    //section owner

    function freezeTokens() external onlyOwner() {
    	frozen = true;
    }

    function unfreezeTokens() external onlyOwner() {
    	frozen = false;
    }

    function stopSelling() public onlyOwner() {
        buyableFlag = false;
    }

    function continueSelling() public onlyOwner() {
        buyableFlag = true;
    }

    function nextRound() external onlyOwner() {
    	_nextRound();
    }

    function withdraw(address payable receiver, uint256 amount) public onlyOwner() nonReentrant() {
    	receiver.transfer(amount);
    }

    function donateTokens(address tokenRecipient, uint256 amount) public onlyOwner() {
    	_transfer(address(this), tokenRecipient, amount);
    }

    function setPrice(uint256 newPrice, uint256 round) public onlyOwner() {
    	require(_isRoundExists(round), "Wrong round number");
    	price[round] = newPrice;
    }

    function burnUnsold() public onlyOwner() {
    	_burn(address(this), balanceOf(address(this)));
    }

    //endsection


    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData) external returns (bool success)
    {
        approve(_spender, _value);
        TokenRecipient(_spender).receiveApproval(msg.sender, _value, address(this), _extraData);
        return true;
    }

    // section payable

    receive() external payable buyable() {
         _swapTokenForEhter(msg.sender,msg.value);
    }

    function buy() payable public buyable() {
        _swapTokenForEhter(msg.sender,msg.value);
    }

    //endsection

    function _swapTokenForEhter(address buyer, uint256 amount) private {
        require(amount >= min,"Less than the minimum purchase");

        uint256 _swapBalance = _calculateToken(buyer,amount);

        _transfer(address(this), buyer, _swapBalance);
        totalTokenSold = totalTokenSold.add(_swapBalance);
        totalEtherEarned = totalEtherEarned.add(amount);


        require(totalTokenSold<=upperCap, "No tokens left for selling");
    }

    function _calculateToken(address buyer, uint256 amount) private returns (uint256) {
        uint256 _price;
        uint256 res;
        uint256 localRound = currentRound;


        if(currentRound>=price.length)
    	{
    	    _price = _postIcoPrice();
    	}
        else

        {
            _price = price[currentRound];
            uint256 currentRoundMilestone = currentRoundMilestoneInEther();
            if(eatherEarnedInCurrentRound.add(amount) > currentRoundMilestone)
            {
                uint256 etherLeftForMilestone = currentRoundMilestone.sub(eatherEarnedInCurrentRound);
               	_nextRound();									//entering new round
            	res = res.add(_calculateToken(buyer, amount.sub(etherLeftForMilestone)));
            	amount = etherLeftForMilestone;
            }
            else
                eatherEarnedInCurrentRound = eatherEarnedInCurrentRound.add(amount);
        }

        balances[buyer][localRound] = balances[buyer][localRound].add(amount);
        if(localRound<price.length)
            require(balances[buyer][localRound]<=maxStep.mul(2**localRound.sub(1)),"More than the maximum purchase");

        res = res.add(amount.mul(_price));
        return res;
    }

    function _nextRound() private {
    	require(currentRound<=price.length, "No more rounds left");
    	currentRound = currentRound.add(1);
    	eatherEarnedInCurrentRound=0;
    }

    function _beforeTokenTransfer(address from, address, uint256) internal override {
    	require(!isLocked(from), "Sender is blacklisted");
    	if(from != address(this) && from != address(0))
    		require(!frozen, "Tokens are frozen");
    }

    function _isRoundExists(uint256 roundInQuestion) private view returns(bool) {
    	return roundInQuestion>0 && roundInQuestion<price.length;
    }

    modifier buyable() {
        require(currentRound>0, "Not opened for purchase");
        require(currentRound<=price.length, "All rounds of ico has been completed");
        require(buyableFlag, "Buyable flag is not set");
        _;
    }

}