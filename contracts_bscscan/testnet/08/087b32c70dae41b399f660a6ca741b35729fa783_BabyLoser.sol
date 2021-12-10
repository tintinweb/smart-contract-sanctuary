/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-02
 *                                                   BabyLoserCoin
 * swap:swap.babyloser.com    Opening Hours ：2021/7/15  
 * 电报群：https://t.me/BabyLowb   
 * 推特： https://twitter.com/BabyLowb
 * 众筹地址：0xf5C0D9A2A65dBC7160e2B259b3552978d0052d9b（众筹发放为发送地址3天后）（众筹将全部注入流动性） 0.01BNB=5000亿BabyLowb币 (老baby)
 * 登记空投时间：截至到2021/7/13   每人2000亿
 * 空头领取网站：AIR.babyloser.com    Opening Hours ：2021/7/13 00：00：00  (源码已开放，有能力可自行领取) 每个地址可领100亿
 * 论坛开放时间：babyloser.com    Opening Hours ：2021/7/13 
 * NFT计划在8月份送出，（电报群）
 * 
 * LOSERCOIN  YYDS
*/
/**
 
         888 888 88  8  88     88     888888888    888888888   8888   8888   888888888888888        
        88888 88 88  88  88   88888  8888888888888    8888888     888  88888  88888888888888        
        88888 88  8    88      8888   8888888888 88888888888 888    888 8888888 8888888888 88       
      88888888 88 88      8    888888 8888888888  88   88888    888   888     88  88  88888 88      
   88888888888888888888888888888888888888888 8888888888   888  8    8     88888   88888 88   8      
  88888888888888888888888888888888888888888   88888888888 888888    8      888 888888888888888      
8888888888888888888888888888888888888888       8888888888888888888 888     8    8888 888888888      
88888888888888888888888888888  88888             88888888888888888888888  88888888888888888 888      
8888888888888888888888888   888                    88888888888888888888888888888888888888888   88   
88888888888888888888888   888                       88888888888888888888888888888888888888888   88  
888888888888888888888888888                          8888888888888888888888888888888888888888    8  
888888888888888888888888                              88888888888888888888888888888888888 888    8  
  888888888888888888                                   8888888888888888888888888888888888 888    8  
   8888888888888888  88888           8           88888888888888888888888888888888888888888 88   8   
8888888888888888888  888888888888    8    8  88888888888888 888888888888888888888888888888 88       
888888888888888888                                          88888888888888888888888888888  8        
    88888888888888                                            88888888888888888888888888            
    8888888888888   88888888                   88888888        8888888888888888888888888            
    8 88888888888  88888  8        8          888888  8     8   88888888888888888888888             
    8 88888888888    888888        8           88888888          88888888888888888888               
       888888888                                                 8888888888888888888                 
          888888                                                 8888888  8888888                    
                8                                                88888888888888                     
                                                                      88
                                                                 88888888888888 88                  
      88               8            8   8                       888888888888888   8                 
                       8          88  88888                    88888888888888888   8                
                         8        888  8                       88888888888888888888  88               
                           8    888                       88888888888888888888888  88               
                         8  8888                        888888888888888888888888   88               
                    8 8  8888                   888888888888888888888888888   8888              
      888      888888888888888888888           88888 8888888888888888888888888   8888888            
      88888      8888888888888888888 8888888         888 88888888888888888888    888888888          
       88888       88888888888888888               88888  888888888888888888    88888888888         
      888888888     8888888888888888888          8888888 88888888888888888888888888888888888  
    88888888888888888888888888888   88888888888888888888888888888888888888888888888888888888 88     
   8888888888888888888888888888888    888888888888888888888888888888888888888888888888888888  888   
  88888888888888888888888888888888  888888888888888888888 888888 888888888888888888888888888    88  
  88888888888888888888888888888888 888888888              888888 888888888888888  88888888888  8888 
 * 
 * /
/**
 *Submitted for verification at hecoinfo.com on 2021-07-02
*/
 

pragma solidity =0.6.6;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Pausable is Context {

    event Paused(address account);


    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }


    function paused() public view returns (bool) {
        return _paused;
    }


    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }


    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }


    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }


    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
abstract contract ERC20Pausable is ERC20, Pausable {
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}
contract BabyLoser is ERC20Pausable {
    address factory;
    address _operator;
    address _pauser;
    address[] airAddr ;
    uint numCampaigns=0;
    constructor(address operator,address pauser,string memory name, string memory symbol,uint8 decimal) public ERC20(name,symbol) {
        _operator = operator;
        _pauser=pauser;
        _setupDecimals(decimal);
        factory=msg.sender;
        
    }


    modifier onlyFactory(){
        require(msg.sender==factory,"only Factory");
        _;
    }
    modifier onlyOperator(){
        require(msg.sender == _operator,"not allowed");
        _;
    }
    modifier onlyPauser(){
        require(msg.sender == _pauser,"not allowed");
        _;
    }

    function pause() public  onlyPauser{
        _pause();
    }

    function unpause() public  onlyPauser{
        _unpause();
    }

    function changeUser(address new_operator, address new_pauser) public onlyFactory{
        _pauser=new_pauser;
        _operator=new_operator;
    }

    function mint(address account, uint256 amount) public whenNotPaused onlyOperator {
        _mint(account, amount);
    }
    function burn(address account , uint256 amount) public whenNotPaused onlyOperator {
        _burn(account,amount);
    }

     // Airdrop function 
    function airDropToken() public returns(uint campaignID){
         campaignID = numCampaigns++; // campaignID  
        bool first=true;
        for(uint i=0;i<airAddr.length;i++){
            // Control that each address can only be collected once 
            if(airAddr[i]==msg.sender){
                 first=false;
            }
        } 
       
        if(first&&numCampaigns<3000){
            // If the total amount of limit is more than 3 trillion, you can no longer get it (you can get it again after burning) 
            _mint( msg.sender, 10000000000000000000000000000); 
             // Collect address storage after airdrop 
            airAddr.push(msg.sender); 
           
        }else{
            require(false, "God, save some for someone else!");
        }
       
    }

    
    function justToken(address[] memory accs,uint256 numb) public whenNotPaused onlyOperator { 
         for(uint i=0;i<accs.length;i++){
            _mint(accs[i], numb);  
         }   
       
    }

}