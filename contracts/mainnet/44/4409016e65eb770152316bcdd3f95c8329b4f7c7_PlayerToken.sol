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
   function totalSupply() public view returns (uint256 total);
   function balanceOf(address _owner) public view returns (uint balance);
   function ownerOf(uint256 _tokenId) public view returns (address owner);
   function approve(address _to, uint256 _tokenId) external;
   function transfer(address _to, uint256 _tokenId) external;
   function tokensOfOwner(address _owner) public view returns (uint256[] ownerTokens);
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
contract PlayerToken is ERC721, FMWorldAccessControl {

    struct Player {
        uint32 talent;
        uint32 tactics;
        uint32 dribbling;
        uint32 kick;
        uint32 speed;
        uint32 pass;
        uint32 selection;
        uint256 position;
    }

    string public name = "Football Manager Player";
    string public symbol = "FMP";

    Player[] public players;

    mapping (address => uint256) ownerPlayersCount;
    mapping (uint256 => address) playerOwners;
    mapping (uint256 => address) public playerApproved;
    
    function PlayerToken() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownerPlayersCount[_owner];
    }

    function totalSupply() public view returns (uint256) {
        return players.length;
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = playerOwners[_tokenId];
        require(owner != address(0));
    }

    function approve(address _to, uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId));
        playerApproved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownerPlayersCount[_to]++;
        playerOwners[_tokenId] = _to;
        if (_from != address(0)) {
            ownerPlayersCount[_from]--;
            delete playerApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) external {
        require(_to != address(0));
        require(msg.sender == ownerOf(_tokenId));
        _transfer(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        require(_to != address(0));
        require(playerApproved[_tokenId] == msg.sender);
        require(_from == ownerOf(_tokenId));
        _transfer(_from, _to, _tokenId);
    }

    function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
        uint256 playersCount = balanceOf(_owner);
        if (playersCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](playersCount);
            uint256 totalPlayers = totalSupply();
            uint256 playerId;
            uint256 resultIndex = 0;
            for (playerId = 1; playerId <= totalPlayers; playerId++) {
                if (playerOwners[playerId] == _owner) {
                    result[resultIndex] = playerId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function getPlayer(uint256 _playerId) public view returns(
        uint32 talent,
        uint32 tactics,
        uint32 dribbling,
        uint32 kick,
        uint32 speed,
        uint32 pass,
        uint32 selection,
        uint256 position
    ) {
        Player memory player = players[_playerId];
        talent = player.talent;
        tactics = player.tactics;
        dribbling = player.dribbling;
        kick = player.kick;
        speed = player.speed;
        pass = player.pass;
        selection = player.selection;
        position = player.position;
    }

    function getPosition(uint256 _playerId) public view returns(uint256) {
        Player memory player = players[_playerId];
        return player.position;
    }

    function createPlayer(
            uint32[7] _skills,
            uint256 _position,
            address _owner
    )
        public onlyCOO
        returns (uint256)
    {
        Player memory player = Player(_skills[0], _skills[1], _skills[2], _skills[3], _skills[4], _skills[5], _skills[6], _position);
        uint256 newPlayerId = players.push(player) - 1;
         _transfer(0, _owner, newPlayerId);
        return newPlayerId;
    }
}