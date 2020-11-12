pragma solidity ^0.7.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.7.4;

contract Context {
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

pragma solidity ^0.7.4;

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

pragma solidity ^0.7.4;

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() override public view returns (uint256) {
        
        
        return _totalSupply;
    }

    function balanceOf(address account)override public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)override public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) override
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)override public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )override public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "ERC20: burn amount exceeds allowance"
            )
        );
    }
}

pragma solidity >=0.4.22 <0.8.0;

// "SPDX-License-Identifier: MIT"

contract SpringField is ERC20 {
    using SafeMath for uint256;
    IERC20 public token;
    IERC20 public lpToken;
    uint256 public initialBlock;
    uint8 public decimals = 18;
    address[] stakers;
    string public name;
    string public symbol;
    address public owner;
   
    struct stakeData {
        address staker;
        uint256 amount;
        uint256 blockNumber;
      
    }

    mapping(address => mapping(uint256 => stakeData)) public stakes;
    mapping(address => uint256) public stakeCount;
    mapping(address => uint256) public takenRewards;

    constructor(IERC20 _token,IERC20 _lpToken) {
        token = _token;
        lpToken = _lpToken;
        name = "SpringField";
        symbol = "ySIMF";
        initialBlock = block.number;
        owner = msg.sender;
     
    }

    function enter(uint256 _amount) public {
        require(initialBlock+2389091>block.number,"Staking Period Over");
        bool available = false;
        uint256 usersTokens= lpToken.balanceOf(msg.sender);
        uint256 allowedTokens = lpToken.allowance(msg.sender, address(this));
        require(usersTokens>= _amount, "Insufficient Balance to Stake");
        require(allowedTokens >= _amount, "Allowed balance is Insufficient");
        lpToken.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
        stakes[msg.sender][stakeCount[msg.sender]] = stakeData(
            msg.sender,
            _amount,
            block.number
        );
        stakeCount[msg.sender] += 1;
        for(uint i=0;i<stakers.length;i++){
            if(stakers[i]==msg.sender){
                available=true;
                break;
            }else{
                continue;
            }
        }
        if(!available){
            stakers.push(msg.sender);
        }
    }

    function getrewards() public {
   require(block.number>stakes[msg.sender][0].blockNumber+6545,"Cannot get rewards until 24 hours from the stake");
    
     uint256 rewards =_rewards(msg.sender);
        for(uint256 i = 0; i <stakeCount[msg.sender];i++){
            if(initialBlock+2389091<block.number){
      stakes[msg.sender][i].blockNumber=initialBlock+2389091;
}else{
  stakes[msg.sender][i].blockNumber=block.number;
} 
      }
     takenRewards[msg.sender]+=rewards;
        token.transfer(msg.sender, rewards);
    }

    function unstake() public {
   require(block.number>stakes[msg.sender][0].blockNumber+6545,"Cannot unstake until 24 hours from the stake");
    uint256 stakeAmount=0;
    
      uint256 reward = _rewards(msg.sender);
      for(uint256 i = 0; i <stakeCount[msg.sender];i++){
          stakeAmount+= stakes[msg.sender][i].amount;
        
        stakes[msg.sender][i]=stakeData(
            msg.sender,0,block.number
        );
      }
           takenRewards[msg.sender]+=reward;
        _burn(msg.sender, stakeAmount);
        token.transfer(msg.sender, reward);
        lpToken.transfer(msg.sender,stakeAmount);

    }


    function _rewards(address adrs) private view returns (uint256) {
    uint256 reward;
    uint256 totalRewards;
    uint256 stakeAmount;
    uint256 denominator;
    uint256 finalBlock=block.number;
    
if(initialBlock+2389091<block.number){
    finalBlock = initialBlock+2389091;
}
      for(uint256 j = 0; j < stakers.length; j++){
             totalRewards+= takenRewards[stakers[j]];
        for(uint256 i = 0; i <stakeCount[stakers[j]];i++){
denominator += (stakes[stakers[j]][i].amount)*(finalBlock-stakes[stakers[j]][i].blockNumber);          
        }}
   if(denominator==0){
       return 0;
   }
    
    for(uint256 i = 0; i <stakeCount[adrs];i++){
          stakeAmount+= (stakes[adrs][i].amount)*(finalBlock-stakes[adrs][i].blockNumber);
      }
   reward = stakeAmount*((11000*(10**18)*(finalBlock-initialBlock)/(2389091))-totalRewards)/denominator;
    return reward;
    }
    function myReward(address adrs)public view returns (uint256){
        return _rewards(adrs);
    }

    function getApy()public view returns(uint256){
    uint256 apy;
    uint256 stakeAmount;
    uint256 totalRewards;

      for(uint256 j = 0; j < stakers.length; j++){
           
        for(uint256 i = 0; i <stakeCount[stakers[j]];i++){
            stakeAmount += stakes[stakers[j]][i].amount;          
        }}
     for(uint256 k = 0; k < stakers.length; k++){
             totalRewards+= takenRewards[stakers[k]];
    }
       apy = ((11000-totalRewards)*(10**20))/stakeAmount;
    return apy;
    }
    

}