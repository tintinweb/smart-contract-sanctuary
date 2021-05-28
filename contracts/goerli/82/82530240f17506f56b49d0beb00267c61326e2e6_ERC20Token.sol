/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

/**
 *Submitted for verification at Etherscan.io on 2019-04-20
*/

pragma solidity 0.5.2;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Mint(address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract Modifiers
{
    address _owner;
      
    constructor(address owner) public
    {
        _owner=owner;
    }
    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    
    function isOwner() private view returns (bool) {
        return msg.sender == _owner;
    }
}


contract ERC20Token is IERC20 ,Modifiers {

    using SafeMath for uint256;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    //Amount to be minted for reward,ico and vesting.
    uint256 public rewardMintAmount=25000;
    uint256 public icoMintAmount=25000;
    uint256 public vestMintAmount=50000;
    
    //Amount minted for reward,ico and vesting
    uint256 private rewardMintedAmount;
    uint256 private icoMintedAmount;
    uint256 private vestMintedAmount;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    uint256 private _totalSupply;
    
    constructor(string memory _type) public Modifiers(msg.sender)
    {
        _name = "MAG";
        _symbol = "MG";
        _decimals = 6;
        _totalSupply=100000 * (10 ** uint256(decimals()));
        _mint(msg.sender,25000,_type);
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

    function balanceOf(address account) public view  returns (uint256) {
        return getBalance(account);
    }
 
    function allowance(address owner, address spender) public view  returns(uint256 remaining)
    {
        return getAllowed(owner, spender);
    }
    
    //Transfer token fro one to another
    function transfer(address recipient, uint256 amount) public  returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
       _transfer(sender, recipient, amount);
     
       uint256 currentAllowance = getAllowed(msg.sender,sender);
       require(currentAllowance >= amount, "TRC20: transfer amount exceeds allowance");
       _approve(sender, _owner, currentAllowance - amount);

        return true;
    }

    function approve(address spender, uint256 amount) public onlyOwner  returns (bool) {
        _approve(spender,_owner, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public onlyOwner returns (bool) {
         uint256 currentAllowance = getAllowed(msg.sender, spender);
        _approve( spender, _owner,currentAllowance + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public onlyOwner returns (bool) {
        uint256 currentAllowance = getAllowed(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "TRC20: decreased allowance below zero");
        _approve( spender,_owner,currentAllowance - subtractedValue);

        return true;
    }
    
    function mint(uint256 _amount,string memory _type) public onlyOwner returns (bool) {
        _mint(_owner,_amount,_type);
        return true;
    }


    function _transfer(address caller, address to, uint256 amount) internal 
    {
        require(caller != address(0), "TRC20: transfer from the zero address");
        require(to != address(0), "TRC20: transfer to the zero address");

        uint256 senderBalance = getBalance(caller);
        require(senderBalance >= amount, "TRC20: transfer amount exceeds balance");
        amount=amount* 10 ** uint256(decimals());
        subBalance(caller, amount);
        addBalance(to, amount);
        emit Transfer(caller, to, amount);

    }

    function _approve(address spender, address owner, uint256 amount) internal  
    {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");
        amount=amount* 10 ** uint256(decimals());
        setAllowed(owner, spender, amount);
        emit Approval(owner, spender, amount);
    }
    
    function _mint(address account, uint256 amount,string memory  _type) internal  {
        require(account != address(0) && amount>0, "TRC20: mint to the zero address");
        if( keccak256(abi.encodePacked(_type))== keccak256(abi.encodePacked("ICO")))
        {
            uint256 _icoAmount=icoMintedAmount.add(amount);
            require(icoMintAmount>=amount && icoMintAmount>=_icoAmount,"Amount must be less than the ico minted amount");
            icoMintedAmount=_icoAmount;
        }else if(keccak256(abi.encodePacked(_type))== keccak256(abi.encodePacked("Vesting")))
        {
            uint256 _vestAmount=vestMintedAmount.add(amount);
            require(vestMintAmount>=amount && vestMintAmount>=_vestAmount,"Amount must be less than the vested minted amount");
            vestMintedAmount=_vestAmount;
        }else if(keccak256(abi.encodePacked(_type))== keccak256(abi.encodePacked("Reward")))
        {
            uint256 _rewardAmount=rewardMintedAmount.add(amount);
            require(rewardMintAmount>=amount && rewardMintAmount>=_rewardAmount,"Amount must be less than the reward minted amount");
            rewardMintedAmount=_rewardAmount;
        }
        setBalance(account,balances[account].add(amount * (10 ** uint256(decimals()))));
        emit Mint( account, amount);
    }
    
    function _burn(address account, uint256 amount) internal  {
        require(account != address(0), "TRC20: burn from the zero address");

        uint256 accountBalances = getBalance(account);
        require(accountBalances >= amount, "TRC20: burn amount exceeds balance");
        setBalance(account,accountBalances - amount);
        updateTotalSupplyBalance(_totalSupply = _totalSupply.add(amount));

        // emit Transfer(account, address(0), amount);
    }
    
    function addBalance(address to, uint256 amount) internal
    {
        //self.totalSupply = TokenStorage.totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
    }


    function subBalance(address from, uint256 amount) internal
    {
        //self.totalSupply = self.totalSupply.sub(amount);
        balances[from] = balances[from].sub(amount);
    }


    function setAllowed(address owner, address spender, uint256 amount)  internal
    {
        allowed[owner][spender] = amount;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function getBalance(address who) public view returns (uint256)
    {
        return balances[who];
    }
    
    function setBalance(address who,uint256 amount)  internal
    {
         balances[who]=amount;
    }

    function getAllowed(address owner, address spender) internal view returns (uint256)
    {
        return allowed[owner][spender];
    }
    
    function updateTotalSupplyBalance( uint256 amount) internal
    {
         _totalSupply=amount;
    }
}