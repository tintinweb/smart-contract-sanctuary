/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor ()  {

        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
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

    constructor ()  {
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

contract P2PBetting is Ownable, ERC165 {
    
    uint256 public playerID;
    uint256 public pairCount;
    
    uint256 public fee;
    address payable public wallet;
    address public signer;
    
    struct PlayerDetails{
        address playerAddress;
        uint256 playerID;
        string playingSide;
        address[] NFTaddress;
        uint256[] NFT_IDs;
        uint256[] NFTType;
        uint256 registerTime;
        bool winning;
    }
    
    struct UserIDs{
        uint256[] playerIDs;
        uint256[] pairIDs;
    }
    
    struct PlayingPair {
        uint256 creatorID;
        uint256 joinerID;
        uint256 winnerID;
        address winnerAddress;
        bool pass;
    }
    
    mapping ( address => bool ) public isAuthToken;
    mapping ( uint256 => PlayerDetails ) public _playerDetails;
    mapping ( address => UserIDs ) private _userID;
    mapping ( uint256 => PlayingPair ) public playingPairDetails;
    mapping (bytes32 => bool) public hashVerify;
    
    event UpdateFeeAmount(address owner, uint256 FeeAmount);
    event UpdateWallet(address owner, address WalletAddress);
    event UpdateSignerAddress(address owner, address signer);
    event CreatePairSlot(address player, uint256 playerID, uint256 pairID);
    event JoinPairSlot(address player, uint256 playerID, uint256 pairID);
    event Winner(address owner, address winnerAddress, uint256 pairID, uint256 winnerID);
    event ClaimEth(address owner, uint256 ETHamount);
    event ApprovedToken(address owner, address TokenAddress, bool status);
    event EmergencySafeNFT(address owner, address receiver, address tokenAddress, uint256 tokenID);
    event claimNFTs(address player, uint256 playerID, uint256 pairID, address NFTaddress, uint256 NFTIDs, uint256 claimTime);
    
    constructor(address payable _wallet, uint256 _playerFee) {
        wallet = _wallet;
        fee = _playerFee;
    }
    
    receive() external payable {}
    
    modifier authTokens(address[] memory _NFTaddress){
        for(uint256 i = 0; i < _NFTaddress.length; i++){
            require(isAuthToken[_NFTaddress[i]]," UnAuthorized Token");
        }
        _;
    }
    
    function setApproveToken(address _tokenAddress, bool status) external onlyOwner {
        isAuthToken[_tokenAddress] = status;
        emit ApprovedToken(msg.sender, _tokenAddress, status);
    }
    
    function updateSigner(address _signer) external onlyOwner {
        signer = _signer;
        emit UpdateSignerAddress(msg.sender, _signer);
    }
    
    function updateWalletAddress(address payable _newWalletAddress) external onlyOwner{
        wallet = _newWalletAddress;
        emit UpdateWallet(msg.sender, _newWalletAddress);
    }
    
    function updateFee(uint256 _feeAmount) external onlyOwner {
        fee = _feeAmount;
        emit UpdateFeeAmount(msg.sender, _feeAmount);
    }
    
    function creatSlot(address[] memory _NFTaddress, uint256[] memory _NFTids, uint256[] memory _type) external payable authTokens(_NFTaddress) {
        playerID++;
        pairCount++;
        require(_NFTaddress.length == _NFTids.length,"Incorrect parameters");
        require(msg.value > fee, "Bad fee amount" );
        PlayerDetails storage player = _playerDetails[playerID];
        PlayingPair storage pair = playingPairDetails[pairCount];
        player.playerAddress = msg.sender;
        player.playerID = playerID;
        player.playingSide = "Creator";
        player.NFTaddress = _NFTaddress;
        player.NFT_IDs = _NFTids;
        player.NFTType = _type;
        player.registerTime = block.timestamp;
        
        pair.creatorID = playerID;
        _userID[msg.sender].playerIDs.push(playerID);
        _userID[msg.sender].pairIDs.push(pairCount);
        
        for(uint256 i = 0; i < _NFTaddress.length ; i++){
            if(_type[i] == 1){
                IERC721(_NFTaddress[i]).safeTransferFrom( msg.sender ,address(this), _NFTids[i]);
            }else if(_type[i] == 2) {
                IERC1155(_NFTaddress[i]).safeTransferFrom( msg.sender ,address(this), _NFTids[i], 1, "0x");
            } else {
                revert("invalid type value");
            }
        }
        require(wallet.send(msg.value),"Fee transaction failed");
        emit CreatePairSlot(msg.sender, playerID, pairCount);
    }
    
    function joinSlot(uint256 _pairID, uint256 creatorID, address[] memory _NFTaddress, uint256[] memory _NFTids, uint256[] memory _type ) external payable authTokens(_NFTaddress) {
        playerID++;
        require(_NFTaddress.length == _NFTids.length,"Incorrect parameters");
        require(_playerDetails[creatorID].NFTaddress.length == _NFTaddress.length , "No. of NFTs not match to creator" );
        require(msg.value > fee, "Bad fee amount" );
        PlayerDetails storage player = _playerDetails[playerID];
        PlayingPair storage pair = playingPairDetails[_pairID];
        require(pair.creatorID == creatorID ,"pair and creatorID mismatched");
        require(pair.joinerID == 0,"joinSlot :: already pair executed");
        player.playerAddress = msg.sender;
        player.playerID = playerID;
        player.playingSide = "Joiner";
        player.NFTaddress = _NFTaddress;
        player.NFT_IDs = _NFTids;
        player.NFTType = _type;
        player.registerTime = block.timestamp;
        
        pair.joinerID = playerID;
        _userID[msg.sender].playerIDs.push(playerID);
        _userID[msg.sender].pairIDs.push(_pairID);

        for(uint256 i = 0; i < _NFTaddress.length ; i++){
            if(_type[i] == 1){
                IERC721(_NFTaddress[i]).safeTransferFrom( msg.sender, address(this), _NFTids[i]);
            }else if(_type[i] == 2) {
                IERC1155(_NFTaddress[i]).safeTransferFrom( msg.sender, address(this) , _NFTids[i], 1, "0x");
            }
            else {
                revert("invalid type value");
            }
        }
        
        require(wallet.send(msg.value),"Fee transaction failed");
        emit JoinPairSlot(msg.sender, playerID, _pairID);
    }
    
    function winners(uint256 _pairID, uint256 _winnerID) external onlyOwner {
        PlayingPair storage pair = playingPairDetails[_pairID];
        require(!pair.pass,"pair already announced");
        pair.winnerID = _winnerID;
        pair.winnerAddress = _playerDetails[_winnerID].playerAddress;
        pair.pass = true;
        
        emit Winner(msg.sender, pair.winnerAddress, _pairID, _winnerID);
    }
    
    function claimTokens(uint256 _playerID, uint256 _pairID, uint256 blockTime,  uint8 v, bytes32 r, bytes32 s) external {
        PlayingPair storage pair = playingPairDetails[_pairID];
        PlayerDetails storage player1 = _playerDetails[_playerID];
        PlayerDetails storage player2 = _playerDetails[pair.creatorID];
        
        require(pair.pass,"Winner not announced");
        require(pair.creatorID == _playerID || pair.joinerID == _playerID,"pair and playerID mismatched");
        require(blockTime >= block.timestamp,"signature expiry");
        bytes32 msgHash = toSigEthMsg(msg.sender, _playerID, _pairID, blockTime);
        require(!hashVerify[msgHash],"Claim :: signature already used");
        require(verifySignature(msgHash, v,r,s) == signer,"Claim :: not a signer address");
        hashVerify[msgHash] = true;
        
        if(pair.winnerID == 0){
            
            for(uint256 i = 0; i < player1.NFTaddress.length ; i++){
                if(player1.NFTType[i] == 1){
                    IERC721(player1.NFTaddress[i]).safeTransferFrom(address(this), msg.sender,player1.NFT_IDs[i]);
                }else if(player1.NFTType[i] == 2) {
                    IERC1155(player1.NFTaddress[i]).safeTransferFrom(address(this), msg.sender, player1.NFT_IDs[i], 1, "0x");
                }
                emit claimNFTs(msg.sender, _playerID, _pairID, player1.NFTaddress[i], player1.NFT_IDs[i], block.timestamp );
            }
        } else if(pair.winnerID > 0) {
            
            for(uint256 i = 0; i < player1.NFTaddress.length ; i++){
                if(player1.NFTType[i] == 1){
                    IERC721(player1.NFTaddress[i]).safeTransferFrom(address(this), msg.sender,player1.NFT_IDs[i]);
                }else if(player1.NFTType[i] == 2) {
                    IERC1155(player1.NFTaddress[i]).safeTransferFrom(address(this), msg.sender, player1.NFT_IDs[i], 1, "0x");
                }
                emit claimNFTs(msg.sender, _playerID, _pairID, player1.NFTaddress[i], player1.NFT_IDs[i], block.timestamp );
            }
            
            for(uint256 i = 0; i < player2.NFTaddress.length ; i++){
                if(player2.NFTType[i] == 1){
                    IERC721(player2.NFTaddress[i]).safeTransferFrom(address(this), msg.sender,player2.NFT_IDs[i]);
                }else if(player2.NFTType[i] == 2) {
                    IERC1155(player2.NFTaddress[i]).safeTransferFrom(address(this), msg.sender, player2.NFT_IDs[i], 1, "0x");
                }
                emit claimNFTs(msg.sender, _playerID, _pairID, player2.NFTaddress[i], player2.NFT_IDs[i], block.timestamp );
            } 
        }
    }
    
    function verifySignature(bytes32 msgHash, uint8 v,bytes32 r, bytes32 s)public pure returns(address signerAdd){
        signerAdd = ecrecover(msgHash, v, r, s);
    }
    
    function toSigEthMsg(address _user, uint256 _playerID, uint256 _pairID, uint256 _blockTime)internal view returns(bytes32){
        bytes32 hash = keccak256(abi.encodePacked(abi.encodePacked(_user, _playerID, _pairID, _blockTime),address(this)));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function emergencySafe(address _tokenAddress,address _to, uint256 _tokenId, uint256 _type) external onlyOwner {
        if(_type == 1){
            IERC721(_tokenAddress).safeTransferFrom(address(this), _to,_tokenId);
        }else if(_type == 2) {
            IERC1155(_tokenAddress).safeTransferFrom(address(this), _to, _tokenId, 1, "0x");
        }
        else{
            revert("Invalid type value");
        }
        emit EmergencySafeNFT(msg.sender, _to, _tokenAddress, _tokenId);
    }
    
    function emergency(address _tokenAddress,address _to, uint256 _tokenAmount) external onlyOwner {
        if(_tokenAddress == address(0x0)){
            require(payable(_to).send(_tokenAmount),"emergency :: transaction failed");
        }else{
            IERC20(_tokenAddress).transfer(_to, _tokenAmount);
        }
    }
    
}