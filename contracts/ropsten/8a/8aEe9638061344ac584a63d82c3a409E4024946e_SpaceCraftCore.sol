pragma solidity ^0.4.11;

// File: contracts/SpaceCraftAccessControl.sol

contract SpaceCraftAccessControl {

      // TODO: 계약을 새로 생성하는 경우 대비
      event ContractUpdate(address newContract);

      address ceoAddress;
      address gmAddress;

      address CfoAddress;

      bool paused = false;

      modifier onlyCEO() {
          require(msg.sender == ceoAddress || msg.sender == gmAddress);
          _;
      }

      // 운영을 위해, 운영 권한을 분리해둠
      function setGM(address _newGM) external onlyCEO {
          require(_newGM != address(0));
          //ceoAddress = _newCEO;
          gmAddress = _newGM;
      }

      //
      function setNewCFO(address _newCFO) external {

          require(CfoAddress == msg.sender);
          require(_newCFO != address(0));

          CfoAddress = _newCFO;
      }


      // 문제 발생에 대비하여.. pause 기능을 적용함
      modifier whenNotPaused() {
          require(!paused);
          _;
      }

      modifier whenPaused() {
          require(paused);
          _;
      }

      //
      function pause() external onlyCEO whenNotPaused {
          paused = true;
      }

      function unpause() public onlyCEO whenPaused {
          paused = false;
      }
  }

// File: contracts/RandomNumber.sol

contract RandomNumber {

    function _getRandom(uint256 _max, uint _seed) internal view returns (uint) {
        return uint256(keccak256(now, block.number, _seed))%_max;
    }

    function _getRandomNumber(uint _max, uint _seed) internal view returns
    (uint r0, uint r1, uint r2, uint r3, uint r4, uint r5, uint r6 ) {

        bytes32 s = keccak256(now, block.difficulty, block.number, _seed);

        bytes4[8] memory y = [bytes4(0), 0, 0, 0 ,0 ,0 ,0 ,0];
        assembly {
            mstore(y, s)
            mstore(add(y, 28), s)
            mstore(add(y, 56), s)
            mstore(add(y, 84), s)
            mstore(add(y, 112), s)
            mstore(add(y, 140), s)
            mstore(add(y, 168), s)
            mstore(add(y, 196), s)
        }

        r0 = uint256(y[0]) % _max;
        r1 = uint256(y[1]) % _max;
        r2 = uint256(y[2]) % _max;
        r3 = uint256(y[3]) % _max;
        r4 = uint256(y[4]) % _max;
        r5 = uint256(y[5]) % _max;
        r6 = uint256(y[6]) % _max;

    }

}

// File: contracts/DroneShop.sol

contract DroneShop is SpaceCraftAccessControl , RandomNumber {

    struct DroneProduct {
        string nameKey;
        uint price;

        uint explore;
        uint speed;
        uint attack;

        uint sense; // 관찰력 (세심함)
        uint challenge; // 모험적 -
        uint wariness; // 경계심 -
        uint curiosity; // 호기심
        uint loyalty; // 충성심
        uint kindness; // 친절함
    }

    DroneProduct[] public products;

    // 개발용 => 임시 드론상품 데이터 등록
    function DroneShop() public {

    }

    // 드론 상품을 추가합니다.
    function addProduct (
        string _nameKey,
        uint _price,
        uint _explore,
        uint _speed,
        uint _attack,
        uint _sense,
        uint _challenge,
        uint _wariness,
        uint _curiosity,
        uint _loyalty,
        uint _kindness
    )
        external
        onlyCEO
    {

        DroneProduct memory _newProduct = DroneProduct({
          nameKey:_nameKey,
          price:_price,
          explore:_explore,
          speed:_speed,
          attack:_attack,
          sense:_sense,
          challenge:_challenge,
          wariness:_wariness,
          curiosity:_curiosity,
          loyalty:_loyalty,
          kindness:_kindness
          });

        products.push(_newProduct);

    }

    // 드론 상품을 제거합니다.
    function updateProduct(
      uint256 _index,
      string _nameKey,
      uint _price,
      uint _explore,
      uint _speed,
      uint _attack,
      uint _sense,
      uint _challenge,
      uint _wariness,
      uint _curiosity,
      uint _loyalty,
      uint _kindness
      ) external onlyCEO {
        require(_index < products.length);

        DroneProduct storage product = products[_index];
        product.nameKey = _nameKey;
        product.price = _price;
        product.explore = _explore;
        product.speed = _speed;
        product.attack = _attack;
        product.sense = _sense;
        product.challenge = _challenge;
        product.wariness = _wariness;
        product.curiosity = _curiosity;
        product.loyalty = _loyalty;
        product.kindness = _kindness;

    }

    // 전체 드론 상품의 수를 확인합니다.
    function getTotalProduct() external view returns(uint256){
        return products.length;
    }

    // 드론 상품을 확인합니다.
    function getProduct (uint256 _index) external view returns (
        uint index,
        string nameKey,
        uint price,
        uint explore,
        uint speed,
        uint attack,
        int sense,
        int curiosity,
        int loyalty,
        int kindness,
        int challenge,
        int wariness
        )
    {

        require(_index < products.length);
        DroneProduct storage product = products[_index];

        index = _index;
        price = product.price;

        nameKey = product.nameKey;

        explore = product.explore;
        speed = product.speed;
        attack = product.attack;

        sense = int(product.sense);
        curiosity = int(product.curiosity);
        loyalty = int(product.loyalty);
        kindness = int(product.kindness);

        challenge = int(product.challenge);
        wariness = int(product.wariness);
    }

    // TODO: 함수를 merge 해야 합니다.
    function _getProductShopInfo (uint256 _index)
        internal
        view
        returns
    (
        uint price,
        uint sense,
        uint curiosity,
        uint loyalty,
        uint kindness,
        uint challenge,
        uint wariness
    ) {

        require(_index < products.length);
        DroneProduct storage product = products[_index];

        price = product.price;

        sense = product.sense;
        curiosity = product.curiosity;
        loyalty = product.loyalty;
        kindness = product.kindness;

        challenge = product.challenge;
        wariness = product.wariness;
    }

    // 드론 스피드를 리턴합니다.
    function _getDroneDefaultAbility(uint _index) internal view returns(uint explore, uint speed, uint attack){
        require(_index < products.length);
        DroneProduct storage product = products[_index];

        explore = product.explore;
        speed = product.speed;
        attack = product.attack;
    }
}

// File: contracts/ERC721.sol

contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);

    // 유저가 보유하고 있는 자산의 숫자
    function balanceOf(address _owner) public view returns (uint256 balance);
    // 해당 자산의 소유자 (주소)
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    // 자산에 대한 승인을 합니다. (자산 이전을 위한?)
    function approve(address _to, uint256 _tokenId) external;

    // 자산을 이동 합니다 (to 에게 자산을)
    function transfer(address _to, uint256 _tokenId) external;
    // 자산을 이동합니다. from -> to  자산을..
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId, uint64 _now);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    //function name() public view returns (string name);
    //function symbol() public view returns (string symbol);
    //function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    //function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

// File: contracts/DroneBase.sol

contract DroneBase is DroneShop, ERC721  {

    event BuyDrone(address _buyer, uint256 _droneId, uint _productId, uint64 _now);
    event ResultExplore(address _owner ,uint _droneId, uint _spaceId, uint result,uint resultValue,uint reserves,uint size,uint color,uint pType, uint alien, uint64 _now);

    // drone 정보를 유저별로 관리합니다.
    struct DroneList {
        uint droneId;
        bool ownership;
    }

    mapping (address => DroneList[]) public myDroneList;

    //
    struct Drone {

        uint productId;

        uint enchantExplore;
        uint enchantSpeed;
        uint enchantAttack;

        uint exploreResult;
        uint resultValue;
        uint resultNumber;
        uint alien;

        uint planetId;

        uint spaceId;

    }

    uint256 public secondsPerBlock = 15; // 블럭생성 주기에 따른 cooltime 계산용

    // 저장 관리 데이터
    uint totalDrone = 0; // 전체 드론수
    Drone[] public drones;

    mapping (uint256 => address) public droneIndexToOwner;

    // ERC721 보유자의 토큰(자산) 갯수, balanceOf() 를 통해 사용됨
    mapping (address => uint256) ownerDroneCount;

    /// ERC721 증명용. 0인 경우 아직 소유증명이 안된 경우임
    mapping (uint256 => address) public droneIndexToApproved;

    // 외부 계약과의 값 전달에 대한 증명용으로 사용됨
    mapping (uint256 => uint256) public transferValue;
    mapping (address => uint256) public transferValuebyAddr;

    //TODO: from 주소를 통해, 구매 혹은 획득 드론을 구분하도록 합니다.
    function _createDrone(address _owner, uint _productId, bool _isBuy, bool _fromAuction)
        internal returns(
          uint droneId
          )
        {

        Drone memory _newDrone = Drone({productId:uint8(_productId), enchantExplore:0, enchantSpeed:0, enchantAttack:0,
        exploreResult:0, resultValue:0, resultNumber:0, alien:0, planetId:0, spaceId:0});

        uint256 newDroneId = drones.push(_newDrone) - 1;

        // id값이 overflow 했는지를 체크합니다.
        require(newDroneId == uint256(uint32(newDroneId)));

        //
        if(_fromAuction == false)
           _transferDrone(address(0), _owner, newDroneId);

        if(_isBuy == true)
            BuyDrone(_owner, newDroneId, _productId, uint64(now)); // 실행 트렌젝션을 로드에 알려 별도에 관리토록 합니다.

        return newDroneId;
    }

    // 실제 드론을 넘김니다
    function _transferDrone(address _from, address _to, uint256 _droneId)
        internal
    {

        // 경매로 구매시..
        // 드론이 하나도 없는 경우, 무상 지급 드론을 제공해줍니다.
        if(_from != address(0) && ownerDroneCount[_to] == 0){

            uint newDroneId = _createDrone(_to, 0, false, true);

            //
            ownerDroneCount[_to]++;
            droneIndexToOwner[newDroneId] = _to; // 드론의 주인을 변경합니다.
        }

        //
        ownerDroneCount[_to]++;
        droneIndexToOwner[_droneId] = _to; // 드론의 주인을 변경합니다.

        // 주인이 없는 드론일 수 있으니..
        if (_from != address(0)) {
            // 기존 주인의 드론 소유 숫자를 줄입니다.
            // 여기 좀 이상한데? _from 이 계약일 수 있는데...
            if(ownerDroneCount[_from] > 0)
                ownerDroneCount[_from]--;

            // 소유권이전을 위해 설정한 소유권 변경대상 주소 내용을 폐기합니다.
            delete droneIndexToApproved[_droneId]; // error 발생
            //droneIndexToApproved[_droneId] = address(0);

        }

        // 실행 트렌젝션을 로드에 알립니다
        Transfer(_from, _to, _droneId, uint64(now));
    }

    // 신규 블럭의 생성 시간을 설정합니다. (waiting 시간으로 활용합니다.)
    function setSecondsPerBlock(uint256 secs) external onlyCEO {
        secondsPerBlock = secs;
    }

    // 전체 생성된 드론의 수를 확인합니다.
    function getTotalDrone() external view returns(uint total){
        return drones.length;
    }

    // 드론의 능력치를 계산합니다.
    function _getDroneAbility(uint droneId)
        public
        view
        returns(
        uint productId,
        uint speedEnchant,
        uint speed,
        uint exploreEnchant,
        uint explore,
        uint attackEnchant,
        uint attack,
        int enchantSum
    ) {

        uint e;
        uint s;
        uint a;

        Drone storage droneInfo = drones[droneId];

        (e,s,a) = _getDroneDefaultAbility(droneInfo.productId);

        productId = droneInfo.productId;

        explore = e + e * droneInfo.enchantExplore * 2 / 100;
        exploreEnchant = droneInfo.enchantExplore;

        speed = s + s * droneInfo.enchantSpeed * 2 / 100;
        speedEnchant = droneInfo.enchantSpeed;

        attack = a + a * droneInfo.enchantAttack * 2 / 100;
        attackEnchant = droneInfo.enchantAttack;

        enchantSum = int(droneInfo.enchantExplore + droneInfo.enchantSpeed + droneInfo.enchantAttack);
    }

    // 드론 소유자를 확인합니다.
    function isMyDrone(uint _droneId) external view
        returns (
        bool _isMine, uint _droneAmount
    ) {

        if (droneIndexToOwner[_droneId] == msg.sender) {
            _isMine = true;
        }else{
            _isMine = false;
        }

        _droneAmount = ownerDroneCount[msg.sender];
    }

    // 발견한 행성의 매장량을 확인합니다.
    function getTransferValue(uint _droneId) external view returns (uint ){
        return transferValue[_droneId];
    }

    // 행성을 생성하면 바로, 0으로 셋팅합니다.
    function clearTransferValue(uint _droneId) external {
        transferValue[_droneId] = 0;
    }

    //  주소 기준으로 전달값을 확인합니다.
    function getTransferValuebyArrd(address _onwer) external view returns (uint){
        return transferValuebyAddr[_onwer];
    }

    function clearTransferValueby(address _onwer) external {
        transferValuebyAddr[_onwer] = 0;
    }
}

// File: contracts/DroneOwnerShip.sol

contract DroneOwnerShip is DroneBase{

    // ERC721 을 위해 정의하지만, 사용하진 않습니다.
    string public constant name = "SpaceDrone";
    string public constant symbol = "SD";

    // ERC721, ERC165에 대한 InterfaceSignature
    bytes4 constant InterfaceSignature_ERC165 = bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

    bytes4 constant InterfaceSignature_ERC721 =
          bytes4(keccak256(&#39;name()&#39;)) ^
          bytes4(keccak256(&#39;symbol()&#39;)) ^
          bytes4(keccak256(&#39;totalSupply()&#39;)) ^
          bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
          bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
          bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
          bytes4(keccak256(&#39;transfer(address,uint256)&#39;)) ^
          bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
          bytes4(keccak256(&#39;tokensOfOwner(address)&#39;)) ^
          bytes4(keccak256(&#39;tokenMetadata(uint256,string)&#39;));

    // ERC-721 인터페이스를 적용하고 있는지 확인합니다.
    // ERC-165 and ERC-721.
    function supportsInterface(bytes4 _interfaceId) external view returns(bool){
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));
        return ((_interfaceId == InterfaceSignature_ERC165) || (_interfaceId == InterfaceSignature_ERC721));
    }

    // 자산(드론)의 소유자를 확인합니다.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return droneIndexToOwner[_tokenId] == _claimant;
    }

    // 경매 진행을 위해, 경매 요청 계약의 주소를 넣어 둡니다. (향후, 별도 자산 경매에 대한 고려입니다)
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return droneIndexToApproved[_tokenId] == _claimant;
    }

    // 해당 드론이 교환을 위한 승인 단계의 대상으로 "경매" 지정
    function _approve(uint256 _tokenId, address _approved) internal {
        droneIndexToApproved[_tokenId] = _approved;
    }

    /// Required for ERC-721 compliance
    // 소유자가 보유한 자산의 수를 확인합니다.
    function balanceOf(address _owner) public view returns (uint256 count) {

        if(ownerDroneCount[_owner] == 0)
            return 0;
        return ownerDroneCount[_owner];
    }

    // Required for ERC-721 compliance.
    // 입찰 성공에 따라, 자산(드론)을 구매자에게 전달합니다.
    function transfer(address _to, uint256 _tokenId) external whenNotPaused {

        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        require(_to != address(this));

        // TODO: 계약 자체에 전달하지 못하도록 합니다.
        //require(_to != address( .. ));

        // 자신 소유의 자산만 이동 시킬 수 있습니다 (굳이 추가 확인할 필요가 없습니다)
        require(_owns(msg.sender, _tokenId));

        // 자산(드론)을 이동시킵니다
        _transferDrone(msg.sender, _to, _tokenId);
    }

    /// Required for ERC-721 compliance.
    function approve(address _to, uint256 _tokenId) external whenNotPaused {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event. -> ERC721.sol
        Approval(msg.sender, _to, _tokenId);
    }

    /// For ERC-721 compliance.
    /// 1) 경매 계약의 escrow 요청으로.. 소유권을 경매 계약으로 넘긴다
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        require(_to != address(this));

        // 소유권 변화 요청의 주체를 확인하고 (경매 계약주소 확인)
        require(_approvedFor(msg.sender, _tokenId));

        // 소유권이 있는지 여부를 확인
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transferDrone(_from, _to, _tokenId);
    }

    // For ERC-721 compliance.
    // 전체 드론의 수를 확인합니다.
    function totalSupply() public view returns (uint) {
        return drones.length - 1;
    }

    /// For ERC-721 compliance.
    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        owner = droneIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    /// 특정 소유수가 보유한 드론을 리턴합니다.
    /// 해당 코드는 게스 소모가 큰 함수로, web3 를 통해서만 호출하고, 스마트 계약 내부에선 호출하지 말아야 합니다.
    /// For ERC-721 compliance.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalDrones = totalSupply();
            uint256 resultIndex = 0;

            uint256 droneId;
            for (droneId = 1; droneId <= totalDrones; droneId++) {
                if (droneIndexToOwner[droneId] == _owner) {
                    result[resultIndex] = droneId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

}

// File: contracts/ClockAuctionBase.sol

contract ClockAuctionBase {

    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
    }

    // Reference to contract tracking NFT ownership
    ERC721 public nonFungibleContract;

    // 경매 수수료
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;

    // 경매 정보에 대한 맵핑
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration, address seller, uint64 startedAt);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner, address seller, uint64 _now);
    event AuctionCancelled(uint256 tokenId, uint64 _now);

    /// 드론의 소유자를 확인합니다.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /// 실제 메인 계약의 ERC721이 동작합니다
    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    /// 입찰이 성공하여, 자산(드론)을 구매자에게 전달합니다.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    /// 경매에 등록합니다.
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        // 최소 경매 남은 시간이 1일 이상이어야 합니다.
        require(_auction.duration >= 1);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration),
            _auction.seller,
            uint64(_auction.startedAt)
        );
    }

    // 경매를 취소합니다.
    // 경매 정보를 제거하고, 자산(드론)을 판매자에게 전달합니다.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId, uint64(now));
    }

    // 입찰을 진행합니다. 소유권이 경매 주소에 있는 것만 입찰 할 수 있도록 합니다.
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        //
        Auction storage auction = tokenIdToAuction[_tokenId];

        // 실시간으로 진행되는 상황에서, 블럭 체인에 값이 정상 적용된 것을 확인합니다.
        // 순간적으로 생성시 0의 값을 가질 수 있어, 이에 대한 확인입니다.
        require(_isOnAuction(auction));

        // 현재 가격보다 높은 가격으로 입찰하는지 확인합니다.
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        // 자산(드론)의 판매자를 확인합니다.
        address seller = auction.seller;

        // 입찰 완료로 경매 정보를 삭제합니다. (중복 입찰을 막기위해 정보부터 삭제합니다.)
        _removeAuction(_tokenId);

        // 입찰 금액을 판매자에게 송금합니다.
        if (price > 0) {

            // 경매 수수료를 차감합니다.
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

            //
            seller.transfer(sellerProceeds);
        }

        // 입찰 금액이 현재가보다 높은 경우, 차액을 반환해 줍니다.
        uint256 bidExcess = _bidAmount - price;

        //
        msg.sender.transfer(bidExcess);

        // 경매 성공을 알린다
        AuctionSuccessful(_tokenId, price, msg.sender, seller, uint64(now));

        return price;
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /// 경매를 위한 시작가가 설정되었는지 확인합니다.
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    // 현재 경매 물건의 가격을 확인힙니다.
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 hoursPassed = 0;

        //
        if (now > _auction.startedAt) {
            hoursPassed = (now - _auction.startedAt) / 3600;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            hoursPassed
        );
    }

    /// 지난 시간에 따라 현재 가격을 계산합니다.
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _hoursPassed
    )
        internal
        pure
        returns (uint256)
    {
        //
        if (_hoursPassed / 24 >= _duration) {
            // 시간이 오버되어 최종가격입니다
            return _endingPrice;
        } else {

            // 최종가격에서 최초가격의 차를 구하여(-값), 현재까지 지난 시간만큼을 차감합니다.
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            int256 currentPriceChange = totalPriceChange * int256(_hoursPassed) / int256(_duration * 24);

            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    // 경매 수수료를 계산합니다.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }

    /// 유저가 등록한 경매 정보를 리턴합니다.
    /// 해당 코드는 게스 소모가 큰 함수로, web3 를 통해서만 호출하고, 스마트 계약 내부에선 호출하지 말아야 합니다.
    function getMyAllAuction(address _adr) external view
    returns (
      uint256[] ownerAuctions
    ) {

        require(address(0) == _adr);

        uint256 totalItems = nonFungibleContract.totalSupply();

        if (totalItems == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory tResult = new uint256[](totalItems);
            uint256 resultIndex = 0;

            uint256 droneId;
            for (droneId = 0; droneId <= totalItems; droneId++) {
                if (tokenIdToAuction[droneId].seller == _adr) {
                    tResult[resultIndex] = droneId;
                    resultIndex++;
                }
            }

            uint256 i;
            uint256[] memory result = new uint256[](resultIndex);
            for(i = 0; i < resultIndex; i++){
                result[i] = tResult[i];
            }

            return result;
        }

    }
}

// File: contracts/ClockAuction.sol

contract ClockAuction is SpaceCraftAccessControl, ClockAuctionBase {

    /// @dev The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256(&#39;name()&#39;)) ^
        bytes4(keccak256(&#39;symbol()&#39;)) ^
        bytes4(keccak256(&#39;totalSupply()&#39;)) ^
        bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
        bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
        bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;transfer(address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;tokensOfOwner(address)&#39;)) ^
        bytes4(keccak256(&#39;tokenMetadata(uint256,string)&#39;));

    // 메인 계약의 주소를 셋팅하고, 경매 수수료를 설정합니다.
    function setClockAuction(address _nftAddress, uint256 _cut)
        public
        onlyCEO
    {
        require(_cut <= 10000);

        // 경매 수수료 입니다. (n / 10000)
        ownerCut = _cut;

        // 메인 계약에 해당하는 ERC721 인터페이스 생성
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

    // 잔액을 송금합니다.
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require( msg.sender == ceoAddress || msg.sender == gmAddress || msg.sender == nftAddress );

        // 전송 실패 여부
        bool res = nftAddress.send(this.balance);
    }

    // 소유권을 경매 계약으로 넘겨 escrow를 적용하고, 경매 정보를 생성합니다.
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
        whenNotPaused
    {
        require(msg.sender == address(nonFungibleContract));

        //
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        //
        _escrow(msg.sender, _tokenId);

        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    // 외부 입찰에서 사용할 수 있습니다.
    function bid(uint256 _tokenId) external payable whenNotPaused {
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    // 판자가는 경매를 취소하고, 자산(드론)을 판매자에게 전달합니다.
    function cancelAuction(uint256 _tokenId)
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    // 서비스를 중지하고, 관리자가 강제로 경매를 중지시킵니다.
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyCEO
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    /// 현재 등록된 경매 물건의 정보를 확인합니다.
    function getAuction(uint256 _tokenId)
        external
        view
        returns (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    /// 현재 가격을 확인합니다.
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}

// File: contracts/SaleClockAuction.sol

contract SaleClockAuction is ClockAuction {

    function SaleClockAuction() public {
        paused = false;
        ceoAddress = msg.sender;
        gmAddress = msg.sender;

        CfoAddress = msg.sender;

    }

    /// 경매에 드론을 등록합니다. 메인 계약에서만 호출 할 수 있도록 합니다.
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {

        // 내부 계산의 편의를 위해 사전에 값들을 점검합니다.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));

        // 물건(드론)의 소유를 계약주소로 변경합니다.
        _escrow(_seller, _tokenId);

        // 경매 정보를 등록합니다.
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    // 입찰을 진행합니다. 성공한 경우, 자산(드론)을 구매자에게 전달하고
    // 판매대금을 지급합니다.
    function bid(uint256 _tokenId) external payable {
        // 자산(드론) 물건에 입찰을 진행합니다.
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);

        // 자산을 구매자에게 전달합니다.
        _transfer(msg.sender, _tokenId);

    }

}

// File: contracts/DroneAuction.sol

contract DroneAuction is DroneOwnerShip {

    // 경매를 위한 계약.. 지정
    SaleClockAuction public saleAuction;

    // 경매 계약 주소를 셋팅합니다
    function setSaleAuctionAddress(address _address) public onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        // 경매 계약
        saleAuction = candidateContract;
    }

    // 경매를 생성합니다.
    function createSaleAuction( uint256 _droneId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration ) public  whenNotPaused
    {
        // 0번 드론은 전달할 수 없습니다.
        require(_droneId != 0);

        // 최소 2개 이상의 드론을 소요해야 합니다.
        require(ownerDroneCount[msg.sender] > 1);

        // 경매에 올리기 전에 드론 소유자인지 확인합니다.
        require(_owns(msg.sender, _droneId));

        // 해당 드론을 경매에 올렸음을 설정(지정))합니다. 소유권 변화는 없습니다.
        // droneId 에 saleAuction address 를 넣어둡니다.
        // droneIndexToApproved[_droneId] = address;
        _approve(_droneId, address(saleAuction));

        // 경매 정보를 경매 계약에 생성하고, 소유권을 경매계약으로 이전합니다. (escrow)
        saleAuction.createAuction( _droneId, _startingPrice, _endingPrice, _duration, msg.sender );
    }

    // 경매 계약의 잔액을 송금합니다
    function withdrawAuctionBalances() external onlyCEO {
        saleAuction.withdrawBalance();
    }


}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: contracts/ExplorePanel.sol

contract GameEngineInterface{
    function getSpaceInfo(uint _index) external view returns (string _key, bool _isService, uint _price, uint _distance) {}
    function getExploreResult(uint _spaceId, uint _droneId) external view returns(uint result, uint resultValue, uint resultNumber){}
    function discoverNewPlanet(uint _spaceId, uint _droneId, bool _isBonus) external view returns (uint sizeIndex, uint colorIndex, uint typeIndex, uint freserves) {}
}

contract GameCenterInterface{
    function exchangeHelenium(uint amount, address _owner) external returns (uint cash){}
    function createPlanet(uint _droneId, address _owner, uint _size, uint _color, uint _pType, uint _reserves, uint _spaceId) external returns(uint planetId){}
    function AddDroneItem(address _owner, uint _itemIndex, uint _amount) external {}
    function AddMaterial(address _owner, uint _itemIndex, uint _amount) external {}
    function AddHelenium(address _owner, uint _amount) external {}
    function subDroneItem(address _owner, uint _itemIndex, uint _amount) external {}
    function deposit() payable returns ( bool _success) {}
    function getJackPotInfo() external returns (uint _fundRate, uint _alienJackpotProbability, uint _exchangeJackpotProbability){}
}

contract JackPotInterface{
    //function getJackPotInfo() external returns (uint _fundRate, uint _alienJackpotProbability, uint _exchangeJackpotProbability){}
    function winJackPot(address _winnerAddr, string _code, uint _rate) external returns (uint _winPrize) {}
    function depositJackPot() payable returns ( bool _success ) {}
}

contract ExplorePanel is DroneAuction {

    //
    using SafeMath for *;

    GameEngineInterface public engine;
    GameCenterInterface public gameCenter;
    JackPotInterface public jackPot;

    address jackpotAddr;

    // 탐사 결과를 확인합니다. gas: 700,000
    function checkExplore(uint _droneId, uint _spaceId) payable external {

        // 탐사 연료 가격 징수
        uint price;
        (,,price,) = engine.getSpaceInfo(_spaceId);
        require( price == msg.value);

        //
        uint droneId = _droneId;

        // 유저가 드론을 소유하고 있는지 확인하고, 소유전이면 새드론을 지급합니다.
        if(ownerDroneCount[msg.sender] == 0){
            droneId = _createDrone(msg.sender, 0, false, false);
        }

        // 드론 소유 확인
        require(droneIndexToOwner[droneId] == msg.sender);

        // 잭팟적립
        uint jackpot;
        (jackpot,,) = gameCenter.getJackPotInfo(); //jackPot.getJackPotInfo();

        jackpot = msg.value.mul(jackpot).div(10000);
        if(this.balance > jackpot){
            jackPot.depositJackPot.value(jackpot)();
        }

        // 잔액을 모두 게임센터로 보냅니다.
        gameCenter.deposit.value(this.balance)();

        //
        uint size;
        uint color;
        uint ptype;
        uint reserves;
        uint result;
        uint resultValue;

        //
        Drone storage _droneInfo = drones[droneId];

        // 우주셋팅
        _droneInfo.spaceId = _spaceId;

        // 1차 결과
        //GameEngineInterface engine = GameEngineInterface(gameEngineAddress);
        (result, resultValue, reserves) = engine.getExploreResult(_droneInfo.spaceId, droneId);

        uint r = _getRandom(101, result); // 랜덤 강화 아이템 용

        //
        _droneInfo.alien = 0;

        // 우호 외계인 조우
        if(result == 224 || result == 225 || result == 226 || result == 227 || result == 228){
            _droneInfo.alien = r % 100 + 1;
        }

        // 우호 외계인 조우
        if(result == 2291 || result == 2292 || result == 2293 || result == 2294 || result == 2295){
            _droneInfo.alien = r % 100 + 1;
        }

        // 탐사 결과
        if(result == 1) {
            // 행성발견 : 소박, 중박, 대박 처리 : gas 37589, 20447
            (size, color, ptype, reserves) = engine.discoverNewPlanet(_droneInfo.spaceId, droneId, false);

            transferValue[droneId] = reserves;

            // 유저에게 행성을 지급합니다. // 198491, 179207
            _droneInfo.planetId = gameCenter.createPlanet(droneId, msg.sender, size, color, ptype, reserves, _droneInfo.spaceId);

        } else if( result == 221 || result == 224){
            // 강화 아이템 발견
            // 아이템은 0 ~ 11
            // resultValue = r % 12;
            // droneItems[0] - exploreItem,	droneItems[1] - speedItem, droneItems[2] - attackItem
            _droneInfo.resultNumber = r % 3;

            // 0 - explore, 1 - speed, 2 - attack
            if(_droneInfo.resultNumber == 0 && _droneInfo.enchantExplore == 50){
                _droneInfo.resultNumber = 10;
            }else if(_droneInfo.resultNumber == 1 && _droneInfo.enchantSpeed == 50){
                _droneInfo.resultNumber = 11;
            }else if(_droneInfo.resultNumber == 2 && _droneInfo.enchantAttack == 50){
                _droneInfo.resultNumber = 12;
            }else if(_droneInfo.resultNumber == 0 && _droneInfo.enchantExplore < 50){
                _droneInfo.enchantExplore++;
            }else if(_droneInfo.resultNumber == 1 && _droneInfo.enchantSpeed < 50){
                _droneInfo.enchantSpeed++;
            }else if(_droneInfo.resultNumber == 2 && _droneInfo.enchantAttack < 50){
                _droneInfo.enchantAttack++;
            }

        } else if( result == 225 ) {
            // 드론을 선물합니다.
            r = r % (products.length - 1);
            //
            _droneInfo.resultNumber = r;
            // 선물할 드론을 고정된 값으로 전달합니다.
            _createDrone(msg.sender, r, false, false);

        } else if (result == 226) {

            // 광석을 획득했습니다.
            // 광석의 수는 100 ~ 1000 개 사이입니다.
            price = _getRandom(900, r);
            price = price + 100;
            transferValuebyAddr[msg.sender] = price; // 100 ~ 1000

            _droneInfo.resultNumber = r % 3;
            gameCenter.AddMaterial( msg.sender, r % 3, price);

        } else if (result == 227) {
            // 외계인 행성 추가
            (size, color, ptype, reserves) = engine.discoverNewPlanet(_droneInfo.spaceId, droneId, true);

            transferValue[droneId] = reserves;

            // 유저에게 행성을 지급합니다.
            _droneInfo.planetId = gameCenter.createPlanet(droneId, msg.sender, size, color, ptype, reserves, _droneInfo.spaceId);
        } else if (result == 2232){

            // 잭팟을 처리합니다.
            //(uint _fundRate, uint _alienJackpotProbability, uint _exchangeJackpotProbability)
            jackpot = 0;
            (,jackpot,) = gameCenter.getJackPotInfo(); //jackPot.getJackPotInfo();

            r = _getRandom(10000, result);

            if( jackpot > r ){
                _droneInfo.resultNumber = 0;

                _droneInfo.resultNumber = _winJackPot(msg.sender, "SC_EXPLORE");

                // 젝팟 당첨으로 변경
                result = 777;
            }else{
                // 헬레니움을 바로 추가해줍니다.
                _droneInfo.resultNumber = reserves;

                transferValuebyAddr[msg.sender] = reserves;
                gameCenter.AddHelenium( msg.sender, reserves);
            }

        } else if (result == 228 || result == 2295 || result == 230 ){
            // 우호 외계인의 스토리를 진행합니다. 그냥 이야기, 중립 이야기,
            _droneInfo.resultNumber = reserves;
            reserves = 0;
        }

        // 추가 탐사 관련
        if(result == 2294 || result == 2312) {
            // 외계인 행성 추가
            (size, color, ptype, reserves) = engine.discoverNewPlanet(_droneInfo.spaceId, droneId, true);

            //
            transferValue[_droneId] = reserves;

            // 유저에게 행성을 지급합니다.
            _droneInfo.planetId = gameCenter.createPlanet(droneId, msg.sender, size, color, ptype, reserves, _droneInfo.spaceId);
        } else if( result == 2291){
            // 강화 아이템 발견
            // 아이템은 0 ~ 11
            _droneInfo.resultNumber = r % 3;

            // 0 - explore, 1 - speed, 2 - attack
            if(_droneInfo.resultNumber == 0 && _droneInfo.enchantExplore == 50){
                _droneInfo.resultNumber = 10;
            }else if(_droneInfo.resultNumber == 1 && _droneInfo.enchantSpeed == 50){
                _droneInfo.resultNumber = 11;
            }else if(_droneInfo.resultNumber == 2 && _droneInfo.enchantAttack == 50){
                _droneInfo.resultNumber = 12;
            }else if(_droneInfo.resultNumber == 0 && _droneInfo.enchantExplore < 50){
                _droneInfo.enchantExplore++;
            }else if(_droneInfo.resultNumber == 1 && _droneInfo.enchantSpeed < 50){
                _droneInfo.enchantSpeed++;
            }else if(_droneInfo.resultNumber == 2 && _droneInfo.enchantAttack < 50){
                _droneInfo.enchantAttack++;
            }

        } else if( result == 2292 ) {
            // 드론을 선물합니다.
            r = r % (products.length - 1);
            //
            _droneInfo.resultNumber = r;

            _createDrone(msg.sender, r, false, false);
        } else if (result == 2293) {

            // 광석을 획득했습니다.
            // 광석의 수는 100 ~ 1000 개 사이입니다.
            price = _getRandom(900, r);
            price = price + 100;
            transferValuebyAddr[msg.sender] = price; // 100 ~ 1000

            gameCenter.AddMaterial( msg.sender, price % 3, price);
            _droneInfo.resultNumber = price;

            reserves = 0;
        }

        // 결과를 마킹합니다.
        _droneInfo.exploreResult = result;
        _droneInfo.resultValue = resultValue;

        //
        ResultExplore(msg.sender, droneId, _droneInfo.spaceId, result, resultValue, reserves, size, color, ptype, _droneInfo.alien, uint64(now));

    }

    // jackPot 50%
    function _winJackPot(address _addr, string _code) internal
        returns (uint jackpotWin)
    {
        // 적립금의 50%를 지급합니다.
        // 당첨자, 타입, 전체 젝팟금액 중 배당률
        return jackPot.winJackPot(_addr, _code, 5000);
    }

}

// File: contracts/SpaceCraftCore.sol

contract SpaceCraftCore is ExplorePanel {

    // 계약 업그레이드 용
    address public newContractAddress;

    function SpaceCraftCore() public {
        paused = false;

        ceoAddress = msg.sender;
        gmAddress = msg.sender;

        CfoAddress = msg.sender;

    }

    // TODO: 업그레이드 플랜 준비
    function setNewAddress(address _upgradeAddress) external onlyCEO whenPaused {
        newContractAddress = _upgradeAddress;
        //ContractUpgrade(_upgradeAddress);
    }

    // 드론 정보를 확인합니다.
    function getDrone(uint256 _index) external view returns (

        uint productId,

        uint enchantExplore,
        uint enchantSpeed,
        uint enchantAttack,

        uint256 exploreResult,
        uint resultValue,

        uint spaceId,
        uint alien,

        uint planetId,
        uint resultNumber

    ) {
        Drone storage drone = drones[_index];

        productId = drone.productId;
        enchantExplore = drone.enchantExplore;
        enchantSpeed = drone.enchantSpeed;
        enchantAttack = drone.enchantAttack;

        if ( keccak256(droneIndexToOwner[_index]) == keccak256(msg.sender)) {
            exploreResult = drone.exploreResult;
            resultValue = drone.resultValue;
            resultNumber = drone.resultNumber;
            planetId = drone.planetId;

        } else {
            exploreResult = 0; // 탐험 결과 0번은 임시값으로 사용함
            resultValue = 0;
            resultNumber = 0;
            planetId = 0;
        }

        spaceId = drone.spaceId;
        alien = drone.alien;
    }

    // 새 드론을 구입합니다.
    // 가격을 지불하고, 랜덤 인공지능을 받아 새 드론에 등록합니다.
    function buyNewDrone(uint _productId) payable external {

        require(msg.value > 0);

        uint price;
        (price,,,,) = _getProductShopInfo(_productId);
        require(msg.value == price);

        // 드론이 하나도 없는 경우, 무상 지급 드론을 제공해줍니다.
        if(ownerDroneCount[msg.sender] == 0){
            _createDrone(msg.sender, 0, false, false);
        }

        // 유료 구매 드론
        _createDrone(msg.sender, _productId, true, false);

    }

    //////////////////////////////////////////// Misc
    function withDrawBalance(uint _amount) external {

        require(msg.sender == CfoAddress);

        if (_amount >= this.balance) {
            msg.sender.transfer(_amount);
        }
    }

    function unpause() public onlyCEO whenPaused {
        require(newContractAddress == address(0));

        super.unpause();
    }

    // 게임 엔진과 인프라 계약을 설정합니다.
    function setGameAddress(address _engineAddr, address _centerAddr, address _jackpotAddr) external onlyCEO {
        require(_engineAddr != address(0) && _centerAddr != address(0) && _jackpotAddr != address(0));

        engine = GameEngineInterface(_engineAddr);
        gameCenter = GameCenterInterface(_centerAddr);
        jackPot = JackPotInterface(_jackpotAddr);

        jackpotAddr = _jackpotAddr;
    }

    // 
    function getGameEngineAddress() external view onlyCEO returns (address engineAddr, address centerAddr) {
        engineAddr = address(engine);
        centerAddr = address(gameCenter);
    }


}