/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

/*  _______________________________________________________________
                      PRESALE DETAILS |

    1. Presale Start    : 1614171600 [FEB 24, 2021] [1 PM UTC]
    2. Presale End      : 1614344400 [FEB 26, 2021] [1 PM UTC]  
    3. Base Price       : 1 ETH = 1000 APEAPE                  
    4. Max Purchase     : 3 ETH                                
    5. HARD CAP         : 60 ETH                               
    _______________________________________________________________
                    | APE APE DETAILS |

    1. Total Supply       : 100K                                |
    2. APEAPE Unlock Time : 1614430800 [FEB 27, 2021] [1PM UTC] | *
    3. Burn               : 1%                                  | 
    4. Total Supply       : 100K                                |
    5. Last20 Tx Fee      : 1%                                  |
    6. Reward Collector   : 3% from last 7 days token transfers | 
    _______________________________________________________________
    
    -Codezeros Developers
    -https://www.codezeros.com/
    _______________________________________________________________
*/


// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
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

contract Context {
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract BasicToken is IERC20, Context, Ownable {
    using SafeMath for uint256;
    uint256 public _totalSupply;
    mapping(address => uint256) balances_;
    mapping(address => uint256) ethBalances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 public unlockDuration = 72 hours;                               // ----| Lock transfers for non-owner |------

    uint256 public startTime = 1614171600;                                  // ------| Deploy Timestamp |--------
    uint256 public rewardDispatchStartTime = startTime.add(unlockDuration); // ------| Start after 72 hours |--------

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances_[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function checkInvestedETH(address who) public view returns (uint256) {
        return ethBalances[who];
    }
}

abstract contract StandardToken is BasicToken {
    using SafeMath for uint256;

    uint256 public lastTwentyTxReward = 0;               //----| Stores 1 % form last 20 transactions|-----
    uint256 public tokensToBurn;                         //------| Burns 1 % token on each transfer |------
    uint256 public StakingContractFee = 0;
    uint256 public transferCounter = 0;

    address public stakingContract;
    address public rewardCollector;

    uint256 public realStakingContractFee;               

    function setupContract(address _stakingContract, address _rewardCollector) public onlyOwner {
       
        require(stakingContract == address(0),"Staking Contract is already set");
        require(rewardCollector == address(0),"Reward Collector Contract is already set");

        stakingContract = _stakingContract;
        rewardCollector = _rewardCollector;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        
        if (msg.sender == stakingContract ||  msg.sender == rewardCollector || msg.sender == owner()) {
                                        
            _transferSpecial(msg.sender, recipient, amount);

        } else {

            _transfer(msg.sender, recipient, amount);

        }

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {

        if (msg.sender == stakingContract ||  msg.sender == rewardCollector || msg.sender == owner()) {

            _transferSpecial(sender, recipient, amount);

        } else {
          
            _transfer(sender, recipient, amount);
        }

        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function findOnePercent(uint256 amount) internal pure returns (uint256) {
        return amount.mul(10).div(1000);
    }

    function findThreePercent(uint256 amount) internal pure returns (uint256) {
        return amount.mul(30).div(1000);
    }

    function findFivePercent(uint256 amount) internal pure returns (uint256) {
        return amount.mul(50).div(1000);
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

        balances_[sender] = balances_[sender].sub(
            amount,
            "ERC20 Special: transfer amount exceeds balance"
        );
        balances_[recipient] = balances_[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(stakingContract != address(0), "Staking contract is not set");
        require(rewardCollector != address(0), "RewardCollector contract is not set");

        require(
            block.timestamp >= startTime.add(unlockDuration), "Tokens not unlocked yet");


        tokensToBurn = findOnePercent(amount);                               //---| 1% ===> Burn |-----------------
        lastTwentyTxReward = lastTwentyTxReward + findOnePercent(amount);    //---| 1% ===> Last20Tx Collection|---
        StakingContractFee = StakingContractFee + findThreePercent(amount);  //---| 3% ===> Reward Collector |-----

        uint256 tokensToTransfer = amount.sub(findFivePercent(amount), "overflow");        //---| Net Amount Received |----------

        _totalSupply = _totalSupply.sub(tokensToBurn);                       //---| Remove from Total Supply |-----

        balances_[sender] = balances_[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );

        balances_[recipient] = balances_[recipient].add(tokensToTransfer);

        transferCounter = transferCounter + 1;

        if (transferCounter == 20) {
            
            balances_[sender] = balances_[sender].add(lastTwentyTxReward); //---| Rewards last 20 Transactions |-----
            transferCounter = 0;

            emit Transfer(address(0), sender, lastTwentyTxReward);
            lastTwentyTxReward = 0;
        }

        if (block.timestamp > rewardDispatchStartTime.add(7 days)) {   //-|Transfer rewards to RewardCollector every 7 days |--
            balances_[rewardCollector] = balances_[rewardCollector].add(
                StakingContractFee
            );

            realStakingContractFee = StakingContractFee;
            StakingContractFee = 0;
            rewardDispatchStartTime = block.timestamp;

            emit Transfer(
                address(this),
                rewardCollector,
                realStakingContractFee
            );
        }

        emit Transfer(sender, recipient, tokensToTransfer);
        emit Transfer(sender, address(0), tokensToBurn);
    }
    
}

contract Configurable {
    uint256 public cap = 60000 * 10**18;                 //---------| Tokens for Presale |---------
    uint256 public basePrice = 1000 * 10**18;            //-----| 1 ETH = 1000 Tokens |---------
    uint256 public tokensSold;
    uint256 public tokenReserve = 100000 * 10**18;       //-----------| Total Supply = 100 K |------
    uint256 public remainingTokens;
}

contract PreSaleToken is StandardToken, Configurable { 
    using SafeMath for uint256;
    enum Phases {none, start, end}
    Phases public currentPhase;

    constructor() {
       
        currentPhase = Phases.none;
        balances_[owner()] = balances_[owner()].add(tokenReserve);
        _totalSupply = _totalSupply.add(tokenReserve);
        remainingTokens = cap;
        emit Transfer(address(this), owner(), tokenReserve);
    }

    receive() external payable {
        require(
            currentPhase == Phases.start,
            "The presale has not started yet"
        );
        require(remainingTokens > 0, "Presale token limit reached");

        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(basePrice).div(1 ether);
    
        ethBalances[msg.sender] = ethBalances[msg.sender].add(weiAmount); // Track each user investments
        ethBalances[address(this)] = ethBalances[address(this)].add(weiAmount); // Track this contract's funds

        require(
            ethBalances[msg.sender] <= 3e18,
            "You are exceeding max 3 ETH of purchase"
        );
        require(
            ethBalances[address(this)] <= 60e18,
            "Sorry! target amount of 60 ETH has been achieved"
        );

        if (tokensSold.add(tokens) > cap) {
            revert("Exceeding limit of presale tokens");
        }

        tokensSold = tokensSold.add(tokens); // counting tokens sold
        remainingTokens = cap.sub(tokensSold);

        balances_[owner()] = balances_[owner()].sub(
            tokens,
            "ERC20: transfer amount exceeds balance"
        );

        balances_[msg.sender] = balances_[msg.sender].add(tokens);

        emit Transfer(address(this), msg.sender, tokens);

        payable(owner()).transfer(weiAmount);
    }

    function startPresale() public onlyOwner {
        require(currentPhase != Phases.end, "The coin offering has ended");
        currentPhase = Phases.start;
    }

    function endPresale() public onlyOwner {
        require(currentPhase != Phases.end, "The presale has ended");
        currentPhase = Phases.end;
    }

}

contract Presale is PreSaleToken {
    string public name = "ApeApe Finance";
    string public symbol = "APEAPE";
    uint32 public decimals = 18;
}