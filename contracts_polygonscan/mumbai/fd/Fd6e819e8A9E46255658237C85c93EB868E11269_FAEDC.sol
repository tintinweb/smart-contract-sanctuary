/**
 *Submitted for verification at polygonscan.com on 2022-01-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity  >=0.7.0 <0.9.0;

// imports and interfaces
//import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
//import "https://github.com/aave/protocol-v2/blob/master/contracts/protocol/configuration/LendingPoolAddressesProvider.sol";
//import "https://github.com/aave/protocol-v2/blob/master/contracts/protocol/lendingpool/LendingPool.sol";
// import {ILendingPoolAddressesProvider} from '/home/siddharth/vault-contracts/node_modules/@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol';


// TODO: add reentrancy lock.
// TODO: disallow use of mint and burn when paused
interface IERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external view returns(bool);
    function approve(address spender, uint256 amount) external view returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external view returns(bool);
}


interface ILendingPool{
     function deposit(address asset,uint256 amount,address onBehalfOf,uint16 referralCode) external;
     function withdraw(address asset,uint256 amount,address to) external returns (uint256);
}

interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}


contract FAEDC {
    
    string public NAME = "fAED Stablecoin";
    string public SYMBOL = "fAED";
    uint8 public DECIMALS = 8;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address admin;
    uint16 aave_referral = 0;
    uint16 public buy_rate = 367;
    uint16 public sell_rate = 367;
    mapping(address => bool) isMinter;
    mapping(address => uint256) user_interest;
    mapping(address => uint256) user_interest_claimed;
    uint256 accumulatedInterestPerShare;
    uint256 lastRewardCalcTimestamp;
    uint256 public totalDepositBalance;
    uint256 lastAtokenBalance;
    bool public isPaused;
    
    // external addresses 
    address lendingpool;
    address USDC_contract =  0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e; // 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address AMUSDC_contract = 0x2271e3Fef9e15046d09E1d78a8FF038c691E9Cf9; // 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F;
    address AAVE_contract =  0x178113104fEcbcD7fF8669a0150721e231F0FD4B; // 0xd05e3E715d945B59290df0ae8eF85c1BdB684744;

    IERC20 USDC_instance = IERC20(USDC_contract);
    IERC20 AMUSDC_instance = IERC20(AMUSDC_contract);

    //ERC20 specification mandates.
    //It requires that events be triggered for allowance and transfers.
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Bugger(uint256 _value, string _message);

    // initialize variables
    constructor(){
        lendingpool = getLendingPool();
        admin = msg.sender;
        isMinter[msg.sender] = true; 

        // get lending pool address and initialize
        // approve max no of USDC to lending pool
    }

    // modifiers 
    modifier onlyAdmin {
        require(msg.sender == admin,
        "Only the contract Admin can call this function");
        _;
    }    

    // EIP20  functions
    function _transfer(address _from, address _to, uint256 _value) internal returns(bool) {
        require(_to != address(0), "transfer to zero address!");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from,_to,_value);
        return true;
    }

    function transfer(address _to, uint256 _value) external returns(bool){
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender,_to,_value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value; // _to instead of msg.sender?
        emit Transfer(_from, _to, _value);
        return true;
        
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
        
    // ERC20 extra functions (to use openzeppelin?)

    function _mint(address _to, uint256 _value) internal returns(bool){
        require(_to != address(0), "transfer to zero address!");
        totalSupply += _value;
        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function mint(address _to, uint256 _value) external returns(bool){
        require(isMinter[msg.sender] == true, "Only minter can mint");
        return _mint(_to,_value);       
    }

    function _burn(address _to, uint256 _value) internal {
        // permissions?
        totalSupply -= _value;
        balanceOf[_to] -= _value;
        emit Transfer(_to, address(0), _value); 
    }

    function burn(uint256 _value) external {
        require(balanceOf[msg.sender] >= _value && totalSupply >= _value , "Underflow error, not enough balance");
        _burn(msg.sender, _value);
    }

    function burnFrom(address _to, uint256 _value) external {
        require(allowance[_to][msg.sender] >= _value, "allowance lower than burn amount");
        allowance[_to][msg.sender] -= _value;
        _burn(_to,_value);
    }

    // contract functions
    function setPaused(bool paused) external onlyAdmin {
        if(paused != isPaused){
            isPaused = paused;
        }
    }

    function saveATokenBalance() internal {
        lastAtokenBalance = AMUSDC_instance.balanceOf(address(this));
    }

    function getLendingPool() internal view returns(address){
        return ILendingPoolAddressesProvider(AAVE_contract).getLendingPool();
    }

    function updateInterest() internal {
        if(block.timestamp <= lastRewardCalcTimestamp){
            return;
        }
        
        uint256 current_atoken_balance = USDC_instance.balanceOf(address(this));
        emit Bugger(current_atoken_balance, 'balance current');
        emit Bugger(lastAtokenBalance, 'balance last');
        if( current_atoken_balance == 0 || totalDepositBalance == 0 ) {
            return;
        }

        uint256 interest_difference = (current_atoken_balance - lastAtokenBalance);

        emit Bugger(totalDepositBalance, "balance difference scaled");

        accumulatedInterestPerShare = accumulatedInterestPerShare + ((interest_difference * 10**12)/totalDepositBalance);
        emit Bugger(accumulatedInterestPerShare, "rewardPerShare");
        emit Bugger(interest_difference, "rewardPerSeconds");    
        lastRewardCalcTimestamp = block.timestamp;
    }

    function setBuyRate(uint16 _newRate) external onlyAdmin {
        buy_rate = _newRate;
    }

    function setSellRate(uint16 _newRate) external onlyAdmin {
        sell_rate = _newRate;
    }

    // getter functions for buy/sell rate omitted since both are public

    function addMinter(address _newMinter) external onlyAdmin {
        isMinter[_newMinter] = true;
    }

    function changeAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    // Main buy/sell functions, check for re-entrancy in all of them 
    // admin fx buy/sell , initiated by us on behalf of user
    
    function adminFxBuy(address _user, uint256 _deposit) external onlyAdmin returns(bool){
        require(isPaused != true, "contract paused by admin");
        updateInterest();

        uint256 usdc_amount = _deposit * buy_rate;
        uint256 user_balance = balanceOf[_user];

        if(user_balance > 0 ){
            user_interest[_user] += ((user_balance / buy_rate) * accumulatedInterestPerShare ) - user_interest_claimed[_user];
        }
        _mint(_user,_deposit);
        emit Bugger(user_interest[_user], "interests");
        ILendingPool(lendingpool).deposit(USDC_contract,usdc_amount,address(this),aave_referral);

        totalDepositBalance += usdc_amount ;
        user_interest_claimed[_user] = (( balanceOf[_user] / buy_rate )) * accumulatedInterestPerShare;
        emit Bugger(accumulatedInterestPerShare, "rewardPerShare");
        saveATokenBalance();
        return true;

    }

    // user's fxbuy - used to convert currency

    function fxBuy (uint256 _deposit) external returns(bool){
        require(isPaused != true, "contract paused by admin");
        updateInterest();
        uint256 usdc_amount = _deposit * 10**6;
        // approval?
        USDC_instance.transferFrom(msg.sender,address(this),usdc_amount);
        uint256 faed_amount = _deposit * sell_rate;
        uint256 user_balance = balanceOf[msg.sender];

        if(user_balance > 0){
            user_interest[msg.sender] += (((user_balance / buy_rate)) * accumulatedInterestPerShare) - user_interest_claimed[msg.sender];
            
        }

        _mint(msg.sender,faed_amount);
        emit Bugger(user_interest[msg.sender], "interests");
        ILendingPool(lendingpool).deposit(USDC_contract,usdc_amount,address(this),aave_referral);
        totalDepositBalance += usdc_amount ;
        user_interest_claimed[msg.sender] = (( balanceOf[msg.sender] / buy_rate )) * accumulatedInterestPerShare;
        emit Bugger(accumulatedInterestPerShare, "rewardPerShare");
        saveATokenBalance();
        return true;

    }


    function adminFxSell(address _user, uint256 _withdraw) external onlyAdmin returns(bool){
        require(isPaused != true, "contract paused by admin");
        updateInterest();

        uint256 user_balance = balanceOf[_user];
        require(user_balance >= _withdraw, "not enough balance!");
        
        _burn(_user,_withdraw);

        uint256 usdc_amount = _withdraw / sell_rate;
        emit Bugger(user_interest_claimed[_user], "interests claimed");
        user_interest[_user] += (((user_balance / buy_rate)) * accumulatedInterestPerShare) - user_interest_claimed[msg.sender];

        emit Bugger(user_interest[_user], "interests");
        uint256 interest_on_withdrawal = usdc_amount/((user_balance/buy_rate)) * user_interest[_user];
        emit Bugger(interest_on_withdrawal, "interest on withdrawal");

        require(user_interest[_user] >= interest_on_withdrawal, "interest error!");
        user_interest[_user] -= interest_on_withdrawal;
        uint256 usdc_amount_plus_interest = usdc_amount + (interest_on_withdrawal / 10**12);
        emit Bugger(usdc_amount_plus_interest, "interest + withdrawal");
        
        ILendingPool(lendingpool).withdraw(USDC_contract,usdc_amount_plus_interest,address(this));

        USDC_instance.transfer(msg.sender,usdc_amount_plus_interest);
        totalDepositBalance -= usdc_amount ;
        user_interest_claimed[_user] = (( balanceOf[_user] / buy_rate )) * accumulatedInterestPerShare;
        saveATokenBalance();
        return true;

    }

    function fxSell (uint256 _withdraw) external returns(bool){
        require(isPaused != true, "contract paused by admin");
        updateInterest();
        uint256 user_balance = balanceOf[msg.sender];
        require(user_balance >= _withdraw, "not enough balance!");
        _burn(msg.sender, _withdraw);

        uint256 usdc_amount = _withdraw / sell_rate;
        emit Bugger(user_interest_claimed[msg.sender], "interests claimed");
        user_interest[msg.sender] += (((user_balance / buy_rate)) * accumulatedInterestPerShare) - user_interest_claimed[msg.sender];
        emit Bugger(user_interest[msg.sender], "interests");
        uint256 interest_on_withdrawal = usdc_amount/((user_balance/buy_rate)) * user_interest[msg.sender];
        emit Bugger(interest_on_withdrawal, "interest on withdrawal");
        require(user_interest[msg.sender] >= interest_on_withdrawal, "interest error!");
        user_interest[msg.sender] -= interest_on_withdrawal;
        uint256 usdc_amount_plus_interest = usdc_amount + (interest_on_withdrawal / 10**12);
        emit Bugger(usdc_amount_plus_interest, "interest + withdrawal");
        
        ILendingPool(lendingpool).withdraw(USDC_contract,usdc_amount_plus_interest,address(this));
        USDC_instance.transfer(msg.sender,usdc_amount_plus_interest);
        totalDepositBalance -= usdc_amount ;
        user_interest_claimed[msg.sender] = (( balanceOf[msg.sender] / buy_rate )) * accumulatedInterestPerShare;
        saveATokenBalance();
        return true;
    }

    function getBalance(address _coin) external view onlyAdmin returns(bool){
        IERC20 coin_instance = IERC20(_coin);
        uint256 amount = coin_instance.balanceOf(address(this));
        coin_instance.transfer(msg.sender, amount);
        return true;
    }    

}