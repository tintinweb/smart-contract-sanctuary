/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

/*
    Description:
    P2E contract version 0.0.06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

uint256 constant EULER_NUM = 271828; // EULAR_NUM / 10000

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) { return payable(msg.sender); }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
        }
    }
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) { return _owner; }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    }
interface IERC721Special is IERC721{
    function getAggregateWeight(address _owner) external view returns (uint256);
    function getERC721Indecies(address _owner) external view returns (int[] memory);
    function tokensOfOwner(address _owner) external view returns (uint256[] memory);
    function getNftWeight(address _owner) external view returns(uint256);
}
interface IERC20Special is IERC20{
    function mintFromGamify(uint256 _amount, address _recipient) external returns (bool);
    function decimals() external view returns (uint8);
}
contract SirLeonidus_P2E is Ownable {
    mapping (address => bool) internal authorizations;
    mapping (uint256 => bool) publicKey;
    mapping (uint256 => bool) tempKey;
    mapping (uint256 => uint256) tempKeyExpiration;

    uint256 internal EPOCH1 = 86400;
    uint256 internal EPOCH7 = 604800;
    uint256 private privateKey;

    uint256 public dailyPayout;
    uint256 public weeklyPayout;
    uint256 public dayEndTimestamp;
    uint256 public weekEndTimestamp;

    uint256[10] public dailyPayoutRate;  // payout rates for P2E only
    uint256[10] public weeklyPayoutRate;

    address public goverenceToken = 0x000000000000000000000000000000000000dEaD;
    address public nftToken       = 0x000000000000000000000000000000000000dEaD;

    string public version;
// ----------------------------------------------------------------------------
// Possible multiple NFT contracts (all MUST use "getNFTWeight"):
    mapping (address => bool) internal nftContract;                       // NFT > is contract with active rewards
    mapping (address => mapping (address => uint256)) public rewards;     // NFT > user > total rewards
    mapping (address => mapping (address => uint256)) public lastClaim;   // NFT > user > last claim
    mapping (address => score) public playerHighscore;
    mapping (address => uint256[]) public scoreIndex;
    uint256 public totalRewards;                                          // NFT > overall total rewards
    uint256 public stakedPayout = 100;
    
    bool internal locked;
    modifier noreentry() {
        require(!locked, "No re-entrance");
        locked = true;
        _;
        locked = false;
        }
    modifier authorization(uint256 _key) { require(authorizations[_msgSender()] || privateKey == _key, "Only designated user can edit contract"); _; }
    modifier client(uint256 _key) { require(publicKey[_key] || (tempKey[_key] && tempKeyExpiration[_key] > block.timestamp), "Only designated client can edit contract state"); _; }

    struct score { uint256 score; uint256 timestamp; string version; }
    struct highscore { uint256 score; uint256 timestamp; address player; string version; }

    score[] private scores;
    highscore[30] private highscores;          //top 30 all-time
    highscore[30] private highscoresDaily;     //top 30 daily

    constructor(address [] memory _devs, uint256 input) { 
        authorizations[owner()] = true;
        for(uint256 i=0; i<_devs.length; i++)
            authorizations[_devs[i]] = true;

        dailyPayoutRate  = [40, 30, 15, 9, 1, 1, 1, 1, 1, 1];
        weeklyPayoutRate = [40, 30, 15, 9, 1, 1, 1, 1, 1, 1];

        dailyPayout  = 100;
        weeklyPayout = 500;
        totalRewards = 0;

        privateKey = uint256(keccak256(abi.encodePacked(block.timestamp, rand(), input)));

        uint256 current  = block.timestamp;
        dayEndTimestamp  = current - current % EPOCH1 + EPOCH1;
        weekEndTimestamp = current - current % EPOCH7 + EPOCH7;
        }
    receive() external payable {}

    function updateAuthorization(bool state, address target) external onlyOwner { 
        require(authorizations[target] != state);
        authorizations[target] = state;
        }
    function getPrivateKey() external view onlyOwner returns(uint256) { return privateKey; }
    function generateKey(uint256 _privateKey, bool temp) external authorization(_privateKey) noreentry returns(uint256) {
        uint256 key = uint256(keccak256(abi.encodePacked(block.timestamp, rand(), privateKey)));
        if(temp) {
            tempKey[key] = true;
            tempKeyExpiration[key] = block.timestamp + EPOCH7;
        } else { publicKey[key] = true; }
        return key;
        }
    function updateKey(uint256 _privateKey, uint256 key, bool state, bool temp, uint256 _days) external authorization(_privateKey) noreentry {
        if(temp) {
            require(_days > 0 && _days < 15);
            require(tempKey[key], "tempKey[key] is false, you must request a new key");
            if(state) {
                tempKey[key] = true;
                tempKeyExpiration[key] = tempKeyExpiration[key] + EPOCH1 * _days;
            } else { tempKey[key] = false; }
        } else { 
            require(publicKey[key] == state, "publicKey[key] is already has that state");
            publicKey[key] = state;
        }
    }

    function updateData(string memory _version, address _governenceToken, address _nftToken) external onlyOwner {
        version = _version;
        goverenceToken = _governenceToken;
        nftToken = _nftToken;
        nftContract[_nftToken] = true;
        }
    function rand() public view returns(uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / 
                    (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / 
                    (block.timestamp)) + block.number)
                    )
                );
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else { return randNumber; }
    }

    function resetDailyHighscores() internal {
        for(uint256 i=0; i<30; i++) {
            highscoresDaily[i].score = 0;
            highscoresDaily[i].timestamp = block.timestamp;
            highscoresDaily[i].version = version;
        }
        }
    function addPlayerHighscore(uint256 _score, address _player, uint256 _timestamp) internal returns (bool) {
        uint256[] memory _indecies = scoreIndex[_player];
        // change personal best highscore
        if(playerHighscore[_player].score == 0) {
            playerHighscore[_player].score = _score;
            playerHighscore[_player].timestamp = _timestamp;
            playerHighscore[_player].version = version;
            return true;
        } else {
            for(uint256 i=0; i<_indecies.length; i++) {
                if(scores[_indecies[i]].score > playerHighscore[_player].score) {
                    playerHighscore[_player].score = _score;
                    playerHighscore[_player].timestamp = _timestamp;
                    playerHighscore[_player].version = version;
                    return true;
                }
            }
        }
        return false;
        }
    function addHighscoreDaily(uint256 _score, address _player, uint256 _timestamp) internal returns (bool) {
        int newScore = 999;
        for(int i=0; i<30; i++) 
            if(_score > highscoresDaily[uint256(i)].score) newScore = i;
        
        if(newScore != 999)
        if(newScore == 29) {
            highscoresDaily[29].score = _score;
            highscoresDaily[29].timestamp = _timestamp;
            highscoresDaily[29].player = _player;
            highscoresDaily[29].version = version;
            return true;
        } else {
            highscoresDaily[uint256(newScore)].score = _score;
            highscoresDaily[uint256(newScore)].timestamp = _timestamp;
            highscoresDaily[uint256(newScore)].player = _player;
            for(uint256 i=highscoresDaily.length-1; i>uint256(newScore); i--) {
                highscoresDaily[i].score = highscoresDaily[i-1].score;
                highscoresDaily[i].timestamp = highscoresDaily[i-1].timestamp;
                highscoresDaily[i].player = highscoresDaily[i-1].player;
                highscoresDaily[i].version = version;
            }
            return true;
        }
        return false;
        }
    function addHighscore(uint256 _score, address _player, uint256 _timestamp) internal {
        int newScore = 999;
        for(int i=0; i<30; i++) 
            if(_score > highscores[uint256(i)].score) newScore = i;
        
        if(newScore != 999)
        if(newScore == 29) {
            highscores[29].score = _score;
            highscores[29].timestamp = _timestamp;
            highscores[29].player = _player;
            highscores[29].version = version;
            //return true;
        } else {
            highscores[uint256(newScore)].score = _score;
            highscores[uint256(newScore)].timestamp = _timestamp;
            highscores[uint256(newScore)].player = _player;
            for(uint256 i=highscores.length-1; i>uint256(newScore); i--) {
                highscores[i].score = highscores[i-1].score;
                highscores[i].timestamp = highscores[i-1].timestamp;
                highscores[i].player = highscores[i-1].player;
                highscores[i].version = version;
            }
            //return true;
        }
        //return false;
        }
    function addScore(uint256 _score, address _player, uint256 key) external client(key) {
        // add fee to contract or governence LP
        // add score
        scores.push(score(_score, block.timestamp, version));
        scoreIndex[_player].push(scores.length);

        // test for new day
        uint256 newTime = block.timestamp;
        bool newDay = false;
        for(uint256 i=0; i<30; i++) {
            uint256 oldTime = highscoresDaily[i].timestamp;
            if(((oldTime - (oldTime % EPOCH1)) / EPOCH1) != ((newTime - (newTime % EPOCH1)) / EPOCH1))
                newDay = true;
        }

        //payout
        if(newDay) { 
            if(mintForHighscoreDaily()) {
                dayEndTimestamp  = dayEndTimestamp + EPOCH1;
                if(mintForHighscore())
                    weekEndTimestamp  = weekEndTimestamp + EPOCH7;
            }
            resetDailyHighscores();
        }

        // check highscore status
        if(addPlayerHighscore(_score, _player, newTime))
            if(addHighscoreDaily(_score, _player, newTime))
                addHighscore(_score, _player, newTime);

        // payout NFTs
        //uint256 lastScoreTime = scores[scoreIndex[_player][scoreIndex[_player].length-1]].timestamp;
        uint256 _lastClaim = lastClaim[nftToken][_player];
            
        if(((_lastClaim - (_lastClaim % EPOCH1)) / EPOCH1) < ((newTime - (newTime % EPOCH1)) / EPOCH1)) {
            if(mintForNFT(nftToken, _player))
                lastClaim[nftToken][_player] = newTime;
        }

    }

    function getHighscore(address _player) external view returns (uint256, uint256, string memory) { return ( playerHighscore[_player].score, playerHighscore[_player].timestamp, playerHighscore[_player].version ); }
    function getHighscores(bool daily) external view returns (uint256[30] memory, address[30] memory, uint256[30] memory, string[30] memory) {
        uint256[30] memory _scores;
        address[30] memory _players;
        uint256[30] memory _timestamps;
        string[30] memory _version;
        if(daily) {
            for(uint256 i=0; i<30; i++) {
            _scores[i] = highscoresDaily[i].score;
            _players[i] = highscoresDaily[i].player;
            _timestamps[i] = highscoresDaily[i].timestamp;
            _version[i] = highscoresDaily[i].version;
            }
        } else {
            for(uint256 i=0; i<30; i++) {
                _scores[i] = highscores[i].score;
                _players[i] = highscores[i].player;
                _timestamps[i] = highscores[i].timestamp;
                _version[i] = highscores[i].version;
            }
        }
        return (_scores, _players, _timestamps, _version);
        }
    function getScores(address _player) external view returns (uint256[] memory, uint256[] memory, string[] memory) {
        require(scoreIndex[_player].length != 0);
        require(scores.length > 0);

        uint256[] memory _scores;
        uint256[] memory _timestamps;
        string[] memory _version;
        for(uint256 i=0; i<scoreIndex[_player].length; i++) {
            _scores[i] = scores[scoreIndex[_player][i]].score;
            _timestamps[i] = scores[scoreIndex[_player][i]].timestamp;
            _version[i] = scores[scoreIndex[_player][i]].version;
        }

        return ( _scores, _timestamps, _version );
    }

    

    event MintForGamify(bool success, uint256 amount, address minter, address recipient);
    function getWeight(address _owner, address _token) public noreentry returns(uint256) {
        address token;
        if(_token == address(0)) { token = nftToken; }
        else { token = _token; }

        //(bool success, bytes memory result) = _token.call(bytes4(keccak256("ownerWeight(address)")),_owner);
        return IERC721Special(token).getNftWeight(_owner);
        }
    function mintForNFT(address _contract, address _recipient) internal noreentry returns (bool) {
        address token;
        bool success = false;
        if(_contract == address(0)) { token = nftToken; }
        else { token = _contract; }

        if(!nftContract[token]) return false;
        uint256 _amount = getWeight(_recipient, token) * stakedPayout;
        success = mintReward(_amount, _recipient);
        if(success) totalRewards = totalRewards + _amount;

        emit MintForGamify(success, getWeight(_recipient, token) * stakedPayout, address(this), _recipient);
        return success;
        }
    function mintForHighscoreDaily() internal noreentry returns (bool) {
        uint256 newTime = block.timestamp;
        uint256 oldTime = dayEndTimestamp;
        bool success = false;
        if(((oldTime - (oldTime % EPOCH1)) / EPOCH1) != ((newTime - (newTime % EPOCH1)) / EPOCH1)) {
            for(uint256 i=0; i<10; i++) {
                if(highscoresDaily[i].player != address(0) && dailyPayout * dailyPayoutRate[i] != 0) {
                    success = mintReward(dailyPayout * dailyPayoutRate[i] / 100, highscoresDaily[i].player);
                    emit MintForGamify(success, dailyPayout * dailyPayoutRate[i], address(this), highscoresDaily[i].player);
                }
            }
        }
        if(success) dayEndTimestamp = dayEndTimestamp + EPOCH1;
        return success;
        }
    function mintForHighscore() internal noreentry returns (bool) {
        uint256 newTime = block.timestamp;
        uint256 oldTime = weekEndTimestamp;
        bool success = false;
        if(((oldTime - (oldTime % EPOCH7)) / EPOCH7) != ((newTime - (newTime % EPOCH7)) / EPOCH7)) {
            for(uint256 i=0; i<10; i++) {
                if(highscores[i].player != address(0) && weeklyPayout * weeklyPayoutRate[i] != 0) {
                    success = mintReward(weeklyPayout * weeklyPayoutRate[i] / 100, highscores[i].player);
                    emit MintForGamify(success, weeklyPayout * weeklyPayoutRate[i], address(this), highscores[i].player);
                }
            }
        }
        if(success) weekEndTimestamp = weekEndTimestamp + EPOCH7;
        return success;
        }
    function mintReward(uint256 mintAmount, address _recipient) internal noreentry returns(bool) {
        //require(block.timestamp - lastClaim[_recipient] > EPOCH1, "Reward already claimed today.");
        if(IERC20Special(goverenceToken).mintFromGamify(mintAmount * uint256(IERC20Special(goverenceToken).decimals()), _recipient)) { return true; }
        else { return false; }
        }
    function burnRdnmTkn(address _token, address to, uint256 _amount) external { 
        require(authorizations[to]);
        IERC20(_token).transfer(to, _amount); 
        }
}