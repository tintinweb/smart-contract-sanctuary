/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity ^0.4.22;

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract Pledge {
    function getTameStake(address _own) public view returns(uint256 stake);
    function getPledgeInfo(address _own) public view returns(uint256 balance, uint256 createdAt);
    function updateTamePledgeTime(address _own) public;
}

contract SubBase {
    ERC721 public nonFungibleContract;
    ERC20 public fungibleContract;
    Pledge public pledgeContract;
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    function _transferFrom(uint256 _tokenId) internal {
        address _owner = nonFungibleContract.ownerOf(_tokenId);
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(this, _receiver, _tokenId);
    }

    function _createRandom() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, now)));
    }

    function _getCurrentStakeOfAddress(address _own) internal view returns(uint256)
    {
        return pledgeContract.getTameStake(_own);
    }

    function _meetPledged(address _own) internal view returns(bool) {
        uint256 value;
        uint256 created;
        (value, created) = pledgeContract.getPledgeInfo(_own);
        return (value>=(10*(10**18))&&((now-created)>=30*24*3600));
    }

    function _updatePledgeTime(address _own) internal{
        return pledgeContract.updateTamePledgeTime(_own);
    }
}


contract ClockTame is SubBase, Ownable{
    uint256[10] horses;
    uint64 startTime;

    event TameCreated(uint256 term);
    event TameSuccessful(uint256 term);
    event TameWinner(uint256 term, address winner, uint256 tokenId);

    uint256 periods;

    address[] participants;
    uint256[] stakes;

    mapping(uint256 => mapping(address => bool)) allUsers;


    constructor(address _nftAddress) public{
        ERC721 candidateContract = ERC721(_nftAddress);
        nonFungibleContract = candidateContract;
        owner = msg.sender;
    }

    function setERC20Address(address _address) external onlyOwner {
        fungibleContract = ERC20(_address);
    }

    function setPledgeAddress(address _address) external onlyOwner {
        pledgeContract = Pledge(_address);
    }


    function createTame(uint256[10] _hs) public onlyOwner {
        periods +=1;
        require(startTime == 0);

        for (uint256 i =0;i<10; i++) {
            _transferFrom(_hs[i]);
        }
        horses = _hs;
        startTime = uint64(now);
        emit TameCreated(periods);
    }

    function joinTame() public {
        require(startTime > 0);
        require(_meetPledged(msg.sender), "not meet pledge");
        require(!allUsers[periods][msg.sender]);
        participants.push(msg.sender);
        allUsers[periods][msg.sender]=true;
    }

    function _returnzero() internal {
        startTime =0;
        delete horses;
        delete participants;
        delete stakes;
    }

    function endTame() public onlyOwner {
        require(startTime > 0);
        require(participants.length >9);
        for(uint256 i=0; i< participants.length; i++) {
            stakes.push(_getCurrentStakeOfAddress(participants[i]));
        }
        uint256[10] memory indexOfWinner=[uint256(0),1,2,3,4,5,6,7,8,9];

        for (i =10; i<participants.length; i++ ) {
            uint256 index = i;
            for (uint256 j = 0; j<10 ; j++) {
                if (stakes[index] > stakes[indexOfWinner[j]]) {
                    uint256 temp = indexOfWinner[j];
                    indexOfWinner[j] = index;
                    index = temp;
                }
            }
        }

        for(i=0; i< horses.length; i++) {
            _transfer(participants[indexOfWinner[i]], horses[i]);
            _updatePledgeTime(participants[indexOfWinner[i]]);
            emit TameWinner(periods, participants[indexOfWinner[i]], horses[i]);
        }
        _returnzero();
        emit TameSuccessful(periods);
    }

    function cancelTame() public onlyOwner {
        require(startTime > 0);
        for (uint256 i =0; i<10; i++) {
            _transfer(msg.sender, horses[i]);
        }

        _returnzero();
    }

    function isJoined(address _address) public view returns (bool){
        return allUsers[periods][_address];
    }

    function getParticipants() public view returns (address[]) {
        return participants;
    }
}