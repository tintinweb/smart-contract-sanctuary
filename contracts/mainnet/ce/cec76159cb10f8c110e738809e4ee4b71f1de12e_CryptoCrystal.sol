pragma solidity ^0.4.23;

// File: contracts/zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: contracts/Acceptable.sol

// @title Acceptable
// @author Takayuki Jimba
// @dev Provide basic access control.
contract Acceptable is Ownable {
    address public sender;

    // @dev Throws if called by any address other than the sender.
    modifier onlyAcceptable {
        require(msg.sender == sender);
        _;
    }

    // @dev Change acceptable address
    // @param _sender The address to new sender
    function setAcceptable(address _sender) public onlyOwner {
        sender = _sender;
    }
}

// File: contracts/zeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);  

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);
  
  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);
  
  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;  
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;
}

// File: contracts/zeppelin-solidity/contracts/token/ERC721/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: contracts/CrystalBaseIF.sol

// @title CrystalBaseIF
// @author Takayuki Jimba
contract CrystalBaseIF is ERC721 {
    function mint(address _owner, uint256 _gene, uint256 _kind, uint256 _weight) public returns(uint256);
    function burn(address _owner, uint256 _tokenId) public;
    function _transferFrom(address _from, address _to, uint256 _tokenId) public;
    function getCrystalKindWeight(uint256 _tokenId) public view returns(uint256 kind, uint256 weight);
    function getCrystalGeneKindWeight(uint256 _tokenId) public view returns(uint256 gene, uint256 kind, uint256 weight);
}

// File: contracts/zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: contracts/MiningSupplier.sol

// @title MiningSupplier
// @author Takayuki Jimba
contract MiningSupplier {
    using SafeMath for uint256;

    uint256 public constant secondsPerYear = 1 years * 1 seconds;
    uint256 public constant secondsPerDay = 1 days * 1 seconds;

    // @dev Number of blocks per year
    function _getBlocksPerYear(
        uint256 _secondsPerBlock
    ) public pure returns(uint256) {
        return secondsPerYear.div(_secondsPerBlock);
    }

    // @dev 0-based block number index
    //      First block number index of every years is 0
    function _getBlockIndexAtYear(
        uint256 _initialBlockNumber,
        uint256 _currentBlockNumber,
        uint256 _secondsPerBlock
    ) public pure returns(uint256) {
        //require(_currentBlockNumber >= _initialBlockNumber, "current is large than or equal to initial");
        require(_currentBlockNumber >= _initialBlockNumber);
        uint256 _blockIndex = _currentBlockNumber.sub(_initialBlockNumber);
        uint256 _blocksPerYear = _getBlocksPerYear(_secondsPerBlock);
        return _blockIndex.sub(_blockIndex.div(_blocksPerYear).mul(_blocksPerYear));
    }

    // @dev Map block number to block index.
    //      First block is number 0.
    function _getBlockIndex(
        uint256 _initialBlockNumber,
        uint256 _currentBlockNumber
    ) public pure returns(uint256) {
        //require(_currentBlockNumber >= _initialBlockNumber, "current is large than or equal to initial");
        require(_currentBlockNumber >= _initialBlockNumber);
        return _currentBlockNumber.sub(_initialBlockNumber);
    }

    // @dev Map block number to year index.
    //      First (blocksPerYear - 1) blocks are number 0.
    function _getYearIndex(
        uint256 _secondsPerBlock,
        uint256 _initialBlockNumber,
        uint256 _currentBlockNumber
    ) public pure returns(uint256) {
        uint256 _blockIndex =  _getBlockIndex(_initialBlockNumber, _currentBlockNumber);
        uint256 _blocksPerYear = _getBlocksPerYear(_secondsPerBlock);
        return _blockIndex.div(_blocksPerYear);
    }

    // @dev
    function _getWaitingBlocks(
        uint256 _secondsPerBlock
    ) public pure returns(uint256) {
        return secondsPerDay.div(_secondsPerBlock);
    }

    function _getWeightUntil(
        uint256 _totalWeight,
        uint256 _yearIndex
    ) public pure returns(uint256) {
        uint256 _sum = 0;
        for(uint256 i = 0; i < _yearIndex; i++) {
            _sum = _sum.add(_totalWeight / (2 ** (i + 1)));
        }
        return _sum;
    }

    function _estimateSupply(
        uint256 _secondsPerBlock,
        uint256 _initialBlockNumber,
        uint256 _currentBlockNumber,
        uint256 _totalWeight
    ) public pure returns(uint256){
        uint256 _yearIndex = _getYearIndex(_secondsPerBlock, _initialBlockNumber, _currentBlockNumber); // 0-based
        uint256 _blockIndex = _getBlockIndexAtYear(_initialBlockNumber, _currentBlockNumber, _secondsPerBlock) + 1;
        uint256 _numerator = _totalWeight.mul(_secondsPerBlock).mul(_blockIndex);
        uint256 _yearFactor = 2 ** (_yearIndex + 1);
        uint256 _denominator =  _yearFactor.mul(secondsPerYear);
        uint256 _supply = _numerator.div(_denominator).add(_getWeightUntil(_totalWeight, _yearIndex));
        return _supply; // mg
    }

    function _estimateWeight(
        uint256 _secondsPerBlock,
        uint256 _initialBlockNumber,
        uint256 _currentBlockNumber,
        uint256 _totalWeight,
        uint256 _currentWeight
    ) public pure returns(uint256) {
        uint256 _supply = _estimateSupply(
            _secondsPerBlock,
            _initialBlockNumber,
            _currentBlockNumber,
            _totalWeight
        );
        uint256 _yearIndex = _getYearIndex(
            _secondsPerBlock,
            _initialBlockNumber,
            _currentBlockNumber
        ); // 0-based
        uint256 _yearFactor = 2 ** _yearIndex;
        uint256 _defaultWeight = 10000; // mg

        if(_currentWeight > _supply) {
            // (_supply / _currentWeight) * _defaultWeight / _yearFactor
            return _supply.mul(_defaultWeight).div(_currentWeight).div(_yearFactor);
        } else {
            // _defaultWeight / _yearFactor
            return _defaultWeight.div(_yearFactor);
        }
    }

    function _updateNeeded(
        uint256 _secondsPerBlock,
        uint256 _currentBlockNumber,
        uint256 _blockNumberUpdated
    ) public pure returns(bool) {
        if (_blockNumberUpdated == 0) {
            return true;
        }
        uint256 _waitingBlocks = _getWaitingBlocks(_secondsPerBlock);
        return _currentBlockNumber >= _blockNumberUpdated + _waitingBlocks;
    }
}

// File: contracts/CrystalWeightManager.sol

// @title CrystalWeightManager
// @author Takayuki Jimba
contract CrystalWeightManager is MiningSupplier {
    // Amounts of deposit of all crystals.
    // Each unit of weight is milligrams
    // e.g. 50000000000 means 50t.
    uint256[100] crystalWeights = [
        50000000000,226800000000,1312500000000,31500000000,235830000000,
        151200000000,655200000000,829500000000,7177734375,762300000000,
        684600000000,676200000000,5037226562,30761718750,102539062500,
        102539062500,102539062500,5126953125,31500000000,5040000000,
        20507812500,20507812500,10253906250,5024414062,6300000000,
        20507812500,102539062500,102539062500,102539062500,102539062500,
        102539062500,7690429687,15380859375,69300000000,10253906250,
        547050000000,15380859375,20507812500,15380859375,15380859375,
        20507812500,15380859375,7690429687,153808593750,92285156250,
        102539062500,71777343750,82031250000,256347656250,1384277343750,
        820312500000,743408203125,461425781250,563964843750,538330078125,
        358886718750,256347656250,358886718750,102539062500,307617187500,
        256347656250,51269531250,41015625000,307617187500,307617187500,
        2050781250,3588867187,2563476562,5126953125,399902343750,
        615234375000,563964843750,461425781250,358886718750,717773437500,
        41015625000,41015625000,2050781250,102539062500,102539062500,
        51269531250,102539062500,30761718750,41015625000,102539062500,
        102539062500,102539062500,205078125000,205078125000,556500000000,
        657300000000,41015625000,102539062500,30761718750,102539062500,
        20507812500,20507812500,20507812500,20507812500,82031250000
    ];

    uint256 public secondsPerBlock = 12;
    uint256 public initialBlockNumber = block.number;
    uint256 public constant originalTotalWeight = 21 * 10**13; // mg
    uint256 public currentWeight = 0;
    uint256 public estimatedWeight = 0;
    uint256 public blockNumberUpdated = 0;

    event UpdateEstimatedWeight(uint256 weight, uint256 nextUpdateBlockNumber);

    function setEstimatedWeight(uint256 _minedWeight) internal {
        currentWeight = currentWeight.add(_minedWeight);

        uint256 _currentBlockNumber = block.number;

        bool _isUpdate = _updateNeeded(
            secondsPerBlock,
            _currentBlockNumber,
            blockNumberUpdated
        );

        if(_isUpdate) {
            estimatedWeight = _estimateWeight(
                secondsPerBlock,
                initialBlockNumber,
                _currentBlockNumber,
                originalTotalWeight,
                currentWeight
            );
            blockNumberUpdated = _currentBlockNumber;

            emit UpdateEstimatedWeight(estimatedWeight, _currentBlockNumber);
        }
    }

    function getCrystalWeights() external view returns(uint256[100]) {
        return crystalWeights;
    }
}

// File: contracts/EOACallable.sol

// @title EOACallable
// @author Takayuki Jimba
contract EOACallable {
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    modifier onlyEOA {
        require(!isContract(msg.sender));
        _;
    }
}

// File: contracts/ExchangeBaseIF.sol

// @title ExchangeBaseIF
// @author Takayuki Jimba
contract ExchangeBaseIF {
    function create(
        address _owner,
        uint256 _ownerTokenId,
        uint256 _ownerTokenGene,
        uint256 _ownerTokenKind,
        uint256 _ownerTokenWeight,
        uint256 _kind,
        uint256 _weight,
        uint256 _createdAt
    ) public returns(uint256);
    function remove(uint256 _id) public;
    function getExchange(uint256 _id) public view returns(
        address owner,
        uint256 tokenId,
        uint256 kind,
        uint256 weight,
        uint256 createdAt
    );
    function getTokenId(uint256 _id) public view returns(uint256);
    function ownerOf(uint256 _id) public view returns(address);
    function isOnExchange(uint256 _tokenId) public view returns(bool);
    function isOnExchangeById(uint256 _id) public view returns(bool);
}

// File: contracts/zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: contracts/PickaxeIF.sol

// @title PickaxeIF
// @author Takayuki Jimba
contract PickaxeIF is ERC20 {
    function transferFromOwner(address _to, uint256 _amount) public;
    function burn(address _from, uint256 _amount) public;
}

// File: contracts/RandomGeneratorIF.sol

// @title RandomGeneratorIF
// @author Takayuki Jimba
contract RandomGeneratorIF {
    function generate() public returns(uint64);
}

// File: contracts/Sellable.sol

// @title Sellable
// @author Takayuki Jimba
// @dev Sell tokens.
//      Token is supposed to be Pickaxe contract in our contracts.
//      Actual transferring tokens operation is to be implemented in inherited contract.
contract Sellable is Ownable {
    using SafeMath for uint256;

    address public wallet;
    uint256 public rate;

    address public donationWallet;
    uint256 public donationRate;

    uint256 public constant MIN_WEI_AMOUNT = 5 * 10**15;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event ForwardFunds(address sender, uint256 value, uint256 deposit);
    event Donation(address sender, uint256 value);

    constructor(address _wallet, address _donationWallet, uint256 _donationRate) public {
        // 1 token = 0.005 ETH
        rate = 200;
        wallet = _wallet;
        donationWallet = _donationWallet;
        donationRate = _donationRate;
    }

    function setWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }

    function setEthereumWallet(address _donationWallet) external onlyOwner {
        donationWallet = _donationWallet;
    }

    function () external payable {
        require(msg.value >= MIN_WEI_AMOUNT);
        buyPickaxes(msg.sender);
    }

    function buyPickaxes(address _beneficiary) public payable {
        require(msg.value >= MIN_WEI_AMOUNT);

        uint256 _weiAmount = msg.value;
        uint256 _tokens = _weiAmount.mul(rate).div(1 ether);

        require(_tokens.mul(1 ether).div(rate) == _weiAmount);

        _transferFromOwner(msg.sender, _tokens);
        emit TokenPurchase(msg.sender, _beneficiary, _weiAmount, _tokens);
        _forwardFunds();
    }

    function _transferFromOwner(address _to, uint256 _value) internal {
        /* MUST override */
    }

    function _forwardFunds() internal {
        uint256 donation = msg.value.div(donationRate); // 2%
        uint256 value = msg.value - donation;

        wallet.transfer(value);

        emit ForwardFunds(msg.sender, value, donation);

        uint256 donationEth = 2014000000000000000; // 2.014 ether
        if(address(this).balance >= donationEth) {
            donationWallet.transfer(donationEth);
            emit Donation(msg.sender, donationEth);
        }
    }
}

// File: contracts/CryptoCrystal.sol

// @title CryptoCrystal
// @author Takayuki Jimba
// @dev Almost all application specific logic is in this contract.
//      CryptoCrystal acts as a facade to Pixaxe(ERC20), CrystalBase(ERC721), ExchangeBase as to transactions.
contract CryptoCrystal is Sellable, EOACallable, CrystalWeightManager {
    PickaxeIF public pickaxe;
    CrystalBaseIF public crystal;
    ExchangeBaseIF public exchange;
    RandomGeneratorIF public generator;

    //event RandomGenerated(uint256 number);

    event MineCrystals(
        // miner of the crystal
        address indexed owner,
        // time of mining
        uint256 indexed minedAt,
        // tokenIds of mined crystals
        uint256[] tokenIds,
        // kinds of mined crystals
        uint256[] kinds,
        // weights of mined crystals
        uint256[] weights,
        // genes of mined crystals
        uint256[] genes
    );

    event MeltCrystals(
        // melter of the crystals
        address indexed owner,
        // time of melting
        uint256 indexed meltedAt,
        // tokenIds of melted crystals
        uint256[] meltedTokenIds,
        // tokenId of newly generated crystal
        uint256 tokenId,
        // kind of newly generated crystal
        uint256 kind,
        // weight of newly generated crystal
        uint256 weight,
        // gene of newly generated crystal
        uint256 gene
    );

    event CreateExchange(
        // id of exchange
        uint256 indexed id,
        // creator of the exchange
        address owner,
        // tokenId of exhibited crystal
        uint256 ownerTokenId,
        // gene of exhibited crystal
        uint256 ownerTokenGene,
        // kind of exhibited crystal
        uint256 ownerTokenKind,
        // weight of exhibited crystal
        uint256 ownerTokenWeight,
        // kind of condition for exchange
        uint256 kind,
        // weight of condition for exchange
        uint256 weight,
        // time of exchange creation
        uint256 createdAt
    );

    event CancelExchange(
        // id of excahnge
        uint256 indexed id,
        // creator of the exchange
        address owner,
        // tokenId of exhibited crystal
        uint256 ownerTokenId,
        // kind of exhibited crystal
        uint256 ownerTokenKind,
        // weight of exhibited crystal
        uint256 ownerTokenWeight,
        // time of exchange cancelling
        uint256 cancelledAt
    );

    event BidExchange(
        // id of exchange
        uint256 indexed id,
        // creator of the exchange
        address owner,
        // tokenId of exhibited crystal
        uint256 ownerTokenId,
        // gene of exhibited crystal
        uint256 ownerTokenGene,
        // kind of exhibited crystal
        uint256 ownerTokenKind,
        // weight of exhibited crystal
        uint256 ownerTokenWeight,
        // exchanger who bid to exchange
        address exchanger,
        // tokenId of crystal to exchange
        uint256 exchangerTokenId,
        // kind of crystal to exchange
        uint256 exchangerTokenKind,
        // weight of crystal to exchange (may not be the same to weight condition)
        uint256 exchangerTokenWeight,
        // time of bidding
        uint256 bidAt
    );

    struct ExchangeWrapper {
        uint256 id;
        address owner;
        uint256 tokenId;
        uint256 kind;
        uint256 weight;
        uint256 createdAt;
    }

    struct CrystalWrapper {
        address owner;
        uint256 tokenId;
        uint256 gene;
        uint256 kind;
        uint256 weight;
    }

    constructor(
        PickaxeIF _pickaxe,
        CrystalBaseIF _crystal,
        ExchangeBaseIF _exchange,
        RandomGeneratorIF _generator,
        address _wallet,
        address _donationWallet,
        uint256 _donationRate
    ) Sellable(_wallet, _donationWallet, _donationRate) public {
        pickaxe = _pickaxe;
        crystal = _crystal;
        exchange = _exchange;
        generator = _generator;
        setEstimatedWeight(0);
    }

    // @dev mineCrystals consists of two basic operations that burn pickaxes and mint crystals.
    // @param _pkxAmount uint256 the amount of tokens to be burned
    function mineCrystals(uint256 _pkxAmount) external onlyEOA {
        address _owner = msg.sender;
        require(pickaxe.balanceOf(msg.sender) >= _pkxAmount);
        require(0 < _pkxAmount && _pkxAmount <= 100);

        uint256 _crystalAmount = _getRandom(5);

        uint256[] memory _tokenIds = new uint256[](_crystalAmount);
        uint256[] memory _kinds = new uint256[](_crystalAmount);
        uint256[] memory _weights = new uint256[](_crystalAmount);
        uint256[] memory _genes = new uint256[](_crystalAmount);

        uint256[] memory _crystalWeightsCumsum = new uint256[](100);
        _crystalWeightsCumsum[0] = crystalWeights[0];
        for(uint256 i = 1; i < 100; i++) {
            _crystalWeightsCumsum[i] = _crystalWeightsCumsum[i - 1].add(crystalWeights[i]);
        }
        uint256 _totalWeight = _crystalWeightsCumsum[_crystalWeightsCumsum.length - 1];
        uint256 _weightRandomSum = 0;
        uint256 _weightSum = 0;

        for(i = 0; i < _crystalAmount; i++) {
            _weights[i] = _getRandom(100);
            _weightRandomSum = _weightRandomSum.add(_weights[i]);
        }

        for(i = 0; i < _crystalAmount; i++) {
            // Kind is decided randomly according to remaining crystal weights.
            // That means crystals of large quantity are chosen with high probability.
            _kinds[i] = _getFirstIndex(_getRandom(_totalWeight), _crystalWeightsCumsum);

            // Weight is decided randomly according to estimatedWeight.
            // EstimatedWeight is fixed (calculated in advance) in one mining.
            // EstimatedWeight is randomly divided into each of weight.
            // That means sum of weights is equal to EstimatedWeight.
            uint256 actualWeight = estimatedWeight.mul(_pkxAmount);
            _weights[i] = _weights[i].mul(actualWeight).div(_weightRandomSum);

            // Gene is decided randomly.
            _genes[i] = _generateGene();

            require(_weights[i] > 0);

            _tokenIds[i] = crystal.mint(_owner, _genes[i], _kinds[i], _weights[i]);

            crystalWeights[_kinds[i]] = crystalWeights[_kinds[i]].sub(_weights[i]);

            _weightSum = _weightSum.add(_weights[i]);
        }

        setEstimatedWeight(_weightSum);
        pickaxe.burn(msg.sender, _pkxAmount);

        emit MineCrystals(
        _owner,
        now,
        _tokenIds,
        _kinds,
        _weights,
        _genes
        );
    }

    // @dev meltCrystals consists of two basic operations.
    //      It burns old crystals and mint new crystal.
    //      The weight of new crystal is the same to total weight of bunred crystals.
    // @notice meltCrystals may have bugs. We will fix later.
    // @param uint256[] _tokenIds the token ids of crystals to be melt
    function meltCrystals(uint256[] _tokenIds) external onlyEOA {
        uint256 _length = _tokenIds.length;
        address _owner = msg.sender;

        require(2 <= _length && _length <= 10);

        uint256[] memory _kinds = new uint256[](_length);
        uint256 _weight;
        uint256 _totalWeight = 0;

        for(uint256 i = 0; i < _length; i++) {
            require(crystal.ownerOf(_tokenIds[i]) == _owner);
            (_kinds[i], _weight) = crystal.getCrystalKindWeight(_tokenIds[i]);
            if (i != 0) {
                require(_kinds[i] == _kinds[i - 1]);
            }

            _totalWeight = _totalWeight.add(_weight);
            crystal.burn(_owner, _tokenIds[i]);
        }

        uint256 _gene = _generateGene();
        uint256 _tokenId = crystal.mint(_owner, _gene, _kinds[0], _totalWeight);

        emit MeltCrystals(_owner, now, _tokenIds, _tokenId, _kinds[0], _totalWeight, _gene);
    }

    // @dev create exchange
    // @param uint256 _tokenId tokenId you want to exchange
    // @param uint256 _kind crystal kind you want to get
    // @param uint256 _weight minimum crystal weight you want to get
    function createExchange(uint256 _tokenId, uint256 _kind, uint256 _weight) external onlyEOA {
        ExchangeWrapper memory _ew = ExchangeWrapper({
            id: 0, // specify after
            owner: msg.sender,
            tokenId: _tokenId,
            kind: _kind,
            weight: _weight,
            createdAt: 0
            });

        CrystalWrapper memory _cw = getCrystalWrapper(msg.sender, _tokenId);

        require(crystal.ownerOf(_tokenId) == _cw.owner);
        require(_kind < 100);

        // escrow crystal to exchange contract
        crystal._transferFrom(_cw.owner, exchange, _tokenId);

        _ew.id = exchange.create(_ew.owner, _tokenId, _cw.gene, _cw.kind, _cw.weight, _ew.kind, _ew.weight, now);

        emit CreateExchange(_ew.id, _ew.owner, _ew.tokenId, _cw.gene, _cw.kind, _cw.weight, _ew.kind, _ew.weight, now);
    }

    function getCrystalWrapper(address _owner, uint256 _tokenId) internal returns(CrystalWrapper) {
        CrystalWrapper memory _cw;
        _cw.owner = _owner;
        _cw.tokenId = _tokenId;
        (_cw.gene, _cw.kind, _cw.weight) = crystal.getCrystalGeneKindWeight(_tokenId);
        return _cw;
    }

    // @dev cancel exchange
    // @param uint256 _id exchangeId you want to cancel
    function cancelExchange(uint256 _id) external onlyEOA {
        require(exchange.ownerOf(_id) == msg.sender);

        uint256 _tokenId = exchange.getTokenId(_id);

        CrystalWrapper memory _cw = getCrystalWrapper(msg.sender, _tokenId);

        // withdraw crystal from exchange contract
        crystal._transferFrom(exchange, _cw.owner, _cw.tokenId);

        exchange.remove(_id);

        emit CancelExchange(_id, _cw.owner, _cw.tokenId, _cw.kind, _cw.weight, now);
    }

    // @dev bid exchange
    // @param uint256 _exchangeId exchange id you want to bid
    // @param uint256 _tokenId token id of your crystal to be exchanged
    function bidExchange(uint256 _exchangeId, uint256 _tokenId) external onlyEOA {
        // exchange
        ExchangeWrapper memory _ew;
        _ew.id = _exchangeId;
        (_ew.owner, _ew.tokenId, _ew.kind, _ew.weight, _ew.createdAt) = exchange.getExchange(_ew.id); // check existence

        // crystal of exchanger
        CrystalWrapper memory _cwe = getCrystalWrapper(msg.sender, _tokenId);

        // crystal of creator of exchange
        CrystalWrapper memory _cwo = getCrystalWrapper(_ew.owner, _ew.tokenId);

        require(_cwe.owner != _ew.owner);
        require(_cwe.kind == _ew.kind);
        require(_cwe.weight >= _ew.weight);

        // transfer my crystal to owner of exchange
        crystal._transferFrom(_cwe.owner, _ew.owner, _cwe.tokenId);

        // transfer escrowed crystal to me.
        crystal._transferFrom(exchange, _cwe.owner, _ew.tokenId);

        exchange.remove(_ew.id);

        emit BidExchange(_ew.id, _ew.owner, _ew.tokenId, _cwo.gene, _cwo.kind, _cwo.weight, _cwe.owner, _cwe.tokenId, _cwe.kind, _cwe.weight, now);
    }

    // @dev get index when cumsum[i] exceeds _in first.
    // @param uint256 _min
    // @param uint256[] _sorted array is required to be sorted by ascending order
    function _getFirstIndex(uint256 _min, uint256[] _sorted) public pure returns(uint256) {
        for(uint256 i = 0; i < _sorted.length; i++) {
            if(_min < _sorted[i]) {
                return i;
            }
        }
        return _sorted.length - 1;
    }

    function _transferFromOwner(address _to, uint256 _value) internal {
        pickaxe.transferFromOwner(_to, _value);
    }

    function _generateGene() internal returns(uint256) {
        return _getRandom(~uint256(0));
    }

    function _getRandom(uint256 _max) public returns(uint256){
        bytes32 hash = keccak256(generator.generate());
        uint256 number = (uint256(hash) % _max) + 1;
        //emit RandomGenerated(number);
        return number;
    }

    // @dev change random generator
    // @param RandomGeneratorIF randomGenerator contract address
    function setRandomGenerator(RandomGeneratorIF _generator) external onlyOwner {
        generator = _generator;
    }
}