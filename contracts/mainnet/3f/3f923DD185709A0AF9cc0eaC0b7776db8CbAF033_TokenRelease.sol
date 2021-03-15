/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity >=0.6.0;


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

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract Context {
  
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    struct PoolAddress{
        address poolReward;
        bool isActive;
        bool isExist;

    }
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address[] rewardPool;
    mapping(address=>PoolAddress) mapRewardPool;
   
    address internal tokenOwner;
    uint256 internal beginFarming;

    function addRewardPool(address add) public {
        require(_msgSender() == tokenOwner, "ERC20: Only owner can init");
        require(!mapRewardPool[add].isExist,"Pool already exist");
        mapRewardPool[add].poolReward=add;
        mapRewardPool[add].isActive=true;
        mapRewardPool[add].isExist=true;
        rewardPool.push(add);
    }
    function removeRewardPool(address add) public {
        require(_msgSender() == tokenOwner, "ERC20: Only owner can init");
        mapRewardPool[add].isActive=false;
       
        
    }

    function countActiveRewardPool() public  view returns (uint256){
        uint length=0;
     for(uint i=0;i<rewardPool.length;i++){
         if(mapRewardPool[rewardPool[i]].isActive){
             length++;
         }
     }
      return  length;
    }
   function getRewardPool(uint index) public view  returns (address){
    
        return rewardPool[index];
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
        uint256 burnAmount;
        uint256 rewardAmount;
         uint totalActivePool=countActiveRewardPool();
         if (block.timestamp > beginFarming && totalActivePool>0) {
            (burnAmount,rewardAmount)=_caculateExtractAmount(amount);

        }     
        //div reward
        if(rewardAmount>0){
           
            uint eachPoolShare=rewardAmount.div(totalActivePool);
            for(uint i=0;i<rewardPool.length;i++){
                 if(mapRewardPool[rewardPool[i]].isActive){
                    _balances[rewardPool[i]] = _balances[rewardPool[i]].add(eachPoolShare);
                    emit Transfer(sender, rewardPool[i], eachPoolShare);

                 }
                
       
            }
        }


        //burn token
        if(burnAmount>0){
          _burn(sender,burnAmount);
            _balances[sender] = _balances[sender].add(burnAmount);//because sender balance already sub in burn

        }
      
        
        uint256 newAmount=amount-burnAmount-rewardAmount;

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
      
        _balances[recipient] = _balances[recipient].add(newAmount);
        emit Transfer(sender, recipient, newAmount);

        
        
    }

    
    function _deploy(address account, uint256 amount,uint256 beginFarmingDate) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        tokenOwner = account;
        beginFarming=beginFarmingDate;

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

    
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    
    function _caculateExtractAmount(uint256 amount)
        internal
        
        returns (uint256, uint256)
    {
       
            uint256 extractAmount = (amount * 5) / 1000;

            uint256 burnAmount = (extractAmount * 10) / 100;
            uint256 rewardAmount = (extractAmount * 90) / 100;

            return (burnAmount, rewardAmount);
      
    }

    function setBeginDeflationFarming(uint256 beginDate) public {
        require(msg.sender == tokenOwner, "ERC20: Only owner can call");
        beginFarming = beginDate;
    }

    function getBeginDeflationary() public view returns (uint256) {
        return beginFarming;
    }

    

}

contract ERC20Burnable is Context, ERC20 {
    
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

  
    function burnFrom(address account, uint256 amount) public virtual {
        _burnFrom(account, amount);
    }
}

abstract contract ERC20Detailed is IERC20 {
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
}

contract PolkaBridge is ERC20, ERC20Detailed, ERC20Burnable {
    constructor(uint256 initialSupply)
        public
        ERC20Detailed("PolkaBridge", "PBR", 18)
    {
        _deploy(msg.sender, initialSupply, 1616630400); //25 Mar 2021 1616630400
    }

    //withdraw contract token
    //use for someone send token to contract
    //recuse wrong user

    function withdrawErc20(IERC20 token) public {
        token.transfer(tokenOwner, token.balanceOf(address(this)));
    }
}

contract TokenRelease {
    using SafeMath for uint256;
    PolkaBridge private _polkaBridge;
    event TokensReleased(address beneficiary, uint256 amount);
    address payable private owner;
    // beneficiary of tokens after they are released
    string public name = "PolkaBridge: Token Vesting";

    struct Vesting {
        string Name;
        address Beneficiary;
        uint256 Cliff;
        uint256 Start;
        uint256 AmountReleaseInOne;
        uint256 MaxRelease;
        bool IsExist;
    }
    mapping(address => Vesting) private _vestingList;

    constructor(
        PolkaBridge polkaBridge,
        address team,
        address marketing,
        address eco,
        uint256 cliffTeam,
        uint256 cliffMarketing,
        uint256 cliffEco,
        uint256 amountReleaseInOneTeam,
        uint256 amountReleaseInOneMarketing,
        uint256 amountReleaseInOneEco,
        uint256 maxReleaseTeam,
        uint256 maxReleaseMarketing,
        uint256 maxReleaseEco
    ) public {
        _polkaBridge = polkaBridge;
        _vestingList[team].Name = "Team Fund";
        _vestingList[team].Beneficiary = team;
        _vestingList[team].Cliff = cliffTeam;
        _vestingList[team].Start = 1611248400;//22 jan 2021
        _vestingList[team].AmountReleaseInOne = amountReleaseInOneTeam;
        _vestingList[team].MaxRelease = maxReleaseTeam;
        _vestingList[team].IsExist = true;

        _vestingList[marketing].Name = "Marketing Fund";
        _vestingList[marketing].Beneficiary = marketing;
        _vestingList[marketing].Cliff = cliffMarketing;
        _vestingList[marketing].Start = 1616346000;//22 March 2021
        _vestingList[marketing]
            .AmountReleaseInOne = amountReleaseInOneMarketing;
        _vestingList[marketing].MaxRelease = maxReleaseMarketing;
        _vestingList[marketing].IsExist = true;

        _vestingList[eco].Name = "Ecosystem Fund";
        _vestingList[eco].Beneficiary = eco;
        _vestingList[eco].Cliff = cliffEco;
        _vestingList[eco].Start = 1616346000;//22 March 2021
        _vestingList[eco].AmountReleaseInOne = amountReleaseInOneEco;
        _vestingList[eco].MaxRelease = maxReleaseEco;
        _vestingList[eco].IsExist = true;

        owner = msg.sender;
    }

    function depositETHtoContract() public payable {}

    function addLockingFund(
        string memory name,
        address beneficiary,
        uint256 cliff,
        uint256 start,
        uint256 amountReleaseInOne,
        uint256 maxRelease
    ) public {
        require(msg.sender == owner, "only owner can addLockingFund");
        _vestingList[beneficiary].Name = name;
        _vestingList[beneficiary].Beneficiary = beneficiary;
        _vestingList[beneficiary].Cliff = cliff;
        _vestingList[beneficiary].Start = start;
        _vestingList[beneficiary].AmountReleaseInOne = amountReleaseInOne;
        _vestingList[beneficiary].MaxRelease = maxRelease;
        _vestingList[beneficiary].IsExist = true;
    }

    function beneficiary(address acc) public view returns (address) {
        return _vestingList[acc].Beneficiary;
    }

    function cliff(address acc) public view returns (uint256) {
        return _vestingList[acc].Cliff;
    }

    function start(address acc) public view returns (uint256) {
        return _vestingList[acc].Start;
    }

    function amountReleaseInOne(address acc) public view returns (uint256) {
        return _vestingList[acc].AmountReleaseInOne;
    }

    function getNumberCycle(address acc) public view returns (uint256) {
        return
            (block.timestamp.sub(_vestingList[acc].Start)).div(
                _vestingList[acc].Cliff
            );
    }

    function getRemainBalance() public view returns (uint256) {
        return _polkaBridge.balanceOf(address(this));
    }

    function getRemainUnlockAmount(address acc) public view returns (uint256) {
        return _vestingList[acc].MaxRelease;
    }

    function isValidBeneficiary(address _wallet) public view returns (bool) {
        return _vestingList[_wallet].IsExist;
    }

    function release(address acc) public {
        require(acc != address(0), "TokenRelease: address 0 not allow");
        require(
            isValidBeneficiary(acc),
            "TokenRelease: invalid release address"
        );

        require(
            _vestingList[acc].MaxRelease > 0,
            "TokenRelease: no more token to release"
        );

        uint256 unreleased = _releasableAmount(acc);

        require(unreleased > 0, "TokenRelease: no tokens are due");

        _polkaBridge.transfer(_vestingList[acc].Beneficiary, unreleased);
        _vestingList[acc].MaxRelease -= unreleased;

        emit TokensReleased(_vestingList[acc].Beneficiary, unreleased);
    }

    function _releasableAmount(address acc) private returns (uint256) {
        uint256 currentBalance = _polkaBridge.balanceOf(address(this));
        if (currentBalance <= 0) return 0;
        uint256 amountRelease = 0;
        //require(_start.add(_cliff) < block.timestamp, "not that time");
        if (
            _vestingList[acc].Start.add(_vestingList[acc].Cliff) >
            block.timestamp
        ) {
            //not on time

            amountRelease = 0;
        } else {
            uint256 numberCycle = getNumberCycle(acc);
            if (numberCycle > 0) {
                amountRelease =
                    numberCycle *
                    _vestingList[acc].AmountReleaseInOne;
            } else {
                amountRelease = 0;
            }

            _vestingList[acc].Start = block.timestamp; //update start
        }
        return amountRelease;
    }

    function withdrawEtherFund() public {
        require(msg.sender == owner, "only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough fund");
        owner.transfer(balance);
    }
}