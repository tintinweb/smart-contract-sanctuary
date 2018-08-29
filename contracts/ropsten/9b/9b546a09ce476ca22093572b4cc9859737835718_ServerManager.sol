pragma solidity ^0.4.13;

contract ERC721 {
    function isERC721() public pure returns (bool _b);
    function implementsERC721() public pure returns (bool _b);
    function name() public pure returns (string _name);
    function symbol() public pure returns (string _symbol);
    function totalSupply() public view returns (uint256 _totalSupply);
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function approve(address _to, uint256 _tokenId) public;
    function takeOwnership(uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint tokenId);
    function tokenMetadata(uint256 _tokenId) public constant returns (string infoUrl);

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

contract CharacterRegistry is ERC721 {

    ///////////////////////////////////////////////////////////////
    /// Modifiers

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    ///////////////////////////////////////////////////////////////
    /// Structures

    struct Character {
        string nickname;
        address owner;
        uint nuja;
        uint indexUser;
    }

    struct SellOrder {
        address seller;
        uint token;
        uint price;
    }

    ///////////////////////////////////////////////////////////////
    /// Constants

    string constant NAME = "NujaToken";
    string constant SYMBOL = "NJT";

    ///////////////////////////////////////////////////////////////
    /// Attributes

    address nujaRegistry;
    address owner;
    uint characterNumber;
    Character[] characterArray;
    mapping (address => uint256) characterCount;
    mapping (uint256 => address) approveMap;
    SellOrder[] sellOrderList;

    // Index of the card for the user
    mapping (address => mapping (uint => uint)) indexCharacter;

    mapping (address => bool) starterClaimed;

    ///////////////////////////////////////////////////////////////
    /// Constructor

    function CharacterRegistry() public {
        nujaRegistry = 0x796826c8adEB80A5091CEe9199D551ccB0bd3f18;
        owner = msg.sender;
        characterNumber = 0;
    }

    ///////////////////////////////////////////////////////////////
    /// Admin functions

    function addCharacter(string nickname, address characterOwner, uint nuja) public onlyOwner {
        NujaRegistry reg = NujaRegistry(nujaRegistry);
        require(nuja < reg.getNujaNumber());

        Character memory c = Character(nickname, characterOwner, nuja, characterCount[characterOwner]);
        characterArray.push(c);

        indexCharacter[characterOwner][characterCount[characterOwner]] = characterNumber;
        characterCount[characterOwner] += 1;
        characterNumber += 1;
    }


    function claimStarter(string nickname, uint nuja) public {
        require(starterClaimed[msg.sender] == false);
        require(nuja < 3);

        Character memory c = Character(nickname, msg.sender, nuja, characterCount[msg.sender]);
        characterArray.push(c);

        indexCharacter[msg.sender][characterCount[msg.sender]] = characterNumber;
        characterCount[msg.sender] += 1;
        characterNumber += 1;

        starterClaimed[msg.sender] = true;
    }

    function isStarterClaimed(address user) public view returns(bool starterClaimedRet) {
        return starterClaimed[user];
    }

    ///////////////////////////////////////////////////////////////
    /// Implementation ERC721

    function isERC721() public pure returns (bool b) {
        return true;
    }

    function implementsERC721() public pure returns (bool b) {
        return true;
    }

    function name() public pure returns (string _name) {
        return NAME;
    }

    function symbol() public pure returns (string _symbol) {
        return SYMBOL;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return characterNumber;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return characterCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        require(_tokenId < characterNumber);
        Character memory c = characterArray[_tokenId];
        return c.owner;
    }

    function approve(address _to, uint256 _tokenId) public {
        require(msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);

        approveMap[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_tokenId < characterNumber);
        require(_from == ownerOf(_tokenId));
        require(_from != _to);
        require(approveMap[_tokenId] == _to);

        characterCount[_from] -= 1;

        // Change the indexCharacter of _from
        indexCharacter[_from][characterArray[_tokenId].indexUser] = indexCharacter[_from][characterCount[_from]];
        characterArray[indexCharacter[_from][characterCount[_from]]].indexUser = characterArray[_tokenId].indexUser;

        // This card is the last one for the new owner
        characterArray[_tokenId].indexUser = characterCount[_to];
        indexCharacter[_to][characterCount[_to]] = _tokenId;

        characterArray[_tokenId].owner = _to;
        characterCount[_to] += 1;
        Transfer(_from, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) public {
        require(_tokenId < characterNumber);
        address oldOwner = ownerOf(_tokenId);
        address newOwner = msg.sender;
        require(newOwner != oldOwner);
        require(approveMap[_tokenId] == msg.sender);

        characterCount[oldOwner] -= 1;

        // Change the indexCharacter of _from
        indexCharacter[oldOwner][characterArray[_tokenId].indexUser] = indexCharacter[oldOwner][characterCount[oldOwner]];
        characterArray[indexCharacter[oldOwner][characterCount[oldOwner]]].indexUser = characterArray[_tokenId].indexUser;

        // This card is the last one for the new owner
        characterArray[_tokenId].indexUser = characterCount[newOwner];
        indexCharacter[newOwner][characterCount[newOwner]] = _tokenId;

        characterArray[_tokenId].owner = newOwner;
        characterCount[newOwner] += 1;
        Transfer(oldOwner, newOwner, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public {
        require(_tokenId < characterNumber);
        address oldOwner = msg.sender;
        address newOwner = _to;
        require(oldOwner == ownerOf(_tokenId));
        require(oldOwner != newOwner);
        require(newOwner != address(0));

        characterCount[oldOwner] -= 1;

        // Change the indexCharacter of _from
        indexCharacter[oldOwner][characterArray[_tokenId].indexUser] = indexCharacter[oldOwner][characterCount[oldOwner]];
        characterArray[indexCharacter[oldOwner][characterCount[oldOwner]]].indexUser = characterArray[_tokenId].indexUser;

        // This card is the last one for the new owner
        characterArray[_tokenId].indexUser = characterCount[newOwner];
        indexCharacter[newOwner][characterCount[newOwner]] = _tokenId;

        characterArray[_tokenId].owner = newOwner;
        characterCount[newOwner] += 1;
        Transfer(oldOwner, newOwner, _tokenId);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint tokenId) {
        require(_index < characterCount[_owner]);

        return indexCharacter[_owner][_index];
    }


    // For this case the only metadata is the name of the human
    // TODO: implement this function with 2 byte32 arrays
    function tokenMetadata(uint256 _tokenId) public constant returns (string infoUrl) {
        require(_tokenId < characterNumber);
        return "nothing";//TODO
    }


    // Sale functions
    function createSellOrder(uint256 _tokenId, uint price) public {
        require(_tokenId < characterNumber);
        require(msg.sender == ownerOf(_tokenId));

        SellOrder memory newOrder = SellOrder(msg.sender, _tokenId, price);
        sellOrderList.push(newOrder);

        characterArray[_tokenId].owner = address(0);
        characterCount[msg.sender] -= 1;

        // Change the indexCharacter of sender
        indexCharacter[msg.sender][characterArray[_tokenId].indexUser] = indexCharacter[msg.sender][characterCount[msg.sender]];
        characterArray[indexCharacter[msg.sender][characterCount[msg.sender]]].indexUser = characterArray[_tokenId].indexUser;
    }

    function processSellOrder(uint id, uint256 _tokenId) payable public {
        require(id < sellOrderList.length);

        SellOrder memory order = sellOrderList[id];
        require(order.token == _tokenId);
        require(msg.value == order.price);
        require(msg.sender != order.seller);

        // Sending fund to the seller
        if(!order.seller.send(msg.value)) {
           revert();
        }

        // Adding token to the buyer
        characterArray[_tokenId].owner = msg.sender;

        // This token is the last one for the new owner
        characterArray[_tokenId].indexUser = characterCount[msg.sender];
        indexCharacter[msg.sender][characterCount[msg.sender]] = _tokenId;

        characterCount[msg.sender] += 1;

        // Update list
        sellOrderList[id] = sellOrderList[sellOrderList.length-1];
        delete sellOrderList[sellOrderList.length-1];
        sellOrderList.length--;
    }

    function cancelSellOrder(uint id, uint256 _tokenId) public {
        require(id < sellOrderList.length);

        SellOrder memory order = sellOrderList[id];
        require(order.seller == msg.sender);
        require(order.token == _tokenId);

        // Give back token to seller
        characterArray[_tokenId].owner = msg.sender;

        // This card is the last one for the new owner
        characterArray[_tokenId].indexUser = characterCount[msg.sender];
        indexCharacter[msg.sender][characterCount[msg.sender]] = _tokenId;

        characterCount[msg.sender] += 1;

        // Update list
        sellOrderList[id] = sellOrderList[sellOrderList.length-1];
        delete sellOrderList[sellOrderList.length-1];
        sellOrderList.length--;
    }

    function getSellOrder(uint id) public view returns(address sellerRet, uint tokenRet, uint priceRet) {
        require(id < sellOrderList.length);

        SellOrder memory ret = sellOrderList[id];
        return(ret.seller, ret.token, ret.price);
    }

    function getNbSellOrder() public view returns(uint nb) {
        return sellOrderList.length;
    }

    function getCharacterInfo(uint _tokenId) public view returns(string nicknameRet, address ownerRet) {
        require(_tokenId < characterNumber);

        Character memory ret = characterArray[_tokenId];
        return(ret.nickname, ret.owner);
    }

    function getCharacterNuja(uint _tokenId) public view returns(uint nujaRet) {
        require(_tokenId < characterNumber);

        Character memory ret = characterArray[_tokenId];
        return(ret.nuja);
    }

    // Get functions
    function getOwner() public view returns(address ret) {
        return owner;
    }
    function getNujaRegistry() public view returns(address ret) {
        return nujaRegistry;
    }
}

contract Geometry {
    function max(uint8 a, uint8 b) internal pure returns (uint8) {
        return a > b ? a : b;
    }
    function abs(int8 a) internal pure returns (uint8) {
        return a < 0 ? (uint8)(-a) : (uint8)(a);
    }
    function distance(uint8 x1, uint8 y1, uint8 x2, uint8 y2) internal pure returns (uint8) {
        return max(abs((int8)(x1-x2)), abs((int8)(y1-y2)));
    }
}

contract NujaRegistry {

    ///////////////////////////////////////////////////////////////
    /// Modifiers

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    ///////////////////////////////////////////////////////////////
    /// Attributes
    address owner;
    uint nujaNumber;
    address[] nujaArray;

    ///////////////////////////////////////////////////////////////
    /// Constructor

    function NujaRegistry() public {
        owner = msg.sender;
        nujaNumber = 0;
    }

    ///////////////////////////////////////////////////////////////
    /// Admin functions

    function addNuja(address nujaContract) public onlyOwner {
        nujaArray.push(nujaContract);
        nujaNumber += 1;
    }

    function getContract(uint256 index) public constant returns (address contractRet) {
        require(index < nujaNumber);

        return nujaArray[index];
    }

    // Get functions
    function getOwner() public view returns(address ret) {
        return owner;
    }

    function getNujaNumber() public view returns(uint ret) {
        return nujaNumber;
    }
}

contract StateManager {

    function moveOwner(
      uint[3] metadata,
      uint[4] move,
      uint8[176] moveOutput,
      bytes32 r,
      bytes32 s,
      uint8 v
      ) public pure returns (address recovered) {

        // Convert to uint for keccak256 function
        uint[176] memory moveOutputUint;
        for(uint8 i=0; i<176; i++) {
          moveOutputUint[i] = uint(moveOutput[i]);
        }

        // Calculate the hash of the move
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 msg = keccak256(prefix, keccak256(metadata, move, moveOutputUint));

        return ecrecover(msg, v, r, s);
    }


    // Building function
    function getBuilding(uint8[176] state, uint8 x, uint8 y) internal pure returns (uint8 ret) {
        return state[x*8+y];
    }
    function setBuilding(uint8[176] state, uint8 x, uint8 y, uint8 code) internal pure returns (uint8[176] ret) {
        state[x*8+y] = code;
        return state;
    }

    // Position function
    function getPlayer(uint8[176] state, uint8 x, uint8 y) internal pure returns (uint8 ret) {
        return state[64+x*8+y];
    }
    function getPosition(uint8[176] state, uint p) internal pure returns (uint8 xret, uint8 yret) {
        return (state[136+p], state[144+p]);
    }

    function movePlayer(uint8[176] state, uint8 p, uint8 x, uint8 y) internal pure returns (uint8[176] ret) {
      uint8 oldX = state[136+p];
      uint8 oldY = state[144+p];

      // Put player in the new position
      require(state[64+x*8+y] == 0);
      state[64+x*8+y] = p + 1;
      state[136+p] = x;
      state[144+p] = y;

      // Remove player from old position
      state[64+oldX*8+oldY] = 0;
      return state;
    }

    // Health function
    function getHealth(uint8[176] state, uint8 p) public pure returns (uint8 ret) {
        return state[128+p];
    }
    function damage(uint8[176] state, uint8 p, uint8 nb) internal pure returns(uint8[176] ret) {
        require(nb <= 100);
        uint8 remaining = state[128+p];

        if(remaining <= nb) {
            state = kill(state, p);
        }
        else {
            state[128+p] = remaining - nb;
        }

        return state;
    }
    function restore(uint8[176] state, uint8 p, uint8 nb) internal pure returns(uint8[176] ret) {
        require(nb <= 100);
        uint8 remaining = state[128+p];

        if(remaining + nb > 100) {
            state[128+p] = 100;
        }
        else {
            state[128+p] = remaining + nb;
        }

        return state;
    }
    function isAlive(uint8[176] state, uint8 p) internal pure returns (bool ret) {
        return state[128+p] > 0;
    }

    // Not internal because necessary for timeoutManager
    function kill(uint8[176] state, uint8 p) public pure returns (uint8[176] ret) {
        state[128+p] = 0;

        // Set the position of the player to 0
        uint8 x = uint8(state[136+p]);
        uint8 y = uint8(state[144+p]);

        state[64+x*8+y] = 0;

        return state;
    }


    // Weapon function

    function getWeaponNb(uint8[176] state, uint8 p) internal pure returns (uint8 ret) {
        if(state[152+p] == 0) {
            return 0;
        }
        else if(state[160+p] == 0) {
            return 1;
        }
        else if(state[168+p] == 0) {
            return 2;
        }
        else {
            return 3;
        }
    }
    function getWeapon(uint8[176] state, uint8 p, uint8 index) internal pure returns (uint8 ret) {
        require(index < 3);
        require(state[152+p+index*8] > 0);
        return state[152+p+index*8] - 1;
    }
    function addWeapon(uint8[176] state, uint8 p, uint8 w) internal pure returns (uint8[176] ret) {
        if(state[152+p] == 0) {
            state[152+p] = w+1;
        }
        else if(state[160+p] == 0) {
            state[160+p] = w+1;
        }
        else if(state[168+p] == 0) {
            state[168+p] = w+1;
        }
        else {
            revert();
        }
        return state;
    }
    function removeWeapon(uint8[176] state, uint8 p, uint8 index) internal pure returns (uint8[176] ret) {
        require(index < 3);
        state[152+p+index*8] = 0;

        // Other weapon reindexation
        for(uint8 i=index+1; i<3; i++) {
            state[152+p+(i-1)*8] = state[152+p+i*8];
            state[152+p+i*8] = 0;
        }

        return state;
    }
}

contract Nuja is Geometry, StateManager {
    function getMetadata() public constant returns (string metadata);

    // Function called by server to use the Weapon
    function power(uint8 x, uint8 y, uint8 player, uint8[176] moveInput) public view returns(uint8[176] moveOutput);
}

contract NujaBattle is Geometry, StateManager {

    // General values
    address characterRegistry;
    address weaponRegistry;
    address timeoutStopper;
    address serverManager;

    ///////////////////////////////////////////////////////////////
    /// Modifiers

    modifier fromTimeoutStopper {
        require(msg.sender == timeoutStopper);
        _;
    }

    // Give for a given match the turn that have been timed out
    mapping (uint => mapping (uint => mapping (uint => bool))) matchTimeoutTurns;
    mapping (uint => mapping (uint8 => bool)) deadPlayer;


    ///////////////////////////////////////////////////////////////

    function NujaBattle() public {
        characterRegistry = 0x462893f08BbaED3319a44E613E57e5257b0E5037;
        weaponRegistry = 0xDF480F0D91C0867A0de18DA793486287A22c2243;
        serverManager = 0x9B546a09ce476Ca22093572B4cC9859737835718;
        timeoutStopper = 0x5ad3268897d14974b2806196CcDb7ca947c9AAD2;
    }


    //////////////////////////////////////////////////////////////////
    // Turn simulation

    // idMove:
    // 0: Simple move
    // 1: Simple attack
    // 2: Explore building
    // 3: Weapon
    // 4: Nuja power
    // 5: Idle
    function simulate(uint indexServer, uint8 p, uint8 idMove, uint8 xMove, uint8 yMove, uint8 indexWeapon, uint8[176] moveInput) public view returns (uint8[176] moveOutput) {
        require(idMove < 6);
        require(xMove < 8 && yMove < 8);
        require(p < ServerManager(serverManager).getPlayerMax(indexServer));
        require(isAlive(moveInput, p));

        uint8 xInitial;
        uint8 yInitial;
        (xInitial, yInitial) = getPosition(moveInput, p);

        if (idMove == 0) {
            // Move
            require(distance(xMove, yMove, xInitial, yInitial) == 1);
            return movePlayer(moveInput, p, xMove, yMove);
        }
        else if (idMove == 1) {
            // Simple attack
            require(distance(xMove, yMove, xInitial, yInitial) == 1);
            uint8 opponent = getPlayer(moveInput, xMove, yMove);
            require(opponent > 0);
            opponent -= 1;
            return damage(moveInput, opponent, 30);
        }
        else if (idMove == 2) {
            return exploreBuilding(p, moveInput);
        }
        else if (idMove == 3) {
            return useWeapon(p, xMove, yMove, indexWeapon, moveInput);
        }
        else if (idMove == 4) {
            return usePower(indexServer, p, xMove, yMove, moveInput);
        }
        else {
            return moveInput;
        }
    }

    function exploreBuilding(uint8 p, uint8[176] moveInput) internal pure returns (uint8[176] moveOutput) {
        uint8 xInitial;
        uint8 yInitial;
        (xInitial, yInitial) = getPosition(moveInput, p);
        uint8 buildingCode = getBuilding(moveInput, xInitial, yInitial);

        // Add the weapon
        require(buildingCode > 1);
        moveOutput = addWeapon(moveInput, p, buildingCode-2);

        // Set building as explored
        return setBuilding(moveOutput, xInitial, yInitial, 1);
    }

    function useWeapon(uint8 p, uint8 x, uint8 y, uint8 index, uint8[176] moveInput) internal view returns (uint8[176] moveOutput) {
        uint8 weaponId = getWeapon(moveInput, p, index);

        // Get weapon contract
        WeaponRegistry weaponReg = WeaponRegistry(weaponRegistry);
        address weaponAddress = weaponReg.getContract(weaponId);

        // Call the weapon function
        Weapon w = Weapon(weaponAddress);
        moveOutput = w.use(x, y, p, moveInput);

        // Remove weapon after use
        return removeWeapon(moveOutput, p, index);
    }

    function usePower(uint indexServer, uint8 p, uint8 x, uint8 y, uint8[176] moveInput) internal view returns (uint8[176] moveOutput) {
        CharacterRegistry characterContract = CharacterRegistry(characterRegistry);
        uint characterIndex = ServerManager(serverManager).playerCharacter(indexServer, p);
        var r_nuja = characterContract.getCharacterNuja(characterIndex);

        // Get nuja contract
        address nujaRegistryAddress = characterContract.getNujaRegistry();
        NujaRegistry nujaContract = NujaRegistry(nujaRegistryAddress);
        address nujaAddress = nujaContract.getContract(r_nuja);

        // Call the power function
        Nuja player_nuja = Nuja(nujaAddress);
        return player_nuja.power(x, y, p, moveInput);
    }


    //////////////////////////////////////////////////////////////////
    // Match functions

    // Get the next turn metadata from old metadata and move&#39;s output
    function nextTurn(
      uint indexServer,
      uint[3] metadata,
      uint8[176] moveOutput
      ) public view returns (uint[3] metadataRet) {

        metadataRet[0] = metadata[0];
        metadataRet[1] = metadata[1];
        metadataRet[2] = metadata[2];

        uint8 playerMax = ServerManager(serverManager).getPlayerMax(indexServer);

        // We skip dead player
        do {
            metadataRet[2]++;
            if(metadataRet[2] >= playerMax) {
                metadataRet[2] = 0;
                metadataRet[1]++;
            }
        } while (getHealth(moveOutput, uint8(metadataRet[2])) == 0);

        return metadataRet;
    }

    // Verify if the given next metadata match the actual next metadata
    function verifyNextTurn(uint indexServer, uint[3] metadata, uint[3] metadataNext, uint8[176] moveOutput) internal view {
        uint[3] memory newMetadata = nextTurn(indexServer, metadata, moveOutput);
        require(newMetadata[0] == metadataNext[0]);
        require(newMetadata[1] == metadataNext[1]);
        require(newMetadata[2] == metadataNext[2]);
    }

    // Check depending on first and last metadata that every alive player has signed their turn
    function verifyAllSigned(uint indexServer, uint[3] metadataFirst, uint[3] metadataLast, uint8[176] moveOutput) internal view {
        uint[3] memory newMetadata = nextTurn(indexServer, metadataLast, moveOutput);
        require(newMetadata[0] == metadataFirst[0]);
        require((newMetadata[1] == (metadataFirst[1]+1) && newMetadata[2] >= metadataFirst[2]) || (newMetadata[1] > metadataFirst[1]+1));
    }

    // Check if player is killed
    function isKilled(uint indexServer, uint8 p) public view returns (bool isRet) {
        uint currentMatch = ServerManager(serverManager).getServerCurrentMatch(indexServer);
        return deadPlayer[currentMatch][p];
    }

    // Get array of killed player
    // Useful for iterative function in backend code
    function getKilledArray(uint indexServer) public view returns (bool[8] killedRet) {

        uint currentMatch = ServerManager(serverManager).getServerCurrentMatch(indexServer);

        for(uint8 i=0; i<8; i++) {
            if(deadPlayer[currentMatch][i]) {
                killedRet[i] = true;
            }
            else {
                killedRet[i] = false;
            }
        }

        return killedRet;
    }


    // Tell to the contract that a player has been killed
    // Only if this function is call, the player will be actually removed from server
    function killPlayer(
      uint indexServer,
      uint8[2] killerAndKilled, // First element represents killer and second the killed: we use this trik to avoid stack too deep error
      uint[3][8] metadata,
      uint[4][8] move,
      bytes32[2][8] signatureRS,
      uint8[8] v,
      uint8[176] moveInput,
      uint8 nbSignature
      ) public {
        require(nbSignature > 0);
        require(metadata[0][0] == ServerManager(serverManager).getServerCurrentMatch(indexServer));
        require(metadata[0][2] < ServerManager(serverManager).getPlayerMax(indexServer));
        require(!deadPlayer[metadata[0][0]][killerAndKilled[1]]);

        // Check if it is the first turn
        // During first turn not all alive player are required to be part of the signatures list
        if(metadata[0][1] == 0 && metadata[0][2] == 0) {
            moveInput = ServerManager(serverManager).getInitialState(indexServer);
        }

        // Verify the killer is the last player
        require(metadata[nbSignature-1][2] == killerAndKilled[0]);

        // Verify the player is originally alive
        require(isAlive(moveInput, killerAndKilled[1]));

        // Verify all signatures
        for(uint8 i=0; i<nbSignature; i++) {

            // Check if this turn has been timed out
            if(matchTimeoutTurns[metadata[i][0]][metadata[i][1]][metadata[i][2]]) {
                // If the turn has been timed out no need to verify move owner
                if(i == 0) {
                    uint8[176] memory simulatedTurn = kill(moveInput, uint8(metadata[i][2]));
                }
                else {
                    simulatedTurn = kill(simulatedTurn, uint8(metadata[i][2]));
                }
            }
            else {
                // Simulate the turn and verify the simulated output is the given output
                if(i == 0) {
                    simulatedTurn = simulate(indexServer, uint8(metadata[i][2]), uint8(move[i][0]), uint8(move[i][1]), uint8(move[i][2]), uint8(move[i][3]), moveInput);
                }
                else {
                    simulatedTurn = simulate(indexServer, uint8(metadata[i][2]), uint8(move[i][0]), uint8(move[i][1]), uint8(move[i][2]), uint8(move[i][3]), simulatedTurn);
                }

                // Verify that the move have been signed by the player
                require(moveOwner(metadata[i], move[i], simulatedTurn, signatureRS[i][0], signatureRS[i][1], v[i]) == ServerManager(serverManager).getAddressFromIndex(indexServer, uint8(metadata[i][2])));
            }

            // Vertify metadata integrity
            if(i < nbSignature-1) {
                // If not the last turn check the next turn is correctly the next player
                verifyNextTurn(indexServer, metadata[i], metadata[i+1], simulatedTurn);
            }
            else if(metadata[0][1] > 0 || metadata[0][2] > 0) {
                // Last turn: we verified every alive player signed their turn
                // Not necessary if the signature list begin from origin
                verifyAllSigned(indexServer, metadata[0], metadata[i], simulatedTurn);
            }

            // Verify the killed has been actually killed in the last turn
            if(i < nbSignature-1) {
                // If it was not the last turn, the player should still be alive
                require(isAlive(simulatedTurn, killerAndKilled[1]));
            }
            else {
                // Otherwise he must be dead
                require(!(isAlive(simulatedTurn, killerAndKilled[1])));
            }
        }

        // Set player to dead
        deadPlayer[ServerManager(serverManager).getServerCurrentMatch(indexServer)][killerAndKilled[1]] = true;

        // Kill the player
        ServerManager(serverManager).removePlayer(indexServer, killerAndKilled[1]);

        // Transfer fund to players when a player is killed
        // Killer receive money bag from killed
        // Killed get his cheat warrant back
        ServerManager(serverManager).nujaBattleTransfer(ServerManager(serverManager).getAddressFromIndex(indexServer, killerAndKilled[0]), ServerManager(serverManager).getServerMoneyBag(indexServer));
        ServerManager(serverManager).nujaBattleTransfer(ServerManager(serverManager).getAddressFromIndex(indexServer, killerAndKilled[1]), ServerManager(serverManager).getCheatWarrant());

        // If it was the last player, terminate the server
        if(ServerManager(serverManager).getPlayerNb(indexServer) == 1) {
            ServerManager(serverManager).terminateServer(indexServer, killerAndKilled[0]);
        }
    }


    // Function for timeout manager
    function timeoutPlayer(uint matchId, address timeoutClaimer, uint timeoutTurn, uint8 timeoutPlayer) public fromTimeoutStopper {
        uint server = ServerManager(serverManager).getMatchServer(matchId);

        // Transfer fund to players when a player is timed out
        // Timeout claimer receive money bag and cheat warrant from timed out
        ServerManager(serverManager).nujaBattleTransfer(timeoutClaimer, ServerManager(serverManager).getServerMoneyBag(server) + ServerManager(serverManager).getCheatWarrant());

        // Set player to dead
        deadPlayer[matchId][timeoutPlayer] = true;

        // Kick blamed player
        ServerManager(serverManager).removePlayer(server, timeoutPlayer);

        // register timeout
        matchTimeoutTurns[matchId][timeoutTurn][timeoutPlayer] = true;

        // If it was the last player, terminate the server
        if(ServerManager(serverManager).getPlayerNb(server) == 1) {

            // Search for last alive player
            for(uint8 i=0; i<ServerManager(serverManager).getPlayerMax(server); i++) {
                if(deadPlayer[matchId][i] == false) {
                  // Terminate the server
                  ServerManager(serverManager).terminateServer(server, i);
                  break;
                }
            }
        }
    }

    function isTimedout(uint matchId, uint turn, uint turnPlayer) public view returns (bool timedoutRet) {
        return matchTimeoutTurns[matchId][turn][turnPlayer];
    }
}

contract ServerManager is Geometry, StateManager {

    // General values
    address owner;
    address characterRegistry;
    address weaponRegistry;
    address nujaBattle;
    uint serverCreationFee;
    uint cheatWarrant;
    bool addressesSet;

    ///////////////////////////////////////////////////////////////
    /// Modifiers

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier fromNujaBattle {
        require(msg.sender == nujaBattle);
        _;
    }


    ///////////////////////////////////////////////////////////////
    /// Structures

    struct Player {
        address owner;
        uint characterIndex;
        uint8 initialX;
        uint8 initialY;
    }

    struct Building {
        uint8 weapon;
        bytes32 name;
    }

    struct Server {
        uint id;
        string name;
        address owner;
        uint fee;
        uint moneyBag;
        uint currentMatchId; // Warning: offset
        uint8 playerMax;
        uint8 playerNb;
        uint8 state;       // 0: offline, 1: waiting, 2: running
        mapping (uint8 => Building) buildings;
        mapping (uint8 => Player) players;
        mapping (address => uint8) playerIndex;   // Warning: offset
    }

    uint serverNumber;
    Server[] servers;

    // Get the server associated with the match id
    // The value is server.id + 1 because 0 represents not started yet match or ended match
    mapping (uint => uint) serverMatch;
    uint matchNb;

    // Necessary to get user&#39;s server
    mapping (address => uint) serverUserNumber;
    mapping (address => mapping (uint => uint)) serverUserIndex;

    // Map character to server
    mapping (uint => uint) characterServer;  // Offset

    ///////////////////////////////////////////////////////////////

    function ServerManager() public {
        owner = msg.sender;
        serverNumber = 0;
        characterRegistry = 0x462893f08BbaED3319a44E613E57e5257b0E5037;
        weaponRegistry = 0xDF480F0D91C0867A0de18DA793486287A22c2243;
        nujaBattle = address(0);
        serverCreationFee = 5 finney;
        cheatWarrant = 5 finney;
        matchNb= 0;
        addressesSet = false;
    }

    ///////////////////////////////////////////////////////////////
    /// Administration functions

    function setAddresses(address nujaBattle_) public onlyOwner {
        require(addressesSet == false);
        nujaBattle = nujaBattle_;
        addressesSet = true;
    }

    function changeFeeAndCheatWarrant(uint fee, uint warrant) public onlyOwner {
        serverCreationFee = fee * 1 finney;
        cheatWarrant = warrant * 1 finney;
    }

    // Add server to the server list
    function addServer(string name, uint8 max, uint fee, uint moneyBag) public payable {
        require(max > 1 && max <= 8);
        require(msg.value == serverCreationFee);
        Server memory newServer;
        newServer.id = serverNumber;
        newServer.fee = fee * 1 finney;
        newServer.moneyBag = moneyBag * 1 finney;
        newServer.currentMatchId = 0;
        newServer.name = name;
        newServer.owner = msg.sender;
        newServer.state = 0;
        newServer.playerMax = max;
        newServer.playerNb = 0;

        servers.push(newServer);

        // Update general information
        serverUserIndex[msg.sender][serverUserNumber[msg.sender]] = serverNumber;
        serverUserNumber[msg.sender] += 1;
        serverNumber += 1;

        // Transfer fee to contract owner
        owner.transfer(msg.value);
    }

    // Set the server online if server offline and offline if server online
    function changeServerState(uint indexServer) public {
        require(indexServer < serverNumber);
        require(servers[indexServer].owner == msg.sender);

        if(servers[indexServer].state == 0) {
            servers[indexServer].state = 1;
        }
        else if(servers[indexServer].state == 1) {
            // If player has already joined the server, it can&#39;t be offline
            require(servers[indexServer].playerNb == 0);
            servers[indexServer].state = 0;
        }
        else {
            // A match is running on the server, the state cannot be changed
            revert();
        }
    }

    // Add list of buildings to the server
    function addBuildingToServer(uint indexServer, uint8[10] x, uint8[10] y, uint8[10] weapon, bytes32[10] name, uint8 nbBuilding) public {
        require(indexServer < serverNumber);
        require(servers[indexServer].state == 0);
        require(servers[indexServer].owner == msg.sender);
        require(nbBuilding <= 10 && nbBuilding > 0);

        // Add building
        for(uint8 i=0; i<nbBuilding; i++) {
            require(x[i] < 8 && y[i] < 8);
            require(servers[indexServer].buildings[x[i]*8+y[i]].weapon == 0);

            // Verify weapon exists
            WeaponRegistry reg = WeaponRegistry(weaponRegistry);
            require(weapon[i] < reg.getWeaponNumber());

            servers[indexServer].buildings[x[i]*8+y[i]].weapon = 2 + weapon[i];
            servers[indexServer].buildings[x[i]*8+y[i]].name = name[i];
        }
    }

    // Remove list of buildings from server
    function removeBuildingFromServer(uint indexServer, uint8[10] x, uint8[10] y, uint8 nbBuilding) public {
        require(indexServer < serverNumber);
        require(servers[indexServer].state == 0);
        require(servers[indexServer].owner == msg.sender);
        require(nbBuilding <= 10 && nbBuilding > 0);

        // Add building
        for(uint8 i=0; i<nbBuilding; i++) {
            require(x[i] < 8 && y[i] < 8);
            require(servers[indexServer].buildings[x[i]*8+y[i]].weapon > 0);
            servers[indexServer].buildings[x[i]*8+y[i]].weapon = 0;
        }
    }

    // Owner of a character can add his character to the server
    function addPlayerToServer(uint character, uint server) public payable {
        require(server < serverNumber);
        require(servers[server].state == 1);
        require(characterServer[character] == 0);
        require(servers[server].playerNb < servers[server].playerMax);

        // Verify value
        uint sumValue = servers[server].fee + servers[server].moneyBag + cheatWarrant;
        require(msg.value == sumValue);

        // Verify character exists and subcribes it
        CharacterRegistry reg = CharacterRegistry(characterRegistry);
        require(character < reg.totalSupply());
        require(msg.sender == reg.ownerOf(character));
        characterServer[character] = server+1;

        // Create player
        uint8 numero = servers[server].playerNb;
        Player memory newPlayer;
        newPlayer.characterIndex = character;
        newPlayer.owner = msg.sender;

        // Player information for server
        servers[server].players[numero] = newPlayer;
        servers[server].playerIndex[msg.sender] = numero+1;

        servers[server].playerNb += 1;
    }

    // Remove character from server
    // No chracter id because it can be infered from owner address
    function removePlayerFromServer(uint server) public {
        require(server < serverNumber);
        require(servers[server].state == 1);
        require(servers[server].playerNb > 0);

        // Get the player of the caller
        uint8 p = servers[server].playerIndex[msg.sender];
        require(p > 0);
        p -= 1;

        // Remove player from server
        servers[server].playerIndex[msg.sender] = 0;
        characterServer[servers[server].players[p].characterIndex] = 0;

        // Reindexation if he was not the last player
        if(p < servers[server].playerNb-1) {
            servers[server].players[p] = servers[server].players[servers[server].playerNb-1];
            servers[server].playerIndex[servers[server].players[p].owner] = p;
        }

        // The caller get back his money
        uint sumValue = servers[server].fee + servers[server].moneyBag + cheatWarrant;
        msg.sender.transfer(sumValue);

        servers[server].playerNb -= 1;
    }

    // Start the server if it is full
    function startServer(uint server) public {
        require(server < serverNumber);
        require(servers[server].playerNb == servers[server].playerMax);

        uint8 maxPlayer = servers[server].playerMax;
        int random = int(keccak256(block.timestamp));
        for(uint8 i=0; i<maxPlayer; i++) {
            // Unique horizontale position
            servers[server].players[i].initialX = (3*i+5)%8;

            // Random vertical position
            random = int(keccak256(random));
            if(random < 0) {
                random *= -1;
            }
            uint8 y = uint8(random%8);
            servers[server].players[i].initialY = y;
            /* servers[server].players[i].initialX = i;
            servers[server].players[i].initialY = i; */
        }

        // Start the server
        servers[server].state = 2;
        servers[server].currentMatchId = matchNb+1;
        serverMatch[matchNb] = server+1;
        matchNb += 1;

        // Owner get the fees
        servers[server].owner.transfer(servers[server].fee * maxPlayer);
    }


    ///////////////////////////////////////////////////////////////
    /// Server functions

    // Servers informations

    // Number of server
    function getServerNb() public view returns(uint nbRet) {
        return serverNumber;
    }

    // Get the cheat warrant value
    function getCheatWarrant() public view returns(uint cheatWarrantRet) {
        return cheatWarrant;
    }

    // Get the server creatin fee calue
    function getServerCreationFee() public view returns(uint serverCreationFeeRet) {
        return serverCreationFee;
    }

    // Get name of a server
    function getServerName(uint indexServer) public view returns(string nameRet) {
        require(indexServer < serverNumber);
        return servers[indexServer].name;
    }

    // Get the id of a server from id of a match
    function getMatchServer(uint idMatch) public view returns(uint serverRet) {
        require(idMatch < matchNb);

        serverRet = serverMatch[idMatch];
        require(serverRet>0);

        return serverRet-1;
    }

    // Get current id of the server&#39;s match
    function getServerCurrentMatch(uint indexServer) public view returns(uint matchRet) {
        require(indexServer < serverNumber);

        matchRet = servers[indexServer].currentMatchId;
        require(matchRet>0);

        return matchRet-1;
    }

    // Get player max number from server
    function getPlayerMax(uint indexServer) public view returns(uint8 playerMaxRet) {
        require(indexServer < serverNumber);
        return servers[indexServer].playerMax;
    }

    // Get player number from server
    // waitig players if not started yet
    // alive players if server is running
    function getPlayerNb(uint indexServer) public view returns(uint8 playerNbRet) {
        require(indexServer < serverNumber);
        return servers[indexServer].playerNb;
    }

    // Get the state of the server
    // 0: server offline
    // 1: online but not started yet
    // 2: online and running
    function getServerState(uint indexServer) public view returns(uint8 stateRet) {
        require(indexServer < serverNumber);
        return servers[indexServer].state;
    }

    // Get some infos from server
    function getServerInfo(uint indexServer) public view returns(string nameRet, uint id, uint8 playerMaxRet, uint8 playerNbRet) {
        require(indexServer < serverNumber);
        return (servers[indexServer].name, servers[indexServer].id, servers[indexServer].playerMax, servers[indexServer].playerNb);
    }

    // Get financial infos from server (fee to join, money bag for player
    function getServerFee(uint indexServer) public view returns(uint feeRet) {
        require(indexServer < serverNumber);
        return servers[indexServer].fee;
    }
    function getServerMoneyBag(uint indexServer) public view returns(uint moneyBagRet) {
        require(indexServer < serverNumber);
        return servers[indexServer].moneyBag;
    }

    // Get building weapon code for position
    // 0: no building
    // 1: empty building
    // n: building with weapon n-2
    function getServerBuildingWeapon(uint indexServer, uint8 x, uint8 y) public view returns(uint8 weaponRet) {
        require(indexServer < serverNumber);
        require(x < 8);
        require(y < 8);

        return servers[indexServer].buildings[x*8+y].weapon;
    }

    function getServerBuildingName(uint indexServer, uint8 x, uint8 y) public view returns(bytes32 nameRet) {
        require(indexServer < serverNumber);
        require(x < 8);
        require(y < 8);

        return servers[indexServer].buildings[x*8+y].name;
    }


    // Get the number of server owned by user
    function getServerUserNumber(address user) public view returns(uint serverUserNumberRet) {
        return serverUserNumber[user];
    }

    // Get id of server from owner and index of owned server
    function getServerUserIndex(address user, uint index) public view returns(uint serverUserIndexRet) {
        require(index < serverUserNumber[user]);

        return serverUserIndex[user][index];
    }


    // Specific server information

    // Get the initial state of server (considering building, players position etc)
    function getInitialState(uint indexServer) public view returns(uint8[176] ret) {
        require(indexServer < serverNumber);

        // Buildings
        for(uint8 i = 0; i<8; i++) {
            for(uint8 j = 0; j<8; j++) {
                ret[i*8+j] = servers[indexServer].buildings[i*8+j].weapon;
            }
        }
        // Players
        for(i = 0; i<8; i++) {
            for(j = 0; j<8; j++) {
                ret[64+i*8+j] = 0;
            }
        }
        // healths
        for(i = 0; i<servers[indexServer].playerMax; i++) {
            ret[128+i] = 100;
        }
        for(i = servers[indexServer].playerMax; i<8; i++) {
            ret[128+i] = 0;
        }
        // Positions
        for(i = 0; i<servers[indexServer].playerMax; i++) {
            ret[136+i] = servers[indexServer].players[i].initialX;
            ret[144+i] = servers[indexServer].players[i].initialY;
            ret[64+servers[indexServer].players[i].initialX*8+servers[indexServer].players[i].initialY] = i+1;
        }
        for(i = servers[indexServer].playerMax; i<8; i++) {
            ret[136+i] = 0;
            ret[144+i] = 0;
        }
        // Weapons
        for(i = 0; i<24; i++) {
            ret[152+i] = 0;
        }

        return ret;
    }

    // Get user index in server from his address
    function getIndexFromAddress(uint indexServer, address ownerAddress) public view returns(uint8 indexRet) {
        require(indexServer < serverNumber);
        require(servers[indexServer].playerIndex[ownerAddress] > 0);

        return servers[indexServer].playerIndex[ownerAddress]-1;
    }

    // Get address in a server from the index
    function getAddressFromIndex(uint indexServer, uint8 indexPlayer) public view returns(address ownerRet) {
        require(indexServer < serverNumber);
        require(indexPlayer < servers[indexServer].playerMax);

        return servers[indexServer].players[indexPlayer].owner;
    }

    // Check if user is present in the server
    function isAddressInServer(uint indexServer, address ownerAddress) public view returns(bool isRet) {
        require(indexServer < serverNumber);

        return (servers[indexServer].playerIndex[ownerAddress] > 0);
    }

    // Get Character index from server and player index
    function playerCharacter(uint indexServer, uint8 indexPlayer) public view returns(uint characterIndex) {
        require(indexServer < serverNumber);
        require(indexPlayer < servers[indexServer].playerMax);

        return (servers[indexServer].players[indexPlayer].characterIndex);
    }

    // Get the current server from character
    function getCharacterServer(uint characterId) public view returns(uint serverId) {
        // Verify character exists
        CharacterRegistry reg = CharacterRegistry(characterRegistry);
        require(characterId < reg.totalSupply());

        return characterServer[characterId];
    }


    // Server modification

    // Remove player from server
    function removePlayer(uint indexServer, uint8 killed) public fromNujaBattle {
        servers[indexServer].playerNb -= 1;

        // Set player index to 0
        servers[indexServer].playerIndex[servers[indexServer].players[killed].owner] = 0;

        // Set character server to 0
        uint character = servers[indexServer].players[killed].characterIndex;
        characterServer[character] = 0;
    }

    // Terminate the running server
    function terminateServer(uint indexServer, uint8 winner) public fromNujaBattle {
        // Reset server
        removePlayer(indexServer, winner);
        servers[indexServer].state = 1;
        serverMatch[servers[indexServer].currentMatchId-1] = 0;
        servers[indexServer].currentMatchId = 0;

        // Winner get his money back
        servers[indexServer].players[winner].owner.transfer(servers[indexServer].moneyBag + cheatWarrant);
    }

    // Transfer of fund approved by nuja battle smart contract
    function nujaBattleTransfer(address addr, uint amount) public fromNujaBattle {
        addr.transfer(amount);
    }
}

contract Weapon is Geometry, StateManager {
    // Must return ipfs hash
    // the repository must at least contain image.png and name/default
    function getMetadata() public pure returns (string metadata);

    // Function called by server to use the Weapon
    function use(uint8 x, uint8 y, uint8 player, uint8[176] moveInput) public view returns(uint8[176] moveOutput);
}

contract WeaponRegistry {

    ///////////////////////////////////////////////////////////////
    /// Modifiers

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    ///////////////////////////////////////////////////////////////
    /// Attributes
    address owner;
    uint8 weaponNumber;
    address[] weaponArray;

    ///////////////////////////////////////////////////////////////
    /// Constructor

    function WeaponRegistry() public {
        owner = msg.sender;
        weaponNumber = 0;
    }

    ///////////////////////////////////////////////////////////////
    /// Admin functions

    function addWeapon(address weaponContract) public onlyOwner {
        // Weapons max number
        require(weaponNumber <= 250);
        weaponArray.push(weaponContract);
        weaponNumber += 1;
    }

    function getContract(uint8 index) public constant returns (address contractRet) {
        require(index < weaponNumber);

        return weaponArray[index];
    }

    // Get functions
    function getOwner() public view returns(address ret) {
        return owner;
    }

    function getWeaponNumber() public view returns(uint8 ret) {
        return weaponNumber;
    }
}