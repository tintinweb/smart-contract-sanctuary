//SourceUnit: MigrateNFT.sol

/***** Submitted for verification at Tronscan.org on 2021-02-27
*
*  ______     ______     ______     _____     __  __     ______     ______     ______   ______     ______   __     __   __     ______     __   __     ______     ______    
* /\  ___\   /\  __ \   /\  == \   /\  __-.  /\ \_\ \   /\  ___\   /\  ___\   /\  == \ /\  ___\   /\  ___\ /\ \   /\ "-.\ \   /\  __ \   /\ "-.\ \   /\  ___\   /\  ___\   
* \ \ \____  \ \ \/\ \  \ \  __<   \ \ \/\ \ \ \____ \  \ \ \____  \ \  __\   \ \  _-/ \ \___  \  \ \  __\ \ \ \  \ \ \-.  \  \ \  __ \  \ \ \-.  \  \ \ \____  \ \  __\   
*  \ \_____\  \ \_____\  \ \_\ \_\  \ \____-  \/\_____\  \ \_____\  \ \_____\  \ \_\    \/\_____\  \ \_\    \ \_\  \ \_\\"\_\  \ \_\ \_\  \ \_\\"\_\  \ \_____\  \ \_____\ 
*   \/_____/   \/_____/   \/_/ /_/   \/____/   \/_____/   \/_____/   \/_____/   \/_/     \/_____/   \/_/     \/_/   \/_/ \/_/   \/_/\/_/   \/_/ \/_/   \/_____/   \/_____/ 
*
*    https://cordyceps.finance
*
*    file: ./MigrateNFT.sol
*    time:  2021-02-16
*
*    Copyright (c) 2021 Cordyceps.finance 
*/   

pragma solidity ^0.5.8;


interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);

    function ownerOf(uint256 tokenId) public view returns (address owner);
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
   
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract INFTERC721 is IERC721{
    function tokensOfOwner(address owner) public view returns (uint256[] memory);
    function mint(address to, uint256 tokenId) external returns (bool) ;
    function burn(uint256 tokenId) external;
}


contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
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
        return _msgSender() == _owner;
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


contract Operator is Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender,'operator: caller is not the operator');
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator) public onlyOwner {
        _transferOperator(newOperator);
    }

    function _transferOperator(address newOperator) internal {
        require(newOperator != address(0),'operator: zero address given for new operator');
        emit OperatorTransferred(address(0), newOperator);
        _operator = newOperator;
    }
}
contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(
            !checkSameOriginReentranted(),
            'ContractGuard: one block, one function'
        );
        require(
            !checkSameSenderReentranted(),
            'ContractGuard: one block, one function'
        );

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}



contract MigrateNFT is ContractGuard,Operator{
    using SafeMath for uint256;
    using Address for address;

    INFTERC721 public package;
    INFTERC721 public cordyNFT;
    
    struct Migration{
        uint256 id;
        bool isPack;
        uint256 time;
        uint256[] tids;
        address from;
        string  htAddress;
    }

    uint256 public migrationIndex;
    uint256 public tokenBurnAmount;
    uint256 public packMigrateNum;
    uint256 public cordyMigrateNum;
    bool public isPaused;

    mapping(uint256=>Migration) public indexToMigration;
    mapping(address=>uint256[]) public addrToMigrIds;

    event MigrationAdded(address indexed operator, uint256 mid);
    event CordycepsBurnt(address indexed user,uint256 amount);

    constructor(address _packNFT,address _cordyNFT) public {
        package=INFTERC721(_packNFT); 
        cordyNFT=INFTERC721(_cordyNFT);
        isPaused=false;
    }

    function setPaused(bool _p) external onlyOwner returns(bool){
        isPaused=_p;
        return isPaused;
    }
  
    function getMigrationById(uint256 _mid) view public returns(
        uint256 _id,
        bool _isPack,
        uint256 _time,
        uint256[] memory _tids,
        address _from,
        string memory _htAddress
    ){
        Migration memory migr=indexToMigration[_mid];
        _id=migr.id;
        _isPack=migr.isPack;
        _time=migr.time;
        _tids=migr.tids;
        _from=migr.from;
        _htAddress=migr.htAddress;
    }
    function getMidsByAddr(address _addr) view public returns(uint256[] memory){
        return addrToMigrIds[_addr];
    }

    modifier checkHtAddr(string memory _addr) {
        bytes memory addr=bytes(_addr);
        require(addr[0]==0x30&&addr[1]==0x78&&addr.length==42,'Error: Heco address error!');
        _;
    }
    modifier checkStart() {
        require(!isPaused,'Error: Migration has been suspended!');
        _;
    }

    function migrate(string memory _htAddr,bool isPack,uint256[] memory _tokenIds) public onlyOneBlock checkStart checkHtAddr(_htAddr){
        address sender=_msgSender();

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 tid=_tokenIds[i];
            if(isPack){
                require(package.ownerOf(tid)==sender,'Error1: Some NFTs are not yours!');
                package.burn(tid);
                packMigrateNum++;
            }else{
                require(cordyNFT.ownerOf(tid)==sender,'Error2: Some NFTs are not yours!');
                cordyNFT.burn(tid);
                cordyMigrateNum++;
            }
        }
        migrationIndex++;
        addrToMigrIds[sender].push(migrationIndex);
        indexToMigration[migrationIndex]=Migration(migrationIndex,isPack,now,_tokenIds,sender,_htAddr);
        emit MigrationAdded(sender,migrationIndex);
    }


}



// ******** library *********/

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


//math

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// safeMath

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}