/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address public owner;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

contract PrizeFactory is Owner {
    using SafeMath for uint256;
    event NewPrize(address to);
    struct Prize{
        uint16 typeNft;
    }
    Prize[] public prizes;
    mapping (uint => address) public prizeToOwner;
    mapping (address => uint)  ownerPrizeCount;
    //  每轮奖品池
    mapping (uint => uint[]) public prizeRoundLength;
    mapping (address => bool) public playersBool;
    mapping (uint16 => string) public nftTypeName;
    constructor ()  {
            round = 1;
            nftTypeName[uint16(1)] = "1";
            nftTypeName[uint16(2)] = "2";
            nftTypeName[uint16(3)] = "3";
            nftTypeName[uint16(4)] = "memory";
            nftTypeName[uint16(5)] = "tiger";
            nftTypeName[uint16(6)] = "nft";
            uint[17] memory x = [uint(1),uint(4),4,4,4,5,5,5,5,uint(6),6,6,6,6,6,6,6];
            uint[17] memory y = [uint(2),uint(4),4,4,4,5,5,5,5,uint(6),6,6,6,6,6,6,6];
            uint[17] memory z = [uint(3),uint(4),4,4,4,5,5,5,5,uint(6),6,6,6,6,6,6,6];
            prizeRoundLength[uint(1)] = x;
            prizeRoundLength[uint(2)] = y;
            prizeRoundLength[uint(3)] = z;
    }
    //  总奖品池
//    mapping (address => uint) public ownerPrizeCount;
    //参与者
    address[] public players;
    // 抽第几奖
    uint8 public round;

    function _createPrize(uint16 typeNft,address to) internal {
//        typeNft = _getNftTypeByIndex(index);
        prizes.push(Prize(typeNft));
        uint id =prizes.length -1;
        prizeToOwner[id] = to;
        ownerPrizeCount[to];
        emit NewPrize(to);
    }
    
    function createPrize(uint16 typeNft,address to ) internal {
//        require(ownerZombieCount[msg.sender] == 0);
        _createPrize(typeNft,to);
    }

}

contract PrizeLottery is PrizeFactory {

    function joinedAlready(address _participant)private view returns(bool){
        return playersBool[_participant];
    }

    function play() public  {
        // require(joinedAlready(msg.sender) == false);
        players.push(msg.sender);
        playersBool[msg.sender] =true;
    }
     function setRounds(uint[] memory _array) public  {
          prizeRoundLength[round] = _array;
    }
      function removeAtIndex(uint  _index, uint[] memory _array) public pure returns( uint[] memory) {
        if (_index >= _array.length) return _array;
        for (uint i = _index; i < _array.length-1; i++) {
            _array[i] = _array[i+1];
        }
        delete _array[_array.length-1];
        return _array;
    }
    function removeAtIndexAddress(uint  _index, address[] memory _array) public pure returns( address[] memory) {
        if (_index >= _array.length) return _array;
        for (uint i = _index; i < _array.length-1; i++) {
            _array[i] = _array[i+1];
        }
        delete _array[_array.length-1];
        return _array;
    }

    //抽奖
    function lotteryOnRound() isOwner public {

        require(players.length >= 2);
        uint[] memory nftTmp  = (prizeRoundLength[round]);
        // for (uint i = 0; i < nftTmp.length; i++) {
        //     uint rand = uint(keccak256(abi.encodePacked(block.difficulty)));
        //     uint256 res = uint256(rand);
        //     uint index = res % players.length;
        //     address winner = players[index];
        //     uint nftIndex = res % nftTmp.length;
        //     uint16 nftType = uint16( nftTmp[nftIndex]);
        //     createPrize(nftType,winner);
        // }
        address[] memory playersTmp  = players;
        while (nftTmp.length >0){
            uint rand = uint(keccak256(abi.encodePacked(block.difficulty)));
            uint256 res = uint256(rand);
            uint index = res % playersTmp.length;
            address winner = playersTmp[index];
            uint nftIndex = res % nftTmp.length;
            uint16 nftType = uint16( nftTmp[nftIndex]);
            createPrize(nftType,winner); 
            nftTmp = removeAtIndex(nftIndex,nftTmp);
            playersTmp = removeAtIndexAddress(nftIndex,playersTmp);
        }
        round++;
        delete players;
    }

    // 1. 返回所有玩家
    function getPlayers() public view  returns(address[] memory) {
        return players;
    }
    // 2. 返回玩家人数
    function getPlayersCount() public view returns(uint256) {
        return players.length;
    }
    //   3· 余额
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
}

contract PrizeHelper is PrizeLottery {
     modifier onlyOwnerOf(uint _prizeT) {
        require(msg.sender == prizeToOwner[_prizeT]);
        _;
    }
    function getPrizesByOwner(address _owner) public view returns(   uint[] memory) {
        uint[] memory result = new uint[](ownerPrizeCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < prizes.length; i++) {
            if (prizeToOwner[i] == _owner) {
            result[counter] = i;
            counter++;
            }
        }
        return result;
    }

    // function setRoundLength(uint round, uint _newName) external onlyOwner {
    //     prizes[_zombieId].name = _newName;
    // }
}

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    function balanceOf(address _owner) external view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function transfer(address _to, uint256 _tokenId) external;
    function approve(address _to, uint256 _tokenId) external;
    function takeOwnership(uint256 _tokenId) external;
}

contract PrizeOwnership is PrizeHelper,ERC721 {
  
  using SafeMath for uint256;

  mapping (uint => address) prizeApprovals;

  function balanceOf(address _owner) public override view returns  (uint256 _balance) {
    return ownerPrizeCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public override view returns (address _owner) {
    return prizeToOwner[_tokenId];
  }

  function _transferNft(address _from, address _to, uint256 _tokenId) private  {
    ownerPrizeCount[_to] = ownerPrizeCount[_to].add(1);
    ownerPrizeCount[msg.sender] = ownerPrizeCount[msg.sender].sub(1);
    prizeToOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
  }

  function transfer( address _to, uint256 _tokenId) public override onlyOwnerOf(_tokenId) {
      _transferNft(msg.sender, _to, _tokenId);
    }
    // 
    // function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    //     _transfer(msg.sender, _to, _tokenId);
    // }
  function approve(address _approved, uint256 _tokenId) public override  onlyOwnerOf(_tokenId) {
    prizeApprovals[_tokenId] = _approved;
      emit Approval(msg.sender, _approved, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) public override   {
        require(prizeApprovals[_tokenId] == msg.sender);
        address ownert = ownerOf(_tokenId);
        _transferNft(ownert, msg.sender, _tokenId);
    }
}