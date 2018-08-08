pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // уточниьт у МЕноскоп про этот функционал  - убрали  передачу владения (по итогам встречи 20171128)
  /*
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  */
}

//Abstract contract for Calling ERC20 contract
contract AbstractCon {
    function allowance(address _owner, address _spender)  public pure returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function token_rate() public returns (uint256);
    function minimum_token_sell() public returns (uint16);
    function decimals() public returns (uint8);
    //function approve(address _spender, uint256 _value) public returns (bool); //test
    //function transfer(address _to, uint256 _value) public returns (bool); //test
    
}

//ProxyDeposit
contract SynergisProxyDeposit is Ownable {
    using SafeMath for uint256;

    ///////////////////////
    // DATA STRUCTURES  ///
    ///////////////////////
    enum Role {Fund, Team, Adviser}
    struct Partner {
        Role roleInProject;
        address account;
        uint256  amount;
    }

    mapping (int16 => Partner)  public partners; //public for dubug only
    mapping (address => uint8) public special_offer;// % of discount


    /////////////////////////////////////////
    // STAKE for partners    - fixed !!!   //
    /////////////////////////////////////////
    uint8 constant Stake_Team = 10;
    uint8 constant Stake_Adv = 5;

    string public constant name = "SYNERGIS_TOKEN_CHANGE";


    uint8 public numTeamDeposits = 0; //public for dubug only
    uint8 public numAdviserDeposits = 0; //public for dubug only
    int16 public maxId = 1;// public for dubug only
    uint256 public notDistributedAmount = 0;
    uint256 public weiRaised; //All raised ether
    address public ERC20address;

    ///////////////////////
    /// EVENTS     ///////
    //////////////////////
    event Income(address from, uint256 amount);
    event NewDepositCreated(address _acc, Role _role, int16 _maxid);
    event DeletedDeposit(address _acc, Role _role, int16 _maxid, uint256 amount);
    event DistributeIncome(address who, uint256 notDistrAm, uint256 distrAm);
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 weivalue, uint256 tokens);
    event FundsWithdraw(address indexed who, uint256 amount );
    event DepositIncome(address indexed _deposit, uint256 _amount );
    event SpecialOfferAdd(address _acc, uint16 _discount);
    event SpecialOfferRemove(address _acc);
     

    //!!!! Fund Account address must be defind and provided in constructor
    constructor (address fundAcc) public {
        //costructor
        require(fundAcc != address(0)); //Fund must exist
        partners[0]=Partner(Role.Fund, fundAcc, 0);// Always must be Fund
    }

    function() public payable {
        emit Income(msg.sender, msg.value);
        sellTokens(msg.sender);
    }

        // low level token purchase function
    function sellTokens(address beneficiary) internal  {  //public payable modificatros- for truffle tests only
        uint256 weiAmount = msg.value; //local
        notDistributedAmount = notDistributedAmount.add(weiAmount);//
        AbstractCon ac = AbstractCon(ERC20address);
        //calculate token amount for sell -!!!! must check on minimum_token_sell
        uint256 tokens = weiAmount.mul(ac.token_rate()*(100+uint256(special_offer[beneficiary])))/100;
        require(beneficiary != address(0));
        require(ac.token_rate() > 0);//implicit enabling/disabling sell
        require(tokens >= ac.minimum_token_sell()*(10 ** uint256(ac.decimals())));
        require(ac.transferFrom(ERC20address, beneficiary, tokens));//!!!token sell/change
        weiRaised = weiRaised.add(weiAmount);
        emit TokenPurchase(msg.sender, beneficiary, msg.value, tokens);
    }

    //set   erc20 address for token process  with check of allowance 
    function setERC20address(address currentERC20contract)  public onlyOwner {
        require(address(currentERC20contract) != 0);
        AbstractCon ac = AbstractCon(currentERC20contract);
        require(ac.allowance(currentERC20contract, address(this))>0);
        ERC20address = currentERC20contract;
    }    

    /////////////////////////////////////////
    // PARTNERS DEPOSIT MANAGE          /////
    /////////////////////////////////////////
    //Create new deposit account
    function newDeposit(Role _role, address _dep) public onlyOwner returns (int16){
        require(getDepositID(_dep)==-1);//chek double
        require(_dep != address(0));
        require(_dep != address(this));
        int16 depositID = maxId++;//first=, then ++
        partners[depositID]=Partner(_role, _dep, 0);//new deposit with 0 ether
        //We need to know number of deposits per Role
        if (_role==Role.Team) {
            numTeamDeposits++; // For quick calculate stake
        }
        if (_role==Role.Adviser) {
            numAdviserDeposits++; // For quick calculate stake
        }
        emit NewDepositCreated(_dep, _role, depositID);
        return depositID;
    }

    //Delete Team or Adviser accounts
    function deleteDeposit(address dep) public onlyOwner {
        int16 depositId = getDepositID(dep);
        require(depositId>0);
        //can`t delete Fund deposit account
        require(partners[depositId].roleInProject != Role.Fund);
        //Decrease deposits number befor deleting
        if (partners[depositId].roleInProject==Role.Team) {
            numTeamDeposits--;
        }
        if (partners[depositId].roleInProject==Role.Adviser) {
            numAdviserDeposits--;
        }
        //return current Amount of deleting Deposit  to  notDistributedAmount
        notDistributedAmount = notDistributedAmount.add(partners[depositId].amount);
        emit DeletedDeposit(dep, partners[depositId].roleInProject, depositId, partners[depositId].amount);
        delete(partners[depositId]);

    }

    function getDepositID(address dep) internal constant returns (int16 id){
        //id = -1; //not found
        for (int16 i=0; i<=maxId; i++) {
            if (dep==partners[i].account){
                //id=i;
                //return id;
                return i;
            }
        }
        return -1;
    }

    //withdraw with pull payee patern
    function withdraw() external {
        int16 id = getDepositID(msg.sender);
        require(id >=0);
        uint256 amount = partners[id].amount;
        // set to zero the pending refund before
        // sending to prevent re-entrancy attacks
        partners[id].amount = 0;
        msg.sender.transfer(amount);
        emit FundsWithdraw(msg.sender, amount);
    }


    function distributeIncomeEther() public onlyOwner { 
        require(notDistributedAmount !=0);
        uint256 distributed;
        uint256 sum;
        uint256 _amount;
        for (int16 i=0; i<=maxId; i++) {
            if  (partners[i].account != address(0) ){
                sum = 0;
                if  (partners[i].roleInProject==Role.Team) {
                    sum = notDistributedAmount/100*Stake_Team/numTeamDeposits;
                    emit DepositIncome(partners[i].account, uint256(sum));
                }
                if  (partners[i].roleInProject==Role.Adviser) {
                    sum = notDistributedAmount/100*Stake_Adv/numAdviserDeposits;
                    emit DepositIncome(partners[i].account, uint256(sum));
                }
                if  (partners[i].roleInProject==Role.Fund) {
                    int16 fundAccountId=i; //just Remember last id
                } else {
                    partners[i].amount = partners[i].amount.add(sum);
                    distributed = distributed.add(sum);
                }
            }
        }
        //And now Amount for Fund = notDistributedAmount - distributed
        emit DistributeIncome(msg.sender, notDistributedAmount, distributed);
        _amount = notDistributedAmount.sub(distributed);
        partners[fundAccountId].amount =
                 partners[fundAccountId].amount.add(_amount);
        emit DepositIncome(partners[fundAccountId].account, uint256(_amount));         
        notDistributedAmount = 0;
        //проверить  на  ошибку   округления.
    }


    //Check of red_balance
    function checkBalance() public constant returns (uint256 red_balance) {
        // this.balance = notDistributedAmount + Sum(all deposits)
        uint256 allDepositSum;
        for (int16 i=0; i<=maxId; i++) {
            allDepositSum = allDepositSum.add(partners[i].amount);
        }
        red_balance = address(this).balance.sub(notDistributedAmount).sub(allDepositSum);
        return red_balance;
    }

    //общая практика,  но уменьшает прозрачность и доверие -убрали destroy (по итогам встречи 20171128)
    /*
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
    */

    //////////////////////////////////////////////////////////////////////
    /////  SPECIAL OFFER MANAGE - DISCOUNTS        ///////////////////////
    //////////////////////////////////////////////////////////////////////

        //For add percent discount for some purchaser - see WhitePaper
    function addSpecialOffer (address vip, uint8 discount_percent) public onlyOwner {
        require(discount_percent>0 && discount_percent<100);
        special_offer[vip] = discount_percent;
        emit SpecialOfferAdd(vip, discount_percent);
    }

    //For remove discount for some purchaser - see WhitePaper
    function removeSpecialOffer(address was_vip) public onlyOwner {
        special_offer[was_vip] = 0;
        emit SpecialOfferRemove(was_vip);
    }
  //***************************************************************
  //Token Change Contract Design by IBERGroup, email:<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f29f938a819b889f9d909b9e97b29b909780dc95809d8782">[email&#160;protected]</a>; 
  //     Telegram: https://t.me/msmobile
  //
  ////**************************************************************
}