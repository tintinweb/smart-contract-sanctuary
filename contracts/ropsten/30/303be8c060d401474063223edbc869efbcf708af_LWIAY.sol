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
    
    event NewEpisode(uint id);
    event NewMeme(uint id);
    event EpisodeEdited(uint id);
    event MemeEdited(uint id);
    
    uint public episodeCount;
    uint public memeCount;
    
    // Meme id => Transaction hash
    mapping(uint => string) payouts;
    
    
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
        uint _reward
    ) 
    
    public onlyOwner {
        uint id = memes.push(Meme(
            _author,
            _title,
            _url,
            _thumbnail,
            _reward)) -1;
        
        memeCount++;
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
    
    
    function addPayout(uint _id, string _hash) external onlyOwner {
        payouts[_id] = _hash;
    }


}