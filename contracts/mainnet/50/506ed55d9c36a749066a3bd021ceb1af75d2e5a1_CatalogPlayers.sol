pragma solidity ^0.4.16;

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) pure internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

contract ERC721 {
   // ERC20 compatible functions
   function totalSupply() public view returns (uint256 total);
   function balanceOf(address _owner) public view returns (uint balance);
   // Functions that define ownership
   function ownerOf(uint256 _tokenId) public view returns (address owner);
   function approve(address _to, uint256 _tokenId) external;
   function transfer(address _to, uint256 _tokenId) external;
   function tokensOfOwner(address _owner) public view returns (uint256[] ownerTokens);
   // Token metadata
   //function tokenMetadata(uint256 _tokenId) view returns (string infoUrl);
   // Events
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

contract FMWorldAccessControl {
    address public ceoAddress;
    address public cooAddress;
    
    bool public pause = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyC() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress
        );
        _;
    }

    modifier notPause() {
        require(!pause);
        _;
    }
    
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }
    
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }


    function setPause(bool _pause) external onlyC {
        pause = _pause;
    }
    

}

contract CatalogPlayers is FMWorldAccessControl
{
    struct ClassPlayer
    {
        uint32 talent;
        uint32 tactics;
        uint32 dribbling;
        uint32 kick;
        uint32 speed;
        uint32 pass;
        uint32 selection;
    }

    struct boxPlayer
    {
        uint256 price;
        uint256 countSales;
        ClassPlayer[] classPlayers;
    }
    
    function _set1() onlyCEO public {
        //init for dev, def-2
        newClassPlayer(2,2,5,10,2,3,5,5,10);
        newClassPlayer(2,2,6,10,2,3,6,6,7);
        newClassPlayer(2,2,5,14,5,2,6,3,5);
        newClassPlayer(2,2,6,8,4,4,9,4,7);
        newClassPlayer(2,2,5,15,1,1,3,5,12);
        newClassPlayer(2,2,6,9,3,3,6,6,9);
        newClassPlayer(2,2,5,11,1,2,6,5,10);
        newClassPlayer(2,2,6,9,3,3,7,7,5);
        newClassPlayer(2,2,5,9,2,4,6,4,8);
        newClassPlayer(2,2,7,14,3,1,5,6,9);
        setBoxPrice(2,2,390000000000000000);
        //
    }
    
    function _set2() onlyCEO public {
        newClassPlayer(1,2,3,7,1,1,5,5,8);
        newClassPlayer(1,2,4,7,1,2,4,4,6);
        newClassPlayer(1,2,3,11,2,1,4,2,5);
        newClassPlayer(1,2,4,5,2,2,7,3,7);
        newClassPlayer(1,2,3,10,1,1,2,3,10);
        newClassPlayer(1,2,4,4,2,2,6,6,6);
        newClassPlayer(1,2,3,8,1,2,1,3,10);
        newClassPlayer(1,2,4,5,3,3,5,5,3);
        newClassPlayer(1,2,3,6,2,2,4,3,6);
        newClassPlayer(1,2,5,5,2,1,5,6,9);
        setBoxPrice(1,2,90000000000000000);
        //
    }
    
    function _set3() onlyCEO public {
        //init for dev, def-3
        newClassPlayer(3,2,7,14,2,3,6,6,13);
        newClassPlayer(3,2,8,15,3,2,6,6,12);
        newClassPlayer(3,2,7,21,3,2,4,3,12);
        newClassPlayer(3,2,8,15,4,4,9,4,10);
        newClassPlayer(3,2,7,20,1,1,2,4,19);
        newClassPlayer(3,2,8,12,6,6,6,6,10);
        newClassPlayer(3,2,7,16,1,2,8,5,13);
        newClassPlayer(3,2,8,15,3,3,8,7,8);
        newClassPlayer(3,2,8,16,2,4,6,4,17);
        newClassPlayer(3,2,9,14,3,1,8,9,15);
        setBoxPrice(3,2,690000000000000000);
        //
    }    
    
    function _set4() onlyCEO public {
        // //gk-1
        newClassPlayer(1,1,3,0,0,0,27,0,0);
        newClassPlayer(1,1,4,0,0,0,24,0,0);
        newClassPlayer(1,1,3,0,0,0,25,0,0);
        newClassPlayer(1,1,4,0,0,0,26,0,0);
        newClassPlayer(1,1,3,0,0,0,27,0,0);
        newClassPlayer(1,1,4,0,0,0,26,0,0);
        newClassPlayer(1,1,3,0,0,0,25,0,0);
        newClassPlayer(1,1,4,0,0,0,24,0,0);
        newClassPlayer(1,1,3,0,0,0,23,0,0);
        newClassPlayer(1,1,5,0,0,0,28,0,0);
        setBoxPrice(1,1,190000000000000000);
        //
    }

    function _set5() onlyCEO public {
        // //gk-2
        newClassPlayer(2,1,5,0,0,0,35,0,0);
        newClassPlayer(2,1,6,0,0,0,34,0,0);
        newClassPlayer(2,1,5,0,0,0,35,0,0);
        newClassPlayer(2,1,6,0,0,0,36,0,0);
        newClassPlayer(2,1,5,0,0,0,37,0,0);
        newClassPlayer(2,1,6,0,0,0,36,0,0);
        newClassPlayer(2,1,5,0,0,0,35,0,0);
        newClassPlayer(2,1,6,0,0,0,34,0,0);
        newClassPlayer(2,1,5,0,0,0,33,0,0);
        newClassPlayer(2,1,7,0,0,0,38,0,0);
        setBoxPrice(2,1,490000000000000000);
        //
    }

    function _set6() onlyCEO public {
        // //gk-3
        newClassPlayer(3,1,7,0,0,0,44,0,0);
        newClassPlayer(3,1,8,0,0,0,44,0,0);
        newClassPlayer(3,1,7,0,0,0,45,0,0);
        newClassPlayer(3,1,8,0,0,0,46,0,0);
        newClassPlayer(3,1,7,0,0,0,47,0,0);
        newClassPlayer(3,1,8,0,0,0,46,0,0);
        newClassPlayer(3,1,7,0,0,0,45,0,0);
        newClassPlayer(3,1,8,0,0,0,44,0,0);
        newClassPlayer(3,1,8,0,0,0,49,0,0);
        newClassPlayer(3,1,9,0,0,0,50,0,0);
        setBoxPrice(3,1,790000000000000000);
        //
    }

    function _set7() onlyCEO public {
        //mid-1
        newClassPlayer(1,3,3,5,2,3,4,7,6);
        newClassPlayer(1,3,4,6,3,3,2,7,3);
        newClassPlayer(1,3,3,5,2,2,3,11,2);
        newClassPlayer(1,3,4,6,2,3,2,9,4);
        newClassPlayer(1,3,3,10,1,2,3,10,1);
        newClassPlayer(1,3,4,7,3,3,5,4,4);
        newClassPlayer(1,3,3,9,2,3,2,8,2);
        newClassPlayer(1,3,4,6,3,3,3,6,3);
        newClassPlayer(1,3,3,7,2,2,3,6,1);
        newClassPlayer(1,3,5,8,2,3,3,8,4);
        setBoxPrice(1,3,250000000000000000);
    }
    
    function _set8() onlyCEO public {
        //mid-2
        newClassPlayer(2,3,5,10,3,4,3,10,5);
        newClassPlayer(2,3,6,9,2,4,5,10,4);
        newClassPlayer(2,3,5,13,3,3,1,14,1);
        newClassPlayer(2,3,6,9,2,3,12,8,2);
        newClassPlayer(2,3,5,14,1,1,3,15,3);
        newClassPlayer(2,3,6,10,1,2,6,9,8);
        newClassPlayer(2,3,5,12,2,2,3,11,2);
        newClassPlayer(2,3,6,11,3,3,2,9,4);
        newClassPlayer(2,3,5,12,3,3,3,9,3);
        newClassPlayer(2,3,7,15,2,3,3,14,1);
        setBoxPrice(2,3,550000000000000000);
    }
    
    function _set11() onlyCEO public {
        //mid-3
        newClassPlayer(3,3,7,4,5,5,5,20,5);
        newClassPlayer(3,3,8,15,3,4,7,8,7);
        newClassPlayer(3,3,7,10,3,2,10,10,10);
        newClassPlayer(3,3,8,15,3,2,10,8,8);
        newClassPlayer(3,3,7,8,2,2,9,16,10);
        newClassPlayer(3,3,8,13,3,4,10,8,8);
        newClassPlayer(3,3,7,12,4,4,7,16,2);
        newClassPlayer(3,3,8,12,3,1,5,12,11);
        newClassPlayer(3,3,8,12,3,3,10,11,10);
        newClassPlayer(3,3,9,17,1,2,10,15,5);
        setBoxPrice(3,3,850000000000000000);
    }    
    
    function _set9() onlyCEO public {
        //fw-1
        newClassPlayer(1,4,3,2,6,7,8,2,2);
        newClassPlayer(1,4,4,5,3,7,6,1,2);
        newClassPlayer(1,4,3,1,4,11,5,2,2);
        newClassPlayer(1,4,4,3,3,6,7,2,5);
        newClassPlayer(1,4,3,1,5,10,9,1,1);
        newClassPlayer(1,4,4,2,5,7,8,2,2);
        newClassPlayer(1,4,3,1,3,8,10,1,2);
        newClassPlayer(1,4,4,5,2,5,5,4,3);
        newClassPlayer(1,4,3,2,5,6,6,2,2);
        newClassPlayer(1,4,5,2,4,9,11,1,1);
        setBoxPrice(1,4,350000000000000000);
    }    

    function _set10() onlyCEO public {
        //fw-2
        newClassPlayer(2,4,5,3,3,12,11,3,3);
        newClassPlayer(2,4,6,1,5,12,12,2,2);
        newClassPlayer(2,4,5,1,1,14,14,2,3);
        newClassPlayer(2,4,6,4,6,9,13,2,2);
        newClassPlayer(2,4,5,1,4,15,15,1,1);
        newClassPlayer(2,4,6,3,3,10,10,5,5);
        newClassPlayer(2,4,5,2,2,15,13,1,2);
        newClassPlayer(2,4,6,4,4,11,13,1,1);
        newClassPlayer(2,4,5,2,8,9,9,2,3);
        newClassPlayer(2,4,7,1,14,7,14,1,1);
        setBoxPrice(2,4,650000000000000000);
    }
    
    function CatalogPlayers() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;

        //fw-3
        newClassPlayer(3,4,7,3,14,4,14,4,5);
        newClassPlayer(3,4,8,2,8,15,15,3,1);
        newClassPlayer(3,4,7,3,9,10,21,1,1);
        newClassPlayer(3,4,8,3,12,15,12,2,2);
        newClassPlayer(3,4,7,4,15,8,15,3,2);
        newClassPlayer(3,4,8,3,12,13,10,5,3);
        newClassPlayer(3,4,7,1,10,12,16,3,3);
        newClassPlayer(3,4,8,1,12,12,11,6,2);
        newClassPlayer(3,4,8,2,13,12,16,4,2);
        newClassPlayer(3,4,9,1,16,17,13,2,1);
        setBoxPrice(3,4,950000000000000000);

    }

    mapping(uint256 => mapping(uint256 => boxPlayer)) public boxPlayers;

    function newClassPlayer(
        uint256 _league,
        uint256 _position,
        uint32 _talent,
        uint32 _tactics,
        uint32 _dribbling,
        uint32 _kick,
        uint32 _speed,
        uint32 _pass,
        uint32 _selection
    )
        public onlyCEO returns(uint256)
    {
        ClassPlayer memory player = ClassPlayer({
            talent: _talent,
            tactics: _tactics,
            dribbling: _dribbling,
            kick: _kick,
            speed: _speed,
            pass: _pass,
            selection: _selection
        });
        return boxPlayers[_league][_position].classPlayers.push(player) - 1;

    }

    function getClassPlayers(uint256 _league, uint256 _position, uint256 _index) public view returns(uint32[7] skills)
    {
        ClassPlayer memory classPlayer = boxPlayers[_league][_position].classPlayers[_index];
        skills[0] = classPlayer.talent;
        skills[1] = classPlayer.tactics;
        skills[2] = classPlayer.dribbling;
        skills[3] = classPlayer.kick;
        skills[4] = classPlayer.speed;
        skills[5] = classPlayer.pass;
        skills[6] = classPlayer.selection;
    }

    function getLengthClassPlayers(uint256 _league, uint256 _position) public view returns (uint256)
    {
        return boxPlayers[_league][_position].classPlayers.length;
    }

    function setBoxPrice(uint256 _league, uint256 _position, uint256 _price) onlyCEO public
    {
        boxPlayers[_league][_position].price = _price;
    }

    function getBoxPrice(uint256 _league, uint256 _position) public view returns (uint256)
    {
        return boxPlayers[_league][_position].price + ((boxPlayers[_league][_position].countSales / 10) * (boxPlayers[_league][_position].price / 100));
    }
    
    function incrementCountSales(uint256 _league, uint256 _position) public onlyCOO {
        boxPlayers[_league][_position].countSales++;
    }
    
    function getCountSales(uint256 _league, uint256 _position) public view returns(uint256) {
        return boxPlayers[_league][_position].countSales;
    }
}