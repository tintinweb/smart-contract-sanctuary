pragma solidity ^0.4.18;

contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 _totalSupply);
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint _tokenId) external view returns (address _owner);
    function approve(address _to, uint _tokenId) external;
    function transferFrom(address _from, address _to, uint _tokenId) external;
    function transfer(address _to, uint _tokenId) external;
    
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    // Optional functions
    // function name() public view returns (string _name);
    // function symbol() public view returns (string _symbol);
    // function tokenOfOwnerByIndex(address _owner, uint _index) external view returns (uint _tokenId);
    // function tokenMetadata(uint _tokenId) public view returns (string _infoUrl);
}

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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;

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
    owner = newOwner;
  }

}

contract AccessControl is Ownable {
    
    bool public paused = false;
    
    modifier whenPaused {
        require(paused);
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }
    
    function unpause() external onlyOwner whenPaused {
        paused = false;
    }
    
}

contract DetailBase is AccessControl {
    
    event Create(address owner, uint256 detailId, uint256 dna);

    event Transfer(address from, address to, uint256 tokenId);

    struct Detail {
        uint256 dna;
        uint256 idParent;
        uint64 releaseTime;
    }

    Detail[] details;

    mapping (uint256 => address) public detailIndexToOwner;
    mapping (address => uint256) public ownershipTokenCount;
    mapping (uint256 => address) public detailIndexToApproved;

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        detailIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete detailIndexToApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }

    function createDetail(address _owner, uint256 _dna) internal whenNotPaused returns (uint) {
        Detail memory _detail = Detail(_dna, 0, uint64(now));
        uint256 newDetailId = details.push(_detail) - 1;
        require(newDetailId == uint256(uint32(newDetailId)));
        Create(_owner, newDetailId, _detail.dna);
        _transfer(0, _owner, newDetailId);

        return newDetailId;
    }

    function getDetail(uint _id) public view returns (uint256, uint256, uint64) {
        return (details[_id].dna, details[_id].idParent, details[_id].releaseTime);
    }
    
}

contract AssemblyBase is DetailBase {
        
    struct Assembly {
        uint256 idParent;
        uint256 dna;
        uint64 releaseTime;
        uint64 updateTime;
        uint64 startMiningTime;
        uint64[] spares;
        uint8 countMiningDetail;
        uint8 rang;
    }
    
    uint8[] private rangIndex = [
        3,
        4,
        5,
        6
    ];
    
    Assembly[] assemblys;
    
    mapping (uint256 => address) public assemblIndexToOwner;
    mapping (address => uint256) public ownershipAssemblyCount;
    mapping (uint256 => address) public robotIndexToApproved;
    
    function gatherDetails(uint64[] _arrIdDetails) public whenNotPaused returns (uint) {
        
        require(_arrIdDetails.length == 7);
        
        for (uint i = 0; i < _arrIdDetails.length; i++) {
            _checkDetail(_arrIdDetails[i], uint8(i+1));
        }
        
        Assembly memory _ass = Assembly(0, _makeDna(_arrIdDetails), uint64(now), uint64(now), 0, _arrIdDetails, 0,  _range(_arrIdDetails));
        
        uint256 newAssemblyId = assemblys.push(_ass) - 1;
        
        for (uint j = 0; j < _arrIdDetails.length; j++) {
            details[_arrIdDetails[j]].idParent = newAssemblyId;
        }
        
        assemblIndexToOwner[newAssemblyId] = msg.sender;
        ownershipAssemblyCount[msg.sender]++;
        
        return newAssemblyId;
    }
    
    function changeAssembly(uint _id, uint64[] _index, uint64[] _arrIdReplace) public whenNotPaused {
        require(_index.length == _arrIdReplace.length &&
                assemblIndexToOwner[_id] == msg.sender &&
                assemblys[_id].startMiningTime == 0);
        for (uint i = 0; i < _arrIdReplace.length; i++) {
            _checkDetail(_arrIdReplace[i], uint8(_index[i] + 1));
        }
        
        Assembly storage _assStorage = assemblys[_id];
        
        for (uint j = 0; j < _index.length; j++) {
            details[_assStorage.spares[_index[j]]].idParent = 0;
            _assStorage.spares[_index[j]] = _arrIdReplace[j];
            details[_arrIdReplace[j]].idParent = _id;
        }
        
        _assStorage.dna = _makeDna(_assStorage.spares);
        _assStorage.updateTime = uint64(now);
        _assStorage.rang = _range(_assStorage.spares);
    }
    
    function startMining(uint _id) public whenNotPaused returns(bool) {
        require(assemblIndexToOwner[_id] == msg.sender &&
                assemblys[_id].rang > 0 &&
                assemblys[_id].startMiningTime == 0);
        assemblys[_id].startMiningTime = uint64(now);
        return true;
    }
    
    function getAssembly(uint _id) public view returns (uint256, uint64, uint64, uint64, uint64[], uint8, uint8) {
        return (assemblys[_id].dna,
                assemblys[_id].releaseTime,
                assemblys[_id].updateTime,
                assemblys[_id].startMiningTime,
                assemblys[_id].spares,
                assemblys[_id].countMiningDetail,
                assemblys[_id].rang);
    }
    
    function getAllAssembly(address _owner) public view returns(uint[], uint[], uint[]) {
        uint[] memory resultIndex = new uint[](ownershipAssemblyCount[_owner]);
        uint[] memory resultDna = new uint[](ownershipAssemblyCount[_owner]);
        uint[] memory resultRang = new uint[](ownershipAssemblyCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < assemblys.length; i++) {
          if (assemblIndexToOwner[i] == _owner) {
            resultIndex[counter] = i; // index
            resultDna[counter] = assemblys[i].dna;
            resultRang[counter] = assemblys[i].rang;
            counter++;
          }
        }
        return (resultIndex, resultDna, resultRang);
    }
    
    function _checkDetail(uint _id, uint8 _mask) internal view {
        require(detailIndexToOwner[_id] == msg.sender
        && details[_id].idParent == 0
        && details[_id].dna / 1000 == _mask);
    }
    
    function _isCanMining(uint64[] memory _arrIdDetails) internal view returns(uint) {
        uint _ch = details[_arrIdDetails[i]].dna % 100;
        for (uint i = 1; i < _arrIdDetails.length; i++) {
            if (_ch != details[_arrIdDetails[i]].dna % 100) {
                return 0;
            }
        }
        return _ch;
    }
    
    function costRecharge(uint _robotId) public view returns(uint) {
        uint8 _rang = assemblys[_robotId].rang;
        if (_rang == 3) {
            return 0.015 ether;
        } else if (_rang == 4) {
            return 0.02 ether;
        } else if (_rang == 5) {
            return 0.025 ether;
        } else if (_rang == 6) {
            return 0.025 ether;
        }
    }
    
    function _range(uint64[] memory _arrIdDetails) internal view returns(uint8) {
        uint8 rang;
        uint _ch = _isCanMining(_arrIdDetails);
        if (_ch == 0) {
            rang = 0;
        } else if (_ch < 29) {
            rang = rangIndex[0];
        } else if (_ch > 28 && _ch < 37) {
            rang = rangIndex[1];
        } else if (_ch > 36 && _ch < 40) {
            rang = rangIndex[2];
        } else if (_ch < 39) {
            rang = rangIndex[3];
        }
        return rang;
    }
    
    function _makeDna(uint64[] memory _arrIdDetails) internal view returns(uint) {
        uint _dna = 0;
        for (uint i = 0; i < _arrIdDetails.length; i++) {
            _dna += details[_arrIdDetails[i]].dna * (10000 ** i);
        }
        return _dna;
    }
    
    function _transferRobot(address _from, address _to, uint256 _robotId) internal {
        ownershipAssemblyCount[_to]++;
        assemblIndexToOwner[_robotId] = _to;
        if (_from != address(0)) {
            ownershipAssemblyCount[_from]--;
            delete robotIndexToApproved[_robotId];
        }
        Transfer(_from, _to, _robotId);
    }
    
}

contract BaseContract is AssemblyBase, ERC721 {
    
    using SafeMath for uint;
    address wallet1;
    address wallet2;
    address wallet3;
    address wallet4;
    address wallet5;
    
    string public constant name = "Robots Crypto";
    string public constant symbol = "RC";

    uint[] dHead;
    uint[] dHousing;
    uint[] dLeftHand;
    uint[] dRightHand;
    uint[] dPelvic;
    uint[] dLeftLeg;
    uint[] dRightLeg;
    
    uint randNonce = 0;

    function BaseContract() public {
        Detail memory _detail = Detail(0, 0, 0);
        details.push(_detail);
        Assembly memory _ass = Assembly(0, 0, 0, 0, 0, new uint64[](0), 0, 0);
        assemblys.push(_ass);
    }

    function transferOnWallet() public payable {
        uint value84 = msg.value.mul(84).div(100);
        uint val79 = msg.value.mul(79).div(100);
        
        wallet1.transfer(msg.value - value84);
        wallet2.transfer(msg.value - val79);
        wallet3.transfer(msg.value - val79);
        wallet4.transfer(msg.value - val79);
        wallet5.transfer(msg.value - val79);
        
    }
    
    function setWallet(address _wall1, address _wall2, address _wall3, address _wall4, address _wall5) public onlyOwner {
        wallet1 = _wall1;
        wallet2 = _wall2;
        wallet3 = _wall3;
        wallet4 = _wall4;
        wallet5 = _wall5;
    }
    
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return detailIndexToOwner[_tokenId] == _claimant;
    }
    
    function _ownsRobot(address _claimant, uint256 _robotId) internal view returns (bool) {
        return assemblIndexToOwner[_robotId] == _claimant;
    }
    
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return detailIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        detailIndexToApproved[_tokenId] = _approved;
    }
    
    function _approveRobot(uint256 _robotId, address _approved) internal {
        robotIndexToApproved[_robotId] = _approved;
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }
    
    function balanceOfRobots(address _owner) public view returns (uint256 count) {
        return ownershipAssemblyCount[_owner];
    }

    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
    {
        require(_to != address(0));
        require(_to != address(this));
        _transfer(msg.sender, _to, _tokenId);
    }
    
    function transferRobot(
        address _to,
        uint256 _robotId
    )
        external
    {
        require(_to != address(0));
        require(_to != address(this));
        _transferRobot(msg.sender, _to, _robotId);
        uint64[] storage spares = assemblys[_robotId].spares;
        for (uint i = 0; i < spares.length; i++) {
            _transfer(msg.sender, _to, spares[i]);
        }
    }

    function approve(address _to, uint256 _tokenId) external {
        require(_owns(msg.sender, _tokenId));
        _approve(_tokenId, _to);
        Approval(msg.sender, _to, _tokenId);
    }
    
    function approveRobot(address _to, uint256 _robotId) external {
        require(_ownsRobot(msg.sender, _robotId));
        _approveRobot(_robotId, _to);
        Approval(msg.sender, _to, _robotId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        
    {
        require(_to != address(0));
        require(_owns(_from, _tokenId));
        _transfer(_from, _to, _tokenId);
    }
    
    function transferFromRobot(
        address _from,
        address _to,
        uint256 _robotId
    )
        external
        
    {
        require(_to != address(0));
        require(_ownsRobot(_from, _robotId));

        _transferRobot(_from, _to, _robotId);
        ownershipTokenCount[_from] -= 7;
    }

    function totalSupply() public view returns (uint) {
        return details.length - 1;
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = detailIndexToOwner[_tokenId];
        require(owner != address(0));
    }
    
    function ownerOfRobot(uint256 _robotId)
        external
        view
        returns (address owner)
    {
        owner = assemblIndexToOwner[_robotId];
        require(owner != address(0));
    }


    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalDetails = totalSupply();
            uint256 resultIndex = 0;
            uint256 detailId;

            for (detailId = 1; detailId <= totalDetails; detailId++) {
                if (detailIndexToOwner[detailId] == _owner) {
                    result[resultIndex] = detailId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
    
    modifier canMining(uint _id) {
        if (assemblys[_id].rang == 6) {
            require(assemblys[_id].countMiningDetail < (assemblys[_id].rang - 1));
        } else {
            require(assemblys[_id].countMiningDetail < assemblys[_id].rang);
        }
        _;
      }
    
    function getAllHead() public view returns (uint[]) {
        return dHead;
    }
    
    function getAllHousing() public view returns (uint[]) {
        return dHousing;
    }
    
    function getAllLeftHand() public view returns (uint[]) {
        return dLeftHand;
    }
    
    function getAllRightHand() public view returns (uint[]) {
        return dRightHand;
    }
    
    function getAllPelvic() public view returns (uint[]) {
        return dPelvic;
    }
    
    function getAllLeftLeg() public view returns (uint[]) {
        return dLeftLeg;
    }
    
    function getAllRightLeg() public view returns (uint[]) {
        return dRightLeg;
    }
    
}

contract MainContract is BaseContract {
    
    event BuyChestSuccess(uint count);
    
    mapping (address => uint256) public ownershipChestCount;
    
        modifier isMultiplePrice() {
        require((msg.value % 0.1 ether) == 0);
        _;
    }
    
    modifier isMinValue() {
        require(msg.value >= 0.1 ether);
        _;
    }
    
    function addOwnershipChest(address _owner, uint _num) external onlyOwner {
        ownershipChestCount[_owner] += _num;
    }
    
    function getMyChest(address _owner) external view returns(uint) {
        return ownershipChestCount[_owner];
    }
    
    function buyChest() public payable whenNotPaused isMinValue isMultiplePrice {
        transferOnWallet();
        uint tokens = msg.value.div(0.1 ether);
        ownershipChestCount[msg.sender] += tokens;
        BuyChestSuccess(tokens);
    }
    
    
    function getMiningDetail(uint _id) public canMining(_id) whenNotPaused returns(bool) {
        require(assemblIndexToOwner[_id] == msg.sender);
        if (assemblys[_id].startMiningTime + 259200 <= now) {
            if (assemblys[_id].rang == 6) {
                _generateDetail(40);
            } else {
                _generateDetail(28);
            }
            assemblys[_id].startMiningTime = uint64(now);
            assemblys[_id].countMiningDetail++;
            return true;
        }
        return false;
    }
    
    function getAllDetails(address _owner) public view returns(uint[], uint[]) {
        uint[] memory resultIndex = new uint[](ownershipTokenCount[_owner] - (ownershipAssemblyCount[_owner] * 7));
        uint[] memory resultDna = new uint[](ownershipTokenCount[_owner] - (ownershipAssemblyCount[_owner] * 7));
        uint counter = 0;
        for (uint i = 0; i < details.length; i++) {
          if (detailIndexToOwner[i] == _owner && details[i].idParent == 0) {
            resultIndex[counter] = i;
            resultDna[counter] = details[i].dna;
            counter++;
          }
        }
        return (resultIndex, resultDna);
    }
    
    function _generateDetail(uint _randLim) internal {
        uint _dna = randMod(7);
            
        uint256 newDetailId = createDetail(msg.sender, (_dna * 1000 + randMod(_randLim)));
                
        if (_dna == 1) {
            dHead.push(newDetailId);
        } else if (_dna == 2) {
            dHousing.push(newDetailId);
        } else if (_dna == 3) {
            dLeftHand.push(newDetailId);
        } else if (_dna == 4) {
            dRightHand.push(newDetailId);
        } else if (_dna == 5) {
            dPelvic.push(newDetailId);
        } else if (_dna == 6) {
            dLeftLeg.push(newDetailId);
        } else if (_dna == 7) {
            dRightLeg.push(newDetailId);
        }
    }
    
    function init(address _owner, uint _color) external onlyOwner {
        
        uint _dna = 1;
        
        for (uint i = 0; i < 7; i++) {
            
            uint256 newDetailId = createDetail(_owner, (_dna * 1000 + _color));
            
            if (_dna == 1) {
                dHead.push(newDetailId);
            } else if (_dna == 2) {
                dHousing.push(newDetailId);
            } else if (_dna == 3) {
                dLeftHand.push(newDetailId);
            } else if (_dna == 4) {
                dRightHand.push(newDetailId);
            } else if (_dna == 5) {
                dPelvic.push(newDetailId);
            } else if (_dna == 6) {
                dLeftLeg.push(newDetailId);
            } else if (_dna == 7) {
                dRightLeg.push(newDetailId);
            }
            _dna++;
        }
    }
    
    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;
        return (uint(keccak256(now, msg.sender, randNonce)) % _modulus) + 1;
    }
    
    function openChest() public whenNotPaused {
        require(ownershipChestCount[msg.sender] >= 1);
        for (uint i = 0; i < 5; i++) {
            _generateDetail(40);
        }
        ownershipChestCount[msg.sender]--;
    }
    
    function open5Chest() public whenNotPaused {
        require(ownershipChestCount[msg.sender] >= 5);
        for (uint i = 0; i < 5; i++) {
            openChest();
        }
    }
    
    function rechargeRobot(uint _robotId) external whenNotPaused payable {
        require(assemblIndexToOwner[_robotId] == msg.sender &&
                msg.value == costRecharge(_robotId));
        if (assemblys[_robotId].rang == 6) {
            require(assemblys[_robotId].countMiningDetail == (assemblys[_robotId].rang - 1));
        } else {
            require(assemblys[_robotId].countMiningDetail == assemblys[_robotId].rang);
        }   
        transferOnWallet();        
        assemblys[_robotId].countMiningDetail = 0;
        assemblys[_robotId].startMiningTime = 0;
    }
    
    
}