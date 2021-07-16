//SourceUnit: RISK.sol

pragma solidity >=0.5.0 <0.6.0;


contract Context {
    
    
    constructor () internal { }
    

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

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract ERC20Detailed is IERC20 {
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RISK is Ownable, ERC20, ERC20Detailed {
    using SafeMath for uint256;

    uint256 public feePercent = 1; 

    uint256 public emitPerBlock = 0.011 * 10**18;
    uint256 public tokenPerPower = 0;
    uint256 public totalStakedPower = 0;
    uint256 public lastInspectedBlock = 0;

    uint256 roundingHelper = 1e21;

    uint256 public minterId = 0;
    mapping(address => bool) public minters;
    mapping(address => uint256) public addressToMinterId;
    mapping(uint256 => address) public minterIdToAddress;

    modifier onlyMinter {
        require(minters[msg.sender] == true, "only minters allowed");
        _;
    }

    struct PowerStaker {
        uint256 amount;
        uint256 paid;
    }

    
    IERC20 public funny;

    mapping(address => PowerStaker) public powerStakers;

    struct Liquidity {
        uint256 totalPower;
        uint256 ttReserve;
        uint256 riskReserve;
    }

    Liquidity public liquidity;

    mapping(address => uint256) public powers;

    event LiquidityChange(
        address indexed who,
        uint256 ttReserve,
        uint256 riskReserve
    );
    event Swap(address indexed who, bool buy, uint256 tt, uint256 risk);
    event TTReturned(address indexed who, uint256 tt);
    event RiskReturned(address indexed who, uint256 risk);
    event PowerModified(
        address indexed who,
        bool adding,
        uint256 amount,
        uint256 totalAmount
    );
    event StakedPowerModified(
        address indexed who,
        bool adding,
        uint256 totalFreePower,
        uint256 totalStakedPower,
        uint256 paid,
        uint256 tokenPerPower,
        uint256 lastInspectedBlock,
        uint256 totalNetworkStakedPower
    );

    constructor() public ERC20Detailed("Serious Risk", "RISK", 18) {
        _mint(msg.sender, 45_000 * 10**18);
        funny = IERC20(address(this));

        ++minterId;
        minters[msg.sender] = true;
        addressToMinterId[msg.sender] = minterId;
        minterIdToAddress[minterId] = msg.sender;
    }

    function mint(address who, uint256 amount) public onlyMinter {
        _mint(who, amount);
    }

    function setMinter(address minter, bool minting) public onlyMinter {
        minters[minter] = minting;
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function swapOutput(
        uint256 input,
        uint256 inputReserve,
        uint256 outputReserve
    ) public view returns (uint256) {
        return
            input.mul(100 - feePercent).mul(outputReserve).div(
                inputReserve.mul(100).add(input.mul(100 - feePercent))
            );
    }

    function initSwap(uint256 riskAmount) public payable {
        if (liquidity.totalPower == 0) {
            funny.transferFrom(msg.sender, address(this), riskAmount);

            powers[msg.sender] = msg.value;
            liquidity.totalPower = msg.value;
            liquidity.ttReserve = msg.value;
            liquidity.riskReserve = riskAmount;

            emit LiquidityChange(
                msg.sender,
                liquidity.ttReserve,
                liquidity.riskReserve
            );

            emit PowerModified(msg.sender, true, msg.value, msg.value);
        } else {
            
            msg.sender.transfer(msg.value);
        }
    }

    function buy(uint256 minReceive) public payable {
        uint256 amount = msg.value;

        
        require(amount > 0, "invalid value");

        uint256 part = amount.div(2);

        
        uint256 output =
            swapOutput(part, liquidity.ttReserve, liquidity.riskReserve);

        require(output >= minReceive, "slippage");

        emit Swap(msg.sender, true, part, output);

        liquidity.ttReserve = liquidity.ttReserve.add(part);
        liquidity.riskReserve = liquidity.riskReserve.sub(output);

        _getPower(output, part);
    }

    function sell(uint256 amount, uint256 minReceive) public {
        if (amount > 0) {
            funny.transferFrom(msg.sender, address(this), amount);

            uint256 output =
                swapOutput(amount, liquidity.riskReserve, liquidity.ttReserve);

            require(output >= minReceive, "slippage");

            emit Swap(msg.sender, false, output, amount);

            liquidity.riskReserve = liquidity.riskReserve.add(amount);
            liquidity.ttReserve = liquidity.ttReserve.sub(output);

            emit LiquidityChange(
                msg.sender,
                liquidity.ttReserve,
                liquidity.riskReserve
            );

            msg.sender.transfer(output);
        }
    }

    function powerValue(uint256 amount) public view returns (uint256, uint256) {
        if (liquidity.totalPower == 0 || liquidity.riskReserve == 0)
            return (0, 0);

        uint256 riskShare =
            liquidity.riskReserve.mul(amount).div(liquidity.totalPower);
        uint256 nativeShare =
            liquidity.ttReserve.mul(riskShare).div(liquidity.riskReserve);

        return (nativeShare, riskShare);
    }

    function burnPower(uint256 amount) public {
        if (amount > 0) {
            powers[msg.sender] = powers[msg.sender].sub(amount);

            emit PowerModified(msg.sender, false, amount, powers[msg.sender]);

            
            (uint256 nativeShare, uint256 riskShare) = powerValue(amount);

            msg.sender.transfer(nativeShare);
            funny.transfer(msg.sender, riskShare);

            liquidity.ttReserve = liquidity.ttReserve.sub(nativeShare);
            liquidity.riskReserve = liquidity.riskReserve.sub(riskShare);
            liquidity.totalPower = liquidity.totalPower.sub(amount);

            emit LiquidityChange(
                msg.sender,
                liquidity.ttReserve,
                liquidity.riskReserve
            );
        }
    }

    

    function _getPower(uint256 amount, uint256 amountTT) internal {
        uint256 TT_R = liquidity.ttReserve;
        uint256 RISK_R = liquidity.riskReserve;

        
        uint256 requiredTT = amount.mul(TT_R).div(RISK_R);
        uint256 requiredRISK = amountTT.mul(RISK_R).div(TT_R);

        
        
        
        

        if (requiredTT > amountTT) {
            
            requiredTT = amountTT;
            
            requiredRISK = requiredTT.mul(RISK_R).div(TT_R);

            
            
        } else if (requiredRISK > amount) {
            
            requiredRISK = amount;
            
            requiredTT = amount.mul(TT_R).div(RISK_R);
        }

        require(requiredRISK <= amount, "required risk exceed posted amount");
        require(requiredTT <= amountTT, "required tt exceed posted tt amount");

        if (amount > requiredRISK) {
            
            emit RiskReturned(msg.sender, amount.sub(requiredRISK));
            funny.transfer(msg.sender, amount.sub(requiredRISK));
        }

        if (amountTT > requiredTT) {
            
            emit TTReturned(msg.sender, amountTT.sub(requiredTT));
            msg.sender.transfer(amountTT.sub(requiredTT));
        }

        uint256 power = requiredTT;

        if (liquidity.totalPower > 0) {
            power = requiredTT.mul(liquidity.totalPower).div(TT_R);
        }

        liquidity.totalPower = liquidity.totalPower.add(power);
        liquidity.ttReserve = TT_R.add(requiredTT);
        liquidity.riskReserve = RISK_R.add(requiredRISK);

        powers[msg.sender] = powers[msg.sender].add(power);

        emit PowerModified(msg.sender, true, power, powers[msg.sender]);

        emit LiquidityChange(
            msg.sender,
            liquidity.ttReserve,
            liquidity.riskReserve
        );
    }

    function getPower(uint256 amount) public payable {
        require(amount > 0 && msg.value > 0, "innvalid power request");
        funny.transferFrom(msg.sender, address(this), amount);
        _getPower(amount, msg.value);
    }

    function updatePowerReward() public {
        if (totalStakedPower == 0) {
            lastInspectedBlock = block.number;
            return;
        }

        uint256 reward = block.number.sub(lastInspectedBlock).mul(emitPerBlock);

        if (reward > 0) {
            
            _mint(owner(), reward.div(10));
            
            tokenPerPower = tokenPerPower.add(
                reward.mul(roundingHelper).div(totalStakedPower)
            );
        }

        lastInspectedBlock = block.number;
    }

    function stakePower(uint256 amount) public {
        PowerStaker storage staker = powerStakers[msg.sender];

        powers[msg.sender] = powers[msg.sender].sub(amount);

        updatePowerReward();

        if (staker.amount > 0) {
            uint256 reward =
                tokenPerPower.mul(staker.amount).div(roundingHelper).sub(
                    staker.paid
                );
            _mint(msg.sender, reward);
        }

        if (amount > 0) {
            
            totalStakedPower = totalStakedPower.add(amount);
            staker.amount = staker.amount.add(amount);
        }

        staker.paid = tokenPerPower.mul(staker.amount).div(roundingHelper);

        emit StakedPowerModified(
            msg.sender,
            true,
            powers[msg.sender],
            staker.amount,
            staker.paid,
            tokenPerPower,
            lastInspectedBlock,
            totalStakedPower
        );
    }

    function unstakePower(uint256 amount) public {
        PowerStaker storage staker = powerStakers[msg.sender];
        updatePowerReward();

        require(amount <= staker.amount, "invalid amount");

        if (staker.amount > 0) {
            uint256 reward =
                tokenPerPower.mul(staker.amount).div(roundingHelper).sub(
                    staker.paid
                );
            _mint(msg.sender, reward);
        }

        if (amount > 0) {
            staker.amount = staker.amount.sub(amount);
            totalStakedPower = totalStakedPower.sub(amount);

            powers[msg.sender] = powers[msg.sender].add(amount);
        }

        staker.paid = tokenPerPower.mul(staker.amount).div(roundingHelper);

        emit StakedPowerModified(
            msg.sender,
            false,
            powers[msg.sender],
            staker.amount,
            staker.paid,
            tokenPerPower,
            lastInspectedBlock,
            totalStakedPower
        );
    }
}