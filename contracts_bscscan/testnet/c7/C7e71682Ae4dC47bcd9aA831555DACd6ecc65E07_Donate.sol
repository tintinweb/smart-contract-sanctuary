/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity ^0.4.24;

library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns(uint256)
    {
        require(b <= a);
        return a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns(uint256)
    {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns(uint256)
    {
        require(b != 0);
        uint256 c = a / b;
        return c;
    }
}
pragma solidity ^0.4.24;
contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
pragma solidity ^0.4.24;
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
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}
pragma solidity ^0.4.24;
contract LockInterface {
     function putDonateReward(address _addr, uint256 _value) public returns (bool _result);
     function putInviterReward(address _addr, uint256 _value) public returns (bool _result);
     function putNodeReward(address _addr, uint256 _value) public returns (bool _result);
     
     function withdraw() public returns (bool _result);
     function getUserDonateReward(address _addr) public view returns (uint256 _value);
}
pragma solidity ^0.4.24;
interface IPancakePair {
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
    // function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
pragma solidity ^0.4.24;
contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
pragma solidity ^0.4.24;
contract Donate is Ownable, Pausable {
    using SafeMath for uint256;
    uint constant public PERCENTS_DIVIDER = 10**5;
    address public owner;
    address public blackHole; // black hole
    address public fund; // platform
    IPancakePair public inLp;
    EIP20Interface public airdropCoin;
    LockInterface public lockContract;
    address public uintAddress;
    uint256 public minDonate = 100*10**18;
    
    bool public donateEnd = false;
    Rule public rule;
    
    mapping(address => User) public users;
    
    /* This notifies clients about the amount Donate */
    event NewDonate(address indexed from, uint256 indexed ownReward, uint256 indexed inviterReward, uint256 nodeReward);
    
    struct User {
        address inviter;
        bool isNode;
        bool isUsed;
        address upNode;
        mapping(uint8 => uint256)  donateOf; // 1: donate, 2: own 3: inviter 4: node
    }
    
    struct Rule {
        uint256 airdrop; // airdrop amount
        uint256 reward; // reward amount
        uint32 upProp; // Inviter reward ratio
        uint32 nodeProp; //   Inviter reward ratio
        uint32 priceProp; // price ratio
        uint256 remainAirdrop; // remain airdrop
        uint256 remainReward; // remain reward
        uint256 maxAirdrop; // max Reward
        uint256 totalDonate; // total donate lp 
    }
 
    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        address _holder, 
        address _blackHole, 
        address _fund,
        address _airdropCoin,
        address _inLp,
        address _uintAddress
    ) public {
        owner = _holder;
        blackHole = _blackHole;
        inLp = IPancakePair(_inLp);
        airdropCoin = EIP20Interface(_airdropCoin);
        fund = _fund;
        uintAddress = _uintAddress;
    }
    
    /* stopDonate */
    function stopDonate() public onlyOwner returns (bool _result){
        donateEnd = true ;
        _result = true;
    }
    
    /* start next index */
    function stratDonate() public onlyOwner returns (bool _result) {
        require(rule.airdrop > 0, 'No rules set, Failed to open! ');
        donateEnd = false ;
        _result = true;
    }
    
    /* set Lock contract */
    function setLockAddr(address _lockAddr) public onlyOwner returns (bool _result){
        require(_lockAddr != address(0), 'address 0 ');
        lockContract = LockInterface(_lockAddr);
        _result = true;
    }
    
    /* setnode */
    function setNode(address _addr, bool _set) public onlyOwner returns (bool _result){
        require(users[_addr].isUsed, "this account is not activated");
        if(_set)
            users[_addr].isNode = true;
        else
            users[_addr].isNode = false;
        
        _result = true;
    }
    
    /* setRule */
    function setRule(uint256 _airdrop, uint256 _reward, uint32 _inviterProp, uint32 _nodeProp, uint32 _priceProp, uint256 _maxAirdrop) public onlyOwner returns (bool _result){
        rule.airdrop = _airdrop;
        rule.reward = _reward;
        rule.upProp =_inviterProp;
        rule.nodeProp =_nodeProp;
        rule.priceProp =_priceProp;
        rule.remainAirdrop= _airdrop;
        rule.remainReward = _reward;
        rule.maxAirdrop = _maxAirdrop;
        
        _result = true;
    }

    /* setMinDonate */
    function setMinDonate(uint256 _value) public onlyOwner returns(bool _result) {
        minDonate = _value;
        _result = true;
    }
    
    // Do not filter whether these modified addresses are 0, equal to 0. Specific operations will be filtered
    /* setInLp */
    function setInLp(address _inLp) public onlyOwner returns(bool _result) {
        inLp = IPancakePair(_inLp);
        _result = true;
    }

    /* setBlackHole */
    function setBlackHole(address _blackHole) public onlyOwner returns(bool _result){
        blackHole = _blackHole;
        _result = true;
    }
    
    /* setFund */
    function setFund(address _fund) public onlyOwner returns(bool _result){
        fund = _fund;
        _result = true;
    }
    
    /* donate */
    function doDonate(uint256 _value, address _inviterAddr) public whenNotPaused returns (bool _result){
        require(inLp != address(0) && lockContract != address(0), 'not open!');
        require(_value > 0, 'minimum donate amount > 0 ');
        require((_inviterAddr != address(0) && users[_inviterAddr].isUsed) || (_inviterAddr == address(0)), 'inviter does not exist !' );
        
        inLp.transferFrom(msg.sender, blackHole, _value);
        User storage _user = users[msg.sender];
        if(!_user.isUsed)
            _user.inviter = _inviterAddr;
        
        _user.isUsed = true;
        _user.upNode = users[_inviterAddr].isNode ? _inviterAddr : users[_inviterAddr].upNode;
        (uint256 _ownAirdrop, uint256 _donateCost) = _getOwnAirdrop(_value);
        
        uint256 _transferToFund;
        uint256 _transferToLock = _ownAirdrop;
        
        uint256 _remainAirdrop = rule.remainAirdrop;
        uint256 _remainReward = rule.remainReward;
        _ownAirdrop = _remainAirdrop < _ownAirdrop ? _remainAirdrop: _ownAirdrop;
        
        uint256 _inviterReward;
        uint256 _nodeReward;
        
        if(_donateCost >= minDonate && _ownAirdrop > 0) {
            _user.donateOf[1] = _user.donateOf[1].safeAdd(_value);
            rule.totalDonate = rule.totalDonate.safeAdd(_value);
            _inviterReward = _ownAirdrop.safeMul(rule.upProp).safeDiv(PERCENTS_DIVIDER);
            (_remainReward, _inviterReward) = _calcRemain(_remainReward, _inviterReward);
            if(_inviterReward > 0) {
                if(_user.inviter != address(0)) {
                    lockContract.putInviterReward(_user.inviter, _inviterReward);
                    users[_user.inviter].donateOf[3] = users[_user.inviter].donateOf[3].safeAdd(_inviterReward);
                    _transferToLock = _transferToLock.safeAdd(_inviterReward);
                } else {
                    _transferToFund = _transferToFund.safeAdd(_inviterReward);
                    users[fund].donateOf[3] = users[fund].donateOf[3].safeAdd(_inviterReward);
                }
            }
            _nodeReward = _ownAirdrop.safeMul(rule.nodeProp).safeDiv(PERCENTS_DIVIDER);
            (_remainReward, _nodeReward) = _calcRemain(_remainReward, _nodeReward);
            if(_nodeReward > 0) {
                if(_user.upNode != address(0)) {
                    lockContract.putNodeReward(_user.upNode, _nodeReward);
                    _transferToLock = _transferToLock.safeAdd(_nodeReward);
                    users[_user.upNode].donateOf[4] = users[_user.upNode].donateOf[4].safeAdd(_nodeReward);
                } else {
                    _transferToFund = _transferToFund.safeAdd(_nodeReward);
                    users[fund].donateOf[4] = SafeMath.safeAdd(users[fund].donateOf[4], _nodeReward);
                }
            }
        } else {
            _ownAirdrop = 0;
            _transferToLock = 0;
        }
        if(_ownAirdrop > 0) {
            lockContract.putDonateReward(msg.sender, _ownAirdrop);
            _user.donateOf[2] = _user.donateOf[2].safeAdd(_ownAirdrop);
            rule.remainAirdrop -= _ownAirdrop;
            rule.remainReward = _remainReward;
        }
        
        if(_transferToLock > 0)
            airdropCoin.transfer(lockContract, _transferToLock);
        if(_transferToFund > 0)
            airdropCoin.transfer(fund, _transferToFund);
            
        emit NewDonate(msg.sender, _ownAirdrop, _inviterReward, _nodeReward);
        
        _result = true;
    }
    
    // TODO public --> private
    /* get own airdrop*/
    function _getOwnAirdrop(uint256 _value) public view returns(uint256 _airdrop, uint256 _cost){
        uint256 _donateRewarded = lockContract.getUserDonateReward(msg.sender);
        // _ownAirdrop = donateLp/totalLP * USDT*2
       (uint256 _reserve, uint256 _totalLp) = _getLpData();
        _cost = _value.safeMul(_reserve.safeMul(2)).safeDiv(_totalLp);
        _airdrop = _cost.safeMul(PERCENTS_DIVIDER).safeDiv(rule.priceProp);
        _airdrop = _airdrop >= rule.maxAirdrop ? rule.maxAirdrop : _airdrop;
        _airdrop = _donateRewarded.safeAdd(_airdrop) <= rule.maxAirdrop ? _airdrop : rule.maxAirdrop.safeSub(_donateRewarded);
    }
    
    /*  _getLpData */
    function _getLpData() public view returns(uint256 _reserve, uint256 _totalLp) {
        (uint256 _reserve1, uint256 _reserve2,) = inLp.getReserves();
        address _token0 = inLp.token0();
        if(_token0 == uintAddress) {
            _reserve = _reserve1;
        } else {
            _reserve = _reserve2;
        }
        
        _totalLp = inLp.totalSupply();
    }
    
    /* calc remain */
    function _calcRemain(uint256 _total, uint256 _sub) public pure returns(uint256 _remainTotal, uint256 _realSub){
        if(_total >= _sub) {
            _remainTotal = _total.safeSub(_sub);
            _realSub = _sub;
        } else {
            _realSub = _total;
            _remainTotal = 0;
        }
    }
    
    /* getUserNum  1: donate 2: own reward 3: inviter 4: node */
    function getUserNum(address _addr, uint8 _num) public view returns (uint _value){
        _value = users[_addr].donateOf[_num];
    }
}