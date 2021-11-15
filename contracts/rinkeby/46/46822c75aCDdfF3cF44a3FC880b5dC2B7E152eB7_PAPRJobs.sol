pragma solidity 0.6.12;

import "./Migratable.sol";

abstract contract Context {
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



library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

   
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
       
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

   
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }


    function name() public view virtual returns (string memory) {
        return _name;
    }


    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view virtual override returns (uint256) {
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

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

    
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


library Address {
   
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

   
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

       
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

   
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
           
            if (returndata.length > 0) {
               
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

   
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
           
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IUniswapRouterETH {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

}


interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IPAPRBUSDVault {
    function depositAll() external;
    function withdrawAll() external;
    function deposit(uint256 _amounts) external;
    function withdraw(uint256 _amounts) external;
    function getPricePerFullShare() external returns (uint256);
    function balanceOf(address _address) external returns (uint256);
}

interface IZapper {
    function breakLP(address _from, uint amount) external;

}

contract Escrow is Migratable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ERC20 internal escrowToken;
    uint256 internal escrowId;
    address escrowDapp;

    address constant private paprgov = address(0x7bf5F00AdF1a71bad1Fdbb916e4F0cC229f9c541);
    address constant private busd = address(0xB7F7644f999D34fB58cE91b3dBc26B0Bf7081337);
    address constant private wbnb = address(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    address constant private unirouter = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address constant private want = address(0x7607CcB24C388Ec563be1488Ecc2B27455265ba6);
    address constant private vault = address(0x9B7caEBC185e15686F171f79Eb989F0fdbec92Cc);
    address constant private Zapper = address(0x053bd6855Bb4976d8e20268951c4837c4b610784);

    address[] public escrowTokentoPAPRroute;
    address[] public escrowTokentoBUSDroute;
    address[] public busdtoPAPRroute;
    address[] public escrowTokenToLp0Route;
    address[] public escrowTokenToLp1Route;
    address public lpToken0;
    address public lpToken1;

    uint256 internal DAPP_PAYMENT_PERCENTAGE;  

    enum EscrowStatus {
        New,
        Completed,
        Cancelled
    }

    struct EscrowRecord {
        uint256 id;
        uint256 proofofdeposit;
        address client;
        address provider;
        uint256 amount;
        EscrowStatus status;
        uint256 createdAt;
        uint256 closedAt;
        uint256 payoutAmount;
        uint256 paidToDappAmount;
        uint256 paidToProviderAmount;
        uint256 paidToClientAmount;
        uint256 paidToArbiterAmount;
    }


    mapping(uint256 => EscrowRecord) internal escrows;


    event OnInitialize(address indexed token, address indexed dApp);
    event OnCreateEscrow(address indexed dapp, address indexed client, address indexed provider, uint256 amount, uint256 proofDeposit);
    event OnCompleteEscrow(address indexed dapp, uint256 indexed escrowId);
    event OnCancelEscrowByProvider(address indexed dapp, uint256 indexed escrowId);
    event OnCancelEscrow(address indexed dapp, uint256 indexed escrowId, uint256 payToProviderAmount, address indexed arbiter, uint256 payToArbiterAmount);

    function initialize(ERC20 _token, address _dApp) 
    internal 
    virtual
    isInitializer("Escrow", "0.1.3") {
        
        escrowToken = _token;
        escrowDapp = _dApp;
        DAPP_PAYMENT_PERCENTAGE = 1;
        escrowId = 0;
        escrowTokentoPAPRroute = [address(escrowToken), paprgov];
        escrowTokentoBUSDroute = [address(escrowToken), busd];
        busdtoPAPRroute = [busd, paprgov];

        lpToken0 = IUniswapV2Pair(want).token0();
        lpToken1 = IUniswapV2Pair(want).token1();

        if (lpToken0 == paprgov) {
            escrowTokenToLp0Route = [address(escrowToken), paprgov];
        } else if (lpToken0 == busd) {
            escrowTokenToLp0Route = [address(escrowToken), busd];
        } else if (lpToken0 != address(escrowToken)) {
            escrowTokenToLp0Route = [address(escrowToken), wbnb, lpToken0];
        }

        if (lpToken1 == paprgov) {
            escrowTokenToLp1Route = [address(escrowToken), paprgov];
        } else if (lpToken1 == busd) {
            escrowTokenToLp1Route = [address(escrowToken), busd];
        } else if (lpToken1 != address(escrowToken)) {
            escrowTokenToLp1Route = [address(escrowToken), wbnb, lpToken1];
        }

        _giveAllowances();

        emit OnInitialize(address(_token), _dApp);
    }

        function _addLiquidity() internal {
        uint256 wbnbHalf = ERC20(escrowToken).balanceOf(address(this)).div(2);

        if (lpToken0 != address(escrowToken)) {
             IUniswapRouterETH(unirouter).swapExactTokensForTokens(wbnbHalf, 0, escrowTokentoPAPRroute, address(this), now);
        }

        if (lpToken1 != address(escrowToken)) {
            IUniswapRouterETH(unirouter).swapExactTokensForTokens(wbnbHalf, 0, escrowTokentoBUSDroute, address(this), now);
        }

        uint256 lp0Bal = ERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = ERC20(lpToken1).balanceOf(address(this));
        IUniswapRouterETH(unirouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), now);
    }

        function _giveAllowances() internal {
        IERC20(address(escrowToken)).safeApprove(unirouter, uint(-1));
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, uint(-1));
        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, uint(-1));

        IERC20(want).safeApprove(vault, 0);
        IERC20(want).safeApprove(vault, uint(-1));

        IERC20(want).safeApprove(Zapper, 0);
        IERC20(want).safeApprove(Zapper, uint(-1));
        
    }

    function createEscrow(address _client, address _provider, uint256 _amount) 
    internal 
    returns (uint256) {
        
        require(escrowToken.transferFrom(_client, address(this), _amount));
        _addLiquidity();
         uint256 paprLPBalance = IERC20(want).balanceOf(address(this));
         uint256 proofOfDeposit = paprLPBalance.div(IPAPRBUSDVault(vault).getPricePerFullShare());
         uint256 id = ++escrowId;
         EscrowRecord storage escrow = escrows[id];
         escrow.proofofdeposit = proofOfDeposit;
         //IPAPRBUSDVault(vault).deposit(paprLPBalance);
        
        
        escrow.id = id;
        
        escrow.client = _client;
        escrow.provider = _provider;
        escrow.amount = _amount;
        escrow.createdAt = block.number;
        escrow.status = EscrowStatus.New;
        escrow.payoutAmount = 0;
        escrow.paidToProviderAmount = 0;
        escrow.paidToClientAmount = 0;
        escrow.paidToArbiterAmount = 0;



        emit OnCreateEscrow(escrowDapp, _client, _provider, _amount, proofOfDeposit);

        return id;
    }

    function completeEscrow(uint256 _escrowId) 
    internal 
    returns (bool) {
        //require(escrows[_escrowId].status == EscrowStatus.New, "Escrow status must be 'new'");
        require(escrows[_escrowId].client == msg.sender, "Transaction must be sent by the client");

        escrows[_escrowId].status = EscrowStatus.Completed; 
        escrows[_escrowId].closedAt = block.number;

        escrows[_escrowId].payoutAmount = getTotalPayoutPAPR(_escrowId);

        uint256 payToDappAmount = escrows[_escrowId].payoutAmount.mul(DAPP_PAYMENT_PERCENTAGE).div(100);
        if(payToDappAmount > 0){
            escrows[_escrowId].paidToDappAmount = payToDappAmount;
            //bnb/2 ==> buyback paprgov + burn
            escrowToken.transfer(escrowDapp, payToDappAmount);
        }

        uint256 providerPayoutCan = escrows[_escrowId].payoutAmount.sub(payToDappAmount);
        escrows[_escrowId].paidToProviderAmount = providerPayoutCan;

        escrowToken.transfer(escrows[_escrowId].provider, escrows[_escrowId].paidToProviderAmount);

        emit OnCompleteEscrow(escrowDapp, _escrowId);

        return true;
    }

    function withdraw(uint _escrowId) public {

        uint256 toWithdraw = escrows[_escrowId].proofofdeposit;
        IPAPRBUSDVault(vault).withdraw(toWithdraw);
    }
    
    function getTotalPayoutPAPR(uint _escrowId) 
    internal 
    returns (uint256) {
        uint256 toWithdraw = escrows[_escrowId].proofofdeposit;
        IPAPRBUSDVault(vault).withdraw(toWithdraw);
        uint256 paprLPBalance = ERC20(want).balanceOf(address(this));
        IZapper(Zapper).breakLP(want, paprLPBalance);
        uint256 busdBal = ERC20(busd).balanceOf(address(this));
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(busdBal, 0, busdtoPAPRroute, address(this), now);

        uint256 totalPayoutPAPR = escrows[_escrowId].amount;
        //require(totalPayoutPAPR > 0, "Must return a non zero payout");
        if(totalPayoutPAPR >= escrows[_escrowId].amount.mul(2)){ // max payout in PAPR is 2x initial pay in
            return escrows[_escrowId].amount.mul(2);
        }
        return totalPayoutPAPR;
    }

    function cancelEscrowByProvider(uint256 _escrowId) 
    internal 
    returns (bool) {
        require(escrows[_escrowId].status == EscrowStatus.New, "Escrow status must be 'new'");
        require(escrows[_escrowId].provider == msg.sender, "Transaction must be sent by provider");

        escrows[_escrowId].payoutAmount = getTotalPayoutPAPR(_escrowId);

        escrows[_escrowId].paidToClientAmount = escrows[_escrowId].payoutAmount;
        escrows[_escrowId].status = EscrowStatus.Cancelled;
        escrows[_escrowId].closedAt = block.number;

        escrowToken.transfer(escrows[_escrowId].client, escrows[_escrowId].paidToClientAmount);

        emit OnCancelEscrowByProvider(escrowDapp, _escrowId);

        return true;
    }    

    function cancelEscrow(uint256 _escrowId, uint8 _payToClientPercentage, uint8 _payToProviderPercentage, address _arbiter, uint8 _payToArbiterPercentage) 
    internal 
    returns (bool) {
        require(escrows[_escrowId].status == EscrowStatus.New, "Escrow status must be 'new'");
        require(_payToClientPercentage >= 0 && _payToProviderPercentage >= 0 && _payToArbiterPercentage >= 0
            && _payToClientPercentage <= 100 && _payToProviderPercentage <= 100 && _payToArbiterPercentage <= 100, "Payments to client, provider and arbiter must be gte 0");
        require((_payToClientPercentage + _payToProviderPercentage + _payToArbiterPercentage) == 100, "Total payout must equal 100 percent");

        escrows[_escrowId].status = EscrowStatus.Cancelled;        
        escrows[_escrowId].closedAt = block.number;

        escrows[_escrowId].payoutAmount = getTotalPayoutPAPR(_escrowId);

        uint256 payToDappAmount = escrows[_escrowId].payoutAmount.mul(DAPP_PAYMENT_PERCENTAGE).div(100);
        if (payToDappAmount > 0){
            escrows[_escrowId].paidToDappAmount = payToDappAmount;
            escrowToken.transfer(escrowDapp, payToDappAmount);
        }

        uint payoutToSplit = escrows[_escrowId].payoutAmount.sub(payToDappAmount);

        if (_payToArbiterPercentage > 0) {
            //require(_arbiter != address(0), "Arbiter address must be valid");
            escrows[_escrowId].paidToArbiterAmount = payoutToSplit.mul(_payToArbiterPercentage).div(100);
            escrowToken.transfer(_arbiter, escrows[_escrowId].paidToArbiterAmount);
        }                

        if (_payToProviderPercentage > 0) {
            escrows[_escrowId].paidToProviderAmount = payoutToSplit.mul(_payToProviderPercentage).div(100);
            escrowToken.transfer(escrows[_escrowId].provider, escrows[_escrowId].paidToProviderAmount);
        }        
             
        if (_payToClientPercentage > 0) {
            escrows[_escrowId].paidToClientAmount = payoutToSplit.mul(_payToClientPercentage).div(100); 
            escrowToken.transfer(escrows[_escrowId].client, escrows[_escrowId].paidToClientAmount);
        }       

        emit OnCancelEscrow(escrowDapp, _escrowId, escrows[_escrowId].paidToProviderAmount, _arbiter, escrows[_escrowId].paidToArbiterAmount); 

        return true;
    }



    function getEscrow(uint256 _escrowId) 
    public 
    view
    returns (
      address client, 
      address provider, 
      uint256 amount,
      uint256 proofOfDeposit,
      uint8 status, 
      uint256 createdAt, 
      uint256 closedAt) 
      {      
        //require(_escrowId > 0 && escrows[_escrowId].createdAt > 0, "Must be a valid escrow Id");
        return (
            escrows[_escrowId].client, 
            escrows[_escrowId].provider, 
            escrows[_escrowId].amount,
            escrows[_escrowId].proofofdeposit,
            uint8(escrows[_escrowId].status),
            escrows[_escrowId].createdAt, 
            escrows[_escrowId].closedAt
            );       
    }

    function getEscrowPayments(uint256 _escrowId) 
    public 
    view
    returns (
      uint256 amount, 
      uint256 payoutAmount,
      uint256 paidToDappAmount,
      uint256 paidToProviderAmount,
      uint256 paidToClientAmount,      
      uint256 paidToArbiterAmount)
      {      
        //require(_escrowId > 0 && escrows[_escrowId].createdAt > 0, "Must be a valid escrow Id");
        return (
            escrows[_escrowId].amount, 
            escrows[_escrowId].payoutAmount, 
            escrows[_escrowId].paidToDappAmount,
            escrows[_escrowId].paidToProviderAmount,
            escrows[_escrowId].paidToClientAmount,        
            escrows[_escrowId].paidToArbiterAmount
            );       
    }    
}

pragma solidity 0.6.12;


/**
 * @title Migratable
 * Helper contract to support intialization and migration schemes between
 * different implementations of a contract in the context of upgradeability.
 * To use it, replace the constructor with a function that has the
 * `isInitializer` modifier starting with `"0"` as `migrationId`.
 * When you want to apply some migration code during an upgrade, increase
 * the `migrationId`. Or, if the migration code must be applied only after
 * another migration has been already applied, use the `isMigration` modifier.
 * This helper supports multiple inheritance.
 * WARNING: It is the developer's responsibility to ensure that migrations are
 * applied in a correct order, or that they are run at all.
 * See `Initializable` for a simpler version.
 */
contract Migratable {
  /**
   * @dev Emitted when the contract applies a migration.
   * @param contractName Name of the Contract.
   * @param migrationId Identifier of the migration applied.
   */
  event Migrated(string contractName, string migrationId);

  /**
   * @dev Mapping of the already applied migrations.
   * (contractName => (migrationId => bool))
   */
  mapping (string => mapping (string => bool)) internal migrated;


  /**
   * @dev Modifier to use in the initialization function of a contract.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  modifier isInitializer(string memory contractName, string memory migrationId) {
    require(!isMigrated(contractName, migrationId));
    _;
    emit Migrated(contractName, migrationId);
    migrated[contractName][migrationId] = true;
  }

  /**
   * @dev Modifier to use in the migration of a contract.
   * @param contractName Name of the contract.
   * @param requiredMigrationId Identifier of the previous migration, required
   * to apply new one.
   * @param newMigrationId Identifier of the new migration to be applied.
   */
  modifier isMigration(string memory contractName, string memory requiredMigrationId, string memory newMigrationId) {
    require(isMigrated(contractName, requiredMigrationId) && !isMigrated(contractName, newMigrationId));
    _;
    emit Migrated(contractName, newMigrationId);
    migrated[contractName][newMigrationId] = true;
  }

  /**
   * @dev Returns true if the contract migration was applied.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   * @return true if the contract migration was applied, false otherwise.
   */
  function isMigrated(string memory contractName, string memory migrationId) public view returns(bool) {
    return migrated[contractName][migrationId];
  }
}

pragma solidity 0.6.12;

import "./PAPRJobsCreator.sol";

contract PAPRJobs is PAPRJobsCreator {
    ERC20 papr;

    event OnEmeregencyTransfer(address indexed toAddress, uint256 balance);

    function initialize(ERC20 _token, PAPRJobsAdmin _paprjobsAdmin, address _dApp) 
    public
    override
    isInitializer("PAPRJobs", "0.1.0") {

        PAPRJobsCreator.initialize(_token, _paprjobsAdmin, _dApp);      

        papr = _token;        
    }
 
  
}

pragma solidity 0.6.12;

import "./Escrow.sol";

interface PAPRJobsAdmin {
    function addSig(address signer, bytes32 id) external returns (uint8);
    function resetSignature(bytes32 id) external returns (bool);  
    function getSignersCount(bytes32 id) external view returns (uint8);
    function getSigner(bytes32 id, uint index) external view returns (address,bool);
    function hasRole(address addr, string memory roleName) external view returns (bool);
}

contract PAPRJobsCreator is Escrow {
    
    using SafeMath for uint256;
    
    PAPRJobsAdmin paprjobsAdmin;    
    string public constant ROLE_ADMIN = "admin";
    string public constant ROLE_OWNER = "owner";
    address private _owner;
    bytes32 _jobId;

    enum JobStatus {
        New,
        Completed,
        Cancelled
    }

    struct Job {
        bytes32 id;
        address client;
        address provider;
        uint256 escrowId;
        JobStatus status;
        uint256 amount;
    }

        modifier jobIDDiff() {
        require(_jobId[0] != 0);
        _;
    }

     modifier newJobDiff() {
        require(jobs[_jobId].status == JobStatus.New);
        _;
    }

    mapping(bytes32 => Job) internal jobs;
    address dApp;

    event OnCreateJob(address indexed dapp, bytes32 indexed jobId, address client, address indexed provider, uint256 totalCosts);
    event OnCompleteJob(address indexed dapp, bytes32 indexed jobId);
    event OnCancelJobByProvider(address indexed dapp, bytes32 indexed jobId);
    event OnCancelJobByAdmin(address indexed dapp, bytes32 indexed jobId, uint8 payToProviderPercentage, address indexed arbiter, uint8 payToArbiterPercentage);

    function initialize(ERC20 _token, PAPRJobsAdmin _paprjobsAdmin, address _dApp)
    public 
    virtual
    isInitializer("PAPRJobsCreator", "0.1.0") {
        Escrow.initialize(_token, _dApp);
        paprjobsAdmin = PAPRJobsAdmin(_paprjobsAdmin);
        dApp = _dApp;
        _owner = msg.sender;
        
    }

    function createJob(bytes32 _jobId, address _client, address _provider, uint256 _totalCosts) 
    public
    
    returns (bool) {
        require(jobs[_jobId].id[0] == 0);

        jobs[_jobId].id = _jobId;
        jobs[_jobId].client = _client;
        jobs[_jobId].provider = _provider;
        jobs[_jobId].status = JobStatus.New;
        jobs[_jobId].amount = _totalCosts;
        jobs[_jobId].escrowId = createEscrow(_client, _provider, _totalCosts);

        emit OnCreateJob(dApp, _jobId, _client, _provider, _totalCosts);

        return true;
    }

    function completeJob(bytes32 _jobId) 
    public
    
    
    returns (bool) {  
        require(jobs[_jobId].client == msg.sender);   
        
        completeEscrow(jobs[_jobId].escrowId);
        
        jobs[_jobId].status = JobStatus.Completed;

        emit OnCompleteJob(dApp, _jobId);

        return true;
    }

    function cancelJobByProvider(bytes32 _jobId) 
    public 
    
    
    returns (bool) {
        require(jobs[_jobId].provider == msg.sender);
        
        cancelEscrowByProvider(jobs[_jobId].escrowId);
        
        jobs[_jobId].status = JobStatus.Cancelled;

        emit OnCancelJobByProvider(dApp, _jobId);

        return true;
    }

    function cancelJobByAdmin(bytes32 _jobId, uint8 _payToClientPercentage, uint8 _payToProviderPercentage, address _arbiter, uint8 _payToArbiterPercentage)
    public
    
    
    returns (bool) { 
        require(paprjobsAdmin.hasRole(msg.sender, ROLE_ADMIN));
        require(_payToArbiterPercentage <= 5, "Arbiter cannot receive more than 5% of funds");
        
        require(cancelEscrow(jobs[_jobId].escrowId, _payToClientPercentage, _payToProviderPercentage, _arbiter, _payToArbiterPercentage));

        jobs[_jobId].status = JobStatus.Cancelled;

        emit OnCancelJobByAdmin(dApp, _jobId, _payToProviderPercentage, _arbiter, _payToArbiterPercentage);

        return true;
    }

    function getJob(bytes32 _jobId) 
    public 
    view
    
    returns (
      address client, 
      address provider,
      uint256 amount,
      uint256 proofOfDeposit,
      uint8 status, 
      uint256 createdAt, 
      uint256 closedAt
      ) {

        return getEscrow(jobs[_jobId].escrowId);
    }

    function getJobPayments(bytes32 _jobId) 
    public 
    view
    
    returns (
      uint256 amount,  
      uint256 payoutAmount,
      uint256 paidToDappAmount,
      uint256 paidToProviderAmount,
      uint256 paidToClientAmount,
      uint256 paidToArbiterAmount
      ) {
        return getEscrowPayments(jobs[_jobId].escrowId);
    } 
}

