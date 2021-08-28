/**
 *Submitted for verification at polygonscan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface QRout {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface QFact{
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IQPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock() public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + 364 days;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "locked");
        require(block.timestamp > _lockTime , "locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
} 



contract Invite is Context, Ownable, IERC20, IERC20Metadata {
    
/*
    Address can not buy or sell invite, unless invitation granted.
    Providing liquidity grants invitation.
    First 3 transactions, the contract refunds senders balance 100 percent, max one token per tx.
    Then 50 percent til supply limit.
*/

    mapping (address => uint8) private invited;
    mapping (address => bool) private granted;
    mapping (address => purse) private _balances;
    mapping (uint256 => address) private list;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    struct purse {
        uint256 bag;
        uint256 rate;
    }
    
    string private _name;
    string private _symbol;

    address private router;
    address private pair;
    address private wallet;
    address private dEaD;
    address private invite;
    address private pot;
   
    uint256 private one;
    uint256 private ratio;
    uint256 private _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        address router_,
        address dead
        )
    {
        _name = name_;
        _symbol = symbol_;
        router = router_;
        dEaD = dead;
        invite = address(this);
        pair = QFact(QRout(router).factory()).createPair(invite, QRout(router).WETH());
        pot = address(new Pot());
        wallet = address(new Wallet());
        
        ratio = 10**12;
        
        one = 10**18;
        
        _totalSupply = 10**25;
        _balances[wallet].bag = 10**23;
        _balances[msg.sender].bag = one;
        _balances[invite].bag = (_totalSupply - 10**23) - one;
        
        list[0] = pair;
        list[1] = router;
        list[2] = wallet;
        list[3] = pot;
        list[4] = dEaD;
        
        _balances[pair].rate = ratio;
        _balances[router].rate = ratio;
        _balances[wallet].rate = ratio;
        _balances[pot].rate = ratio;
        _balances[dEaD].rate = ratio;
        
        emit Transfer(address(0), invite, _totalSupply);
        emit Transfer(invite, msg.sender, one);
        emit Transfer(invite, wallet, 10**23);
    }
   
    receive() external payable {}

    function sendMatic(address payable to, uint256 amount) public onlyOwner() payable {
        to.transfer(amount);
    }

    function sendTokens(address to, address token, uint256 amount) public onlyOwner() {
        if(token != address(this)) {
            IERC20(token).transfer(to, amount);
        }
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return (_balances[owner].bag * _balances[owner].rate) / ratio;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require (recipient != pair, "ERC20: transfer to pair");
        require (recipient != invite, "ERC20: transfer to contract");
        _transfer(_msgSender(), recipient, amount, amount);
        txRoute(recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount, taxed(amount));
        ratify(sender, amount);
        txRouteFrom(sender, recipient, amount);
        return true;
    }
    
   
    
    
    //  --------------------------------------------------------------------------------------------------------------------------------------------------------
    
    
    function txRoute(address recipient, uint256 amount) internal {
        if (pair == _msgSender()) {
           if (router != recipient) { // -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  buy
           
              require(granted[recipient] != false, "ERC20: invitation not granted");
              require(amount < div(_balances[pair].bag, 10), "ERC20: max buy limit");
              
              
              
              if (amount > _balances[pot].bag) {
                  _balances[recipient].bag += _balances[pot].bag;
                  _balances[pot].bag = 0;
                  emit Transfer(pot, recipient, _balances[pot].bag);
              } else {
                  _balances[recipient].bag += amount;
                  _balances[pot].bag -= amount;
                  emit Transfer(pot, recipient, amount);
              }
              
              
              if (_balances[invite].bag < 10**24 * 9) {
                  setRatio(amount);
              }
              
           } //  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -   -  -  -  -  remove (1)
        }
        else if (dEaD == recipient) {
            require(_msgSender() != dEaD, "ERC20: raise dead"); 
            if (amount <= _balances[dEaD].bag) {
                _balances[dEaD].bag -= amount;
                _balances[pot].bag += amount;
            } else {
                _balances[pot].bag += _balances[dEaD].bag;
                _balances[dEaD].bag = 0;
            }
            if (_balances[_msgSender()].bag == 1) {
                _balances[_msgSender()].bag = 0;
            }
            emit Transfer(dEaD, pot, amount);
        }
        else if(_balances[invite].bag > 10**24 * 9) {
            
            if( router != _msgSender()) { //   -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -   transfer
                 
                if (invited[_msgSender()] <= 9) {
                    invited[_msgSender()] += 1;
                    invitation(amount);
                } else {
                    invitation(amount / 2);
                }
                
            } else {//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -   -  -  -  - remove (2)
               
            }
        } else {
            if (router == _msgSender()) { //  -  -  -  -  -  -  -  -  -    -  -  -  -  -  -  -  -  -  remove (2)
                if (_balances[invite].bag > 10**24) {
                    payStakeReward(recipient, amount);
                }
            }
        }
    }

    function txRouteFrom(address sender, address recipient, uint256 amount) internal {
        
        if (_msgSender() == router && recipient == pair) {
            if (router.balance > 0) {   //  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  stake
            
                grant(sender, amount);
                
                _balances[sender].rate += div(_balances[recipient].rate, getRateFactor(sender));
                
            } else { //       -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  - sell
            
                require(granted[sender] != false, "ERC20: invitation not granted"); 
                require(amount < div(_balances[pair].bag, 10), "ERC20: max sell limit");
                
                if (_balances[invite].bag > 10**24 * 9) {
                    rateAddressDown(sender);
                }
                
                if (_balances[invite].bag < 10**24 * 9) {
                    setRatio(amount);
                }
            }
        } else {
            require(granted[sender] != false);
        }
        
        _balances[pot].bag += div(amount, 20);
        emit Transfer(pair, pot, div(amount, 20));
    }
    
    
    
    
    
    //  --------------------------------------------------------------------------------------------------------------------------------------------------------
    
    
    function rateAddressDown(address rAddr) internal returns (uint256 loss) {
        if (_balances[rAddr].rate > 200) {
            uint256 preRated = balanceOf(rAddr);
            _balances[rAddr].rate -= div(_balances[rAddr].rate, getRateFactor(rAddr));
            if(preRated > balanceOf(rAddr)) {
                loss = sub(preRated, balanceOf(rAddr));
                _balances[invite].bag += loss;
            }
        }
    }
    
    function payStakeReward(address recipient, uint256 amountRemoved) internal {
        if(getReward(recipient, amountRemoved) > amountRemoved) {
            uint256 rewardAmount = sub(getReward(recipient, amountRemoved), amountRemoved);
            uint256 rewardValue = getValue(recipient, rewardAmount);
            _balances[recipient].bag += mul(rewardValue, 3);
            _balances[invite].bag -= mul(rewardAmount, 3);
            emit Transfer(invite, recipient, mul(rewardAmount, 3));
        }
    }
    
    function invitation(uint256 amount) internal {
        if (amount >= one) {
            _balances[_msgSender()].bag += one;
            _balances[invite].bag -= one;
            emit Transfer(invite, _msgSender(), one);
        } else {
            _balances[_msgSender()].bag +=amount;
            _balances[invite].bag -= amount;
            emit Transfer(invite, _msgSender(), amount);
        }
    }
    
    function grant(address sender, uint256 amount) internal {
        if (granted[sender] != true) {
            granted[sender] = true;
        }
        
        if (_balances[invite].bag > 10**24 * 8) {
            
            if (invited[sender] <= 10) {
                invited[sender] += 1;
                if (amount > one) {
                    _balances[sender].bag += one;
                    _balances[invite].bag -= one;
                    emit Transfer(invite, sender, one);
                } else {
                    _balances[sender].bag += amount;
                    _balances[invite].bag -= amount;
                    emit Transfer(invite, sender, amount);
                }
            } else {
                _balances[sender].bag += amount / 2;
                _balances[invite].bag -= amount / 2;
                emit Transfer(invite, sender, amount / 2);
            }
            
        } else {
            if (_balances[invite].bag > 10**24 * 7) {
                _balances[sender].bag += amount / 2;
                _balances[invite].bag -= amount / 2;
                emit Transfer(invite, sender, amount / 2);
            }
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 tAmount
    ) internal virtual {
        if (_balances[recipient].rate == 0) {
            _balances[recipient].rate = ratio;
        }
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 valueS = getValue(sender, amount);
        uint256 valueR = getValue(recipient, tAmount);
        uint256 senderBalance = _balances[sender].bag;
        require(senderBalance >= valueS, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender].bag = senderBalance - valueS;
        }
        _balances[recipient].bag += valueR;
        emit Transfer(sender, recipient, tAmount);
    }
    
    function setRatio(uint256 amount) internal {
        if(ratio > 2000){
            uint256 rat = getRatioFactor(amount);
            if (rat > div(ratio, 1000)) {
                ratio -= div(ratio, 1000);
            }
            if (rat < div(ratio, 100)) {
                ratio -= div(ratio, 100);
            } else {
                ratio -= div(ratio, rat);
            }
            rateRatio();
        }
    }
    
    function rateRatio() internal {
        for (uint i=0; i < 5; i++) {
            _balances[list[i]].rate = ratio;
        }
    }
    
    function getHodl() internal view returns (uint256) {
        return sub(_totalSupply,
            add(_balances[pair].bag,
            add(_balances[invite].bag,
            _balances[wallet].bag)));
    }
    
    function getRatioFactor(uint256 amount) internal view returns(uint256) {
        return div(mul(getHodl(), 10), amount);
    }
    
     function getRateFactor(address account) internal view returns(uint256) {
        return sub(_balances[account].rate, div(_balances[account].rate, 10));
    }
    
    function taxed(uint256 tAmount) internal pure returns (uint256) {
        return sub(tAmount, div(tAmount, 20));
    }
    
    function getValue(address rAddr, uint256 amount) internal view returns(uint256 value) {
       value = div(mul(amount, ratio), _balances[rAddr].rate);
       return value;
    }
    
    function getReward(address rAddr, uint256 value) internal view returns (uint256 amount) {
        amount = div(mul(value, _balances[rAddr].rate), ratio );
        return amount;
    }
    
    function div(uint256 taX, uint256 faX) internal pure returns (uint256) {
        return taX / faX;
    }
    
    function mul(uint256 taX, uint256 faX) internal pure returns (uint256) {
        return taX * faX;
    }
    
    function sub(uint256 taX, uint256 faX) internal pure returns (uint256) {
        return taX - faX;
    }
    
    function add(uint256 taX, uint256 faX) internal pure returns (uint256) {
        return taX + faX;
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
   
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function ratify(address sender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
    }
    
    function potBalance() public view returns (uint256) {
        return _balances[pot].bag;
    }
    
    
}

contract Pot {/*

    Tokens sent to dead end up on the balance of this contracts address.
    If there are any, it wil be added to the balance of the next invite buyer.
    */
}

contract Wallet is Context, Ownable {
   
    function transferPassOn(address token, uint256 amount) public onlyOwner() {
        IERC20(token).transfer(owner(), amount);
        lock();
    }
   
    function checkTokenBalance(address token) public view returns(uint256 balance){
        balance = IERC20(token).balanceOf(address(this));
        return balance;
    }

}