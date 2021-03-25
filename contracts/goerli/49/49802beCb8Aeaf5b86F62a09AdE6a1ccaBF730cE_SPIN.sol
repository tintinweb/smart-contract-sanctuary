/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
  address payable _owner;

  event OwnershipTransferred(
    address payable indexed previousOwner,
    address payable indexed newOwner
  );

  constructor()  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner(), "Not authorised for this operation");
    _;
  }

  function isOwner() public view returns(bool) {
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
       

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
     
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
        
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
         
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract BasicToken is IERC20, Context{

    using SafeMath for uint256;
    uint256 public _totalSupply;
    mapping(address => uint256) balances_;
    
    mapping(address => uint256) ethBalances;
    
    mapping (address => mapping (address => uint256)) internal _allowances;
    
    uint256 public startTime = 1616699722;   // ------| 12 AM UTC ____28-March-2021 |-------- 
   

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances_[account];
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function checkInvestedETH(address who) public view returns (uint256) {
        return ethBalances[who];
    }
}

contract StandardToken is BasicToken, Ownable {

    using SafeMath for uint256;   
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
       
        // require(block.timestamp >= startTime.add(unlockDuration) || _msgSender() == owner(), "Tokens not unlocked yet");
        
        balances_[sender] = balances_[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        balances_[recipient] = balances_[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}


contract Configurable {

    uint256 public capPrivate = 4*10**6*10**18;           //-----| 4.000,000 for Private|---------
    uint256 public capPublic =  240**3*10**18;            //-----| 240,000 for Public  |---------
   
    uint256 public basePricePrivate = 2*10**18;            //----| 1 USDT = 2 SPIN |---------
    uint256 public basePricePublic = 10*10**18;   
    uint256 public tokensSoldPrivate;
    uint256 public tokensSoldPublic;

    uint256 public tokenReserve = 20*10**6*10**18;         //-----| Total Supply |------ 
   
    uint256 public remainingTokensPublic;
    uint256 public remainingTokensPrivate;

    address public publicentireEcosystem;
    address public teamAdvisors ;
    address public markettingCommunity ;
    address public ecosystemReserve ;

    uint256 entireEcosystemFUND = 8*10**6*10**18;           //____| 8 Million |________
    uint256 teamAdvisorsFUND = 5*10**6*10**18;              //____| 5 Million |________
    uint256 markettingCommunityFUND = 1*10**6*10**18;       //____| 1 Million |________
    uint256 ecosystemReserveFUND = 176*10**3*10**18;        //____| 1 M and 760K |________

}

contract CrowdsaleToken is StandardToken, Configurable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum Phases {none, start, end}
    Phases public currentPhase;
    IERC20 public USDT;

    constructor(address _USDT, address _eEco,address _tAdv, address _mCom, address _eRes) {

        USDT = IERC20(_USDT); 
        
        publicentireEcosystem = _eEco;
        teamAdvisors = _tAdv;
        markettingCommunity = _mCom;
        ecosystemReserve = _eRes;

	    balances_[publicentireEcosystem] = entireEcosystemFUND;
        balances_[teamAdvisors] = teamAdvisorsFUND;
        balances_[markettingCommunity] = markettingCommunityFUND;
        balances_[ecosystemReserve] = ecosystemReserveFUND;

        currentPhase = Phases.none;

        balances_[owner()] = balances_[owner()].add(capPrivate).add(capPublic); //____| Balance Owner |______

        _totalSupply = _totalSupply.add(tokenReserve);

        remainingTokensPrivate = capPrivate;
        remainingTokensPublic = capPublic;

    emit Transfer(address(0), msg.sender, capPrivate.add(capPublic));
    emit Transfer(address(0), publicentireEcosystem, entireEcosystemFUND);
    emit Transfer(address(0), teamAdvisors, teamAdvisorsFUND);
    emit Transfer(address(0), markettingCommunity, markettingCommunityFUND);
    emit Transfer(address(0), ecosystemReserve, ecosystemReserveFUND);


    }

    uint256 public oneMonth = 30 days;               
    uint256 public withdrewTokens = 0 ;
   
    mapping(address => uint256) public publicFund;
    mapping(address => uint256) public privateFund;
    mapping(address => uint256) public vestedFund;

    mapping (address => uint256) public _released;
    mapping (IERC20 => bool) private _revoked;
    mapping (address => mapping (uint => bool)) public claimed;

   
    function publicPresale(uint256 amount) public {
        
        require(currentPhase == Phases.start, "The public presale has not started yet");
        require(remainingTokensPrivate > 0, "Public presale token limit has reached");
        require(remainingTokensPrivate > 0, "Presale token limit reached");

        uint256 tokens = amount.mul(basePricePublic).div(12*10**6);            

        publicFund[msg.sender] = publicFund[msg.sender].add(amount);
        publicFund[address(this)] = publicFund[address(this)].add(amount);

        require(publicFund[msg.sender] <= 1e9, "Reaching personal cap of 1000 USDT");
        require(publicFund[address(this)] <= 144e9, "Target amount of 144K USDT reached"); // 144,000 

        if(tokensSoldPublic.add(tokens) > capPublic){
           revert("Exceeding limit of public presale tokens");
        }

        tokensSoldPublic = tokensSoldPublic.add(tokens); 
        remainingTokensPublic = capPublic.sub(tokensSoldPublic);

        balances_[owner()] = balances_[owner()].sub(tokens, "ERC20: transfer amount exceeds balance");
        balances_[msg.sender] = balances_[msg.sender].add(tokens);

        USDT.safeTransferFrom(msg.sender, owner(), amount);

        emit Transfer(address(this), msg.sender, tokens);

    }

    function privatePresale(uint256 amount) public {
        
        require(currentPhase == Phases.start, "The private presale has not started yet");
        require(remainingTokensPrivate > 0, "Private presale token limit has reached");

        require(amount <=  1e9 , "Cannot send more than 1000 USDT");
        require(remainingTokensPrivate > 0, "Presale token limit reached");

        uint256 tokens = amount.mul(basePricePrivate).div(1*10**6);  

        privateFund[msg.sender] = privateFund[msg.sender].add(amount);
        privateFund[address(this)] = privateFund[address(this)].add(amount);

        require(privateFund[address(this)] <= 2e12, "Target amount of 2M USDT reached");

        if(tokensSoldPrivate.add(tokens) > capPrivate){
           revert("Exceeding limit of private presale tokens");
        }

        tokensSoldPrivate = tokensSoldPrivate.add(tokens); 
        remainingTokensPrivate = capPrivate.sub(tokensSoldPrivate);

        balances_[owner()] = balances_[owner()].sub(tokens, "ERC20: transfer amount exceeds balance");
        vestedFund[msg.sender] = vestedFund[msg.sender].add(tokens);
       
        USDT.safeTransferFrom(msg.sender, owner(), amount);
        emit Transfer(address(this), msg.sender, tokens);
    }

    function releaseVestedFund() public {

      uint256 unreleased = _releasableAmount();
      require(unreleased > 0, "No releasable amount or amount for this month already claimed");

      _released[msg.sender] = _released[msg.sender].add(unreleased);
      balances_[msg.sender] = balances_[msg.sender].add(unreleased);
     
      emit Transfer(address(this), msg.sender, unreleased);
        
    }

    function released() public view returns(uint256) {
     return _released[msg.sender];
    }


    function _releasableAmount() private returns (uint256) {
      
        uint256 currentSeconds;
        uint256 monthValue;
        uint256 releasable;
     
        uint[9] memory unlockingTokenPercent =  [uint(20), uint(30), uint(40), uint(50), uint(60), uint(70), uint(80), uint(90), uint(100)]; 
        currentSeconds = block.timestamp.sub(startTime);        //------| Starttime ?! StartPresale |---------

        monthValue = currentSeconds.div(oneMonth);
        
        if(monthValue >= 1 && monthValue <= 8){

         releasable = vestedFund[msg.sender].mul(unlockingTokenPercent[monthValue.sub(1)]).mul(10).div(1000) - withdrewTokens;
         
         withdrewTokens += releasable;
         
        } else if(monthValue >= 9){
            
        releasable = vestedFund[msg.sender].mul(unlockingTokenPercent[8]).mul(10).div(1000) - withdrewTokens;
         
         withdrewTokens += releasable;
            
        } else {

          releasable = 0 ;
        }
       
        return releasable;
        
      }

    function startPresale() public onlyOwner {
        require(currentPhase != Phases.end, "The coin offering has ended");
        currentPhase = Phases.start;
    }

    function endPresale() public onlyOwner {
        require(currentPhase != Phases.end, "The coin offering has ended");
        currentPhase = Phases.end;
    
    }

}

contract SPIN is CrowdsaleToken {
    string public name = "Spinach Tokens";
    string public symbol = "SPIN";
    uint32 public decimals = 18;

   constructor(address _USDT, address _eEco,address _tAdv, address _mCom, address _eRes) CrowdsaleToken(_USDT, _eEco, _tAdv, _mCom, _eRes) {

          }

      }