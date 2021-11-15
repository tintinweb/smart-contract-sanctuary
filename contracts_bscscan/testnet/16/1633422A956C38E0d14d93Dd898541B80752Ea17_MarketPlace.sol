// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./market/Ownable.sol";
//import "./dragonSphereNFT.sol";


contract DragonSphere is Ownable, IERC721 {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeERC20 for IERC20;

    bytes4 private constant _InterfaceIdERC721 = 0x80ac58cd;
    bytes4 internal constant _ERC721Checksum = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    address public mdo = address(0x25A2E82B0009Ed46A6a5B1e17BdA18d5e21CF7Ab);
    address public acc_fund = address(0x6F812734385F7C3525d9E5612bEF353ba572D146);
    // max int 115792089237316195423570985008687907853269984665640564039457584007913129639935

    // address currencyToken = IERC20(mdo);

    string[] RACES =  ["GOKU", "VEGETA", "KRILLIN", "FRIEZA", "BEERUS", "ANDROID_18", "BROLY", "BULMA", "GINYU", "JIREN", "KID_BUU", "MAJIN_BUU", "MASTER_ROSHI",
    "MERCENARY", "PICCOLO", "SON_GOHAN", "SON_GOTEN", "TIEN_SHINHAN", "YAAMCHA", "ZARBON" ]; // chung toc 20
    uint[] LEVEL = [0, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000, 1000000, 2000000, 5000000, 10000000]; // level 1,2,3 .. 14

    // 0-kim, 1-moc, 2-thuy, 3-hoa, 4- tho,

    struct Character {
        uint index;
        address player;
        string userName;
        string avatar;
        uint32 attack;
        uint32 defense;
        uint8 star; // menh: kim, moc thuy hoa tho
        uint8 level;
        uint8 xo; // gioi tinh
        uint8 love; // chi so yeu
        string race; // chung toc
        uint256 createTime;

    }

    struct ItemBoard{
        uint name; // 1- kim 2- moc 3- thuy 4- hoa 5-tho
        uint8 status; // active or no active
        uint8 position;
        address[] addrs;
        uint[] idCharacter;
    }

    struct Board{
        uint idBoard;
        uint8[2] sizeBoard;
        address[] player;
        uint8[] character;
        uint8 status;
        uint8 depth; // do sau
        uint256 rewardDepth;

    }

    struct Trap{
        uint id;
        address owner;
        string nameTrap;
        uint attack;
        uint defence;
        uint race;
        uint position;
        uint idBoard;
        bool isActive;
    }


    //Character[] public charactersDefault;
    mapping(uint => Character) charactersDefault;
    Character[] public characters;
    mapping(address => uint256[]) public charactersOf;
    mapping(uint256 => address) public approvalOneCharacter;
    mapping(address => mapping (address => bool)) private _operatorApprovalsCharacter;

    mapping(uint => Board)  boards;
    uint8 public _countBoard = 0;
    mapping(uint => mapping (uint => ItemBoard)) public itemBoards;
    mapping(uint => mapping (uint => uint[]) ) public arrItemOfBoard;
    mapping(address => uint[] ) public boardsOf;


    Trap[] public traps;
    mapping(address => uint256[]) public trapsOf;
    mapping(uint256 => address) public approvalOneTrap;
    mapping(address => mapping (address => bool)) private _operatorApprovalsTrap;
    mapping(uint => mapping(uint => uint[])) public trapOnItemOnBoards;


    mapping(address => bool) public admin;
    //address _owner;



    event CreateCharacter( address _player ,string _userName, string _avatar, uint8 _xo);
    event CreateRandom(uint _random);
    event Win(address _player, string _whoWin, uint32 _attack, uint32 _defense);
    event Lose(address _player, string _whoLose, uint32 _attack, uint32 _defense);
    event UpdateCharacter(uint _i, uint32, uint32);
    event CharacterMove( uint _indexCharacter, uint _idBoard, uint _idItemBoard );
    event Transfer(address, address, uint);

    modifier onlyAdmin(){
        require(admin[msg.sender], "contract is not allowed");
        _;
    }

    constructor() public {
        // OwnableUpgradeSafe.__Ownable_init();
        admin[msg.sender] = true;
        _owner = msg.sender;

    }

    function getContractOwner() external view returns(address contractOwner ){
        return _owner;
    }


    // ==== CHARACTER ===
    // 20 characters
    // function setCharactersDefault() external onlyOwner{
    //     // set default 20 items character
    //     for(uint256 i=0; i<20; i++ ){

    //         charactersDefault[i] = Character(i, msg.sender , RACES[i], "url" , 0, 0, 0, 0, 0, 0, RACES[i] , now);
    //     }
    // }


    // === hard code default 20 Character
    function getCharactersDefault(uint i) external view returns( uint _index,  address _player, string memory _userName, string memory _avatar, uint32 _attack, uint32 _defense,
        uint8 _star, uint8 _level, uint8 _xo, uint8 _love, string memory _race ,uint256 _createTime ) {

        require(i >= 0 , "i >= 0");

        //for(uint i=0; i< 20; i++ ){
        Character memory _character = charactersDefault[i];

        _index = _character.index;
        _player = _character.player;
        _userName = _character.userName;
        _avatar = _character.avatar;
        _attack = _character.attack;
        _defense = _character.defense;
        _star = _character.star;
        _level = _character.level;
        _xo = _character.xo;
        _love = _character.love;
        _race = _character.race;
        _createTime = _character.createTime;
        // _inBoard = _character.inBoard;

        //}

    }


    function createCharacter( string memory _userName, string memory _avatar, uint8 _star , uint8 _xo, string memory _race) public onlyOwner returns(uint256 _characterIndex) {

        require(bytes(_userName).length >= 3, "_userName is >=3 ");
        require(_xo <2 , " _xo is not xo" );
        //require(bytes(_race).length > 0, "_race is not string");

        // === set data default from level 1; ===
        address _player = msg.sender;
        uint32 _attack = 10;
        uint32 _defense = 10;
        // uint8 _star = 0;
        uint8 _level = 1;
        uint8 _love = 1;
        uint8 _status = 0;

        _characterIndex = characters.length;

        characters.push(Character({
        index: _characterIndex,
        player: _player,
        userName: _userName,
        avatar: _avatar,
        attack: _attack,
        defense: _defense,
        star: _star,
        level: _level,
        xo: _xo,
        love: _love,
        race: _race,
        createTime: now

        }));

        uint256 betAmount = 1 ether; // hard code each create Character is 1 mdo
        //IERC20(mdo).safeTransferFrom(_player, address(acc_fund), betAmount );

        charactersOf[_player].push(_characterIndex);

        // === add market ===
        uint256 newCharacterId = SafeMath.sub(characters.length, 1);//want to start with zero.
        _transfer(address(0), _owner, newCharacterId);
        //

        emit CreateCharacter(msg.sender, _userName, _avatar, _xo );
    }

    function editCharacter(uint8 _i, string memory _userName, string memory _avatar, uint8 _star, uint8 _xo, string memory _race,   uint32 _attack,
uint32 _defense ) public onlyOwner {

        Character storage character = characters[_i];

        character.userName = _userName;
        character.avatar = _avatar;
        character.star = _star;
        character.xo = _xo;
        character.race = _race;
        character.attack = _attack;
        character.defense = _defense;

    }

    function removeCharacter(uint8 _i) external  {
        characters[_i] = characters[characters.length - 1];
        characters.pop();
    }

    function countAllCharacter() public view returns(uint){
        return characters.length;
    }

    function getNumbersOfMyCharacter(address _player ) public view returns(uint256[] memory) {
        return charactersOf[_player];
    }



    function getMyCharacters(uint8 _i) public view returns(uint _index ,address _player, string memory _userName, string memory _avatar, uint32 _attack, uint32 _defense,
        uint8 _star, uint8 _level, uint8 _xo, uint8 _love, string memory _race,  uint256 _createTime ) {

        require(_i >=0 ," _i >= 0 " );

        Character memory character = characters[_i];

        _index = character.index;
        _player = character.player;
        _userName = character.userName;
        _avatar = character.avatar;
        _attack = character.attack;
        _defense = character.defense;
        _star = character.star;
        _level = character.level;
        _xo = character.xo;
        _love = character.love;
        _race = character.race;
        _createTime = character.createTime;
        //_inBoard = character.inBoard;

    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyOwner {
        _token.safeTransfer(to, amount);
    }

    // ==== END CHARACTER ====


    // ==== BOARD ===
    function createBoard( uint8 _countUser,  uint8 _countCharacter ) public onlyOwner { // fix size board 12 , # 12 can bug UI

        require(_countUser > 0, "number User > 0");
        require(_countCharacter > 0 , "number Character > 0");

        uint8 _sizeBoard = (_countCharacter + 1) * ( _countUser + 1);
        uint8[] memory _character;
        address[] memory _player;
        uint[] memory _idCharacter;

        boards[_countBoard]=(Board({
        idBoard : _countBoard,
        sizeBoard : [ _countCharacter + 1,  _countUser + 1 ],
        player: _player,
        character : _character,
        status: 0,
        depth: 1,
        rewardDepth: 300 ether

        }));

        //uint _numRandom =  randomItem(5);

        for(uint8 i=0; i< _sizeBoard; i++ ){
            itemBoards[_countBoard][i] = (ItemBoard({
            name:  uint(keccak256(abi.encodePacked(block.timestamp + i, block.difficulty)))%5, // kim moc thuy hoa tho 1-5
            status:   0, // no action
            position:  i, // index board
            addrs:  _player, // count user
            idCharacter: _idCharacter
            }));

        }

        boardsOf[msg.sender].push(_countBoard) ;

        _countBoard ++;

    }


    function getNumberOfMyBoard(address _player ) public view returns (uint[] memory){
        return boardsOf[_player];
    }

    function getAllBoard() public view returns(uint) {
        return _countBoard;
    }


    function getBoard(uint i) public view returns (uint _idBoard ,uint8[2] memory _sizeBoard, address[] memory _player, uint8[] memory _character, uint8 _status, uint8 _depth, uint256 _rewardDepth ){

        require(i >= 0, "i >= 0");

        Board memory board = boards[i];

        _idBoard = board.idBoard;
        _sizeBoard = board.sizeBoard;
        _player = board.player;
        _character = board.character;
        _status = board.status;
        _depth = board.depth;
        _rewardDepth = board.rewardDepth;
    }

    // i follow sizeBoard
    function getItemBoard(uint _idxBoard, uint i) public view returns(uint _name, uint8 _status, uint8 _position, address[] memory _adds, uint[] memory _idCharacters ){

        require(_idxBoard >= 0, "_idxBoard >= 0");
        require(i >= 0, "i >= 0");

        ItemBoard memory itemBoard =  itemBoards[_idxBoard][i];

        _name = itemBoard.name;
        _status = itemBoard.status;
        _position = itemBoard.position;
        _adds = itemBoard.addrs;
        _idCharacters = itemBoard.idCharacter;

    }

    function characterMoveOnBoard( uint _indexCharacter,  uint _idBoard, uint _idItemBoard) public{ // params uint _lastItemBoard

        require(_indexCharacter >= 0, "_indexCharacter >= 0");
        require(_idBoard >= 0, "_idBoard >= 0");
        require(_idItemBoard >= 0, "_idItemBoard >= 0");
        //require(_lastItemBoard >= 0, "_lastItemBoard >= 0");


        // remove position old

        for(uint i=0; i< 12; i++ ){ // fix size board 12
            ItemBoard storage itemBoardOld =  itemBoards[_idBoard][i];

            if(itemBoardOld.status == 1 &&  itemBoardOld.idCharacter.length > 0){
                for(uint j=0; j<itemBoardOld.idCharacter.length; j++){
                    if( itemBoardOld.idCharacter[j] == _indexCharacter  ){ // check is me cant remove
                        //delete itemBoardOld.idCharacter[j];

                        itemBoardOld.idCharacter[j] = itemBoardOld.idCharacter[itemBoardOld.idCharacter.length - 1];
                        itemBoardOld.idCharacter.pop();

                        if(itemBoardOld.idCharacter.length == 0 ){
                            itemBoardOld.status = 0;
                        }
                    }
                }
            }

        }


        // add new data
        if(_idItemBoard != 1000 ){
            ItemBoard storage itemBoard =  itemBoards[_idBoard][_idItemBoard];
            itemBoard.status = 1;
            itemBoard.idCharacter.push(_indexCharacter) ;
        }

        emit CharacterMove(_indexCharacter, _idBoard, _idItemBoard);

    }


    // ==== END BOARD ===

    function randomItem(uint mod) public view returns(uint){
        return uint(keccak256(abi.encodePacked(now, block.difficulty, msg.sender))) % mod;
    }


    // ==== TRAP ===
    // trap nay mua de tan cong doi thu
    //  is 1: kim, 2: moc, 3: thuy, 4: hoa, 5: tho
    function createTrap( string memory _nameTrap, uint _attack, uint _defence, uint _race) public onlyOwner{
        require(_attack >= 0 , "_attack >= 0");
        require(_defence >= 0 , "_defence >= 0");

        uint _id = traps.length;
        traps.push( Trap({
        id: _id,
        owner: msg.sender,
        nameTrap: _nameTrap,
        attack: _attack,
        defence: _defence,
        race: _race,
        position: 1000000, //default position = 1000000
        idBoard: 1000000, // default idBoard = 1000000
        isActive : false
        }));

        trapsOf[msg.sender].push(_id);

    }

    function getNumbersOfTrap(address _player ) public view returns(uint256[] memory) {
        return trapsOf[_player];
    }

    function getTrap(uint _idTrap) public view returns(uint _id, address _owner, string memory _nameTrap, uint _attack,  uint _defence, uint _race, uint _position, uint _idBoard, bool _isActive ){
        require(_idTrap >= 0 , "_idTrap >= 0");

        Trap memory trap = traps[_idTrap];

        _id = trap.id;
        _owner = trap.owner;
        _nameTrap = trap.nameTrap;
        _attack = trap.attack;
        _defence= trap.defence;
        _race = trap.race;
        _position = trap.position;
        _idBoard = trap.idBoard;
        _isActive = trap.isActive;

    }

    function setTrapOnBoard(uint _idTrap, uint _idBoard, uint _position) public returns( uint[] memory )  {


        //Trap storage trap = traps[_idTrap];

        //   trap.idBoard = _idBoard;
        //   trap.position = _position;
        //   trap.isActive = true;

        trapOnItemOnBoards[_idBoard][_position].push(_idTrap);

        return trapOnItemOnBoards[_idBoard][_position];
    }

    function getTrapOnBoard(uint _idBoard, uint _position) public returns(uint[] memory) {
        return trapOnItemOnBoards[_idBoard][_position];
    }

    // remove _idTrap
    // remove trapOfUser

    function interactiveTrapvsCharacter(uint _idTrap, uint _idCharacter ,uint _idBoard, uint _position) public returns(uint _downAttack, uint _downDefence) {

        require(_idTrap >= 0 , "_idTrap >= 0");
        require(_idCharacter >= 0 , "_idCharacter >= 0");

        _downAttack= 0;_downDefence = 0;

        Trap memory trap = traps[_idTrap];
        Character storage character = characters[_idCharacter];

        if(trap.attack > 0 && trap.defence > 0 ){
            // if(trap.idBoard == _idBoard && trap.position == _position ){
            if(trap.owner != character.player ){
                _downAttack = trap.attack;
                _downDefence = trap.defence;
            }
            // }

        }

        if(trap.attack > 0 && trap.defence == 0){
            //  if(trap.idBoard == _idBoard && trap.position == _position ){
            if(trap.owner != character.player ){
                _downAttack = trap.attack;
                _downDefence = 0;
            }
            // }
        }

        if(trap.attack == 0 && trap.defence > 0){
            // if(trap.idBoard == _idBoard && trap.position == _position ){
            if(trap.owner != character.player ){
                _downAttack = 0;
                _downDefence = trap.defence;
            }
            // }
        }
        // update character

        if(character.attack >= uint32(_downAttack) &&  character.defense >= uint32(_downDefence)){
            character.attack = character.attack - uint32(_downAttack);
            character.defense = character.defense - uint32(_downDefence);
            return (_downAttack, _downDefence);
        }else{
            return (0, 0);
        }


    }


    // === END TRAP ===


    // === battle fighting game ===
    function onBattle( uint _idA, uint _idB ) public returns(uint _result, uint32 _attackA, uint32 _defenseA, uint32 _attackB, uint32 _defenseB) {
        //Character memory _characterA, Character memory _characterB
        Character memory _characterA = characters[_idA];
        Character memory _characterB = characters[_idB];
        // PHASE 1:

        if(_characterA.attack ==  _characterB.defense &&  _characterA.defense == _characterB.attack ){
            // -1 hoa or show id win
            return(1000,_characterA.attack , _characterA.defense,  _characterB.attack, _characterB.defense) ;
        }

        if(_characterA.attack >= _characterB.defense && _characterA.defense >= _characterB.attack ){ // a win sure
            _characterA.attack  += ( 1 * _characterB.defense ) / 100; // + 1%
            _characterA.defense += (1 * _characterB.attack) / 100; //

            _characterB.attack -= (1 * _characterA.defense) / 100;
            _characterB.defense -= (1 * _characterA.attack) / 100;

            Win( _characterA.player, ": WIN", _characterA.attack, _characterA.defense);
            Lose(_characterB.player, ": LOSE", _characterB.attack, _characterB.defense);
            updateDataOfCharacter(_characterA.index, _characterA.attack, _characterA.defense);
            updateDataOfCharacter(_characterB.index, _characterB.attack, _characterB.defense);
            return(_idA,_characterA.attack , _characterA.defense,  _characterB.attack, _characterB.defense) ;

        }else{ // b win sure
            _characterA.attack  -= ( 1 * _characterB.defense ) / 100; // + 1%
            _characterA.defense -= (1 * _characterB.attack) / 100; //

            _characterB.attack += (1 * _characterA.defense) / 100;
            _characterB.defense += (1 * _characterA.attack) / 100;

            Win( _characterB.player, ": WIN", _characterB.attack, _characterB.defense);
            Lose(_characterA.player, ": LOSE", _characterA.attack, _characterA.defense);
            updateDataOfCharacter(_characterA.index, _characterA.attack, _characterA.defense);
            updateDataOfCharacter(_characterB.index, _characterB.attack, _characterB.defense);
            return(_idB,_characterA.attack , _characterA.defense,  _characterB.attack, _characterB.defense) ;
        }

        if(_characterA.attack >= _characterB.defense && _characterA.defense < _characterB.attack ){
            // PHASE 2:
            _characterB.defense = 0;
            _characterA.defense = 0;


            if(_characterA.attack > _characterB.attack ){
                // a win
                _characterA.attack  += ( 1 * _characterB.defense ) / 100; // + 1%
                _characterA.defense += (1 * _characterB.attack) / 100; //

                _characterB.attack -= (1 * _characterA.defense) / 100;
                _characterB.defense -= (1 * _characterA.attack) / 100;


                Win( _characterA.player, ": WIN", _characterA.attack, _characterA.defense);
                Lose(_characterB.player, ": LOSE", _characterB.attack, _characterB.defense);
                updateDataOfCharacter(_characterA.index, _characterA.attack, _characterA.defense);
                updateDataOfCharacter(_characterB.index, _characterB.attack, _characterB.defense);
                return(_idA,_characterA.attack , _characterA.defense,  _characterB.attack, _characterB.defense) ;
            }else{
                // a lose
                _characterA.attack  -= ( 1 * _characterB.defense ) / 100; // + 1%
                _characterA.defense -= (1 * _characterB.attack) / 100; //

                _characterB.attack += (1 * _characterA.defense) / 100;
                _characterB.defense += (1 * _characterA.attack) / 100;


                Win( _characterB.player, ": WIN", _characterB.attack, _characterB.defense);
                Lose(_characterA.player, ": LOSE", _characterA.attack, _characterA.defense);
                updateDataOfCharacter(_characterA.index, _characterA.attack, _characterA.defense);
                updateDataOfCharacter(_characterB.index, _characterB.attack, _characterB.defense);
                return(_idB,_characterA.attack , _characterA.defense,  _characterB.attack, _characterB.defense) ;
            }

        }else{
            //  PHASE 2:
            _characterA.attack = 0;
            _characterB.attack = 0; // A, B mat kha nang tan cong


        }

        // update data for character
        updateDataOfCharacter(_characterA.index, _characterA.attack, _characterA.defense);
        updateDataOfCharacter(_characterB.index, _characterB.attack, _characterB.defense);
        return(1000,_characterA.attack , _characterA.defense,  _characterB.attack, _characterB.defense) ;
    }

    function updateDataOfCharacter(uint _i, uint32 _attack, uint32 _defense) public {
        require(_i >= 0, "_i >= 0" );
        require(_attack >= 0, "_attack >= 0" );
        require(_defense >= 0, "_defense >= 0" );

        Character storage _character =  characters[_i];

        _character.attack = _attack;
        _character.defense = _defense;

        UpdateCharacter(_i, _attack, _defense);
    }

    // === end battle ===



    // ERC721
    function approve(address _approved, uint256 _id) external override {
        require(characters[_id].player == msg.sender ||
            _operatorApprovalsCharacter[characters[_id].player][msg.sender] == true
        ,"You are not authorized to access this function.");
        approvalOneCharacter[_id] = _approved;
        emit Approval(msg.sender, _approved, _id);
    }

    function approveTrap(address _approved, uint256 _id) external  {
        require(traps[_id].owner == msg.sender ||
            _operatorApprovalsTrap[traps[_id].owner][msg.sender] == true
        ,"You are not authorized to access this function.");
        approvalOneTrap[_id] = _approved;
        emit Approval(msg.sender, _approved, _id);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        require(_operator != msg.sender,"wrong: address approval all");
        _operatorApprovalsCharacter[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function setApprovalForAllTrap(address _operator, bool _approved) external  {
        require(_operator != msg.sender,"wrong: address approval all");
        _operatorApprovalsTrap[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _id) external override view returns (address) {
        require(_id < characters.length, "ID doesn't exist");
        return approvalOneCharacter[_id];

    }

    function getApprovedTrap(uint256 _id) external  view returns (address) {
        require(_id < traps.length, "ID doesn't exist");
        return approvalOneTrap[_id];

    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return _operatorApprovalsCharacter[_owner][_operator];

    }

    function isApprovedForAllTrap(address _owner, address _operator) external view returns (bool) {
        return _operatorApprovalsTrap[_owner][_operator];

    }


    function balanceOf(address owner) external override view returns (uint256 balance) {
        return charactersOf[owner].length;
    }

    function totalSupply() external view returns (uint total){
        return characters.length;
    }

    function _isOwnerOrApproved(address _from, address _to, uint256 _tokenId) internal view returns (bool) {
        require(_from == msg.sender ||
        approvalOneCharacter[_tokenId] == msg.sender ||
            _operatorApprovalsCharacter[_from][msg.sender],
            "You are not authorized to use this function");
        require(characters[_tokenId].player == _from, "Owner incorrect");
        require(_to != address(0), "Error: Operation would delete this token permanently");
        require(_tokenId < characters.length, "Token doesn't exist");
        return true;
    }

    function _isOwnerOrApprovedTrap(address _from, address _to, uint256 _tokenId) internal view returns (bool) {
        require(_from == msg.sender ||
        approvalOneTrap[_tokenId] == msg.sender ||
            _operatorApprovalsTrap[_from][msg.sender],
            "You are not authorized to use this function");
        require(traps[_tokenId].owner == _from, "Owner incorrect");
        require(_to != address(0), "Error: Operation would delete this trap permanently");
        require(_tokenId < traps.length, "trap doesn't exist");
        return true;
    }

    function transfer(address _to, uint _id) external{
        require(_to != address(0), "Use the burn function to burn tokens");
        require(_to != address(this), "Wrong address, try again");
        require(characters[_id].player == msg.sender, "Wrong id of user");
        _transfer(msg.sender, _to, _id );
    }

    function _transfer(address _from, address _to, uint256 _id) internal {
        require(_to != address(this));

        charactersOf[_to].push(_id);
        characters[_id].player = _to;

        // uint _idxOfID;

        if(_from != address(0) && charactersOf[_from].length> 0 ){

            for(uint i=0; i<charactersOf[_from].length; i++){
                if(charactersOf[_from][i] == _id ){
                    //_idxOfID = i;
                    charactersOf[_from][i] = charactersOf[_from][charactersOf[_from].length - 1];
                    charactersOf[_from].pop();
                }
            }


            delete approvalOneCharacter[_id];
        }

        emit Transfer(_from, _to, _id);
    }

    function _transferTrap(address _from, address _to, uint256 _id) internal {
        require(_to != address(this));

        trapsOf[_to].push(_id);
        traps[_id].owner = _to;

        // uint _idxOfID;

        if(_from != address(0) && trapsOf[_from].length> 0 ){

            for(uint i=0; i<trapsOf[_from].length; i++){
                if(trapsOf[_from][i] == _id ){
                    //_idxOfID = i;
                    trapsOf[_from][i] = trapsOf[_from][trapsOf[_from].length - 1];
                    trapsOf[_from].pop();
                }
            }


            delete approvalOneTrap[_id];
        }

        emit Transfer(_from, _to, _id);
    }

    function _isContract(address _to) internal view returns (bool) {
        uint32 size;
        assembly{
            size := extcodesize(_to)
        }
        return size > 0;
        //check if code size > 0; wallets have 0 size.
    }

    function _checkERC721Support(address _from, address _to, uint256 _tokenId, bytes memory _data)internal returns(bool) {
        if(!_isContract(_to)) {
            return true;
        }
        bytes4 returnData = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        //Call onERC721Received in the _to contract
        return returnData == _ERC721Checksum;
        //Check return value
    }

    function _safeTransfer(address _from, address _to, uint256 _tokenId, bytes memory _data) internal {
        require(_checkERC721Support(_from, _to, _tokenId, _data));
        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external override {
        _isOwnerOrApproved(_from, _to, _tokenId);
        _safeTransfer(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        _isOwnerOrApproved(_from, _to, _tokenId);
        _safeTransfer(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external override {
        _isOwnerOrApproved(_from, _to, _tokenId);
        _transfer(_from, _to, _tokenId);
    }

    function transferFromTrap(address _from, address _to, uint256 _tokenId) external  {
        _isOwnerOrApprovedTrap(_from, _to, _tokenId);
        _transferTrap(_from, _to, _tokenId);
    }

    function transferBalance(address _from, address _to, uint256 _balance) external {

        IERC20(mdo).safeTransferFrom(_from, _to, _balance );

    }


    function ownerOf(uint256 tokenId) external override view returns (address owner) {
        require(tokenId < characters.length, "Token ID doesn't exist.");
        return characters[tokenId].player;

    }

    function ownerOfTrap(uint256 tokenId) external view returns (address owner) {
        require(tokenId < traps.length, "Token ID doesn't exist.");
        return traps[tokenId].owner;

    }


    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {
        return (_interfaceId == _InterfaceIdERC721 );
    }


}

pragma solidity ^0.6.12;


interface IMarketPlace {

    event MarketTransaction(string TxType, address owner, uint256 tokenId);
    event MonetaryTransaction(string message, address recipient, uint256 amount);


    function setContract(address _contractAddress) external;

    function pause() external;

    function resume() external;

    function getOffer(uint256 _tokenId) external view returns (address seller, uint256 price, uint256 index, uint256 tokenId, bool active);
    function getOfferTrap(uint256 _trapId) external view returns (address seller, uint256 price, uint256 index, uint256 trapId, bool active);

    function getAllTokensOnSale() external view returns (uint256[] memory listOfOffers);
    function getAllTrapOnSale() external view returns (uint256[] memory listTrapOfOffers);

    function setOffer(uint256 _price, uint256 _tokenId) external;
    function setOfferTrap(uint256 _price, uint256 _trapId) external;

    function removeOffer(uint256 _tokenId) external;
    function removeOfferTrap(uint256 _tokenId) external;

    function buyCharacter(uint256 _tokenId) external payable;
    function buyTrap(uint256 _tokenId) external payable;

    function getBalance() external view returns (uint256);

    function withdrawFunds() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../DragonSphere.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMarketPlace.sol";

contract MarketPlace is Ownable, IMarketPlace {
    DragonSphere private _dragonSphere;
    //0x4bcec70b6c8e4d2eb9a6e32db596027525b54a95
    //ERC20 public tokenCanWithdraw = ERC20(0x4bcec70b6c8e4d2eb9a6e32db596027525b54a95);


    using SafeMath for uint256;

    struct Offer {
        address payable seller;
        uint256 price;
        uint256 index;
        uint256 tokenId;
        bool active;
    }

    struct OfferTrap {
        address payable seller;
        uint256 price;
        uint256 index;
        uint256 tokenId;
        bool active;
    }

    bool internal _paused;

    Offer[] offers;
    OfferTrap[] offerTraps;

    mapping(uint256 => Offer) tokenIdToOffer;
    mapping(address => uint256) internal _fundsToBeCollected;

    mapping(uint256 => OfferTrap) trapIdToOffer;


    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    modifier whenPaused() {
        require(_paused);
        _;
    }

    function setContract(address _contractAddress) onlyOwner public override {
        _dragonSphere = DragonSphere(_contractAddress);
    }

    constructor(address _contractAddress) public {
        setContract(_contractAddress);
        _paused = false;
    }

    function pause() public override onlyOwner whenNotPaused {
        _paused = true;
    }

    function resume() public override onlyOwner whenPaused {
        _paused = false;
    }

    function isPaused() public view returns (bool) {
        return _paused;
    }

    // ****

    function getOffer(uint256 _tokenId) public override view returns (
        address seller,
        uint256 price,
        uint256 index,
        uint256 tokenId,
        bool active) {

        require(tokenIdToOffer[_tokenId].active == true, "No active offer at this time");

        return (tokenIdToOffer[_tokenId].seller,
        tokenIdToOffer[_tokenId].price,
        tokenIdToOffer[_tokenId].index,
        tokenIdToOffer[_tokenId].tokenId,
        tokenIdToOffer[_tokenId].active);
    }

    function getAllTokensOnSale() public override view returns (uint256[] memory listOfOffers) {
        uint256 resultId = 0;

        for (uint256 index = 0; index < offers.length; index++) {
            if (offers[index].active == true) {
                resultId = SafeMath.add(resultId, 1);
            }
        }

        if (offers.length == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory allTokensOnSale = new uint256[](resultId);

            resultId = 0;
            for (uint256 index = 0; index < offers.length; index++) {
                if (offers[index].active == true) {
                    allTokensOnSale[resultId] = offers[index].tokenId;
                    resultId = SafeMath.add(resultId, 1);
                }
            }
            return allTokensOnSale;
        }
    }

    function _ownsItem(address _address, uint256 _tokenId) public view returns (bool) {
        return (_dragonSphere.ownerOf(_tokenId) == _address);
    }

    function setOffer(uint256 _price, uint256 _tokenId) public override {
        require(_ownsItem(msg.sender, _tokenId),
            "Only the owner of the game can initialize an offer");
        require(tokenIdToOffer[_tokenId].active == false,
            "You already created an offer for this game. Please remove it first before creating a new one.");
        require(_dragonSphere.isApprovedForAll(msg.sender, address(this)),
            "MarketPlace contract must first be an approved operator for your character");

        Offer memory _currentOffer = Offer({
        seller: msg.sender,
        price: _price,
        index: offers.length,
        tokenId: _tokenId,
        active: true
        });

        tokenIdToOffer[_tokenId] = _currentOffer;
        offers.push(_currentOffer);

        emit MarketTransaction("Offer created", msg.sender, _tokenId);
    }

    function removeOffer(uint256 _tokenId) public override {
        require(tokenIdToOffer[_tokenId].seller == msg.sender,
            "Only the owner of the Game can withdraw the offer.");

        offers[tokenIdToOffer[_tokenId].index].active = false;

        delete tokenIdToOffer[_tokenId];

        emit MarketTransaction("Offer removed", msg.sender, _tokenId);
    }
    //using SafeERC20 for IERC20;
    //address erc20 = 0x4bcec70b6c8e4d2eb9a6e32db596027525b54a95;

    function buyCharacter(uint256 _tokenId) public override payable whenNotPaused{
        Offer memory _currentOffer = tokenIdToOffer[_tokenId];

        require(_currentOffer.active, "There is no active offer for this character");
        //require(msg.value == _currentOffer.price, "The amount offered is not equal to the requested amount");


        delete tokenIdToOffer[_tokenId];
        offers[_currentOffer.index].active = false;

        // if (_currentOffer.price > 0) {
        //     _fundsToBeCollected[_currentOffer.seller] =
        //     SafeMath.add(_fundsToBeCollected[_currentOffer.seller], _currentOffer.price);

        // }

        _dragonSphere.transferFrom(_currentOffer.seller, msg.sender, _tokenId);

        _dragonSphere.transferBalance( msg.sender, _currentOffer.seller, _currentOffer.price); // __tokenId


        emit MarketTransaction("Game successfully purchased", msg.sender, _tokenId);
    }

    function getBalance() public override view returns (uint256) {
        return _fundsToBeCollected[msg.sender];
    }

    function withdrawFunds() public override payable whenNotPaused{

        require(_fundsToBeCollected[msg.sender] > 0, "No funds available at this time");

        uint256 toWithdraw = _fundsToBeCollected[msg.sender];


        _fundsToBeCollected[msg.sender] = 0;


        msg.sender.transfer(toWithdraw);


        assert(_fundsToBeCollected[msg.sender] == 0);


        emit MonetaryTransaction("Funds successfully received", msg.sender, toWithdraw);
    }


    // ***** TRAP ***
    function getOfferTrap(uint256 _trapId) public override view returns (
        address seller,
        uint256 price,
        uint256 index,
        uint256 tokenId,
        bool active) {

        require(trapIdToOffer[_trapId].active == true, "No active offer at this time");

        return (trapIdToOffer[_trapId].seller,
        trapIdToOffer[_trapId].price,
        trapIdToOffer[_trapId].index,
        trapIdToOffer[_trapId].tokenId,
        trapIdToOffer[_trapId].active);
    }

    function getAllTrapOnSale() public override view returns (uint256[] memory listOfOfferTraps) {
        uint256 resultId = 0;

        for (uint256 index = 0; index < offerTraps.length; index++) {
            if (offerTraps[index].active == true) {
                resultId = SafeMath.add(resultId, 1);
            }
        }

        if (offerTraps.length == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory allTrapsOnSale = new uint256[](resultId);

            resultId = 0;
            for (uint256 index = 0; index < offerTraps.length; index++) {
                if (offerTraps[index].active == true) {
                    allTrapsOnSale[resultId] = offerTraps[index].tokenId;
                    resultId = SafeMath.add(resultId, 1);
                }
            }
            return allTrapsOnSale;
        }
    }

    function _ownsItemTrap(address _address, uint256 _tokenId) public view returns (bool) {
        return (_dragonSphere.ownerOfTrap(_tokenId) == _address);
    }

    function setOfferTrap(uint256 _price, uint256 _tokenId) public override {
        require(_ownsItemTrap(msg.sender, _tokenId),
            "Only the owner of the trap can initialize an offer");
        require(trapIdToOffer[_tokenId].active == false,
            "You already created an offer for this trap. Please remove it first before creating a new one.");
        require(_dragonSphere.isApprovedForAllTrap(msg.sender, address(this)),
            "MarketPlace contract must first be an approved operator for your trap");

        OfferTrap memory _currentOffer = OfferTrap({
        seller: msg.sender,
        price: _price,
        index: offerTraps.length,
        tokenId: _tokenId,
        active: true
        });

        trapIdToOffer[_tokenId] = _currentOffer;
        offerTraps.push(_currentOffer);

        emit MarketTransaction("Offertrap created", msg.sender, _tokenId);
    }


    function removeOfferTrap(uint256 _tokenId) public override {
        require(trapIdToOffer[_tokenId].seller == msg.sender,
            "Only the owner of the trap can withdraw the offer.");

        offerTraps[trapIdToOffer[_tokenId].index].active = false;

        delete trapIdToOffer[_tokenId];

        emit MarketTransaction("OfferTrap removed", msg.sender, _tokenId);
    }
    //using SafeERC20 for IERC20;
    //address erc20 = 0x4bcec70b6c8e4d2eb9a6e32db596027525b54a95;

    function buyTrap(uint256 _tokenId) public override payable whenNotPaused{
        OfferTrap memory _currentOffer = trapIdToOffer[_tokenId];

        require(_currentOffer.active, "There is no active offertrap for this character");
        require(msg.value == _currentOffer.price, "The amount offerTraped is not equal to the requested amount");


        delete trapIdToOffer[_tokenId];
        offerTraps[_currentOffer.index].active = false;

        // if (_currentOffer.price > 0) {
        //     _fundsToBeCollected[_currentOffer.seller] =
        //     SafeMath.add(_fundsToBeCollected[_currentOffer.seller], _currentOffer.price);

        // }

        _dragonSphere.transferFromTrap(_currentOffer.seller, msg.sender, _tokenId);

        _dragonSphere.transferBalance( msg.sender, _currentOffer.seller, _currentOffer.price); // __tokenId


        emit MarketTransaction("Trap successfully purchased", msg.sender, _tokenId);
    }




}

pragma solidity ^0.6.12;

contract Ownable{

    address payable internal _owner;

    modifier onlyOwner(){
        require(msg.sender == _owner,
            "You need to be owner of the contract in order to access this functionality!");
        _;
    }

    constructor() public{
        _owner = msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

