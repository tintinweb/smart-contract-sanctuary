pragma solidity ^0.4.24;

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
    
    
    uint public episodeCount;
    uint public memeCount;
    
    
    struct Episode {
        string title;
        string url;
        uint32 date;
    }
    
    
    struct Meme {
        string author;
        string title;
        string url;
        uint8 reward;
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
        uint8 _reward
    ) 
    
    public onlyOwner {
        uint id = memes.push(Meme(
            _author,
            _title,
            _url,
            _reward)) -1;
        
        memeCount++;
        emit NewMeme(id);
    }


}