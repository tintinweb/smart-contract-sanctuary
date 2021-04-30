/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

/* 
 * PROOF ASSET TOKEN (PRS)
 * Developed by @cryptocreater
 * Produced by PROOF CAPITAL GROUP

 * PRF TOKEN INFO *
  Name      PROOF ASSET
  Code      PRS
  Decimals  9

 * PRS TOKEN MARKETING *
 1. Liquidity is replenished by transferring ETH tokens to the address of the smart contract by interested parties. Moreover, the return of liquidity is possible only through the exchange of PRS tokens for ETH at the liquidity rate.
 2. The exchange rate of PRF to PRS is 1:1 in absolute terms or 1000.000000:1.000000000 taking into tokens decimals.
 3. The exchange rate of PRS to ETH is calculated based on the number of PRS tokens and the amount of liquidity in ETH tokens on the PROOF ASSET smart contract.
 4. PRS liquidity is calculated using the formula:
    Lq = Se / Sp
    where
    Lq - liquidity of the PRS token (PRS to ETH exchange rate),
    Se - the volume (amount) of ETH tokens on the PROOF ASSET smart contract,
    Sp - total emission of PRS tokens.
 5. According to the provision of liquidity and the mechanics of the smart contract, PRS tokens can be obtained only in exchange for PRF tokens, and part of the liquidity can be withdrawn to ETH only in exchange for PRS tokens. Thus, each PRS token is provided with current liquidity in the ETH token, and a decrease in liquidity is not possible, in contrast to an increase due to its replenishment.
 6. The remuneration of a smart contract for holding PRF tokens is 0.62% per day and does not depend on the PRF balance.
 7. The emission of the PRS token is calculated based on the total emission of PRF tokens minus the amount of PRF tokens on the PROOF ASSET smart contract. Thus, each holders PRF token can be exchanged for an PRS token.
 8. Any PRS token holder, depending on the financial strategy, can independently decide on the exchange of PRF tokens for PRS tokens and PRS tokens for ETH tokens without restrictions on the amount and timing of the exchange.

 * PRS TOKEN MECHANICS *
 1. To exchange PRF tokens for PRS tokens, you must:
    - use the "prf2prs" function, after granting permission to the PROOF ASSET smart contract to write off PRF tokens from the user's address;
    or
    - send PRF tokens to the address of the PROOF ASSET smart contract to activate the exchange;
    - send 0 (zero) ETH to the address of the PROOF ASSET smart contract to receive PRS tokens.    
 2. To exchange PRS tokens for ETH tokens according to the liquidity rate, you need to send PRS tokens to the address of the PROOF ASSET smart contract.
    !!!Attention!!!
    At the time of the exchange of tokens, the liquidity rate may change, because the smart contract will equalize the emission of PRF and PRS tokens, and then calculate the liquidity rate and transfer the corresponding number of ETH tokens.
 3. Liquidity replenishment can be carried out by any interested person at his discretion in any time and amount exceeding 1 (one) ETH.
 
*/

pragma solidity 0.6.6;
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
interface prfInterface {
    function swapOf(address account) external view returns (uint256);
    function fnSwap(uint256 amount) external;
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
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "Non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeAdd(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeSub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "Non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "Call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "Not succeed");
        }
    }
}
contract ERC20 is IERC20 {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name = "PROOF ASSET";
    string private _symbol = "PRS";
    uint8 private _decimals = 9;
    event CheckOut(address indexed addr, uint256 amount);
    function name() public view returns (string memory) {
        return _name;
    }    
    function symbol() public view returns (string memory) {
        return _symbol;
    }    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        require(sender != address(0) && recipient != address(0), "Zero address");
        uint256 _value = beforeTokenTransfer(recipient, amount);
        if(_value > 0) {
            _balances[sender] = _balances[sender].safeSub(amount);
            _totalSupply = _totalSupply.safeSub(amount);
            emit Transfer(sender, address(0), amount);
            emit CheckOut(sender, amount);
            payable(sender).transfer(_value);
        } else {
            _balances[sender] = _balances[sender].safeSub(amount);
            _balances[recipient] = _balances[recipient].safeAdd(amount);
            emit Transfer(sender, recipient, amount);
        }        
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Zero address");
        _totalSupply = _totalSupply.safeAdd(amount);
        _balances[account] = _balances[account].safeAdd(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Zero address");
        _balances[account] = _balances[account].safeSub(amount);
        _totalSupply = _totalSupply.safeSub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0) && spender != address(0), "Zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }
    function beforeTokenTransfer(address to, uint256 amount) internal virtual returns (uint256) { }
}
contract ProofAssetToken is ERC20 {
    using SafeERC20 for IERC20;
    IERC20 public prf = IERC20(0x499b78d0ef68272804C9661d7a12dcC7208BC322);    
    prfInterface public prfInterfaceCall = prfInterface(0x499b78d0ef68272804C9661d7a12dcC7208BC322);
    address private smart;
    event CheckIn(address indexed addr, uint256 prfs);    
    event RateUpdate(uint256 value);
    constructor() public {
        smart = address(this);
    }
    function beforeTokenTransfer(address to, uint256 amount) internal override returns (uint256) {
        return (to == smart) ? amount * smart.balance / totalSupply() : 0;
    }
    receive() payable external {
        if(msg.value > 0) {
            uint256 _rate = smart.balance / totalSupply();
            emit RateUpdate(_rate);
        } else {
            uint256 _amount = prfInterfaceCall.swapOf(msg.sender);
            require(_amount > 0, "Send PRF first");
            uint256 _supply = totalSupply().safeAdd(_amount);
            uint256 _rate = smart.balance / _supply;
            emit RateUpdate(_rate);
            prfInterfaceCall.fnSwap(_amount);
            _mint(msg.sender, _amount);
            emit CheckIn(msg.sender, _amount);
        }
    }
    function prf2prs(uint256 amount) external {
        require(amount > 0, "Zero amount");
        prfInterfaceCall.fnSwap(amount);
        prf.safeTransferFrom(msg.sender, smart, amount);
        _mint(msg.sender, amount);
        emit CheckIn(msg.sender, amount);
    }
    function prs2eth(uint256 amount) external {
        uint256 _withdraw = amount * smart.balance / totalSupply();
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(_withdraw);
        emit CheckOut(msg.sender, amount);
    }
    function prsBurn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    function prsRate() external view returns(uint256) {
        return smart.balance / totalSupply();
    }
}