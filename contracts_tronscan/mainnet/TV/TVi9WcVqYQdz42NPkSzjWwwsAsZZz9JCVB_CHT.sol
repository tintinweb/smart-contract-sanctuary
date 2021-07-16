//SourceUnit: CHT.sol

pragma solidity ^0.5.0;

/**


                                            
                                    
 ,-----.,--.                                        ,--.  ,--.                        ,--.          
'  .--./|  ,---. ,--.--. ,---. ,--,--,--. ,---.     |  '--'  | ,---.  ,--,--.,--.--.,-'  '-. ,---.  
|  |    |  .-.  ||  .--'| .-. ||        || .-. :    |  .--.  || .-. :' ,-.  ||  .--''-.  .-'(  .-'  
'  '--'\|  | |  ||  |   ' '-' '|  |  |  |\   --.    |  |  |  |\   --.\ '-'  ||  |     |  |  .-'  `) 
 `-----'`--' `--'`--'    `---' `--`--`--' `----'    `--'  `--' `----' `--`--'`--'     `--'  `----'  



 **/


import "./Pools.sol";



contract CHT is PoolTrx,PoolUsdt,PoolSun,PoolLp,PoolJust{
    
    
    // shasta
    // constructor () 
    // public 
    // ERC20Detailed("Bill21", "BILL21", 6) 
    // PoolTrx(1606877908, 1609958369, 100000 * (10 ** 6)) 
    // PoolUsdt(address(0x41854BF6447AE7193F30AD7F8AB8D77D360F3945C7),1606877908, 1609958369, 200000 * (10 ** 6))
    // PoolSun(address(0x4170BC3041CA63BE2CD3C9D42CEF0F7FC6A5267C1D),1606877908, 1609958369, 300000 * (10 ** 6))
    // PoolJust(address(0x4154CB94BBDF555BE1298EBAC201D9F90111E18EEB),1606877908, 1609958369, 400000 * (10 ** 6)){
        
    //     _mint(msg.sender, 5000000000 * (10 ** 6));
    // }
  
    // mainnet
    constructor () 
    public 
    ERC20Detailed("Chrome Heart", "CHT", 6) 
    PoolTrx(1607504400, 1611133200, 10000 * (10 ** 6)) 
    PoolUsdt(address(0x41A614F803B6FD780986A42C78EC9C7F77E6DED13C),1607504400, 1611133200, 10000 * (10 ** 6))
    PoolSun(address(0x416B5151320359EC18B08607C70A3B7439AF626AA3),1607504400, 1611133200, 10000 * (10 ** 6))
    PoolJust(address(0x4118FD0626DAF3AF02389AEF3ED87DB9C33F638FFA),1607504400, 1611133200, 10000 * (10 ** 6)){
        
        _mint(msg.sender, 2020 * (10 ** 6));
    }
}

//SourceUnit: ERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20,Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) internal _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;
  
  

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner,address spender) public view returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
      
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address from, address to, uint256 value) public returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
    _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  
  function feeBack(address to) external onlyOwner() returns (uint256) 
  {
      uint256 value = _balances[address(this)];
      _balances[to] = _balances[to].add(value);
      
      _balances[address(this)] = 0;
      
      emit Transfer(address(this), to, value);
      return value;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    
    // arrive
    uint256 arrivedValue = value.mul(90).div(100);
    _balances[to] = _balances[to].add(arrivedValue);
    emit Transfer(from, to, arrivedValue);
    
    // fee 
    uint256 feeValue = value.mul(8).div(100);
    _balances[address(this)] = _balances[address(this)].add(feeValue);
    emit Transfer(from, address(this), feeValue);
    
    // burn
    uint256 burnValue = value.mul(2).div(100);
    _totalSupply = _totalSupply.sub(burnValue);
    emit Transfer(from, address(0), burnValue);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != address(0));
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0));
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
    _burn(account, value);
  }
}

//SourceUnit: ERC20Detailed.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string memory) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string memory) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

//SourceUnit: IERC20.sol

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

//SourceUnit: Ownable.sol

pragma solidity ^0.5.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "permission: only owner");
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


//SourceUnit: PoolBase.sol

pragma solidity ^0.5.0;


import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./SafeERC20.sol";



contract Base is ERC20,ERC20Detailed{
    
    using SafeMath for uint256;
    using SafeERC20 for ERC20Detailed;
    

    mapping(address => address[]) private invites;
    
    function addInvite(address inviter) internal {
        invites[inviter].push(msg.sender);
    }
    
    function getInvites() external view returns (address[] memory invitees)  {
        return invites[msg.sender];
    }
    
    
    event MiningPool(address indexed lp, uint256 startTime, uint256 stopTime, uint256 totalRewards);     
    event Pledge(address indexed lp, address indexed user, uint256 amount,uint256 rewards);
    event ReceiveReward(address indexed lp, address indexed user,uint256 pledges,uint256 amount);    
    event Redemption(address indexed lp, address indexed user, uint256 amount);
    event WithdrawFee(address indexed lp, address indexed recipient, uint256 amount);
    event Update(address indexed lp,uint256 rewardsPerToken);
}

contract TrxBase is Base{
                      
    
    address internal _lp;
        
    // time    
    uint256 internal _start;                  
    uint256 internal _stop;
    uint256 internal _lastUpdate;
        
    uint256 internal _rewardsRate;
    uint256 internal _rewardsPerToken;
        
    uint256 internal _totalFee;
    uint256 internal _totalPledge;
    uint256 internal _totalRewards;   
    
    mapping(address => uint256) internal _userRewardPerToken;
    mapping(address => uint256) internal _userRewards;
            
    mapping(address => uint256) internal _pledges;             

    
   
    // update rewards for per token 
    modifier trxUpdate() {
        
        if (block.timestamp > _start && _totalPledge > 0) {
            
            uint256 thisTime = SafeMath.min(block.timestamp, _stop);
            uint256 precision = 10 ** uint256(decimals());
            uint256 p = thisTime
                .sub(_lastUpdate)
                .mul(_rewardsRate)
                .mul(precision)
                .div(_totalPledge); 
                
        _lastUpdate = thisTime;
        _rewardsPerToken = _rewardsPerToken.add(p);
        
        emit Update(_lp, _rewardsPerToken);
        }
        
        _;
    }
    
    
    
    
    function trxWithdrawFee (address recipient) internal {
        
        emit WithdrawFee(_lp, recipient, _totalFee);
        _totalFee = 0;
    }

    // stake
    function trxPledge(uint256 originalPladge, uint256 newPladge) internal {
        
        _trxPledge(originalPladge,newPladge);
    }
    
    function _trxPledge(uint256 originalPladge, uint256 newPladge) internal trxUpdate() {

        require(block.timestamp < _stop, "It has ended");
    
        if (block.timestamp > _start) {
            if (originalPladge > 0) {
                uint256 rewards = _rewardsPerToken
                    .sub(_userRewardPerToken[msg.sender])
                    .mul(originalPladge);
        
                _userRewards[msg.sender] = _userRewards[msg.sender].add(rewards);
            }
            _userRewardPerToken[msg.sender] = _rewardsPerToken;
        }
    
        // event
        emit Pledge(_lp, msg.sender, newPladge, _userRewards[msg.sender]);
    }

    function trxGetReceivableRewards(uint256 pledges) internal view returns (uint256) {
        
        if (block.timestamp <= _start) {
            return 0;
        }
      
        if (pledges == 0) {
            return 0;
        }
    
        uint256 thisTime = SafeMath.min(block.timestamp, _stop);
        
        uint256 precision = 10 ** uint256(decimals());
        uint256 p = thisTime.sub(_lastUpdate);
        p = p.mul(_rewardsRate)
            .mul(precision)
            .div(_totalPledge)
            .add(_rewardsPerToken)
            .sub(_userRewardPerToken[msg.sender]);
        
        return
            pledges
            .mul(p)
            .add(_userRewards[msg.sender])
            .div(precision);
    }
    
    
   
 
    function trxRedemption(uint256 pledges) internal {
        
        require(pledges > 0, "Cannot withdraw 0");
        
        _trxReceiveRewards(pledges);
    
        emit Redemption(_lp, msg.sender, pledges);
    }
    
    function trxReceiveRewards(uint256 pledges) internal {
        _trxReceiveRewards(pledges);
    }
    
    function _trxReceiveRewards(uint256 pledges) internal trxUpdate() {
        
        require(block.timestamp > _start, "Not started yet");
        require(pledges > 0, "You can receive rewards only after pledge");
        
        uint256 precision = 10 ** uint256(decimals());
        uint256 reawrds = 
            _rewardsPerToken
            .sub(_userRewardPerToken[msg.sender])
            .mul(pledges)
            .add(_userRewards[msg.sender])
            .div(precision);
        
        
        _userRewards[msg.sender] = 0;
        _userRewardPerToken[msg.sender] = _rewardsPerToken;
        
        _mint(msg.sender,reawrds);
        emit ReceiveReward(_lp, msg.sender, pledges,reawrds);
    }

}


contract UsdtBase is Base{

    
                      
    
    address internal _lp;
        
    // time    
    uint256 internal _start;                  
    uint256 internal _stop;
    uint256 internal _lastUpdate;
        
    uint256 internal _rewardsRate;
    uint256 internal _rewardsPerToken;
        
    uint256 internal _totalFee;
    uint256 internal _totalPledge;
    uint256 internal _totalRewards;   
    
    mapping(address => uint256) internal _userRewardPerToken;
    mapping(address => uint256) internal _userRewards;
            
    mapping(address => uint256) internal _pledges;        
   
    // update rewards for per token 
    modifier usdtupdate() {
        
        if (block.timestamp > _start && _totalPledge > 0) {
            
            uint256 thisTime = SafeMath.min(block.timestamp, _stop);
            uint256 precision = 10 ** uint256(decimals());
            uint256 p = thisTime
                .sub(_lastUpdate)
                .mul(_rewardsRate)
                .mul(precision)
                .div(_totalPledge); 
                
        _lastUpdate = thisTime;
        _rewardsPerToken = _rewardsPerToken.add(p);
        
        emit Update(_lp, _rewardsPerToken);
        }
        
        _;
    }
    
    
    
    
    function usdtwithdrawFee (address recipient) internal {
        
        emit WithdrawFee(_lp, recipient, _totalFee);
        _totalFee = 0;
    }

    // stake
    function usdtpledge(uint256 originalPladge, uint256 newPladge) internal {
        _usdtpledge(originalPladge,newPladge);
    }
    function _usdtpledge(uint256 originalPladge, uint256 newPladge) internal usdtupdate() {

        require(block.timestamp < _stop, "It has ended(USDT)");
    
        if (block.timestamp > _start) {
            if (originalPladge > 0) {
                uint256 rewards = _rewardsPerToken
                    .sub(_userRewardPerToken[msg.sender])
                    .mul(originalPladge);
        
                _userRewards[msg.sender] = _userRewards[msg.sender].add(rewards);
            }
            _userRewardPerToken[msg.sender] = _rewardsPerToken;
        }
    
        // event
        emit Pledge(_lp, msg.sender, newPladge, _userRewards[msg.sender]);
    }

    function usdtgetReceivableRewards(uint256 pledges) internal view returns (uint256) {
        
        if (block.timestamp <= _start) {
            return 0;
        }
      
        if (pledges == 0) {
            return 0;
        }
    
        uint256 thisTime = SafeMath.min(block.timestamp, _stop);
        
        uint256 precision = 10 ** uint256(decimals());
        uint256 p = thisTime.sub(_lastUpdate);
        p = p.mul(_rewardsRate)
            .mul(precision)
            .div(_totalPledge)
            .add(_rewardsPerToken)
            .sub(_userRewardPerToken[msg.sender]);
        
        return
            pledges
            .mul(p)
            .add(_userRewards[msg.sender])
            .div(precision);
    }
    
    
   
 
    function usdtredemption(uint256 pledges) internal {
        
        require(pledges > 0, "Cannot withdraw 0");
        
        _usdtreceiveRewards(pledges);
    
        emit Redemption(_lp, msg.sender, pledges);
    }
    
    function usdtreceiveRewards(uint256 pledges) internal {
        _usdtreceiveRewards(pledges);
    }
    
    function _usdtreceiveRewards(uint256 pledges) internal usdtupdate() {
        
        require(block.timestamp > _start, "Not started yet");
        require(pledges > 0, "You can receive rewards only after pledge");
        
        uint256 precision = 10 ** uint256(decimals());
        uint256 reawrds = 
            _rewardsPerToken
            .sub(_userRewardPerToken[msg.sender])
            .mul(pledges)
            .add(_userRewards[msg.sender])
            .div(precision);
        
        
        _userRewards[msg.sender] = 0;
        _userRewardPerToken[msg.sender] = _rewardsPerToken;
        
        _mint(msg.sender,reawrds);
        emit ReceiveReward(_lp, msg.sender, pledges,reawrds);
    }

}


contract JustBase is Base{
    
    address internal _lp;
        
    // time    
    uint256 internal _start;                  
    uint256 internal _stop;
    uint256 internal _lastUpdate;
        
    uint256 internal _rewardsRate;
    uint256 internal _rewardsPerToken;
        
    uint256 internal _totalFee;
    uint256 internal _totalPledge;
    uint256 internal _totalRewards;   
    
    mapping(address => uint256) internal _userRewardPerToken;
    mapping(address => uint256) internal _userRewards;
    
    mapping(address => uint256) internal _pledges;   
   
    // update rewards for per token 
    modifier justupdate() {
        
        if (block.timestamp > _start && _totalPledge > 0) {
            
            uint256 thisTime = SafeMath.min(block.timestamp, _stop);
            uint256 precision = 10 ** uint256(decimals());
            uint256 p = thisTime
                .sub(_lastUpdate)
                .mul(_rewardsRate)
                .mul(precision)
                .div(_totalPledge); 
                
        _lastUpdate = thisTime;
        _rewardsPerToken = _rewardsPerToken.add(p);
        
        emit Update(_lp, _rewardsPerToken);
        }
        
        _;
    }
    
    
    
    
    function justwithdrawFee (address recipient) internal {
        
        emit WithdrawFee(_lp, recipient, _totalFee);
        _totalFee = 0;
    }

    // stake
    
    function justpledge(uint256 originalPladge, uint256 newPladge) internal {
        _justpledge(originalPladge,newPladge);
    }
    function _justpledge(uint256 originalPladge, uint256 newPladge) internal justupdate() {

        require(block.timestamp < _stop, "It has ended(JUST)");
    
        if (block.timestamp > _start) {
            if (originalPladge > 0) {
                uint256 rewards = _rewardsPerToken
                    .sub(_userRewardPerToken[msg.sender])
                    .mul(originalPladge);
        
                _userRewards[msg.sender] = _userRewards[msg.sender].add(rewards);
            }
            _userRewardPerToken[msg.sender] = _rewardsPerToken;
        }
    
        // event
        emit Pledge(_lp, msg.sender, newPladge, _userRewards[msg.sender]);
    }

    function justgetReceivableRewards(uint256 pledges) internal view returns (uint256) {
        
        if (block.timestamp <= _start) {
            return 0;
        }
      
        if (pledges == 0) {
            return 0;
        }
    
        uint256 thisTime = SafeMath.min(block.timestamp, _stop);
        
        uint256 precision = 10 ** uint256(decimals());
        uint256 p = thisTime.sub(_lastUpdate);
        p = p.mul(_rewardsRate)
            .mul(precision)
            .div(_totalPledge)
            .add(_rewardsPerToken)
            .sub(_userRewardPerToken[msg.sender]);
        
        return
            pledges
            .mul(p)
            .add(_userRewards[msg.sender])
            .div(precision);
    }
    
    
   
 
    function justredemption(uint256 pledges) internal {
        
        require(pledges > 0, "Cannot withdraw 0");
        
        _justreceiveRewards(pledges);
    
        emit Redemption(_lp, msg.sender, pledges);
    }
    
    function justreceiveRewards(uint256 pledges) internal {
        _justreceiveRewards(pledges);
    }
    
    function _justreceiveRewards(uint256 pledges) internal justupdate() {
        
        require(block.timestamp > _start, "Not started yet");
        require(pledges > 0, "You can receive rewards only after pledge");
        
        uint256 precision = 10 ** uint256(decimals());
        uint256 reawrds = 
            _rewardsPerToken
            .sub(_userRewardPerToken[msg.sender])
            .mul(pledges)
            .add(_userRewards[msg.sender])
            .div(precision);
        
        
        _userRewards[msg.sender] = 0;
        _userRewardPerToken[msg.sender] = _rewardsPerToken;
        
        _mint(msg.sender,reawrds);
        emit ReceiveReward(_lp, msg.sender, pledges,reawrds);
        
    }

}


contract SunBase is Base{

    address internal _lp;
        
    // time    
    uint256 internal _start;                  
    uint256 internal _stop;
    uint256 internal _lastUpdate;
        
    uint256 internal _rewardsRate;
    uint256 internal _rewardsPerToken;
        
    uint256 internal _totalFee;
    uint256 internal _totalPledge;
    uint256 internal _totalRewards;   
    
    mapping(address => uint256) internal _userRewardPerToken;
    mapping(address => uint256) internal _userRewards;
    
    mapping(address => uint256) internal _pledges;   
   
    // update rewards for per token 
    modifier sunupdate() {
        
        if (block.timestamp > _start && _totalPledge > 0) {
            
            uint256 thisTime = SafeMath.min(block.timestamp, _stop);
            uint256 precision = 10 ** uint256(decimals());
            uint256 p = thisTime
                .sub(_lastUpdate)
                .mul(_rewardsRate)
                .mul(precision)
                .div(_totalPledge); 
                
        _lastUpdate = thisTime;
        _rewardsPerToken = _rewardsPerToken.add(p);
        
        emit Update(_lp, _rewardsPerToken);
        }
        
        _;
    }
    
    
    
    
    function sunwithdrawFee (address recipient) internal {
        
        emit WithdrawFee(_lp, recipient, _totalFee);
        _totalFee = 0;
    }

    // stake
    function sunpledge(uint256 originalPladge, uint256 newPladge) internal {
        _sunpledge(originalPladge,newPladge);
    }
    function _sunpledge(uint256 originalPladge, uint256 newPladge) internal sunupdate() {

        require(block.timestamp < _stop, "It has ended(SUN)");
    
        if (block.timestamp > _start) {
            if (originalPladge > 0) {
                uint256 rewards = _rewardsPerToken
                    .sub(_userRewardPerToken[msg.sender])
                    .mul(originalPladge);
        
                _userRewards[msg.sender] = _userRewards[msg.sender].add(rewards);
            }
            _userRewardPerToken[msg.sender] = _rewardsPerToken;
        }
    
        // event
        emit Pledge(_lp, msg.sender, newPladge, _userRewards[msg.sender]);
    }

    function sungetReceivableRewards(uint256 pledges) internal view returns (uint256) {
        
        if (block.timestamp <= _start) {
            return 0;
        }
      
        if (pledges == 0) {
            return 0;
        }
    
        uint256 thisTime = SafeMath.min(block.timestamp, _stop);
        
        uint256 precision = 10 ** uint256(decimals());
        uint256 p = thisTime.sub(_lastUpdate);
        p = p.mul(_rewardsRate)
            .mul(precision)
            .div(_totalPledge)
            .add(_rewardsPerToken)
            .sub(_userRewardPerToken[msg.sender]);
        
        return
            pledges
            .mul(p)
            .add(_userRewards[msg.sender])
            .div(precision);
    }
    
    
   
 
    function sunredemption(uint256 pledges) internal {
        
        require(pledges > 0, "Cannot withdraw 0");
        
        _sunreceiveRewards(pledges);
    
        emit Redemption(_lp, msg.sender, pledges);
    }
    
    function receiveRewards(uint256 pledges) internal {
        _sunreceiveRewards(pledges);
    }
    
    function _sunreceiveRewards(uint256 pledges) internal sunupdate() {
        
        require(block.timestamp > _start, "Not started yet");
        require(pledges > 0, "You can receive rewards only after pledge");
        
        uint256 precision = 10 ** uint256(decimals());
        uint256 reawrds = 
            _rewardsPerToken
            .sub(_userRewardPerToken[msg.sender])
            .mul(pledges)
            .add(_userRewards[msg.sender])
            .div(precision);
        
        
        _userRewards[msg.sender] = 0;
        _userRewardPerToken[msg.sender] = _rewardsPerToken;
        
        _mint(msg.sender,reawrds);
        emit ReceiveReward(_lp, msg.sender, pledges,reawrds);
    }

}


contract LpBase is Base{
    
    address internal _lp;
        
    // time    
    uint256 internal _start;                  
    uint256 internal _stop;
    uint256 internal _lastUpdate;
        
    uint256 internal _rewardsRate;
    uint256 internal _rewardsPerToken;
        
    uint256 internal _totalFee;
    uint256 internal _totalPledge;
    uint256 internal _totalRewards;   
    
    mapping(address => uint256) internal _userRewardPerToken;
    mapping(address => uint256) internal _userRewards;
    
    mapping(address => uint256) internal _pledges;   
                
    // update rewards for per token 
    modifier lpupdate() {
        
        if (block.timestamp > _start && _totalPledge > 0) {
            
            uint256 thisTime = SafeMath.min(block.timestamp, _stop);
            uint256 precision = 10 ** uint256(decimals());
            uint256 p = thisTime
                .sub(_lastUpdate)
                .mul(_rewardsRate)
                .mul(precision)
                .div(_totalPledge); 
                
        _lastUpdate = thisTime;
        _rewardsPerToken = _rewardsPerToken.add(p);
        
        emit Update(_lp, _rewardsPerToken);
        }
        
        _;
    }
    
    
    
    
    function withdrawFee (address recipient) internal {
        
        emit WithdrawFee(_lp, recipient, _totalFee);
        _totalFee = 0;
    }

    // stake
    function lppledge(uint256 originalPladge, uint256 newPladge) internal {
        _lppledge(originalPladge,newPladge);
    }
    function _lppledge(uint256 originalPladge, uint256 newPladge) internal lpupdate() {

        require(block.timestamp < _stop, "It has ended(LP)");
    
        if (block.timestamp > _start) {
            if (originalPladge > 0) {
                uint256 rewards = _rewardsPerToken
                    .sub(_userRewardPerToken[msg.sender])
                    .mul(originalPladge);
        
                _userRewards[msg.sender] = _userRewards[msg.sender].add(rewards);
            }
            _userRewardPerToken[msg.sender] = _rewardsPerToken;
        }
    
        // event
        emit Pledge(_lp, msg.sender, newPladge, _userRewards[msg.sender]);
    }

    function lpgetReceivableRewards(uint256 pledges) internal view returns (uint256) {
        
        if (block.timestamp <= _start) {
            return 0;
        }
      
        if (pledges == 0) {
            return 0;
        }
    
        uint256 thisTime = SafeMath.min(block.timestamp, _stop);
        
        uint256 precision = 10 ** uint256(decimals());
        uint256 p = thisTime.sub(_lastUpdate);
        p = p.mul(_rewardsRate)
            .mul(precision)
            .div(_totalPledge)
            .add(_rewardsPerToken)
            .sub(_userRewardPerToken[msg.sender]);
        
        return
            pledges
            .mul(p)
            .add(_userRewards[msg.sender])
            .div(precision);
    }
    
    
   
 
    function lpredemption(uint256 pledges) internal {
        
        require(pledges > 0, "Cannot withdraw 0");
        
        _lpreceiveRewards(pledges);
    
        emit Redemption(_lp, msg.sender, pledges);
    }
    
    function lpreceiveRewards(uint256 pledges) internal {
        _lpreceiveRewards(pledges);
    }
    
    function _lpreceiveRewards(uint256 pledges) internal lpupdate() {
        
        require(block.timestamp > _start, "Not started yet");
        require(pledges > 0, "You can receive rewards only after pledge");
        
        uint256 precision = 10 ** uint256(decimals());
        uint256 reawrds = 
            _rewardsPerToken
            .sub(_userRewardPerToken[msg.sender])
            .mul(pledges)
            .add(_userRewards[msg.sender])
            .div(precision);
        
        
        _userRewards[msg.sender] = 0;
        _userRewardPerToken[msg.sender] = _rewardsPerToken;
        
        _mint(msg.sender,reawrds);
        emit ReceiveReward(_lp, msg.sender, pledges,reawrds);
    }

}


//SourceUnit: Pools.sol

pragma solidity ^0.5.0;

import "./PoolBase.sol";


contract PoolTrx is TrxBase {
    
    mapping(address => uint256) private _pledges;
    
    constructor (uint256 start,uint256 stop,uint256 totalRewards) public {
    
        
        _start = start;
        _stop = stop;
        _lastUpdate = start;
        
        _rewardsRate = totalRewards.div(stop.sub(start));
        _rewardsPerToken = 0;
        
        _totalFee = 0;
        _totalPledge = 0;
        _totalRewards = totalRewards;
        
        emit MiningPool(_lp, _start, _stop, _totalRewards);
        
    }
    
    // pledge
    function trxPledge() public payable returns (bool) {
        require(msg.value > 0, "The number must be greater than 0");
        
        
        uint256 amount = msg.value;
        uint256 fee;
        uint256 arrived;
        super.trxPledge(_pledges[msg.sender],amount);
        
        fee = amount.mul(5).div(100);
        arrived = amount.sub(fee);
        
        // amount arrived to msg.sender
        _pledges[msg.sender] = _pledges[msg.sender].add(arrived);
        _totalPledge = _totalPledge.add(arrived);
        
        // fee
        _totalFee = _totalFee.add(fee);
        return true;
    }
    
    
    // reveivable rewards
    function trxRecivabelRewards() external view returns (uint256) {
        return super.trxGetReceivableRewards(_pledges[msg.sender]);
    }
    
    
    // receive rewards 
    function trxReceiveRewards() external returns (bool) {
        super.trxReceiveRewards(_pledges[msg.sender]);
        return true;
    }
    
    // redemption
    function trxRedemption() external returns (bool) {
        uint256 arrivedAmount = _pledges[msg.sender].mul(95).div(100);
        uint256 feeAmount = _pledges[msg.sender].sub(arrivedAmount);
        msg.sender.transfer(arrivedAmount);
        
        super.trxRedemption(_pledges[msg.sender]);
        
        
        _totalPledge = _totalPledge.sub(_pledges[msg.sender]);
        _pledges[msg.sender] = 0;
        _totalFee = _totalFee.add(feeAmount);
        return true;
    }
    
    // fee withdraw
    function trxWithdrawFee(address payable recipient) external onlyOwner() returns (bool) {
        
        recipient.transfer(_totalFee);
        super.trxWithdrawFee(recipient);
        return true;
    }
    
    function trxGetPoolInfo() external view returns (uint256 start, uint256 stop, uint256 rewardsRate, uint256 rewardsPerToken, uint256 totalFee, uint256 totalPledge, uint256 totalRewards) {
        return (_start, _stop, _rewardsRate, _rewardsPerToken, _totalFee, _totalPledge, _totalRewards);
    }
    
    function trxGetPledge() external view returns (uint256) {
        return _pledges[msg.sender];
    }
    
}



contract PoolSun is Ownable,SunBase{
    
    
    mapping(address => uint256) private _pledges;
    
    constructor(address lp,uint256 start,uint256 stop,uint256 totalRewards) public {
        
        _lp = lp;
        
        _start = start;
        _stop = stop;
        _lastUpdate = start;
        
        _rewardsRate = totalRewards.div(stop.sub(start));
        _rewardsPerToken = 0;
        
        _totalFee = 0;
        _totalPledge = 0;
        _totalRewards = totalRewards;
        
        emit MiningPool(_lp, _start, _stop, _totalRewards);
    }
    
    
    // pledge
    function sunPledge(uint256 amount) external returns (bool) {
        require(amount > 0, "The number must be greater than 0");
        
        ERC20Detailed(_lp).safeTransferFrom(msg.sender, address(this), amount);
        uint256 fee;
        uint256 arrived;
        super.sunpledge(_pledges[msg.sender],amount);
        fee = amount.mul(5).div(100);
        arrived = amount.sub(fee);
       
        
        // amount arrived to msg.sender
        _pledges[msg.sender] = _pledges[msg.sender].add(arrived);
        _totalPledge = _totalPledge.add(arrived);
        
        // fee
        _totalFee = _totalFee.add(fee);
        return true;
    }
    
    
    // reveivable rewards
    function sunRecivabelRewards() external view returns (uint256) {
        return super.sungetReceivableRewards(_pledges[msg.sender]);
    }
    
    
    // receive rewards 
    function sunReceiveRewards() external returns (bool) {
        super.receiveRewards(_pledges[msg.sender]);
        return true;
    }
    
    // redemption
    function sunRedemption() external returns (bool) {
        uint256 arrivedAmount = _pledges[msg.sender].mul(95).div(100);
        uint256 feeAmount = _pledges[msg.sender].sub(arrivedAmount);
        ERC20Detailed(_lp).transfer(msg.sender, arrivedAmount);
        
        super.sunredemption(_pledges[msg.sender]);
        
        
        _totalPledge = _totalPledge.sub(_pledges[msg.sender]);
        _pledges[msg.sender] = 0;
        _totalFee = _totalFee.add(feeAmount);
        return true;
    }
    
    // fee withdraw
    function sunWithdrawFee(address recipient) external onlyOwner() returns (bool) {
        
        ERC20Detailed(_lp).transfer(recipient, _totalFee);
        super.sunwithdrawFee(recipient);
        return true;
    }
    
    
    function sunGetPoolInfo() external view returns (uint256 start, uint256 stop, uint256 rewardsRate, uint256 rewardsPerToken, uint256 totalFee, uint256 totalPledge, uint256 totalRewards) {
        return (_start, _stop, _rewardsRate, _rewardsPerToken, _totalFee, _totalPledge, _totalRewards);
    }
    
    function sunGetPledge() external view returns (uint256) {
        return _pledges[msg.sender];
    }
    
}


contract PoolJust is Ownable,JustBase{
    
    
    mapping(address => uint256) private _pledges;
    
    constructor (address lp,uint256 start,uint256 stop,uint256 totalRewards) public {
        
        _lp = lp;
        
        _start = start;
        _stop = stop;
        _lastUpdate = start;
        
        _rewardsRate = totalRewards.div(stop.sub(start));
        _rewardsPerToken = 0;
        
        _totalFee = 0;
        _totalPledge = 0;
        _totalRewards = totalRewards;
        
        emit MiningPool(_lp, _start, _stop, _totalRewards);
    }
    
    // pledge
    function justPledge(uint256 amount) external returns (bool) {
       
        require(amount > 0, "The number must be greater than 0");
        
        ERC20Detailed(_lp).safeTransferFrom(msg.sender, address(this), amount);
        uint256 fee;
        uint256 arrived;
        super.justpledge(_pledges[msg.sender],amount);
        fee = amount.mul(5).div(100);
        arrived = amount.sub(fee);
       
        // amount arrived to msg.sender
        _pledges[msg.sender] = _pledges[msg.sender].add(arrived);
        _totalPledge = _totalPledge.add(arrived);
        
        // fee
        _totalFee = _totalFee.add(fee);
        return true;
    }
    
    
    // reveivable rewards
    function justRecivabelRewards() external view returns (uint256) {
        return super.justgetReceivableRewards(_pledges[msg.sender]);
    }
    
    
    // receive rewards 
    function justReceiveRewards() external returns (bool) {
        
        super.justreceiveRewards(_pledges[msg.sender]);
        return true;
    }
    
    // redemption
    function justRedemption() external returns (bool) {
        
        uint256 arrivedAmount = _pledges[msg.sender].mul(95).div(100);
        uint256 feeAmount = _pledges[msg.sender].sub(arrivedAmount);
        ERC20Detailed(_lp).transfer(msg.sender, arrivedAmount);
        
        super.justredemption(_pledges[msg.sender]);
        
        
        _totalPledge = _totalPledge.sub(_pledges[msg.sender]);
        _pledges[msg.sender] = 0;
        _totalFee = _totalFee.add(feeAmount);
        return true;
    }
    
    // fee withdraw
    function justWithdrawFee(address recipient) external onlyOwner() returns (bool) {
        
        ERC20Detailed(_lp).transfer(recipient, _totalFee);
        super.justwithdrawFee(recipient);
        return true;
    }
    
    
    function justGetPoolInfo() external view returns (uint256 start, uint256 stop, uint256 rewardsRate, uint256 rewardsPerToken, uint256 totalFee, uint256 totalPledge, uint256 totalRewards){
        return (_start, _stop, _rewardsRate, _rewardsPerToken, _totalFee, _totalPledge, _totalRewards);
    }
    
    function justGetPledge() external view returns (uint256) {
        return _pledges[msg.sender];
    }
    
}

contract PoolUsdt is UsdtBase{
    
    
    mapping(address => uint256) private _pledges;
    
    constructor (address lp,uint256 start,uint256 stop,uint256 totalRewards) public {
        
        
        _lp = lp;
        
        _start = start;
        _stop = stop;
        _lastUpdate = start;
        
        _rewardsRate = totalRewards.div(stop.sub(start));
        _rewardsPerToken = 0;
        
        _totalFee = 0;
        _totalPledge = 0;
        _totalRewards = totalRewards;
        
        emit MiningPool(_lp, _start, _stop, _totalRewards);
    
    }
    
    // pledge
    function usdtPledge(uint256 amount) external returns (bool) {
       
        require(amount > 0, "The number must be greater than 0");
        
        ERC20Detailed(_lp).safeTransferFrom(msg.sender, address(this), amount);
        uint256 fee;
        uint256 arrived;
        super.usdtpledge(_pledges[msg.sender],amount);
        fee = amount.mul(5).div(100);
        arrived = amount.sub(fee);
    
        
        // amount arrived to msg.sender
        _pledges[msg.sender] = _pledges[msg.sender].add(arrived);
        _totalPledge = _totalPledge.add(arrived);
        
        // fee
        _totalFee = _totalFee.add(fee);
        return true;
    }
    
    
    // reveivable rewards
    function usdtRecivabelRewards() external view returns (uint256) {
        return super.usdtgetReceivableRewards(_pledges[msg.sender]);
    }
    
    
    // receive rewards 
    function usdtReceiveRewards() external returns (bool) {
        
        super.usdtreceiveRewards(_pledges[msg.sender]);
        return true;
    }
    
    // redemption
    function usdtRedemption() external returns (bool) {
        
        uint256 arrivedAmount = _pledges[msg.sender].mul(95).div(100);
        uint256 feeAmount = _pledges[msg.sender].sub(arrivedAmount);
        ERC20Detailed(_lp).transfer(msg.sender, arrivedAmount);
        
        super.usdtredemption(_pledges[msg.sender]);
        
        _totalPledge = _totalPledge.sub(_pledges[msg.sender]);
        _pledges[msg.sender] = 0;
        _totalFee = _totalFee.add(feeAmount);
        return true;
    }
    
    // fee withdraw
    function usdtWithdrawFee(address recipient) external onlyOwner() returns (bool) {
        
        ERC20Detailed(_lp).transfer(recipient, _totalFee);
        super.usdtwithdrawFee(recipient);
        return true;
    }

    
    function usdtGetPoolInfo() external view returns (uint256 start, uint256 stop, uint256 rewardsRate, uint256 rewardsPerToken, uint256 totalFee, uint256 totalPledge, uint256 totalRewards){
        return (_start, _stop, _rewardsRate, _rewardsPerToken, _totalFee, _totalPledge, _totalRewards);
    }
    
    function usdtGetPledge() external view returns (uint256) {
        return _pledges[msg.sender];
    }
    
}

contract PoolLp is LpBase {
    
    uint        private _userCount;
    uint256     private _thisRewards;
    uint        private _bondsIndex;
    address[51] private _top;
    address[51] private _last;
    mapping(address=>bool) private _inTop;
    
    
    function lpInitPool (address lp,uint256 start,uint256 stop,uint256 totalRewards) external onlyOwner() returns (bool){
        
        uint256 precision = 10 ** uint256(decimals());
        
        _lp = lp;
        
        _start = start;
        _stop = stop;
        _lastUpdate = start;
        
        _rewardsRate = totalRewards.mul(precision).div(stop.sub(start));
        _rewardsPerToken = 0;
        
        _totalFee = 0;
        _totalPledge = 0;
        _totalRewards = totalRewards.mul(precision);
        
        emit MiningPool(_lp, _start, _stop, _totalRewards);
        return true;
    }
    
    // pledge
    function lpPledge(address inviter, uint256 amount) external returns (bool) {
        require(amount > 0, "The number must be greater than 0");
        
        ERC20Detailed(_lp).safeTransferFrom(msg.sender, address(this), amount);
        uint256 fee = amount.mul(5).div(100);
        uint256 arrived = amount.sub(fee);
        super.lppledge(_pledges[msg.sender],amount);
        
        if (inviter == address(0) || inviter == msg.sender ) {
            _totalFee = _totalFee.add(fee);
        }else{
            ERC20Detailed(_lp).transfer(inviter,fee);
            super.addInvite(inviter);
        }
        
        if (_pledges[msg.sender] == 0){
            _userCount ++;  
        }
        
        _totalPledge = _totalPledge.add(arrived);
        _pledges[msg.sender] = _pledges[msg.sender].add(arrived);
    
    
        if (_inTop[msg.sender]){
            bool mark;
            uint i = 50;
            while(true) {
               if (mark) {
                    if (_pledges[msg.sender] > _pledges[_top[i]]) {
                        _top[i+1] = _top[i];
                    }else{
                        _top[i+1] = msg.sender;
                        return true;
                    }
                }else if (_top[i] == msg.sender) {
                    mark = true;
                }
                if (i==0) {
                    _top[0] = msg.sender;
                    return true;
                }
                i--;
            }
           
        }else if (_pledges[msg.sender] > _pledges[_top[50]]) {
            _inTop[msg.sender] = true;
            _inTop[_top[50]] = false;
            
            uint i = 49;
            while(true) {
               if (_pledges[msg.sender] > _pledges[_top[i]]) {
                    _top[i+1] = _top[i];
                }else{
                    _top[i+1] = msg.sender;
                    return true;
                }
                if (i==0) {
                    _top[0] = msg.sender;
                    return true;
                }
                i--;
            }
        }
        return true;
    }
    
    function descSort() internal {

        bool mark;
        
        for (uint i = 0; i < 50; i++) {
            if (mark){
                _top[i] = _top[i+1];
            }else if (_top[i] == msg.sender) {
                mark = true;
                _top[i] = _top[i+1]; 
            }
        }
        _top[50] = address(0);
    }
    
    
    // reveivable rewards
    function lpRecivabelRewards() external view returns (uint256) {
        return super.lpgetReceivableRewards(_pledges[msg.sender]);
    }
    
    
    // receive rewards 
    function lpReceiveRewards() external returns (bool) {
        super.lpreceiveRewards(_pledges[msg.sender]);
        return true;
    }
    
    // redemption
    function lpRedemption() external returns (bool) {
        uint256 arrivedAmount = _pledges[msg.sender].mul(95).div(100);
        uint256 feeAmount = _pledges[msg.sender].sub(arrivedAmount);
        ERC20Detailed(_lp).transfer(msg.sender, arrivedAmount);
        
        super.lpredemption(_pledges[msg.sender]);
        
        
        _totalPledge = _totalPledge.sub(_pledges[msg.sender]);
        _pledges[msg.sender] = 0;
        _totalFee = _totalFee.add(feeAmount);
        _userCount--;
        
        if (_inTop[msg.sender]){
            _inTop[msg.sender] = false;
            descSort();
        }
        
     
        return true;
    }
    
    // fee withdraw
    function lpWithdrawFee(address recipient) external onlyOwner() returns (bool) {
        
        ERC20Detailed(_lp).transfer(recipient, _totalFee);
        super.withdrawFee(recipient);
        return true;
    }
    
    
    function lpGetPoolInfo() external view returns (uint256 start, uint256 stop, uint256 rewardsRate, uint256 rewardsPerToken, uint256 totalFee, uint256 totalPledge, uint256 totalRewards){
        return (_start, _stop, _rewardsRate, _rewardsPerToken, _totalFee, _totalPledge, _totalRewards);
    }
    
    function lpGetPledge() external view returns (uint256) {
        return _pledges[msg.sender];
    }
    
    function debugLpGetPledge(address user) external view onlyOwner() returns (uint256) {
        return _pledges[user];
    }
    
    
    
    function bonds () external onlyOwner() returns (uint index,bool next) {
        require(_userCount >= 9,"at least 9 user");
        
        
        if (_bondsIndex == 0) {
            _thisRewards = balanceOf(address(this)).mul(20).div(100);
            uint256 rewards = _thisRewards.mul(60).div(100);
        
            _balances[address(this)] = _balances[address(this)].sub(rewards);
            delete _last;
        
            uint256 bondTop = rewards.div(9);
            for (_bondsIndex; _bondsIndex<4; _bondsIndex++) {
                address receiver = _top[_bondsIndex];
                _last[_bondsIndex] = receiver;
                _balances[receiver] = _balances[receiver].add(bondTop);
                emit Transfer(address(this),receiver,bondTop);
            }
            return (_bondsIndex,true);
        }else if (_bondsIndex == 4) {
            uint256 rewards = _thisRewards.mul(60).div(100);
            uint256 bondTop = rewards.mul(60).div(100).div(9);
        
            for (_bondsIndex; _bondsIndex<9; _bondsIndex++) {
                address receiver = _top[_bondsIndex];
                _last[_bondsIndex] = receiver;
                _balances[receiver] = _balances[receiver].add(bondTop);
                emit Transfer(address(this),receiver,bondTop);
            }
            if (_userCount < 49) {
                _bondsIndex = 0;
                return (9,false);
            }
            return (_bondsIndex,true);
        }else {
            uint256 rewards = _thisRewards.mul(40).div(100);
            if (_bondsIndex == 9) {
                _balances[address(this)] = _balances[address(this)].sub(rewards);
            }
            
            uint256 bondRand = rewards.div(40);

            uint loop = _bondsIndex+5;
            for (_bondsIndex; _bondsIndex < loop; _bondsIndex++) {
                address receiver = _top[_bondsIndex];
                _last[_bondsIndex] = receiver;
                _balances[receiver] = _balances[receiver].add(bondRand);
                emit Transfer(address(this),receiver,bondRand);
            }
            
            if (_bondsIndex == 49){
                _bondsIndex = 0;
                return (49,false);
            }
            return (_bondsIndex,true);
        }
    }
    
    function debugCount() external onlyOwner() view returns (uint) {
        return _userCount;
    }
    
    
    function getTops() external view returns (address[49] memory) {
       
        address[49] memory top;
        for (uint i=0;i<49;i++) {
            top[i] = _top[i];
        }
        return top;
    }
    
    function getLast() external view returns (address[49] memory) {
        address[49] memory last;
        for (uint i=0;i<49;i++) {
            last[i] = _last[i];
        }
        return last;
    }
    
}

//SourceUnit: SafeERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
      require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
      require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
      // safeApprove should only be called when setting an initial allowance, 
      // or when resetting it to zero. To increase and decrease it, use 
      // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
      require((value == 0) || (token.allowance(msg.sender, spender) == 0));
      require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
      uint256 newAllowance = token.allowance(address(this), spender).add(value);
      require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
      uint256 newAllowance = token.allowance(address(this), spender).sub(value);
      require(token.approve(spender, newAllowance));
    }
    
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
    * @dev Returns the largest of two numbers.
    */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
    * @dev Returns the smallest of two numbers.
    */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Calculates the average of two numbers. Since these are integers,
    * averages of an even and odd number cannot be represented, and will be
    * rounded down.
    */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}