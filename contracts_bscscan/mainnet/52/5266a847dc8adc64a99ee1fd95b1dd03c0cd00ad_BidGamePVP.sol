/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

/**
 BIDDING BSC PLAYER VS PLAYER (PVP)
 UI UX : Visit https://wishlambo.com/game/
 ( Project by WishLambo WLB - All transactions 10% Tax for Buy Back Token Wishlambo.io )

 START BID ONLY 0.005 BNB WIN Up 1000 BNB / WIN 25,000x ( POSSIBLE )

 Very Addictive BSC GAME | SIMPLE & EASY!

 JUST BID (0.005 BNB) & HOLD in 5 Minutes = THE LAST BID WIN ALL BNB POOL !

 * ALSO ALL CAN BID LIKE YOU ^_^
 * Time will be reset if another BID 

 50% Commission Each Refferal BID ( UNLIMITED )
 ENJOY FIGHTING BIDDING GAME PLAY!


*/

pragma solidity 0.6.2;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the _newOwnerowner.
     */
    modifier onlyMidWayOwner() {
        require(_newOwner == _msgSender(), "Ownable: caller is not the Mid Way Owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _newOwner = newOwner;
    }
    
    /**
     * @dev receive ownership of the contract by _newOwner. Previous owner assigned this _newOwner to receive ownership. 
     * Can only be called by the current _newOwner.
     */
    function recieveOwnership() public virtual onlyMidWayOwner {
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}

contract BidGamePVP is Ownable {

    event AnnounceWinner(address playerAddress, uint256 moneypot);
    event NewBid(address playerAddress, uint256 bid, uint256 moneypot);
    
    struct Player {
        uint256 funds;
        bool exists;
    }
    
    struct GameCycle
    {
        uint256 startTime;
        address startAddress;
        uint256 endTime;
        address finalAddress;
        uint256 moneypot;
        bool moneydistributed;
    }
    
    GameCycle[] gameCycle;
    
    mapping(address => Player) private players;
    
    uint256 private devTax = 50;
    uint256 private devFunds = 0;
    uint256 private totalPlayers = 0;
    uint256 private cycleTime = 300;
    uint256 private bidCost = 0.005 ether;
    uint256 private currentCycle = 0;

    function GetCycleTime() public view returns(uint256 _cycleTime){
        _cycleTime = cycleTime;
    }
    
    function SetCycleTime(uint256 sec) public onlyOwner() {
        cycleTime = sec;
    }
    
    function SetBidCost(uint256 cost) public onlyOwner() {
        bidCost = cost;
    }
    
    function GetBidCost() public view returns (uint256 _bidCost) {
        _bidCost = bidCost;
    }
    
    function GetDevFunds() public onlyOwner() view returns (uint256 _devFunds) {
        _devFunds = devFunds;
    }
    
    function GetCurrentCycle() public view returns (uint256 _currentCycle) {
        _currentCycle = currentCycle;
    }
    
    function GetGameByCycle(uint256 cycle) public view returns (uint256 _startTime, address _startAddress, uint256 _endTime, address _finalAddress, uint256 _moneypot, bool _moneydistributed) {
        _startTime = gameCycle[cycle].startTime;
        _startAddress = gameCycle[cycle].startAddress;
        _endTime = gameCycle[cycle].endTime;
        _finalAddress = gameCycle[cycle].finalAddress;
        _moneypot = gameCycle[cycle].moneypot;
        _moneydistributed = gameCycle[cycle].moneydistributed;
    }
    
    function GetCurrentGame() public view returns (uint256 _startTime, address _startAddress, uint256 _endTime, address _finalAddress, uint256 _moneypot, bool _moneydistributed) {
        _startTime = gameCycle[currentCycle].startTime;
        _startAddress = gameCycle[currentCycle].startAddress;
        _endTime = gameCycle[currentCycle].endTime;
        _finalAddress = gameCycle[currentCycle].finalAddress;
        _moneypot = gameCycle[currentCycle].moneypot;
        _moneydistributed = gameCycle[currentCycle].moneydistributed;

    }
    
    function GetPlayerFunds(address addr) public view returns (uint256 _playerFunds) {
        require(players[addr].exists);
        _playerFunds = players[addr].funds;
    }
    
    function WithdrawDevFunds() public onlyOwner() {
        require(devFunds > 0);
        if (msg.sender.send(devFunds)) {
            devFunds = 0;
        }
    }
    
    function WithdrawFunds() public {
        require(players[msg.sender].exists);
        require(players[msg.sender].funds > 0);
        if (msg.sender.send(players[msg.sender].funds)) {
            players[msg.sender].funds = 0;
        }
    }
    
    function GetPlayersCount() public view returns (uint256 _playerCount) {
        _playerCount = totalPlayers;
    }
    
    function DistributeRewards() public {
        if (gameCycle.length == 0) {
            return;
        }
        uint256 cycleIdx = currentCycle;
        if (currentCycle > 1) {
            cycleIdx = currentCycle - 1;
        }
        
        require(gameCycle[cycleIdx].endTime < block.timestamp);
        require(gameCycle[cycleIdx].moneypot > 0);
        if (gameCycle[cycleIdx].moneydistributed == true) {
            return;
        }
        
        players[gameCycle[cycleIdx].finalAddress].funds += gameCycle[cycleIdx].moneypot;
        gameCycle[cycleIdx].moneydistributed = true;
        emit AnnounceWinner(gameCycle[cycleIdx].finalAddress, gameCycle[cycleIdx].moneypot);
        
    }
    
    function ManagePlayers(address sender) private {
        if (!players[sender].exists) {
            players[sender].funds = 0;
            players[sender].exists = true;
            totalPlayers += 1;
        }
    }
    
    function Bid() external payable {
        require(gameCycle[currentCycle].endTime > block.timestamp);
        require(msg.value >= bidCost);
        ManagePlayers(msg.sender);
        gameCycle[currentCycle].finalAddress = msg.sender;
        devFunds += (msg.value * devTax) / 100;
        uint256 bidval = (msg.value * (100-devTax) / 100);
        gameCycle[currentCycle].moneypot += bidval;
        gameCycle[currentCycle].endTime = block.timestamp + cycleTime;
        emit NewBid(msg.sender, bidval, gameCycle[currentCycle].moneypot);
    }
    
    function RunCycle(uint256 time, address sender, uint256 value) private {
        devFunds += (value * devTax) / 100;
        gameCycle.push(GameCycle(time, sender, time + cycleTime, sender, (value * (100-devTax)) / 100, false));
    }
    
    function Start() external payable {
        require(msg.value >= bidCost);
        if (currentCycle == 0) {
            if (gameCycle.length == 0) {
                DistributeRewards();
                RunCycle(block.timestamp, msg.sender, msg.value);
                ManagePlayers(msg.sender);
                return;
            }
        }
        require(gameCycle[currentCycle].endTime < block.timestamp, "Previous cycle has not ended.");
        DistributeRewards();
        RunCycle(block.timestamp, msg.sender, msg.value);
        ManagePlayers(msg.sender);
        currentCycle += 1;
    }

}