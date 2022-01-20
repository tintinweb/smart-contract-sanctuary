/**
 *Submitted for verification at Etherscan.io on 2022-01-20
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


interface ICALand{
  function mint(address to, uint256 tokenId,int128 _dst,int128 _blk,int128 _plot) external returns (bool);
  function ownerOf(uint256 tokenId) external returns (address owner);
  function totalSupply() external view returns (uint256);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}


interface AnftToken {
  function mint(address account, uint256 tokenId) external returns (bool);
  function safeMint(address to, uint256 tokenId, bytes calldata _data) external returns (bool);
  function ownerOf(uint256 tokenId) external returns (address owner);
  function totalSupply() external view returns (uint256);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function existData(uint256 _data) external view returns (bool);
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




contract CAClaim is  Ownable {
    using SafeMath for uint256;

    uint256 private releaseDate;

    address public _anft = address(0x8B801270f3e02eA2AACCf134333D5E5A019eFf42);
    address public _canft = address(0x7d64C9C7284641a225C6c0F3B3E83DDf55A2cF03);
    address private checker = address(0x3244C695758e077422DDB30Ec229595A6A92DC04);
    address payable _teamWallet = address(0x2dc11d4267e31911A2d11817e4f0Fca14dF2E3Fd);    
    address private _burnPool = 0x6666666666666666666666666666666666666666;
    address private init_address = address(0x3244C695758e077422DDB30Ec229595A6A92DC04);

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
     uint[] public stagelimit = [ 100, 50, 30, 20, 0] ;
   // uint[] public stagelimit = [ 4000, 3000, 2000, 1000, 0] ;
    uint[] public stageminted = [ 0, 0, 0, 0, 0 ] ;
    uint public current_stage = 0;

    uint16[] public round ;
    uint16[] public round_len ;
    uint16[] public shift ;

    uint256 Stage_p1 = 100000000000000000; // 0.1 ETH 
    uint256 Stage_p2 = 300000000000000000; // 0.3 ETH
    uint256 Stage_p3 = 500000000000000000; // 0.5 ETH
    uint256 Stage_p4 = 900000000000000000; // 0.9 ETH
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
    
    
    struct RegData {
        bool picked;
        uint num;
        address account;
    }
    struct StoreNft {
        uint256 tokenid;
    }
    mapping (uint256 => RegData[] ) public regdat;
    mapping (uint256 => StoreNft[] ) public tmpnft;
    

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
        random_value = block.number;
    }

    function setAnft( address anft ) external onlyOwner {
        _anft = anft;
    }
    
    function setCAnft( address canft ) external onlyOwner {
        _canft = canft;
    }
    
    function stageAdjust( uint nextstage ) external onlyOwner {
        if( nextstage >= 4 )
          isRegister = false;
        else
          isRegister = true; 
        current_stage = nextstage;
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
        AnftToken _anftx =  AnftToken(_anft);
        address owner = _anftx.ownerOf(nftId);
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

    function addRecord(uint number, address wallet) internal {
        RegData memory newd;
        newd.picked = false;
        newd.num = number;
        newd.account = wallet;
        regdat[current_stage].push(newd);
    }
    
    function _random_X() internal view returns (uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp+block.number+uint256(keccak256(abi.encodePacked(msg.sender))))));
        return seed;
    }

    function _claim_2( address reg_addr,uint256 tokeid, int128 _dist, int128 _block, int128 _plot) internal returns (uint16) 
    {
        ICALand _caland = ICALand(_canft);
        _caland.mint(reg_addr, tokeid, _dist, _block, _plot );
    }
        
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) 
    {
        _addNft( tokenId );
        _addReg( tokenId );
        _addReg_stage( tokenId );
        emit NFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param nftId uint256 ID of the token to be removed from the tokens list
     */
     
    function _removeNft(uint256 nftId) private {

        uint256 lastNftIndex = _allNft.length.sub(1);
        uint256 NftIndex = _allNftIndex[nftId];

        uint256 lastNftId = _allNft[lastNftIndex];

        _allNft[NftIndex] = lastNftId; 
        _allNftIndex[lastNftId] = NftIndex; 

        _allNft.length--;
        _allNftIndex[nftId] = 0;
    }
    
    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addNft(uint256 tokenId) private {
        _allNftIndex[tokenId] = _allNft.length;
        _allNft.push(tokenId);
    }
    
    /**
     * @dev Gets the total amount of NFT stored by the contract.
     * @return uint256 representing the total amount of NFT
     */
    function totalNFTs() public view returns (uint256) {
        return _allNft.length;
    }


    function registeredNum(uint256 stage, uint256 index) public view returns (address) {
       // require(index < totalNFTs(), "RegisterAddress: global index out of bounds");
        return regdat[stage][index].account;
    }
    
    
    function getPriceMin() public view returns (uint256) {
       // require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
       // require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
          return stagePrice[current_stage];
    }
    
    function _addReg(uint256 tokenId) private {
        _allReg.push(tokenId);
    }
    
    function totalReg() public view returns (uint256) {
        return _allReg.length;
    }

    function _addReg_stage(uint256 tokenId) private {
        StoreNft memory snft;
        snft.tokenid = tokenId;
        tmpnft[current_stage].push(snft);
    }
    
    function totalstoreNft(uint256 stage) public view returns (uint256) {
        return tmpnft[stage].length;
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

    function preRegNFT(uint256 price100, uint256 tokenid,uint256 expiry, uint256 _nonce, int128 _district, int128 _block, int128 _plot, bytes memory sig) public payable {

            require( expiry > block.number, "Expiry fail" );
            require(!usedNonces[_nonce]);
            usedNonces[_nonce] = true;
        
            bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, price100, tokenid, _district, _block, _plot, expiry, _nonce, this)));

            if( recoverSigner( message, sig ) == checker )
            {
               require(price100 <= msg.value, "Ether too small");
               _claim_2(msg.sender,tokenid,_district,_block,_plot);
            }
    }  


    function Registered() public view returns (uint256) {
       // require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
       // require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
          return stagePrice[current_stage];
    }    

    function finializeErc20( address _token ) external onlyOwner {
        ERC20Token _tokenx =  ERC20Token(_token);
        uint _currentBalance =  _tokenx.balanceOf(address(this));
        _tokenx.transfer(_teamWallet, _currentBalance );
    }
    
    function finializeEth() external onlyOwner {
        uint256 _currentBalance =  address(this).balance;
        _teamWallet.transfer(_currentBalance);
    }

    function pickupAllow() public view returns (uint256) {
        uint rlen = round.length;
        if( rlen ==0 ){
             return 0;
        }
        
        return round[rlen-1] + round_len[rlen-1];
    }


   function setRoundforPickup() external { // onlyOwner{ 
       
       uint rlen = round.length;
       if( rlen ==0 ){
            round.push(0);
       }
       else{
           uint16 x = round[rlen-1];
           uint16 y = round_len[rlen-1];
           round.push(x+y);
       }
       
       uint16 newlen = uint16(totalReg() - round[rlen]);
       round_len.push( newlen );
         
       uint16 randomshift = uint16(random_value%newlen);
       shift.push( randomshift );
       
   }
   
   function  pickindex (uint idx) public view returns (uint){
            uint r;
            uint my_round = 0;
            for(r=0; r<round.length; r++) 
            {
               if( idx >= round[r] )
                   my_round = r;
            }
            uint thesshift = shift[my_round];
            uint start = thesshift + round[my_round];
            uint len = round_len[my_round];
            uint new_idx = idx-start + round[my_round];
            if(idx < start){
                      new_idx = idx + len -start + round[my_round];
            }   
            return new_idx;
   }
    
    function pickupNFT() external { 
        require( isPickup, "isPickup: Pickup not enable");
        
        uint total=0;
        AnftToken _anftx =  AnftToken(_anft);
        uint op_stage;
        for(op_stage=0; op_stage<4; op_stage++) 
        {
            uint length = totalstoreNft(op_stage);
            total = total + length;
            uint rlen = round.length;
            if( length > 0 && rlen > 0)
            {
               // uint256  randomshift = random_value%length;
                uint allow = round[rlen-1]+round_len[rlen-1];
                if( total > allow ){ 
                    length = length - (total-allow);
                }
                
                uint i;
                for(i=0; i<length; i++) 
                {  
                   //uint xid = regdat[op_stage][new_idx].num;
                   bool status = regdat[op_stage][i].picked;
                   address register = regdat[op_stage][i].account;
                   if( register == msg.sender && status==false)
                   {
                      uint xid = pickindex(regdat[op_stage][i].num); 
                      _anftx.safeTransferFrom( address(this), register,xid );
                      regdat[op_stage][i].picked = true;
                      _removeNft(0);
                   }
                }
            }
        }

    } 

    function getPickupdNumber( address buyer ) public view returns (uint[] memory,uint[] memory,uint[] memory,uint[] memory) 
    {  

        uint[] memory tickets_stg0;
        uint[] memory tickets_stg1;
        uint[] memory tickets_stg2;
        uint[] memory tickets_stg3;

        uint op_stage;
        for(op_stage=0; op_stage<4; op_stage++) 
        {
            uint length = totalstoreNft(op_stage);
            uint i;
            uint count = 0;
            for(i=0; i<length; i++) 
            {   
                address register = regdat[op_stage][i].account;
                if( register == buyer)
                {
                    count = count + 1;
                }
            }
            if(op_stage==0)
                tickets_stg0 = new uint[](count);
            else if(op_stage==1)
                tickets_stg1 = new uint[](count); 
            else if(op_stage==2)
                 tickets_stg2 = new uint[](count);                    
            else if(op_stage==3)
                 tickets_stg3 = new uint[](count);  

            uint cnt=0;
            for(i=0; i<length; i++) 
            {  
                bool status = regdat[op_stage][i].picked;
                //uint xid = regdat[op_stage][i].num;
                address register = regdat[op_stage][i].account;
                if( register == buyer && status==true)
                {
                    uint xid = pickindex(regdat[op_stage][i].num);
                    if(op_stage==0)
                       tickets_stg0[cnt++] = xid;
                    else if(op_stage==1)
                       tickets_stg1[cnt++] = xid; 
                    else if(op_stage==2)
                       tickets_stg2[cnt++] = xid;                    
                    else if(op_stage==3)
                       tickets_stg3[cnt++] = xid;
                }
            }
        }
        return(tickets_stg0,tickets_stg1,tickets_stg2,tickets_stg3);
    }
    
    function getRegisteredNumber( address buyer ) public view returns (uint,uint,uint,uint) 
    {  

        uint  tickets_stg0 = 0;
        uint  tickets_stg1 = 0;
        uint  tickets_stg2 = 0;
        uint  tickets_stg3 = 0;

        uint op_stage;
        for(op_stage=0; op_stage<4; op_stage++) 
        {
            uint length = totalstoreNft(op_stage);
            uint i;

            for(i=0; i<length; i++) 
            {  
                //uint xid = regdat[op_stage][i].num;
                bool status = regdat[op_stage][i].picked;
                address register = regdat[op_stage][i].account;
                if( register == buyer && status==false)
                {
                    if(op_stage==0)
                       //tickets_stg0[cnt++] = xid;
                       tickets_stg0 = tickets_stg0 + 1;
                    else if(op_stage==1)
                       //tickets_stg1[cnt++] = xid; 
                        tickets_stg1 = tickets_stg1 + 1;
                    else if(op_stage==2)
                       //tickets_stg2[cnt++] = xid; 
                       tickets_stg2 = tickets_stg2 + 1;
                    else if(op_stage==3)
                       //tickets_stg3[cnt++] = xid;
                       tickets_stg3 = tickets_stg3 + 1;
                }
            }
        }
        return(tickets_stg0,tickets_stg1,tickets_stg2,tickets_stg3);
    }
}