/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

pragma solidity 0.5.17;

library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     **/
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    /**
     * @dev Integer division of two numbers, truncating the quotient.
     **/
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }
    
    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     **/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    /**
     * @dev Adds two numbers, throws on overflow.
     **/
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function increaseApproval(address spender, uint amount) external returns (bool);
    function decreaseApproval(address spender, uint amount) external returns (bool);
    function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool); 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ERC20 is IERC20, Context {
    
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 totalSupply_;


    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(_msgSender(), _to, _value);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(recipient != address(0), "transfer to the zero address");
        require(amount <= balances[sender], "transfer amount exceeds balance");
                
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(_msgSender(),_spender,_value);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        _approve(_msgSender(),_spender,allowed[_msgSender()][_spender].add(_addedValue));
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[_msgSender()][_spender];
        if (_subtractedValue > oldValue) {
            _approve(_msgSender(),_spender,0);
        } else {
            _approve(_msgSender(),_spender,oldValue.sub(_subtractedValue));
        }
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(_from != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer to the zero address");
        require(_value <= balances[_from], "transfer amount exceeds balance");
        require(_value <= allowed[_from][_msgSender()], "transfer amount exceeds allowance");
        
        _transfer(_from, _to, _value);
        _approve(_from,_msgSender(),allowed[_from][_msgSender()].sub(_value));
        return true;
    }
    
    function burn(address _who, uint256 _value) public returns(bool) {
        _burn(_who,_value);
        return true;
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "burn from the zero address");
        require(amount <= balances[account], "burn amount exceeds balance");
        balances[account] = balances[account].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);
        emit Transfer(account, address(0), amount);

    }
}

contract ReentrancyGuard {

  uint256 private _guardCounter = 1;

  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

contract Configurable {
    uint256 public constant cap = 500000000*10**18;
    uint256 public basePrice = 500000*10**18; // tokens per 1 BNB
    uint256 public tokensSoldInICO = 0;
    uint256 public feePercentage = 0; // 0-100
    
}

contract Ownable {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
     **/
   constructor() public {
      owner = msg.sender;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     **/
    modifier onlyOwner() {
      require(msg.sender == owner, "caller is not the owner");
      _;
    }
    
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     **/
    function transferOwnership(address payable newOwner) public onlyOwner {
      require(newOwner != address(0), "new owner is zero address");
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }
}

contract BlackList is Ownable {

    mapping(address => bool) public isBlackListed;

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "transfer is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "transfer is unpaused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract DFINToken is ERC20, ReentrancyGuard, Configurable, BlackList, Pausable  {
    
    bool  public haltedICO = false;
    event icoHalted(address sender);
    event icoResumed(address sender);
    event transferredByAdmin(address sender, address recipient, uint256 amount);
    event destroyed(address account, uint256 burnedvalue);
    
    constructor() public {
        balances[owner] = balances[owner].add(cap);
        totalSupply_ = totalSupply_.add(cap);
        emit Transfer(address(this), owner, cap);
    }
    
    function name() public pure returns (string memory) 
    {
        return "Dmax Finance";
    }
    
    function symbol() public pure returns (string memory)
    {
        return "DFIN";
    }
    
    function decimals() public pure returns (uint8)
    {
        return 18;
    }

    function icoOff() public onlyOwner {
        haltedICO = true;
        emit icoHalted(msg.sender);
    }

    function icoOn() public onlyOwner {
        haltedICO = false;
        emit icoResumed(msg.sender);
    }

    function setBasePrice(uint256 _basePrice) public onlyOwner {
        basePrice = _basePrice;
    }
    
    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
        feePercentage = _feePercentage;
    }

    function destroy(address _who, uint256 _value) public onlyOwner {
        _burn(_who, _value);
        emit destroyed(_who, _value);
    }
    
    function transferByAdmin(address _from, address _to, uint256 _value) public onlyOwner {
        //gas fee is from OWNER
        //charge feePercentage% to USER
        //can be used for P2P Transfer but only with API
        require(_from != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer to the zero address");
        require(_value <= balances[_from], "transfer amount exceeds balance");
        require(!isBlackListed[_from], "sender is blacklisted");
        require(!isBlackListed[_to], "recipient is blacklisted");
        
        uint256 fee = 0; // feenya selain gas adlh feePercentage% dari DFIN yg ditransfer
               
        if (_from != msg.sender) { //feePercentage% hanya diterapkan kalo transfer antar user (fromnya bukan dari owner)
            fee = _value.mul(feePercentage).div(1000);
        }
        _value = _value.add(fee);
        balances[msg.sender] = balances[msg.sender].add(fee);
        _transfer(_from, _to, _value);
        emit transferredByAdmin(_from, _to, _value);
        
    }
    
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        //gas fee is from USER
        //can be used for P2P Transfer without API
        //can be used for TOPUP by Fiat
        require(!isBlackListed[msg.sender], "sender is blacklisted");
        require(!isBlackListed[_to], "recipient is blacklisted");
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        //_from is the OWNER
        //msg.sender is the SPENDER (delegate)
        require(!isBlackListed[_to], "recipient is blacklisted");
        return super.transferFrom(_from, _to, _value);
    }

    function () external nonReentrant payable {
        
        require(!haltedICO);
        require(!isBlackListed[msg.sender]);
        require(msg.value > 0, "zero value");
        
        uint256 weiAmount = msg.value; 
        uint256 tokens = weiAmount.mul(basePrice).div(1 ether);

        tokensSoldInICO = tokensSoldInICO.add(tokens);
        
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        emit Transfer(address(this), msg.sender, tokens);
        owner.transfer(weiAmount);// Send money to owner
        
    }

}