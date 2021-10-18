/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _setOwner(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface EthereansInterface {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface InvaderTokenInterface {
    function claimReward(address owner, uint amount) external;

    function burnFrom(address from, uint amount) external;
}

interface EmpireDropsInterface {
    function mint(address from, uint tokenId) external;

}

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
    function balanceOf(address owner) external view returns (uint256 balance);

    
    function ownerOf(uint256 tokenId) external view returns (address owner);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function approve(address to, uint256 tokenId) external;

    
    function getApproved(uint256 tokenId) external view returns (address operator);

    
    function setApprovalForAll(address operator, bool _approved) external;

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract EthereanEmpire is Ownable {

using SafeMath for uint256;

event EmpireCreated(address owner, string name, string motto);
event EmpireCustomized(address owner, string newName, string newMotto);
event RewardClaimed(address claimer, uint amount);
event DropCreated(uint tokenId, string title, string description, string artist, uint cost, uint supply, uint end);
event DropMinted(address minter, uint dropId);


struct Empire {
    string name;
    string motto;
    bool exists;
}

struct Drop {
    uint tokenId;
    string title;
    string description;
    string artist;
    uint cost; 
    uint supply;
    uint end;
    bool exists;
    uint minted;
}

uint public ETHEREAN_MIN = 3;
uint public EMPIRE_EDIT_FEE = 200 ether;
uint public numDrops = 0;
address public ETHEREANS_CONTRACT_ADDRESS;
address public INVADER_CONTRACT_ADDRESS;
address public EMPIRE_DROPS_CONTRACT_ADDRESS;
uint constant public END_REWARDS = 1735693200; 
EthereansInterface private ethereanContract;
InvaderTokenInterface private invaderContract;
EmpireDropsInterface private empireDropsContract;

mapping(address => Empire) public empires;
address[] private empireAddresses;
mapping(uint => uint) public tokenToLastUpdated;
mapping(uint => Drop) public drops;
mapping(address => mapping(uint => bool)) public addressOwnsDrop;


constructor(address _ethereansAddress, address _invaderAddress) {
    ETHEREANS_CONTRACT_ADDRESS = _ethereansAddress;
    ethereanContract = EthereansInterface(_ethereansAddress);

    INVADER_CONTRACT_ADDRESS = _invaderAddress;
    invaderContract = InvaderTokenInterface(_invaderAddress);
}

function setEthereansContractAddress(address _contractAddress) external onlyOwner() {
    ETHEREANS_CONTRACT_ADDRESS = _contractAddress;
    ethereanContract = EthereansInterface(_contractAddress);
}

function setEmpireDropsContractAddress(address _contractAddress) external onlyOwner() {
    EMPIRE_DROPS_CONTRACT_ADDRESS = _contractAddress;
    empireDropsContract = EmpireDropsInterface(_contractAddress);
}


function newEmpire(string memory _name, string memory _motto) public {
    require(empires[msg.sender].exists == false, "Only one empire per wallet.");
    require(ethereanContract.balanceOf(msg.sender) >= ETHEREAN_MIN, "Did not meet minimum ethereans requirement.");
    empires[msg.sender] = Empire(_name, _motto, true);
    empireAddresses.push(msg.sender);
    emit EmpireCreated(msg.sender, _name, _motto);
}

function newDrop(uint _tokenId, string memory _title, string memory _description, string memory _artist, uint _cost, uint _supply, uint _end) external onlyOwner() {
    require(_tokenId >= 0, "Must supply a tokenId");
    require(_supply > 0, "Supply must be greater than 1.");
    require(block.timestamp < _end, "End date must be set in the future");
    numDrops = numDrops.add(1);
    drops[numDrops] = Drop(_tokenId, _title, _description, _artist, _cost, _supply, _end, true, 0);
    emit DropCreated(_tokenId, _title, _description, _artist, _cost, _supply, _end);
} 

function getEmpireAddresses() public view returns (address[] memory) {
    return empireAddresses;
}

function setEmpireEditFee(uint _newFee) external onlyOwner(){
    EMPIRE_EDIT_FEE = _newFee;
}

modifier hasEmpire {
    require(empires[msg.sender].exists == true, "Does not own empire.");
    _;
}

function customizeEmpire(string memory _newName, string memory _newMotto) external hasEmpire(){
    invaderContract.burnFrom(msg.sender, EMPIRE_EDIT_FEE);
    empires[msg.sender].name = _newName;
    empires[msg.sender].motto = _newMotto;
    emit EmpireCustomized(msg.sender, _newName, _newMotto);
}


function claimReward(uint[] memory _tokenIds) external hasEmpire() {
    uint ethereanBalance = ethereanContract.balanceOf(msg.sender);
    require(ethereanBalance >= ETHEREAN_MIN, "Did not meet minimum ethereans requirement to claim rewards.");
    uint currentTime = min(block.timestamp, END_REWARDS);
    uint totalElapsedTime;
    for (uint i=0; i<_tokenIds.length; i++) {
        uint tokenId = _tokenIds[i];
        uint lastUpdated = tokenToLastUpdated[tokenId];
        require(ethereanContract.ownerOf(tokenId) == msg.sender, "Etherean does not belong to you.");
        if (lastUpdated == 0) {
            tokenToLastUpdated[tokenId] = currentTime;
        } else if (lastUpdated > 0) {
            totalElapsedTime += currentTime.sub(lastUpdated);
            tokenToLastUpdated[tokenId] = currentTime;
        }
    }
    if (totalElapsedTime > 0) {
        uint multiplier = getMultiplier(ethereanBalance);
        uint rewardAmount = totalElapsedTime.mul(multiplier).mul(10**18).div(86400);
        invaderContract.claimReward(msg.sender, rewardAmount);
        emit RewardClaimed(msg.sender, rewardAmount);
    }
}

function mintDrop(uint _dropId) external hasEmpire(){
    Drop storage drop = drops[_dropId];
    require(drop.exists == true, "Drop does not exist.");
    require(block.timestamp < drop.end, "Drop has expired.");
    require(drop.minted < drop.supply, "Drop is sold out.");
    require(addressOwnsDrop[msg.sender][_dropId] == false, "Only one drop allowed per empire.");
    uint ethereanBalance = ethereanContract.balanceOf(msg.sender);
    require(ethereanBalance >= ETHEREAN_MIN, "Did not meet minimum ethereans requirement to mint drop.");
    if (drop.cost > 0) {
        invaderContract.burnFrom(msg.sender, drop.cost);
    }
    empireDropsContract.mint(msg.sender, drop.tokenId);
    drop.minted += 1;
    addressOwnsDrop[msg.sender][_dropId] = true;
    emit DropMinted(msg.sender, _dropId);
}

function min(uint a, uint b) internal pure returns (uint) {
		return a < b ? a : b;
	}


function getMultiplier(uint ethereanBalance) internal pure returns (uint) {
    if (ethereanBalance < 6) 
        return 10;
    if (ethereanBalance < 18)
        return 11;
    if (ethereanBalance < 72)
        return 12;
    return 13;
}

function withdraw() public onlyOwner() {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
}

function recoverERC20(address _tokenAddress, uint _tokenAmount) public onlyOwner() {
    IERC20(_tokenAddress).transfer(owner(), _tokenAmount);
}

function recoverERC721(address _tokenAddress, uint _tokenId) public onlyOwner() {
    IERC721(_tokenAddress).safeTransferFrom(address(this), owner(), _tokenId);
}

}