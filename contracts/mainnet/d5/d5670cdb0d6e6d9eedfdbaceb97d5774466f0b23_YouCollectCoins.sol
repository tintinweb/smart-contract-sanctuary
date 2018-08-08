pragma solidity ^0.4.18;

contract InterfaceContentCreatorUniverse {
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function priceOf(uint256 _tokenId) public view returns (uint256 price);
  function getNextPrice(uint price, uint _tokenId) public pure returns (uint);
  function lastSubTokenBuyerOf(uint tokenId) public view returns(address);
  function lastSubTokenCreatorOf(uint tokenId) public view returns(address);

  //
  function createCollectible(uint256 tokenId, uint256 _price, address creator, address owner) external ;
}

contract InterfaceYCC {
  function payForUpgrade(address user, uint price) external  returns (bool success);
  function mintCoinsForOldCollectibles(address to, uint256 amount, address universeOwner) external  returns (bool success);
  function tradePreToken(uint price, address buyer, address seller, uint burnPercent, address universeOwner) external;
  function payoutForMining(address user, uint amount) external;
  uint256 public totalSupply;
}

contract InterfaceMining {
  function createMineForToken(uint tokenId, uint level, uint xp, uint nextLevelBreak, uint blocknumber) external;
  function payoutMining(uint tokenId, address owner, address newOwner) external;
  function levelUpMining(uint tokenId) external;
}

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

contract Owned {
  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;
  address private newCeoAddress;
  address private newCooAddress;


  function Owned() public {
      ceoAddress = msg.sender;
      cooAddress = msg.sender;
  }

  /*** ACCESS MODIFIERS ***/
  /// @dev Access modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  /// @dev Access modifier for COO-only functionality
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  /// Access modifier for contract owner only functionality
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    newCeoAddress = _newCEO;
  }

  /// @dev Assigns a new address to act as the COO. Only available to the current COO.
  /// @param _newCOO The address of the new COO
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));
    newCooAddress = _newCOO;
  }

  function acceptCeoOwnership() public {
      require(msg.sender == newCeoAddress);
      require(address(0) != newCeoAddress);
      ceoAddress = newCeoAddress;
      newCeoAddress = address(0);
  }

  function acceptCooOwnership() public {
      require(msg.sender == newCooAddress);
      require(address(0) != newCooAddress);
      cooAddress = newCooAddress;
      newCooAddress = address(0);
  }

  mapping (address => bool) public youCollectContracts;
  function addYouCollectContract(address contractAddress, bool active) public onlyCOO {
    youCollectContracts[contractAddress] = active;
  }
  modifier onlyYCC() {
    require(youCollectContracts[msg.sender]);
    _;
  }

  InterfaceYCC ycc;
  InterfaceContentCreatorUniverse yct;
  InterfaceMining ycm;
  function setMainYouCollectContractAddresses(address yccContract, address yctContract, address ycmContract, address[] otherContracts) public onlyCOO {
    ycc = InterfaceYCC(yccContract);
    yct = InterfaceContentCreatorUniverse(yctContract);
    ycm = InterfaceMining(ycmContract);
    youCollectContracts[yccContract] = true;
    youCollectContracts[yctContract] = true;
    youCollectContracts[ycmContract] = true;
    for (uint16 index = 0; index < otherContracts.length; index++) {
      youCollectContracts[otherContracts[index]] = true;
    }
  }
  function setYccContractAddress(address yccContract) public onlyCOO {
    ycc = InterfaceYCC(yccContract);
    youCollectContracts[yccContract] = true;
  }
  function setYctContractAddress(address yctContract) public onlyCOO {
    yct = InterfaceContentCreatorUniverse(yctContract);
    youCollectContracts[yctContract] = true;
  }
  function setYcmContractAddress(address ycmContract) public onlyCOO {
    ycm = InterfaceMining(ycmContract);
    youCollectContracts[ycmContract] = true;
  }

}

contract TransferInterfaceERC721YC {
  function transferToken(address to, uint256 tokenId) public returns (bool success);
}
contract TransferInterfaceERC20 {
  function transfer(address to, uint tokens) public returns (bool success);
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ConsenSys/Tokens/blob/master/contracts/eip20/EIP20.sol
// ----------------------------------------------------------------------------
contract YouCollectBase is Owned {
  using SafeMath for uint256;

  event RedButton(uint value, uint totalSupply);

  // Payout
  function payout(address _to) public onlyCLevel {
    _payout(_to, this.balance);
  }
  function payout(address _to, uint amount) public onlyCLevel {
    if (amount>this.balance)
      amount = this.balance;
    _payout(_to, amount);
  }
  function _payout(address _to, uint amount) private {
    if (_to == address(0)) {
      ceoAddress.transfer(amount);
    } else {
      _to.transfer(amount);
    }
  }

  // ------------------------------------------------------------------------
  // Owner can transfer out any accidentally sent ERC20 tokens
  // ------------------------------------------------------------------------
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyCEO returns (bool success) {
      return TransferInterfaceERC20(tokenAddress).transfer(ceoAddress, tokens);
  }
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract YouCollectCoins is YouCollectBase {

  //
  //  ERC20 
  //
    /*** CONSTANTS ***/
    string public constant NAME = "YouCollectCoin";
    string public constant SYMBOL = "YCC";
    uint8 public constant DECIMALS = 18;  

    uint256 public totalSupply;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    bool allowTransfer;

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function YouCollectCoins() {
      addYouCollectContract(msg.sender, true);
    }

    /// @dev Required for ERC-20 compliance.
    function name() public pure returns (string) {
      return NAME;
    }

    /// @dev Required for ERC-20 compliance.
    function symbol() public pure returns (string) {
      return SYMBOL;
    }
    /// @dev Required for ERC-20 compliance.
    function decimals() public pure returns (uint8) {
      return DECIMALS;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(allowTransfer);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowTransfer);
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(allowTransfer);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        require(allowTransfer);
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   
  //
  //


  //
  // Coin sale controlled by external smart contract
  //
    bool public coinSaleStarted;
    address public mintableAddress;
    uint public totalTokenSellAmount;
    function mintCoins(address to, uint256 amount) external returns (bool success) {
      require(coinSaleStarted);
      require(msg.sender == mintableAddress);
      require(balances[this] >= amount);
      balances[this] -= amount;
      balances[to] += amount;
      uint bonus = amount.div(100);
      address universeOwner = yct.ownerOf(0);
      balances[universeOwner] += bonus;
      totalSupply += bonus;
      Transfer(this, to, amount);
      Transfer(address(0), universeOwner, bonus);
      return true;
    }
    function startCoinSale(uint totalTokens, address sellingContractAddress) public onlyCEO {
      require(!coinSaleStarted);
      totalTokenSellAmount = totalTokens;
      mintableAddress = sellingContractAddress;
    }
    function acceptCoinSale() public onlyCEO {
      coinSaleStarted = true;
      balances[this] = totalTokenSellAmount;
      totalSupply += totalTokenSellAmount;
    }
    function changeTransfer(bool allowTransfers) external {
        require(msg.sender == mintableAddress);
        allowTransfer = allowTransfers;
    }
  //
  //


  function mintCoinsForOldCollectibles(address to, uint256 amount, address universeOwner) external onlyYCC returns (bool success) {
    balances[to] += amount;
    uint bonus = amount.div(100);
    balances[universeOwner] += bonus;
    totalSupply += amount + bonus;
    Transfer(address(0), to, amount);
    Transfer(address(0), universeOwner, amount);
    return true;
  }

  function payForUpgrade(address user, uint price) external onlyYCC returns (bool success) {
    require(balances[user] >= price);
    balances[user] -= price;
    totalSupply -= price;
    Transfer(user, address(0), price);
    return true;
  }

  function payoutForMining(address user, uint amount) external onlyYCC {
    balances[user] += amount;
    totalSupply += amount;
    Transfer(address(0), user, amount);
  }

  function tradePreToken(uint price, address buyer, address seller, uint burnPercent, address universeOwner) external onlyYCC {
    require(balances[buyer] >= price);
    balances[buyer] -= price;
    if (seller != address(0)) {
      uint256 onePercent = price.div(100);
      uint256 payment = price.sub(onePercent.mul(burnPercent+1));
      // Payment for old owner
      balances[seller] += payment;
      totalSupply -= onePercent.mul(burnPercent);
      balances[universeOwner] += onePercent;
      Transfer(buyer, seller, payment);
      Transfer(buyer, universeOwner, onePercent);
    }else {
      totalSupply -= price;
    }
  }

}