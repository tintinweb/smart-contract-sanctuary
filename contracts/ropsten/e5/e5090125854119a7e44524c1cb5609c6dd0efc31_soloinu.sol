/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.5.11;

interface Callable {
    function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

contract soloinu {

    uint256 constant private FLOAT_SCALAR = 2**64;
    uint256 constant private INITIAL_SUPPLY = 999e21; // 50Thousand
    uint256 constant private BURN_RATE = 10; // 10% per tx
    uint256 constant private SUPPLY_FLOOR = 1; // 1% of 50Thou = 500
    uint256 public MIN_FREEZE_AMOUNT = 1000000000000000000; // 1 minimum
    uint256 constant private MIN_REWARD_DUR = 30 days;
    uint256 private  Q_BURN_RATE = 20;
    uint256 private  _burnedAmount;

    string constant public name = "sololoan";
    string constant public symbol = "sloan";
    uint8 constant public decimals = 18;

    struct User {
        bool whitelisted;
        uint256 balance;
        uint256 frozen;
        mapping(address => uint256) allowance;
        int256 scaledPayout;
        uint256 loantime;
    }

    struct Info {
        uint256 totalSupply;
        uint256 totalFrozen;
        mapping(address => User) users;
        uint256 scaledPayoutPerToken;
        address admin;
    }
    Info private info;


    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);
    event Whitelist(address indexed user, bool status);
    event Freeze(address indexed owner, uint256 tokens);
    event Unfreeze(address indexed owner, uint256 tokens);
    event Collect(address indexed owner, uint256 tokens);
    event Burn(uint256 tokens);


    constructor() public {
        
        info.admin = msg.sender;
        info.totalSupply = INITIAL_SUPPLY;
        info.users[msg.sender].balance = INITIAL_SUPPLY;
        emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
        whitelist(msg.sender, true);
    }

    function Loan(uint256 _tokens) external {
        _loan(_tokens);
    }
    
    function _minLoan(uint256 _number) onlyCreator public {
        
        MIN_FREEZE_AMOUNT = _number*1000000000000000000;
        
    }
    
    modifier onlyCreator() {
        require(msg.sender == info.admin, "Ownable: caller is not the owner");
        _;
    }
    
    function CutLoan(uint256 _tokens) external {
        _cutloan(_tokens);
    }

    
    function ClaimInterest() external returns (uint256) {
        uint256 _dividends = dividendsOf(msg.sender);
        require(_dividends >= 0, "you do not have any dividend yet");
        info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);
        info.users[msg.sender].balance += _dividends;
        emit Transfer(address(this), msg.sender, _dividends);
        emit Collect(msg.sender, _dividends);
        return _dividends;
    }

    function burn(uint256 _tokens) external {
        require(balanceOf(msg.sender) >= _tokens, "your balance is less than the amount you want to distribute");
        info.users[msg.sender].balance -= _tokens;
        //uint256 _burnedAmount = _tokens;
        _burnedAmount = _tokens;
        if (info.totalFrozen > 0) {
            _burnedAmount /= 2;
            info.scaledPayoutPerToken += _burnedAmount * FLOAT_SCALAR / info.totalFrozen;
            emit Transfer(msg.sender, address(this), _burnedAmount);
        }
        info.totalSupply -= _burnedAmount;
        emit Transfer(msg.sender, address(0x0), _burnedAmount);
        emit Burn(_burnedAmount);
    }
    


    function distribute(uint256 _tokens) external {
        require(info.totalFrozen > 0, "No one has staked yet");
        require(balanceOf(msg.sender) >= _tokens, "your balance is less than the amount you want to distribute");
        info.users[msg.sender].balance -= _tokens;
        info.scaledPayoutPerToken += _tokens * FLOAT_SCALAR / info.totalFrozen;
        emit Transfer(msg.sender, address(this), _tokens);
    }

    function transfer(address _to, uint256 _tokens) external returns (bool) {
        _transfer(msg.sender, _to, _tokens);
        return true;
    }

    function approve(address _spender, uint256 _tokens) external returns (bool) {
        info.users[msg.sender].allowance[_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
        require(info.users[_from].allowance[msg.sender] >= _tokens);
        info.users[_from].allowance[msg.sender] -= _tokens;
        _transfer(_from, _to, _tokens);
        return true;
    }

    function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
        uint256 _transferred = _transfer(msg.sender, _to, _tokens);
        uint32 _size;
        assembly {
            _size := extcodesize(_to)
        }
        if (_size > 0) {
            require(Callable(_to).tokenCallback(msg.sender, _transferred, _data));
        }
        return true;
    }

    function bulkTransfer(address[] calldata _receivers, uint256[] calldata _amounts) external {
        require(_receivers.length == _amounts.length);
        for (uint256 i = 0; i < _receivers.length; i++) {
            _transfer(msg.sender, _receivers[i], _amounts[i]);
        }
    }

    function whitelist(address _user, bool _status) public {
        require(msg.sender == info.admin, "ownable: Only admin can call this function");
        info.users[_user].whitelisted = _status;
        emit Whitelist(_user, _status);
    }


    function totalSupply() public view returns (uint256) {
        return info.totalSupply;
    }

    function totalFrozen() public view returns (uint256) {
        return info.totalFrozen;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return info.users[_user].balance - frozenOf(_user);
    }

    function frozenOf(address _user) public view returns (uint256) {
        return info.users[_user].frozen;
    }

    function dividendsOf(address _user) public view returns (uint256) {
        return uint256(int256(info.scaledPayoutPerToken * info.users[_user].frozen) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
    }

    function allowance(address _user, address _spender) public view returns (uint256) {
        return info.users[_user].allowance[_spender];
    }

    function isWhitelisted(address _user) public view returns (bool) {
        return info.users[_user].whitelisted;
    }
    

    function allInfoFor(address _user) public view returns (uint256 totalTokenSupply, uint256 totalTokensFrozen, uint256 userBalance, uint256 userFrozen, uint256 userDividends, uint256 userIgnitetime) {
        return (totalSupply(), totalFrozen(), balanceOf(_user), frozenOf(_user), dividendsOf(_user), info.users[_user].loantime);
    }

 
    function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {
        require(balanceOf(_from) >= _tokens);
        info.users[_from].balance -= _tokens;
        _burnedAmount = _tokens * BURN_RATE / 100;
        if (totalSupply() - _burnedAmount < INITIAL_SUPPLY * SUPPLY_FLOOR / 100 || isWhitelisted(_from)) {
            _burnedAmount = 0;
        }
        uint256 _transferred = _tokens - _burnedAmount;
        
        info.users[_to].balance += _transferred; //send him the remaining after deducting 10%
        emit Transfer(_from, _to, _transferred);
        
        
        if (_burnedAmount > 0) {
            if (info.totalFrozen > 0) {
                
                uint _burnedAmountA = _burnedAmount*80/100;
                info.scaledPayoutPerToken += _burnedAmountA * FLOAT_SCALAR / info.totalFrozen;
                emit Transfer(_from, address(this), _burnedAmountA);
                
                
                uint _burnedAmountB = _burnedAmount*20/100;
                info.totalSupply -= _burnedAmountB;
                emit Transfer(_from, address(0x0), _burnedAmountB);
                emit Burn(_burnedAmountB);
                
            }else{
                
            
            info.totalSupply -= _burnedAmount;
            emit Transfer(_from, address(0x0), _burnedAmount);
            emit Burn(_burnedAmount);
            
            }
            
            
        }
        return _transferred;
    }


    function _loan(uint256 _amount) internal {
        require(balanceOf(msg.sender) >= _amount, "Insufficient token balance");
        require(frozenOf(msg.sender) + _amount >= MIN_FREEZE_AMOUNT, "Your balance is lower than the min. stake");
        info.users[msg.sender].loantime = now;
        info.totalFrozen += _amount;
        info.users[msg.sender].frozen += _amount;
        info.users[msg.sender].scaledPayout += int256(_amount * info.scaledPayoutPerToken);
        emit Transfer(msg.sender, address(this), _amount);
        emit Freeze(msg.sender, _amount);

    
    }
    
   
    
    function _cutloan(uint256 _amount) internal {
        
        require(frozenOf(msg.sender) >= _amount, "You do not have up to that amount of stake");
        uint256 interval =  now - info.users[msg.sender].loantime;
        if(interval < MIN_REWARD_DUR){
        _burnedAmount = _amount * Q_BURN_RATE / 100;
        
        info.users[msg.sender].balance -= _burnedAmount;
        
        info.totalFrozen -= _amount;
        info.users[msg.sender].frozen -= _amount;
        info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledPayoutPerToken);
        info.scaledPayoutPerToken += _burnedAmount * FLOAT_SCALAR / info.totalFrozen;
        emit Transfer(address(this), msg.sender, _amount);
        emit Unfreeze(msg.sender, _amount);
         
        }else{
            
        info.totalFrozen -= _amount;
        info.users[msg.sender].frozen -= _amount;
        info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledPayoutPerToken);
        emit Transfer(address(this), msg.sender, _amount);
        emit Unfreeze(msg.sender, _amount);
        
        }
        
        
        
    }
    

}