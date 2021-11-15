pragma solidity ^0.8.0;
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./SafeMath.sol";
import "./ERC165.sol";
// PXA实现
contract MetaFarm is  ERC165, IERC721 {
    using SafeMath for uint256;

    // 验证接受者地址为合约时，是否支持接收ERC721 tokenid
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    // 记录token归属
    mapping (uint256 => address) private _tokenOwner;
    // 记录token授权情况
    mapping (uint256 => address) private _tokenApprovals;
    // 记录用户token数量
    mapping (address => uint256) private _ownedTokensCount;
    // 记录用户全部授权情况
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    uint256 public totalsuply;
    mapping(bytes4 => address) invite2address;
    bytes4 public invite=0x00000000;
    bytes4  _invite;
    mapping(bytes4 => uint256) invite2tokenID;
    mapping(bytes4 => uint256) invitetokenIDcount;
    uint256[][]  levels;
    address[] work;
    uint256[][] public land; //记录收获时间，种子ID，收获数量
    mapping(uint256=>mapping(uint256=>uint256)) land_index;//tokenId=>land_index=>index
    mapping(uint256=>uint256) land_index_landId;
    mapping(uint256=>uint256) land_index_tokenId;
    mapping(address=>uint256) address_index;//从1开始
    uint256[][] list_token;
    mapping(uint256=>uint256) token_index;//从0开始
    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    string constant private _name = "MetaFarm";
    string constant private _symbol = "MTF";
    uint8 constant private _decimals=0;
    address payable admin=payable(msg.sender);
    bytes4 internal My_invite;
    bytes4 internal My_inviteCode;
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

        struct _farmer{
        bytes4  My_invite;//我的推荐人
        bytes4  My_inviteCode;//我的推荐CODE
        string  name;//名字
        uint256 level;//等级
        uint256 exp;//经验
        uint256 coins;//金币
        uint256 wisdom;//智慧(1-33)
        uint256 industrious;//勤劳(1-33)
        uint256 courage;//勇气(1-33)
        uint256 growth;//成长值百分比 普通1-10，精英5-10，传说7-10
        string rarity;//稀有度，普通，精英，传说  （普通<80，精英80-94，传说>=95）
    }

    function name() public view virtual  returns (string memory) {
        return _name;
    }

    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8){return _decimals;}
    _farmer[] MetaFarmer;
    constructor () {
        _registerInterface(_INTERFACE_ID_ERC721);
        invite2address[0x00000000]=admin;
        invite2tokenID[0x00000000]=0;
        list_token.push();
    }

    modifier canOperate(uint _tokenId) {
        address tokenOwner = _tokenOwner[_tokenId];
        require( tokenOwner == msg.sender ||
                 _operatorApprovals[tokenOwner][msg.sender] );
        _;
    }



    modifier canTransfer(uint _tokenId, address from) {
        uint256 tokenID = uint256(keccak256(abi.encode(_tokenId, from)));
        address tokenOwner = _tokenOwner[tokenID];
        require( tokenOwner == msg.sender ||
                 _operatorApprovals[tokenOwner][msg.sender] ||
                 getApproved(_tokenId) == msg.sender );
        _;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner];
    }


    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }


    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }



    function FM_safeMint(bytes4 FM_invite,address to) public payable  {
       require(checkwork(msg.sender), "ERC721: operator not allowed");
        uint256 tokenId=MetaFarmer.length;
        uint256 i;
        totalsuply=MetaFarmer.length+1;
        MetaFarmer.push();
        FM_mint(to, tokenId,FM_invite);
        for(i=1;i<4;i++)
        {
        land.push([0,0,0]);
        land_index[tokenId][i]=land.length-1;
        land_index_tokenId[land.length-1]=tokenId;
        land_index_landId[land.length-1]=i;
        }
    }

    function FM_mint(address to, uint256 tokenId,bytes4 FM_invite) internal  {
        address payable invite_address;
        invite_address=z_getaddre(FM_invite);
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to]++;
        invitetokenIDcount[FM_invite]++;
        setFramerinvite(tokenId,FM_invite);
          if(address_index[to]==0){
          list_token.push([tokenId]);
          address_index[to]=list_token.length-1;
          token_index[tokenId]=list_token[address_index[to]].length-1;
        }
          if(address_index[to]!=0){
          list_token[address_index[to]].push(tokenId);
          token_index[tokenId]=list_token[address_index[to]].length-1;
        }
        emit Transfer(address(0), to, tokenId);
        SetFramer_nature(tokenId);
                if(tokenId!=0)
        {
                   z_GetInvite(tokenId,to);
        }
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");


        // Clear approvals
        _approve(address(0), tokenId);

        _ownedTokensCount[from] -= 1;
        _ownedTokensCount[to] += 1;

        _tokenOwner[tokenId] = to;
        changeownerlist(from,to,tokenId);
        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!isContract(to)) {
            return true;
        }

        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            msg.sender,
            from,
            tokenId,
            _data
        ));
        if (!success) {
            revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }


    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

        receive() external payable{}
        function withdraw() public {
        require(msg.sender == admin, "Only Owner");
        uint amount = address(this).balance;

        (bool success, ) = admin.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

        //根据推荐人code获取推荐人地址
    function z_getaddre(bytes4 FM_invite) public view returns (address payable){
    return payable(invite2address[FM_invite]) ;

    }

    function z_gettokenID(bytes4 FM_invite) public view returns (uint256){
    return(invite2tokenID[FM_invite]) ;

    }


    //根据推荐人地址随机生成推荐CODE
    function z_GetInvite(uint256 tokenId,address to) internal{
        _invite =bytes4(keccak256(abi.encode(to,tokenId,block.timestamp,block.number)));
        invite2tokenID[_invite]=tokenId;
        invite2address[_invite]=to;
        My_inviteCode=_invite;
        setFramerinvitecode(tokenId,_invite);

    }

       function _GetMyInviteCode() internal view returns(bytes4){
        return(My_inviteCode);
    }

    //确认权限，只有归属者才有权操作
    modifier onlyOwnerOf(uint tokenId){
    bool isall;
    isall=_isApprovedOrOwner(msg.sender, tokenId)||checkwork(msg.sender);
    require(isall, "ERC721:  is not owner nor approved");
        _;
    }



    //设置农民名字
   function Set_FramerName(uint256 tokenId,string memory _farmername) public onlyOwnerOf(tokenId){
      SetFramerName(tokenId,_farmername);
    }
    function SetFramerName(uint256 tokenId,string memory _farmername) internal {
        _farmer storage farmer = MetaFarmer[tokenId];
        farmer.name=_farmername;
    }

    //设置邀请人
        function setFramerinvite(uint256 tokenId,bytes4 FM_invite) internal {
        _farmer storage farmer = MetaFarmer[tokenId];
        farmer.My_invite=FM_invite;
    }

    //设置邀请邀请码
        function setFramerinvitecode(uint256 tokenId,bytes4 _invitecode) internal {
        _farmer storage farmer = MetaFarmer[tokenId];
        farmer.My_inviteCode=_invitecode;
    }

    //读取农民信息
        function MyFramer(uint256 tokenId)public view returns (string memory NAME,uint256 LEVLE,uint256 EXP,uint256 COIN,string memory RARITY,bytes4 My_Invite,bytes4 My_InviteCode){
        if(tokenId>=0){
        _farmer storage farmer = MetaFarmer[tokenId];
        return(farmer.name,farmer.level,farmer.exp,farmer.coins,farmer.rarity,farmer.My_invite,farmer.My_inviteCode);}
    }
    //读取农民属性
        function GetFramer_nature(uint256 tokenId)public view returns (string memory FMname,uint256 FMwisdom,uint256 FMindustrious,uint256 FMcourage,uint256 FMgrowth,string memory FMrarity){
        _farmer storage farmer = MetaFarmer[tokenId];
        return(farmer.name,farmer.wisdom,farmer.industrious,farmer.courage,farmer.growth,farmer.rarity);
    }
    //农民初始化
        function SetFramer_nature(uint256 tokenId) internal{
        _farmer storage farmer = MetaFarmer[tokenId];
        farmer.name="MetaFarmer";
        farmer.level=1;
        farmer.exp=0;
        farmer.coins=15;
        uint256 nowtime;
        nowtime = block.timestamp;//now
        uint256 total;
        farmer.wisdom=uint256(keccak256(abi.encode(msg.sender, nowtime,block.number,tokenId,"wisdom")))%19+15;
        farmer.industrious=uint256(keccak256(abi.encode(msg.sender, nowtime,block.number,tokenId,"industrious")))%19+15;
        farmer.courage=uint256(keccak256(abi.encode(msg.sender, nowtime,block.number,tokenId,"courage")))%19+15;
        total=farmer.wisdom+farmer.courage+farmer.industrious;

        if(total<=80)
        {
          farmer.rarity="Command";
          farmer.growth=uint256(keccak256(abi.encode(msg.sender, nowtime,block.number,tokenId,"Command")))%10+1;
        }
                if(total<=94 && total>80)
        {
          farmer.rarity="Elite";
          farmer.growth=uint256(keccak256(abi.encode(msg.sender, nowtime,block.number,tokenId,"Elite")))%6+5;
        }
                        if(total>95)
        {
          farmer.rarity="Legend";
          farmer.growth=uint256(keccak256(abi.encode(msg.sender, nowtime,block.number,tokenId,"Legend")))%4+7;
        }
    }
    event _farmer_LevelUP(uint256 tokenId,uint256 level,uint256 uplevel);
    //农民升级
    function _farmerLevelUP(uint256 tokenId)public {
      require(checkwork(msg.sender), "ERC721: operator not allowed");
      _farmer storage farmer = MetaFarmer[tokenId];
      uint256 farmer_upexp=60*(farmer.level+1)*(farmer.level+1)-60*(farmer.level+1)+15;
      uint256 farmer_upcoin=(576*(farmer.level+1)*(farmer.level+1)-1008*(farmer.level+1)+360)/(20+farmer.level);
      require(farmer.exp >= farmer_upexp, "not enough exp");
      require(farmer.coins >= farmer_upcoin, "not enough coin");
      farmer.level=farmer.level+1;
      _farmerOprexp(tokenId,farmer_upexp,0);
     _farmerOprcoin(tokenId,farmer_upcoin,0);
     farmer.wisdom=farmer.wisdom.add(farmer.growth);
     farmer.industrious=farmer.industrious.add(farmer.growth);
     farmer.courage=farmer.courage.add(farmer.growth);
     emit _farmer_LevelUP(tokenId,farmer.level-1,farmer.level);
    }
    ////农民经验 opr1+ opr0-
    event farmerchangeexp(uint256 tokenId,uint256 expamount,string opr);
    function _farmerOprexp(uint256 tokenId,uint256 expamount,uint256 opr)public{
        require(checkwork(msg.sender), "ERC721: operator not allowed");
         _farmer storage farmer = MetaFarmer[tokenId];
         string memory _opr;
        if(opr==1)
        {
          farmer.exp=farmer.exp.add(expamount);
          _opr="add";
        }
        if(opr==0)
        {
          farmer.exp=farmer.exp.sub(expamount);
          _opr="sub";
        }
        emit farmerchangeexp(tokenId,expamount,_opr);
        }

    ////农民金币 opr1+ opr0-
    event farmerchangecoin(uint256 tokenId,uint256 expamount,string opr);
    function _farmerOprcoin(uint256 tokenId,uint256 coinamount,uint256 opr)public{
        require(checkwork(msg.sender), "ERC721: operator not allowed");
         _farmer storage farmer = MetaFarmer[tokenId];
         string memory _opr;
        if(opr==1)
        {
          farmer.coins=farmer.coins.add(coinamount);
          _opr="add";
        }
        if(opr==0)
        {
          farmer.coins=farmer.coins.sub(coinamount);
           _opr="sub";
        }
        emit farmerchangecoin(tokenId,coinamount,_opr);
        }

      //转移金币
      event _coinstransfer (uint256 From,uint256 To,uint256 amount);
      function coinstransfer (uint256 From,uint256 To,uint256 amount) public{
          require(checkwork(msg.sender), "ERC721: operator not allowed");
        _farmer storage _from = MetaFarmer[From];
        _farmer storage _to = MetaFarmer[To];
        require(_from.coins>=amount, "not enough coins");
        _from.coins=_from.coins.sub(amount);
        _to.coins=_to.coins.add(amount);
        emit _coinstransfer ( From, To, amount);
      }
    //添加工作合约
    function addwork(address _work)public{
        require(msg.sender == admin, "only admin can do this");
        work.push(_work);
    }
    //修改工作合约，弃用合约地址改为0
    function oprwork(uint256 _work_index,address _work)public{
        require(msg.sender == admin, "only admin can do this");
        work[_work_index]=_work;
    }

        function getwork(uint256 _work_index)public view returns(address _work){
        return(work[_work_index]);
    }
function checkwork(address _work)public view returns(bool)
{
  uint256 i=work.length;
  for(i=0;i<work.length;i++)
 {
     if(_work==work[i]){
         return(true);
     }
 }
    return(false);
}

    function cultivation(uint256 Land_index,uint256 times,uint256 seedid,uint256 amount)public{
     require(checkwork(msg.sender), "ERC721: operator not allowed");
     land[Land_index][0]=times;
     land[Land_index][1]=seedid;
     land[Land_index][2]=amount;
    }
    function getland(uint256 tokenId,uint256 landId)public view returns(uint256 LANDtimes,uint256 LANDseedid,uint256 LANDamount){
        return(land[getland_index(tokenId,landId)][0],land[getland_index(tokenId,landId)][1],land[getland_index(tokenId,landId)][2]);
    }
        function getland_index(uint256 tokenId,uint256 landId)public view returns(uint256){
        return(land_index[tokenId][landId]);
    }
    function get_ownedTokensCount(address addr) public view returns(uint256){
        return(_ownedTokensCount[addr]);
    }
    function get_addresstokenId(address addr,uint256 tokenindex) public view returns(uint256){
            return(list_token[address_index[addr]][token_index[tokenindex]]);
    }
    function get_addresstokenlist(address addr) public view returns(uint256){
            return(list_token[address_index[addr]].length);
    }

    function changeownerlist(address from,address to,uint256 tokenId)internal{
        list_token[address_index[from]][token_index[tokenId]]=0;
       if(address_index[to]==0){
       list_token.push([tokenId]);
       address_index[to]=list_token.length-1;
       token_index[tokenId]=list_token[address_index[to]].length-1;
        }
       if(address_index[to]!=0){
       list_token[address_index[to]].push(tokenId);
       token_index[tokenId]=list_token[address_index[to]].length-1;
        }
    }

    function getlasttokenId()public view returns(uint256){
        return(MetaFarmer.length-1);
    }
    }