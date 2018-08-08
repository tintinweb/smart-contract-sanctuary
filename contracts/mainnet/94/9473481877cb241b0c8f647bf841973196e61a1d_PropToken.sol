pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}



contract Prop {
    function noFeeTransfer(address _to, uint256 _value) public returns (bool);
    function mintTokens(address _atAddress, uint256 _amount) public;

}

contract BST {
    function balanceOf(address _owner) public constant returns (uint256 _balance);
}

contract FirstBuyers is Ownable {
    using SafeMath for uint256;

    /* Modifiers */
    modifier onlyFirstBuyer() {
        require(firstBuyers[msg.sender].tokensReceived > 0);
        _;
    }

    /* Struct */
    struct FirstBuyer {
        uint256 lastTransactionIndex;
        uint256 tokensReceived;
        uint256 weightedContribution;
    }

    /* Mappings */
    mapping(address => FirstBuyer) firstBuyers;
    mapping(uint256 => uint256) transactions;
    mapping(uint256 => address) firstBuyerIndex;

    /* Private variables */
    uint256 numOfTransaction;
    uint256 numOfFirstBuyers = 0;
    uint256 totalWeightedContribution;
    Prop property;
    BST bst;

    event FirstBuyerWhitdraw(address indexed _firstBuyer, uint256 _amount);
    event NewTransactionOfTokens(uint256 _amount, uint256 _index);

    /**
    * @dev constructor function, creates new FirstBuyers
    * @param _property Address of property
    * @param _owner Owner of this ICO
    **/
    constructor(address _property,  address _owner) public {
        property = Prop(_property);
        owner = _owner;
        bst = BST(0x509A38b7a1cC0dcd83Aa9d06214663D9eC7c7F4a);
    }

    /**
    * @dev add first buyers
    * @param _addresses Array of first buyer addresses
    * @param _amount Array of first buyer tokens
    **/
    function addFirstBuyers(address[] _addresses, uint256[] _amount) public onlyOwner {
        require(_addresses.length == _amount.length);
        for(uint256 i = 0; i < _addresses.length; i++) {
            uint256 weightedContribution = (bst.balanceOf(_addresses[i]).mul(_amount[i])).div(10**18);

            FirstBuyer storage buyer = firstBuyers[_addresses[i]];
            uint256 before = buyer.tokensReceived;
            buyer.tokensReceived = buyer.tokensReceived.add(_amount[i]);
            buyer.weightedContribution = buyer.weightedContribution.add(weightedContribution);

            property.mintTokens(_addresses[i], _amount[i]);
            firstBuyers[_addresses[i]] = buyer;

            totalWeightedContribution = totalWeightedContribution.add(weightedContribution);
            if(before == 0) {
                firstBuyerIndex[numOfFirstBuyers] = _addresses[i];
                numOfFirstBuyers++;
            }
        }
    }

    /**
    * @dev allows First buyers to collect fee from transactions
    **/
    function withdrawTokens() public onlyFirstBuyer {
        FirstBuyer storage buyer = firstBuyers[msg.sender];
        require(numOfTransaction >= buyer.lastTransactionIndex);
        uint256 iterateOver = numOfTransaction.sub(buyer.lastTransactionIndex);
        if (iterateOver > 30) {
            iterateOver = 30;
        }
        uint256 iterate = buyer.lastTransactionIndex.add(iterateOver);
        uint256 amount = 0;
        for (uint256 i = buyer.lastTransactionIndex; i < iterate; i++) {
            uint256 ratio = ((buyer.weightedContribution.mul(10**14)).div(totalWeightedContribution));
            amount = amount.add((transactions[buyer.lastTransactionIndex].mul(ratio)).div(10**14));
            buyer.lastTransactionIndex = buyer.lastTransactionIndex.add(1);
        }
        assert(property.noFeeTransfer(msg.sender, amount));
        emit FirstBuyerWhitdraw(msg.sender, amount);
    }

    /**
    * @dev save every transaction that BSPT sends
    * @param _amount Amount of tokens taken as fee
    **/
    function incomingTransaction(uint256 _amount) public {
        require(msg.sender == address(property));
        transactions[numOfTransaction] = _amount;
        numOfTransaction += 1;
        emit NewTransactionOfTokens(_amount, numOfTransaction);
    }

    /**
    * @dev get transaction index of last transaction that First buyer claimed
    * @param _firstBuyer First buyer address
    * @return Return transaction index
    **/
    function getFirstBuyer(address _firstBuyer) constant public returns (uint256, uint256, uint256) {
        return (firstBuyers[_firstBuyer].lastTransactionIndex,firstBuyers[_firstBuyer].tokensReceived,firstBuyers[_firstBuyer].weightedContribution);
    }

    /**
    * @dev get number of first buyers
    * @return Number of first buyers
    **/
    function getNumberOfFirstBuyer() constant public returns(uint256) {
        return numOfFirstBuyers;
    }

    /**
    * @dev get address of first buyer by index
    * @param _index Index of first buyer
    * @return Address of first buyer
    **/
    function getFirstBuyerAddress(uint256 _index) constant public returns(address) {
        return firstBuyerIndex[_index];
    }

    /**
    * @dev get total number of transactions
    * @return Total number of transactions that came in
    **/
    function getNumberOfTransactions() constant public returns(uint256) {
        return numOfTransaction;
    }

    /**
    * @dev get total weighted contribution
    * @return Total sum of all weighted contribution
    **/
    function getTotalWeightedContribution() constant public returns(uint256) {
        return totalWeightedContribution;
    }

    /**
    * @dev fallback function to prevent any ether to be sent to this contract
    **/
    function () public payable {
        revert();
    }
}


/*****************************/
/*   STANDARD ERC20 TOKEN    */
/*****************************/

contract ERC20Token {

    /** Functions needed to be implemented by ERC20 standard **/
    function totalSupply() public constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) public constant returns (uint256 _balance);
    function transfer(address _to, uint256 _amount) public returns (bool _success);
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool _success);
    function approve(address _spender, uint256 _amount) public returns (bool _success);
    function allowance(address _owner, address _spender) public constant returns (uint256 _remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}

contract Data {
    function canMakeNoFeeTransfer(address _from, address _to) constant public returns(bool);
    function getNetworkFee() public constant returns (uint256);
    function getBlocksquareFee() public constant returns (uint256);
    function getCPFee() public constant returns (uint256);
    function getFirstBuyersFee() public constant returns (uint256);
    function hasPrestige(address _owner) public constant returns(bool);
}

/*****************/
/*   PROPERTY    */
/*****************/

contract PropToken is ERC20Token, Ownable {
    using SafeMath for uint256;

    struct Prop {
        string primaryPropertyType;
        string secondaryPropertyType;
        uint64 cadastralMunicipality;
        uint64 parcelNumber;
        uint64 id;
    }


    /* Info about property */
    string mapURL = "https://www.google.com/maps/place/Tehnolo%C5%A1ki+park+Ljubljana+d.o.o./@46.0491873,14.458252,17z/data=!3m1!4b1!4m5!3m4!1s0x477ad2b1cdee0541:0x8e60f36e738253f0!8m2!3d46.0491873!4d14.4604407";
    string public name = "PropToken BETA 000000000001"; // Name of property
    string public symbol = "BSPT-BETA-000000000001"; // Symbol for property
    uint8 public decimals = 18; // Decimals
    uint8 public numOfProperties;

    bool public tokenFrozen; // Can property be transfered

    /* Fee-recievers */
    FirstBuyers public firstBuyers; //FirstBuyers
    address public networkReserveFund; // Address of Reserve funds
    address public blocksquare; // Address of Blocksquare
    address public certifiedPartner; // Address of partner who is selling property

    /* Private variables */
    uint256 supply; //Current supply, at end total supply
    uint256 MAXSUPPLY = 100000 * 10 ** 18; // Total supply
    uint256 feePercent;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    Data data;

    Prop[] properties;

    /* Events */
    event TokenFrozen(bool _frozen, string _reason);
    event Mint(address indexed _to, uint256 _value);

    /**
    * @dev constructor
    **/
    constructor() public {
        owner = msg.sender;
        tokenFrozen = true;
        feePercent = 2;
        networkReserveFund = address(0x7E8f1b7655fc05e48462082E5A12e53DBc33464a);
        blocksquare = address(0x84F4CE7a40238062edFe3CD552cacA656d862f27);
        certifiedPartner = address(0x3706E1CdB3254a1601098baE8D1A8312Cf92f282);
        firstBuyers = new FirstBuyers(this, owner);
    }

    /**
    * @dev add new property under this BSPT
    * @param _primaryPropertyType Primary type of property
    * @param _secondaryPropertyType Secondary type of property
    * @param _cadastralMunicipality Cadastral municipality
    * @param _parcelNumber Parcel number
    * @param _id Id of property
    **/
    function addProperty(string _primaryPropertyType, string _secondaryPropertyType, uint64 _cadastralMunicipality, uint64 _parcelNumber, uint64 _id) public onlyOwner {
        properties.push(Prop(_primaryPropertyType, _secondaryPropertyType, _cadastralMunicipality, _parcelNumber, _id));
        numOfProperties++;
    }

    /**
    * @dev set data factory
    * @param _data Address of data factory
    **/
    function setDataFactory(address _data) public onlyOwner {
        data = Data(_data);
    }

    /**
    * @dev send tokens without fee
    * @param _from Address of sender.
    * @param _to Address of recipient.
    * @param _amount Amount to send.
    * @return Whether the transfer was successful or not.
    **/
    function noFee(address _from, address _to, uint256 _amount) private returns (bool) {
        require(!tokenFrozen);
        require(balances[_from] >= _amount);
        balances[_to] = balances[_to].add(_amount);
        balances[_from] = balances[_from].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
    * @dev allows first buyers contract to transfer BSPT without fee
    * @param _to Where to send BSPT
    * @param _amount Amount of BSPT to send
    * @return True if transfer was successful, false instead
    **/
    function noFeeTransfer(address _to, uint256 _amount) public returns (bool) {
        require(msg.sender == address(firstBuyers));
        return noFee(msg.sender, _to, _amount);
    }

    /**
    * @dev calculate and distribute fee for fee-recievers
    * @param _fee Fee amount
    **/
    function distributeFee(uint256 _fee) private {
        balances[networkReserveFund] = balances[networkReserveFund].add((_fee.mul(data.getNetworkFee())).div(100));
        balances[blocksquare] = balances[blocksquare].add((_fee.mul(data.getBlocksquareFee())).div(100));
        balances[certifiedPartner] = balances[certifiedPartner].add((_fee.mul(data.getCPFee())).div(100));
        balances[address(firstBuyers)] = balances[address(firstBuyers)].add((_fee.mul(data.getFirstBuyersFee())).div(100));
        firstBuyers.incomingTransaction((_fee.mul(data.getFirstBuyersFee())).div(100));
    }

    /**
    * @dev send tokens
    * @param _from Address of sender.
    * @param _to Address of recipient.
    * @param _amount Amount to send.
    **/
    function _transfer(address _from, address _to, uint256 _amount) private {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _amount);
        uint256 fee = (_amount.mul(feePercent)).div(100);
        distributeFee(fee);
        balances[_to] = balances[_to].add(_amount.sub(fee));
        balances[_from] = balances[_from].sub(_amount);
        emit Transfer(_from, _to, _amount.sub(fee));
    }

    /**
    * @dev send tokens from your address.
    * @param _to Address of recipient.
    * @param _amount Amount to send.
    * @return Whether the transfer was successful or not.
    **/
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(!tokenFrozen);
        if (data.canMakeNoFeeTransfer(msg.sender, _to) || data.hasPrestige(msg.sender)) {
            noFee(msg.sender, _to, _amount);
        }
        else {
            _transfer(msg.sender, _to, _amount);
        }
        return true;
    }

    /**
    * @dev set allowance for someone to spend tokens from your address
    * @param _spender Address of spender.
    * @param _amount Max amount allowed to spend.
    * @return Whether the approve was successful or not.
    **/
    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
    * @dev send tokens
    * @param _from Address of sender.
    * @param _to Address of recipient.
    * @param _amount Amount of token to send.
    * @return Whether the transfer was successful or not.
    **/
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(_amount <= allowances[_from][msg.sender]);
        require(!tokenFrozen);
        _transfer(_from, _to, _amount);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
        return true;
    }

    /**
    * @dev mint tokens, can only be done by first buyers contract
    * @param _atAddress Adds tokens to address
    * @param _amount Amount of tokens to add
    **/
    function mintTokens(address _atAddress, uint256 _amount) public {
        require(msg.sender == address(firstBuyers));
        require(balances[_atAddress].add(_amount) > balances[_atAddress]);
        require((supply.add(_amount)) <= MAXSUPPLY);
        supply = supply.add(_amount);
        balances[_atAddress] = balances[_atAddress].add(_amount);
        emit Mint(_atAddress, _amount);
        emit Transfer(0x0, _atAddress, _amount);
    }

    /**
    * @dev changes status of frozen
    * @param _reason Reason for freezing or unfreezing token
    **/
    function changeFreezeTransaction(string _reason) public onlyOwner {
        tokenFrozen = !tokenFrozen;
        emit TokenFrozen(tokenFrozen, _reason);
    }

    /**
    * @dev change fee percent
    * @param _fee New fee percent
    **/
    function changeFee(uint256 _fee) public onlyOwner {
        feePercent = _fee;
    }

    /**
    * @dev get allowance
    * @param _owner Owner address
    * @param _spender Spender address
    * @return Return amount allowed to spend from &#39;_owner&#39; by &#39;_spender&#39;
    **/
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowances[_owner][_spender];
    }

    /**
    * @dev total amount of token
    * @return Total amount of token
    **/
    function totalSupply() public constant returns (uint256) {
        return supply;
    }

    /**
    * @dev check balance of address
    * @param _owner Address
    * @return Amount of token in possession
    **/
    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    /**
    * @dev get information about property
    * @param _index Index of property
    * @return Primary type, secondary type, cadastral municipality, parcel number and id of property
    **/
    function getPropertyInfo(uint8 _index) public constant returns (string, string, uint64, uint64, uint64) {
        return (properties[_index].primaryPropertyType, properties[_index].secondaryPropertyType, properties[_index].cadastralMunicipality, properties[_index].parcelNumber, properties[_index].id);
    }

    /**
    * @dev get google maps url of property location
    **/
    function getMap() public constant returns (string) {
        return mapURL;
    }
}