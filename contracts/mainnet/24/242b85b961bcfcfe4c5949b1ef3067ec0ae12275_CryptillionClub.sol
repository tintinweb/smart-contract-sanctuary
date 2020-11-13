pragma solidity ^0.7.4;


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


contract CryptillionClub {
    
    using SafeMath for uint256;
    
    struct User {
        address sponsor;
        bool[21] relations;
        uint[21] levels;
    }
    
    
    mapping (address => User) private users;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    
    address private owner;
    address private founder;

    uint private usersCounter;
    uint private normalLevelPrice;
    uint private levelTime;
    
    uint private discountCounter;
    uint private discountTimer;
    uint private discountFactor;
    bool private discountFirst;

    uint private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;


    event GotPartner(address indexed user, address indexed sponsor, uint indexed level, uint regDate);
    event LostPartner(address indexed user, address indexed sponsor, uint indexed level, uint regDate);
    event GotProfit(address indexed sponsor, address indexed user, uint etherAmount, uint tokenAmount, uint rate, uint level, uint date);
    event LostProfit(address indexed sponsor, address indexed user, uint etherAmount, uint tokenAmount, uint rate, uint level, uint date);
    
    event TokenRateChanged(uint indexed tokenRate, uint indexed date);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Sell(address indexed seller, uint256 tokenAmount, uint256 rate, uint256 etherAmount, uint256 date);


    constructor() {
        owner = msg.sender;
        founder = msg.sender;

        usersCounter = 0;

        normalLevelPrice = 100000000000000000;
        levelTime = 8640000;
        
        _name = "Cryptillion Club Token";
        _symbol = "CRION";
        _decimals = 18;
        
        emit TokenRateChanged(10000000000000000, block.timestamp);
    }

    modifier onlyOwner() {
        require (_msgSender() == owner, 'Only for owner');
        _;
    }
    
    modifier maxLevel(uint _level) {
        require (_level >= 1 && _level <= 20, 'Min and max levels are 1-20');
        _;
    }


    receive() external payable {
        revert();
    }

    function changeOwnerAddress(address _newOwner) external onlyOwner {
        owner = _newOwner;
        assert(owner == _newOwner);
    }
    
    function changeFounderAddress(address _newFounder) external onlyOwner {
        founder = _newFounder;
        assert(founder == _newFounder);
    }
    
    function changeNormalLevelPrice(uint _newPrice) external onlyOwner {
        normalLevelPrice = _newPrice;
        assert(normalLevelPrice == _newPrice);
    }
    
    function changeLevelTime(uint _newTime) external onlyOwner {
        levelTime = _newTime;
        assert(levelTime == _newTime);
    }
    
    function createDiscount(uint _counter, uint _timer, uint _factor, bool _first) external onlyOwner {
        discountCounter = _counter;
        discountTimer = _timer;
        discountFactor = _factor;
        discountFirst = _first;
    }
    
    function registerUser(address _sponsor) external payable {
        
        require (msg.value == levelPrice(1), 'Wrong registration payment amount.');
        require (_sponsor != address(0) && users[_sponsor].levels[0] > 0, 'Please provide registered sponsor.');
        require (_sponsor != _msgSender(), 'You can\'t be your own sponsor.');
        require (users[_msgSender()].levels[0] == 0, 'You are already registered');
        
        address temp_sponsor = _sponsor;
        uint[21] memory tempLevels;
        bool[21] memory tempRelations;
        
        tempLevels[0] = 1;
        tempRelations[0] = true;
        
        uint date = block.timestamp;
        
        for (uint i = 1; i <= 20 && temp_sponsor != address(0); ++i) {
            
            if(users[temp_sponsor].levels[i] >= date) {
                
                tempRelations[i] = true;
                emit GotPartner(_msgSender(), temp_sponsor, i, date);
                
            } else {
                
                emit LostPartner(_msgSender(), temp_sponsor, i, date);
            }
            temp_sponsor = users[temp_sponsor].sponsor;
        }
        
        users[_msgSender()] = User(_sponsor, tempRelations, tempLevels);
        
        buyLevel(1);
        
        ++usersCounter;
    }
    
    function createSuperUser(address _superUser, address _sponsor) external onlyOwner {
        
        bool[21] memory tempRelations;
        uint[21] memory tempLevels;
        
        tempLevels[0] = 1;
        tempRelations[0] = true;

        for (uint i = 1; i < 21; ++i) {
            tempLevels[i] = 11044857601;
        }
        
        users[_superUser] = User(_sponsor, tempRelations, tempLevels);
        ++usersCounter;
        
        emit GotPartner(_superUser, _sponsor, 1, block.timestamp);
    }
    
    function buyLevel (uint _level) public payable maxLevel(_level) {
        
        require(msg.value == levelPrice(_level), 'Wrong amount.');
        require(users[_msgSender()].levels[0] == 1, 'Please register.');

        uint nowStamp = block.timestamp;
        
        require(users[_msgSender()].levels[_level] < nowStamp.add(_levelTime()), 'No more than +200 days.');
        
        for (uint i = 1; i < _level; ++i) {
            require(users[_msgSender()].levels[i] >= nowStamp, 'Please, activate the previous levels first.');
        }
        
        if(users[_msgSender()].levels[_level] <= nowStamp) {
            users[_msgSender()].levels[_level] = nowStamp.add(_levelTime());
        } else {
            users[_msgSender()].levels[_level] = users[_msgSender()].levels[_level].add(_levelTime());
        }
        
        address sponsor = getSponsor(_msgSender(), _level);
        
        if (sponsor != address(0)) {
            
            uint etherAmount = msg.value;
            (uint tokenAmount, uint rate) = tokenAmountForEther(etherAmount);
            
            if(_level == 1) {
                etherAmount = etherAmount.div(2);
                tokenAmount = tokenAmount.div(2);
                _mint(founder, tokenAmount);
            }
            
            if (users[sponsor].levels[_level] >= nowStamp) {
            
                _mint(sponsor, tokenAmount);
                emit GotProfit(sponsor, _msgSender(), etherAmount, tokenAmount, rate, _level, nowStamp);
                assert(balanceOf(sponsor) >= tokenAmount);
                
            } else {
                
                emit LostProfit(sponsor, _msgSender(), etherAmount, tokenAmount, rate, _level, nowStamp);
                emit TokenRateChanged(_tokenRate(0), nowStamp);
            }
        } else {
            emit TokenRateChanged(_tokenRate(0), nowStamp);
        }
    }
    
    function getSponsor(address _user, uint _level) public view maxLevel(_level) returns (address) {
        
        address temp_sponsor = users[_user].sponsor;
        
        if (!users[_user].relations[_level]) {
            return address(0);
        } else {
            for (uint i = 2; i <= _level; ++i) {
                temp_sponsor = users[temp_sponsor].sponsor;
            }
            return temp_sponsor;
        }
        
    }
    
    function getRelations(address _user) external view returns (bool[21] memory relations) {
        return users[_user].relations;
    }
    
    function levelPrice(uint _level) public view maxLevel(_level) returns (uint) {
        if((_usersCounter() > _discountCounter() && block.timestamp > _discountTimer()) || users[_msgSender()].levels[_level] != 0) {
            return _normalLevelPrice();
        } else if (_discountFirst() == false || _level == 1) {
            return _normalLevelPrice().div(_discountFactor());
        } else {
            return _normalLevelPrice();
        }
    }
    
    function userInfo(address _user) public view returns (address[21] memory _sponsors, uint[21] memory _levels) {
        
        address[21] memory sponsors;
        bool[21] memory temp_relations = users[_user].relations;
        
        address temp_sponsor = users[_user].sponsor;
        sponsors[0] = temp_sponsor;
        
        for (uint i = 1; i < 21 && temp_sponsor != address(0); ++i) {
            if(temp_relations[i]) {
                sponsors[i] = temp_sponsor;
            }
            temp_sponsor = users[temp_sponsor].sponsor;
        }
        
        return (sponsors, users[_user].levels);
    }
    
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    
    function _usersCounter() public view returns (uint) {
        return usersCounter;
    }
    
    function _normalLevelPrice() public view returns (uint) {
        return normalLevelPrice;
    }
    
    function _levelTime() public view returns (uint) {
        return levelTime;
    }
    
    function _discountCounter() public view returns (uint) {
        return discountCounter;
    }
    
    function _discountTimer() public view returns (uint) {
        return discountTimer;
    }
    
    function _discountFactor() public view returns (uint) {
        return discountFactor;
    }
    
    function _discountFirst() public view returns (bool) {
        return discountFirst;
    }
	
	function _userSponsor(address _user) public view returns (address) {
        return users[_user].sponsor;
    }

    function transfer(address _recipient, uint256 _tokenAmount) public virtual returns (bool) {

        if (_recipient == address(this)) {

            uint date = block.timestamp;
            uint rate = _tokenRate(0);
            uint etherAmount = _tokenAmount.mul(rate).div(10**18);
            
            _burn(_msgSender(), _tokenAmount);

            sendValue(_msgSender(), etherAmount);
            
            emit Sell(_msgSender(), _tokenAmount, rate, etherAmount, date);

        } else {
            _transfer(_msgSender(), _recipient, _tokenAmount);
        }
        return true;
    }
    
    function _transfer(address _sender, address _recipient, uint256 _amount) internal virtual {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");

        _balances[_sender] = _balances[_sender].sub(_amount, "ERC20: transfer amount exceeds balance");
        _balances[_recipient] = _balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }
    
    function transferFrom(address _sender, address _recipient, uint256 _amount) public virtual returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, _msgSender(), _allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function _mint(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(_amount);
        _balances[_account] = _balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }
    
    function _burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: burn from the zero address");

        _balances[_account] = _balances[_account].sub(_amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }
    
    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
    
    function sendValue(address payable _recipient, uint256 _amount) internal {
        require(address(this).balance >= _amount, "Address: insufficient balance");
        (bool success, ) = _recipient.call{ value: _amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowances[_owner][_spender];
    }
    
    function _tokenRate(uint _sum) private view returns (uint) {
        
        uint ttlspl = _totalSupply;
        uint oldContractBalance = address(this).balance.sub(_sum);
        
        if (oldContractBalance == 0 || ttlspl == 0) {
            return 10**16;
        }
        
        return oldContractBalance.mul(10**18).div(ttlspl);
    }
    
    function tokenAmountForEther(uint _sum) private view returns (uint, uint) {
        uint rate = _tokenRate(_sum);
        uint result = _sum.mul(10**18).div(rate);
        return (result, rate);
    }
    
    function calcTokenRate() public view returns (uint) {
        uint ttlspl = _totalSupply;
        uint actualContractBalance = address(this).balance;
        if (actualContractBalance == 0 || ttlspl == 0) {
            return 10**16;
        }
        return actualContractBalance.mul(10**18).div(ttlspl);
    }
}

// SPDX-License-Identifier: MIT