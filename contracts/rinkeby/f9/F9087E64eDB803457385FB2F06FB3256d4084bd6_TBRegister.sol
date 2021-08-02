/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

pragma solidity ^0.5.16;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

interface AnftToken {
  //function mint(address account, uint256 tokenId) external returns (bool);
  function safeMint(address to, uint256 tokenId, bytes calldata _data) external returns (bool);
  function ownerOf(uint256 tokenId) external returns (address owner);
  function totalSupply() external view returns (uint256);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function existData(uint256 _data) external view returns (bool);
  function mint(address _to, uint256 _tokenId) external;
}

interface ERC20Token {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) ;    
  function transfer(address dst, uint rawAmount) external returns (bool);
  function balanceOf(address account) external view returns (uint);
} 

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address  _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}




contract TBRegister is  Ownable {
    using SafeMath for uint256;

    uint256 private releaseDate;

    address public TBnft =  address(0xB42A7C7FDFB7546f917a3bC54F399a40fAB52f2E);

    address private _burnPool = 0x6666666666666666666666666666666666666666;
   // address private init_address = address(0x3244C695758e077422DDB30Ec229595A6A92DC04);

    uint256 public _storestartTime =  now + 365 days;
    uint256 private nonce = 0;

    uint256 public _claimdays = 60 days;
    
    uint256[] private _allNft;
    uint256[] private _allReg;
    uint256[] private _stageReg;
    
    // Mapping from NFT-id to position in the allNft array
    mapping(uint256 => uint256) private _allNftIndex;
    mapping(uint256 => bool) usedNonces;

    uint public constant MaxRegister = 10000;
    
    bool public isRegister = false;
    bool public isPickup = false;
    // uint[] stagelimit = [ 4000, 3000, 2000, 1000, 0 ] ;
   //  uint[] public stagelimit = [ 100, 50, 30, 20, 0] ;
   // uint[] public stagelimit = [ 4000, 3000, 2000, 1000, 0] ;
  //  uint[] public stageminted = [ 0, 0, 0, 0, 0 ] ;
    uint public current_stage = 0;

    uint16[] public round ;
    uint16[] public round_len ;
    uint16[] public shift ;
 
    uint256 Stage_p1 = 10000000000000000; // 0.01 ETH 
    uint256 Stage_p2 = 30000000000000000; // 0.03 ETH
    uint256 Stage_p3 = 50000000000000000; // 0.05 ETH
    uint256 Stage_p4 = 90000000000000000; // 0.09 ETH
    uint256[] stagePrice = [ Stage_p1, Stage_p2, Stage_p3, Stage_p4, 0 ] ;
  
    uint random_value = 0;

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);
    event EncodeProperties(uint16 a, uint16 b,uint16 c, uint16 d);
    event CreatedProperties(uint256 pro);
    event RegisteredNFT(uint256 id, address wallet);

    mapping(uint256 => uint256) public _lastStoreTime;
    mapping(uint256 => uint) private _allowchallenge;
    mapping (address => bool) public hasClaimed;
    mapping (uint256 => address) public registeredAddress;
    mapping (uint256 => uint256) public registerPool;
    
   

   // Throws when msg.sender has already claimed the airdrop 
    modifier hasNotClaimed() {
        require(hasClaimed[msg.sender] == false);
        _;
    }
    
    // Throws when the 30 day airdrop period has passed 
    modifier canClaim() {
        require(releaseDate + _claimdays >= now);
        _;
    }

    modifier checkstoreStart() {
        require(block.timestamp > _storestartTime, "store not start");
        _;
    }

    constructor() public {
        
        releaseDate = now;
       
        isRegister = true;
        isPickup = true;
        //random_value = block.number;
    }

    function setAnft( address anft ) external onlyOwner {
        TBnft = anft;
    }
    
    function priceResponse( uint stage, uint256 price ) external onlyOwner {
        stagePrice[stage] = price;
    }
    
        /**
     * @dev Gets the owner of the NFT ID
     * @param nftId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given NFT ID
     */
    function NFTownerOf(uint256 nftId) private returns (address) {
        AnftToken TBnftx =  AnftToken(TBnft);
        address owner = TBnftx.ownerOf(nftId);
        require(owner != address(0));
        return owner;
    }

    function toBytes(uint256 x) pure internal returns (bytes memory b) {
         b = new bytes(32);
         assembly { mstore(add(b, 32), x) }
    }

    function isContract(address _addr) internal view returns (bool)
    {
        uint32 size;
          assembly {
            size := extcodesize(_addr)
          }
          return (size > 0);
    }
    
    function convert_uint16 (uint256 _a) pure internal returns (uint16) 
    {
        return uint16(_a);
    }

        
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) 
    {
        emit NFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);
    
        bytes32 r;
        bytes32 s;
        uint8 v;
    
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    
        return (v, r, s);
    } 
    
    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }
    
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
         return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
        
    function isSpecUsed(uint256 _nonce) public view returns (bool){
            return usedNonces[_nonce];   
    } 
    
    function viewsign(uint256 price100, uint256 _nonce, bytes memory sig) public view returns(bytes32,address) {
                    
                    bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, price100, _nonce, this)));
                    return  (message, recoverSigner( message, sig ));
    }
    
    function specregisterNFT(uint256 amount, uint256 price100, uint256 _nonce, bytes memory sig) public payable {

            require(!usedNonces[_nonce]);
            usedNonces[_nonce] = true;
        
            bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, price100, _nonce, this)));

            if( recoverSigner( message, sig ) == 0x3244C695758e077422DDB30Ec229595A6A92DC04 )
            {
               require(price100.mul(amount) <= msg.value, "Ether too small");
               //  _registerNFT_pass( amount);
               registerNFT();
            }
    }  
 
    function registerNFT() public payable {

        require(stagePrice[current_stage] <= msg.value, "Ether too small");
        require( isContract(msg.sender) == false, "Not allow contract to call");
        
        AnftToken TBnftx =  AnftToken(TBnft);
        uint totalminted = TBnftx.totalSupply();
        require(MaxRegister > totalminted, "MaxRegister: Not available");
        require(totalminted.add(1) <= MaxRegister, "Exceed max Register amount");     
        
        uint256 id = totalminted+1;

        TBnftx.mint(msg.sender, id );
    }

    
    function currentPrice() public view returns (uint256) {
       // require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
       // require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
          return stagePrice[current_stage];
    }    

    function stageAdjust( uint nextstage ) external onlyOwner {
        if( nextstage >= 4 )
          isRegister = false;
        else
          isRegister = true; 
        current_stage = nextstage;
    }
    
   
}