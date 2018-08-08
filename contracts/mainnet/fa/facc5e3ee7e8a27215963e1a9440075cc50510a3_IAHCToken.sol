pragma solidity ^0.4.4;

contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && (balances[_to] + _value) > balances[_to] && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to] && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract IAHCToken is StandardToken {

    string public constant name   = "IAHC";
    string public constant symbol = "IAHC";

    uint8 public constant decimals = 8;
    uint  public constant decimals_multiplier = 100000000;

    address public constant ESCROW_WALLET = 0x3D7FaD8174dac0df6a0a3B473b9569f7618d07E2;

    uint public constant icoSupply          = 500000000 * decimals_multiplier; //0,5 billion (500,000,000 IAHC coins will be available for purchase (25% of total IAHC)
    uint public constant icoTokensPrice     = 142000;                          //wei / decimals, base price: 0.0000142 ETH per 1 IAHC
    uint public constant icoMinCap          = 100   ether;
    uint public constant icoMaxCap          = 7000  ether;

    uint public constant whiteListMinAmount = 0.50  ether;
    uint public constant preSaleMinAmount   = 0.25  ether;
    uint public constant crowdSaleMinAmount = 0.10  ether;

    address public icoOwner;
    uint public icoLeftSupply  = icoSupply; //current left tokens to sell during ico
    uint public icoSoldCap     = 0;         //current sold value in wei

    uint public whiteListTime         = 1519084800; //20.02.2018 (40% discount)
    uint public preSaleListTime       = 1521590400; //21.03.2018 (28% discount)
    uint public crowdSaleTime         = 1524355200; //22.04.2018 (10% discount)
    uint public crowdSaleEndTime      = 1526947200; //22.05.2018 (0% discount)
    uint public icoEndTime            = 1529712000; //23.06.2018
    uint public guarenteedPaybackTime = 1532304000; //23.07.2018

    mapping(address => bool) public whiteList;
    mapping(address => uint) public icoContributions;

    function IAHCToken(){
        icoOwner = msg.sender;
        balances[icoOwner] = 2000000000 * decimals_multiplier - icoSupply; //froze ico tokens
        totalSupply = 2000000000 * decimals_multiplier;
    }

    modifier onlyOwner() {
        require(msg.sender == icoOwner);
        _;
    }

    //unfroze tokens if some left unsold from ico
    function icoEndUnfrozeTokens() public onlyOwner() returns(bool) {
        require(now >= icoEndTime && icoLeftSupply > 0);

        balances[icoOwner] += icoLeftSupply;
        icoLeftSupply = 0;
    }

    //if soft cap is not reached - participant can ask ethers back
    function minCapFail() public {
        require(now >= icoEndTime && icoSoldCap < icoMinCap);
        require(icoContributions[msg.sender] > 0 && balances[msg.sender] > 0);

        uint tokens = balances[msg.sender];
        balances[icoOwner] += tokens;
        balances[msg.sender] -= tokens;
        uint contribution = icoContributions[msg.sender];
        icoContributions[msg.sender] = 0;

        Transfer(msg.sender, icoOwner, tokens);

        msg.sender.transfer(contribution);
    }

    // for info
    function getCurrentStageDiscount() public constant returns (uint) {
        uint discount = 0;
        if (now >= icoEndTime && now < preSaleListTime) {
            discount = 40;
        } else if (now < crowdSaleTime) {
            discount = 28;
        } else if (now < crowdSaleEndTime) {
            discount = 10;
        }
        return discount;
    }

    function safePayback(address receiver, uint amount) public onlyOwner() {
        require(now >= guarenteedPaybackTime);
        require(icoSoldCap < icoMinCap);

        receiver.transfer(amount);
    }

    // count tokens i could buy now
    function countTokens(uint paid, address sender) public constant returns (uint) {
        uint discount = 0;
        if (now < preSaleListTime) {
            require(whiteList[sender]);
            require(paid >= whiteListMinAmount);
            discount = 40;
        } else if (now < crowdSaleTime) {
            require(paid >= preSaleMinAmount);
            discount = 28;
        } else if (now < crowdSaleEndTime) {
            require(paid >= crowdSaleMinAmount);
            discount = 10;
        }

        uint tokens = paid / icoTokensPrice;
        if (discount > 0) {
            tokens = tokens / (100 - discount) * 100;
        }
        return tokens;
    }

    // buy tokens if you can
    function () public payable {
        contribute();
    }

    function contribute() public payable {
        require(now >= whiteListTime && now < icoEndTime && icoLeftSupply > 0);

        uint tokens = countTokens(msg.value, msg.sender);
        uint payback = 0;
        if (icoLeftSupply < tokens) {
            //not enough tokens so we need to return some ethers back
            payback = msg.value - (msg.value / tokens) * icoLeftSupply;
            tokens = icoLeftSupply;
        }
        uint contribution = msg.value - payback;

        icoLeftSupply                -= tokens;
        balances[msg.sender]         += tokens;
        icoSoldCap                   += contribution;
        icoContributions[msg.sender] += contribution;

        Transfer(icoOwner, msg.sender, tokens);

        if (icoSoldCap >= icoMinCap) {
            ESCROW_WALLET.transfer(this.balance);
        }
        if (payback > 0) {
            msg.sender.transfer(payback);
        }
    }


    //lists
    function addToWhitelist(address _participant) public onlyOwner() returns(bool) {
        if (whiteList[_participant]) {
            return true;
        }
        whiteList[_participant] = true;
        return true;
    }
    function removeFromWhitelist(address _participant) public onlyOwner() returns(bool) {
        if (!whiteList[_participant]) {
            return true;
        }
        whiteList[_participant] = false;
        return true;
    }

}