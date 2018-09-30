pragma solidity ^0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }
  
  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract LotteryData is Ownable{
    address[] public players;
    address[] public inviters;
    uint256[] public tickets;
    uint256[] public miniTickets;
    uint256[] public benzTickets;
    uint256[] public porscheTickets;
    

    mapping (address => uint256) public playerID;
    mapping (address => uint256) public inviterID;
    mapping (uint256 => address) public ticketToOwner;
    mapping (uint256 => address) public miniToOwner;
    mapping (uint256 => address) public benzToOwner;
    mapping (uint256 => address) public porscheToOwner; 
    mapping (address => uint256) ownerTicketCount;
    mapping (address => uint256) ownerMiniCount;
    mapping (address => uint256) ownerBenzCount;
    mapping (address => uint256) ownerPorscheCount;

    //Bears prop
    mapping (address => address) inviter;//invitee => inviter
    mapping (address => uint256) inviteeCount;//邀请总数
    mapping (address => uint256) inviteeAccumulator;//邀请总额
 
    mapping (address => uint256) public ownerAccWei;//投资wei总额
    mapping (address => uint8) ownerTeam;//0:bull 1:wolf 2:bear
    mapping (address => bool) public invalidPlayer;//false:valid true:invalid
    mapping (uint256 => bool) internal invalidPhone;
    mapping (uint256 => bool) internal invalidMini;
    mapping (uint256 => bool) internal invalidBenz;
    mapping (uint256 => bool) internal invalidPorsche;

    
    //Prize
    uint256[] internal phones;
    uint256[] internal phoneType;
    uint256 public miniWinner;
    uint256 public benzWinner;
    uint256 public porscheWinner;

    uint256 internal totalWei;
    uint256 internal accumulatedWei;
    uint256 internal accumulatedPlayer;
    uint256 internal accumulatedInvitor;
    uint256 public invalidTicketCount;
    uint256 public invalidMiniTicketCount;
    uint256 public invalidBenzTicketCount;
    uint256 public invalidPorscheTicketCount;
    //Events
    event Invalidate(address player, uint256 soldAmount, address inviter);
    event DrawPhone(uint256 id, address luckyOne, uint256 prizeType);
    event DrawMini(address luckyOne);
    event DrawBenz(address luckyOne);
    event DrawPorsche(address luckyOne);
}

contract LotteryExternal is LotteryData{
    using SafeMath for uint256;

    //ADMIN SET
    function setTeamByAddress(uint8 team, address player)
        external
        onlyOwner
    {
        ownerTeam[player] = team;
    }

    //使用户失效
    function invalidate(address player, uint256 soldAmount)
        external 
        onlyOwner 
    {
        invalidPlayer[player] = true;
        address supernode = inviter[player];
        ownerAccWei[player] = ownerAccWei[player].sub(soldAmount);
        totalWei = totalWei.sub(soldAmount);
        
        inviteeCount[supernode] = inviteeCount[supernode].sub(1);
        inviteeAccumulator[supernode] = inviteeAccumulator[supernode].sub(soldAmount);
        invalidTicketCount = invalidTicketCount.add(ownerTicketCount[player]);
        invalidMiniTicketCount = invalidMiniTicketCount.add(ownerMiniCount[player]);
        invalidBenzTicketCount = invalidBenzTicketCount.add(ownerBenzCount[player]);
        invalidPorscheTicketCount = invalidPorscheTicketCount.add(ownerPorscheCount[player]);
        desposeBear(supernode);
        emit Invalidate(player, soldAmount, supernode);
    }
    
    //有人失效后,判断推荐人获得抽奖号资格低于一半时就使抽奖号失效
    function desposeBear(address player)
        public
        onlyOwner
    {
        uint256 gotTickets = inviteeCount[player].div(10) + ownerAccWei[player].div(10**16);
        uint256 gotMTickets = inviteeCount[player].div(100);
        uint256 gotBTickets = inviteeCount[player].div(200);
        uint256 gotPTickets = inviteeCount[player].div(400);

        if(inviteeAccumulator[player].div(10**17)+ownerAccWei[player].div(10**16) >= gotTickets){
            gotTickets = inviteeAccumulator[player].div(10**17)+ownerAccWei[player].div(10**16);
        }
        if(inviteeAccumulator[player].div(((10**18)*5)) >= gotMTickets){
            gotMTickets = inviteeAccumulator[player].div(((10**18)*5));
        }
        if(inviteeAccumulator[player].div(((10**18)*10)) >= gotBTickets){
            gotBTickets = inviteeAccumulator[player].div(((10**18)*10));
        }
        if(inviteeAccumulator[player].div(((10**18)*20)) >= gotPTickets){
            gotPTickets = inviteeAccumulator[player].div(((10**18)*20));
        }

        if(ownerTicketCount[player] > gotTickets){
            for (uint8 index = 0; index < getTicketsByOwner(player).length; index++) {
                if(invalidPhone[getTicketsByOwner(player)[index]] == false){
                    invalidPhone[getTicketsByOwner(player)[index]] = true;
                    break;
                }
            }
            invalidTicketCount = invalidTicketCount.add(ownerTicketCount[player].sub(gotTickets));
        }
        if(ownerMiniCount[player] > gotMTickets){
            for (uint8 miniIndex = 0; miniIndex < getMiniByOwner(player).length; miniIndex++) {
                if(invalidPhone[getMiniByOwner(player)[miniIndex]] == false){
                    invalidPhone[getMiniByOwner(player)[miniIndex]] = true;
                    break;
                }
            }
            invalidMiniTicketCount = invalidMiniTicketCount.add(ownerMiniCount[player].sub(gotMTickets));
        }
        if(ownerBenzCount[player] > gotBTickets){
            for (uint8 benzIndex = 0; benzIndex < getBenzByOwner(player).length; benzIndex++) {
                if(invalidPhone[getBenzByOwner(player)[benzIndex]] == false){
                    invalidPhone[getBenzByOwner(player)[benzIndex]] = true;
                    break;
                }
            }
            invalidBenzTicketCount = invalidBenzTicketCount.add(ownerBenzCount[player].sub(gotBTickets));
        }
        if(ownerPorscheCount[player] > gotPTickets){
            for (uint8 porsIndex = 0; porsIndex < getPorscheByOwner(player).length; porsIndex++) {
                if(invalidPhone[getPorscheByOwner(player)[porsIndex]] == false){
                    invalidPhone[getPorscheByOwner(player)[porsIndex]] = true;
                    break;
                }
            }
            invalidPorscheTicketCount = invalidPorscheTicketCount.add(ownerPorscheCount[player].sub(gotPTickets));

        }
    }

    //获取用户所有手机抽奖码
    function getTicketsByOwner(address _owner) 
        public 
        view 
    returns(uint[]) 
    {
        uint[] memory result = new uint[](ownerTicketCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < tickets.length; i++) {
            if (ticketToOwner[i] == _owner) {
                result[counter] = i + 1;
                counter++;
            }
        }
        return result;
    }

    //获取用户mini抽奖码
    function getMiniByOwner(address _owner) 
        public 
        view 
    returns(uint[]) 
    {
        uint[] memory result = new uint[](ownerMiniCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < miniTickets.length; i++) {
            if (miniToOwner[i] == _owner) {
                result[counter] = i + 1;
                counter++;
            }
        }
        return result;
    }

    //获取用户benz抽奖码
    function getBenzByOwner(address _owner) 
        public 
        view 
    returns(uint[]) 
    {
        uint[] memory result = new uint[](ownerBenzCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < benzTickets.length; i++) {
            if (benzToOwner[i] == _owner) {
                result[counter] = i + 1;
                counter++;
            }
        }
        return result;
    }

    //获取用户porsche抽奖码
    function getPorscheByOwner(address _owner) 
        public 
        view 
    returns(uint[]) 
    {
        uint[] memory result = new uint[](ownerPorscheCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < porscheTickets.length; i++) {
            if (porscheToOwner[i] == _owner) {
                result[counter] = i + 1;
                counter++;
            }
        }
        return result;
    }

    function getPrizes()
        external
        view
    returns (uint256[]) 
    {
        return phones;
    }

    function getPlayerInfo(address player)
        external
        view
        returns(uint256, uint, bool, address, uint256, uint256)
    {
        return(
            ownerAccWei[player],
            ownerTeam[player],
            invalidPlayer[player],
            //Just For Bears
            inviter[player],
            inviteeCount[player],
            inviteeAccumulator[player]
        );
    }

    function getAccumulator()
        external
        view
        returns(uint256, uint256, uint256, uint256)
    {
        return(totalWei, accumulatedWei, accumulatedPlayer, accumulatedInvitor);
    }

    function getRate()
        external
        view
        returns(uint256, uint256, uint256, uint256)
    {
        return (
            tickets.length - invalidTicketCount,
            miniTickets.length - invalidMiniTicketCount,
            benzTickets.length - invalidBenzTicketCount,
            porscheTickets.length - invalidPorscheTicketCount
        );
    }
}

contract LotteryDraw is LotteryExternal{
    //增加抽奖号
    function createTicket(address player, uint count) 
        public 
        onlyOwner
    {
        for(uint i = 0;i < count;i++){
            uint256 ticket = tickets.push(tickets.length+1)-1;
            ticketToOwner[ticket] = player;
            ownerTicketCount[player] = ownerTicketCount[player].add(1);
        }
    }

    //增加Mini抽奖号
    function createMiniTicket(address player, uint count)
        public 
        onlyOwner
    {
        for(uint i = 0;i < count;i++){
            uint256 ticket = miniTickets.push(miniTickets.length+1)-1;
            miniToOwner[ticket] = player;
            ownerMiniCount[player] = ownerMiniCount[player].add(1);
        }
    }

    //增加Benz抽奖号
    function createBenzTicket(address player, uint count) 
        public 
        onlyOwner
    {
        for(uint i = 0;i < count;i++){
            uint256 ticket = benzTickets.push(benzTickets.length+1)-1;
            benzToOwner[ticket] = player;
            ownerBenzCount[player] = ownerBenzCount[player].add(1);
        }
    }

    //增加Porsche抽奖号
    function createPorscheTicket(address player, uint count) 
        public 
        onlyOwner
    {
        for(uint i = 0;i < count;i++){
            uint256 ticket = porscheTickets.push(porscheTickets.length+1)-1;
            porscheToOwner[ticket] = player;
            ownerPorscheCount[player] = ownerPorscheCount[player].add(1);
        }
    }

    //Draw
    function drawPhone()
        external
        onlyOwner
    returns (bool)
    {
        uint256 lucky = luckyOne(tickets.length);
        if(invalidPlayer[ticketToOwner[lucky]] == true) {
            return false;
        }
        else if(invalidPhone[lucky] == true){
            return false;
        }
        else{
            phones.push(lucky);
            uint256 prizeType = luckyOne(3);
            phoneType.push(prizeType);
            emit DrawPhone(phones.length, ticketToOwner[lucky], prizeType);
            return true;
        }
    }

    function drawMini()
        external
        onlyOwner
    returns (bool)
    {
        uint256 lucky = luckyOne(miniTickets.length);
        if(invalidPlayer[miniToOwner[lucky]] == true) {
            return false;
        }else if(invalidMini[lucky] == true){
            return false;
        }
        else{
            miniWinner = lucky;
            emit DrawMini(miniToOwner[lucky]);
            return true;
        }
    }

    function drawBenz()
        external
        onlyOwner
    returns (bool)
    {
        uint256 lucky = luckyOne(benzTickets.length);
        if(invalidPlayer[benzToOwner[lucky]] == true) {
            return false;
        }else if(invalidBenz[lucky] == true){
            return false;
        }
        else{
            benzWinner = lucky;
            emit DrawBenz(benzToOwner[lucky]);
            return true;
        }
    }

    function drawPorsche()
        external
        onlyOwner
    returns (bool)
    {
        uint256 lucky = luckyOne(porscheTickets.length);
        if(invalidPlayer[porscheToOwner[lucky]] == true) {
            return false;
        }else if(invalidPorsche[lucky] == true){
            return false;
        }
        else{
            porscheWinner = lucky;
            emit DrawPorsche(porscheToOwner[lucky]);
            return true;
        }
    }

    //For testing the random function
    function rollIt()
        public
        onlyOwner
    returns (bool)
    {
        uint256 lucky = luckyOne(tickets.length);
        if(invalidPlayer[ticketToOwner[lucky]] == true) {
            return false;
        }else{
            phones.push(lucky);
            return true;
        }

    }

    function luckyOne(uint256 candidate)
        public
        view
    returns (uint256)
    {
        uint256 seed = uint256(
            keccak256(  
                abi.encodePacked(
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
        )));
        uint256 lucky = seed % candidate;
        return lucky;
    }
}

contract Lottery is LotteryDraw{
    using SafeMath for uint256;
    //Test
    function setInviteeAccumulator(address player, uint256 amount)
        external
        onlyOwner
    {
        inviteeAccumulator[player] = amount;
        updateBearCount(player);
    }

    function setInviteeCount(address player, uint256 count)
        external
        onlyOwner
    {
        inviteeCount[player] = count;
        updateBearCount(player);
    }

        //ADMIN SET
    function setTeamByAddress(uint8 team, address player)
        external
        onlyOwner
    {
        ownerTeam[player] = team;
    }

    //更新用户累计购买以太
    function updatePlayerEth(address player,uint256 weiAmount, address supernode)
        external
        onlyOwner
    returns (uint256)
    {
        if(playerID[player] == 0){
            accumulatedPlayer = accumulatedPlayer.add(1);
            playerID[player] = accumulatedPlayer;
        }
        ownerAccWei[player] = ownerAccWei[player].add(weiAmount);
        totalWei = totalWei.add(weiAmount);
        accumulatedWei = accumulatedWei.add(weiAmount);
        //为邀请人增加
        inviter[player] = supernode;
        inviteeCount[supernode] = inviteeCount[supernode].add(1);
        inviteeAccumulator[supernode] = inviteeAccumulator[supernode].add(weiAmount);
        if(inviterID[supernode] == 0){
            accumulatedInvitor = accumulatedInvitor.add(1);
            inviterID[supernode] = accumulatedInvitor;
        }

        if(ownerTeam[player] == 0) {
            //牛队
            uint256 gotMTickets = ownerAccWei[player].div(10**18);
            uint256 gotBTickets = ownerAccWei[player].div(10**18).div(2);
            uint256 gotPTickets = ownerAccWei[player].div(10**18).div(5);

            createMiniTicket(player, gotMTickets - ownerMiniCount[player]);
            createBenzTicket(player, gotBTickets - ownerBenzCount[player]);
            createPorscheTicket(player, gotPTickets - ownerPorscheCount[player]);
        }else if(ownerTeam[player] == 1) {
            //狼队//龙队
            uint256 gotTickets = ownerAccWei[player].div(10**16);
            createTicket(player, gotTickets - ownerTicketCount[player]);
            
        } 
        if(ownerTeam[player] == 2){
            uint256 gotPhones = ownerAccWei[player].div(10**16);
            createTicket(player, gotPhones - ownerTicketCount[player]);
            updateBearCount(player);
        }
        return ownerAccWei[player];
    } 

    function updateBearCount(address player)
        public
        onlyOwner
    {
        if(ownerAccWei[player] < 10**16){
            return;
        }

        uint256 gotTickets = inviteeCount[player].div(10) + ownerAccWei[player].div(10**16);
        uint256 gotMTickets = inviteeCount[player].div(100);
        uint256 gotBTickets = inviteeCount[player].div(200);
        uint256 gotPTickets = inviteeCount[player].div(400);

        if(inviteeAccumulator[player].div(10**17) >= gotTickets){
            gotTickets = inviteeAccumulator[player].div(10**17)+ownerAccWei[player].div(10**16);
        }
        if(inviteeAccumulator[player].div(((10**18)*5)) >= gotMTickets){
            gotMTickets = inviteeAccumulator[player].div(((10**18)*5));
        }
        if(inviteeAccumulator[player].div(((10**18)*10)) >= gotBTickets){
            gotBTickets = inviteeAccumulator[player].div(((10**18)*10));
        }
        if(inviteeAccumulator[player].div(((10**18)*20)) >= gotPTickets){
            gotPTickets = inviteeAccumulator[player].div(((10**18)*20));
        }

        createTicket(player, gotTickets - ownerTicketCount[player]);
        createMiniTicket(player, gotMTickets - ownerMiniCount[player]);
        createBenzTicket(player, gotBTickets - ownerBenzCount[player]);
        createPorscheTicket(player, gotPTickets - ownerPorscheCount[player]);
    }


}