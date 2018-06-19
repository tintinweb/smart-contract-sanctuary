pragma solidity ^0.4.0;

contract TycoonPresale {
    event HHH(address bidder, uint amount); // Event

    address public owner; // Minor management of game
    bool public isPresaleEnd;
    uint256 private constant price = 0.0666 ether;
    uint8 private constant maxNumbersPerPlayer = 10;
    mapping (address => mapping (uint8 => bool)) private doihave;
    mapping (address => uint8[]) private last; // [choumode][idx1][idx2][...]
    uint256 private constant FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
    uint256 private constant MAGICNUMBER = 6666666666666666666666666666666666666666666666666666666666666666666666666666;
    struct Level {
        uint8[] GaoIdx;
        uint8 passProb;
    }
    Level[] private levels;
    /*** CONSTRUCTOR ***/
    constructor() public {
        owner = msg.sender;
        Level memory _level;
        _level.GaoIdx = new uint8[](5);
        _level.GaoIdx[0] = 2;
        _level.GaoIdx[1] = 3;
        _level.GaoIdx[2] = 5;
        _level.GaoIdx[3] = 6;
        _level.GaoIdx[4] = 7;
        _level.passProb = 55;
        levels.push(_level);
        _level.GaoIdx = new uint8[](4);
        _level.GaoIdx[0] = 9;
        _level.GaoIdx[1] = 10;
        _level.GaoIdx[2] = 12;
        _level.GaoIdx[3] = 13;
        _level.passProb = 65;
        levels.push(_level);
        //
        _level.GaoIdx = new uint8[](11);
        _level.GaoIdx[0] = 16;
        _level.GaoIdx[1] = 18;
        _level.GaoIdx[2] = 19;
        _level.GaoIdx[3] = 20;
        _level.GaoIdx[4] = 21;
        _level.GaoIdx[5] = 23;
        _level.GaoIdx[6] = 24;
        _level.GaoIdx[7] = 25;
        _level.GaoIdx[8] = 26;
        _level.GaoIdx[9] = 28;
        _level.GaoIdx[10] = 29;
        _level.passProb = 0;
        levels.push(_level);
    }
    function MyGaoguans() public view returns (uint8[]){
        return last[msg.sender];
    }
    function Chou(uint8 seChou) public payable {
        require(!isPresaleEnd);
        require(_goodAddress(msg.sender));
        require(seChou > 0 && seChou < 6);
        uint8 owndCount = 0;
        if (last[msg.sender].length != 0){
            owndCount = last[msg.sender][0];
        }
        require(owndCount + seChou <= maxNumbersPerPlayer);
        require(msg.value >= (price * seChou));

        if (last[msg.sender].length < 2){
            last[msg.sender].push(seChou);
            last[msg.sender].push(seChou);
        }else{
            last[msg.sender][0] += seChou;
            last[msg.sender][1] = seChou;
        }

        uint256 zhaoling = msg.value - (price * seChou);
        assert(zhaoling <= msg.value); // safe math
        // multi-chou
        for (uint _seChouidx = 0; _seChouidx != seChou; _seChouidx++){
            uint randN = _rand(_seChouidx + MAGICNUMBER); // only generate once for saving gas
            for (uint idx = 0; idx != levels.length; idx++) {
                bool levelPass = true;
                uint8 chosenIdx;
                for (uint jdx = 0; jdx != levels[idx].GaoIdx.length; jdx++) {
                    if (!_Doihave(levels[idx].GaoIdx[(jdx+randN)%levels[idx].GaoIdx.length])){
                        levelPass = false;
                        chosenIdx = levels[idx].GaoIdx[(jdx+randN)%levels[idx].GaoIdx.length];
                        break;
                    }
                }
                if (!levelPass){
                    if (randN % 100 >= levels[idx].passProb) { // this level right, and the last chosenIdx is chosenIdx
                        _own(chosenIdx);
                        break;
                    }
                    randN = randN + MAGICNUMBER;
                }
            }
        }
        msg.sender.transfer(zhaoling);
    }
    
    // private
    function _Doihave(uint8 gaoIdx) private view returns (bool) {
        return doihave[msg.sender][gaoIdx];
    }
    function _own(uint8 gaoIdx) private {
        last[msg.sender].push(gaoIdx);
        doihave[msg.sender][gaoIdx] = true;
    }
    function _rand(uint exNumber) private constant returns (uint){
        uint lastBlockNumber = block.number - 1;
        uint hashVal = uint256(blockhash(lastBlockNumber));
        uint result = uint(keccak256(exNumber, msg.sender, hashVal));
        return result;
    }
    function _goodAddress(address add) private pure returns (bool) {
        return add != address(0);
    }
    function _payout(address _to) private {
        if (_to == address(0)) {
            owner.transfer(address(this).balance);
        } else {
            _to.transfer(address(this).balance);
        }
    }
    // business use only for owner
    modifier ensureOwner() {
        require(
            msg.sender == owner
        );
        _;
    }
    function payout() external ensureOwner {
        _payout(address(0));
    }
    function B() external ensureOwner constant returns (uint256){
        return address(this).balance;
    }
    // presale control
    function End() external ensureOwner {
         require(!isPresaleEnd);
         isPresaleEnd = true;
    }
    function Gaoguans(address player) public ensureOwner view returns (uint8[]){
        return last[player];
    }
}