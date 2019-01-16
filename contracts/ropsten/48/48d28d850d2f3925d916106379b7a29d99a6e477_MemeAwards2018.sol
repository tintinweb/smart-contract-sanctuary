pragma solidity ^0.4.24;

/*
  __  __                                                    _       ___   ___  __  ___  
 |  \/  |                         /\                       | |     |__ \ / _ \/_ |/ _ \ 
 | \  / | ___ _ __ ___   ___     /  \__      ____ _ _ __ __| |___     ) | | | || | (_) |
 | |\/| |/ _ \ &#39;_ ` _ \ / _ \   / /\ \ \ /\ / / _` | &#39;__/ _` / __|   / /| | | || |> _ < 
 | |  | |  __/ | | | | |  __/  / ____ \ V  V / (_| | | | (_| \__ \  / /_| |_| || | (_) |
 |_|  |_|\___|_| |_| |_|\___| /_/    \_\_/\_/ \__,_|_|  \__,_|___/ |____|\___/ |_|\___/

*/

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
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
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

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

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _approved, uint256 _tokenId) external payable;
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
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

contract MemeAwards2018 is ERC721, Ownable {
    
    using SafeMath for uint;
    
    event MemeClaimed(uint _memeId, address _who);
    
    struct Meme {
        string name;
        string category;
        string url;
        string ipfsHash;
    }
    
    // When was the contract released
    uint public releaseDate;
    constructor() {
        releaseDate = now;
    }
    
    // Incrementing nonce for the random function
    uint private randNonce;
    
    // Templates of claimable memes (the 10 best memes of 2018)
    Meme[] public memeTemplates;
    
    // Memes claimed by users chosen randomly from memeTemplates
    Meme[] public claimedMemes;
    
    // map the claimed memes (claimedMemes) to the claimable memes templates (memeTemplates)
    mapping (uint => uint) public whichMemeIsWhich;
    
    // One meme per address (only during free airdrop)
    mapping (address => bool) public hasClaimed;
    
    // Id of a claimedMemes Meme to address (the owner)
    mapping (uint => address) public memeRegistry;
    
    // Meme counter (how many memes an address holds)
    mapping (address => uint) public ownerMemeCount;
    
    // Total supply of memes in circulation (memeTemplates id => count)
    mapping (uint => uint) public memesTotalSupply;
    
    // Approvals
    mapping (uint => address) public memeApprovals;
    
    // Check that the address has not yet claimed a meme
    modifier hasNotClaimed() {
        require(hasClaimed[msg.sender] == false);
        _;
    }
    
    // The 30 day window after releaseDate when memes can be claimed freely
    modifier canClaim() {
        require(releaseDate + 30 days >= now);
        _;
    }
    
    // Check if meme is owned by address
    modifier onlyOwnerOf(uint _memeId) {
        require(memeRegistry[_memeId] == msg.sender);
        _;
    }
    
    // Returns a pseudo random number between 1 and the length of memeTemplates array
    function _randomMeme() internal returns (uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % memeTemplates.length;
    }
    
    /* Public function to claim yourself a meme!
    It might not be the most optimal solution so sorry for any potential 
    wasted Gas. I did my best at the time of writing 2nd of Jan 2019 */
    function claimMeme() public hasNotClaimed canClaim {
        uint randomMemeId = _randomMeme();
        string memory memeName = memeTemplates[randomMemeId].name;
        string memory memeCategory = memeTemplates[randomMemeId].category;
        string memory memeUrl = memeTemplates[randomMemeId].url;
        string memory memeIPFSHash = memeTemplates[randomMemeId].ipfsHash;
        uint id = claimedMemes.push(Meme(memeName, memeCategory, memeUrl, memeIPFSHash)) -1;
        memeRegistry[id] = msg.sender;
        //id of new meme to one of the template memes
        whichMemeIsWhich[id] = randomMemeId; 
        // Increment total supply of this meme
        memesTotalSupply[randomMemeId] = memesTotalSupply[randomMemeId].add(1);
        ownerMemeCount[msg.sender] = ownerMemeCount[msg.sender].add(1);
        hasClaimed[msg.sender] = true;
        emit MemeClaimed(id, msg.sender);
    }
    
    // Sends a meme to another address
    function _transferMeme(address _from, address _to, uint _memeId) private {
        ownerMemeCount[_to] = ownerMemeCount[_to].add(1);
        ownerMemeCount[msg.sender] = ownerMemeCount[msg.sender].sub(1);
        memeRegistry[_memeId] = _to;
        emit Transfer(_from, _to, _memeId);
    }

    // Return the total claimed memes count (how many cards are out there)
    function getMemeCount() external view returns (uint) {
        return claimedMemes.length;
    }

    // ERC721 Standard functions
    function balanceOf(address _owner) external view returns (uint256) {
        return ownerMemeCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) external view returns (address) {
        return memeRegistry[_tokenId];
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require (memeRegistry[_tokenId] == msg.sender || memeApprovals[_tokenId] == msg.sender);
        _transferMeme(_from, _to, _tokenId);
    }
    
    function approve(address _approved, uint256 _tokenId) external payable onlyOwnerOf(_tokenId) {
        memeApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }
    
    
    // Admin functions
    function editMemeInfo(
        uint _memeId, 
        string _name, 
        string _category,
        string _Url,
        string _ipfsHash
    ) 
        external onlyOwner 
    {
        memeTemplates[_memeId].name = _name;
        memeTemplates[_memeId].category = _category;
        memeTemplates[_memeId].url = _Url;
        memeTemplates[_memeId].ipfsHash = _ipfsHash;
    }
    
    
    function addNewMeme(
        string _name, 
        string _category,
        string _Url,
        string _ipfsHash
    ) 
        external onlyOwner 
    {
        memeTemplates.push(Meme(_name, _category, _Url, _ipfsHash)) - 1;
    }
        
}