// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Foods.sol";
import "./Equipments.sol";
import "./Tablecloths.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Ownable.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract SandwichesContract is ERC1155, Ownable, Foods, Equipments, Tablecloths {
    
    //name
    string public name;

    //symbol
    string public symbol;
        
    using SafeMath for uint256;
    
    uint public totalTokenTypes = 1;
    
    uint256 public maxPurchase = 4;
        
    uint256 public foodPrice = 0; // 0.05 ETH
    uint256 public equipmentPrice = 0; // 0.05 ETH
    uint256 public tableclothPrice = 0; // 0.05 ETH
    uint256 public synthesisPrice = 0; // 0.05 ETH

    uint8 private foodType = 1;
    uint8 private equipmentType = 2;
    uint8 private tableclothType = 3;
    uint8 private sandwichType = 4;

    // Mapping from token ID to owner address
    mapping (uint256 => address) public _owners;

    event goodsCreated(uint256 _type, uint256 indexed id, address indexed owner, uint256 created);
    event resourceStatusUpdate(uint256[] foods, uint256[] equipments);
    
    //https://game.example/api/item/{id}.json
    constructor() ERC1155("https://cryptosandwiches.com/") {
        name = "Sandwich";
        symbol = "SW";
    }
    
    struct Sandwich {
        uint id;
        string name;
        string describe;
        uint32 aggressivity;
        uint32 defensive;
        uint32 healthPoint;
        uint256[5] elements;
        // The timestamp from the block when this cat came into existence.
        uint64 created;
    }
    
    mapping(address => uint[]) internal userSandwiches;
    mapping(uint => Sandwich) internal sandwiches;

     /**
    * Create Combination
    */
    function createCombination(
        address recipient,
        uint numberOfTokens,
        string memory _name,
        string memory _describe
    ) public payable {
        require(numberOfTokens > 0, "Number must be greater than 0.");
        require(numberOfTokens <= maxPurchase, "Exceeds max number in one transaction.");
        require(foodPrice.mul(numberOfTokens) == msg.value, "Ether value sent is not correct");
        
        uint8 _type = _createRandom(0, 2);

        if (_type == 0) {
            uint8 calories = _createRandom(20, 40);
            uint8 scent = _createRandom(20, 40);
            uint8 freshness = _createRandom(20, 40);
            
            Food memory _food = Food({
                id: totalTokenTypes,
                name: _name,
                describe: _describe,
                calories: uint32(calories),
                scent: uint32(scent),
                freshness:uint32(freshness),
                created: uint64(block.timestamp),
                used: false
            });
            foods[totalTokenTypes] = _food;
            _owners[totalTokenTypes] = recipient;
            _mint(recipient, totalTokenTypes, 1, "");
            userFoods[recipient].push(totalTokenTypes);
            
            emit goodsCreated(foodType, totalTokenTypes, recipient, _food.created);
        } else {
            uint256 end = 3;
            uint8 aggressivity = _createRandom(0, end + 1);
            uint8 aggressivityType;
            if(_createRandom(0, 10) % 2 == 0){
                aggressivityType = 0;
            }else{
                aggressivityType = 1;
            }
            
            uint8 defensive = _createRandom(0, end + 1);
            uint8 defensiveType;
            if(_createRandom(0, 10) % 2 == 0){
                defensiveType = 0;
            }else{
                defensiveType = 1;
            }
       
            uint8 healthPoint = _createRandom(0, end + 1);
            uint8 healthPointType;
            if(_createRandom(0, 10) % 2 == 0){
                healthPointType = 0;
            }else{
                healthPointType = 1;
            }
            
            Equipment memory _equipment = Equipment({
                id: totalTokenTypes,
                name: _name,
                describe: _describe,
                aggressivity: uint32(aggressivity),
                defensive: uint32(defensive),
                healthPoint: uint32(healthPoint),
                aggressivityType: aggressivityType,
                defensiveType: defensiveType,
                healthPointType: defensiveType,
                created: uint64(block.timestamp),
                used: false
            });
            
            equipments[totalTokenTypes] = _equipment;
            _owners[totalTokenTypes] = recipient;
            _mint(recipient, totalTokenTypes, 1, "");
            userEquipments[recipient].push(totalTokenTypes);
            emit goodsCreated(equipmentType, totalTokenTypes, recipient, _equipment.created);
        }
        nextTokenId();
    }
  
    /**
    * Create Food
    */
    function createFood(
        address recipient,
        uint numberOfTokens,
        string memory _name,
        string memory _describe
    ) public payable {
        require(numberOfTokens > 0, "Number must be greater than 0.");
        require(numberOfTokens <= maxPurchase, "Exceeds max number in one transaction.");
        require(foodPrice.mul(numberOfTokens) == msg.value, "Ether value sent is not correct");
        
        for (uint i = 0; i < numberOfTokens; i++) {
            uint8 calories = _createRandom(20, 40);
            uint8 scent = _createRandom(20, 40);
            uint8 freshness = _createRandom(20, 40);
            
            Food memory _food = Food({
                id: totalTokenTypes,
                name: _name,
                describe: _describe,
                calories: uint32(calories),
                scent: uint32(scent),
                freshness:uint32(freshness),
                created: uint64(block.timestamp),
                used: false
            });
            foods[totalTokenTypes] = _food;
            _owners[totalTokenTypes] = recipient;
            _mint(recipient, totalTokenTypes, 1, "");
            userFoods[recipient].push(totalTokenTypes);
            
            emit goodsCreated(foodType, totalTokenTypes, recipient, _food.created);
            
            nextTokenId();
        }
    }
    
    /**
    * Create Equipment
    */
    function createEquipment(
        address recipient,
        uint numberOfTokens,
        string memory _name,
        string memory _describe
    ) public payable {
        require(numberOfTokens > 0, "Number must be greater than 0.");
        require(numberOfTokens <= maxPurchase, "Exceeds max number in one transaction.");
        require(equipmentPrice.mul(numberOfTokens) == msg.value, "Ether value sent is not correct");
        
        uint256 end = 3;
        for (uint i = 0; i < numberOfTokens; i++) {
            
            uint8 aggressivity = _createRandom(0, end + 1);
            uint8 aggressivityType;
            if(_createRandom(0, 10) % 2 == 0){
                aggressivityType = 0;
            }else{
                aggressivityType = 1;
            }
            
            uint8 defensive = _createRandom(0, end + 1);
            uint8 defensiveType;
            if(_createRandom(0, 10) % 2 == 0){
                defensiveType = 0;
            }else{
                defensiveType = 1;
            }
       
            uint8 healthPoint = _createRandom(0, end + 1);
            uint8 healthPointType;
            if(_createRandom(0, 10) % 2 == 0){
                healthPointType = 0;
            }else{
                healthPointType = 1;
            }
            
            Equipment memory _equipment = Equipment({
                id: totalTokenTypes,
                name: _name,
                describe: _describe,
                aggressivity: uint32(aggressivity),
                defensive: uint32(defensive),
                healthPoint: uint32(healthPoint),
                aggressivityType: aggressivityType,
                defensiveType: defensiveType,
                healthPointType: defensiveType,
                created: uint64(block.timestamp),
                used: false
            });
            
            equipments[totalTokenTypes] = _equipment;
            _owners[totalTokenTypes] = recipient;
            _mint(recipient, totalTokenTypes, 1, "");
            userEquipments[recipient].push(totalTokenTypes);
            
            emit goodsCreated(equipmentType, totalTokenTypes, recipient, _equipment.created);
            
            nextTokenId();
        }
    }
    
    /**
    * Create Tablecloth
    */
    function createTablecloth(
        address recipient,
        uint numberOfTokens,
        string memory _name,
        string memory _describe
    ) public payable {
        require(numberOfTokens > 0, "Number must be greater than 0.");
        require(numberOfTokens <= maxPurchase, "Exceeds max number in one transaction.");
        require(tableclothPrice.mul(numberOfTokens) == msg.value, "Ether value sent is not correct");
        
        for (uint i = 0; i < numberOfTokens; i++) {
            uint8 metal = _createRandom(0, 100);
            uint8 wood = _createRandom(0, 100);
            uint8 water = _createRandom(0, 100);
            uint8 fire = _createRandom(0, 100);
            uint8 earth = _createRandom(0, 100);
            
            Tablecloth memory _tablecloth = Tablecloth({
                id: totalTokenTypes,
                name: _name,
                describe: _describe,
                metal: uint32(metal),
                wood: uint32(wood),
                water: uint32(water),
                fire: uint32(fire),
                earth: uint32(earth),
                created: uint64(block.timestamp)
            });
     
            tablecloths[totalTokenTypes] = _tablecloth;
            _mint(recipient, totalTokenTypes, 1, "");
            userTablecloths[recipient].push(totalTokenTypes);
            
            emit goodsCreated(tableclothType, totalTokenTypes, recipient, _tablecloth.created);
            
            nextTokenId();
        }
    }
      
    function verify(uint256[] memory _foods,uint256[] memory _equipments) private {
        for (uint i = 0; i < _foods.length; i++){
            address owner = _owners[_foods[i]];
            require(owner == msg.sender, "No permissions");
        }
        for (uint i = 0; i < _equipments.length; i++){
            address owner = _owners[_equipments[i]];
            require(owner == msg.sender, "No permissions");
        }
    }
    // Create new sandwich heroes by synthesizing food, tablecloths, and props.
    function synthesis(address recipient,
        uint256[] memory foods,
        uint256[] memory equipments, 
        uint256 tablecloth,
        string memory _name,
        string memory _describe
    ) public payable{
        require(synthesisPrice == msg.value, "Ether value sent is not correct");
        verify(foods,equipments);
        
        uint256 _aggressivity;
        uint256 _defensive;
        uint256 _healthPoint;
        uint256[5] memory _elements;
        
        (_aggressivity, _defensive, _healthPoint, _elements) = calculate(foods, equipments, tablecloth);
        
        Sandwich memory _sandwich = Sandwich({
            id: totalTokenTypes,
            name: _name,
            describe: _describe,
            aggressivity: uint32(_aggressivity),
            defensive: uint32(_defensive),
            healthPoint: uint32(_healthPoint),
            elements: _elements,
            created: uint64(block.timestamp)
        });
        
        sandwiches[totalTokenTypes] = _sandwich;
        _mint(recipient, totalTokenTypes, 1, "");
        userSandwiches[recipient].push(totalTokenTypes);
        
        emit goodsCreated(sandwichType, totalTokenTypes, recipient, _sandwich.created);
        
        for(uint i = 0; i < foods.length; i++){ useFood(foods[i]); }
        for(uint i = 0; i < equipments.length; i++){ useEquipment(equipments[i]); }
        
        emit resourceStatusUpdate(foods, equipments);
        
        nextTokenId();
    }
    
    // Calculate the attribute value when the sandwich is generated.
    // Calculation formula:
    // A =（C + S）/ 2 + S;
    // D =（C + S）/ 2 + C;
    // H = 222 - D;
    function calculate(
        uint256[] memory foods,
        uint256[] memory equipments,
        uint256 tablecloth
    ) private returns (
        uint256 aggressivity,
        uint256 defensive,
        uint256 healthPoint,
        uint256[5] memory _elements
    ) {
        uint256 f_calories;
        uint256 f_scent;
        uint256 f_freshness;
        (f_calories, f_scent, f_freshness) = parseFood(foods);
        
        uint256 e_aggressivity;
        uint256 e_defensive;
        uint256 e_healthPoint;
        (e_aggressivity, e_defensive, e_healthPoint) = parseEquipments(equipments);
     
        // A =（C + S）/ 2 + S;
        // D =（C + S）/ 2 + C;
        // H = F;
        // Because Equipment uses 100 as the initial attribute value calculation, 100 is subtracted here
        aggressivity = (f_calories + f_scent) / 2 + f_scent + e_aggressivity - 100;
        defensive = (f_calories + f_scent) / 2 + f_calories + e_defensive - 100;
        healthPoint = f_freshness + e_healthPoint - 100;
        
        _elements = parseTablecloth(tablecloth);
    }


    // function test(
    //     uint256[4] memory foods,
    //     uint256[4] memory equipments,
    //     uint256 tablecloth
    // ) public view returns (
    //     uint256 f_calories,
    //     uint256 f_scent,
    //     uint256 f_freshness,
    //     uint256 e_aggressivity,
    //     uint256 e_defensive,
    //     uint256 e_healthPoint,
    //     uint256[5] memory _elements
    // ) {
    //     (f_calories, f_scent, f_freshness) = parseFood(foods);
        
    //     (e_aggressivity, e_defensive, e_healthPoint) = parseEquipments(equipments);
    // }



    function getUserSandwiches(address user) public view returns (uint[] memory) {
        return userSandwiches[user];
    }
    
    function getSandwich(uint256 _id)
    public
    view
    returns (
        uint id,
        string memory name,
        string memory describe,
        uint256 aggressivity,
        uint256 defensive,
        uint256 healthPoint,
        uint256[5] memory elements,
        uint256 created
    ) {
        Sandwich storage sandwich = sandwiches[_id];
        created = uint256(sandwich.created);
        aggressivity = sandwich.aggressivity;
        defensive = sandwich.defensive;
        healthPoint = sandwich.healthPoint;
        name = sandwich.name;
        describe = sandwich.describe;
        elements = sandwich.elements;
        id = _id;
    }
    
    // Initializing the state variable
    uint64 randNonce = 0;

    // Defining a function to generate
    // a random number             0             1
    function _createRandom(uint256 start, uint256 end) private returns (uint8)
    {
        // increase nonce
        randNonce++; 
        
        return uint8(
             (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, randNonce))) % (end - start)) + start
        );
    }
    
    function nextTokenId() private {
         totalTokenTypes ++;
    }
    
    /**
     * @dev Returns the URI of a token given its ID
     * @param id ID of the token to query
     * @return uri of the token or an empty string if it does not exist
     */
    function uri(uint256 id) public view override returns (string memory) {
        string memory baseUri = super.uri(0);
        return string(abi.encodePacked(baseUri, Strings.toString(id)));
    }
    
    /**
     * @dev Function to set the URI for all NFT IDs
     */
    function setBaseURI(string calldata _uri) external onlyOwner{
        _setURI(_uri);
    }
}