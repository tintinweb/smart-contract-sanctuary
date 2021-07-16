//SourceUnit: DFORK_trc20.sol

pragma solidity 0.5.10;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


}

contract ERC20token is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    uint public maxtotalsupply = 28500000000000;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function maxTokenSupply() public view returns (uint256) {
        return maxtotalsupply;
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
        require(account != address(0), "TRC20: Cannot mint to the zero address");

        //_totalSupply = _totalSupply.add(amount);
        //_balances[account] = _balances[account].add(amount);
        //emit Transfer(address(0), account, amount);

        uint sumofTokens = _totalSupply.add(amount);
        if(sumofTokens <= maxtotalsupply){
            _totalSupply = _totalSupply.add(amount);
            _balances[account] = _balances[account].add(amount);
            emit Transfer(address(0), account, amount);
        }else{
            uint netTokens = maxtotalsupply.sub(_totalSupply);
            if(netTokens >0) {
                _totalSupply = _totalSupply.add(netTokens);
                _balances[account] = _balances[account].add(netTokens);
                emit Transfer(address(0), account, netTokens);
            }
        }
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: Cannot burn from the zero address");
        require(amount <= _balances[account]);

        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds your balance");
        _totalSupply = _totalSupply.sub(amount);
        maxtotalsupply = maxtotalsupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _burnTokens(address account, uint256 amount) public {
        require(account != address(0), "ERC20: Cannot burn from the zero address");
        require(msg.sender==account);
        require(amount <= _balances[account]);


        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds your balance");
        _totalSupply = _totalSupply.sub(amount);
        maxtotalsupply = maxtotalsupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract ERC677 is ERC20token {
    function transferAndCall(address to, uint value, bytes memory data) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

interface ERC677Receiver {
    function onTokenTransfer(address _sender, uint _value, bytes calldata _data) external;
}

contract ERC677Token is ERC677 {

    /**
    * @dev transfer token to a contract address with additional data if the recipient is a contact.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data The extra data to be passed to the receiving contract.
    */
    function transferAndCall(address _to, uint _value, bytes memory _data) public returns (bool success) {
        super.transfer(_to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
            contractFallback(_to, _value, _data);
        }
        return true;
    }

    function contractFallback(address _to, uint _value, bytes memory _data) private {
        ERC677Receiver receiver = ERC677Receiver(_to);
        receiver.onTokenTransfer(msg.sender, _value, _data);
    }

    function isContract(address _addr) private view returns (bool hasCode) {
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }

}

contract DK is ERC20token, ERC677Token {
    string public name = "DATA FORK";
    string public symbol = "DK";
    uint8 constant public decimals = 6;
    
    uint public exchangeDk = 0;
    uint public currentPrice = 10;
    uint public currentRounds = 1;
    uint public currentLayers = 1;
    uint public currentBalance = 150000;

    uint private minDepositSize = 100;
    uint private interestRateDivisor = 1000000;
    uint private commissionDivisor = 100;
    uint private quotaPrice = 10;
    uint private usdtAmount;
    uint private tokenAmount;
    
    IERC20 usdtToken;

    address payable owner;
    address payable affAddress;
    address payable usdtAddress;
    
    struct Player {
        uint dkAmount;
        uint usdtAmount;
        uint affRewardQuota;
        address affFrom;
        uint affNum;
    }

    address[] private team100;
    address[] private team500;
    address[] private team1000;
    address[] private team;
    address[] private newTeam;
    mapping(address => Player) public players;
    
    event Exchange(uint _amount);
    event Partake(address _affAddr, uint amount);
    event WithdrawDk(uint amount);
    event WithdrawUsdt(uint amount);
     
    constructor(address _usdtAddress) public {
        owner = msg.sender;
        usdtAddress = msg.sender;
        affAddress = msg.sender;
        usdtToken = IERC20(_usdtAddress);

    }
    

    function exchange(uint _amount) public payable{
        Player storage p = players[msg.sender];
        require(p.affRewardQuota >= _amount, "Insufficient dk reward quota");
        usdtAmount = _amount.div(quotaPrice);
        require(usdtToken.transferFrom(msg.sender, usdtAddress, usdtAmount.mul(interestRateDivisor)),"Insufficient usdt balance");
        p.dkAmount = p.dkAmount + _amount;
        p.affRewardQuota = p.affRewardQuota - _amount;
        exchangeDk = exchangeDk + _amount;
        if(currentBalance > _amount){
            currentBalance = currentBalance - _amount;
        } else if(currentBalance == _amount){
            currentBalance = 0;
            updatePrice();
        } else {
            _amount = _amount - currentBalance;
            currentBalance = 0;
            updatePrice();
            currentBalance = currentBalance - _amount;
        }
        emit Exchange(_amount);

    }

    function partake(address payable _affAddr, uint amount) public payable{
        require(amount == 100 || amount == 500 || amount == 1000, "Please enter the specified quantity");
        
        require(usdtToken.transferFrom(msg.sender, usdtAddress, amount.mul(interestRateDivisor)),"Insufficient usdt balance");
        Player storage p = players[msg.sender];
        if(p.affFrom == address(0) || p.affFrom == affAddress){
			p.affFrom = _affAddr;
        } else {
            p.affFrom = affAddress;
        }

        if(amount == 100){
            team100.push(msg.sender);
            team = team100;
            if (team100.length == 9){
                team100 = newTeam;
            }
        } else if (amount == 500){
            team500.push(msg.sender);
            team = team500;
            if (team500.length == 9){
                team500 = newTeam;
            }
        } else if (amount == 1000){
            team1000.push(msg.sender);
            team = team1000;
            if (team1000.length == 9){
                team1000 = newTeam;
            }
        }
        if(team.length != 9){
            emit Partake(_affAddr, amount);
            return;
        }
        address luckeyAddress1;
        address luckeyAddress2;
        address luckeyAddress3;
        address otherAddress1;
        address otherAddress2;
        address otherAddress3;
        address otherAddress4;
        address otherAddress5;
        address otherAddress6;
        uint n = rand(9);
        luckeyAddress1 = team[n];
        n = n + 1;
        if (n > 8){
            n = 0;
        }
        luckeyAddress2 = team[n];
        n = n + 1;
        if (n > 8){
            n = 0;
        }
        luckeyAddress3 = team[n];
        n = n + 1;
        if (n > 8){
            n = 0;
        }
        otherAddress1 = team[n];
        n = n + 1;
        if (n > 8){
            n = 0;
        }
        otherAddress2 = team[n];
        n = n + 1;
        if (n > 8){
            n = 0;
        }
        otherAddress3 = team[n];
        n = n + 1;
        if (n > 8){
            n = 0;
        }
        otherAddress4 = team[n];
        n = n + 1;
        if (n > 8){
            n = 0;
        }
        otherAddress5 = team[n];
        n = n + 1;
        if (n > 8){
            n = 0;
        }
        otherAddress6 = team[n];

        tokenAmount = amount.mul(commissionDivisor).div(currentPrice);

        affRewDkQuota(luckeyAddress1, tokenAmount);
        affRewDkQuota(luckeyAddress2, tokenAmount);
        affRewDkQuota(luckeyAddress3, tokenAmount);
        affRewUsdt(otherAddress1, amount);
        affRewUsdt(otherAddress2, amount);
        affRewUsdt(otherAddress3, amount);
        affRewUsdt(otherAddress4, amount);
        affRewUsdt(otherAddress5, amount);
        affRewUsdt(otherAddress6, amount);
        tokenAmount = tokenAmount.mul(3);
        exchangeDk = exchangeDk + tokenAmount;
        if(currentBalance > tokenAmount){
            currentBalance = currentBalance - tokenAmount;
        } else if(currentBalance == tokenAmount){
            currentBalance = 0;
            updatePrice();
        } else {
            tokenAmount = tokenAmount - currentBalance;
            currentBalance = 0;
            updatePrice();
            currentBalance = currentBalance - tokenAmount;
        }
        emit Partake(_affAddr, amount);
    }

    function withdrawDk() public payable{

        Player storage p = players[msg.sender];
		uint _amount = p.dkAmount;
		require(_amount > 0, "Insufficient dk balance");
        _mint(msg.sender, _amount.mul(interestRateDivisor));
		p.dkAmount = 0;
        emit WithdrawDk(_amount);
    }

    function withdrawUsdt() public payable{

        Player storage p = players[msg.sender];
		uint _amount = p.usdtAmount;
        require(_amount > 0, "Insufficient usdt balance");
        usdtToken.transferFrom(usdtAddress, msg.sender, _amount.mul(interestRateDivisor));
		p.usdtAmount = 0;
        emit WithdrawUsdt(_amount);
    }

    function affRewDkQuota(address _account, uint _amount) private{
        Player storage p = players[_account];
        p.dkAmount = p.dkAmount + _amount;
        uint  affQuota = _amount.div(10);
        if(p.affFrom != affAddress){
            Player storage aff = players[p.affFrom];
            aff.affRewardQuota = aff.affRewardQuota + affQuota;
        }
    }
    function affRewUsdt(address _account, uint _amount) private{
        Player storage  p = players[_account];
        p.usdtAmount = p.usdtAmount + _amount.div(10) + _amount;
        uint affUsdtAmount = _amount.div(100);
        if(p.affFrom != affAddress){
            Player storage aff = players[p.affFrom];
            aff.usdtAmount = aff.usdtAmount + affUsdtAmount;
        }
    }

    function getPlayerInfo(address _addr) public view returns (uint affRewardQuota, address affFrom, uint affNum, uint _dkAmount, uint _usdtAmount) {
        address playerAddress= _addr;
        Player storage player = players[playerAddress];
        affRewardQuota = player.affRewardQuota;
        affFrom = player.affFrom;
        affNum = player.affNum;
        _dkAmount = player.dkAmount;
        _usdtAmount = player.usdtAmount;
    }

    function getProjectInfo() public view returns (uint _currentPrice, uint _currentRounds, uint _currentLayers, uint _currentBalance) {

        _currentPrice = this.currentPrice();
        _currentRounds = this.currentRounds();
        _currentLayers = this.currentLayers();
        _currentBalance = this.currentBalance();
    }

    function getTeamInfo() public view returns(uint team100length, uint team500length, uint team1000length){
        team100length = team100.length;
        team500length = team500.length;
        team1000length = team1000.length;
    }

    function updateUsdtAddress(address payable _address) public {
        require(msg.sender==owner);
        usdtAddress = _address;
    }
    function updateAffAddress(address payable _address) public  {
        require(msg.sender==owner);
        affAddress = _address;
    }
    function updateOwner(address payable _address) public {
        require(msg.sender==owner);
        owner = _address;
    }
    function rand(uint256 _length) private view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now)));
        return random%_length;
    }

    function updatePrice() private{
        if (currentBalance == 0){
            if(currentRounds == 1){
                if(currentLayers == 10){
                    currentRounds = 2;
                    currentLayers = 1;
                    currentPrice = 58;
                    currentBalance = 200000;
                } else {
                    currentLayers++;
                    currentPrice = currentPrice.add(5);
                    currentBalance = 150000;
                }
            } else if(currentRounds == 2){
                if(currentLayers == 10){
                    currentRounds = 3;
                    currentLayers = 1;
                    currentPrice = 87;
                    currentBalance = 300000;
                } else {
                    currentLayers++;
                    currentPrice = currentPrice.add(3);
                    currentBalance = 200000;
                }
            } else if(currentRounds == 3){
                if(currentLayers == 10){
                    currentRounds = 4;
                    currentLayers = 1;
                    currentPrice = 109;
                    currentBalance = 400000;
                } else {
                    currentLayers++;
                    currentPrice = currentPrice.add(2);
                    currentBalance = 300000;
                }
            } else if(currentRounds == 4){
                if(currentLayers == 10){
                    currentRounds = 5;
                    currentLayers = 1;
                    currentPrice = 150;
                    currentBalance = 500000;
                } else {
                    currentLayers++;
                    currentPrice = currentPrice.add(4);
                    currentBalance = 400000;
                }
            } else if(currentRounds == 5){
                if(currentLayers == 10){
                    currentRounds = 6;
                    currentLayers = 1;
                    currentPrice = 201;
                    currentBalance = 600000;
                } else {
                    currentLayers++;
                    currentPrice = currentPrice.add(5);
                    currentBalance = 500000;
                }
            } else if(currentRounds == 6){
                if(currentLayers == 10){
                    currentRounds = 7;
                    currentLayers = 1;
                    currentPrice = 262;
                    currentBalance = 700000;
                } else {
                    currentLayers++;
                    currentPrice = currentPrice.add(6);
                    currentBalance = 600000;
                }
            } else if(currentRounds == 7){
                if(currentLayers == 10){
                    return;
                } else {
                    currentLayers++;
                    currentPrice = currentPrice.add(5);
                    currentBalance = 700000;
                }
            }
        }
    }
}