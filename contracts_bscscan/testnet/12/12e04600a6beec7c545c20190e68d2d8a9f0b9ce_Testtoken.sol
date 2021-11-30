/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity >=0.6.0;


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
    function transferWithoutDeflationary(address recipient, uint256 amount) external returns (bool) ;
   
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    struct PoolAddress{
        address poolReward;
        bool isActive;
        bool isExist;

    }

    struct WhitelistTransfer{
        address waddress;
        bool isActived;
        string name;

    }
    mapping (address => uint256) private _balances;

    mapping (address => WhitelistTransfer) public whitelistTransfer;

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

    function addWhitelistTransfer(address add, string memory name) public{
         require(_msgSender() == tokenOwner, "ERC20: Only owner can init");
         whitelistTransfer[add].waddress=add;
        whitelistTransfer[add].isActived=true;
        whitelistTransfer[add].name=name;

    }

     function removeWhitelistTransfer(address add) public{
         require(_msgSender() == tokenOwner, "ERC20: Only owner can init");
        
        whitelistTransfer[add].isActived=false;
        

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
        if(whitelistTransfer[recipient].isActived || whitelistTransfer[_msgSender()].isActived){//withdraw from exchange will not effect
            _transferWithoutDeflationary(_msgSender(), recipient, amount);
        }
        else{
            _transfer(_msgSender(), recipient, amount);
        }
        
        return true;
    }
 function transferWithoutDeflationary(address recipient, uint256 amount) public virtual override returns (bool) {
        _transferWithoutDeflationary(_msgSender(), recipient, amount);
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
    
 function _transferWithoutDeflationary(address sender, address recipient, uint256 amount) internal virtual {
          require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        
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

contract Testtoken is ERC20, ERC20Detailed, ERC20Burnable {
    constructor(uint256 initialSupply)
        public
        ERC20Detailed("Testtoken", "TST", 18)
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