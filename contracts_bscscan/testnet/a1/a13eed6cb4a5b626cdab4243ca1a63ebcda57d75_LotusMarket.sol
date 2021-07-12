/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

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


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract LotusMarket is IERC20, Ownable {
    using SafeMath for uint256;

    struct Stake {
        uint256 amount;
        uint256 bonus;
        uint256 depositDate;
    }

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => Stake) private _stakes;

    //uint256 private constant SECONDS_PER_DAY = 3600;

    uint256 public constant SECONDS_PER_DAY = 86400;

    //uint256 private constant UNFREEZE_PERIOD = 7200;

    uint256 public constant UNFREEZE_PERIOD = 365 * 24 * 60 * 60;


    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private maxBurn;
    uint256 private burnt;
    uint256 private startDate;
    uint256 private bonusSupply;
    uint256 private ifoSupply;
    uint256 private foundSupply;
    uint256 private devSupply;
    uint256 private marketSupply;
    uint256 private ecoSupply;
    uint256 private partnerSupply;

    address private stakeWallet;
    address private saleWallet;
    //address private bonusWallet;
    address private ifoWallet;
    address private foundWallet;
    address private devWallet;
    address private marketWallet;
    address private ecoWallet;
    address private partnerWallet;

    event Burn(address indexed sender, uint256 amount);
    event _Stake(address indexed sender, uint256 amount, uint256 createdAt);
    event Withdraw(address indexed sender, uint256 amount);



    constructor () public {
        _decimals = 18;
        _name = "LotusMarket";
        _symbol = "LTS";

        //startDate = now;

        startDate = 1640998800;

        _totalSupply = 25000000 * 10 ** uint256(_decimals);

        maxBurn = 9871597 * 10 ** uint256(_decimals);

        bonusSupply = 17400000 * 10 ** uint256(_decimals);
        ifoSupply = 2500000 * 10 ** uint256(_decimals);
        foundSupply = 2500000 * 10 ** uint256(_decimals);
        devSupply = 1500000 * 10 ** uint256(_decimals);
        marketSupply = 500000 * 10 ** uint256(_decimals);
        ecoSupply = 350000 * 10 ** uint256(_decimals);
        partnerSupply = 250000 * 10 ** uint256(_decimals);


        stakeWallet = 0xa0Fa47E0802BE1eab2F6a2e4F909C51fC7d2c43f;
        saleWallet = 0x4B827b397baEDB206f659A4525161Bb8B8e68f82;
        //bonusWallet = 0x7dfeD7b27cE629068862d8e0f302E188eE8636C1;
        ifoWallet = 0x4ee28d54B68C608d9206f8F73CDA8D2360f08060;
        foundWallet = 0xD9EE1F77EF25e69dfe19Abb95b56130b53991424;
        devWallet = 0xA281D6d2cb248432cB242829Ec21f9B006f39c4F;
        marketWallet = 0x09529618Aa8357E0F23F9391DDC479C1ce8f5EA9;
        ecoWallet = 0x98328c35c9B495F8E184B3f41AB461d5EAB179B4;
        partnerWallet = 0x9bc3753e2446E3cCeEeDe33e7f5e0F82eD01f9E8;

        _balances[address(this)] = bonusSupply;
        _balances[ifoWallet] = ifoSupply;
        _balances[foundWallet] = foundSupply;
        _balances[devWallet] = devSupply;
        _balances[marketWallet] = marketSupply;
        _balances[ecoWallet] = ecoSupply;
        _balances[partnerWallet] = partnerSupply;

        emit Transfer(address(0), address(this), bonusSupply);
        emit Transfer(address(0), ifoWallet, ifoSupply);
        emit Transfer(address(0), foundWallet, foundSupply);
        emit Transfer(address(0), devWallet, devSupply);
        emit Transfer(address(0), marketWallet, marketSupply);
        emit Transfer(address(0), ecoWallet, ecoSupply);
        emit Transfer(address(0), partnerWallet, partnerSupply);
    }


    function getStart() public view returns (uint256) {
        return startDate;
    }

    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view override returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
        uint256 sdays = now.sub(_stakes[account].depositDate).div(SECONDS_PER_DAY);
        uint256 bonus = _stakes[account].amount.mul(sdays).mul(2).div(1000);
        return _balances[account].add(_stakes[account].amount).add(_stakes[account].bonus.add(bonus));
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _transfer(address sender, address recepient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recepient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        if (recepient != saleWallet && recepient != stakeWallet && sender != foundWallet && sender != devWallet) {
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recepient] = _balances[recepient].add(amount);
            emit Transfer(sender, recepient, amount);
        }

        if (recepient == saleWallet) {
            sellAndBurn(sender, amount);
        }

        if (recepient == stakeWallet) {
            addStake(msg.sender, amount);
        }

        if (sender == foundWallet) {
            uint256 available = getUnfrozen(foundSupply, _balances[foundWallet]);
            require(amount <= available, "Insufficient unfrozen amount");
            available = available > amount ? amount : available;
            _balances[sender] = _balances[sender].sub(available, "ERC20: transfer amount exceeds balance");
            _balances[recepient] = _balances[recepient].add(available);
            emit Transfer(sender, recepient, available);
        }
        if (sender == devWallet) {
            uint256 available = getUnfrozen(devSupply, _balances[devWallet]);
            require(amount <= available, "Insufficient unfrozen amount");
            available = available > amount ? amount : available;
            _balances[sender] = _balances[sender].sub(available, "ERC20: transfer amount exceeds balance");
            _balances[recepient] = _balances[recepient].add(available);
            emit Transfer(sender, recepient, available);
        }

    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function sellAndBurn(address sender, uint256 amount) public {
        uint256 toBurn = amount.mul(5).div(100);
        uint256 toSend;
        if (burnt == maxBurn) {
            toBurn = 0;
        } else if (burnt.add(toBurn) > maxBurn) {
            toBurn = maxBurn.sub(burnt);
        }
        toSend = amount.sub(toBurn);
        if (toBurn > 0) {
            _totalSupply = _totalSupply.sub(toBurn);
            emit Burn(sender, toBurn);
            emit Transfer(sender, address(0), toBurn);
        }
        _balances[sender] = _balances[sender].sub(amount);
        _balances[saleWallet] = _balances[saleWallet].add(toSend);
         emit Transfer(sender, saleWallet, toSend);
    }


    function getUnfrozen(uint256 initialAmount, uint256 currentBalance) internal view returns (uint256) {
        uint256 available;
        uint256 x = uint256(now.sub(startDate).div(UNFREEZE_PERIOD));
        require(x > 0);
        x = x > 5 ? 5 : x;
        available = currentBalance.sub(initialAmount.sub(initialAmount.mul(x).div(uint(5))));
        return available;
    }


    function showStake(address sender) public view returns (uint256, uint256, uint256) {
        uint256 sdays = now.sub(_stakes[sender].depositDate).div(SECONDS_PER_DAY);
        uint256 bonus = _stakes[sender].amount.mul(sdays).mul(2).div(1000);
        return (_stakes[sender].amount, _stakes[sender].bonus.add(bonus), _stakes[sender].depositDate);
    }


    function addStake(address sender, uint256 amount) public {
        if  (_stakes[sender].amount > 0) {
            uint256 sdays = (now.sub(_stakes[sender].depositDate)).div(SECONDS_PER_DAY);
            uint256 bonus = _stakes[sender].amount.mul(sdays).mul(2).div(1000);
            require(_balances[address(this)] >= bonus, "ERC20: Not enough tokens on contract for reward");
            _balances[address(this)] = _balances[address(this)].sub(bonus);
            _stakes[sender].bonus = _stakes[sender].bonus.add(bonus);
        }
        _stakes[sender].amount = _stakes[sender].amount.add(amount);
        _stakes[sender].depositDate = now;
        _balances[sender] = _balances[sender].sub(amount);
        _balances[stakeWallet] = _balances[stakeWallet].add(amount);
        emit _Stake(sender, amount, _stakes[sender].depositDate);
        emit Transfer(sender, stakeWallet, amount);

    }


    function withdraw(address sender, uint256 amount) public {
        uint256 sdays = now.sub(_stakes[sender].depositDate).div(SECONDS_PER_DAY);
        uint256 bonus = _stakes[sender].amount.mul(sdays).mul(2).div(1000).add(_stakes[sender].bonus);
        require(_stakes[sender].amount.add(bonus) >= amount, "Insufficient staked amount and bonus to withdraw");
        if (amount <= _stakes[sender].amount) {
            _stakes[sender].amount = _stakes[sender].amount.sub(amount);
            _balances[stakeWallet] = _balances[stakeWallet].sub(amount);
        } else {
            uint256 new_bonus = bonus.add(_stakes[sender].amount).sub(amount);
            _stakes[sender].amount = 0;
            _stakes[sender].bonus = new_bonus;
            _balances[stakeWallet] = _balances[stakeWallet].sub(_stakes[sender].amount);
        }

        _balances[sender] = _balances[sender].add(amount);
        _stakes[sender].depositDate = now;
        emit Transfer(stakeWallet, sender, amount);
        emit Withdraw(sender, amount);
    }


    fallback () external {}

}