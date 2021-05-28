/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity ^0.8.0;

contract Ownable {

    address private owner;
    
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

contract TestLottery is Ownable {
    uint private _Candidates;
    uint private _Winners;
    uint private _LastDraw = 0;
    mapping (uint => uint) private _flags;
    
    event NewLottery(uint Candidates, uint Winners);
    event NewDraw(uint Draw, uint Winner);

    
    constructor () {
        newLottery(1000, 2);
    }
    
    function newLottery(uint candidates, uint winners) public isOwner {
        require(candidates > 0, "Candidates must be greater than zero");
        require(winners > 0, "Winners must be greater than zero");
        require(candidates > winners, "Candidates must be greater than Winners");
        
        _Candidates = candidates;
        _Winners = winners;
        
        emit NewLottery(_Candidates, _Winners);
    }
    
    function getLottery() public view returns (uint, uint)  {
        return (_Candidates, _Winners);
    }
    
    function newRandom(uint prevRandom) private view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(prevRandom, block.timestamp)));
        return (randomHash % _Candidates) + 1;
    }
    
    function newDraw() public isOwner {
        // for(uint i = 0; i < _Candidates; i ++) {
        //     _flags[i] = 0;
        // }
        
        _LastDraw = _LastDraw + 1;
        
        uint _newIndex = 0;
        for(uint i = 0; i < _Winners; i ++) {
            _newIndex = newRandom(_newIndex);
            // do {
            //     _newIndex = newRandom(_newIndex);
            // } while(_flags[_newIndex] == 1);
            // _flags[_newIndex] = 1;
            emit NewDraw(_LastDraw, _newIndex);
        }
    }
    
    function getDraw() public view returns (uint) {
        require(_LastDraw > 0, "No draw has been taken");
        return _LastDraw;
    }
    
    function getFlag(uint index) public view returns (uint) {
        require(index < _Candidates, "Index overflow");
        return _flags[index];
    }
}