pragma solidity ^0.4.19;

/**
 * @title ERC20 Basic smart contract
 * @author Copyright (c) 2016 Smart Contract Solutions, Inc.
 * @author "Manuel Araoz <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6c010d021909000d1e0d03162c0b010d0500420f0301">[email&#160;protected]</a>>"
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 * @dev license: "MIT", source: https://github.com/OpenZeppelin/zeppelin-solidity
 * @author modification: Dmitriy Khizhinskiy @McFly.aero
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title LengthValidator smart contract - fix ERC20 short address attack
 * @author Copyright (c) 2018 McFly.aero
 * @author Dmitriy Khizhinskiy
 * @author "MIT"
 */
contract LengthValidator {
    modifier valid_short(uint _cntArgs) {
        assert(msg.data.length == (_cntArgs * 32 + 4));
        _;
    }
}

/**
 * @title Ownable smart contract
 * @author Copyright (c) 2016 Smart Contract Solutions, Inc.
 * @author "Manuel Araoz <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3d505c534858515c4f5c52477d5a505c5451135e5250">[email&#160;protected]</a>>"
 * @dev license: "MIT", source: https://github.com/OpenZeppelin/zeppelin-solidity
 * @author modification: Dmitriy Khizhinskiy @McFly.aero
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public candidate;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to _request_ transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function requestOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        candidate = newOwner;
    }


    /**
    * @dev Allows the _NEW_ candidate to complete transfer control of the contract to him.
    */
    function confirmOwnership() public {
        require(candidate == msg.sender);
        owner = candidate;
        OwnershipTransferred(owner, candidate);        
    }
}


/**
 * @title MultiOwners smart contract
 * @author Copyright (c) 2018 McFly.aero
 * @author Dmitriy Khizhinskiy
 * @author "MIT"
 */
contract MultiOwners {

    event AccessGrant(address indexed owner);
    event AccessRevoke(address indexed owner);
    
    mapping(address => bool) owners;
    address public publisher;


    function MultiOwners() public {
        owners[msg.sender] = true;
        publisher = msg.sender;
    }


    modifier onlyOwner() { 
        require(owners[msg.sender] == true);
        _; 
    }


    function isOwner() constant public returns (bool) {
        return owners[msg.sender] ? true : false;
    }


    function checkOwner(address maybe_owner) constant public returns (bool) {
        return owners[maybe_owner] ? true : false;
    }


    function grant(address _owner) onlyOwner public {
        owners[_owner] = true;
        AccessGrant(_owner);
    }


    function revoke(address _owner) onlyOwner public {
        require(_owner != publisher);
        require(msg.sender != _owner);

        owners[_owner] = false;
        AccessRevoke(_owner);
    }
}




/**
 * @title SafeMath
 * @author Copyright (c) 2016 Smart Contract Solutions, Inc.
 * @author "Manuel Araoz <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d3beb2bda6b6bfb2a1b2bca993b4beb2babffdb0bcbe">[email&#160;protected]</a>>"
 * @dev license: "MIT", source: https://github.com/OpenZeppelin/zeppelin-solidity
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }


    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }


    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }


    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}











/**
 * @title BasicToken smart contract
 * @author Copyright (c) 2016 Smart Contract Solutions, Inc.
 * @author "Manuel Araoz <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="513c303f24343d3023303e2b11363c30383d7f323e3c">[email&#160;protected]</a>>"
 * @dev license: "MIT", source: https://github.com/OpenZeppelin/zeppelin-solidity
 * @author modification: Dmitriy Khizhinskiy @McFly.aero
 */






/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, LengthValidator {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }


    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) valid_short(2) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }


    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}


/**
 * @title ERC20 smart contract
 * @author Copyright (c) 2016 Smart Contract Solutions, Inc.
 * @author "Manuel Araoz <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b2dfd3dcc7d7ded3c0d3ddc8f2d5dfd3dbde9cd1dddf">[email&#160;protected]</a>>"
 * @dev license: "MIT", source: https://github.com/OpenZeppelin/zeppelin-solidity
 * @author modification: Dmitriy Khizhinskiy @McFly.aero
 */




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 * @author Copyright (c) 2016 Smart Contract Solutions, Inc.
 * @author "Manuel Araoz <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="771a161902121b160516180d37101a161e1b5914181a">[email&#160;protected]</a>>"
 * @dev license: "MIT", source: https://github.com/OpenZeppelin/zeppelin-solidity
 * @author modification: Dmitriy Khizhinskiy @McFly.aero
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;
  
    /** 
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) valid_short(3) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }


    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) valid_short(2) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}


/**
 * @title Mintable token smart contract
 * @author Copyright (c) 2016 Smart Contract Solutions, Inc.
 * @author "Manuel Araoz <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ed808c839888818c9f8c8297ad8a808c8481c38e8280">[email&#160;protected]</a>>"
 * @dev license: "MIT", source: https://github.com/OpenZeppelin/zeppelin-solidity
 * @author modification: Dmitriy Khizhinskiy @McFly.aero
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }


    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner canMint valid_short(2) public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }


    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}


/**
 * @title McFly token smart contract
 * @author Copyright (c) 2018 McFly.aero
 * @author Dmitriy Khizhinskiy
 * @author "MIT"
 */
contract McFlyToken is MintableToken {
    string public constant name = "McFlyToken";
    string public constant symbol = "McFly";
    uint8 public constant decimals = 18;

    /// @dev mapping for whitelist
    mapping(address=>bool) whitelist;

    /// @dev event throw when allowed to transfer address added to whitelist
    /// @param from address
    event AllowTransfer(address from);

    /// @dev check for allowence of transfer
    modifier canTransfer() {
        require(mintingFinished || whitelist[msg.sender]);
        _;        
    }

    /// @dev add address to whitelist
    /// @param from address to add
    function allowTransfer(address from) onlyOwner public {
        whitelist[from] = true;
        AllowTransfer(from);
    }

    /// @dev Do the transfer from address to address value
    /// @param from address from
    /// @param to address to
    /// @param value uint256
    function transferFrom(address from, address to, uint256 value) canTransfer public returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /// @dev Do the transfer from token address to "to" address value
    /// @param to address to
    /// @param value uint256 value
    function transfer(address to, uint256 value) canTransfer public returns (bool) {
        return super.transfer(to, value);
    }
}







/**
 * @title Haltable smart contract - controls owner access
 * @author Copyright (c) 2018 McFly.aero
 * @author Dmitriy Khizhinskiy
 * @author "MIT"
 */
contract Haltable is MultiOwners {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }


    modifier onlyInEmergency {
        require(halted);
        _;
    }


    /// @dev called by the owner on emergency, triggers stopped state
    function halt() external onlyOwner {
        halted = true;
    }


    /// @dev called by the owner on end of emergency, returns to normal state
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}



/**
 * @title McFly crowdsale smart contract
 * @author Copyright (c) 2018 McFly.aero
 * @author Dmitriy Khizhinskiy
 * @author "MIT"
 * @dev inherited from MultiOwners & Haltable
 */
contract McFlyCrowd is MultiOwners, Haltable {
    using SafeMath for uint256;

    /// @dev Total ETH received during WAVES, TLP1.2 & window[1-5]
    uint256 public counter_in; // tlp2
    
    /// @dev minimum ETH to partisipate in window 1-5
    uint256 public minETHin = 1e18; // 1 ETH

    /// @dev Token
    McFlyToken public token;

    /// @dev Withdraw wallet
    address public wallet;

    /// @dev start and end timestamp for TLP 1.2, other values callculated
    uint256 public sT2; // startTimeTLP2
    uint256 constant dTLP2 = 118 days; // days of TLP2
    uint256 constant dBt = 60 days; // days between Windows
    uint256 constant dW = 12 days; // 12 days for 3,4,5,6,7 windows;

    /// @dev Cap maximum possible tokens for minting
    uint256 public constant hardCapInTokens = 1800e24; // 1,800,000,000 MFL

    /// @dev maximum possible tokens for sell 
    uint256 public constant mintCapInTokens = 1260e24; // 1,260,000,000 MFL

    /// @dev tokens crowd within TLP2
    uint256 public crowdTokensTLP2;

    /// @dev tokens crowd before this contract (MFL tokens)
    uint256 preMcFlyTotalSupply;

    /// @dev maximum possible tokens for fund minting
    uint256 constant fundTokens = 270e24; // 270,000,000 MFL
    uint256 public fundTotalSupply;
    address public fundMintingAgent;
                                                          
    /// @dev maximum possible tokens to convert from WAVES
    uint256 wavesTokens = 100e24; // 100,000,000 MFL
    address public wavesAgent;
    address public wavesGW;

    /// @dev Vesting param for team, advisory, reserve.
    uint256 VestingPeriodInSeconds = 30 days; // 24 month
    uint256 VestingPeriodsCount = 24;

    /// @dev Team 10%
    uint256 _teamTokens;
    uint256 public teamTotalSupply;
    address public teamWallet;

    /// @dev Bounty 5% (2% + 3%)
    /// @dev Bounty online 2%
    uint256 _bountyOnlineTokens;
    address public bountyOnlineWallet;
    address public bountyOnlineGW;

    /// @dev Bounty offline 3%
    uint256 _bountyOfflineTokens;
    address public bountyOfflineWallet;

    /// @dev Advisory 5%
    uint256 _advisoryTokens;
    uint256 public advisoryTotalSupply;
    address public advisoryWallet;

    /// @dev Reserved for future 9%
    uint256 _reservedTokens;
    uint256 public reservedTotalSupply;
    address public reservedWallet;

    /// @dev AirDrop 1%
    uint256 _airdropTokens;
    address public airdropWallet;
    address public airdropGW;

    /// @dev PreMcFly wallet (MFL)
    uint256 _preMcFlyTokens;
    address public preMcFlyWallet;

    /// @dev Ppl structure for Win1-5
    struct Ppl {
        address addr;
        uint256 amount;
    }
    mapping (uint32 => Ppl) public ppls;

    /// @dev Window structure for Win1-5
    struct Window {
        bool active;
        uint256 totalEthInWindow;
        uint32 totalTransCnt;
        uint32 refundIndex;
        uint256 tokenPerWindow;
    } 
    mapping (uint8 => Window) public ww;


    /// @dev Events
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenPurchaseInWindow(address indexed beneficiary, uint256 value, uint8 winnum, uint32 totalcnt, uint256 totaleth1);
    event TransferOddEther(address indexed beneficiary, uint256 value);
    event FundMinting(address indexed beneficiary, uint256 value);
    event WithdrawVesting(address indexed beneficiary, uint256 period, uint256 value, uint256 valueTotal);
    event TokenWithdrawAtWindow(address indexed beneficiary, uint256 value);
    event SetFundMintingAgent(address newAgent);
    event SetTeamWallet(address newTeamWallet);
    event SetAdvisoryWallet(address newAdvisoryWallet);
    event SetReservedWallet(address newReservedWallet);
    event SetStartTimeTLP2(uint256 newStartTimeTLP2);
    event SetMinETHincome(uint256 newMinETHin);
    event NewWindow(uint8 winNum, uint256 amountTokensPerWin);
    event TokenETH(uint256 totalEth, uint32 totalCnt);


    /// @dev check for Non zero value
    modifier validPurchase() {
        bool nonZeroPurchase = msg.value != 0;
        require(nonZeroPurchase);
        _;        
    }

    // comment this functions after test passed !!
    /*function getPpls(uint32 index) constant public returns (uint256) {
        return (ppls[index].amount);
    }
    function getPplsAddr(uint32 index) constant public returns (address) {
        return (ppls[index].addr);
    }
    function getWtotalEth(uint8 winNum) constant public returns (uint256) {
        return (ww[winNum].totalEthInWindow);
    }
    function getWtoken(uint8 winNum) constant public returns (uint256) {
        return (ww[winNum].tokenPerWindow);
    }
    function getWactive(uint8 winNum) constant public returns (bool) {
        return (ww[winNum].active);
    }
    function getWtotalTransCnt(uint8 winNum) constant public returns (uint32) {
        return (ww[winNum].totalTransCnt);
    }
    function getWrefundIndex(uint8 winNum) constant public returns (uint32) {
        return (ww[winNum].refundIndex);
    }*/
    // END comment this functions after test passed !!


    /**
     * @dev conctructor of contract, set main params, create new token, do minting for some wallets
     * @param _startTimeTLP2 - set date time of starting of TLP2 (main date!)
     * @param _preMcFlyTotalSupply - set amount in wei total supply of previouse contract (MFL)
     * @param _wallet - wallet for transfer ETH to it
     * @param _wavesAgent - wallet for WAVES gw
     * @param _wavesGW    - wallet for WAVES gw
     * @param _fundMintingAgent - wallet who allowed to mint before TLP2
     * @param _teamWallet - wallet for team vesting
     * @param _bountyOnlineWallet - wallet for online bounty
     * @param _bountyOnlineGW - wallet for online bounty GW
     * @param _bountyOfflineWallet - wallet for offline bounty
     * @param _advisoryWallet - wallet for advisory vesting
     * @param _reservedWallet - wallet for reserved vesting
     * @param _airdropWallet - wallet for airdrop
     * @param _airdropGW - wallet for airdrop GW
     * @param _preMcFlyWallet - wallet for transfer old MFL->McFly (once)
     */
    function McFlyCrowd(
        uint256 _startTimeTLP2,
        uint256 _preMcFlyTotalSupply,
        address _wallet,
        address _wavesAgent,
        address _wavesGW,
        address _fundMintingAgent,
        address _teamWallet,
        address _bountyOnlineWallet,
        address _bountyOnlineGW,
        address _bountyOfflineWallet,
        address _advisoryWallet,
        address _reservedWallet,
        address _airdropWallet,
        address _airdropGW,
        address _preMcFlyWallet
    ) public 
    {   
        require(_startTimeTLP2 >= block.timestamp);
        require(_preMcFlyTotalSupply > 0);
        require(_wallet != 0x0);
        require(_wavesAgent != 0x0);
        require(_wavesGW != 0x0);
        require(_fundMintingAgent != 0x0);
        require(_teamWallet != 0x0);
        require(_bountyOnlineWallet != 0x0);
        require(_bountyOnlineGW != 0x0);
        require(_bountyOfflineWallet != 0x0);
        require(_advisoryWallet != 0x0);
        require(_reservedWallet != 0x0);
        require(_airdropWallet != 0x0);
        require(_airdropGW != 0x0);
        require(_preMcFlyWallet != 0x0);

        token = new McFlyToken();

        wallet = _wallet;

        sT2 = _startTimeTLP2;
        setStartEndTimeTLP(_startTimeTLP2);

        wavesAgent = _wavesAgent;
        wavesGW = _wavesGW;

        fundMintingAgent = _fundMintingAgent;

        teamWallet = _teamWallet;
        bountyOnlineWallet = _bountyOnlineWallet;
        bountyOnlineGW = _bountyOnlineGW;
        bountyOfflineWallet = _bountyOfflineWallet;
        advisoryWallet = _advisoryWallet;
        reservedWallet = _reservedWallet;
        airdropWallet = _airdropWallet;
        airdropGW = _airdropGW;
        preMcFlyWallet = _preMcFlyWallet;

        /// @dev Mint all tokens and than control it by vesting
        _preMcFlyTokens = _preMcFlyTotalSupply; // McFly for thansfer to old MFL owners
        token.mint(preMcFlyWallet, _preMcFlyTokens);
        token.allowTransfer(preMcFlyWallet);
        crowdTokensTLP2 = crowdTokensTLP2.add(_preMcFlyTokens);

        token.mint(wavesAgent, wavesTokens); // 100,000,000 MFL
        token.allowTransfer(wavesAgent);
        token.allowTransfer(wavesGW);
        crowdTokensTLP2 = crowdTokensTLP2.add(wavesTokens);

        _teamTokens = 180e24; // 180,000,000 MFL
        token.mint(this, _teamTokens); // mint to contract address

        _bountyOnlineTokens = 36e24; // 36,000,000 MFL
        token.mint(bountyOnlineWallet, _bountyOnlineTokens);
        token.allowTransfer(bountyOnlineWallet);
        token.allowTransfer(bountyOnlineGW);

        _bountyOfflineTokens = 54e24; // 54,000,000 MFL
        token.mint(bountyOfflineWallet, _bountyOfflineTokens);
        token.allowTransfer(bountyOfflineWallet);

        _advisoryTokens = 90e24; // 90,000,000 MFL
        token.mint(this, _advisoryTokens);

        _reservedTokens = 162e24; // 162,000,000 MFL
        token.mint(this, _reservedTokens);

        _airdropTokens = 18e24; // 18,000,000 MFL
        token.mint(airdropWallet, _airdropTokens);
        token.allowTransfer(airdropWallet);
        token.allowTransfer(airdropGW);
    }


    /**
     * @dev check is TLP2 is active?
     * @return false if crowd TLP2 event was ended
     */
    function withinPeriod() constant public returns (bool) {
        bool withinPeriodTLP2 = (now >= sT2 && now <= (sT2+dTLP2));
        return withinPeriodTLP2;
    }


    /**
     * @dev check is TLP2 is active and minting Not finished
     * @return false if crowd event was ended
     */
    function running() constant public returns (bool) {
        return withinPeriod() && !token.mintingFinished();
    }


    /**
     * @dev check current stage name
     * @return uint8 stage number
     */
    function stageName() constant public returns (uint8) {
        uint256 eT2 = sT2+dTLP2;

        if (now < sT2) {return 101;} // not started
        if (now >= sT2 && now <= eT2) {return (102);} // TLP1.2

        if (now > eT2 && now < eT2+dBt) {return (103);} // preTLP1.3
        if (now >= (eT2+dBt) && now <= (eT2+dBt+dW)) {return (0);} // TLP1.3
        if (now > (eT2+dBt+dW) && now < (eT2+dBt+dW+dBt)) {return (104);} // preTLP1.4
        if (now >= (eT2+dBt+dW+dBt) && now <= (eT2+dBt+dW+dBt+dW)) {return (1);} // TLP1.4
        if (now > (eT2+dBt+dW+dBt+dW) && now < (eT2+dBt+dW+dBt+dW+dBt)) {return (105);} // preTLP1.5
        if (now >= (eT2+dBt+dW+dBt+dW+dBt) && now <= (eT2+dBt+dW+dBt+dW+dBt+dW)) {return (2);} // TLP1.5
        if (now > (eT2+dBt+dW+dBt+dW+dBt+dW) && now < (eT2+dBt+dW+dBt+dW+dBt+dW+dBt)) {return (106);} // preTLP1.6
        if (now >= (eT2+dBt+dW+dBt+dW+dBt+dW+dBt) && now <= (eT2+dBt+dW+dBt+dW+dBt+dW+dBt+dW)) {return (3);} // TLP1.6
        if (now > (eT2+dBt+dW+dBt+dW+dBt+dW+dBt+dW) && now < (eT2+dBt+dW+dBt+dW+dBt+dW+dBt+dW+dBt)) {return (107);} // preTLP1.7
        if (now >= (eT2+dBt+dW+dBt+dW+dBt+dW+dBt+dW+dBt) && now <= (eT2+dBt+dW+dBt+dW+dBt+dW+dBt+dW+dBt+dW)) {return (4);} // TLP1.7"
        if (now > (eT2+dBt+dW+dBt+dW+dBt+dW+dBt+dW+dBt+dW)) {return (200);} // Finished
        return (201); // unknown
    }


    /** 
     * @dev change agent for minting
     * @param agent - new agent address
     */
    function setFundMintingAgent(address agent) onlyOwner public {
        fundMintingAgent = agent;
        SetFundMintingAgent(agent);
    }


    /** 
     * @dev change wallet for team vesting (this make possible to set smart-contract address later)
     * @param _newTeamWallet - new wallet address
     */
    function setTeamWallet(address _newTeamWallet) onlyOwner public {
        teamWallet = _newTeamWallet;
        SetTeamWallet(_newTeamWallet);
    }


    /** 
     * @dev change wallet for advisory vesting (this make possible to set smart-contract address later)
     * @param _newAdvisoryWallet - new wallet address
     */
    function setAdvisoryWallet(address _newAdvisoryWallet) onlyOwner public {
        advisoryWallet = _newAdvisoryWallet;
        SetAdvisoryWallet(_newAdvisoryWallet);
    }


    /** 
     * @dev change wallet for reserved vesting (this make possible to set smart-contract address later)
     * @param _newReservedWallet - new wallet address
     */
    function setReservedWallet(address _newReservedWallet) onlyOwner public {
        reservedWallet = _newReservedWallet;
        SetReservedWallet(_newReservedWallet);
    }


    /**
     * @dev change min ETH income during Window1-5
     * @param _minETHin - new limit
     */
    function setMinETHin(uint256 _minETHin) onlyOwner public {
        minETHin = _minETHin;
        SetMinETHincome(_minETHin);
    }


    /**
     * @dev set TLP1.X (2-7) start & end dates
     * @param _at - new or old start date
     */
    function setStartEndTimeTLP(uint256 _at) onlyOwner public {
        require(block.timestamp < sT2); // forbid change time when TLP1.2 is active
        require(block.timestamp < _at); // should be great than current block timestamp

        sT2 = _at;
        SetStartTimeTLP2(_at);
    }


    /**
     * @dev Large Token Holder minting 
     * @param to - mint to address
     * @param amount - how much mint
     */
    function fundMinting(address to, uint256 amount) stopInEmergency public {
        require(msg.sender == fundMintingAgent || isOwner());
        require(block.timestamp < sT2);
        require(fundTotalSupply + amount <= fundTokens);
        require(token.totalSupply() + amount <= hardCapInTokens);

        fundTotalSupply = fundTotalSupply.add(amount);
        token.mint(to, amount);
        FundMinting(to, amount);
    }


    /**
     * @dev calculate amount
     * @param  amount - ether to be converted to tokens
     * @param  at - current time
     * @param  _totalSupply - total supplied tokens
     * @return tokens amount that we should send to our dear ppl
     * @return odd ethers amount, which contract should send back
     */
    function calcAmountAt(
        uint256 amount,
        uint256 at,
        uint256 _totalSupply
    ) public constant returns (uint256, uint256) 
    {
        uint256 estimate;
        uint256 price;
        
        if (at >= sT2 && at <= (sT2+dTLP2)) {
            if (at <= sT2 + 15 days) {price = 12e13;} else if (at <= sT2 + 30 days) {
                price = 14e13;} else if (at <= sT2 + 45 days) {
                    price = 16e13;} else if (at <= sT2 + 60 days) {
                        price = 18e13;} else if (at <= sT2 + 75 days) {
                            price = 20e13;} else if (at <= sT2 + 90 days) {
                                price = 22e13;} else if (at <= sT2 + 105 days) {
                                    price = 24e13;} else if (at <= sT2 + 118 days) {
                                        price = 26e13;} else {revert();}
        } else {revert();}

        estimate = _totalSupply.add(amount.mul(1e18).div(price));

        if (estimate > hardCapInTokens) {
            return (
                hardCapInTokens.sub(_totalSupply),
                estimate.sub(hardCapInTokens).mul(price).div(1e18)
            );
        }
        return (estimate.sub(_totalSupply), 0);
    }


    /**
     * @dev fallback for processing ether
     */
    function() payable public {
        return getTokens(msg.sender);
    }


    /**
     * @dev sell token and send to contributor address
     * @param contributor address
     */
    function getTokens(address contributor) payable stopInEmergency validPurchase public {
        uint256 amount;
        uint256 oddEthers;
        uint256 ethers;
        uint256 _at;
        uint8 _winNum;

        _at = block.timestamp;

        require(contributor != 0x0);
       
        if (withinPeriod()) {
        
            (amount, oddEthers) = calcAmountAt(msg.value, _at, token.totalSupply());  // recheck!!!
  
            require(amount + token.totalSupply() <= hardCapInTokens);

            ethers = msg.value.sub(oddEthers);

            token.mint(contributor, amount); // fail if minting is finished
            TokenPurchase(contributor, ethers, amount);
            counter_in = counter_in.add(ethers);
            crowdTokensTLP2 = crowdTokensTLP2.add(amount);

            if (oddEthers > 0) {
                require(oddEthers < msg.value);
                contributor.transfer(oddEthers);
                TransferOddEther(contributor, oddEthers);
            }

            wallet.transfer(ethers);
        } else {
            require(msg.value >= minETHin); // checks min ETH income
            _winNum = stageName();
            require(_winNum >= 0 && _winNum < 5);
            Window storage w = ww[_winNum];

            require(w.tokenPerWindow > 0); // check that we have tokens!

            w.totalEthInWindow = w.totalEthInWindow.add(msg.value);
            ppls[w.totalTransCnt].addr = contributor;
            ppls[w.totalTransCnt].amount = msg.value;
            w.totalTransCnt++;
            TokenPurchaseInWindow(contributor, msg.value, _winNum, w.totalTransCnt, w.totalEthInWindow);
        }
    }


    /**
     * @dev close Window and transfer Eth to wallet address
     * @param _winNum - number of window 0-4 to close
     */
    function closeWindow(uint8 _winNum) onlyOwner stopInEmergency public {
        require(ww[_winNum].active);
        ww[_winNum].active = false;

        wallet.transfer(this.balance);
    }


    /**
     * @dev transfer tokens to ppl accts (window1-5)
     * @param _winNum - number of window 0-4 to close
     */
    function sendTokensWindow(uint8 _winNum) onlyOwner stopInEmergency public {
        uint256 _tokenPerETH;
        uint256 _tokenToSend = 0;
        address _tempAddr;
        uint32 index = ww[_winNum].refundIndex;

        TokenETH(ww[_winNum].totalEthInWindow, ww[_winNum].totalTransCnt);

        require(ww[_winNum].active);
        require(ww[_winNum].totalEthInWindow > 0);
        require(ww[_winNum].totalTransCnt > 0);

        _tokenPerETH = ww[_winNum].tokenPerWindow.div(ww[_winNum].totalEthInWindow); // max McFly in window / ethInWindow

        while (index < ww[_winNum].totalTransCnt && msg.gas > 100000) {
            _tokenToSend = _tokenPerETH.mul(ppls[index].amount);
            ppls[index].amount = 0;
            _tempAddr = ppls[index].addr;
            ppls[index].addr = 0;
            index++;
            token.transfer(_tempAddr, _tokenToSend);
            TokenWithdrawAtWindow(_tempAddr, _tokenToSend);
        }
        ww[_winNum].refundIndex = index;
    }


    /**
     * @dev open new window 0-5 and write totl token per window in structure
     * @param _winNum - number of window 0-4 to close
     * @param _tokenPerWindow - total token for window 0-4
     */
    function newWindow(uint8 _winNum, uint256 _tokenPerWindow) private {
        ww[_winNum] = Window(true, 0, 0, 0, _tokenPerWindow);
        NewWindow(_winNum, _tokenPerWindow);
    }


    /**
     * @dev Finish crowdsale TLP1.2 period and open window1-5 crowdsale
     */
    function finishCrowd() onlyOwner public {
        uint256 _tokenPerWindow;
        require(now > (sT2.add(dTLP2)) || hardCapInTokens == token.totalSupply());
        require(!token.mintingFinished());

        _tokenPerWindow = (mintCapInTokens.sub(crowdTokensTLP2).sub(fundTotalSupply)).div(5);
        token.mint(this, _tokenPerWindow.mul(5)); // mint to contract address
        // shoud be MAX tokens minted!!! 1,800,000,000
        for (uint8 y = 0; y < 5; y++) {
            newWindow(y, _tokenPerWindow);
        }

        token.finishMinting();
    }


    /**
     * @dev withdraw tokens amount within vesting rules for team, advisory and reserved
     * @param withdrawWallet - wallet to transfer tokens
     * @param withdrawTokens - amount of tokens to transfer to
     * @param withdrawTotalSupply - total amount of tokens transfered to account
     * @return unit256 total amount of tokens after transfer
     */
    function vestingWithdraw(address withdrawWallet, uint256 withdrawTokens, uint256 withdrawTotalSupply) private returns (uint256) {
        require(token.mintingFinished());
        require(msg.sender == withdrawWallet || isOwner());

        uint256 currentPeriod = (block.timestamp.sub(sT2.add(dTLP2))).div(VestingPeriodInSeconds);
        if (currentPeriod > VestingPeriodsCount) {
            currentPeriod = VestingPeriodsCount;
        }
        uint256 tokenAvailable = withdrawTokens.mul(currentPeriod).div(VestingPeriodsCount).sub(withdrawTotalSupply);  // RECHECK!!!!!

        require(withdrawTotalSupply + tokenAvailable <= withdrawTokens);

        uint256 _withdrawTotalSupply = withdrawTotalSupply + tokenAvailable;

        token.transfer(withdrawWallet, tokenAvailable);
        WithdrawVesting(withdrawWallet, currentPeriod, tokenAvailable, _withdrawTotalSupply);

        return _withdrawTotalSupply;
    }


    /**
     * @dev withdraw tokens amount within vesting rules for team
     */
    function teamWithdraw() public {
        teamTotalSupply = vestingWithdraw(teamWallet, _teamTokens, teamTotalSupply);
    }


    /**
     * @dev withdraw tokens amount within vesting rules for advisory
     */
    function advisoryWithdraw() public {
        advisoryTotalSupply = vestingWithdraw(advisoryWallet, _advisoryTokens, advisoryTotalSupply);
    }


    /**
     * @dev withdraw tokens amount within vesting rules for reserved wallet
     */
    function reservedWithdraw() public {
        reservedTotalSupply = vestingWithdraw(reservedWallet, _reservedTokens, reservedTotalSupply);
    }
}