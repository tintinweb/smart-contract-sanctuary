/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

interface IRevoNFT{
  function nftsDbIds(string memory _collection, string memory _dbId) external view returns (uint256);
  function getTokensDbIdByOwnerAndCollection(address _owner, string memory _collection) external view returns(string[] memory ownerTokensDbId);
  function transferFrom(address from, address to, uint256 tokenId) external;
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() public view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RevoAirdropNFT is Ownable {
    using SafeMath for uint256;
    
    IRevoNFT private revoNFT;

    mapping(uint256 => mapping(uint256 => uint256)) nfts;//Index => index , nftId
    mapping(address => mapping(uint256 => bool)) whitelist;
    mapping(address => bool) hasClaimed;
    //PENDING BUY
    uint256[4] public firstPending;
    uint256[4] public lastPending;

    constructor(address _revoNFT) public{
        setRevoNFT(_revoNFT);

        firstPending = [1,1,1,1];
        lastPending = [0,0,0,0];
    }

    function addAddresses(uint256 _index, address[] memory _addresses) public onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++){
            whitelist[_addresses[i]][_index] = true;
        }
    }
    
    function addNFT(uint256 _index, uint256[] memory _tokenIds) public onlyOwner {

        for(uint256 i = 0; i < _tokenIds.length; i++){
            enqueuePendingTx(_index, _tokenIds[i]);
        }
    }

    function claimNFT() public {
        if(!hasClaimed[msg.sender]){
            hasClaimed[msg.sender] = true;
            for(uint256 i = 0; i < 4; i++){
                if(whitelist[msg.sender][i]){//BLUEZILLA
                    uint256 tokenId = dequeuePendingTx(i);
                    //revoNFT.transferFrom(address(this), msg.sender, tokenId);
                }
            }
        }
    }

    function isEligible(address _address) public view returns(bool){
        bool eligible = false;
        for(uint256 i = 0; i < 4; i++){
            if(whitelist[_address][i]){//BLUEZILLA
                eligible = true;
            }
        }
        return eligible;
    }
    
    
    /*
    PENDING BUY QUEUE
    */
    
    function enqueuePendingTx(uint256 _index, uint256 _tokenId) private {
        lastPending[_index] += 1;
        nfts[_index][lastPending[_index]] = _tokenId;
    }

    function dequeuePendingTx(uint256 _index) public onlyOwner returns (uint256 data) {
        require(lastPending[_index] >= firstPending[_index]);  // non-empty queue

        data = nfts[_index][firstPending[_index]];

        delete nfts[_index][firstPending[_index]];
        firstPending[_index] += 1;
    }
    
    function countPendingTx(uint256 _index) public view returns(uint256){
        return firstPending[_index] <= lastPending[_index] ? (lastPending[_index] - firstPending[_index]) + 1 : 0;
    }
    
    function getPendingTx(uint256 _index, uint256 _maxItems) public view returns(uint256[] memory items){
        uint256 count = countPendingTx(_index);
        count = count > _maxItems ? _maxItems : count;
        uint256[] memory itemToReturn = new uint256[](count);
        
        for(uint256 i = 0; i < count; i ++){
            itemToReturn[i] =  nfts[_index][firstPending[_index] + i];
        }
        
        return itemToReturn;
    }
    
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function setRevoNFT(address _revoNFT) public onlyOwner {
        revoNFT = IRevoNFT(_revoNFT);
    }
}