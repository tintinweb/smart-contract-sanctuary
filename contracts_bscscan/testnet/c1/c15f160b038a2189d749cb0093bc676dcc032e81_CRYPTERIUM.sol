/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

pragma solidity ^0.5.10;

/**

░██╗░░░░░░░██╗███████╗  ░█████╗░██████╗░███████╗
░██║░░██╗░░██║██╔════╝  ██╔══██╗██╔══██╗██╔════╝
░╚██╗████╗██╔╝█████╗░░  ███████║██████╔╝█████╗░░
░░████╔═████║░██╔══╝░░  ██╔══██║██╔══██╗██╔══╝░░
░░╚██╔╝░╚██╔╝░███████╗  ██║░░██║██║░░██║███████╗
░░░╚═╝░░░╚═╝░░╚══════╝  ╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝

░█████╗░██████╗░██╗░░░██╗██████╗░████████╗███████╗██████╗░██╗██╗░░░██╗███╗░░░███╗
██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║██║░░░██║████╗░████║
██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░█████╗░░██████╔╝██║██║░░░██║██╔████╔██║
██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██╔══╝░░██╔══██╗██║██║░░░██║██║╚██╔╝██║
╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░███████╗██║░░██║██║╚██████╔╝██║░╚═╝░██║
░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░╚═════╝░╚═╝░░░░░╚═╝

* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeERC20 {
    using SafeMath for uint;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(isContract(address(token)), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract CRYPTERIUM{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    IERC20 public token;
    
    string public constant name                         = "CRYPTERIUM COIN";                // Name of the token
    string public constant symbol                       = "CCoin";                          // Symbol of token
    uint256 public constant decimals                    = 18;                               // Decimal of token
    uint256 public _totalsupply                         = 200000000 * 10 ** decimals;       // Total supply
    uint256 public _privateSale                         = 10000000 * 10 ** decimals;        // 
    uint256 public _seedSale                            = 10000000 * 10 ** decimals;        // 
    uint256 public _publicSale                          = 10000000 * 10 ** decimals;        // 
    uint256 public _development                         = 16000000 * 10 ** decimals;        // 
    uint256 public _playToEarn                          = 50000000 * 10 ** decimals;        // 
    uint256 public _stakingRewards                      = 30000000 * 10 ** decimals;        // 
    uint256 public _marketingAirdrops                   = 20000000 * 10 ** decimals;        // 
    uint256 public _ecosystem                           = 10000000 * 10 ** decimals;        // 
    uint256 public _ownership                           = 10000000 * 10 ** decimals;        // 
    uint256 public _advisor                             = 4000000 * 10 ** decimals;         // 
    uint256 public _liquidityPool                       = 20000000 * 10 ** decimals;        // 
    address public owner                                = msg.sender;                       // Owner of smart contract
    uint256 public _price_token                         = 3333 * 10 ** 16;                  // 1 BUSD = 33.33 CCoin | 0.03 BSUD = 1 CCoin in Sale
    address public admin                                = msg.sender;   

    address public ownership                            = 0xcfb8A4D984C20B2C07404c9D238235957464b8A9;
    address public advisor                              = 0x1997Cef079aBe9FDe2b76DC7F8eA2d07973C30EC; //0xA1559A50dbbb09b7f1B57087A8c066C9423E9A97;
    address public airdrop                              = 0xabf003De1d15B744DAd6418f326016c68CD7662f;
    address public developer                            = 0xb3A4633aB07Fa85A9B4e2Da0551aE0fD43F2f72E;
    address public liquiditypool                        = 0x026EEE1861BA8E244c1830C1dE26A12549EA81C2;
    address public ecosystem                            = 0xf8A8A37B14Ad2c555edF10f08D986f5769B350C0;

    uint256 public _contractTime                        = now;   
    uint256 public _privateSaleStartTime                = 0; // 1
    uint256 public _seedSaleStartTime                   = 0; // 2
    uint256 public _publicSaleStartTime                 = 0; // 3
    uint256 public _currentSale                         = 0;
    uint256 public _airdropStatus                       = 0;
    uint256 public _unlock25M                           = 0;
    uint256 public _unlock25A                           = 0;
    uint256 public _unlock50A                           = 0;
    uint256 public eth_received;                                                            // Total ether received in the contract
    uint256 no_of_tokens;
    mapping (address => uint256) balances;
    mapping (address => uint256) public stakeTime;
    mapping (address => uint256) public stakeAmount;
    mapping (address => uint256) public airdropUserAmount;
    mapping (address => mapping (address => uint)) public _allowances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval (address indexed _owner, address indexed spender, uint value);
    
    /* ▀█▀ █▀█ █▄▀ █▀▀ █▄░█   █▀▄ █ █▀ ▀█▀ █▀█ █ █▄▄ █░█ ▀█▀ █ █▀█ █▄░█   █▀▄ █▀▀ ▀█▀ ▄▀█ █ █░░ █▀
       ░█░ █▄█ █░█ ██▄ █░▀█   █▄▀ █ ▄█ ░█░ █▀▄ █ █▄█ █▄█ ░█░ █ █▄█ █░▀█   █▄▀ ██▄ ░█░ █▀█ █ █▄▄ ▄█
    // Totalsupply - 200,000,000
    // Private Sale Round - 10,000,000
    // Seed Sale Round - 10,000,000
    // Public Sale Round - 10,000,000
    // Development - 16,000,000
    // Play to Earn - 50,000,000
    // Staking Rewards - 30,000,000
    // Marketing & Airdrops - 20,000,000
    // Ecosystem - 10,000,000
    // Ownership - 10,000,000
    // Advisor - 4,000,000
    // Liquidity Pool - 20,000,000 
    */


    // Only owner can access the function
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    // Only admin can access the function
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert();
        }
        _;
    }
    
    constructor(address tokenAddr, address payable wallet) public {
        require(!isContract(wallet) && isContract(tokenAddr));
        token = IERC20(tokenAddr);
        
        // Development Transfer
        balances[developer]             = _development;
        emit Transfer(address(this), developer, _development);
        
        // Marketing & Airdrops Transfer
        balances[airdrop]             = _marketingAirdrops;
        emit Transfer(address(this), airdrop, _marketingAirdrops);
        
        // Ecosystem Transfer
        balances[ecosystem]             = _ecosystem;
        emit Transfer(address(this), ecosystem, _ecosystem);
        
        // Ownership Transfer
        balances[ownership]             = _ownership;
        emit Transfer(address(this), ownership, _ownership);
        
        // Advisor Transfer
        balances[advisor]             = _advisor;
        emit Transfer(address(this), advisor, _advisor);
        
        // Liquidity Pool Transfer
        balances[liquiditypool]             = _liquidityPool;
        emit Transfer(address(this), liquiditypool, _liquidityPool);
    }
    
    function () external payable {
        revert();
    }
    
    function buy(uint256 value) public {
        require(_currentSale > 0);
        require(value <= token.allowance(msg.sender, address(this)));
        token.safeTransferFrom(msg.sender, address(this), value);
        
        no_of_tokens                = value.mul(_price_token); 
        eth_received                = eth_received.add(value);
        transferTokens(msg.sender,(no_of_tokens/10 ** decimals));
    }
    
    function playToEarn(uint256 tokenAmountWin, address userAddress) public returns(bool success, uint256 winAmount)
    {
        require(_playToEarn > 0 && tokenAmountWin <= 10000*10**decimals);
        if(_playToEarn >= tokenAmountWin) {
            _playToEarn = _playToEarn.sub(tokenAmountWin);
            balances[userAddress]         = balances[userAddress].add(tokenAmountWin);
            emit Transfer(address(this), userAddress, tokenAmountWin);
            success = true;
        } else {
            success = false;
        }
        
        return (success, tokenAmountWin);
    }
    
    function startPrivateSale() public onlyAdmin
    {
        require(_currentSale == 0);
        balances[address(this)] = balances[address(this)].add(_privateSale);
        emit Transfer(address(this), address(this), _privateSale);
        _privateSale = 0;
        _privateSaleStartTime = now;
        _currentSale = 1;
    }
    
    function stopPrivateSale() public onlyAdmin
    {
        require(_currentSale == 1);
        // _privateSale = balances[address(this)].add(_privateSale);
        balances[msg.sender] = balances[msg.sender].add(balances[address(this)]);
        emit Transfer(address(this), msg.sender, balances[address(this)]);
        balances[address(this)] = 0;
        _privateSaleStartTime = 0;
        _currentSale = 0;
    }
    
    function startSeedSale() public onlyAdmin
    {
        require(_currentSale == 0);
        balances[address(this)] = balances[address(this)].add(_seedSale);
        emit Transfer(address(this), address(this), _seedSale);
        _seedSale = 0;
        _seedSaleStartTime = now;
        _currentSale = 2;
    }
    
    function stopSeedSale() public onlyAdmin
    {
        require(_currentSale == 2);
        // _seedSale = balances[address(this)].add(_seedSale);
        balances[msg.sender] = balances[msg.sender].add(balances[address(this)]);
        emit Transfer(address(this), msg.sender, balances[address(this)]);
        balances[address(this)] = 0;
        _seedSaleStartTime = 0;
        _currentSale = 0;
    }
    
    function startPublicSale() public onlyAdmin
    {
        require(_currentSale == 0);
        balances[address(this)] = balances[address(this)].add(_publicSale);
        emit Transfer(address(this), address(this), _publicSale);
        _publicSale = 0;
        _publicSaleStartTime = now;
        _currentSale = 3;
    }
    
    function stopPublicSale() public onlyAdmin
    {
        require(_currentSale == 3);
        // _publicSale = balances[address(this)].add(_publicSale);
        balances[msg.sender] = balances[msg.sender].add(balances[address(this)]);
        emit Transfer(address(this), msg.sender, balances[address(this)]);
        balances[address(this)] = 0;
        _publicSaleStartTime = 0;
        _currentSale = 0;
    }
    
    function transferAirdrop(address _transferTo, uint256 _transferAmount) public returns(bool success)
    {
        require(_airdropStatus == 0 && balances[msg.sender] >= _transferAmount);
        balances[msg.sender] = balances[msg.sender].sub(_transferAmount);
        balances[_transferTo] = balances[_transferTo].add(_transferAmount);
        airdropUserAmount[_transferTo] = airdropUserAmount[_transferTo].add(_transferAmount);
        emit Transfer(msg.sender, _transferTo, _transferAmount);
        return success;
    }
    
    function unlock25M() public onlyAdmin
    {
        _airdropStatus = 1;
        _unlock25M = 1;
    }
    
    function unlock25A() public onlyAdmin
    {
        _airdropStatus = 1;
        _unlock25A = 1;
    }
    
    function unlock50A() public onlyAdmin
    {
        _airdropStatus = 1;
        _unlock50A = 1;
    }
    
    function stakeTokens(uint256 stakeTokenAmount) public returns(bool success, uint256 tokenAmount)
    {
        require(balances[msg.sender] >= stakeTokenAmount && stakeTokenAmount >= (5000*10**decimals) && stakeTime[msg.sender] == 0);
        balances[msg.sender] = balances[msg.sender].sub(stakeTokenAmount);
        stakeAmount[msg.sender] = stakeAmount[msg.sender].add(stakeTokenAmount);
        stakeTime[msg.sender] = now;
        
        return (true, stakeTokenAmount);
    }
    
    function unstakeTokens() public returns(bool, uint256)
    {
        require(now >= (stakeTime[msg.sender] + 86400));
        uint256 roiOnStake = stakeAmount[msg.sender].percent(22, 100, 18);
        uint256 perdayStakeAmount = roiOnStake.div(365);
        uint256 roiTimeCount = now.sub(stakeTime[msg.sender]);
        uint256 roiDaysCount = roiTimeCount.div(86400);
        uint256 finalDaysCount;
        if(roiDaysCount >= 0 && roiDaysCount <= 90) {
            finalDaysCount = roiDaysCount;
        } else {
            finalDaysCount = 90;
        }
        uint256 totalRoiReceived = finalDaysCount.mul(perdayStakeAmount);
        _stakingRewards = _stakingRewards.sub(totalRoiReceived);
        balances[msg.sender] = balances[msg.sender].add(totalRoiReceived);
        balances[msg.sender] = balances[msg.sender].add(stakeAmount[msg.sender]);
        stakeAmount[msg.sender] = 0;
        stakeTime[msg.sender] = 0;
        
        return (true, totalRoiReceived);
    }
    
    function stakeReturnsBalance(address _owner) public view returns(bool, uint256)
    {
        require(stakeTime[_owner] > 0);
        uint256 roiOnStake = stakeAmount[_owner].percent(22, 100, 18);
        uint256 perdayStakeAmount = roiOnStake.div(365);
        uint256 roiTimeCount = now.sub(stakeTime[_owner]);
        uint256 roiDaysCount = roiTimeCount.div(86400);
        uint256 finalDaysCount;
        if(roiDaysCount >= 0 && roiDaysCount <= 90) {
            finalDaysCount = roiDaysCount;
        } else {
            finalDaysCount = 90;
        }
        uint256 totalRoiReceivedShow = finalDaysCount.mul(perdayStakeAmount);
        
        return (true, totalRoiReceivedShow);
    }
    
    // Show token balance of address owner
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    } 
    
    // Token transfer function
    // Token amount should be in 18 decimals (eg. 199 * 10 ** 18)
    function transfer(address _to, uint256 _amount ) public {
        require(balances[msg.sender] >= _amount && _amount >= 0);
        uint256 lockAmount = airdropUserAmount[msg.sender];
        if(airdropUserAmount[msg.sender] > 0) {
            if(_unlock25M == 1) {
                uint256 unlockamount25M = airdropUserAmount[msg.sender].percent(25, 100, 18);
                lockAmount = lockAmount.sub(unlockamount25M);
            }
            if(_unlock25A == 1) {
                uint256 unlockamount25A = airdropUserAmount[msg.sender].percent(25, 100, 18);
                lockAmount = lockAmount.sub(unlockamount25A);
            }
            if(_unlock50A == 1) {
                uint256 unlockamount50A = airdropUserAmount[msg.sender].percent(50, 100, 18);
                lockAmount = lockAmount.sub(unlockamount50A);
            }
            require(balances[msg.sender] >= (_amount.add(lockAmount)));
        }
        balances[msg.sender]            = balances[msg.sender].sub(_amount);
        balances[_to]                   = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
    }
    
    // Transfer the balance from owner's account to another account
    function transferTokens(address _to, uint256 _amount) private returns (bool success) {
        require( _to != 0x0000000000000000000000000000000000000000);       
        require(balances[address(this)] >= _amount && _amount > 0);
        balances[address(this)] = balances[address(this)].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(this), _to, _amount);
        return true;
    }
    
    function allowance(address _owner, address spender) public view returns (uint) {
        return _allowances[_owner][spender];
    }
    
    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        require(balances[sender] >= amount && amount >= 0);
        balances[sender]                = balances[sender].sub(amount);
        balances[recipient]             = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function _approve(address _owner, address spender, uint amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = _totalsupply;
    }
    
    function changeAdmin(address _newAdminAddress) external onlyOwner {
        admin = _newAdminAddress;
    }
 
    function contractearnings() external onlyAdmin {
        uint256 contractBalance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, contractBalance);
        // transfer(admin, balances[address(this)]);
    }
    
    function getContractBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
  
    function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return (value*_quotient/1000000000000000000);
    }
}