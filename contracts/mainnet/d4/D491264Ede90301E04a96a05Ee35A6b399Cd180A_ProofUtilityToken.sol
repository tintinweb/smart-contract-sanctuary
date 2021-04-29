/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

/*****************************

** PROOF UTILITY TOKEN (PRF) **
   Developed by @cryptocreater
   Produced by PROOF CAPITAL GROUP

** TOKEN INFO **
   Name:     PROOF UTILITY
   Code:     PRF
   Decimals: 6

** PRF TOKEN MARKETING **
   1. The maximum emission of the PROOF UTILITY token is 1 000 000 000 PRF.
   2. Initial emission of PROOF UTILITY token to replace PROOF TOKEN - 200 000 PRF.
   3. Renumeration for the founders of the PRF (bounty) - 1% of the total emission of PRF (accrued as the release of PRF tokens).
   4. The minimum balance to receive a staking profit is 10 PRF.
   5. The maximum balance for receiving staking profit is 999 999 PRF.
   6. The profit for holding the token, depending on the balance, per 1 day is: from 10 PRF - 0.10%, from 100 PRF - 0.13%, from 500 PRF - 0.17%, from 1 000 PRF - 0.22%, from 5 000 PRF - 0.28%, from 10 000 PRF - 0.35%, from 50 000 PRF - 0.43%, from 100 000 PRF - 0.52%, from 500 000 PRF - 0.62% and is fixed per second for each transaction at the address, excluding the PROOF ASSET smart contract profit, which receives a reward of 0.62% regardless of the amount of the balance.
   7. When transferring PRF to an address that has not previously received PRF tokens, this address becomes a follower (referral) of the address from which the PRFs were received (referrer).
   8. When calculating a profit for a referral, the referrer receives a referral reward from the amount received by the referral for holding the PRF token.
   9. The minimum balance to receive a referral reward is 100 PRF.
  10. The maximum balance for receiving a referral reward is 1 000 000 PRF.
  11. Referral reward is calculated from the amount of the referral profit and depends on the referrer balance: from 100 PRF - 5.2%, from 1 000 PRF - 7.5%, from 10 000 PRF - 12.8%, from 100 000 PRF - 26.5%.
  12. When calculating all types of profits and rewards, the rule of complication applies, which reduces the income by the percentage of the current supply of the PRF token to it's maximum supply.

** PRF TOKEN MECHANICS **
   1. To receive PRF tokens, you need to send the required number of ETH tokens to the address of the PROOF UTILITY smart contract.
   2. The smart contract issues the required number of PRF tokens to the address from which the ETH tokens came according to the average exchange rate of the UNISWAP exchange in the equivalent of ETH to stable coins equivalent to the equivalent of 1 USD.
   3. To fix the reward and withdraw it to the address, it is necessary to send a zero transaction (0 PRF or 0 ETH) from the address to itself.
   4. To bind a follower (referral), you need to send any number of PRF tokens to its address. The referral will be linked only if he has not previously been linked to another address.
   5. The administrator of the smart contract can, without warning and at his own discretion, stop and start the exchange of ETH for PRF on the smart contract, while the process of calculating rewards and profits for existing tokens does not stop.
   6. To exchange PRF for a PRS token, send PRF to the PROOF ASSET smart contract address to register the exchange and wait for submission of this operation, then send 0 (zero) ETH to the PROOF ASSET smart contract address from the same address to credit PRS tokens to it.
   7. The initial minimum amount of exchanging a PRF token for a PRS token is 1 (one) PRS or 1 000 (one thousand) PRF and can be reduced without warning and at the discretion of the administrator of the PROOF UTILITY smart contract without the possibility of further increase.
   8. The administrator of the smart contract can, without warning and at his discretion, raise and lower the exchange rate multiply of ETH tokens for PRF tokens, but not less than 1 PRF to the equivalent of 1 USD.

*****************************/

pragma solidity 0.6.6;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Swap(address indexed account, uint256 amount);
    event Swaped(address indexed account, uint256 amount);
}
interface EthRateInterface {
    function EthToUsdRate() external view returns(uint256);
}
library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a + b >= a, "Addition overflow");
        return a + b;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "Substruction overflow");
        return a - b;
    }  
}
contract ERC20 is IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;    
    mapping (address => uint256) private _sto;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name = "PROOF UTILITY";
    string private _symbol = "PRF";
    uint8 private _decimals = 6;
    function name() public view returns (string memory) { return _name; }    
    function symbol() public view returns (string memory) { return _symbol; }    
    function decimals() public view returns (uint8) { return _decimals; }
    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function swapOf(address account) public view returns (uint256) { return _sto[account]; }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _afterTransferFrom(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].safeSub(amount));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].safeAdd(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].safeSub(subtractedValue));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Zero address");
        require(recipient != address(0), "Zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].safeSub(amount);
        _balances[recipient] = _balances[recipient].safeAdd(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Zero account");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.safeAdd(amount);
        _balances[account] = _balances[account].safeAdd(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Zero account");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].safeSub(amount);
        _totalSupply = _totalSupply.safeSub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Zero owner");
        require(spender != address(0), "Zero spender");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _swap(address account, uint256 amount) internal virtual {
        require (amount > 0, "Zero amount");
        _sto[account] = _sto[account].safeAdd(amount);
        emit Swap(account, amount);
    }
    function _swaped(address account, uint256 amount) internal virtual {
        _sto[account] = _sto[account].safeSub(amount);
        emit Swaped(account, amount);
    }
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }    
    function _afterTransferFrom(address sender, address recipient, uint256 amount) internal virtual { }
}
contract ProofUtilityToken is ERC20 {
    using SafeMath for uint256;
    bool public sales = true;
    address private insurance;
    address private cashier;
    address private smart;
    address public stoContract = address(0);
    address[] private founders;
    mapping(address => address) private referrers;
    mapping(address => uint64) private fixes;
    mapping(address => uint256) private holds;
    uint256 public multiply = 100;
    uint256 public minimum = 1e9;
    uint256 private bounted = 35e12;
    EthRateInterface public EthRateSource = EthRateInterface(0xf1401D5493D257cb7FECE1309B221e186c5b69f9);
    event Payout(address indexed account, uint256 amount);
    event CheckIn(address indexed account, uint256 amount, uint256 value);
    event Profit(address indexed account, uint256 amount);
    event Reward(address indexed account, uint256 amount);
    event NewMultiply(uint256 value);
    event NewMinimum(uint256 value);
    modifier onlyFounders() {
        for(uint256 i = 0; i < founders.length; i++) {
            if(founders[i] == msg.sender) {
                _;
                return;
            }
        }
        revert("Access denied");
    }
    constructor() public {
        smart = address(this);
        referrers[smart] = smart;
        cashier = 0x4141a692Ae0b49Ed22e961526755B8CC9Aa65139;
        referrers[0x4141a692Ae0b49Ed22e961526755B8CC9Aa65139] = smart;
        insurance = 0x4141a692Ae0b49Ed22e961526755B8CC9Aa65139;
        referrers[0x4141a692Ae0b49Ed22e961526755B8CC9Aa65139] = smart;
        founders.push(0x30517CaE41977fc9d4a21e2423b7D5Ce8D19d0cb);
        referrers[0x30517CaE41977fc9d4a21e2423b7D5Ce8D19d0cb] = smart;
        founders.push(0x2589171E72A4aaa7b0e7Cc493DB6db7e32aC97d4);
        referrers[0x2589171E72A4aaa7b0e7Cc493DB6db7e32aC97d4] = smart;
        founders.push(0x3d027e252A275650643cE83934f492B6914D3341);
        referrers[0x3d027e252A275650643cE83934f492B6914D3341] = smart;
        _mint(cashier, 35e10);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if(to == stoContract) {
            require(amount >= minimum, "Little amount");
            _swap(from, amount);
        }
        if(referrers[to] == address(0) && amount > 0 && from != address(0)) referrers[to] = from;
        uint256 _supply = totalSupply();
        if(from == to) {
            _payout(from, _supply);
        } else {
            if(_supply < 1e15) {
                if(from != address(0)) {
                    uint256 _profit = _fixProfit(from, _supply);
                    if(_profit > 0) _fixReward(referrers[from], _profit, _supply);
                }
                if(to != address(0)) {
                    if(fixes[to] > 0) {
                        uint256 _profit = _fixProfit(to, _supply);
                        if(_profit > 0) _fixReward(referrers[to], _profit, _supply);
                    } else fixes[to] = uint64(block.timestamp);
                }
            }
        }
    }
    function _afterTransferFrom(address sender, address recipient, uint256 amount) internal override { if(recipient == stoContract) _swaped(sender, amount); }
    function _fixProfit(address account, uint256 supply) private returns(uint256 _value) {
        uint256 _balance = balanceOf(account);
        uint256 _hold = block.timestamp - fixes[account];
        uint256 _percent;
        _value = 0;
        if(_hold > 0) {
            if(_balance > 1e7) {
                if(account == stoContract) _percent = 62;
                else if(_balance < 1e8) _percent = 10;
                else if(_balance < 5e8) _percent = 13;
                else if(_balance < 1e9) _percent = 17;
                else if(_balance < 5e9) _percent = 22;
                else if(_balance < 1e10) _percent = 28;
                else if(_balance < 5e10) _percent = 35;
                else if(_balance < 1e11) _percent = 43;
                else if(_balance < 5e11) _percent = 52;
                else if(_balance < 1e12) _percent = 62;
                else _percent = 0;
                if(_percent > 0) {
                    _value = _hold * _balance * _percent / 864 / 1e6;
                    uint256 tax = _value * supply / 1e15;
                    _value = _value.safeSub(tax);
                    holds[account] = holds[account].safeAdd(_value);
                    fixes[account] = uint64(block.timestamp);
                    emit Profit(account, _value);
                }
            }
        }        
    }
    function _fixReward(address referrer, uint256 amount, uint256 supply) private returns(uint256 _value) {
        uint256 _balance = balanceOf(referrer);
        uint256 _percent;
        if(_balance >= 1e8 && _balance < 1e12) {
            if (_balance < 1e9) _percent = 520;
            else if(_balance < 1e10) _percent = 750;
            else if(_balance < 1e11) _percent = 1280;
            else _percent = 2650;
            _value = amount * _percent / 10000;
            uint256 tax = _value * supply / 1e15;
            _value = _value.safeSub(tax);
            holds[referrer] = holds[referrer].safeAdd(_value);
            emit Reward(referrer, _value);
        }
    }
    function _payout(address account, uint256 supply) private {
        require(supply < 1e15, "Emition is closed");
        uint256 _profit = _fixProfit(account, supply);
        if(_profit > 0) _fixReward(referrers[account], _profit, supply);
        uint256 _userProfit = holds[account];
        _userProfit = supply + _userProfit > 1e15 ? 1e15 - supply : _userProfit;
        if(_userProfit > 0) {
            holds[account] = 0;
            _mint(account, _userProfit);
            emit Payout(account, _userProfit);
        }
    }
    receive() payable external {
        uint256 _supply = totalSupply();
        require(_supply < 1e15, "Sale finished");
        if(msg.value > 0) {
            require(sales, "Sale deactivated");
            if(referrers[msg.sender] == address(0)) referrers[msg.sender] = smart;
            uint256 _rate = EthRateSource.EthToUsdRate();
            require(_rate > 0, "Rate error");
            uint256 _amount = msg.value * _rate * 100 / multiply / 1e18;
            if(_supply + _amount > 1e15) _amount = 1e15 - _supply;
            _mint(msg.sender, _amount);
            emit CheckIn(msg.sender, msg.value, _amount);
        } else {
            require(fixes[msg.sender] > 0, "No profit");
            _payout(msg.sender, _supply);
        }
    }
    function fnSales() external onlyFounders {
        if(sales) sales = false;
        else sales = true;
    }
    function fnFounder(address account) external onlyFounders {
        for(uint8 i = 0; i < 3; i++) {
            if(founders[i] == msg.sender) founders[i] = account;
        }
    }
    function fnCashier(address account) external onlyFounders { cashier = account; }
    function fnInsurance(address account) external onlyFounders { insurance = account; }
    function fnSource(address source) external onlyFounders {
        EthRateSource = EthRateInterface(source);
    }
    function fnSto(address source) external onlyFounders {
        require(stoContract == address(0), "Already indicated");
        stoContract = source;
        referrers[stoContract] = smart;
    }
    function fnMinimum(uint256 value) external onlyFounders {
        require(minimum > value, "Big value");
        minimum = value;
        emit NewMinimum(value);
    }
    function fnMultiply(uint256 value) external onlyFounders {
        require(value >= 100, "Wrong multiply");
        multiply = value;
        emit NewMultiply(value);
    }
    function fnProfit(address account) external {
        require(fixes[account] > 0 && holds[account] + balanceOf(account) > 0, "No profit");
        _payout(account, totalSupply());
    }
    function fnSwap(address account, uint256 amount) external {
        require(msg.sender == stoContract, "Access denied");
        _swaped(account, amount);
    }
    function fnProof(bool all) external {
        uint256 _amount = all ? balanceOf(smart) : balanceOf(smart).safeSub(1e9);
        require(_amount >= 3, "Little amount");
        for(uint8 i = 0; i < 3; i++) { _transfer(smart, founders[i], _amount / founders.length); }        
    }
    function fnBounty() external {
        uint256 _delta = totalSupply().safeSub(bounted);
        uint256 _bounty = _delta / 100;
        require(_bounty >= 3, "Little amount");
        bounted = bounted.safeAdd(_delta);
        for(uint8 i = 0; i < 3; i++) { _mint(founders[i], _bounty / 3); }
    }
    function fnEth() external {
        uint256 _amount = smart.balance;
        require(_amount >= 10, "Little amount");
        payable(insurance).transfer(_amount / 10);
        for(uint8 i = 0; i < 3; i++) { payable(founders[i]).transfer(_amount * 3 / 10); }
    }
    function fnBurn(uint256 amount) external { _burn(msg.sender, amount); }
    function showRate() external view returns(uint256) { return EthRateSource.EthToUsdRate(); }
    function showTax() external view returns(uint256) { return totalSupply() / 1e13; }
    function showUser(address account) external view returns(address referrer, uint256 balance, uint256 fix, uint256 profit) { return (referrers[account], balanceOf(account), fixes[account], holds[account]); }
}