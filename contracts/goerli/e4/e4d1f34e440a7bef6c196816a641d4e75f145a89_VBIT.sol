/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

 
    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Configurable {

    //-------------| Addresses Details|-------------------------
    address [] public coFounderList;
    address public initialStakingRewards;
    address public teamContributors ;

    //-------------| Fund Details |----------------------------
    uint256 public tokenReserve = 200*10**9*10**18;                      //_____| Total Supply : 200 Billion |________ 

    uint256 public initialStakingRewardsFUND = 100*10**9*10**18;         //______| 100 Billion |______________________
    uint256 public foundersFUND = 20*10**9*10**18;                       //______| 20 Billion  |______________________
    uint256 public teamContributorsFUND = 3*10**9*10**18;                //______| 3 Billion   |______________________

}

contract VBIT is Context, IERC20, Configurable, Ownable {
    using SafeMath for uint256;

    uint256 public startTime = block.timestamp;   // ------| Deploy Timestamp |------
    // uint256 public oneYear = 1 years;         //---| 1 Years in seconds |--------
    uint256 public oneYear = 2 minutes;                 //----| 2 minute in seconds |------
    uint256 public withdrewTokens = 0 ;

    uint256 burnTokens = 0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping(address => uint256) public vestedFund;
    mapping (address => uint256) private _released;
    mapping (address => bool) private revoked;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    constructor (address[] memory _coFounders, address _initStake, address _teamCont) {
        _name = "VBIT Coins";
        _symbol = "VBIT";
        _mint(msg.sender, 200*10**9*10**18);                        //__| 200 Billion |______

        initialStakingRewards = _initStake;
        teamContributors = _teamCont;
 
    _balances[_msgSender()] = _balances[_msgSender()].sub(initialStakingRewardsFUND.add(foundersFUND).add(teamContributorsFUND)) ;          //_____| Deduct 100 Billion |___________ 

    _balances[initialStakingRewards] += initialStakingRewardsFUND;     //---| 100 Billion to Iinitial Staking Rewards|----- 
    _balances[teamContributors] += teamContributorsFUND;               //---| 3 Billion to Team Contributors |-------------


    for (uint loop = 0; loop < _coFounders.length; loop++) {           //---| 20 Billion vested equally for Co-Founders |-- 
        coFounderList.push(_coFounders[loop]);
        vestedFund[_coFounders[loop]] = foundersFUND.div(_coFounders.length);
    }

    }

    function resetStartTime() public {
       
        startTime = block.timestamp;
    }
    
    function releaseVestedFund() public {

      require(checkRevoked(msg.sender) != true, "You are revoked and not allowed to release fund");

      uint256 unreleased = _releasableAmount(msg.sender);
      require(unreleased > 0, "AMOUNT ALREADY CLAIMED FOR THIS YEAR / NO RELEASABLE AMOUNT");

    //   _released[msg.sender] = _released[msg.sender].add(unreleased);
      _balances[msg.sender] = _balances[msg.sender].add(unreleased);
     
      emit Transfer(address(this), msg.sender, unreleased);
        
    }

    function released(address _account) public view returns(uint256) {
     return _released[_account];
    }

    // check if not revoked
    // release all the funds 
    // take out all their vested fund funds to owner wallet. 
    // update revoked as true
    // Drain Vested fund for that user and transfer them to deployer wallet.
    // Need to tell user to release their fund before revoke.
    
    function revoke(address _account) public onlyOwner { 
     
      require(checkRevoked(_account) != true, "THIS ACCOUNT IS ALREADY REVOKED");

      uint256 balance = vestedFund[_account];
      _balances[owner()] += balance.sub(_released[_account]); 

       vestedFund[_account] = 0;
       revoked[_account] = true;

       emit Transfer(_account, owner(), balance.sub(_released[_account]));
     
    }


    function checkRevoked(address _account) public view returns (bool){
        return revoked[_account];
    }

    function checkYear() public view returns (uint256){  // ################| REMOVE THIS METHOD |#################
     
      uint256 currentSeconds;
      uint256 yearValue;

      currentSeconds = block.timestamp.sub(startTime);               //------| Starttime ?! StartPresale |---------
      yearValue = currentSeconds.div(oneYear);

        return yearValue;


    }

     /**_________________________________________________________________________________________________________
         Vesting Schedule:
            Immediate- 5% => After Year 1- 15% => After Year 2- 20% => After Year 3- 20% => After Year 4- 40%
        _________________________________________________________________________________________________________
    */

    function _releasableAmount(address _account) private returns (uint256) {
      
        uint256 currentSeconds;
        uint256 yearValue;
        uint256 releasable;
     
        uint[5] memory unlockingTokenPercent =  [uint(5), uint(20), uint(40), uint(60), uint(100)]; 
        currentSeconds = block.timestamp.sub(startTime);               //------| Starttime ?! StartPresale |---------
        yearValue = currentSeconds.div(oneYear);

       if(yearValue >= 0 && yearValue <= 3){
         releasable = vestedFund[_account].mul(unlockingTokenPercent[yearValue]).mul(10).div(1000).sub(_released[_account]);
         _released[_account] += releasable;
         
        } else if(yearValue >= 4){
         releasable = vestedFund[_account].mul(unlockingTokenPercent[4]).mul(10).div(1000).sub(_released[_account]);
         _released[_account] += releasable;
        }
        
        return releasable;
      }

    function getFounderCount() public view returns(uint) {
        return coFounderList.length;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function findTwentyPercent(uint256 amount) internal pure returns (uint256) {
        return amount.mul(50).div(1000);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (_totalSupply <= 1e29 || msg.sender == owner()) {         //-----| Reaches 100 Billion|------                            
            _transferSpecial(msg.sender, recipient, amount);

        } else {
            _transfer(msg.sender, recipient, amount);

        }

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
       
        if (_totalSupply <= 1e29 || msg.sender == owner()) {       //-----| Reaches 100 Billion|------                         
            _transferSpecial(msg.sender, recipient, amount);

        } else {
            _transfer(msg.sender, recipient, amount);

        }
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;
     
        burnTokens  = findTwentyPercent(amount);                                                         
        
        _balances[recipient] += amount.sub(burnTokens);                    //___| burn 20% on each transfer |______     
        _totalSupply -= burnTokens;                                      //____| reduce 20% from total supply |______

        emit Transfer(sender, recipient, amount.sub(burnTokens));
        emit Transfer(sender, address(0), burnTokens);
    }
   
    function _transferSpecial(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(
            sender != address(0),
            "ERC20 Special: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "ERC20 Special: transfer to the zero address"
        );

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20 Special: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}