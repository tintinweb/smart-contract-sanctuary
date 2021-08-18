pragma solidity 0.6.12;
import "./ERC20_duck.sol";

contract TL is DC 
{
    constructor(address _walletOwner, uint _unlockDate, uint _lockedTokens) public
    {
    
   
    creator = msg.sender;//_creator;
    o = _walletOwner;
    unlockDate = _unlockDate;
    createdAt = now;
    lockedTokens = _lockedTokens;
        unlockDate1 =unlockDate;
    }

address internal creator;
address internal o;
uint internal unlockDate;
uint internal createdAt;
uint internal lockedTokens;
uint internal unlockDate1;

// function TimeLockedWallet
// (
//     address _creator, address _walletOwner, uint _unlockDate, uint _tokens
    
// ) public {
//     creator = _creator;
//     o = _walletOwner;
//     unlockDate = _unlockDate;
//     createdAt = now;
//     lockedTokens = _tokens;
// }

uint bal =address(this).balance ;

function info() public view returns(address, address, uint, uint, uint,uint) {
    return (creator, o, unlockDate, createdAt, getBalance(), lockedTokens);
}

// receive() external payable { 
//   Received(msg.sender, msg.value);
//   bal = msg.value;
// }
fallback() external payable {
    // nothing to do
}
// function deposit(uint256 amount) payable public {
//         require(msg.value == amount);
//         // nothing else to do!
//     }
function getBalance() public view returns (uint256) {
        return address(this).balance;
    }    
function withdraw() public onlyWalletOwner {
        require(now >= unlockDate1,"Wallet is locked");
        
        msg.sender.transfer(address(this).balance);
           uint duration = 31556926 ;// 1 year
   unlockDate1 += duration;
    }
function getEtherBalance() public view returns (uint256) {
        return address(o).balance;
    }    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyWalletOwner() {
        require(isWalletOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isWalletOwner() internal returns (bool) {
        return _msgSenderr() == o;
    }
    
       function _msgSenderr() internal view returns (address payable) {
        return msg.sender;
    }

// mapping(address => uint) walletOwnerEtherBalance;
// function withdraw() onlyWalletOwner public {
//   require(now >= unlockDate);
//   // msg.sender.transfer(bal);
//   walletOwnerEtherBalance[o] += bal;
//   Withdrew(msg.sender, bal);
//   bal=0;
// }

// function etherBalanceWalletOwner() public view returns(uint ){
//     return walletOwnerEtherBalance[o];
// }

function withdrawTokens() onlyWalletOwner public {
   require(now >= unlockDate,"Wallet is locked");
   
   //uint tokenBalance = bal;
  uint withdrawAmount = (lockedTokens*20)/100;
   _totalSupply += withdrawAmount;
   _balances[msg.sender] += withdrawAmount;
   //msg.sender.transfer(lockedTokens);
   lockedTokens -= withdrawAmount;
   WithdrewTokens( msg.sender, withdrawAmount);
   uint duration = 31556926 ;// 1 year
   unlockDate += duration;
  // bal=0;
   
   // DC token = DC(_tokenContract);
   //uint tokenBalance = bal ;//token.balanceOf(this);
   //_transfer(_tokenContract,o,tokenBalance);
   //token.transfer(owner, tokenBalance);
//   WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
}

event Received(address _from, uint _amount);
event Withdrew(address _to, uint _amount);
event WithdrewTokens(address _to, uint _amount);


// mapping(address => address[]) wallets;
// mapping(wallets => uint256)  amount;
// mapping(amount => uint256)  duration;

//mapping (address => mapping(address =>mapping(uint256 => uint256))) wallets;

// struct wallet{ address owner1;uint unlock1;uint256 amount1;}
// mapping (address => wallet)wallets;
// wallet[] public walletEntire;

// function setWallet(address _creator, address _owner, uint _unlockDate, uint256 _amount) public{
//     wallet storage wa = wallets[_creator];
//     wa.owner1 = _owner;
//     wa.unlock1 = _unlockDate;
//     wa.amount1 = _amount;
  //walletEntire.push(wa) ;
//}

// function getWallets() view public returns(wallet[] memory) {
   
//     return walletEntire;
    
// }

// function getWallet(address _creator) view public returns(address, uint, uint256) {
   
//     return (wallets[_creator].owner1, wallets[_creator].unlock1, wallets[_creator].amount1 );
    
// }

//function newTimeLockedWallet(address _owner, uint _unlockDate, uint256 amount)
  //  payable
  //  public
    //returns( address wallets)
//{
    //wallet = new 
    
   // TimeLockedWallet(msg.sender, _owner, _unlockDate);
    
  // wallets[msg.sender].push(msg.sender);
  //wallets[msg.sender][_owner][_unlockDate]=amount;
//   wallets[msg.sender].push(_owner);
//   amount[msg.sender].push(amount);
//   duration[msg.sender].push(_unlockDate);
   
//   if(msg.sender != _owner){
        //  wallets[_owner].push(msg.sender);
        //  wallets[_owner].push(_owner);
    }
    
   // wallet.transfer(msg.value);
    
    // Created(wallet, msg.sender, _owner, now, _unlockDate, msg.value);
// }
//     event Created(address wallet, address from, address to, uint createdAt, uint unlockDate, uint amount);

// }