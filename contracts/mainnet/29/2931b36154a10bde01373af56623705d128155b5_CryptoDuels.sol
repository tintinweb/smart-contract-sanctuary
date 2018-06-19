// CryptoDuels.co Copyright (c) 2018. All rights reserved.

pragma solidity ^0.4.20;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
}
contract Owned {
    address public ceoAddress;
    address public cooAddress;
    address private newCeoAddress;
    address private newCooAddress;

    function Owned() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }
    
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }
    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cooAddress
        );
        _;
    }
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        newCeoAddress = _newCEO;
    }
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        newCooAddress = _newCOO;
    }
    function acceptCeoOwnership() public {
        require(msg.sender == newCeoAddress);
        require(address(0) != newCeoAddress);
        ceoAddress = newCeoAddress;
        newCeoAddress = address(0);
    }
    function acceptCooOwnership() public {
        require(msg.sender == newCooAddress);
        require(address(0) != newCooAddress);
        cooAddress = newCooAddress;
        newCooAddress = address(0);
    }
}

contract CryptoDuels is Owned {
    using SafeMath for uint;

    struct PLAYER {
        uint wad; // eth balance
        uint lastJoin;
        uint lastDuel;
        
        uint listPosition;
    }
    
    mapping (address => PLAYER) public player;
    address[] public playerList;
    
    function getPlayerCount() public view returns (uint) {
        return playerList.length;
    }
    
    //================ ADMIN ================
    
    uint public divCut = 20; // 2%
    uint public divAmt = 0;
    
    function adminSetDiv(uint divCut_) public onlyCLevel {
        require(divCut_ < 50); // max total cut = 5% (some of which can be used for events)
        divCut = divCut_;
    }
    
    uint public fatigueBlock = 1; // can&#39;t duel too much in too few time
    uint public safeBlock = 1; // new players are safe for a while
    
    uint public blockDuelBegin = 0; // for special event
    uint public blockWithdrawBegin = 0; // for special event
    
    function adminSetDuel(uint fatigueBlock_, uint safeBlock_) public onlyCLevel {
        fatigueBlock = fatigueBlock_;
        safeBlock = safeBlock_;
    }
    
    // for special event
    function adminSetBlock(uint blockDuelBegin_, uint blockWithdrawBegin_) public onlyCLevel {
        require(blockWithdrawBegin_ < block.number + 6000); // at most 1 day

        blockDuelBegin = blockDuelBegin_;
        blockWithdrawBegin = blockWithdrawBegin_;
    }
    
    function adminPayout(uint wad) public onlyCLevel {
        if ((wad > divAmt) || (wad == 0)) // can only payout dividend, so player&#39;s ETHs are safe
            wad = divAmt;
        divAmt = divAmt.sub(wad);
        ceoAddress.transfer(wad);
    }
    
    //================ GAME ================

    event DEPOSIT(address indexed player, uint wad, uint result);
    event WITHDRAW(address indexed player, uint wad, uint result);
    event DUEL(address indexed player, address opp, bool isWin, uint wad);
    
    function deposit() public payable {
        require(msg.value > 0);
        
        PLAYER storage p = player[msg.sender];
        
        if (p.wad == 0) { // new player?
            p.lastJoin = block.number;
            p.listPosition = playerList.length;
            playerList.push(msg.sender);
        }
        
        p.wad = p.wad.add(msg.value);
        DEPOSIT(msg.sender, msg.value, p.wad);
    }

    function withdraw(uint wad) public {
        require(block.number >= blockWithdrawBegin);
        
        PLAYER storage p = player[msg.sender];
        
        if (wad == 0)
            wad = p.wad;
        require(wad != 0);

        p.wad = p.wad.sub(wad);
        msg.sender.transfer(wad); // send ETH
        WITHDRAW(msg.sender, wad, p.wad);
        
        if (p.wad == 0) { // quit game?
            playerList[p.listPosition] = playerList[playerList.length - 1];
            player[playerList[p.listPosition]].listPosition = p.listPosition;
            playerList.length--;
        }
    }
    
    function duel(address opp) public returns (uint, uint) {
        require(block.number >= blockDuelBegin);
        require(block.number >= fatigueBlock + player[msg.sender].lastDuel);
        require(block.number >= safeBlock + player[opp].lastJoin);
        require(!isContract(msg.sender));

        player[msg.sender].lastDuel = block.number;
        
        uint ethPlayer = player[msg.sender].wad;
        uint ethOpp = player[opp].wad;
        
        require(ethOpp > 0);
        require(ethPlayer > 0);
        
        // this is not a good random number, but good enough for now
        uint fakeRandom = uint(keccak256(block.blockhash(block.number-1), opp, divAmt, block.timestamp));
        
        bool isWin = (fakeRandom % (ethPlayer.add(ethOpp))) < ethPlayer;
        
        // send ETH from loser to winner
        address winner = msg.sender;
        address loser = opp;
        uint amt = ethOpp;
        if (!isWin) {
            winner = opp;
            loser = msg.sender;
            amt = ethPlayer;
        }

        uint cut = amt.mul(divCut) / 1000;
        uint realAmt = amt.sub(cut);
        divAmt = divAmt.add(cut);
        
        player[winner].wad = player[winner].wad.add(realAmt);    
        player[loser].wad = 0;
        
        // delete loser
        playerList[player[loser].listPosition] = playerList[playerList.length - 1];
        player[playerList[playerList.length - 1]].listPosition = player[loser].listPosition;
        playerList.length--;
        
        DUEL(msg.sender, opp, isWin, amt);
    }
    
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}