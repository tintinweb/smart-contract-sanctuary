//SourceUnit: dlike_contract.sol

pragma solidity 0.5.9; /*
___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_


██████╗ ██╗     ██╗██╗  ██╗███████╗   
██╔══██╗██║     ██║██║ ██╔╝██╔════╝  
██║  ██║██║     ██║█████╔╝ █████╗    
██║  ██║██║     ██║██╔═██╗ ██╔══╝   
██████╔╝███████╗██║██║  ██╗███████╗ 
╚═════╝ ╚══════╝╚═╝╚═╝  ╚═╝╚══════╝ 
                                                                                   
                                                                                   
// ----------------------------------------------------------
// 'DLIKE' contract with following features
//      => TRC20 Compliance
//      => Higher degree of control by owner - safeguard functionality
//      => SafeMath implementation 
//      => Burnable and minting
//
// Name        : DLIKE
// Symbol      : DLIKE
// Decimals    : 6
//
// Copyright 2020 onwards - DLIKE ( https://dlike.io )
// Contract designed and audited by EtherAuthority ( https://EtherAuthority.io )
// Special thanks to openzeppelin for inspiration:  ( https://github.com/OpenZeppelin )
// ----------------------------------------------------------------------------
*/ 

//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
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
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract Ownable {
    address payable internal _owner;
    address public signer;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        signer = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlySigner {
        require(msg.sender == signer, "caller must be signer");
        _;
    }
    
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
 
interface stakeContract {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);    
}
    
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    
contract DLIKE is Ownable {
    

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of DLIKE
    using SafeMath for uint256;
    string constant private _name = "DLIKE";
    string constant private _symbol = "DLIKE";
    uint256 constant private _decimals = 6;
    uint256 private _totalSupply = 0;
    bool public safeguard;

    // This creates a mapping with all data storage
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public frozenAccount;
    
    mapping(address=>uint256) public stakePool;
    mapping(address=>uint256) public checkPowerDownPeriod;
    mapping(address=>uint256) public unstakePool;

    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address target, bool frozen);
    
    // This will log approval of token Transfer
    event Approval(address indexed from, address indexed spender, uint256 value);


    /*======================================
    =       STANDARD ERC20 FUNCTIONS       =
    ======================================*/
    
    function name() public pure returns(string memory) {
        return _name;
    }
    
    function symbol() public pure returns(string memory) {
        return _symbol;
    }
    
    function decimals() public pure returns(uint256) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address user) public view returns(uint256) {
        return _balanceOf[user];
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(!safeguard);
        require (_to != address(0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        
        _balanceOf[_from] = _balanceOf[_from].sub(_value);    // Subtract from the sender
        _balanceOf[_to] = _balanceOf[_to].add(_value);        // Add the same to the recipient
        
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= _allowance[_from][msg.sender]);     // Check _allowance
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!safeguard);
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function increase_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    function decrease_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].sub(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/
    
    constructor() public {}
    function() external payable {}

    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        _totalSupply = _totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(!safeguard);
        _balanceOf[_from] = _balanceOf[_from].sub(_value);                         // Minus from the targeted balance
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value); // Minus from the sender's allowance
        _totalSupply = _totalSupply.sub(_value);                                   // Update totalSupply
        emit  Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }
        
 
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenAccounts(target, freeze);
    }
    
    uint256 public PowerDownPeriod=604800; 
    uint256 totalStake=0;
    uint256 totalUnstake=0;
    event mintcommonReward(address indexed user, uint256 indexed amount, uint256 time);
    event mintstakeReward(address indexed user, uint256 indexed amount, uint256 time);
    event putstake(address indexed user, uint256 indexed amount, uint256 time);
    event withdrawStake(address indexed user, uint256 indexed amount, uint256 time);
    event unstakeEv(address indexed user, uint256 indexed amount, uint256 time);
    mapping(address=>uint256) public tokenBalances;
    mapping(address=>uint256) public rewardBlanaces;
    
    
    uint256[]  stakingAddress;
    uint256[]  unstakingAddress;
    
    function payToken(address[] memory receivers, uint256[] memory amounts) public onlySigner returns(bool) {
        require(!safeguard);
        uint256 arrayLength = receivers.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            mintToken(receivers[i], amounts[i]);
        }
        return true;
      }
  
    function mintToken(address target, uint256 mintedAmount) internal returns(bool) {
        require(!safeguard);
        require(target!=address(0), "Invalid Address");
        require(mintedAmount!=0, "Invalid Amount");
        tokenBalances[target] =mintedAmount;
        return true;
    }
    
    function payReward(address[] memory receivers, uint256[] memory amounts) public onlySigner returns(bool) {
        require(!safeguard);
        uint256 arrayLength = receivers.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            mintstakingreward(receivers[i], amounts[i]);
        }
        return true;
      }
      
     function mintstakingreward(address target, uint256 mintedAmount) internal returns(bool) {
        require(!safeguard);
        require(target!=address(0), "Invalid Address");
        require(mintedAmount!=0, "Invalid Amount");
        rewardBlanaces[target] = mintedAmount;
        return true;
    }
   
    function stakeIn(uint256 _amount) public returns(bool) {
        require(!safeguard);
        require(_amount!=0, "invalid Amount");
        require(_amount<=_balanceOf[msg.sender], "Insufficient Balance");
        address sender=msg.sender;
        stakePool[sender]=stakePool[sender].add(_amount);
        _balanceOf[sender]=_balanceOf[sender].sub(_amount);
        totalStake=totalStake.add(_amount);
        
        emit putstake(sender, _amount, block.timestamp);
        emit Transfer(sender, address(this), _amount);
        return true;
    }
    
    function stakeOut(uint256 _amount) public returns(uint256, bool) {
        require(!safeguard);
        require(stakePool[msg.sender]>=_amount, "Invalid Amount");
        require(_amount!=0, "Invalid Amount");
        
        address sender=msg.sender;
        if(checkPowerDownPeriod[sender]!=0) {
            return (checkPowerDownPeriod[sender], false);
        } else {
            unstakePool[sender]=unstakePool[sender].add(_amount);
            checkPowerDownPeriod[sender]=block.timestamp.add(PowerDownPeriod);
            stakePool[sender]=stakePool[sender].sub(_amount);
            totalUnstake=totalUnstake.add(_amount);
            totalStake=totalStake.sub(_amount);
            emit unstakeEv(sender, _amount, block.timestamp);
            return (checkPowerDownPeriod[sender], true);
        }
        
    }
    
    function claimStakeOut(uint256 _amount) public returns(bool) {
        require(!safeguard);
        require(checkPowerDownPeriod[msg.sender]<=block.timestamp, "Freezed");
        require(unstakePool[msg.sender]<=_amount, "Invalid Amount");
        address sender=msg.sender;
        _balanceOf[sender]=_balanceOf[sender].add(_amount);
        unstakePool[sender]=unstakePool[sender].sub(_amount);
        checkPowerDownPeriod[sender]=0;
        totalUnstake=totalUnstake.sub(_amount);
        emit Transfer(address(this), sender, _amount);
        return true;
    }
    
    function isUnstaking(address _address) public view returns(uint256, bool) {
        require(_address!=address(0));
        if(checkPowerDownPeriod[msg.sender]!=0) {
            return (checkPowerDownPeriod[msg.sender], true);
        } else {
            return (checkPowerDownPeriod[msg.sender], false);
        } 
    }
    
    function getToken(uint256 _amount) public {
        require(!safeguard);
        require(tokenBalances[msg.sender]!=0, "No Tokens Available");
        require(tokenBalances[msg.sender]>=_amount, "Invalid amount");
        uint256 temp=_amount;
        _balanceOf[msg.sender]=_balanceOf[msg.sender].add(temp);
        tokenBalances[msg.sender]=tokenBalances[msg.sender].sub(temp);
        _totalSupply=_totalSupply.add(temp);
        emit Transfer(address(this), msg.sender, temp);
    }
    
    function getReward(uint256 _amount) public {
        require(!safeguard);
        require(rewardBlanaces[msg.sender]!=0, "No Rewards Available");
        require(rewardBlanaces[msg.sender]>= _amount, "Invalid amount");
        uint256 temp=_amount;
        _balanceOf[msg.sender]=_balanceOf[msg.sender].add(temp);
        rewardBlanaces[msg.sender]=rewardBlanaces[msg.sender].sub(temp);
        _totalSupply=_totalSupply.add(temp);
        emit Transfer(address(this), msg.sender, temp);
    }
    
    function setPowerDownPeriod(uint256 _time) public onlyOwner returns(bool) {
        require(!safeguard);
        PowerDownPeriod=_time;
        return true;
    }
    
    function TotalStakedAmount() public view returns(uint256) {
        return totalStake;
    }
    
    function TotalPendingUnstakeamount() public view returns(uint256) {
         return totalUnstake;
    }
    
    function checkUnstake(address _add) public view returns(uint256) {
        require(_add!=address(0));
        return unstakePool[_add];
        
    }
    
    function checkStake(address _add) public view returns(uint256) {
        require(_add!=address(0));
       return stakePool[_add];
    }

    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner {
        require(!safeguard);
        _transfer(address(this), _owner, tokenAmount);
    }
    
    function manualwithdrawTron() public onlyOwner {
        require(!safeguard);
        address(_owner).transfer(address(this).balance);
    }

    function Boost(uint256 _amount) public {
        require(!safeguard);
        require(_amount!=0, "Invalid Amount");
        burn(_amount);
    }
    
    function Membership(uint256 _amount) public {
        require(!safeguard);
        require(_amount!=0, "Invalid Amount");
        burn(_amount);
    }
    
    function changeSafeguardStatus() public onlyOwner {
        if (safeguard == false) {
            safeguard = true;
        } else {
            safeguard = false;    
        }
    }
    
}