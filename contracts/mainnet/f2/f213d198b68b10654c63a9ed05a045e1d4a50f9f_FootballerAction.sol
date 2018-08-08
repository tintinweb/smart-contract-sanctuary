pragma solidity ^0.4.17;

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    // function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract FootballerAccessControl{

  ///@dev Emited when contract is upgraded
  event ContractUpgrade(address newContract);
  //The address of manager (the account or contracts) that can execute action within the role.
  address public managerAddress;

  ///@dev keeps track whether the contract is paused.
  bool public paused = false;

  function FootballerAccessControl() public {
    managerAddress = msg.sender;
  }

  /// @dev Access modifier for manager-only functionality
  modifier onlyManager() {
    require(msg.sender == managerAddress);
    _;
  }

  ///@dev assigns a new address to act as the Manager.Only available to the current Manager.
  function setManager(address _newManager) external onlyManager {
    require(_newManager != address(0));
    managerAddress = _newManager;
  }

  /*** Pausable functionality adapted from OpenZeppelin ***/

  /// @dev Modifier to allow actions only when the contract IS NOT paused
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /// @dev Modifier to allow actions only when the contract IS paused
  modifier whenPaused {
      require(paused);
      _;
  }

  /// @dev Called by manager to pause the contract. Used only when
  ///  a bug or exploit is detected and we need to limit damage.
  function pause() external onlyManager whenNotPaused {
    paused = true;
  }

  /// @dev Unpauses the smart contract. Can only be called by the manager,
  /// since one reason we may pause the contract is when manager accounts are compromised.
  /// @notice This is public rather than external so it can be called by derived contracts.
  function unpause() public onlyManager {
    // can&#39;t unpause if contract was upgraded
    paused = false;
  }

}

contract FootballerBase is FootballerAccessControl {
  using SafeMath for uint256;
  /*** events ***/
  event Create(address owner, uint footballerId);
  event Transfer(address _from, address _to, uint256 tokenId);

  uint private randNonce = 0;

  //球员/球星 属性
  struct footballer {
    uint price; //球员-价格 ， 球星-一口价 单位wei
    //球员的战斗属性
    uint defend; //防御
    uint attack; //进攻
    uint quality; //素质
  }

  //存球星和球员
  footballer[] public footballers;
  //将球员的id和球员的拥有者对应起来
  mapping (uint256 => address) public footballerToOwner;

  //记录拥有者有多少球员，在balanceOf（）内部使用来解决所有权计数
  mapping (address => uint256) public ownershipTokenCount;

  //从footballID 到 已批准调用transferFrom（）的地址的映射
  //每个球员只能有一个批准的地址。零值表示没有批准
  mapping (uint256 => address) public footballerToApproved;

  // 将特定球员的所有权 赋给 某个地址
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    footballerToApproved[_tokenId] = address(0);
    ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);
    footballerToOwner[_tokenId] = _to;
    ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);
    emit Transfer(_from, _to, _tokenId);
  }

  //管理员用于投放球星,和createStar函数一起使用，才能将球星完整信息保存起来
  function _createFootballerStar(uint _price,uint _defend,uint _attack, uint _quality) internal onlyManager returns(uint) {
      footballer memory _player = footballer({
        price:_price,
        defend:_defend,
        attack:_attack,
        quality:_quality
      });
      uint newFootballerId = footballers.push(_player) - 1;
      footballerToOwner[newFootballerId] = managerAddress;
      ownershipTokenCount[managerAddress] = ownershipTokenCount[managerAddress].add(1);
      //记录这个球星可以进行交易
      footballerToApproved[newFootballerId] = managerAddress;
      require(newFootballerId == uint256(uint32(newFootballerId)));
      emit Create(managerAddress, newFootballerId);
      return newFootballerId;
    }


    //用于当用户买卡包时，随机生成球员
    function createFootballer () internal returns (uint) {
        footballer memory _player = footballer({
          price: 0,
          defend: _randMod(20,80),
          attack: _randMod(20,80),
          quality: _randMod(20,80)
        });
        uint newFootballerId = footballers.push(_player) - 1;
      //  require(newFootballerId == uint256(uint32(newFootballerId)));
        footballerToOwner[newFootballerId] = msg.sender;
        ownershipTokenCount[msg.sender] =ownershipTokenCount[msg.sender].add(1);
        emit Create(msg.sender, newFootballerId);
        return newFootballerId;
    }

  // 生成一个从 _min 到 _max 范围内的随机数（不包括 _max）
  function _randMod(uint _min, uint _max) private returns(uint) {
      randNonce++;
      uint modulus = _max - _min;
      return uint(keccak256(now, msg.sender, randNonce)) % modulus + _min;
  }

}

contract FootballerOwnership is FootballerBase, ERC721 {
  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant name = "CyptoWorldCup";
  string public constant symbol = "CWC";


  function implementsERC721() public pure returns (bool) {
    return true;
  }

  //判断一个给定的地址是不是现在某个球员的拥有者
  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return footballerToOwner[_tokenId] == _claimant;
  }

  //判断一个给定的地址现在对于某个球员 是不是有 transferApproval
  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return footballerToApproved[_tokenId] == _claimant;
  }

  //给某地址的用户 对 球员有transfer的权利
  function _approve(uint256 _tokenId, address _approved) internal {
      footballerToApproved[_tokenId] = _approved;
  }

  //返回 owner 拥有的球员数
  function balanceOf(address _owner) public view returns (uint256 count) {
    return ownershipTokenCount[_owner];
  }

  //转移 球员 给 另一个地址
  function transfer(address _to, uint256 _tokenId) public whenNotPaused {
    require(_to != address(0));
    require(_to != address(this));
    //只能send自己的球员
    require(_owns(msg.sender, _tokenId));
    //重新分配所有权，清除待批准 approvals ，发出转移事件
    _transfer(msg.sender, _to, _tokenId);
  }

  //授予另一个地址通过transferFrom（）转移特定球员的权利。
  function approve(address _to, uint256 _tokenId) external whenNotPaused {
    //只有球员的拥有者才有资格决定要把这个权利给谁
    require(_owns(msg.sender, _tokenId));
    _approve(_tokenId, _to);
    emit Approval(msg.sender, _to, _tokenId);
  }

  //转让由另一个地址所拥有的球员，该地址之前已经获得所有者的转让批准
  function transferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused {
    require(_to != address(0));
    //不允许转让本合同以防止意外滥用。
    // 合约不应该拥有任何球员（除非 在创建球星之后并且在拍卖之前 非常短）。
    require(_to != address(this));
    require(_approvedFor(msg.sender, _tokenId));
    require(_owns(_from, _tokenId));
    //该函数定义在FootballerBase
    _transfer(_from, _to, _tokenId);
  }

  //返回现在一共有多少（球员+球星）
  function totalSupply() public view returns (uint) {
    return footballers.length;
  }

  //返回该特定球员的拥有者的地址
  function ownerOf(uint256 _tokenId) external view returns (address owner) {
    owner = footballerToOwner[_tokenId];
    require(owner != address(0));
  }

  //返回该地址的用户拥有的球员的id
  function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if(tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalpalyers = totalSupply();
      uint256 resultIndex = 0;
      uint256 footballerId;
      for (footballerId = 0; footballerId < totalpalyers; footballerId++) {
        if(footballerToOwner[footballerId] == _owner) {
          result[resultIndex] = footballerId;
          resultIndex++;
        }
      }
      return result;
    }
  }
}

contract FootballerAction is FootballerOwnership {
  //创建球星
  function createFootballerStar(uint _price,uint _defend,uint _attack, uint _quality) public returns(uint) {
      return _createFootballerStar(_price,_defend,_attack,_quality);
  }

  //抽卡包得球星
  function CardFootballers() public payable returns (uint) {
      uint price = 4000000000000 wei; //0.04 eth
      require(msg.value >= price);
      uint ballerCount = 14;
      uint newFootballerId = 0;
      for (uint i = 0; i < ballerCount; i++) {
         newFootballerId = createFootballer();
      }
      managerAddress.transfer(msg.value);
      return price;
  }

  function buyStar(uint footballerId,uint price) public payable  {
    require(msg.value >= price);
    //将球星的拥有权 交给 购买的用户
    address holder = footballerToApproved[footballerId];
    require(holder != address(0));
    _transfer(holder,msg.sender,footballerId);
    //给卖家转钱
    holder.transfer(msg.value);
  }

  //用户出售自己拥有的球员或球星
  function sell(uint footballerId,uint price) public returns(uint) {
    require(footballerToOwner[footballerId] == msg.sender);
    require(footballerToApproved[footballerId] == address(0));
    footballerToApproved[footballerId] = msg.sender;
    footballers[footballerId].price = price;
  }

  //显示球队
  function getTeamBallers(address actor) public view returns (uint[]) {
    uint len = footballers.length;
    uint count=0;
    for(uint i = 0; i < len; i++) {
        if(_owns(actor, i)){
          if(footballerToApproved[i] == address(0)){
            count++;
          }
       }
    }
    uint[] memory res = new uint256[](count);
    uint index = 0;
    for(i = 0; i < len; i++) {
      if(_owns(actor, i)){
          if(footballerToApproved[i] == address(0)){
            res[index] = i;
            index++;
          }
        }
    }
    return res;
  }

  //显示出售的球星+球员
  function getSellBallers() public view returns (uint[]) {
    uint len = footballers.length;
    uint count = 0;
    for(uint i = 0; i < len; i++) {
        if(footballerToApproved[i] != address(0)){
          count++;
        }
    }
    uint[] memory res = new uint256[](count);
    uint index = 0;
    for( i = 0; i < len; i++) {
        if(footballerToApproved[i] != address(0)){
          res[index] = i;
          index++;
        }
    }
    return res;
  }

  //获得球员+球星的总数量
  function getAllBaller() public view returns (uint) {
    uint len = totalSupply();
    return len;
  }

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