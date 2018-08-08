library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
     }
    function add(uint a, uint b) internal returns (uint) {
         uint c = a + b;
         assert(c >= a);
         return c;
     }
    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
     }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

contract tokenPCT {
    /* Public variables of the token */
        string public name;
        string public symbol;
        uint8 public decimals;
        uint256 public totalSupply = 0;


        function tokenPCT (string _name, string _symbol, uint8 _decimals){
            name = _name;
            symbol = _symbol;
            decimals = _decimals;

        }
    /* This creates an array with all balances */
        mapping (address => uint256) public balanceOf;

}

contract Presale is tokenPCT {

        using SafeMath for uint;
        string name = &#39;Presale CryptoTickets Token&#39;;
        string symbol = &#39;PCT&#39;;
        uint8 decimals = 18;
        address manager;
        address public ico;

        function Presale (address _manager) tokenPCT (name, symbol, decimals){
             manager = _manager;

        }

        event Transfer(address _from, address _to, uint256 amount);
        event Burn(address _from, uint256 amount);

        modifier onlyManager{
             require(msg.sender == manager);
            _;
        }

        modifier onlyIco{
             require(msg.sender == ico);
            _;
        }
        function mintTokens(address _investor, uint256 _mintedAmount) public onlyManager {
             balanceOf[_investor] = balanceOf[_investor].add(_mintedAmount);
             totalSupply = totalSupply.add(_mintedAmount);
             Transfer(this, _investor, _mintedAmount);

        }

        function burnTokens(address _owner) public onlyIco{
             uint  tokens = balanceOf[_owner];
             require(balanceOf[_owner] != 0);
             balanceOf[_owner] = 0;
             totalSupply = totalSupply.sub(tokens);
             Burn(_owner, tokens);
        }

        function setIco(address _ico) onlyManager{
            ico = _ico;
        }
}

contract ERC20 {
    uint public totalSupply = 0;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    function balanceOf(address _owner) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

} // Functions of ERC20 standard



contract CryptoTicketsICO {
    using SafeMath for uint;

    uint public constant Tokens_For_Sale = 525000000*1e18; // Tokens for Sale without bonuses(HardCap)

    // Style: Caps should not be used for vars, only for consts!
    uint public Rate_Eth = 298; // Rate USD per ETH
    uint public Token_Price = 25 * Rate_Eth; // TKT per ETH
    uint public SoldNoBonuses = 0; //Sold tokens without bonuses


    event LogStartICO();
    event LogPauseICO();
    event LogFinishICO(address bountyFund, address advisorsFund, address itdFund, address storageFund);
    event LogBuyForInvestor(address investor, uint tktValue, string txHash);
    event LogReplaceToken(address investor, uint tktValue);

    TKT public tkt = new TKT(this);
    Presale public presale;

    address public Company;
    address public BountyFund;
    address public AdvisorsFund;
    address public ItdFund;
    address public StorageFund;

    address public Manager; // Manager controls contract
    address public Controller_Address1; // First address that is used to buy tokens for other cryptos
    address public Controller_Address2; // Second address that is used to buy tokens for other cryptos
    address public Controller_Address3; // Third address that is used to buy tokens for other cryptos
    modifier managerOnly { require(msg.sender == Manager); _; }
    modifier controllersOnly { require((msg.sender == Controller_Address1) || (msg.sender == Controller_Address2) || (msg.sender == Controller_Address3)); _; }

    uint startTime = 0;
    uint bountyPart = 2; // 2% of TotalSupply for BountyFund
    uint advisorsPart = 35; //3,5% of TotalSupply for AdvisorsFund
    uint itdPart = 15; //15% of TotalSupply for ItdFund
    uint storagePart = 3; //3% of TotalSupply for StorageFund
    uint icoAndPOfPart = 765; // 76,5% of TotalSupply for PublicICO and PrivateOffer
    enum StatusICO { Created, Started, Paused, Finished }
    StatusICO statusICO = StatusICO.Created;


    function CryptoTicketsICO(address _presale, address _Company, address _BountyFund, address _AdvisorsFund, address _ItdFund, address _StorageFund, address _Manager, address _Controller_Address1, address _Controller_Address2, address _Controller_Address3){
       presale = Presale(_presale);
       Company = _Company;
       BountyFund = _BountyFund;
       AdvisorsFund = _AdvisorsFund;
       ItdFund = _ItdFund;
       StorageFund = _StorageFund;
       Manager = _Manager;
       Controller_Address1 = _Controller_Address1;
       Controller_Address2 = _Controller_Address2;
       Controller_Address3 = _Controller_Address3;
    }

// function for changing rate of ETH and price of token


    function setRate(uint _RateEth) external managerOnly {
       Rate_Eth = _RateEth;
       Token_Price = 25*Rate_Eth;
    }


//ICO status functions

    function startIco() external managerOnly {
       require(statusICO == StatusICO.Created || statusICO == StatusICO.Paused);
       if(statusICO == StatusICO.Created)
       {
         startTime = now;
       }
       LogStartICO();
       statusICO = StatusICO.Started;
    }

    function pauseIco() external managerOnly {
       require(statusICO == StatusICO.Started);
       statusICO = StatusICO.Paused;
       LogPauseICO();
    }


    function finishIco() external managerOnly { // Funds for minting of tokens

       require(statusICO == StatusICO.Started);

       uint alreadyMinted = tkt.totalSupply(); //=PublicICO+PrivateOffer
       uint totalAmount = alreadyMinted * 1000 / icoAndPOfPart;


       tkt.mint(BountyFund, bountyPart * totalAmount / 100); // 2% for Bounty
       tkt.mint(AdvisorsFund, advisorsPart * totalAmount / 1000); // 3.5% for Advisors
       tkt.mint(ItdFund, itdPart * totalAmount / 100); // 15% for Ticketscloud ltd
       tkt.mint(StorageFund, storagePart * totalAmount / 100); // 3% for Storage

       tkt.defrost();

       statusICO = StatusICO.Finished;
       LogFinishICO(BountyFund, AdvisorsFund, ItdFund, StorageFund);
    }

// function that buys tokens when investor sends ETH to address of ICO
    function() external payable {

       buy(msg.sender, msg.value * Token_Price);
    }

// function for buying tokens to investors who paid in other cryptos

    function buyForInvestor(address _investor, uint _tktValue, string _txHash) external controllersOnly {
       buy(_investor, _tktValue);
       LogBuyForInvestor(_investor, _tktValue, _txHash);
    }

//function for buying tokens for presale investors

    function replaceToken(address _investor) managerOnly{
         require(statusICO != StatusICO.Finished);
         uint pctTokens = presale.balanceOf(_investor);
         require(pctTokens > 0);
         presale.burnTokens(_investor);
         tkt.mint(_investor, pctTokens);

         LogReplaceToken(_investor, pctTokens);
    }
// internal function for buying tokens

    function buy(address _investor, uint _tktValue) internal {
       require(statusICO == StatusICO.Started);
       require(_tktValue > 0);


       uint bonus = getBonus(_tktValue);

       uint _total = _tktValue.add(bonus);

       require(SoldNoBonuses + _tktValue <= Tokens_For_Sale);
       tkt.mint(_investor, _total);

       SoldNoBonuses = SoldNoBonuses.add(_tktValue);
    }

// function that calculates bonus
    function getBonus(uint _value) public constant returns (uint) {
       uint bonus = 0;
       uint time = now;
       if(time >= startTime && time <= startTime + 48 hours)
       {

            bonus = _value * 20/100;
        }

       if(time > startTime + 48 hours && time <= startTime + 96 hours)
       {
            bonus = _value * 10/100;
       }

       if(time > startTime + 96 hours && time <= startTime + 168 hours)
       {

            bonus = _value * 5/100;
        }

       return bonus;
    }

//function to withdraw ETH from smart contract

    // SUGGESTION:
    // even if you lose you manager keys -> you still will be able to get ETH
    function withdrawEther(uint256 _value) external managerOnly {
       require(statusICO == StatusICO.Finished);
       Company.transfer(_value);
    }

}

contract TKT  is ERC20 {
    using SafeMath for uint;

    string public name = "CryptoTickets COIN";
    string public symbol = "TKT";
    uint public decimals = 18;

    address public ico;

    event Burn(address indexed from, uint256 value);

    bool public tokensAreFrozen = true;

    modifier icoOnly { require(msg.sender == ico); _; }

    function TKT(address _ico) {
       ico = _ico;
    }


    function mint(address _holder, uint _value) external icoOnly {
       require(_value != 0);
       balances[_holder] = balances[_holder].add(_value);
       totalSupply = totalSupply.add(_value);
       Transfer(0x0, _holder, _value);
    }


    function defrost() external icoOnly {
       tokensAreFrozen = false;
    }

    function burn(uint256 _value) {
       require(!tokensAreFrozen);
       balances[msg.sender] = balances[msg.sender].sub(_value);
       totalSupply = totalSupply.sub(_value);
       Burn(msg.sender, _value);
    }


    function balanceOf(address _owner) constant returns (uint256) {
         return balances[_owner];
    }


    function transfer(address _to, uint256 _amount) returns (bool) {
        require(!tokensAreFrozen);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _amount) returns (bool) {
        require(!tokensAreFrozen);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
     }


    function approve(address _spender, uint256 _amount) returns (bool) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }
}