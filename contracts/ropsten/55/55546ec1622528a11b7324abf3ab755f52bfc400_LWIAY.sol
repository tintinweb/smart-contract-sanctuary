pragma solidity ^0.4.24;

/****************************************************************\
|  ____             __ _     _    _____      _         _       	 |
| |  _ \           / _(_)   | |  / ____|    (_)       (_)        |
| | |_) |_ __ ___ | |_ _ ___| |_| |     ___  _ _ __    _  ___    |
| |  _ <| &#39;__/ _ \|  _| / __| __| |    / _ \| | &#39;_ \  | |/ _ \   |
| | |_) | | | (_) | | | \__ \ |_| |___| (_) | | | | |_| | (_) |  |
| |____/|_|  \___/|_| |_|___/\__|\_____\___/|_|_| |_(_)_|\___/   |
|																 |
\****************************************************************/

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

contract Ownable {
    address private _owner;

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

contract LWIAY is Ownable {
    
    using SafeMath for uint;
    
    event NewEpisode(uint id);
    event NewMeme(uint id);
    event EpisodeEdited(uint id);
    event MemeEdited(uint id);
    
    uint public episodeCount;
    uint public memeCount;
    uint public totalPaid; // Reminder: PEW token has 8 decimal places
    
    // Meme id => Transaction hash
    mapping(uint => string) payouts;
    
    // Episode => memes
    mapping(uint => uint[]) episodeToMemes;
    
    
    struct Episode {
        string title;
        string url;
        uint32 date;
    }
    
    
    struct Meme {
        string author;
        string title;
        string url;
        string thumbnail;
        uint reward;
    }
    
    
    Episode[] public episodes;
    Meme[] public memes;


    function addEpisode(
        string memory _title,
        string memory _url,
        uint32 _date
    ) 
    
    public onlyOwner {
        uint id = episodes.push(Episode(
            _title, 
            _url,
            _date
        )) -1;
        
        episodeCount++;
        emit NewEpisode(id);
    }
    
    
    function addMeme(
        string memory _author,
        string memory _title,
        string memory _url,
        string memory _thumbnail,
        uint _reward,
        uint _episode
    ) 
    
    public onlyOwner {
        uint id = memes.push(Meme(
            _author,
            _title,
            _url,
            _thumbnail,
            _reward)) -1;
        
        memeCount++;
        episodeToMemes[_episode].push(uint(id));
        emit NewMeme(id);
    }
    
    
    function editEpisode(uint _id, string _title, string _url, uint32 _date) external onlyOwner {
        episodes[_id].title = _title;
        episodes[_id].url = _url;
        episodes[_id].date = _date;
        
        emit EpisodeEdited(_id);
    }
    

    function editMemes(uint _id, string _author, string _title, string _url, string _thumbnail, uint _reward) external onlyOwner {
        memes[_id].author = _author;
        memes[_id].title = _title;
        memes[_id].url = _url;
        memes[_id].thumbnail = _thumbnail;
        memes[_id].reward = _reward;
        
        emit MemeEdited(_id);
    }
    
    
    function addPayout(uint _id, uint _amount, string _hash) external onlyOwner {
        payouts[_id] = _hash;
        totalPaid = totalPaid.add(_amount);
    }
    
    
    function getMemesForEpisode(uint _id) external view returns (uint[]) {
        return episodeToMemes[_id];
    }
    
    
    function getEpisodeData(uint _id) external view returns (string, string, uint32) {
        return (episodes[_id].title, episodes[_id].url, episodes[_id].date);
    }
    
    
    function getMemeData(uint _id) external view returns (string, string, string, string, uint) {
        return (memes[_id].author, memes[_id].title, memes[_id].url, memes[_id].thumbnail, memes[_id].reward);
    }


}