pragma solidity ^ 0.4.21;

/**
 *   @title SafeMath
 *   @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 *   @title ERC20
 *   @dev Standart ERC20 token interface
 */
contract ERC20 {
    function balanceOf(address _owner) public constant returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    function approve(address _spender, uint256 _value) public returns(bool);
    function allowance(address _owner, address _spender) public constant returns(uint256);
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
 *   @dev LTO token contract
 */
contract TESTTESTToken is ERC20 {
    using SafeMath for uint256;
    string public name = "TESTTEST TOKEN";
    string public symbol = "TTT";
    uint256 public decimals = 18;
    uint256 public totalSupply = 0;
    uint256 public constant MAX_TOKENS = 166000000 * 1e18;
    
    

    // Ico contract address
    address public owner;
    event Burn(address indexed from, uint256 value);

    // Disables token transfers
    bool public tokensAreFrozen = true;

    // Allows execution by the owner only
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    
    
    function TESTTESTToken(address _owner) public {
        owner = _owner;
    }
    

   /**
    *   @dev Mint tokens
    *   @param _investor     address the tokens will be issued to
    *   @param _value        number of tokens
    */
    function mintTokens(address _investor, uint256 _value) external onlyOwner {
        require(_value > 0);
        require(totalSupply.add(_value) <= MAX_TOKENS);
        balances[_investor] = balances[_investor].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(0x0, _investor, _value);
    }

   /**
    *   @dev Enables token transfers
    */
    function defrostTokens() external onlyOwner {
      tokensAreFrozen = false;
    }

   /**
    *   @dev Disables token transfers
    */
    function frostTokens() external onlyOwner {
      tokensAreFrozen = true;
    }

   /**
    *   @dev Burn Tokens
    *   @param _investor     token holder address which the tokens will be burnt
    *   @param _value        number of tokens to burn
    */
    function burnTokens(address _investor, uint256 _value) external onlyOwner {
        require(balances[_investor] > 0);
        totalSupply = totalSupply.sub(_value);
        balances[_investor] = balances[_investor].sub(_value);
        emit Burn(_investor, _value);
    }

   /**
    *   @dev Get balance of investor
    *   @param _owner        investor&#39;s address
    *   @return              balance of investor
    */
    function balanceOf(address _owner) public constant returns(uint256) {
      return balances[_owner];
    }

   /**
    *   @return true if the transfer was successful
    */
    function transfer(address _to, uint256 _amount) public returns(bool) {
        require(!tokensAreFrozen);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

   /**
    *   @return true if the transfer was successful
    */
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool) {
        require(!tokensAreFrozen);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

   /**
    *   @dev Allows another account/contract to spend some tokens on its behalf
    *   throws on any error rather then return a false flag to minimize user errors
    *
    *   also, to minimize the risk of the approve/transferFrom attack vector
    *   approve has to be called twice in 2 separate transactions - once to
    *   change the allowance to 0 and secondly to change it to the new allowance
    *   value
    *
    *   @param _spender      approved address
    *   @param _amount       allowance amount
    *
    *   @return true if the approval was successful
    */
    function approve(address _spender, uint256 _amount) public returns(bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

   /**
    *   @dev Function to check the amount of tokens that an owner allowed to a spender.
    *
    *   @param _owner        the address which owns the funds
    *   @param _spender      the address which will spend the funds
    *
    *   @return              the amount of tokens still avaible for the spender
    */
    function allowance(address _owner, address _spender) public constant returns(uint256) {
        return allowed[_owner][_spender];
    }
}


contract TESTTESTICO {
    TESTTESTToken public LTO = new TESTTESTToken(this);
    using SafeMath for uint256;

    // Token price parameters
    uint256 public Rate_Eth = 700; // Rate USD per ETH
    uint256 public Tokens_Per_Dollar = 50; // Lto token per dollar
    uint256 public Token_Price = Tokens_Per_Dollar.mul(Rate_Eth); // Lto token per ETH

    uint256 constant bountyPart = 20; // 2% of TotalSupply for BountyFund
    uint256 constant teamPart = 30; //3% of TotalSupply for TeamFund
    uint256 constant companyPart = 120; //12% of TotalSupply for company
    uint256 constant MAX_PREICO_TOKENS = 27556000 * 1e18;
    uint256 constant TOKENS_FOR_SALE = 137780000 * 1e18;  // 83% of maximum 166M tokens fo sale
    uint256 constant SOFT_CAP = 36300000 * 1e18; // 726 000$ in ICO
    uint256 constant HARD_CAP = 93690400 * 1e18; // ~1 900 000$ in ICO   (1 873 808)
    uint256 public soldTotal;  // total sold without bonus
    bool public isItIco = false;
    bool public canIBuy = false;
    bool public canIWithdraw = false;


    address public BountyFund;
    address public TeamFund;
    address public Company;
    address public Manager; // Manager controls contract
    StatusICO statusICO;


    // Possible ICO statuses
    enum StatusICO {
        Created,
        PreIcoStage1,
        PreIcoStage2,
        PreIcoStage3,
        PreIcoFinished,
        IcoStage1,
        IcoStage2,
        IcoStage3,
        IcoStage4,
        IcoStage5,
        IcoFinished
    }
    
    




    // Mapping
    mapping(address => uint256) public preInvestments; // Mapping for remembering investors eth in preICO
    mapping(address => uint256) public icoInvestments; // Mapping for remembering investors eth in ICO
    mapping(address => bool) public returnStatusPre; // Users can return their funds one time in PreICO and ICO
    mapping(address => bool) public returnStatusIco; // Users can return their funds one time in PreICO and ICO
    mapping(address => uint256) public tokensPreIco; // Mapping for remembering tokens of investors who paid at preICO in ether
    mapping(address => uint256) public tokensIco; // Mapping for remembering tokens of investors who paid at ICO in ether
    mapping(address => uint256) public tokensPreIcoInOtherCrypto; // Mapping for remembering tokens of investors who paid at preICO in other crypto
    mapping(address => uint256) public tokensIcoInOtherCrypto; // Mapping for remembering tokens of investors who paid at ICO in other crypto
    mapping(address => uint256) public tokensNoBonusSold;

    // Events Log
    event LogStartPreIcoStage(uint stageNum);
    event LogFinishPreICO();
    event LogStartIcoStage(uint stageNum);
    event LogFinishICO(address bountyFund, address Company, address teamFund);
    event LogBuyForInvestor(address investor, uint256 value);
    event LogReturnEth(address investor, uint256 eth);
    event LogReturnOtherCrypto(address investor);

    // Modifier
    // Allows execution by the contract manager only
    modifier managerOnly {
        require(msg.sender == Manager);
        _;
    }



   /**
    *   @dev Contract constructor function
    */
    function TESTTESTICO(
        address _BountyFund,
        address _TeamFund,
        address _Company,
        address _Manager
    )
        public {
        BountyFund = _BountyFund;
        TeamFund = _TeamFund;
        Company = _Company;
        Manager = _Manager;
        statusICO = StatusICO.Created;
        
    }
    
    function currentStage() public view returns (string) {
        if(statusICO == StatusICO.Created){return "Created";}
        else if(statusICO == StatusICO.PreIcoStage1){return  "PreIcoStage1";}
        else if(statusICO == StatusICO.PreIcoStage2){return "PreIcoStage2";}
        else if(statusICO == StatusICO.PreIcoStage3){return "PreIcoStage3";}
        else if(statusICO == StatusICO.PreIcoFinished){return "PreIcoFinished";}
        else if(statusICO == StatusICO.IcoStage1){return "IcoStage1";}
        else if(statusICO == StatusICO.IcoStage2){return "IcoStage2";}
        else if(statusICO == StatusICO.IcoStage1){return "IcoStage3";}
        else if(statusICO == StatusICO.IcoStage1){return "IcoStage4";}
        else if(statusICO == StatusICO.IcoStage1){return "IcoStage5";}
        else if(statusICO == StatusICO.IcoStage1){return "IcoFinished";}
    }

   /**
    *   @dev Set rate of ETH and update token price
    *   @param _RateEth       current ETH rate
    */
    function setRate(uint256 _RateEth) external managerOnly {
        Rate_Eth = _RateEth;
        Token_Price = Tokens_Per_Dollar.mul(Rate_Eth);
    }

   /**
    *   
    *   Set PreICO status
    */
    function setPreIcoStatus(uint _numb) external managerOnly {
        require(statusICO == StatusICO.Created 
        || statusICO == StatusICO.PreIcoStage1 
        || statusICO == StatusICO.PreIcoStage2); 
        require(_numb == 1 ||  _numb == 2 || _numb == 3);
        StatusICO stat = StatusICO.PreIcoStage1;
        if(_numb == 2){stat = StatusICO.PreIcoStage2;}
        else if(_numb == 3){stat = StatusICO.PreIcoStage3;}
        
        statusICO = stat;
        canIBuy = true;
        canIWithdraw = true;
        emit LogStartPreIcoStage(_numb);
    }
    
    /**
    *   @dev Finish PreIco
    *   Set Ico status to PreIcoFinished
    */
    function finishPreIco() external managerOnly {
        require(statusICO == StatusICO.PreIcoStage3);
        statusICO = StatusICO.PreIcoFinished;
        isItIco = true;
        canIBuy = false;
        canIWithdraw = false;
        emit LogFinishPreICO();
    }

 
 

   /**
    *   @dev Start ICO
    *   Set ICO status
    */
    
    function setIcoStatus(uint _numb) external managerOnly {
        require(statusICO == StatusICO.PreIcoFinished 
        || statusICO == StatusICO.IcoStage1 
        || statusICO == StatusICO.IcoStage2 
        || statusICO == StatusICO.IcoStage3 
        || statusICO == StatusICO.IcoStage4);
        require(_numb == 1 ||  _numb == 2 || _numb == 3 || _numb == 4 || _numb == 5);
        StatusICO stat = StatusICO.IcoStage1;
        if(_numb == 2){stat = StatusICO.IcoStage2;}
        else if(_numb == 3){stat = StatusICO.IcoStage3;}
        else if(_numb == 4){stat = StatusICO.IcoStage4;}
        else if(_numb == 5){stat = StatusICO.IcoStage5;}
        
        statusICO = stat;
        canIBuy = true;
        canIWithdraw = true;
        emit LogStartIcoStage(_numb);
    }




   /**
    *   @dev Finish ICO and emit tokens for bounty company and team
    */
    function finishIco() external managerOnly {
        require(statusICO == StatusICO.IcoStage5);
        uint256 totalAmount = LTO.totalSupply();
        LTO.mintTokens(BountyFund, bountyPart.mul(totalAmount).div(1000));
        LTO.mintTokens(TeamFund, teamPart.mul(totalAmount).div(1000));
        LTO.mintTokens(Company, companyPart.mul(totalAmount).div(1000));
        statusICO = StatusICO.IcoFinished;
        canIBuy = false;
        if(soldTotal >= SOFT_CAP){canIWithdraw = false;}
        emit LogFinishICO(BountyFund, Company, TeamFund);
    }


   /**
    *   @dev Unfreeze tokens(enable token transfers)
    */
    function enableTokensTransfer() external managerOnly {
        LTO.defrostTokens();
    }

    /**
    *   @dev Freeze tokens(disable token transfers)
    */
    function disableTokensTransfer() external managerOnly {
        require(statusICO != StatusICO.IcoFinished);
        LTO.frostTokens();
    }

   /**
    *   @dev Fallback function calls function to create tokens
    *        when investor sends ETH to address of ICO contract
    */
    function() external payable {
        require(canIBuy);
        require(msg.value > 0);
        createTokens(msg.sender, msg.value.mul(Token_Price), msg.value);
    }
    
    
    function buyToken() external payable {
        require(canIBuy);
        require(msg.value > 0);
        createTokens(msg.sender, msg.value.mul(Token_Price), msg.value);
    }




    function buyForInvestor(address _investor, uint256 _value) external managerOnly {
        require(_value > 0);
        require(canIBuy);
        uint256 decvalue = _value.mul(1 ether);
        uint256 bonus = getBonus(decvalue);
        uint256 total = decvalue.add(bonus);
        if(!isItIco){
            require(LTO.totalSupply().add(total) <= MAX_PREICO_TOKENS);
            tokensPreIcoInOtherCrypto[_investor] = tokensPreIcoInOtherCrypto[_investor].add(total);}
        else {
            require(LTO.totalSupply().add(total) <= TOKENS_FOR_SALE);
            require(soldTotal.add(decvalue) <= HARD_CAP);
            tokensIcoInOtherCrypto[_investor] = tokensIcoInOtherCrypto[_investor].add(total);
            soldTotal = soldTotal.add(decvalue);}
        LTO.mintTokens(_investor, total);
        tokensNoBonusSold[_investor] = tokensNoBonusSold[_investor].add(decvalue);

        emit LogBuyForInvestor(_investor, _value);
    }
    


    function createTokens(address _investor, uint256 _value, uint256 _ethValue) internal {
        require(_value > 0);
        uint256 bonus = getBonus(_value);
        uint256 total = _value.add(bonus);
        if(!isItIco){
            require(LTO.totalSupply().add(total) <= MAX_PREICO_TOKENS);
            tokensPreIco[_investor] = tokensPreIco[_investor].add(total);
            preInvestments[_investor] = preInvestments[_investor].add(_ethValue);}
        else {
            require(LTO.totalSupply().add(total) <= TOKENS_FOR_SALE);
            require(soldTotal.add(_value) <= HARD_CAP);
            tokensIco[_investor] = tokensIco[_investor].add(total);
            icoInvestments[_investor] = icoInvestments[_investor].add(_ethValue);
            soldTotal = soldTotal.add(_value);}
        LTO.mintTokens(_investor, total);
        tokensNoBonusSold[_investor] = tokensNoBonusSold[_investor].add(_value);
    }
 


   /**
    *   @dev Calculates bonus 
    *   @param _value        amount of tokens
    *   @return              bonus value
    */
    function getBonus(uint256 _value) public view returns(uint256) {
        uint256 bonus = 0;
        if (statusICO == StatusICO.PreIcoStage1) {
            bonus = _value.mul(300).div(1000);                    
        } else if (statusICO == StatusICO.PreIcoStage2) {
            bonus = _value.mul(250).div(1000);
        } else if (statusICO == StatusICO.PreIcoStage3) {
            bonus = _value.mul(200).div(1000);
        } else if (statusICO == StatusICO.IcoStage1) {
            bonus = _value.mul(150).div(1000);
        } else if (statusICO == StatusICO.IcoStage2) {
            bonus = _value.mul(100).div(1000);
        } else if (statusICO == StatusICO.IcoStage3) {
            bonus = _value.mul(60).div(1000);
        } else if (statusICO == StatusICO.IcoStage4) {
            bonus = _value.mul(30).div(1000);
        } 
        return bonus;
    }



   /**
    *   @dev Allows investors to return their investments
    */
    function returnEther() public {
        uint256 eth = 0;
        uint256 tokens = 0;
        require(canIWithdraw);
        if (!isItIco) {
            require(!returnStatusPre[msg.sender]);
            require(preInvestments[msg.sender] > 0);
            eth = preInvestments[msg.sender];
            tokens = tokensPreIco[msg.sender];
            preInvestments[msg.sender] = 0;
            tokensPreIco[msg.sender] = 0;
            returnStatusPre[msg.sender] = true;
        }
        else {
            require(!returnStatusIco[msg.sender]);
            require(icoInvestments[msg.sender] > 0);
            eth = icoInvestments[msg.sender];
            tokens = tokensIco[msg.sender];
            icoInvestments[msg.sender] = 0;
            tokensIco[msg.sender] = 0;
            returnStatusIco[msg.sender] = true;
            soldTotal = soldTotal.sub(tokensNoBonusSold[msg.sender]);}
        LTO.burnTokens(msg.sender, tokens);
        msg.sender.transfer(eth);
        emit LogReturnEth(msg.sender, eth);
    }

   /**
    *   @dev Burn tokens who paid in other cryptocurrencies
    */
    function returnOtherCrypto(address _investor)external managerOnly {
        uint256 tokens = 0;
        require(canIWithdraw);
        if (!isItIco) {
            require(!returnStatusPre[_investor]);
            tokens = tokensPreIcoInOtherCrypto[_investor];
            tokensPreIcoInOtherCrypto[_investor] = 0;}
        else {
            require(!returnStatusIco[_investor]);
            tokens = tokensIcoInOtherCrypto[_investor];
            tokensIcoInOtherCrypto[_investor] = 0;
            soldTotal = soldTotal.sub(tokensNoBonusSold[_investor]);}
        LTO.burnTokens(_investor, tokens);
        emit LogReturnOtherCrypto(_investor);
    }

   /**
    *   @dev Allows Company withdraw investments
    */
    function takeInvestments() external managerOnly {
        require(statusICO == StatusICO.PreIcoFinished || statusICO == StatusICO.IcoFinished);
        if(statusICO == StatusICO.PreIcoFinished){
            uint256 totalb = address(this).balance;
            uint256 fivePercent = (totalb.mul(50)).div(1000);
            TeamFund.transfer(fivePercent);
            Company.transfer(totalb.sub(fivePercent));
        } else {
            Company.transfer(address(this).balance);
            LTO.defrostTokens();
        }
        
    }

}

// woopchain.com