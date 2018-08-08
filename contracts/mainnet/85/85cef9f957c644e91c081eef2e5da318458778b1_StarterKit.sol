pragma solidity ^0.4.18;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



/// @title Starter Kit Contract 
/// @author Julia Altenried, Yuriy Kashnikov
contract StarterKit is Ownable {

    /**  CONSTANTS **/
    uint256 public constant COPPER_AMOUNT_NDC = 1000 * 10**18;
    uint256 public constant COPPER_AMOUNT_TPT = 1500 * 10**18;
    uint256 public constant COPPER_AMOUNT_SKL = 25 * 10**18;
    uint256 public constant COPPER_AMOUNT_XPER = 12 * 10**2;

    uint256 public constant BRONZE_AMOUNT_NDC = 2000 * 10**18;
    uint256 public constant BRONZE_AMOUNT_TPT = 4000 * 10**18;
    uint256 public constant BRONZE_AMOUNT_SKL = 50 * 10**18;
    uint256 public constant BRONZE_AMOUNT_XPER = 25 * 10**2;

    uint256 public constant SILVER_AMOUNT_NDC = 11000 * 10**18;
    uint256 public constant SILVER_AMOUNT_TPT = 33000 * 10**18;
    uint256 public constant SILVER_AMOUNT_SKL = 100 * 10**18;
    uint256 public constant SILVER_AMOUNT_XPER = 50 * 10**2;

    uint256 public constant GOLD_AMOUNT_NDC = 25000 * 10**18;
    uint256 public constant GOLD_AMOUNT_TPT = 100000 * 10**18;
    uint256 public constant GOLD_AMOUNT_SKL = 200 * 10**18;
    uint256 public constant GOLD_AMOUNT_XPER = 100 * 10**2;

    uint256 public constant PLATINUM_AMOUNT_NDC = 250000 * 10**18;
    uint256 public constant PLATINUM_AMOUNT_TPT = 1250000 * 10**18;
    uint256 public constant PLATINUM_AMOUNT_SKL = 2000 * 10**18;
    uint256 public constant PLATINUM_AMOUNT_XPER = 500 * 10**2;


    /* set of predefined token contract addresses and instances, can be set by owner only */
    ERC20 public tpt;
    ERC20 public ndc;
    ERC20 public skl;
    ERC20 public xper;

    /* signer address, can be set by owner only */
    address public neverdieSigner;

    event BuyCopper(
        address indexed to,
        uint256 CopperPrice,
        uint256 value
    );

    event BuyBronze(
        address indexed to,
        uint256 BronzePrice,
        uint256 value
    );

    event BuySilver(
        address indexed to,
        uint256 SilverPrice,
        uint256 value
    );

    event BuyGold(
        address indexed to,
        uint256 GoldPrice,
        uint256 value
    );

    event BuyPlatinum(
        address indexed to,
        uint256 PlatinumPrice,
        uint256 value
    );


    /// @dev handy constructor to initialize StarerKit with a set of proper parameters
    /// @param _tptContractAddress TPT token address 
    /// @param _ndcContractAddress NDC token address
    /// @param _signer signer address
    function StarterKit(address _tptContractAddress, address _ndcContractAddress,
                        address _sklContractAddress, address _xperContractAddress,
                        address _signer) public {
        tpt = ERC20(_tptContractAddress);
        ndc = ERC20(_ndcContractAddress);
        skl = ERC20(_sklContractAddress);
        xper = ERC20(_xperContractAddress);
        neverdieSigner = _signer;
    }

    function setNDCContractAddress(address _to) external onlyOwner {
        ndc = ERC20(_to);
    }

    function setTPTContractAddress(address _to) external onlyOwner {
        tpt = ERC20(_to);
    }

    function setSKLContractAddress(address _to) external onlyOwner {
        skl = ERC20(_to);
    }

    function setXPERContractAddress(address _to) external onlyOwner {
        xper = ERC20(_to);
    }

    function setSignerAddress(address _to) external onlyOwner {
        neverdieSigner = _to;
    }

    /// @dev buy Copper with ether
    /// @param _CopperPrice price in Wei
    /// @param _expiration expiration timestamp
    /// @param _v ECDCA signature
    /// @param _r ECDSA signature
    /// @param _s ECDSA signature
    function buyCopper(uint256 _CopperPrice,
                       uint256 _expiration,
                       uint8 _v,
                       bytes32 _r,
                       bytes32 _s
                      ) payable external {
        // Check if the signature did not expire yet by inspecting the timestamp
        require(_expiration >= block.timestamp);

        // Check if the signature is coming from the neverdie address
        address signer = ecrecover(keccak256(_CopperPrice, _expiration), _v, _r, _s);
        require(signer == neverdieSigner);

        require(msg.value >= _CopperPrice);
        
        assert(ndc.transfer(msg.sender, COPPER_AMOUNT_NDC) 
            && tpt.transfer(msg.sender, COPPER_AMOUNT_TPT)
            && skl.transfer(msg.sender, COPPER_AMOUNT_SKL)
            && xper.transfer(msg.sender, COPPER_AMOUNT_XPER));
           

        // Emit BuyCopper event
        emit BuyCopper(msg.sender, _CopperPrice, msg.value);
    }

    /// @dev buy Bronze with ether
    /// @param _BronzePrice price in Wei
    /// @param _expiration expiration timestamp
    /// @param _v ECDCA signature
    /// @param _r ECDSA signature
    /// @param _s ECDSA signature
    function buyBronze(uint256 _BronzePrice,
                       uint256 _expiration,
                       uint8 _v,
                       bytes32 _r,
                       bytes32 _s
                      ) payable external {
        // Check if the signature did not expire yet by inspecting the timestamp
        require(_expiration >= block.timestamp);

        // Check if the signature is coming from the neverdie address
        address signer = ecrecover(keccak256(_BronzePrice, _expiration), _v, _r, _s);
        require(signer == neverdieSigner);

        require(msg.value >= _BronzePrice);
        assert(ndc.transfer(msg.sender, BRONZE_AMOUNT_NDC) 
            && tpt.transfer(msg.sender, BRONZE_AMOUNT_TPT)
            && skl.transfer(msg.sender, BRONZE_AMOUNT_SKL)
            && xper.transfer(msg.sender, BRONZE_AMOUNT_XPER));

        // Emit BuyBronze event
        emit BuyBronze(msg.sender, _BronzePrice, msg.value);
    }

    /// @dev buy Silver with ether
    /// @param _SilverPrice price in Wei
    /// @param _expiration expiration timestamp
    /// @param _v ECDCA signature
    /// @param _r ECDSA signature
    /// @param _s ECDSA signature
    function buySilver(uint256 _SilverPrice,
                       uint256 _expiration,
                       uint8 _v,
                       bytes32 _r,
                       bytes32 _s
                      ) payable external {
        // Check if the signature did not expire yet by inspecting the timestamp
        require(_expiration >= block.timestamp);

        // Check if the signature is coming from the neverdie address
        address signer = ecrecover(keccak256(_SilverPrice, _expiration), _v, _r, _s);
        require(signer == neverdieSigner);

        require(msg.value >= _SilverPrice);
        assert(ndc.transfer(msg.sender, SILVER_AMOUNT_NDC) 
            && tpt.transfer(msg.sender, SILVER_AMOUNT_TPT)
            && skl.transfer(msg.sender, SILVER_AMOUNT_SKL)
            && xper.transfer(msg.sender, SILVER_AMOUNT_XPER));

        // Emit BuySilver event
        emit BuySilver(msg.sender, _SilverPrice, msg.value);
    }

    /// @dev buy Gold with ether
    /// @param _GoldPrice price in Wei
    /// @param _expiration expiration timestamp
    /// @param _v ECDCA signature
    /// @param _r ECDSA signature
    /// @param _s ECDSA signature
    function buyGold(uint256 _GoldPrice,
                       uint256 _expiration,
                       uint8 _v,
                       bytes32 _r,
                       bytes32 _s
                      ) payable external {
        // Check if the signature did not expire yet by inspecting the timestamp
        require(_expiration >= block.timestamp);

        // Check if the signature is coming from the neverdie address
        address signer = ecrecover(keccak256(_GoldPrice, _expiration), _v, _r, _s);
        require(signer == neverdieSigner);

        require(msg.value >= _GoldPrice);
        assert(ndc.transfer(msg.sender, GOLD_AMOUNT_NDC) 
            && tpt.transfer(msg.sender, GOLD_AMOUNT_TPT)
            && skl.transfer(msg.sender, GOLD_AMOUNT_SKL)
            && xper.transfer(msg.sender, GOLD_AMOUNT_XPER));

        // Emit BuyGold event
        emit BuyGold(msg.sender, _GoldPrice, msg.value);
    }

    /// @dev buy Platinum with ether
    /// @param _PlatinumPrice price in Wei
    /// @param _expiration expiration timestamp
    /// @param _v ECDCA signature
    /// @param _r ECDSA signature
    /// @param _s ECDSA signature
    function buyPlatinum(uint256 _PlatinumPrice,
                       uint256 _expiration,
                       uint8 _v,
                       bytes32 _r,
                       bytes32 _s
                      ) payable external {
        // Check if the signature did not expire yet by inspecting the timestamp
        require(_expiration >= block.timestamp);

        // Check if the signature is coming from the neverdie address
        address signer = ecrecover(keccak256(_PlatinumPrice, _expiration), _v, _r, _s);
        require(signer == neverdieSigner);

        require(msg.value >= _PlatinumPrice);
        assert(ndc.transfer(msg.sender, PLATINUM_AMOUNT_NDC) 
            && tpt.transfer(msg.sender, PLATINUM_AMOUNT_TPT)
            && skl.transfer(msg.sender, PLATINUM_AMOUNT_SKL)
            && xper.transfer(msg.sender, PLATINUM_AMOUNT_XPER));

        // Emit BuyPlatinum event
        emit BuyPlatinum(msg.sender, _PlatinumPrice, msg.value);
    }

    /// @dev withdraw all ether
    function withdrawEther() external onlyOwner {
        owner.transfer(this.balance);
    }

    function withdraw() public onlyOwner {
      uint256 allNDC= ndc.balanceOf(this);
      uint256 allTPT = tpt.balanceOf(this);
      uint256 allSKL = skl.balanceOf(this);
      uint256 allXPER = xper.balanceOf(this);
      if (allNDC > 0) ndc.transfer(msg.sender, allNDC);
      if (allTPT > 0) tpt.transfer(msg.sender, allTPT);
      if (allSKL > 0) skl.transfer(msg.sender, allSKL);
      if (allXPER > 0) xper.transfer(msg.sender, allXPER);
    }

    /// @dev withdraw token
    /// @param _tokenContract any kind of ERC20 token to withdraw from
    function withdrawToken(address _tokenContract) external onlyOwner {
        ERC20 token = ERC20(_tokenContract);
        uint256 balance = token.balanceOf(this);
        assert(token.transfer(owner, balance));
    }

    /// @dev kill contract, but before transfer all tokens and ether to owner
    function kill() onlyOwner public {
      withdraw();
      selfdestruct(owner);
    }

}