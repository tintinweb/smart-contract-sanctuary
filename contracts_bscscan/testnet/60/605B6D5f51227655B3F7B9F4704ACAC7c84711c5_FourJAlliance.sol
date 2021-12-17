/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId, uint256 tokenLevel, string memory initialURI) external;
    function existed(uint256 tokenId) external view returns (bool);
}

interface ICreate4JIDStrategy {
    event GetTokenLevel(address indexed user, uint256 indexed tokenID, uint256 indexed level);
    function getTokenLevel(address from, uint256 tokenID) external returns(uint256 level);
}

contract FourJAlliance is Ownable {
    address public receiver;
    address public minter;
    IERC721 public immutable fourJPASS; //Alliance NFT
    IERC721 public immutable fourJID;   //4JID NFT
    address public immutable tokenAddress;
    ICreate4JIDStrategy public immutable createStrategy;  //get token level from this contract

    uint256 public minPrice = 10**8 * 10**9;
    uint256 public normalPrice = 6 * 10**8 * 10**9;
    struct AllianceInfo {
        uint256 membershipFee; // membeership fee of each alliance
        uint256 managerFeeRate; // membeership fee rate to the alliance's owner (manager fee = fee * rate / 1000)
        uint256 ownerRemainedReward; // total remained membeership manager fee
        uint256 allianceMemNum; //the number of one alliance's members
        uint256 rewardPerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }
    mapping(uint256 => AllianceInfo) public allianceInfos;
    uint256 public characterCount;
    //uint256 private priceID = 10**17;
    uint256 private priceID = 10**15;

    /** 4JID's information about its alliance. */
    mapping(uint256 => mapping(uint256 => uint256)) public allianceMembers;
    mapping(uint256 => uint256) public affiliatedAlliance;
    mapping(uint256 => uint256) public memberIndex;

    mapping(uint256 => mapping(uint256 => uint256)) public memberBaseDebts; // not real debt, just for calculating reward

    event  CreateID(address indexed user, uint256 tokenID, uint256 tokenLevel, string indexed initialURI);
    event  JoinAlliance(address indexed user, uint256 memberID, uint256 allianceID, uint256 membershipFee, uint256 managerFee, uint256 addReward);
    event  CreateIDandJoinAlliance(address indexed user, uint256 characterID, uint256 tokenLevel, string indexed initialURI,
                                   uint256 allianceID, uint256 membershipFee, uint256 managerFee, uint256 addReward);
    event  QuitAlliance(uint256 allianceID, uint256 memberID);
    event  ClaimReward(address indexed user, uint256 rewardAmount);
    event  AddReward(address indexed user, uint256 allianceID, uint256 rewardAmount);

    constructor(IERC721 _fourJPASS, IERC721 _fourJID, ICreate4JIDStrategy _strategy, address _tokenAddress) {
        fourJPASS = _fourJPASS;
        fourJID = _fourJID;
        createStrategy = _strategy;
        tokenAddress = _tokenAddress;
        receiver = msg.sender;
    }

    fallback() external payable {}
    receive() external payable {}

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'FourJAlliance: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function create4JID(string memory _initialURI) lock public payable {
        require(msg.value == priceID, "FourJAlliance: bnb value error.");

        characterCount++;
        while (fourJID.existed(characterCount)) {
            characterCount++;
        }
        uint256 _characterID = characterCount;
        uint256 _tokenLevel = createStrategy.getTokenLevel(msg.sender, _characterID);
        fourJID.mint(msg.sender, _characterID, _tokenLevel, _initialURI);

        emit CreateID(msg.sender, _characterID, _tokenLevel, _initialURI);
    }

    function joinAlliance(uint256 _memberID, uint256 _passID, uint256 _membershipFee) public {
        require(fourJPASS.ownerOf(_passID) != address(0), "FourJAlliance: alliance is not existed.");
        require(affiliatedAlliance[_memberID] == 0, "FourJAlliance: already joined in an alliance.");
        require(fourJID.ownerOf(_memberID) == msg.sender, "FourJAlliance: no authority.");
        if (allianceInfos[_passID].membershipFee == 0 || allianceInfos[_passID].membershipFee < minPrice) {
            allianceInfos[_passID].membershipFee = normalPrice;
        }
        require(allianceInfos[_passID].membershipFee == _membershipFee, "FourJAlliance: membership fee error.");

        TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), _membershipFee);
        _addMemberToAllianceEnumeration(_passID, _memberID);

        uint256 managerFee = _membershipFee * allianceInfos[_passID].managerFeeRate / 1000;
        uint256 addedReward = _membershipFee - managerFee;
        allianceInfos[_passID].allianceMemNum++;
        memberBaseDebts[_passID][_memberID] = allianceInfos[_passID].rewardPerShare;
        allianceInfos[_passID].rewardPerShare += addedReward / allianceInfos[_passID].allianceMemNum;
        allianceInfos[_passID].ownerRemainedReward += managerFee;

        emit JoinAlliance(msg.sender, _memberID, _passID, _membershipFee, managerFee, addedReward);
    }

    function createIDandJoinAlliance(string memory _initialURI, uint256 _passID, uint256 _membershipFee) lock public payable {
        require(fourJPASS.ownerOf(_passID) != address(0), "FourJAlliance: alliance is not existed.");
        require(msg.value == priceID, "FourJAlliance: bnb value error.");
        if (allianceInfos[_passID].membershipFee == 0 || allianceInfos[_passID].membershipFee < minPrice) {
            allianceInfos[_passID].membershipFee = normalPrice;
        }
        require(allianceInfos[_passID].membershipFee == _membershipFee, "FourJAlliance: membership fee error.");

        characterCount++;
        while (fourJID.existed(characterCount)) {
            characterCount++;
        }
        uint256 _characterID = characterCount;
        uint256 _tokenLevel = createStrategy.getTokenLevel(msg.sender, _characterID);
        fourJID.mint(msg.sender, _characterID, _tokenLevel, _initialURI);

        TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), _membershipFee);
        _addMemberToAllianceEnumeration(_passID, _characterID);

        uint256 managerFee = _membershipFee * allianceInfos[_passID].managerFeeRate / 1000;
        uint256 addedReward = _membershipFee - managerFee;
        allianceInfos[_passID].allianceMemNum++;
        memberBaseDebts[_passID][_characterID] = allianceInfos[_passID].rewardPerShare;
        allianceInfos[_passID].rewardPerShare += addedReward / allianceInfos[_passID].allianceMemNum;
        allianceInfos[_passID].ownerRemainedReward += managerFee;

        emit CreateIDandJoinAlliance(msg.sender, _characterID, _tokenLevel, _initialURI, _passID, _membershipFee, managerFee, addedReward);
    }

    function quitAlliance(uint256 _memberID, uint256 _passID) public {
        require(affiliatedAlliance[_memberID] > 0, "FourJAlliance: not in an alliance.");
        require(affiliatedAlliance[_memberID] == _passID, "FourJAlliance: affiliated alliance error.");
        require(fourJID.ownerOf(_memberID) == msg.sender, "FourJAlliance: no authority.");

        claimReward(_memberID, _passID);

        _removeMemberFromAllianceEnumeration(_passID, _memberID);
        allianceInfos[_passID].allianceMemNum--;
        memberBaseDebts[_passID][_memberID] = 0;

        emit QuitAlliance(_passID, _memberID);
    }

    function claimReward(uint256 _memberID, uint256 _passID) public {
        require(affiliatedAlliance[_memberID] > 0, "FourJAlliance: not in an alliance.");
        require(affiliatedAlliance[_memberID] == _passID, "FourJAlliance: affiliated alliance error.");
        require(fourJID.ownerOf(_memberID) == msg.sender, "FourJAlliance: no authority.");

        uint256 rewardAmount = allianceInfos[_passID].rewardPerShare - memberBaseDebts[_passID][_memberID];
        if (rewardAmount > 0) {
            TransferHelper.safeTransfer(tokenAddress, msg.sender, rewardAmount);
            memberBaseDebts[_passID][_memberID] = allianceInfos[_passID].rewardPerShare;
        }

        emit ClaimReward(msg.sender, rewardAmount);
    }

    function addReward(uint256 _passID, uint256 _rewardAmount) public {
        TransferHelper.safeTransfer(tokenAddress, address(this), _rewardAmount);
        allianceInfos[_passID].rewardPerShare += _rewardAmount / allianceInfos[_passID].allianceMemNum;

        emit AddReward(msg.sender, _passID, _rewardAmount);
    }

    function _addMemberToAllianceEnumeration(uint256 _passID, uint256 _memberID) private {
        uint256 length = allianceInfos[_passID].allianceMemNum;
        allianceMembers[_passID][length] = _memberID;
        affiliatedAlliance[_memberID] = _passID;
        memberIndex[_memberID] = length;
    }

    function _removeMemberFromAllianceEnumeration(uint256 _passID, uint256 _memberID) private {
        uint256 lastIndex = allianceInfos[_passID].allianceMemNum - 1;
        uint256 memIndex = memberIndex[_memberID];

        if (memIndex != lastIndex) {
            uint256 lastMemID = allianceMembers[_passID][lastIndex];

            allianceMembers[_passID][memIndex] = lastMemID;
            memberIndex[lastMemID] = memIndex;
        }

        delete memberIndex[_memberID];
        delete affiliatedAlliance[_memberID];
        delete allianceMembers[_passID][lastIndex];
    }

    function setPrice(uint256 _minPrice, uint256 _normalPrice) public onlyOwner() {
        require(_normalPrice >= minPrice, "FourJAlliance: error when set membership fee standard.");
        minPrice = _minPrice;
        normalPrice = _normalPrice;
    }

    function setMembershipFee(uint256 _passID, uint256 _membershipFee, uint256 _managerFeeRate) public {
        require(fourJPASS.ownerOf(_passID) == msg.sender, "FourJAlliance: only owner can set membership fee.");
        require(_membershipFee >= minPrice, "FourJAlliance: error when set membership fee.");
        require(_managerFeeRate <= 1000, "FourJAlliance: error when set membership manager fee rate.");
        allianceInfos[_passID].membershipFee = _membershipFee;
        allianceInfos[_passID].managerFeeRate = _managerFeeRate;
    }

    function changeReceiver(address _receiver) public onlyOwner() {
        receiver = _receiver;
    }

    function transferEthAsset(uint256 value) public onlyOwner() {
        TransferHelper.safeTransferETH(receiver, value);
    }

    function transferOtherAsset(address token, uint256 value) public onlyOwner() {
        require(token != tokenAddress, "FourJAlliance: cannot transfer 4JNET from this address.");
        TransferHelper.safeTransfer(token, receiver, value);
    }
}