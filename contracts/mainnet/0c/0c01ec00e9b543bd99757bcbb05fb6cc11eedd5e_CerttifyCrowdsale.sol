pragma solidity 0.4.21;

contract ERC20Basic {

    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
	
}

contract BasicToken is ERC20Basic {
	
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
	
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract CerttifyToken is StandardToken {

    event Burn(address indexed burner, uint256 value, string message);
    event IssueCert(bytes32 indexed id, address certIssuer, uint256 value, bytes cert);

    string public name = "Certtify Token";
    string public symbol = "CTF";
    uint8 public decimals = 18;

    address public deployer;
    bool public lockup = true;

    function CerttifyToken(uint256 maxSupply) public {
        totalSupply = maxSupply.mul(10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
        deployer = msg.sender;
    }

    modifier afterLockup() {
        require(!lockup || msg.sender == deployer);
        _;
    }

    function unlock() public {
        require(msg.sender == deployer);
        lockup = false;
    }

    function transfer(address _to, uint256 _value) public afterLockup() returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public afterLockup() returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value, string _message) public afterLockup() {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        totalSupply = totalSupply.sub(_value);
        balances[burner] = balances[burner].sub(_value);
        emit Burn(burner, _value, _message);
    }

    function issueCert(uint256 _value, bytes _cert) external afterLockup() {
        if (_value > 0) { 
            burn(_value, "");
        }
        emit IssueCert(keccak256(block.number, msg.sender, _value, _cert), msg.sender, _value, _cert);
    }

}

contract Ownable {
  
    address public owner;

    function Ownable(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}

contract Bounty is Ownable {

    CerttifyToken public token;
    mapping(address => uint256) public bounties;
    bool public withdrawlEnabled = false;

    event BountySet(address indexed beneficiary, uint256 amount);
    event BountyWithdraw(address indexed beneficiary, uint256 amount);

    function Bounty(CerttifyToken _token, address _admin) Ownable(_admin) public {
        token = _token;
    }

    function setBounties(address[] beneficiaries, uint256[] amounts) external onlyOwner {
        require(beneficiaries.length == amounts.length);
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            bounties[beneficiaries[i]] = amounts[i];
            emit BountySet(beneficiaries[i], amounts[i]);
        }
    }

    function enableWithdrawl() external onlyOwner {
        withdrawlEnabled = true;
    }

    function withdrawBounty() public {
        require(withdrawlEnabled);
        require(bounties[msg.sender] > 0);
        uint256 bountyWithdrawn = bounties[msg.sender];
        bounties[msg.sender] = 0;
        emit BountyWithdraw(msg.sender, bountyWithdrawn);
        token.transfer(msg.sender, bountyWithdrawn);
    }

    function () external {
        withdrawBounty();
    }

}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
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

contract CerttifyCrowdsale is Ownable {

    using SafeMath for uint256;

    CerttifyToken public token;
    Bounty public bounty;

    bool public icoSpecConfirmed = false;

    uint256 public startTimeStage1 = 4102444799;
    uint256 public startTimeStage2;
    uint256 public startTimeStage3;
    uint256 public endTime;

    address public wallet;

    uint256 public rateStage1;
    uint256 public rateStage2;
    uint256 public rateStage3;

    uint256 public constant DECIMALS = 18;
    uint256 public constant MAX_SUPPLY = 550000000;
    uint256 public constant MAX_SUPPLY_DECIMAL = 550000000 * (10 ** DECIMALS);
    uint256 public constant MAX_ALLOWED_BOUNTY = 16500000 * (10 ** DECIMALS);
    uint256 public constant MAX_ALLOWED_PRE_SALE = 192500000 * (10 ** DECIMALS);
    uint256 public constant MAX_ALLOWED_STAGE_1 = 82500000 * (10 ** DECIMALS);
    uint256 public constant MAX_ALLOWED_STAGE_2 = 82500000 * (10 ** DECIMALS);
    uint256 public constant MAX_ALLOWED_STAGE_3 = 55000000 * (10 ** DECIMALS);
    uint256 public MAX_ALLOWED_BY_STAGE_1 = MAX_ALLOWED_PRE_SALE.add(MAX_ALLOWED_STAGE_1);
    uint256 public MAX_ALLOWED_BY_STAGE_2 = MAX_ALLOWED_BY_STAGE_1.add(MAX_ALLOWED_STAGE_2);
    uint256 public MAX_ALLOWED_TOTAL =  MAX_ALLOWED_BY_STAGE_2.add(MAX_ALLOWED_STAGE_3);

    uint256 public weiRaised;
    uint256 public tokenSold;

    bool public icoEnded;
    
    uint256 public founderTokenUnlockPhase1;
    uint256 public founderTokenUnlockPhase2;
    uint256 public founderTokenUnlockPhase3;
    uint256 public founderTokenUnlockPhase4;

    bool public founderTokenWithdrawnPhase1;
    uint256 public founderWithdrawablePhase1;
    bool public founderTokenWithdrawnPhase2;
    uint256 public founderWithdrawablePhase2;
    bool public founderTokenWithdrawnPhase3;
    uint256 public founderWithdrawablePhase3;
    bool public founderTokenWithdrawnPhase4;
    uint256 public founderWithdrawablePhase4;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    modifier onlyBeforeSpecConfirmed() {
        require(!icoSpecConfirmed);
        _;
    }

    modifier onlyAfterSpecConfirmed() {
        require(icoSpecConfirmed);
        _;
    }

    function CerttifyCrowdsale(address _wallet, address _owner, address _bountyAdmin) Ownable(_owner) public {
        require(_wallet != address(0));
        require(_owner != address(0));
        require(_bountyAdmin != address(0));
        token = createTokenContract();
        bounty = createBountyContract(_bountyAdmin);
        token.transfer(bounty, MAX_ALLOWED_BOUNTY);
        wallet = _wallet;
    }

    function createTokenContract() internal returns (CerttifyToken) {
        return new CerttifyToken(MAX_SUPPLY);
    }

    function createBountyContract(address admin) internal returns (Bounty) {
        return new Bounty(token, admin);
    }

    function setICOSpec(uint256 _timestampStage1, uint256 _timestampStage2, uint256 _timestampStage3, uint256 _timestampEndTime, uint256 _weiCostOfTokenStage1, uint256 _weiCostOfTokenStage2, uint256 _weiCostOfTokenStage3, uint256 _founderTokenUnlockPhase1, uint256 _founderTokenUnlockPhase2, uint256 _founderTokenUnlockPhase3, uint256 _founderTokenUnlockPhase4) external onlyBeforeSpecConfirmed() onlyOwner {
        require(_timestampStage1 > 0);
        require(_timestampStage2 >= _timestampStage1);
        require(_timestampStage3 >= _timestampStage2);
        require(_timestampEndTime >= _timestampStage3);
        require(_weiCostOfTokenStage1 > 0);
        require(_weiCostOfTokenStage2 >= _weiCostOfTokenStage1);
        require(_weiCostOfTokenStage3 >= _weiCostOfTokenStage2);
        require(_founderTokenUnlockPhase1 > 0);
        require(_founderTokenUnlockPhase2 >= _founderTokenUnlockPhase1);
        require(_founderTokenUnlockPhase3 >= _founderTokenUnlockPhase2);
        require(_founderTokenUnlockPhase4 >= _founderTokenUnlockPhase3);
        startTimeStage1 = _timestampStage1;
        startTimeStage2 = _timestampStage2;
        startTimeStage3 = _timestampStage3;
        endTime = _timestampEndTime;
        rateStage1 = _weiCostOfTokenStage1;
        rateStage2 = _weiCostOfTokenStage2;
        rateStage3 = _weiCostOfTokenStage3;
        founderTokenUnlockPhase1 = _founderTokenUnlockPhase1;
        founderTokenUnlockPhase2 = _founderTokenUnlockPhase2;
        founderTokenUnlockPhase3 = _founderTokenUnlockPhase3;
        founderTokenUnlockPhase4 = _founderTokenUnlockPhase4;
    }

    function confirmICOSpec() external onlyBeforeSpecConfirmed() onlyOwner {
        icoSpecConfirmed = true;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable onlyAfterSpecConfirmed() {
        require(beneficiary != address(0));
        require(validPurchase());
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.div(getCurrentRate()).mul(10 ** uint256(18));
        require(checkCapNotReached(tokens));
        weiRaised = weiRaised.add(weiAmount);
        tokenSold = tokenSold.add(tokens);
        forwardFunds();
        token.transfer(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    function buyTokensPreSale(address beneficiary, uint256 tokens) public onlyOwner {
        require(beneficiary != address(0));
        require(tokens > 0);
        require(tokenSold.add(tokens) <= MAX_ALLOWED_PRE_SALE);
        require(getCurrentStage() == 0);
        tokenSold = tokenSold.add(tokens);
        token.transfer(beneficiary, tokens);
        emit TokenPurchase(beneficiary, beneficiary, 0, tokens);
    }

    function postICO() public onlyAfterSpecConfirmed() onlyOwner {
        require(hasEnded());
        require(!icoEnded);
        uint256 founderWithdrawableTotal = tokenSold.add(MAX_ALLOWED_BOUNTY).mul(22).div(78);
        founderWithdrawablePhase1 = founderWithdrawableTotal.mul(10).div(22);
        founderWithdrawablePhase2 = founderWithdrawableTotal.mul(4).div(22);
        founderWithdrawablePhase3 = founderWithdrawableTotal.mul(4).div(22);
        founderWithdrawablePhase4 = founderWithdrawableTotal.mul(4).div(22);
        icoEnded = true;
        uint256 tokenLeft = MAX_SUPPLY_DECIMAL.sub(tokenSold).sub(MAX_ALLOWED_BOUNTY).sub(founderWithdrawableTotal);
        if (tokenLeft != 0) {
            token.burn(tokenLeft, "ICO_BURN_TOKEN_UNSOLD");
        }
        token.unlock();
    }

    function founderWithdraw() public onlyAfterSpecConfirmed() onlyOwner {
        require(icoEnded);
        require(!founderTokenWithdrawnPhase4);
        if (!founderTokenWithdrawnPhase1) {
            require(now >= founderTokenUnlockPhase1);
            founderTokenWithdrawnPhase1 = true;
            token.transfer(owner, founderWithdrawablePhase1);
        } else if (!founderTokenWithdrawnPhase2) {
            require(now >= founderTokenUnlockPhase2);
            founderTokenWithdrawnPhase2 = true;
            token.transfer(owner, founderWithdrawablePhase2);
        } else if (!founderTokenWithdrawnPhase3) {
            require(now >= founderTokenUnlockPhase3);
            founderTokenWithdrawnPhase3 = true;
            token.transfer(owner, founderWithdrawablePhase3);
        } else {
            require(now >= founderTokenUnlockPhase4);
            founderTokenWithdrawnPhase4 = true;
            token.transfer(owner, founderWithdrawablePhase4);
        }
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTimeStage1 && now < endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    function checkCapNotReached(uint256 tokenBuyReq) internal view returns (bool) {
        return tokenSold.add(tokenBuyReq) <= MAX_ALLOWED_TOTAL;
    }

    function getCurrentStage() internal view returns (uint8) {
        if (now < startTimeStage1) {
            return 0;
        } else if (now >= startTimeStage1 && now < startTimeStage2) {
            return 1;
        } else if (now >= startTimeStage2 && now < startTimeStage3) {
            return 2;
        } else {
            return 3;
        }
    }

    function getCurrentRateByStage() internal view returns (uint256) {
        uint8 currentStage = getCurrentStage();
        if (currentStage == 1) {
            return rateStage1;
        } else if (currentStage == 2) {
            return rateStage2;
        } else {
            return rateStage3;
        }
    }

    function getCurrentRateByTokenSold() internal view returns (uint256) {
        if (tokenSold < MAX_ALLOWED_BY_STAGE_1) {
            return rateStage1;
        } else if (tokenSold < MAX_ALLOWED_BY_STAGE_2) {
            return rateStage2;
        } else {
            return rateStage3;
        }
    }

    function getCurrentRate() internal view returns (uint256) {
        uint256 rateByStage = getCurrentRateByStage();
        uint256 rateByTokenSold = getCurrentRateByTokenSold();
        if (rateByStage > rateByTokenSold) {
            return rateByStage;
        } else {
            return rateByTokenSold;
        }
    }

    function hasEnded() public view returns (bool) {
        return now >= endTime || tokenSold >= MAX_ALLOWED_TOTAL;
    }

}