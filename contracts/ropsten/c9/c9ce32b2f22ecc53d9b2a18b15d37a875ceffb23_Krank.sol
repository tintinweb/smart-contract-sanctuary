pragma solidity ^0.4.23;

contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address _owner ) public view returns (uint balance);
    function allowance( address _owner, address _spender ) public view returns (uint allowance_);

    function transfer( address _to, uint _value)public returns (bool success);
    function transferFrom( address _from, address _to, uint _value)public returns (bool success);
    function approve( address _spender, uint _value )public returns (bool success);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed _owner, address indexed _spender, uint value);
}

contract Token is ERC20{
    uint8 public constant TOKEN_DECIMAL      = 18;
    uint public constant TOKEN_ESCALE       = 1 * 10 ** uint(TOKEN_DECIMAL);
    uint public constant TOTAL_SUPPLY       = 1000000000000 * TOKEN_ESCALE; 
    string public constant TOKEN_NAME       = "Prod";
    string public constant TOKEN_SYMBOL     = "PRD";
    uint256 public totalSupply              = TOTAL_SUPPLY;
    mapping(address => uint256) public balances;    
    mapping(address => mapping (address => uint256)) public allowed;
    address public owner;
    event Transfer(address indexed from , address indexed to , uint256 value);
    event Approval(address indexed _owner , address indexed _spender , uint256 _value);
    event Burn(address indexed from, uint256 value);
    event FundTransfer(address backer , uint amount , address investor);
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    //Safe math
    function safeSub(uint a , uint b) internal pure returns (uint){assert(b <= a);return a - b;}  
    function safeAdd(uint a , uint b) internal pure returns (uint){uint c = a + b;assert(c>=a && c>=b);return c;}
    
    constructor() public{
        balances[msg.sender] = totalSupply;
        owner                = msg.sender;
    }
    /**
     * ERC20
     */
    function balanceOf(address _owner) public view returns(uint256 balance){
        return balances[_owner];
    }
    /**
     * ERC20
     */
    function totalSupply()public constant returns(uint256 supply){
        return totalSupply;
    }
    /**
     * For transfer tokens. Internal use, only can executed by this contract ERC20
     * ERC20
     * @param  _from         Source address
     * @param  _to           Destination address
     * @param  _value        Amount of tokens to send
     */
    function _transfer(address _from , address _to , uint _value) internal{        
        require(_to != 0x0);                                                          //Prevent send tokens to 0x0 address        
        require(balances[_from] >= _value);                                           //Check if the sender have enough tokens        
        require(balances[_to] + _value > balances[_to]);                              //Check for overflows        
        balances[_from]         = safeSub(balances[_from] , _value);                  //Subtract from the source ( sender )        
        balances[_to]           = safeAdd(balances[_to]   , _value);                  //Add tokens to destination        
        uint previousBalance    = balances[_from] + balances[_to];                    //To make assert        
        emit Transfer(_from , _to , _value);                                               //Fire event for clients        
        assert(balances[_from] + balances[_to] == previousBalance);                   //Check the assert
    }
    /**
     * Commonly transfer tokens 
     * ERC20
     * @param  _to           Destination address
     * @param  _value        Amount of tokens to send
     */
    function transfer(address _to , uint _value) public returns (bool success){        
        _transfer(msg.sender , _to , _value);
        return true;
    }
    /**
     * Transfer token from address to another address that&#39;s allowed to. 
     * ERC20
     * @param _from          Source address
     * @param _to            Destination address
     * @param _value         Amount of tokens to send
     */   
    function transferFrom(address _from , address _to , uint256 _value) public returns (bool success){
        if(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            _transfer(_from , _to , _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender] , _value);
            return true;
        }else{
            return false;
        }
    }

    /**
     * Approve spender to transfer amount of tokens from your address ERC20
     * ERC20
     * @param _spender       Address that can transfer tokens from your address
     * @param _value         Amount of tokens that can be sended by spender
     */   
    function approve(address _spender , uint256 _value) public returns (bool success){
    allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender , _spender , _value);
        return true;
    }

    /**
     * Returns the amount of tokens allowed by owner to spender ERC20
     * ERC20
     * @param _owner         Source address that allow&#39;s spend tokens
     * @param _spender       Address that can transfer tokens form allowed     
     */   
    function allowance(address _owner , address _spender) public view returns(uint256){
        return allowed[_owner][_spender];
    }

    
    function _mintToken(address target , uint mintedAmount) internal{
        balances[target] = safeAdd(balances[target], mintedAmount);
        totalSupply += mintedAmount;
        emit Transfer(0 , target , mintedAmount);
    }
}

contract Crowdsale is Token{
    uint public MIN_ACCEPTED_VALUE = 50000000000000000 wei;
    uint public TOKEN_VALUE        = 100000000000000 wei;
    uint public CROWDSALE_SUPPLY   = 300000000000 * TOKEN_ESCALE;
    uint public TOKEN_SOLD         = 0;
    bool public CROWDSALE_STARTED  = true;


    modifier crowdsaleStarted() { 
        require(CROWDSALE_STARTED == true);
        _; 
    }
    
    modifier minValue(){
        require(msg.value >= MIN_ACCEPTED_VALUE);
        _;      
    }

    /**
     * Start de Crowdsale
     */
    function startCrowdsale() public{
        CROWDSALE_STARTED = true;
    }

    /**
     * Stop de Crowdsale
     */
    function stopCrowdsale() public{
        CROWDSALE_STARTED = false;
    }


    /**
     * Calculate the amount of tokens to sends depeding on the amount of ethers received
     *
     * @param  _ethers              Amount of ethers for convert to tokens
     * @return uint                 Returns the amount of tokens to send
     */
    function getTokensToSend(uint _ethers) public view returns (uint){
        uint tokensToSend  = 0; //Assign tokens to send to 0                                                    
        uint ethToTokens   = (_ethers * 10 ** uint256(TOKEN_DECIMAL)) / TOKEN_VALUE; //Make the conversion, divide amount of ethers by value of each UTS                                     
        return ethToTokens;
    }

    
    /**
     * Receives ether and send tokens to investor
     */
    function () payable public crowdsaleStarted minValue{       
        address buyer = msg.sender;
        uint tokens   = getTokensToSend(msg.value);     
        require((TOKEN_SOLD+tokens) <= CROWDSALE_SUPPLY);
        TOKEN_SOLD+=tokens;
        _transfer(owner , buyer , tokens);
    }   
}

contract ArtistsManagement is Token{
    
    uint public requiredApprovals = 0;

    mapping(address => Artists) public artists;    
    mapping(address => mapping(address => bool)) public pendingArtistsApprovals;
    mapping(address => uint) public pendingArtists;    
    address[] public pendingArtistsIndex; 
    address[] public artistsList;
    
    struct Artists{
        bytes32 artistInfo;
        bytes32 avatar;   
        bytes32 promoTrack;   
        uint likes;
        uint dislikes;
        uint index;
        mapping(address => bool) likedFrom;        
        mapping(address => bool) dislikedFrom;
        address[] approversRewardeds;
        uint indexApproversRewardeds;
        address[] unnapproversRewardeds;
        uint indexUnnapproversRewardeds;
        bool registered;
        bool pending;
    }
    
    event ApprovedArtist(address artist);
    event ApprovedSuccessful(address artist);

    constructor() public {}


    function isArtist(address user) constant public returns (bool){
        if(artists[user].registered != true && artists[user].registered != false){
            return false;
        }else{
            return artists[user].registered;
        }
    }

    /**
     * Make a request for be artist
     *
     * @param  artistInfo           IPFS Hash of artist info
     * @param  avatar               IPFS Hash of artist avatar
     * @param  promoTrack           IPFS Hash of artist promo track     
     */    
    function requestForArtistRegistration(bytes32 artistInfo , bytes32 avatar , bytes32 promoTrack) public {
        address artist = msg.sender;
        require(artists[artist].registered != true);
        require(artists[artist].pending != true);
        artists[artist].artistInfo    = artistInfo;        
        artists[artist].avatar        = avatar;      
        artists[artist].promoTrack    = promoTrack;  
        artists[artist].registered    = false;
        artists[artist].pending       = true;
        uint index                    = pendingArtistsIndex.length++;
        pendingArtistsIndex[index]    = artist;
        artists[artist].index         = index;
    }

    /**
     * Returns an artist list
     *
     * @return Array                Returns an array with list of artists
     */        
    function getArtistList() public returns(address[]){
        return artistsList;
    }
    

    /**
     * Remove artist from unapproved artist
     *
     * @return Array                Returns an array with list of artists
     */ 
    function _unregisterArtist(address artist) public{
       require(artists[artist].registered == true);
       delete artists[artist];
       _rewardUnnapprovers(artist);
    }

    function approveArtist(address artist) public{
        require(pendingArtistsApprovals[artist][msg.sender] != true);
        require(super.balanceOf(msg.sender) >= 5000000000000000000);        
        pendingArtistsApprovals[artist][msg.sender] = true;
        pendingArtists[artist] += 1;
        super._transfer(msg.sender , owner , 5000000000000000000);
        uint indexRewardeds = artists[artist].approversRewardeds.length++;
        artists[artist].approversRewardeds[indexRewardeds] = msg.sender;
        if(pendingArtists[artist] >= requiredApprovals){
            _registerArtist(artist);
        }        
        emit ApprovedArtist(artist);
    }
    function unapproveArtist(address artist) public{
        require(pendingArtistsApprovals[artist][msg.sender] != true);
        require(super.balanceOf(msg.sender) >= 5000000000000000000);        
        pendingArtistsApprovals[artist][msg.sender] = true;
        pendingArtists[artist] -= 1;
        super._transfer(msg.sender , owner , 5000000000000000000);
        uint indexRewardeds = artists[artist].unnapproversRewardeds.length++;
        artists[artist].unnapproversRewardeds[indexRewardeds] = msg.sender;
        if(pendingArtists[artist] < 0){
            _unregisterArtist(artist);
        }
    }
    function getUnapprovedArtists() constant public returns(address[], bytes32[], bytes32[] , bytes32[] , uint[]){
        uint length = pendingArtistsIndex.length;                                             //Length of array
        address[] memory addr        = new address[](length);
        bytes32[] memory artistInfo  = new bytes32[](length);
        bytes32[] memory avatar      = new bytes32[](length);
        bytes32[] memory promoTrack  = new bytes32[](length);
        uint[] memory approveds      = new uint[](length);
        for(uint i = 0; i < length; i++){
            address key = pendingArtistsIndex[i];
            if(artists[key].registered == false){
                addr[i]        = key;
                artistInfo[i] = artists[key].artistInfo;                
                approveds[i]  = pendingArtists[key];
                avatar[i]     = artists[key].avatar;
                promoTrack[i] = artists[key].promoTrack;
            }
        }
        return (addr , artistInfo , avatar  , promoTrack , approveds);   
    }
    function _registerArtist(address artist) internal{
        require(artists[artist].registered != true);
        require(artists[artist].pending == true);
        artists[artist].registered = true;
        artists[artist].pending    = false;
        artistsList.push(artist);
        _rewardApprovers(artist);
        emit ApprovedSuccessful(artist);
    }

    function _rewardApprovers(address artist) internal{
        uint length = artists[artist].approversRewardeds.length;
        for(uint i = 0; i < length; i++){
            address approver = artists[artist].approversRewardeds[i];
            super._mintToken(approver , 2500000000000000000);
            super._transfer(owner , approver , 5000000000000000000);
        }
    }
    
    function _rewardUnnapprovers(address artist) internal{
        uint length = artists[artist].unnapproversRewardeds.length;
        for(uint i = 0; i < length; i++){
            address approver = artists[artist].unnapproversRewardeds[i];
            super._mintToken(approver , 2500000000000000000);
            super._transfer(owner , approver , 5000000000000000000);
        }
    }
}

contract TracksManagement is ArtistsManagement{
    
    mapping(address => mapping (bytes32 => Tracks)) public artistTracks;
    mapping(address => bytes32[]) public artistTracksList;    
    mapping(address => bytes32[]) public albums;

    struct Tracks{
        bytes32 trackName;
        uint price;        
        uint likes;
        uint dislikes;        
        bool exists;
        bool isAlbum; 
        bool isFeaturing;
        bytes32 cover;
        bytes32 genre;
        bytes32 albumId; 
        mapping(address => bool) featurers;
        mapping(address => bool) likedFrom;
        mapping(address => bool) dislikedFrom;
        mapping(address => bool) buyers;
    }


    constructor() public{         
    }

    function registerTrack(bytes32 trackId , uint price, bytes32 trackName , bytes32 genre , bytes32 cover) public{
        address artist = msg.sender;
        require(artists[artist].registered == true);
        require(artistTracks[artist][trackId].exists != true);
        artistTracksList[artist].push(trackId);
        artistTracks[artist][trackId].price     = price;
        artistTracks[artist][trackId].trackName = trackName;
        artistTracks[artist][trackId].genre     = genre;
        artistTracks[artist][trackId].exists    = true;
    }

    function registerAlbum(bytes32[] tracksIds , bytes32[] tracksNames , bytes32[] genres , bytes32[] isFeaturing , bytes32 albumId , bytes32 cover) public{
        address artist  = msg.sender;
        uint length     = tracksIds.length;
        uint priceAlbum = 10000;
        albums[artist].push(albumId);
        for(uint i = 0; i < length; i++){            
            registerTrack(tracksIds[i] , priceAlbum , tracksNames[i] , genres[i] , cover);
        }
    }

    function getTracks() constant public returns(bytes32[],bytes32[] , uint[] , bytes32[]){
        address[] memory artistList = super.getArtistList();
        for(uint i = 0; i < artistList.length; i++){
            uint lengthArtistsTrack = artistTracksList[artistList[i]].length;            
            bytes32[] memory trackName  = new bytes32[](lengthArtistsTrack);
            uint[] memory trackPrice    = new uint[](lengthArtistsTrack);
            uint[] memory likes         = new uint[](lengthArtistsTrack);
            uint[] memory dislikes      = new uint[](lengthArtistsTrack);                        
            bytes32[] memory genre      = new bytes32[](lengthArtistsTrack); 
            bytes32[] memory trackId    = new bytes32[](lengthArtistsTrack);           
            for(uint e = 0; e < lengthArtistsTrack; e++){
                bytes32 _trackId          = artistTracksList[artistList[i]][e];
                 trackId[e]    = artistTracksList[artistList[i]][e];
                 trackName[e]  = artistTracks[artistList[i]][_trackId].trackName;
                 trackPrice[e] = artistTracks[artistList[i]][_trackId].price;
                 genre[e]      = artistTracks[artistList[i]][_trackId].genre;
            }
        }
        return(trackId , trackName , trackPrice , genre);
    }


    function canDownload(address artist , address buyer , bytes32 trackId) public constant returns(bool){
        return artistTracks[artist][trackId].buyers[buyer];
    }

    function getArtistTrack(bytes32 trackId , address artist) public constant returns(bytes32 , uint){
        return (artistTracks[artist][trackId].trackName , artistTracks[artist][trackId].price);
    }
    
    function likeTrack(address artist , bytes32 trackId) public{
        require(artistTracks[artist][trackId].likedFrom[msg.sender] != true);
        artistTracks[artist][trackId].likedFrom[msg.sender] = true;
        artistTracks[artist][trackId].likes += 1;        
    }
    function dislikeTrack(address artist , bytes32 trackId) public{
        require(artistTracks[artist][trackId].dislikedFrom[msg.sender] != true);
        artistTracks[artist][trackId].dislikes += 1;
        artistTracks[artist][trackId].dislikedFrom[msg.sender] = true;        
    } 
    
    function likeArtist(address artist) public{
        require(artists[artist].likedFrom[msg.sender] != true);
        artists[artist].likedFrom[msg.sender] = true;
        artists[artist].likes += 1;                
    }
    
    function dislikeArtist(address artist) public{
        require(artists[artist].dislikedFrom[msg.sender] != true);
        artists[artist].dislikedFrom[msg.sender] = true;
        artists[artist].dislikes += 1;             
    }
}

contract Shop is Token , ArtistsManagement , TracksManagement{
     
    constructor() public { }

    function buyTrack(address artist , bytes32 trackId) public{
         address buyer = msg.sender;
         uint price    = artistTracks[artist][trackId].price;
         artistTracks[artist][trackId].buyers[buyer] = true;
        _transfer(buyer , artist , price);
    }
}

contract Krank is Shop , Crowdsale{    
    constructor() public{
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
}