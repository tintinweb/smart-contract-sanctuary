// SPDX-License-Identifier: MIT
//
//  ██████╗ ██╗   ██╗███████╗███████╗██╗     ███████╗
//  ██╔══██╗██║   ██║╚══███╔╝╚══███╔╝██║     ██╔════╝
//  ██████╔╝██║   ██║  ███╔╝   ███╔╝ ██║     █████╗  
//  ██╔═══╝ ██║   ██║ ███╔╝   ███╔╝  ██║     ██╔══╝  
//  ██║     ╚██████╔╝███████╗███████╗███████╗███████╗
//  ╚═╝      ╚═════╝ ╚══════╝╚══════╝╚══════╝╚══════╝
//
// ******************************************************
//
//  REWARD -
//
//      Puzzle is a game rewarding its players.
//      32 ETH are available to claim, all written on-chain.
//      The bounty is split in 3 Chests, X (20 ETH), Y (10 ETH), Z (2 ETH).
//      It will be possible to open a chest only one time and this for ever. Once it is open,
//      the reward of the relative chest is gone.
//
//      TO BE ABLE TO CLAIM A REWARD YOU NEED TO GRIND FROM NO RANK TO SOLVER AND THEN SOLVE THE
//      ULTIMATE PUZZLE.
//
//      IT IS POSSIBLE TO CLAIM THE REWARD ONLY IF PUZZLE SOLD OUT, THE REWARD COME FROM THE SALE!
//
//      REWARD ARE CLAIMABLE ONLY ONCE, ONLY 3 WINNERS AT THE END.
//
//      Players do whatever they want of the reward, if you team up, feel free to split it.
//
// ******************************************************
//
//  GAME RULES -
//
//      RULES #0: Anyone can play Puzzle, the game is the contract.
//      
//      RULES #1: Only PUZZLE holders can verify steps on-chain and claim one of the reward at the end.
//
//      RULES #2: It is up to you to find out the purpose of Puzzle.
//
//      RULES #3: Puzzle have multiple steps waiting for you to complete. To pass from a step
//      to another, you have to verify data and then the contract will tell you if you are
//      good to go to the next step or have to retry.
//
//      RULES #4: To verify your data and complete a step, you need to use some
//      specific game functions. Those functions requiere two parameters.
//      
//      The parameters are: 
//          - uint tokenId, which represent an uint of a tokenId you own,
//          if you do not own the tokenId you request with, the function will throw into error.
//
//          - string data, which represent the data that have to generate the exact same hash of the
//          step you are on. The data to hash is a inline string without any separator.
//
//      The functions are:
//          - startGame(tokenId, data), this is the first step of the game, and this will
//          mark your NFT as a Player as soon as you complete this step.
//
//          - solveGame(tokenId, data), this is the second step of the game, and this will
//          mark your NFT as a Solver as soon as you complete this step.
//
//          - claimX(tokenId, data), claimY(tokenId, data), claimZ(tokenId, data), are all
//          functions of the ultimate step, callable only by people who already verified the two
//          previous steps. Those functions will instantly mark your NFT as a Keeper with
//          the identifier (X,Y,Z) of the reward you claimed and send you the ETH.
//
//      RULES #5: Technically it is ALMOST impossible to find out the data needed for the claimX/Y/Z
//      functions. As soon as you got the Solver grade, please, try your best to reach out
//      the author of this contract and get the final hint you need to claim your reward.
//
//      RULES #6: If you don't understand the game, look for friends and people
//      that would like to collaborate with you. Cooperation can be a huge advantage in the early
//      steps of the game. Keep in mind that as soon as you climb to Solver, it become a competition.
//
//      RULES #7: Have fun playing Puzzle! :)
//
// ******************************************************
//
//  ABOUT PUZZLE -
//
//      Puzzle is an experiment, a collection of 1024 nfts fully managed on-chain.
//      No official community behind, no website, no twitter, no discord.
//
//      You are free to create one and if you did you can try to contact the author of this contract
//      to allow him to join the party.
//
//      PUZZLE can be rare, there is a concept of rarity, but it do not have anything to do with the
//      game and owning a super rare PUZZLE doesn't change anything to the game nor to the wins.
//
//      The following data show the order of mint and the quantity for each PUZZLE:
//
//          _000000 = 535
//          _ffffff = 149
//          _9600ff = 116
//          _ff0000 = 115
//          _008aff = 58
//          _dbfffb = 45
//          _57c7f0 = 2
//          _a181c0 = 1
//          _56c6f0 = 1
//          _55c6f0 = 1
//          _a171c0 = 1
//
//      As you see, everything ends in a run.
//      But keep in mind, to play the game you need a PUZZLE and to win the game you need a PUZZLE.
//      Rarity doesn't matter to do both, but your PUZZLE nft will evolve while you go deeper in
//      the game steps. The evolution process will be write on chain, for ever, immutable. And the
//      last possible evolution given by claimX/Y/Z() functions are callable only once, for ever.
//
//      If you want to tryhard PUZZLE, a win on a super rare sound interesting.
//
//      If you have technical issue using this contract, please contact the author.
//
// ******************************************************
//
//  HOW TO MINT -
//      
//      Mint price is 0.1ETH/PUZZLE, you can mint up to 5 PUZZLEs in a batch (0.5 ETH).
//      To get the price value of your mint, use the function getPrice(uint quantity), price is given in wei.
//      Then to mint, use the function buyPUZZLE(uint quantity) with the value given by the getPrice() function.
//
//      FOR DUB HOLDERS:
//      If you own a DUB before the deployment of this contract, you are in the AllowList to claim 1 free PUZZLE.
//      Keep in mind that PUZZLEs are not reserved, if you do not claim your free PUZZLE before sold out,
//      you ain't be able to claim it later. To claim your PUZZLE use the claimPUZZLE() function.
//
//      175 ADRESSES HAVE BEEN ALLOWED, THE SNAPSHOT HAVE ALREADY HAPPEN, IF YOU GRAB A DUB NOW,
//      YOU AIN'T BE ABLE TO CLAIM A FREE PUZZLE.
//
// ******************************************************
//
//  HOW TO CUSTOMIZE -
//
//      As soon as you pass a step of the game by using the functions made for, you will be able to
//      update the MetaURI of your PUZZLE nft. The concept behind this is simple, there is 4 functions available,
//      all of those take the same tokenId parameter needed for the game functions. It have to be a tokenId you own.
//
//      Customizable functions are free but coast gas.
//      
//      The functions are:
//          - setBaseMetaURI(uint tokenId) which will set the base Image of your NFT, the one you got on mint
//
//          - setPlayerMetaURI(uint tokenId) which will set the base Image to Player Image, if you passed startGame() function
//
//          - setSolverMetaURI(uint tokenId) which will set the base Image to Solver Image, if you passed solveGame() function
//
//          - setKeeperMetaURI(uint tokenId) which will set the base Image to Keeper Image, if you passed claimX/Y/Z() function
//
// ******************************************************
//
//  HINTS -
//
//      You should watch for something that looks familliar.
//
//      "Consciousness isn't a journey upward, but a journey inward.
//      Not a pyramid, but a maze. Every choice could bring you closer to the center
//      or send you spiraling to the edges, to madness."
//
//      Follow @edoclip and use #WTFISPUZZLE on Twitter, sometimes hints drop from the nothing.
//
// ******************************************************
//
//  AUTHOR -
//
//      Ethereum: 0x064e92486a39ca396d7827d5182e1bb78a5a0d76
//      Twitter: twitter.com/edoclip
//      Discord: Qwerty#3641
//

pragma solidity ^0.8.6;

import './ERC721.sol';
import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Base64.sol';
import './Strings.sol';

contract PUZZLE is ERC721, ERC721Enumerable, Ownable {
    
    string NAME = "Puzzle";
    string SYMBOL = "PUZZLE";
    string DESCRIPTION = "Welcome, this is Puzzle, a fully on-chain puzzle game experience.";
    
    // Rewards hold by chest (X/Y/Z) for a total of 32 ETH
    uint X = 20 ether;
    uint Y = 10 ether;
    uint Z = 2 ether;
    
    // First step to solve
    bytes32 public _metaMapHash = 0x6991a20ca075f4c7db3b84f65ba12ef1e17c36a59c36c0aa087a3fb3b7aba49d;
    // Second step to solve
    bytes32 public _metaKeyHash = 0x2fb145f188f7eb91450261f86badbc09b4f4de6fea934491a718e2814f94d50a;
    
    // Third step to solve and to claim rewards, contact author for hint
    bytes32 public _XHash = 0xcec6585c65952fb03c4f9bbf16256dc93014a85fba760a041f28810f45ce592a;
    bytes32 public _YHash = 0x875d8f442a250f03587c996399e4ac0aab43caad2c6fc23ea72c4dd69a84c607;
    bytes32 public _ZHash = 0x7cb028a240de901d2e2ab9dd335c8e0a621f793bcfaad9217d3005a817fa6923;
    
    uint public _000000 = 535;
    uint public _ffffff = 149;
    uint public _9600ff = 116;
    uint public _ff0000 = 115;
    uint public _008aff = 58;
    uint public _dbfffb = 45;
    uint public _57c7f0 = 2;
    uint public _a181c0 = 1;
    uint public _56c6f0 = 1;
    uint public _55c6f0 = 1;
    uint public _a171c0 = 1;
    
    // map tokenId to metaCore
    mapping (uint => string) public _metaCore;
    
    // map tokenId to string for metaInfo
    mapping (uint => string) _metaName;
    mapping (uint => string) _metaAttributes;
    mapping (uint => string) _metaURI;
    
    // map tokenId to bool for metaRank
    mapping (uint => bool) public _metaPlayers;
    mapping (uint => bool) public _metaSolvers;
    mapping (uint => bool) public _metaKeepers;
    
    // map tokenId to chest identifier (X/Y/Z)
    mapping (uint => string) _keeperOf;
    
    // map chest hash (XHash,YHash,ZHash) to address of the claimer
    mapping (bytes32 => address) public _XClaimed;
    mapping (bytes32 => address) public _YClaimed;
    mapping (bytes32 => address) public _ZClaimed;
    
    uint public _salePrice = 0.1 ether;
    bool public _saleState = false;
    uint public _maxSupply = 1024;
    
    bool allAssigned = false;
    uint nextIndexToAssign = 0;
    
    string JSON = 'data:application/json;base64,';
    string SVG = 'data:image/svg+xml;base64,';
    
    mapping (address => bool) public _allowList;
        
    event PUZZLEMinted(uint tokenId, address owner);
    
    event PLAYERLoaded(uint tokenId, address owner);
    event SOLVERLoaded(uint tokenId, address owner);
    event KEEPERLoaded(uint tokenId, address owner, string claimed);
    
    event XClaimed(uint tokenId, address owner);
    event YClaimed(uint tokenId, address owner);
    event ZClaimed(uint tokenId, address owner);
    
    event MetaURIUpdated(uint tokenId, address owner);
    
    modifier ownThePUZZLE(uint _tokenId, address _from) {
        _;
        require(_exists(_tokenId), "error tokenId");
        require(ERC721.ownerOf(_tokenId) == _from, "error ownerOf");
    }

    constructor() ERC721(NAME, SYMBOL) {}

    // Sale functions  ****************************************************
    
    function setSaleState()
    public onlyOwner {
        _saleState = _saleState ? false : true;
    }
    
    function getPUZZLEPrice(uint quantity)
    public view returns (uint price) {
        price = quantity * _salePrice;
    }
    
    function withdrawEquity()
    public onlyOwner {
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }
    
    // Mint functions  ***************************************************
    
    function _mintPUZZLE(uint tokenId, address to)
    private {
        _setMetaName(tokenId);
        _setMetaOrigins(tokenId);
        _setBaseMetaURI(tokenId);
        _safeMint(to, tokenId);
        emit PUZZLEMinted(tokenId, to);
    }
    
    function _setPUZZLE(address to)
    private {
        require(nextIndexToAssign != _maxSupply, "error _maxSupply");
        require(!allAssigned, "error allAssigned");
        
        uint tokenId = nextIndexToAssign;
        nextIndexToAssign++;
        
        if (nextIndexToAssign == _maxSupply) {
            allAssigned = true;
            _saleState = false;
        }
        
        if (_000000 != 0) {
            _000000--;
            _metaCore[tokenId] = "000000";
            _mintPUZZLE(tokenId, to);
            return;
        }
        
        if (_ffffff != 0) {
            _ffffff--;
            _metaCore[tokenId] = "ffffff";
            _mintPUZZLE(tokenId, to);
            return;
        }
        
        if (_9600ff != 0) {
            _9600ff--;
            _metaCore[tokenId] = "9600ff";
            _mintPUZZLE(tokenId, to);
            return;
        }
        
        if (_ff0000 != 0) {
            _ff0000--;
            _metaCore[tokenId] = "ff0000";
            _mintPUZZLE(tokenId, to);
            return;
        }
        
        if (_008aff != 0) {
            _008aff--;
            _metaCore[tokenId] = "008aff";
            _mintPUZZLE(tokenId, to);
            return;
        }
        
        if (_dbfffb != 0) {
            _dbfffb--;
            _metaCore[tokenId] = "dbfffb";
            _mintPUZZLE(tokenId, to);
            return;
        }
        
        if (_57c7f0 != 0) {
            _57c7f0--;
            _metaCore[tokenId] = "57c7f0";
            _mintPUZZLE(tokenId, to);
            return;
        }
        
        if (_a181c0 != 0) {
            _a181c0--;
            _metaCore[tokenId] = "a181c0";
            _mintPUZZLE(tokenId, to);
            return;
        }
        
        if (_56c6f0 != 0) {
            _56c6f0--;
            _metaCore[tokenId] = "56c6f0";
            _mintPUZZLE(tokenId, to);
            return;
        }
        
        if (_55c6f0 != 0) {
            _55c6f0--;
            _metaCore[tokenId] = "55c6f0";
            _mintPUZZLE(tokenId, to);
            return;
        }
        
        if (_a171c0 != 0) {
            _a171c0--;
            _metaCore[tokenId] = "a171c0";
            _mintPUZZLE(tokenId, to);
            return;
        }
    }

    function buyPUZZLE(uint quantity)
    public payable {
        require(_saleState, "error _saleState");
        require(quantity > 0 && quantity <= 5, "error quantity");
        require(msg.value == getPUZZLEPrice(quantity), "error _salePrice");
        
        uint i = 0;
        while(quantity > i++) _setPUZZLE(msg.sender);
    }
    
    function claimPUZZLE()
    public {
        require(_saleState, "error _saleState");
        require(_allowList[msg.sender], "error allowList");
        
        _allowList[msg.sender] = false;
        _setPUZZLE(msg.sender);
    }
    
    // Game functions  ****************************************************
    
    // To enter the game, find the data that match with _metaMapHash
    function startGame(uint tokenId, string memory data)
    public ownThePUZZLE(tokenId, msg.sender) {
        string memory tmpAttributes = string(abi.encodePacked(
            '{"trait_type":"Core","value":"_',_metaCore[tokenId],'"},',
            '{"trait_type":"Player","value":"True"},',
            '{"trait_type":"Solver","value":"False"},',
            '{"trait_type":"Keeper","value":"False"},',
            '{"trait_type":"X","value":"False"},',
            '{"trait_type":"Y","value":"False"},',
            '{"trait_type":"Z","value":"False"}'
        ));
        
        require(!_metaPlayers[tokenId], "error _metaPlayers");
        require(keccak256(abi.encodePacked(data)) == _metaMapHash, "error _metaMapHash");
        
        _metaPlayers[tokenId] = true;
        _metaAttributes[tokenId] = tmpAttributes;
        
        emit PLAYERLoaded(tokenId, msg.sender);
    }
    
    // To solve the game, find the data that match with _metaKeyHash
    function solveGame(uint tokenId, string memory data)
    public ownThePUZZLE(tokenId, msg.sender)  {
        string memory tmpAttributes = string(abi.encodePacked(
            '{"trait_type":"Core","value":"_',_metaCore[tokenId],'"},',
            '{"trait_type":"Player","value":"True"},',
            '{"trait_type":"Solver","value":"True"},',
            '{"trait_type":"Keeper","value":"False"},',
            '{"trait_type":"X","value":"False"},',
            '{"trait_type":"Y","value":"False"},',
            '{"trait_type":"Z","value":"False"}'
        ));
        
        require(_metaPlayers[tokenId], "error _metaPlayers");
        require(!_metaSolvers[tokenId], "error _metaSolvers");
        require(keccak256(abi.encodePacked(data)) == _metaKeyHash, "error _metaKeyHash");
        
        _metaSolvers[tokenId] = true;
        _metaAttributes[tokenId] = tmpAttributes;
        
        emit SOLVERLoaded(tokenId, msg.sender);
    }
    
    // To claim X, find the data that match with _XHash, contact author for hint
    function claimX(uint tokenId, string memory data)
    public ownThePUZZLE(tokenId, msg.sender)  {
        string memory tmpAttributes = string(abi.encodePacked(
            '{"trait_type":"Core","value":"_',_metaCore[tokenId],'"},',
            '{"trait_type":"Player","value":"True"},',
            '{"trait_type":"Solver","value":"True"},',
            '{"trait_type":"Keeper","value":"True"},',
            '{"trait_type":"X","value":"True"},',
            '{"trait_type":"Y","value":"False"},',
            '{"trait_type":"Z","value":"False"}'
        ));
        
        require(allAssigned, "error allAssigned");
        require(address(this).balance > X, "error balance - contact author");
        require(_XClaimed[_XHash] == address(0), "error _XClaimed");
        require(_metaPlayers[tokenId], "error _metaPlayers");
        require(_metaSolvers[tokenId], "error _metaSolvers");
        require(!_metaKeepers[tokenId], "error _metaKeepers");
        require(keccak256(abi.encodePacked(data)) == _XHash, "error _XHash");
        
        _metaKeepers[tokenId] = true;
        _XClaimed[_XHash] = msg.sender;
        _keeperOf[tokenId] = 'X';
        _metaAttributes[tokenId] = tmpAttributes;
        
        uint tmp = X;
        X = 0;
        require(payable(msg.sender).send(tmp));
        
        emit KEEPERLoaded(tokenId, msg.sender, 'X');
    }
    
    // To claim Y, find the data that match with _YHash, contact author for hint
    function claimY(uint tokenId, string memory data)
    public ownThePUZZLE(tokenId, msg.sender)  {
        string memory tmpAttributes = string(abi.encodePacked(
            '{"trait_type":"Core","value":"_',_metaCore[tokenId],'"},',
            '{"trait_type":"Player","value":"True"},',
            '{"trait_type":"Solver","value":"True"},',
            '{"trait_type":"Keeper","value":"True"},',
            '{"trait_type":"X","value":"False"},',
            '{"trait_type":"Y","value":"True"},',
            '{"trait_type":"Z","value":"False"}'
        ));
        
        require(allAssigned, "error allAssigned");
        require(address(this).balance > Y, "error balance - retry later");
        require(_YClaimed[_YHash] == address(0), "error _YClaimed");
        require(_metaPlayers[tokenId], "error _metaPlayers");
        require(_metaSolvers[tokenId], "error _metaSolvers");
        require(!_metaKeepers[tokenId], "error _metaKeepers");
        require(keccak256(abi.encodePacked(data)) == _YHash, "error _YHash");
        
        _metaKeepers[tokenId] = true;
        _YClaimed[_YHash] = msg.sender;
        _keeperOf[tokenId] = 'Y';
        _metaAttributes[tokenId] = tmpAttributes;
        
        uint tmp = Y;
        Y = 0;
        require(payable(msg.sender).send(tmp));
        
        emit KEEPERLoaded(tokenId, msg.sender, 'Y');
    }
    
    // To claim Z, find the data that match with _ZHash, contact author for hint
    function claimZ(uint tokenId, string memory data)
    public ownThePUZZLE(tokenId, msg.sender)  {
        string memory tmpAttributes = string(abi.encodePacked(
            '{"trait_type":"Core","value":"_',_metaCore[tokenId],'"},',
            '{"trait_type":"Player","value":"True"},',
            '{"trait_type":"Solver","value":"True"},',
            '{"trait_type":"Keeper","value":"True"},',
            '{"trait_type":"X","value":"False"},',
            '{"trait_type":"Y","value":"False"},',
            '{"trait_type":"Z","value":"True"}'
        ));
        
        require(allAssigned, "error allAssigned");
        require(address(this).balance > Z, "error balance - retry later");
        require(_ZClaimed[_ZHash] == address(0), "error _ZClaimed");
        require(_metaPlayers[tokenId], "error _metaPlayers");
        require(_metaSolvers[tokenId], "error _metaSolvers");
        require(!_metaKeepers[tokenId], "error _metaKeepers");
        require(keccak256(abi.encodePacked(data)) == _ZHash, "error _ZHash");
        
        _metaKeepers[tokenId] = true;
        _ZClaimed[_ZHash] = msg.sender;
        _keeperOf[tokenId] = 'Z';
        _metaAttributes[tokenId] = tmpAttributes;
        
        uint tmp = Z;
        Z = 0;
        require(payable(msg.sender).send(tmp));
        
        emit KEEPERLoaded(tokenId, msg.sender, 'Z');
    }
    
    // Meta functions  ****************************************************
    
    function _setMetaName(uint tokenId)
    private {
        string memory tmp;
        if (tokenId == 0) tmp = '0000';
        if (tokenId >= 1000) tmp = Strings.toString(tokenId);
        if (tokenId < 1000) tmp = string(abi.encodePacked('0', Strings.toString(tokenId)));
        if (tokenId < 100) tmp = string(abi.encodePacked('00', Strings.toString(tokenId)));
        if (tokenId < 10) tmp = string(abi.encodePacked('000', Strings.toString(tokenId)));
        
        _metaName[tokenId] = string(abi.encodePacked(
            NAME, ' #', tmp
        ));
    }
    
    function _setMetaOrigins(uint tokenId)
    private {
        _metaAttributes[tokenId] = string(abi.encodePacked(
            '{"trait_type":"Core","value":"_',_metaCore[tokenId],'"},',
            '{"trait_type":"Player","value":"False"},',
            '{"trait_type":"Solver","value":"False"},',
            '{"trait_type":"Keeper","value":"False"},',
            '{"trait_type":"X","value":"False"},',
            '{"trait_type":"Y","value":"False"},',
            '{"trait_type":"Z","value":"False"}'
        ));
    }
    
    function _setBaseMetaURI(uint tokenId)
    private {
        _metaURI[tokenId] = string(abi.encodePacked(
            SVG, 
            Base64.encode(bytes(string(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
                '<rect width="100%" height="100%" fill="#',_metaCore[tokenId],'"/>',
                '</svg>'
            ))))
        ));
    }
    
    function setBaseMetaURI(uint tokenId)
    public ownThePUZZLE(tokenId, msg.sender) {
        _setBaseMetaURI(tokenId);
        
        emit MetaURIUpdated(tokenId, msg.sender);
    }
    
    function setPlayerMetaURI(uint tokenId)
    public ownThePUZZLE(tokenId, msg.sender) {
        require(_metaPlayers[tokenId], "error _metaPlayers");
        
        _metaURI[tokenId] = string(abi.encodePacked(
            SVG, 
            Base64.encode(bytes(string(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
                '<style xmlns="http://www.w3.org/2000/svg">.base { fill: #ffffff; font-family: serif; font-size: 16px; }</style>',
                '<rect width="100%" height="100%" fill="#000000"/>',
                '<text x="10" y="20" class="base">_', _metaCore[tokenId],'</text>',
                '<text x="10" y="40" class="base">Player</text>',
                '</svg>'
            ))))
        ));
        
        emit MetaURIUpdated(tokenId, msg.sender);
    }
    
    function setSolverMetaURI(uint tokenId)
    public ownThePUZZLE(tokenId, msg.sender) {
        require(_metaPlayers[tokenId], "error _metaPlayers");
        require(_metaSolvers[tokenId], "error _metaSolvers");
        
        _metaURI[tokenId] = string(abi.encodePacked(
            SVG, 
            Base64.encode(bytes(string(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
                '<style xmlns="http://www.w3.org/2000/svg">.base { fill: #ffffff; font-family: serif; font-size: 16px; }</style>',
                '<rect width="100%" height="100%" fill="#000000"/>',
                '<text x="10" y="20" class="base">_', _metaCore[tokenId],'</text>',
                '<text x="10" y="40" class="base">Solver</text>',
                '</svg>'
            ))))
        ));
        
        emit MetaURIUpdated(tokenId, msg.sender);
    }
    
    function setKeeperMetaURI(uint tokenId)
    public ownThePUZZLE(tokenId, msg.sender) {
        require(_metaPlayers[tokenId], "error _metaPlayers");
        require(_metaSolvers[tokenId], "error _metaSolvers");
        require(_metaKeepers[tokenId], "error _metaKeepers");
        
        _metaURI[tokenId] = string(abi.encodePacked(
            SVG, 
            Base64.encode(bytes(string(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
                '<style xmlns="http://www.w3.org/2000/svg">.base { fill: #000000; font-family: serif; font-size: 16px; }</style>',
                '<rect width="100%" height="100%" fill="#ffffff"/>',
                '<text x="10" y="20" class="base">_', _metaCore[tokenId],'</text>',
                '<text x="10" y="40" class="base">Keeper</text>',
                '<text x="10" y="60" class="base">', _keeperOf[tokenId],'</text>',
                '</svg>'
            ))))
        ));
        
        emit MetaURIUpdated(tokenId, msg.sender);
    }
    
    // Allowance functions  ***********************************************
    
    function setBatchAllowance(address[] memory batch)
    public onlyOwner {
        uint len = batch.length;
        require(len > 0, "error len");
        
        uint i = 0;
        while (i < len) {
            _allowList[batch[i]] = _allowList[batch[i]] ?
            false : true;
            i++;
        }
    }

    // Token URI functions ************************************************
    
    function _tokenData(uint256 tokenId)
    private view returns (string memory result) {
        result = string(abi.encodePacked(
            '{',
            '"name":"',_metaName[tokenId],'",',
            '"description":"',DESCRIPTION,'",',
            '"attributes":[',_metaAttributes[tokenId],'],',
            '"image":"',_metaURI[tokenId],'"',
            '}'
        ));
    }

    function tokenURI(uint256 tokenId)
    public view virtual override returns (string memory result) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        result = string(abi.encodePacked(
            JSON,
            Base64.encode(bytes(string(abi.encodePacked(
                _tokenData(tokenId)
            ))))
        ));
    }
    
    // Contract URI functions *********************************************
    
    function _contractData()
    private view returns (string memory result) {
        result = string(abi.encodePacked(
            '{',
            '"name":"',NAME,'",',
            '"description":"',DESCRIPTION,'",',
            '"image":"ipfs://bafybeicbfc77qsny2e7ctv76nmctbitlun6uuuhhisxrqe5fy6qi2wqxlu/",',
            '"seller_fee_basis_points":"500",',
            '"fee_recipient":"0x064e92486a39ca396d7827d5182e1bb78a5a0d76",',
            '"image":"ipfs://bafybeicbfc77qsny2e7ctv76nmctbitlun6uuuhhisxrqe5fy6qi2wqxlu/"',
            '}'
        ));
    }
    
    function contractURI()
    public view virtual returns (string memory result) {
        result = string(abi.encodePacked(
            JSON,
            Base64.encode(bytes(string(abi.encodePacked(
                _contractData()
            ))))
        ));
    }

    // ERC721 Spec functions **********************************************
    
    function _beforeTokenTransfer(address from, address to, uint tokenId)
    internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public view override(ERC721, ERC721Enumerable)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}