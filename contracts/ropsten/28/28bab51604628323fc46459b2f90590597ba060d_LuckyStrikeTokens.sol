/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

/**
 * Source Code first verified at https://etherscan.io on Wednesday, April 17, 2019
 (UTC) */

pragma solidity 0.4.20;

/*
Lucky Strike smart contracts version: 6.0.0
last change: 2019-06-13
*/

/*
This smart contract is intended for entertainment purposes only. Cryptocurrency gambling is illegal in many jurisdictions and users should consult their legal counsel regarding the legal status of cryptocurrency gambling in their jurisdictions.
Since developers of this smart contract are unable to determine which jurisdiction you reside in, you must check current laws including your local and state laws to find out if cryptocurrency gambling is legal in your area.
If you reside in a location where cryptocurrency gambling is illegal, please do not interact with this smart contract in any way and leave it  immediately.
*/

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/* "Interfaces" */

//  this is expected from another contracts
//  if it wants to spend tokens of behalf of the token owner in our contract
//  this can be used in many situations, for example to convert pre-ICO tokens to ICO tokens
//  see &#39;approveAndCall&#39; function
contract allowanceRecipient {
    function receiveApproval(address _from, uint256 _value, address _inContract, bytes _extraData) public returns (bool);
}

// see:
// https://github.com/ethereum/EIPs/issues/677
contract tokenRecipient {
    function tokenFallback(address _from, uint256 _value, bytes _extraData) public returns (bool);
}

contract LuckyStrikeTokens {

    // see: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/BasicToken.sol
    using SafeMath for uint256;

    /* --- ERC-20 variables */

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#name
    // function name() constant returns (string name)
    string public name = "LuckyStrikeTokens";

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#symbol
    // function symbol() constant returns (string symbol)
    string public symbol = "LST";

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#decimals
    // function decimals() constant returns (uint8 decimals)
    uint8 public decimals = 0;

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#totalsupply
    // function totalSupply() constant returns (uint256 totalSupply)
    uint256 public totalSupply;

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#balanceof
    // function balanceOf(address _owner) constant returns (uint256 balance)
    mapping(address => uint256) public balanceOf;

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#allowance
    // function allowance(address _owner, address _spender) constant returns (uint256 remaining)
    mapping(address => mapping(address => uint256)) public allowance;

    /* --- ERC-20 events */

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#events

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#transfer-1
    event Transfer(address indexed from, address indexed to, uint256 value);

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#approval
    event Approval(address indexed _owner, address indexed spender, uint256 value);

    /* --- Interaction with other contracts events  */
    event DataSentToAnotherContract(address indexed _from, address indexed _toContract, bytes _extraData);

    address public owner; // main smart contract (with the game)
    address public team; // team address, to collect tokens minted for the team

    uint256 public invested; // here we count received investments in wei
    uint256 public hardCap; // in ETH

    uint256 public tokenSaleStarted; // unix time
    uint256 public salePeriod; // in seconds
    bool public tokenSaleIsRunning = true;

    /* ---------- Constructor */
    // do not forget about:
    // https://medium.com/@codetractio/a-look-into-paritys-multisig-wallet-bug-affecting-100-million-in-ether-and-tokens-356f5ba6e90a
    address admin; //
    function LuckyStrikeTokens() public {
        admin = msg.sender;
    }

    function init(address luckyStrikeContractAddress) public {

        require(msg.sender == admin);
        require(tokenSaleStarted == 0);
        require(luckyStrikeContractAddress != address(0));

        // production TODO: change in production <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        hardCap = 4500 ether;
        salePeriod = 200 days;

        // test:
        //        hardCap = 1 ether;
        //        salePeriod = 360 minutes;
        // TODO: end of change in production <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

        team = 0x0bBAb60c495413c870F8cABF09436BeE9fe3542F;

        balanceOf[0x7E6CdeE9104f0d93fdACd550304bF36542A95bfD] = 33040000;
        balanceOf[0x21F73Fc4557a396233C0786c7b4d0dDAc6237582] = 8260000;
        balanceOf[0x23a91B45A1Cc770E334D81B24352C1C06C4830F6] = 26600000;
        balanceOf[0x961f5a8B214beca13A0fdB0C1DD0F40Df52B8D55] = 2100000;

        totalSupply = 70000000;

        owner = luckyStrikeContractAddress;
        tokenSaleStarted = block.timestamp;
    }

    /* --- Income */
    event IncomePaid(address indexed to, uint256 tokensBurned, uint256 sumInWeiPaid);

    // valueInTokens : tokens to burn to get income
    function takeIncome(uint256 valueInTokens) public returns (bool) {

        require(!tokenSaleIsRunning);
        require(this.balance > 0);
        require(totalSupply > 0);
        require(balanceOf[msg.sender] > 0);
        require(valueInTokens <= balanceOf[msg.sender]);

        // uint256 sumToPay = (this.balance / totalSupply).mul(valueInTokens);
        uint256 sumToPay = (this.balance).mul(valueInTokens).div(totalSupply);

        totalSupply = totalSupply.sub(valueInTokens);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(valueInTokens);

        msg.sender.transfer(sumToPay);

        IncomePaid(msg.sender, valueInTokens, sumToPay);

        return true;
    }

    // only if all tokens are burned
    event WithdrawalByTeam(uint256 value, address indexed to, address indexed triggeredBy);

    function withdrawAllByTeam() public {
        require(msg.sender == team);
        require(totalSupply == 0 && !tokenSaleIsRunning);
        uint256 sumToWithdraw = this.balance;
        team.transfer(sumToWithdraw);
        WithdrawalByTeam(sumToWithdraw, team, msg.sender);
    }

    /* --- ERC-20 Functions */
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#methods

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#transfer
    function transfer(address _to, uint256 _value) public returns (bool){
        return transferFrom(msg.sender, _to, _value);
    }

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#transferfrom
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

        if (_to == address(this)) {
            // only tokens owner can burn tokens and take income
            require(_from == msg.sender);
            return takeIncome(_value);
        }

        require(!tokenSaleIsRunning);

        // Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event (ERC-20)
        require(_value >= 0);

        // The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism
        require(msg.sender == _from || _value <= allowance[_from][msg.sender]);
        require(_to != 0);

        // check if _from account have required amount
        require(_value <= balanceOf[_from]);

        // Subtract from the sender
        // balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_from] = balanceOf[_from].sub(_value);
        //
        // Add the same to the recipient
        // balanceOf[_to] = balanceOf[_to] + _value;
        balanceOf[_to] = balanceOf[_to].add(_value);

        // If allowance used, change allowances correspondingly
        if (_from != msg.sender) {
            // allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        }

        // event
        Transfer(_from, _to, _value);

        return true;
    } // end of transferFrom

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#approve
    // there is and attack, see:
    // https://github.com/CORIONplatform/solidity/issues/6,
    // https://drive.google.com/file/d/0ByMtMw2hul0EN3NCaVFHSFdxRzA/view
    // but this function is required by ERC-20
    function approve(address _spender, uint256 _value) public returns (bool){
        require(_value >= 0);
        allowance[msg.sender][_spender] = _value;
        // event
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*  ---------- Interaction with other contracts  */

    /* User can allow another smart contract to spend some shares in his behalf
    *  (this function should be called by user itself)
    *  @param _spender another contract&#39;s address
    *  @param _value number of tokens
    *  @param _extraData Data that can be sent from user to another contract to be processed
    *  bytes - dynamically-sized byte array,
    *  see http://solidity.readthedocs.io/en/v0.4.15/types.html#dynamically-sized-byte-array
    *  see possible attack information in comments to function &#39;approve&#39;
    *  > this may be used to convert pre-ICO tokens to ICO tokens
    */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {

        approve(_spender, _value);

        // &#39;spender&#39; is another contract that implements code as prescribed in &#39;allowanceRecipient&#39; above
        allowanceRecipient spender = allowanceRecipient(_spender);

        // our contract calls &#39;receiveApproval&#39; function of another contract (&#39;allowanceRecipient&#39;) to send information about
        // allowance and data sent by user
        // &#39;this&#39; is this (our) contract address
        if (spender.receiveApproval(msg.sender, _value, this, _extraData)) {
            DataSentToAnotherContract(msg.sender, _spender, _extraData);
            return true;
        }
        return false;
    } // end of approveAndCall

    // for convenience:
    function approveAllAndCall(address _spender, bytes _extraData) public returns (bool success) {
        return approveAndCall(_spender, balanceOf[msg.sender], _extraData);
    }

    /* https://github.com/ethereum/EIPs/issues/677
    * transfer tokens with additional info to another smart contract, and calls its correspondent function
    * @param address _to - another smart contract address
    * @param uint256 _value - number of tokens
    * @param bytes _extraData - data to send to another contract
    * > this may be used to convert pre-ICO tokens to ICO tokens
    */
    function transferAndCall(address _to, uint256 _value, bytes _extraData) public returns (bool success){

        transferFrom(msg.sender, _to, _value);

        tokenRecipient receiver = tokenRecipient(_to);

        if (receiver.tokenFallback(msg.sender, _value, _extraData)) {
            DataSentToAnotherContract(msg.sender, _to, _extraData);
            return true;
        }
        return false;
    } // end of transferAndCall

    // for example for converting ALL tokens of user account to another tokens
    function transferAllAndCall(address _to, bytes _extraData) public returns (bool success){
        return transferAndCall(_to, balanceOf[msg.sender], _extraData);
    }

    /* ========= MINT TOKENS: */

    event NewTokensMinted(
        address indexed to, //..............1
        uint256 invested, //................2
        uint256 tokensForInvestor, //.......3
        address indexed by, //..............4
        bool indexed tokenSaleFinished, //..5
        uint256 totalInvested //............6
    );

    // value - number of tokens to mint
    function mint(address to, uint256 value, uint256 _invested) public returns (bool) {

        require(msg.sender == owner);

        require(tokenSaleIsRunning);
        require(value >= 0);
        require(_invested >= 0);
        require(to != owner && to != 0);
        //

        balanceOf[to] = balanceOf[to].add(value);
        totalSupply = totalSupply.add(value);
        invested = invested.add(_invested);

        if (invested >= hardCap || now.sub(tokenSaleStarted) > salePeriod) {
            tokenSaleIsRunning = false;
        }

        NewTokensMinted(
            to, //...................1
            _invested, //............2
            value, //................3
            msg.sender, //...........4
            !tokenSaleIsRunning, //..5
            invested //..............6
        );
        return true;
    }

    //    function() public payable {
    //        // require(msg.sender == owner); // no check means we can use standard transfer in main contract
    //    }

    function transferIncome() public payable {
    }

}