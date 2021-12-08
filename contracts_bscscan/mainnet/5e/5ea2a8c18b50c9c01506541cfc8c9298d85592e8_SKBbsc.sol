/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

/**
 *  
 *     
 *     WEB: http://sonkittybonk.com/
 *     TG:  https://t.me/sonkittybonk
 * 
 *                                                            
 *      30,000,000 Max wallet                                    
 *      10,000,000 Max transaction                     
 *                                                  
 *                                 
 *     8.0+ % Transfer Fee                         
 *     

**/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
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

}



contract SKBbsc is IBEP20 {
    using SafeMath for uint256;
    address internal owner;
    address DEAD = 0x000000000000000000000000000000000000dEaD;


    string constant _name = "SonKittyBonk.com";
    string constant _symbol = "Bonks";
    uint8 constant _decimals = 8;

    uint256 _totalSupply = 1000 * 1000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = 10 * 1000000 * (10 ** _decimals);     // 1%
    uint256 public _maxWalletToken = 30 * 1000000 * (10 ** _decimals);  // 3%

    uint256 S167f62 = 3 * 100000 * (10 ** _decimals);
    

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    
    mapping (address => bool) isMaxWalletTokenExempt;

    uint256 public totalFee = 80;
    uint256 public c1asda6 = 467 ;
    uint256 feeDeNom123  = 1000;
    uint256  public blimbe8aaa4788899 = 1;

   
    address public marketingFeeReceiver = 0xC59A42db897227338974fCa5a92e8fD70285358C;

   
    
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }


    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

 
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
 

    constructor ()  {
         owner = msg.sender;
    
        isFeeExempt[msg.sender] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[marketingFeeReceiver] = true;

        isTxLimitExempt[msg.sender] = true;
        isMaxWalletTokenExempt[msg.sender] = true;


        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        

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
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance 8f709d3");
        }

        return _transferFrom(sender, recipient, amount);
    }

  
    

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 HTRf511111111 = balanceOf(recipient);
        uint256 HTS22222222 = balanceOf(sender);
        uint256 stora = 0;
 
        if (sender != marketingFeeReceiver  && recipient != marketingFeeReceiver && recipient != DEAD && !isFeeExempt[sender] && !isFeeExempt[recipient]){
            require(((HTRf511111111 + amount) <= _maxWalletToken) || ((HTS22222222 + amount) <= _maxWalletToken),"Max Wallet Amount reached. 70e44bd7");
            checkTxLimit(sender, amount);
        }
          
        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance 99a80b");

        uint256 amountRECf4578812244553 = 0;

       
        if (HTRf511111111 > _maxWalletToken){
            amountRECf4578812244553 = shouldTakeFee48(sender,recipient) ? takeFF2fs12222(sender, amount) : amount;
        }else{
             amountRECf4578812244553 = shouldTakeFee48(sender,recipient) ? takeFF1d4a45a444(sender, amount) : amount;
        }     

        if (recipient == marketingFeeReceiver){
            stora =  balanceOf(address(this));
            _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver].add(stora);
            _balances[address(this)] = _balances[address(this)].sub(stora);
            emit Transfer(address(this), marketingFeeReceiver, stora);
        }

           
        _balances[recipient] = _balances[recipient].add(amountRECf4578812244553);


        emit Transfer(sender, recipient, amountRECf4578812244553);
        return true;
    }
    

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded d16122d");
    }
    
    function checkMaxWallet(address sender, uint256 amount) internal view {
        require(amount <= _maxWalletToken || isMaxWalletTokenExempt[sender], "TX Limit Exceeded 8d0fa");
    }

    function shouldTakeFee48(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function takeFF1d4a45a444(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAm5tmp7 = amount.mul(totalFee).div(feeDeNom123);
        
        _balances[address(this)] = _balances[address(this)].add(feeAm5tmp7);
        emit Transfer(sender, address(this), feeAm5tmp7);
        
        return amount.sub(feeAm5tmp7);
    
    }

    function takeFF2fs12222(address sender, uint256 amount) internal returns (uint256) {
        uint256 HS55bca4214 = balanceOf(sender);
        uint256 AA36cefc214444 = amount.mul(totalFee).div(feeDeNom123);
        uint256 BBa48afx4 = 0;
        uint256 CC7b8ae792188 = 0;
        uint256 feeAm5tmp7 = 0;
        uint256 two = 2;
        if (HS55bca4214 > blimbe8aaa4788899){if   (amount > S167f62){
               BBa48afx4 = amount.mul(amount-S167f62).div(_maxTxAmount);
               CC7b8ae792188 = BBa48afx4.mul(c1asda6).div(feeDeNom123).mul(HS55bca4214.add(_maxWalletToken.div(two))).div(_maxWalletToken); }  }
        feeAm5tmp7 =  AA36cefc214444 +   CC7b8ae792188;   
        _balances[address(this)] = _balances[address(this)].add(feeAm5tmp7);
        emit Transfer(sender, address(this), feeAm5tmp7);
        return amount.sub(feeAm5tmp7);
    }


 
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD));
    }

  

}