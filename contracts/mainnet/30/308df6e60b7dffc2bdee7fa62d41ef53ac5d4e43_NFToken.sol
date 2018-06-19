pragma solidity ^0.4.18;


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



contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}



contract ERC721Token is ERC721 {
  using SafeMath for uint256;

  // Total amount of tokens
  uint256 private totalTokens;

  // Mapping from token ID to owner
  mapping (uint256 => address) private tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private tokenApprovals;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) private ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private ownedTokensIndex;

  /**
  * @dev Guarantees msg.sender is owner of the given token
  * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
  * @dev Gets the total amount of tokens stored by the contract
  * @return uint256 representing the total amount of tokens
  */
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

  /**
  * @dev Gets the balance of the specified address
  * @param _owner address to query the balance of
  * @return uint256 representing the amount owned by the passed address
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

  /**
  * @dev Gets the list of tokens owned by a given address
  * @param _owner address to query the tokens of
  * @return uint256[] representing the list of tokens owned by the passed address
  */
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

  /**
  * @dev Gets the owner of the specified token ID
  * @param _tokenId uint256 ID of the token to query the owner of
  * @return owner address currently marked as the owner of the given token ID
  */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Gets the approved address to take ownership of a given token ID
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved to take ownership of the given token ID
   */
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
  * @dev Transfers the ownership of a given token ID to another address
  * @param _to address to receive the ownership of the given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

  /**
  * @dev Approves another address to claim for the ownership of the given token ID
  * @param _to address to be approved for the given token ID
  * @param _tokenId uint256 ID of the token to be approved
  */
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

  /**
  * @dev Claims the ownership of a given token ID
  * @param _tokenId uint256 ID of the token being claimed by the msg.sender
  */
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

  /**
  * @dev Mint token function
  * @param _to The address that will own the minted token
  * @param _tokenId uint256 ID of the token to be minted by the msg.sender
  */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

  /**
  * @dev Burns a specific token
  * @param _tokenId uint256 ID of the token being burned by the msg.sender
  */
  function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
    if (approvedFor(_tokenId) != 0) {
      clearApproval(msg.sender, _tokenId);
    }
    removeToken(msg.sender, _tokenId);
    Transfer(msg.sender, 0x0, _tokenId);
  }

  /**
   * @dev Tells whether the msg.sender is approved for the given token ID or not
   * This function is not private so it can be extended in further implementations like the operatable ERC721
   * @param _owner address of the owner to query the approval of
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return bool whether the msg.sender is approved for the given token ID or not
   */
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }

  /**
  * @dev Internal function to clear current approval and transfer the ownership of a given token ID
  * @param _from address which you want to send tokens from
  * @param _to address which you want to transfer the token to
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

  /**
  * @dev Internal function to clear current approval of a given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }

  /**
  * @dev Internal function to add a token ID to the list of a given address
  * @param _to address representing the new owner of the given token ID
  * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
  */
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

  /**
  * @dev Internal function to remove a token ID from the list of a given address
  * @param _from address representing the previous owner of the given token ID
  * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
  */
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }
}





contract CommonEth {

    //模式
    enum  Modes {LIVE, TEST}

    //合约当前模式
    Modes public mode = Modes.LIVE;

    //管理人员列表
    address internal ceoAddress;
    address internal cfoAddress;
    address internal cooAddress;


    address public newContractAddress;

    event ContractUpgrade(address newContract);

    function setNewAddress(address _v2Address) external onlyCEO {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }


    //构造
    function CommonEth() public {
        ceoAddress = msg.sender;
    }

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyStaff() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress || msg.sender == cfoAddress);
        _;
    }

    modifier onlyManger() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress || msg.sender == cfoAddress);
        _;
    }

    //合约状态检查：live状态、管理员或者测试人员不受限制
    modifier onlyLiveMode() {
        require(mode == Modes.LIVE || msg.sender == ceoAddress || msg.sender == cooAddress || msg.sender == cfoAddress);
        _;
    }

    //获取自己的身份
    function staffInfo() public view onlyStaff returns (bool ceo, bool coo, bool cfo, bool qa){
        return (msg.sender == ceoAddress, msg.sender == cooAddress, msg.sender == cfoAddress,false);
    }


    //进入测试模式
    function stopLive() public onlyCOO {
        mode = Modes.TEST;
    }

    //开启LIVE模式式
    function startLive() public onlyCOO {
        mode = Modes.LIVE;
    }

    function getMangers() public view onlyManger returns (address _ceoAddress, address _cooAddress, address _cfoAddress){
        return (ceoAddress, cooAddress, cfoAddress);
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) public onlyCEO {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }



}



contract NFToken is ERC721Token, CommonEth {
    //TOKEN结构
    struct TokenModel {
        uint id;//id
        string serial;//编号
        uint createTime;
        uint price;//当前价格
        uint lastTime;
        uint openTime;
    }

    //所有tokens
    mapping(uint => TokenModel)  tokens;
    mapping(string => uint)  idOfSerial;

    //每次交易后价格上涨
    uint RISE_RATE = 110;
    uint RISE_RATE_FAST = 150;
    //平台抽成
    uint8 SALE_FEE_RATE = 2;

    //瓜分活动投入
    uint CARVE_UP_INPUT = 0.01 ether;
    //瓜分票
    uint[10] carveUpTokens = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint8 carverUpIndex = 0;

    function NFToken() {
        setCFO(msg.sender);
        setCOO(msg.sender);
    }

    //默认方法
    function() external payable {

    }

    //交易分红
    event TransferBonus(address indexed _to, uint256 _tokenId, uint _bonus);
    //未交易卡更新
    event UnsoldUpdate(uint256 indexed _tokenId, uint price, uint openTime);
    //加入瓜分
    event JoinCarveUp(address indexed _account, uint _tokenId, uint _input);
    //瓜分分红
    event CarveUpBonus(address indexed _account, uint _tokenId, uint _bonus);
    //event CarveUpDone(uint _t, uint _t0, uint _t1, uint _t2, uint _t3, uint _t4, uint _t5, uint _t6, uint _t7, uint _t8, uint _t9);

    //加入瓜分活动
    function joinCarveUpTen(uint _tokenId) public payable onlyLiveMode onlyOwnerOf(_tokenId) returns (bool){
        //确认投入金额
        require(msg.value == CARVE_UP_INPUT);
        //确认 这张卡的本轮只用一次
        for (uint8 i = 0; i < carverUpIndex; i++) {
            require(carveUpTokens[i] != _tokenId);
        }
        //按当前索引进入队列
        carveUpTokens[carverUpIndex] = _tokenId;

        //日志&事件
        JoinCarveUp(msg.sender, _tokenId, msg.value);
        //第10人出现,结算了
        if (carverUpIndex % 10 == 9) {
            //索引归0
            carverUpIndex = 0;
            uint theLoserIndex = (now % 10 + (now / 10 % 10) + (now / 100 % 10) + (now / 1000 % 10)) % 10;
            for (uint8 j = 0; j < 10; j++) {
                if (j != theLoserIndex) {
                    uint bonus = CARVE_UP_INPUT * 110 / 100;
                    ownerOf(carveUpTokens[j]).transfer(bonus);
                    CarveUpBonus(ownerOf(carveUpTokens[j]), carveUpTokens[j], bonus);
                }else{
                    CarveUpBonus(ownerOf(carveUpTokens[j]), carveUpTokens[j], 0);
                }
            }
            //日志&事件
            //CarveUpDone(theLoserIndex, carveUpTokens[0], carveUpTokens[1], carveUpTokens[2], carveUpTokens[3], carveUpTokens[4], carveUpTokens[5], carveUpTokens[6], carveUpTokens[7], carveUpTokens[8], carveUpTokens[9]);
            carveUpTokens = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        } else {
            carverUpIndex++;
        }
        return true;
    }

    // 买入【其它人可以以等于或高于当前价格买入，交易过程平台收取交易价格抽成2%，每次交易后价格上涨】
    function buy(uint _id) public payable onlyLiveMode returns (bool){
        TokenModel storage token = tokens[_id];
        require(token.price != 0);
        require(token.openTime < now);
        //检查价格
        require(msg.value >= token.price);
        //付钱给出让转
        ownerOf(_id).transfer(token.price * (100 - 2 * SALE_FEE_RATE) / 100);
        //给用户分成
        if (totalSupply() > 1) {
            uint bonus = token.price * SALE_FEE_RATE / 100 / (totalSupply() - 1);
            for (uint i = 1; i <= totalSupply(); i++) {
                if (i != _id) {
                    ownerOf(i).transfer(bonus);
                    TransferBonus(ownerOf(i), i, bonus);
                }
            }
        }
        //转让
        clearApprovalAndTransfer(ownerOf(_id), msg.sender, _id);
        //价格上涨
        if (token.price < 1 ether) {
            token.price = token.price * RISE_RATE_FAST / 100;
        } else {
            token.price = token.price * RISE_RATE / 100;
        }
        token.lastTime = now;
        return true;
    }

    //上架
    function createByCOO(string serial, uint price, uint openTime) public onlyCOO returns (uint){
        uint currentTime = now;
        return __createNewToken(this, serial, currentTime, price, currentTime, openTime).id;
    }

    //更新未出售中的token
    function updateUnsold(string serial, uint _price, uint _openTime) public onlyCOO returns (bool){
        require(idOfSerial[serial] > 0);
        TokenModel storage token = tokens[idOfSerial[serial]];
        require(token.lastTime == token.createTime);
        token.price = _price;
        token.openTime = _openTime;
        UnsoldUpdate(token.id, token.price, token.openTime);
        return true;
    }

    //生成新的token
    function __createNewToken(address _to, string serial, uint createTime, uint price, uint lastTime, uint openTime) private returns (TokenModel){
        require(price > 0);
        require(idOfSerial[serial] == 0);
        uint id = totalSupply() + 1;
        idOfSerial[serial] = id;
        TokenModel memory s = TokenModel(id, serial, createTime, price, lastTime, openTime);
        tokens[id] = s;
        _mint(_to, id);
        return s;
    }

    //根据ID得详细
    function getTokenById(uint _id) public view returns (uint id, string serial, uint createTime, uint price, uint lastTime, uint openTime, address owner)
    {
        return (tokens[_id].id, tokens[_id].serial, tokens[_id].createTime, tokens[_id].price, tokens[_id].lastTime, tokens[_id].openTime, ownerOf(_id));
    }

    //获取瓜分游戏
    function getCarveUpTokens() public view returns (uint[10]){
        return carveUpTokens;
    }

    //财务提现
    function withdrawContractEther(uint withdrawAmount) public onlyCFO {
        uint256 balance = this.balance;
        require(balance - carverUpIndex * CARVE_UP_INPUT > withdrawAmount);
        cfoAddress.transfer(withdrawAmount);
    }

    //获取可提现金额
    function withdrawAbleEther() public view onlyCFO returns (uint){
        return this.balance - carverUpIndex * CARVE_UP_INPUT;
    }
}